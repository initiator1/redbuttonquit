#!/usr/bin/env python3
"""Render the approved trailer bookends; real footage is required for the middle.

Requires existing local Pillow and ffmpeg. No network, audio, or generation API.
Run --prepare for bookends and a social preview. Supply both footage paths to
assemble the 22-second trailer. Footage must contain only the approved test app.
"""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FPS = 30
VOID = "#0E1012"
PANEL = "#16191C"
ETCH = "#2B3138"
BONE = "#E9E5DD"
DIM = "#98A0A8"
RED = "#FF5F57"
FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
MONO = "/System/Library/Fonts/Menlo.ttc"
FORMATS = {"landscape": (1280, 720), "square": (1080, 1080)}


def font(size, light=False, mono=False):
    return ImageFont.truetype(MONO if mono else FONT, round(size), index=0 if mono else (7 if light else 0))


def ease(value):
    value = max(0, min(1, value))
    return 1 - (1 - value) ** 3


def frame(size, section, time):
    """A branded illustration, never a substitute for recorded macOS behavior."""
    width, height = size
    scale = width / 1280
    image = Image.new("RGB", size, VOID)
    draw = ImageDraw.Draw(image)
    margin = round(width * 0.09)
    top = round(height * 0.12)
    square = width == height
    draw.line((margin, height * 0.87, width - margin, height * 0.87), fill=ETCH, width=1)
    draw.text((margin, height * 0.91), "REDBUTTONQUIT  /  MACOS 14+", fill=DIM, font=font(15 * scale, mono=True))

    if section == "intro" and time < 5:
        draw.text((margin, top), "dear macOS,", fill=DIM, font=font(26 * scale, mono=True))
        headline = "a closed window\nshould mean\na finished app."
        visible = headline[:min(len(headline), round(max(0, time - 0.4) * 22))]
        draw.multiline_text((margin, top + height * 0.12), visible, fill=BONE,
                            font=font((66 if square else 64) * scale, light=True), spacing=10 * scale)
        # This is an illustration of a close control, not simulated proof footage.
        box_width = width * (0.78 if square else 0.38)
        x = margin if square else width * 0.55
        y = height * (0.60 if square else 0.34)
        fade = 1 - ease((time - 3.3) / 0.5)
        box = Image.new("RGBA", size, (0, 0, 0, 0))
        bd = ImageDraw.Draw(box)
        bd.rounded_rectangle((x, y, x + box_width, y + height * 0.16), radius=10 * scale, fill=PANEL, outline=ETCH)
        for index, color in enumerate((RED, "#FEBC2E", "#28C840")):
            cx = x + (30 + index * 28) * scale
            cy = y + 30 * scale
            bd.ellipse((cx - 8 * scale, cy - 8 * scale, cx + 8 * scale, cy + 8 * scale), fill=color)
        box.putalpha(box.getchannel("A").point(lambda alpha: round(alpha * fade)))
        image.paste(box, (0, 0), box)
        draw.text((x, y + height * 0.22), "ILLUSTRATED BEHAVIOUR", fill=DIM, font=font(12 * scale, mono=True))
    else:
        entry = ease((time - 5) / 0.65) if section == "intro" else ease(time / 0.5)
        offset = round((1 - entry) * 18 * scale)
        icon = Image.open(ROOT / "site/icon-512.png").convert("RGBA")
        icon.thumbnail((round(102 * scale), round(102 * scale)), Image.Resampling.LANCZOS)
        image.paste(icon, (margin, top + offset), icon)
        draw.text((margin + 130 * scale, top + 35 * scale + offset), "RedButtonQuit", fill=BONE, font=font(34 * scale))
        headline = "Close the last window.\nThe app quits." if section == "intro" else "Free and\nopen source."
        draw.multiline_text((margin, top + height * 0.24 + offset), headline, fill=BONE,
                            font=font((78 if square else 76) * scale, light=True), spacing=12 * scale)
        detail = "A local record of every quit." if section == "intro" else "redbuttonquit.com"
        draw.text((margin, height * 0.69 + offset), detail, fill=RED if section == "outro" else DIM,
                  font=font((36 if section == "outro" else 22) * scale))
        if section == "outro":
            draw.text((margin, height * 0.78), "Optional tips support development.", fill=DIM, font=font(19 * scale))
    return image


def encode(path, size, section, duration):
    width, height = size
    command = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24",
               "-s", f"{width}x{height}", "-r", str(FPS), "-i", "-", "-an", "-c:v", "libx264",
               "-preset", "fast", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(path)]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    try:
        for index in range(round(duration * FPS)):
            process.stdin.write(frame(size, section, index / FPS).tobytes())
    finally:
        process.stdin.close()
    if process.wait():
        raise RuntimeError(f"ffmpeg failed while rendering {path.name}")


