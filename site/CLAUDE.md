# CLAUDE.md — site/

The public marketing site for RedButtonQuit, served at `redbuttonquit.com`.

## Contract

- **No build step, no dependencies, no framework.** `index.html` is the whole site: inline CSS,
  inline JS, three PNGs. Cloudflare Worker static assets serve this directory as-is.
  Keep it that way — a build step here buys nothing and adds a thing that can break.
- The only outbound request the page makes is the Google Fonts stylesheet. Do not add analytics,
  tag managers, embedded video, or third-party scripts. The page's own pitch is that the product
  collects nothing; the site has to match.
- Assets come from the real app. `icon-512.png` and `icon-128.png` are copied from
  `RedButtonQuit/Resources/Assets.xcassets/AppIcon.appiconset/`. If the app icon changes, copy
  the new one; never hand-draw a substitute. `social-preview.png` uses that real icon and
  deterministic brand text. From this directory, run
  `python3 ../tools/render_launch_assets.py --prepare`, then copy
  `../dist/launch/social-preview.png` here.

## Design

Deliberate direction, do not flatten it toward a generic landing page:

- **Instrument panel.** Graphite ground, warm bone type, hairline etched rules, silkscreen mono
  labels. The only saturated colours are the three real macOS traffic-light values, because they
  belong to the subject rather than to a theme.
- **One tonal inversion.** "The record" section flips to bone paper with dark ink. That break is
  the page's spine — it lands exactly where the product's receipt idea lives. Keep it.
- **One signature element.** The hero window is functional: its red button closes it, and the
  quit history strip prints a line stamped with the visitor's own clock. That single interaction
  teaches the whole product. Do not add a second attention-seeking animation to compete with it.
- Type: Archivo (display, width axis 108–112) over Outfit (body), with the system mono for
  readouts.

## Truthfulness rules, learned the hard way

Everything on this page is a promise the product has to keep. Before adding a claim, verify it
against the shipped app, not against the README:

- **No Homebrew instructions.** The cask does not exist — `brew info --cask redbuttonquit`
  returned "No Cask with this name exists" on 2026-08-19. Add the section when the cask is
  actually accepted.
- **No donation button without a live destination.** The page is `ko-fi.com/initiatorworks`,
  claimed 2026-08-19 and live. The earlier `ko-fi.com/initiator1` never existed — it redirected
  to Ko-fi's home page and shipped dead inside v1.0.0. Check any payment link resolves before
  putting it on the page.
- **The quit history section describes a shipped feature.** It ships with the app release that
  contains it. Do not publish the section ahead of the release.
- Version, size, and requirements in the hero and spec table are hand-written. Update them with
  each release.

## Verifying a change

There is no test suite. Look at it:

```bash
portmanager sync redbuttonquit
set -a
. ../.portmanager/ports.env   # from this directory
set +a
python3 -m http.server "$PM_PORT_SITE" --bind "$PM_HOST"
```

Render with the Playwright headless shell, never the installed Chrome bundle — a hook blocks the
latter because headless-ing the installed browser hijacks link handling for the whole Mac.

Check both: JavaScript on, and JavaScript off. Scroll-reveal is gated behind a `.js` class on
`<html>` precisely so a blocked script cannot leave the page blank.

## Deployment

Live at **https://redbuttonquit.com** and **www.redbuttonquit.com** since 2026-09-28.

Hosting is a **Cloudflare Worker with static assets** (worker name `redbuttonquit`,
account `db1@pm.me`). It is not a classic Pages project: `wrangler pages project create`
now delegates to Workers, so the Worker is what exists. Static-asset requests are free and
unlimited on the Workers Free plan (Cloudflare docs, checked 2026-09-28). No Worker script
runs; `wrangler.jsonc` only points at the files and binds the two custom domains.

Deploy from this directory:

```bash
npx wrangler deploy
```

**`.assetsignore` is load-bearing.** The assets directory is this folder, so without it
`CLAUDE.md` and `wrangler.jsonc` are served publicly — that happened on the first deploy on
2026-09-28 and was caught by requesting `/CLAUDE.md`. After every deploy, confirm
`https://redbuttonquit.com/CLAUDE.md` returns 404.

There is no git-connected auto-deploy. A merge to `main` does not publish the site; run the
deploy command.
