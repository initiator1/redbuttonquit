# CLAUDE.md — site/

The public marketing site for RedButtonQuit, served at `redbuttonquit.com`.

## Contract

- **No build step, no dependencies, no framework.** `index.html` is the whole site: inline CSS,
  inline JS, two PNGs. Cloudflare Pages serves this directory as-is with an empty build command.
  Keep it that way — a build step here buys nothing and adds a thing that can break.
- The only outbound request the page makes is the Google Fonts stylesheet. Do not add analytics,
  tag managers, embedded video, or third-party scripts. The page's own pitch is that the product
  collects nothing; the site has to match.
- Assets come from the real app. `icon-512.png` and `icon-128.png` are copied from
  `RedButtonQuit/Resources/Assets.xcassets/AppIcon.appiconset/`. If the app icon changes, copy
  the new one; never hand-draw a substitute.

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
python3 -m http.server "$PM_PORT_SITE" --bind 127.0.0.1   # from this directory
```

Render with the Playwright headless shell, never the installed Chrome bundle — a hook blocks the
latter because headless-ing the installed browser hijacks link handling for the whole Mac.

Check both: JavaScript on, and JavaScript off. Scroll-reveal is gated behind a `.js` class on
`<html>` precisely so a blocked script cannot leave the page blank.

## Deployment

Cloudflare Pages, connected to this GitHub repo. Build command empty, output directory `site`.
The domain move to Cloudflare is tracked in the repo root `OPEN-ITEMS.md`, and every step of it
is BOSS's own login.