def inspect_clip(path, minimum):
    result = subprocess.check_output(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)])
    info = json.loads(result)
    if not any(stream["codec_type"] == "video" for stream in info["streams"]):
        raise ValueError(f"No video stream: {path}")
    if float(info["format"]["duration"]) < minimum:
        raise ValueError(f"{path.name} needs at least {minimum} seconds")


def assemble(output, kind, size, proof, settings):
    width, height = size
    segments = [(output / f"intro-{kind}.mp4", 9), (proof, 3), (settings, 5), (output / f"outro-{kind}.mp4", 5)]
    command = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    filters = []
    for index, (path, duration) in enumerate(segments):
        command += ["-i", str(path)]
        suffix = "base" if index in (1, 2) else ""
        filters.append(f"[{index}:v]trim=duration={duration},setpts=PTS-STARTPTS,scale={width}:{height}:force_original_aspect_ratio=decrease,pad={width}:{height}:(ow-iw)/2:(oh-ih)/2:color=0x0E1012,fps={FPS},setsar=1[v{index}{suffix}]")
    # Pillow supplies exact labels. The installed ffmpeg has no drawtext filter.
    for index, label in ((1, "TextEdit - real macOS capture"), (2, "Quit history - real app capture")):
        label_font = font(width * .015, mono=True)
        bounds = label_font.getbbox(label)
        caption = Image.new("RGBA", (bounds[2] - bounds[0] + 24, bounds[3] - bounds[1] + 24), (14, 16, 18, 230))
        ImageDraw.Draw(caption).text((12 - bounds[0], 12 - bounds[1]), label, font=label_font, fill=BONE)
        caption_path = output / f"capture-label-{kind}-{index}.png"
        caption.save(caption_path)
        command += ["-loop", "1", "-i", str(caption_path)]
        filters.append(f"[v{index}base][{index + 3}:v]overlay=(W-w)/2:H-h-28:shortest=1[v{index}]")
    filters.append("[v0][v1][v2][v3]concat=n=4:v=1:a=0[v]")
    command += ["-filter_complex", ";".join(filters), "-map", "[v]", "-an", "-c:v", "libx264", "-crf", "18",
                "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(output / f"RedButtonQuit-trailer-{kind}.mp4")]
    subprocess.run(command, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepare", action="store_true", help="Render finished bookends; do not fabricate a middle clip")
    parser.add_argument("--proof-clip", type=Path, help="Approved TextEdit close-and-quit recording, at least 3 seconds")
    parser.add_argument("--settings-clip", type=Path, help="Approved test-only quit-history recording, at least 5 seconds")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/launch")
    args = parser.parse_args()
    if not args.prepare and not (args.proof_clip and args.settings_clip):
        parser.error("Provide both real capture clips, or use --prepare for the finished bookends.")
    if bool(args.proof_clip) != bool(args.settings_clip):
        parser.error("Both real capture clips are required together.")
    for executable in ("ffmpeg", "ffprobe"):
        if not shutil.which(executable):
            parser.error(f"Install {executable} before rendering.")
    if args.proof_clip:
        inspect_clip(args.proof_clip, 3)
        inspect_clip(args.settings_clip, 5)
    args.output.mkdir(parents=True, exist_ok=True)
    for kind, size in FORMATS.items():
        encode(args.output / f"intro-{kind}.mp4", size, "intro", 9)
        encode(args.output / f"outro-{kind}.mp4", size, "outro", 5)
        if args.proof_clip:
            assemble(args.output, kind, size, args.proof_clip, args.settings_clip)
    frame((1200, 630), "intro", 8).save(args.output / "social-preview.png")
    manifest = {"status": "complete" if args.proof_clip else "bookends-ready-real-capture-pending",
                "duration_seconds": 22, "fps": FPS, "audio": False, "formats": FORMATS,
                "sources": ["site/icon-512.png", "site/index.html palette", "actual captures required for middle"],
                "icon_sha256": hashlib.sha256((ROOT / "site/icon-512.png").read_bytes()).hexdigest(),
                "illustration_notice": "The opening control graphic is labeled ILLUSTRATED BEHAVIOUR.",
                "sequence_seconds": {"intro": 9, "real_TextEdit": 3, "real_history": 5, "outro": 5}}
    (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"{manifest['status']}: {args.output}")


if __name__ == "__main__":
    main()
