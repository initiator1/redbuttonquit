# Open Items — RedButtonQuit

Durable ledger. Extracted 2026-08-16 from the accessibility/domain thread
before archiving it. The app itself is SHIPPED: v1.0.0 is live on GitHub,
notarized, verified by downloading from the public URL and checking the
notarization ticket survived the round trip.

## v1.1.1 released 2026-09-28

Published https://github.com/initiator1/redbuttonquit/releases/tag/v1.1.1 —
notarized and stapled (app and DMG), public download re-verified, installed,
TCC auth 2, TextEdit quit and was recorded as a confirmed quit on macOS 27.0.

- [ ] 2026-09-28 Confirm the helper fix in real use. The new build started
  2026-09-28T05:48:46Z. Every history entry after that should be a real app.
  Check `~/Library/Application Support/RedButtonQuit/history.json`: no
  `openAndSavePanelService`, `ThemeWidgetControlViewService`,
  `*-Settings.extension`, or `WebKit.WebContent` entries after that time.
  Not tested directly because forcing a file dialog takes over BOSS's screen.
- [ ] 2026-09-28 Watch whether Chrome still produces "cancelled" entries. The
  fix counts windows at the moment one closes; with exactly two windows open
  the count can land early and let a few false entries through. Acceptable if
  rare; if Chrome still logs dozens a day, revisit.

## Launch checklist (option C, decided 2026-09-28)

Council decision: skip official Homebrew (self-submission needs 225 stars; the
repo has 4). Build traction first; revisit Homebrew at 75 stars or on a user
request, and consider a personal tap then.

- [x] 2026-09-28 DONE: v1.1.1 fixes the two history bugs a launch audience would see.
- [x] 2026-09-28 DONE: site header no longer wraps at phone width (pushed to main).
- [x] 2026-09-28 DONE: site live at https://redbuttonquit.com and www, as a Cloudflare Worker with static assets. See site/CLAUDE.md → Deployment.
- [ ] 2026-09-28 Launch video for the post. Update 2026-10-02: the 9-second intro
  and 5-second outro are rendered in landscape and square formats, and the social
  preview is live. Real TextEdit and test-only history footage remain blocked by
  native Computer Use; the assembler refuses a full trailer without them. See
  `implementation-notes.md` for the commands and fixture verification. BOSS asked whether a motion-designed trailer
  (Remotion or paid tools; he is willing to pay) beats a plain screen recording, after
  seeing Opus-made app trailers on X. Moved to its own thread 2026-09-28.
  BOSS approves the proposed capture and launch on 2026-10-02.
  2026-09-27 recommendation (page: https://claude.ai/artifact/DdgRPwTBnkNzF5XvzZUvgd): a
  ~22s motion trailer built in code with HyperFrames (Apache-2.0, plain HTML, reuses the site
  hero), with a ~3s labeled real capture of TextEdit quitting in the middle. Remotion is the
  fallback (free for firms of 3 or fewer). No AI video generators: they invent UI. Required
  spend $0; optional music via ElevenLabs Starter, $6/mo.
- [x] 2026-09-27 DONE: launch clip calls. Recording approved (one TextEdit window, ~10s).
  Silent, no music spend. Tone: council picked the hybrid, dry "dear macOS," terminal lines in
  the site's instrument-panel look (~65% confidence; BOSS can override with A or B).
- [x] 2026-09-28 DONE: v1.1.2 released with the red close-button icon (notarized DMG on GitHub, site version line updated and deployed).
- [x] 2026-09-28 DONE: Debug permission prompts stopped (KI-007 in CLAUDE.md): Debug signs with the Apple Development cert and the test host never touches TCC.
- [ ] 2026-09-28 Clock: the Apple Development certificate that signs Debug builds expires 2027-02-03. Renew before then or Debug permission prompts return.
- [ ] 2026-09-28 Visual review of the Settings and onboarding windows (not yet looked at; not in the launch clip).
- [ ] 2026-09-27 Complete the 22-second trailer with real TextEdit and history
  footage. Update 2026-10-02: deterministic bookends and the assembler are ready;
  16:9 and square assembly checks pass with labeled test fixtures. Capture remains
  blocked by native Computer Use. The social preview is complete.
- [x] 2026-10-02 DONE: Social preview image, 1200x630, deployed for link shares.
- [x] 2026-09-28 DONE: GitHub repo website field set to redbuttonquit.com; seven topics added.
- [x] 2026-10-02 DONE: Approved launch posted in r/macapps' October App Pile.
  Public permalink and the 30-day promotion limit are recorded below.

## Quit history validation after review

Added 2026-08-19. The quit history change is uncommitted on
`feature/quit-history`.

- Run one installed-app check before release. Exclude a normal app, close its
  last window, and confirm the app stays open. Then remove the exclusion and
  confirm history changes from `Quitting…` to `Quit` only after termination.
- The automated store tests cover persistence and outcomes. A handler unit test
  needs a mock `NSRunningApplication` or termination seam. The feature brief
  forbids adding that seam for this change.

## The domain: redbuttonquit.com — suspension CLEARED, now an empty zone

**Verified live 2026-08-19 against the registry and NFSN's nameservers.** This
replaces the 2026-08-14 entry, which said the verification had failed.

- **The Whois verification did go through.** Registry `Updated Date` is
  `2026-08-14T11:00:09Z` — about fifteen minutes after the last check said it
  had not taken. Nameservers are now the real `ns.phx1` / `ns.phx5
  .nearlyfreespeech.net`, not the `VERIFICATION-HOLD.SUSPENDED-DOMAIN.COM`
  parking pair.
- **The NFSN support mail was never needed and must not be sent.** The draft
  in the earlier version of this file is dead. Do not send it.
- **The zone answers but is empty.** SOA resolves from NFSN. There is no A,
  no www, no MX, no TXT. The domain resolves to nothing because nothing has
  been put in it, which is a different problem from being switched off.
- `clientTransferProhibited` is set. That is the ordinary registrar lock, not
  a penalty — it is step 5 of the move below.

### The clock — unchanged and still the real risk

Expires **2026-12-29**, renewal type **Manual**. 132 days left as of
2026-08-19. It will not renew itself. Estimated deletion 2027-03-14 if it
lapses. The Cloudflare transfer fixes this permanently: it adds a year (to
2027-12-29) and turns on auto-renew.

### The Cloudflare move — steps 1-3 are DONE (2026-08-20)

1. ~~Cloudflare → Add a site → redbuttonquit.com → Free plan.~~ **Done.**
   Zone ID `1bff360fa9e2ce357c657b1761f8531c`, Free plan, DNS scan found 0
   records because the zone was empty.
2. ~~Copy the assigned nameservers.~~ **Done:** `algin.ns.cloudflare.com` and
   `meadow.ns.cloudflare.com`.
3. ~~NFSN → set nameservers.~~ **Done.** Registry `Updated Date` is
   `2026-08-20T10:59:30Z` and the registry now lists both Cloudflare
   nameservers. Cloudflare's nameservers already answer SOA for the zone.
   Public resolvers still return the old NFSN pair from cache; that expires on
   its own.

4. ~~Zone Active.~~ **Done 2026-08-20.**
5. ~~NFSN Unlock Domain.~~ **Done 2026-09-27.** Registry status went from
   `clientTransferProhibited` to `ok`.
6. ~~Auth code.~~ **Done 2026-09-27.** BOSS retrieved and pasted it himself;
   it was never written into any chat or file.
7. ~~Cloudflare transfer submitted.~~ **Done 2026-09-27.** $10.46, paid by BOSS
   on a new card. Order `7b743f50-9c46-433b-90e0-4336576efdfa`. Registrant is
   INITIATOR LLC with db1@pm.me, redacted from public WHOIS by Cloudflare.
   Registry status read **`pendingTransfer`** at 2026-09-28T05:00Z.

- [ ] 2026-09-28 Confirm the transfer finished. Expected by about 2026-10-03
  (five days; NFSN may email an approval link that makes it faster). Check
  `whois redbuttonquit.com`: Registrar should read Cloudflare, expiry
  **2027-12-29**, and auto-renew should be on in Cloudflare → Registrations.
  If it still reads PDR after 2026-10-05, open a Cloudflare support ticket —
  the manual-renew expiry of 2026-12-29 is the real deadline. Public WHOIS still
  reports PDR, `pendingTransfer`, and expiry 2026-12-29 on 2026-10-02. Recheck
  on 2026-10-03. Account auto-renew status remains unverified.
- [x] 2026-09-28 DONE: Site deployed. The app's About link to redbuttonquit.com
  works now, in every shipped version, with no release needed.

**Whois Verification reads "Verified"** as of 2026-08-20, confirming the
January suspension is fully resolved at the registrar, not just at the registry.

After the transfer completes, expiry moves from 2026-12-29 to **2027-12-29** —
Cloudflare adds one year to the existing expiry, not one year from the transfer
date, per their own documentation — and auto-renew replaces Manual Renew.

Once the zone is Active, the site can deploy: Cloudflare → Workers & Pages →
Create → Pages → connect `initiator1/redbuttonquit`, framework preset **None**,
build command **empty**, output directory **`site`**. Then add the custom domain,
which also creates the A/CNAME records the zone currently lacks.

### Standing warning — still live

**Never use NFSN's "Remove RespectMyPrivacy" action.** It changes the
registrant of record, which is a Change of Registrant and can start a
**60-day inter-registrar transfer lock**. Real details go on the domain at
Cloudflare, after the transfer, where privacy is free.

## The website: built, not yet deployed

Built 2026-08-19 and on `main` at `site/`. One static `index.html`, no build step,
no framework. Its own contracts live in [site/CLAUDE.md](site/CLAUDE.md).

### Hosting: Cloudflare Pages, not NFSN

Decided 2026-08-19 after checking both live.

- **Cloudflare Pages free plan: $0/month, no traffic charge.** Verified against
  Cloudflare's own docs: 500 builds a month, 20,000 files a site, 25 MiB a file,
  100 custom domains a project. This site is 3 files.
- **NFSN charges $0.01/day for a non-production site** — a fixed ~$3.65/year
  before any bandwidth or storage. Cheap, but not free, and it is a second place
  to log into.
- The domain is moving to Cloudflare anyway, so Pages puts DNS, TLS, and hosting
  behind one login, with git-connected deploys straight from this repo.

### Deploy steps, when the domain move is done (BOSS's login)

1. Cloudflare → Workers & Pages → Create → Pages → Connect to Git →
   `initiator1/redbuttonquit`.
2. Framework preset **None**. Build command **empty**. Output directory **`site`**.
3. After the first deploy: Custom domains → add `redbuttonquit.com` and `www`.

**Order matters.** The quit-history section on the page describes a shipped
feature, so the site should go live with or after the release that contains it.

### The app already links to two dead URLs

Both are live in v1.0.0 right now, in Preferences → About:

- `https://redbuttonquit.com` — resolves to nothing until the site is deployed.
- `https://ko-fi.com/initiator1` — **does not exist.** Checked 2026-08-19: it
  redirects to Ko-fi's home page. "Buy me a coffee" currently goes nowhere.
  Needs BOSS's call: claim that Ko-fi username, or wait for GitHub Sponsors
  (parked on the CPA question), or remove the link.

The site deliberately ships no donation button until that is decided.

### Related placement decision

`ai-initiator/PRODUCT-LAB-PLACEMENT-RULE.md` puts RedButtonQuit on the
AI-Initiator Product Lab under "More Apps", linking to GitHub releases. BOSS
decided 2026-08-19 that the Product Lab should link to the website instead.
That rule file still says GitHub releases and needs updating when the site
is live.

## v1.1.0 is released

Published 2026-08-19: https://github.com/initiator1/redbuttonquit/releases/tag/v1.1.0

Signed by INITIATOR LLC, notarization submission
`15ba6ef8-cc81-4556-b5b8-b1ef06871e33` accepted, app and DMG both stapled,
`syspolicy_check distribution` passes. Verified by downloading the DMG from the
public URL and confirming the ticket survived the round trip. Installed locally
and confirmed working: TextEdit quit on last-window close and was recorded.

## Ko-fi is live

**Current verification — 2026-10-02:** The live website renders and links to
`https://ko-fi.com/initiatorworks?app=redbuttonquit`. The signed-in Ko-fi account
is `initiatorworks`; its Payment settings report Stripe connected, USD currency,
a $3 default tip and $1 minimum (changed with BOSS's approval on 2026-10-02). Monthly tips are available, but the default-to-
monthly option is off. The Standard plan is active: no monthly fee, with a 5%
Ko-fi fee on payments, plus payment processor fees. No payment was submitted;
this verifies the displayed setup, not successful payment or payout.

The app source includes support links in the menu and Settings → About. The website's support section appears
after installation instructions. Both the live website and Ko-fi bio promise
that the utilities stay free. Preserve that promise unless BOSS explicitly
chooses a different offer.

**Revenue implementation — 2026-10-02:** BOSS authorizes implementing the
recommended order. Version 1.1.3 (build 6) adds a direct support link to the app
menu and clear optional-tip copy in About. It is installed and running; signature,
TCC grant, preference preservation, and login registration checks pass. The app
and DMG are notarized and stapled. Previous app/data copies are in ignored
`build/support-review/previous/`.

The website changes are deployed: a tip link beside the free download and a
product-specific support message. Desktop, phone (389 CSS pixels), link
navigation, and a scripts-removed fallback check pass. The app remains free.
The launch copy and 22-second demo sequence are in `implementation-notes.md`.
BOSS explicitly approves all proposed work and publication on 2026-10-02.
Cloudflare deployment `d40473cc-fcc9-446a-a9f8-54caec315535` is live on both
domains. `/CLAUDE.md` and `/wrangler.jsonc` return 404. The new social preview
is live and matches the local export. Changes are pushed in draft PR #7 on
`codex/optional-support`. The notarized 1.1.3 DMG is uploaded to a GitHub draft
release; it is not public latest yet. The existing v1.1.2 remains the download.

- [x] 2026-10-02 DONE: BOSS approves the shared Initiator Works Ko-fi default
  change from $5 to $3. The saved settings and public form confirm $3. The $1
  minimum and one-time default remain. No transaction is submitted.
- [ ] 2026-10-02 Native acceptance: Computer Use times out for RedButtonQuit,
  Control Center, and TextEdit. Owner: Codex after native control is available,
  or BOSS for a brief manual check. An isolated render of the actual About view
  passes; it is not installed interaction evidence. Done when the installed menu/About support
  links render, the menu link reaches Ko-fi, and closing a blank TextEdit's last
  window quits TextEdit. Release stays pending until these checks pass. Full-
  display capture is rejected by automatic approval review because unrelated
  private content could appear; narrow menu-bar strips are accepted instead.
- [x] 2026-10-02 DONE: Website support changes, shared $3 default, and social
  preview are live. Publication is explicitly approved.
- [x] 2026-10-02 DONE: Launch posted in r/macapps' October App Pile thread:
  https://www.reddit.com/r/macapps/comments/1wuoav5/comment/pdettnn/
  Full text is verified while signed out. It uses the required PCP format and
  links to the existing v1.1.2 download through the website. Do not make another
  promotional post in that community before 2026-11-01T13:43:34Z. Edit this
  existing launch to add the real demo when ready.
- [ ] 2026-10-02 Publish v1.1.3 after native acceptance, then update the website
  version line, finish/merge draft PR #7, and verify a public DMG download.
  Publication is authorized; no further approval is required for this sequence.
  The real demo/trailer remains in the existing launch item above.
  Current traffic, app-specific support conversion, and earnings are unknown.

**Preview tooling defect — 2026-10-02:** `portmanager run redbuttonquit ...`
fails with `unsupported command: [...]`. The run parser's positional `command`
overwrites the subcommand field used by `main()` in the owning portmanager CLI.
Owner: portmanager project; this defect is already tracked in that project's
`OPEN-ITEMS.md`, so no duplicate obligation is filed. Fix by giving executable
arguments a different destination from the selected subcommand, then verify
`run`. No portmanager code
is changed here. The safe preview loads `.portmanager/ports.env` directly and
uses the claimed loopback port; sync and doctor pass. The site's preview
instructions now show that env-backed path.

**Historical setup (2026-08-19; current fee state is above):**
Page: **ko-fi.com/initiatorworks**, claimed 2026-08-19. Stripe connected,
Delaware ZIP matching the Stripe account, tips at 0% platform fee ("Get all of
Ko-fi" left off deliberately — turning it on costs 5% of every tip).

- The app's "Buy me a coffee" link is fixed in v1.1.0.
- The website's support section now links to it.
- The old `ko-fi.com/initiator1` never existed and shipped dead in v1.0.0.
  Anyone still on v1.0.0 has a dead link until they update.

**Tagging:** every RedButtonQuit surface uses
`https://ko-fi.com/initiatorworks?app=redbuttonquit` — About tab, website button,
README, and FUNDING.yml.

The `app=` tag reads back only through Ko-fi's GA4 integration, which sits behind
Ko-fi's advanced-feature tier — the timeannouncer session cites a Ko-fi help
article, "Connect your Ko-fi page to Google Analytics", stating Contributor is
required. **Corrected 2026-08-20: that tier is not a paid monthly account.** Ko-fi's own pricing page lists three levels — Ko-fi free (0%
on tips, "no advanced features"), Standard (5% service fee on all payment types,
unlocks the extra tools, no monthly charge), and Gold ($12/month, 0% fee). The
advanced tier is the "Get all of Ko-fi" toggle on the Payment settings tab, and
it costs 5% of every tip rather than a subscription. It is reversible.

**The "Get all of Ko-fi" toggle is ON** as of 2026-09-27, verified in BOSS's
Payment settings after a reload. His first attempt had not saved (it showed OFF on
2026-08-20); the second did. It costs 5% of tip income, and it enables the GA4
integration, so the `?app=` tags can now be read once GA4 is connected. GA4 itself
is not connected yet.

**GitHub Sponsors is not enabled, and the Sponsor button was silently dead.**
Found 2026-08-20 by the unstray session, confirmed here: `.github/FUNDING.yml`
said `github: [initiator1]`, but no Sponsors listing exists, so
`github.com/sponsors/initiator1` redirects to the profile page instead of
404ing and no button ever rendered. FUNDING.yml now uses `custom:` with the
tagged Ko-fi URL. `ko_fi:` was not used because it accepts a bare username only
and cannot carry the tag — swap to `ko_fi: initiatorworks` if the branded Ko-fi
entry in GitHub's Sponsor dropdown is worth more than the tag.

The dead `github.com/sponsors/initiator1` URL that unstray's README carried does
**not** appear anywhere in this repo. Checked 2026-08-20.

**The Sponsor button still does not render, and fixing FUNDING.yml was not
enough.** Verified 2026-08-20: GitHub has parsed the file —

    gh api graphql -f query='{ repository(owner:"initiator1", name:"redbuttonquit") { fundingLinks { platform url } } }'

returns `CUSTOM https://ko-fi.com/initiatorworks?app=redbuttonquit`. But the
public repo page contains no Sponsor affordance at all, while the control repo
`sindresorhus/awesome` renders "Sponsor this project" when fetched the same way.

Cause: the per-repo **Sponsorships** feature is switched off. GitHub accepts the
funding link and displays nothing — the same silent failure as the old `github:`
key, one layer higher up.

**RESOLVED 2026-08-20.** All four boxes are ticked (redbuttonquit, unstray,
timeannouncer, portmanager). Confirmed there is no API for it — the repos
endpoint exposes `has_issues`, `has_projects`, `has_downloads`, `has_wiki`,
`has_pages`, `has_discussions`, `has_pull_requests` and nothing for
sponsorships — so it was done through the browser.

**The Sponsor button needs BOTH halves, which is why this was confusing:** the
Sponsorships feature switched on, AND a funding link GitHub can parse. Either
one alone renders nothing and reports no error.

Verified against the public pages afterwards:

| repo | FUNDING.yml in tree | GitHub indexed it | Sponsor UI |
| --- | --- | --- | --- |
| redbuttonquit | yes, `2563fd29` | yes | renders |
| unstray | yes, `383b05f6` | yes | renders |
| timeannouncer | yes, `aa7fca3b` | not yet | not yet |
| portmanager | yes, `bde14022` | not yet | not yet |

**All four files exist and all four carry `custom:` with the right `?app=` tag.**
The two that do not render were both committed today; the two that render were
committed 2026-07-28 and 2026-08-12. **GitHub indexes FUNDING.yml on a lag.**
Nothing is needed from BOSS or from any session — the buttons appear when
GitHub catches up.

**Trap, recorded because this session fell into it.** GraphQL `fundingLinks`
returned empty for the two new files, and their settings pages read "Set up
sponsor button" rather than "Edit funding links". Both are GitHub-side symptoms
of the indexing lag, and this session read them as evidence the files were
missing — then told a sibling session to commit one. Caught by the timeannouncer
session before any damage. **Check `gh api repos/OWNER/REPO/contents/.github/
FUNDING.yml?ref=main` before concluding a funding file is absent.** GitHub's own
UI is not a witness to what is in the tree, and the likely "repair" — re-adding
the file with a `ko_fi:` key — silently drops the tag, because `ko_fi:` accepts
only a bare username.

Note `unstray` uses the scalar form `custom: https://...` while the others use
the array form. Both are valid. Do not normalise it.

**Still open:** the other three apps (unstray, timeannouncer, portmanager) are
being handled in their own sessions.

**`support@initiatorworks.com` delivers.** Confirmed by BOSS 2026-08-20. It is
printed in the Ko-fi auto thank-you message.

## redbuttonquit.com is still dead, and the app links to it

Preferences → About has a "Website" link to `https://redbuttonquit.com`, which
resolves to nothing until the Cloudflare move and the Pages deploy are done.
That link shipped dead in v1.0.0 and is still dead in v1.1.0. It was left in
deliberately rather than removed, because the site is built and waiting — but
it stays a broken promise until the domain move happens.

## Not visually verified

Checked on the installed app 2026-08-19: the History tab with one real entry,
after fixing a list style that painted blank grey rows. **Not** rendered and
looked at: the empty state, the Quits filter, and the Near misses filter — UI
automation could not switch the segmented control. Look at those before release.

Codex reported "Native History tab: inspected. Both connected displays:
checked." Its two screenshots show BOSS's desktop, not the app. Treat that
class of claim as unverified.

## App icon draws its own rounded tile

Noted 2026-08-19. `icon_512x512.png` is a dark rounded square drawn inside the
image. macOS already masks app icons to a squircle, so the artwork gets rounded
twice. House preference is a full-bleed single tile with no nested tile. Worth
regenerating before the next release; not urgent.

- [x] 2026-09-27 DONE: replaced with a layered close-button icon (AppIcon.icon plus a classic fallback set); see implementation-notes.md.

## Related, tracked elsewhere

- **Aria's domain watcher calls this domain healthy ("138 days left"). It is
  wrong** — it reads expiry only and cannot see a suspension or a manual-renew
  setting. The blind spot is recorded in
  `~/.hermes/douglas-ops/open-threads.md` and needs a resolution check
  (NS lookup) added to the watcher. Until then, no domain's "healthy" from
  that watcher means it resolves.
- **GitHub Sponsors enrollment** is deliberately parked: whether the income
  routes through INITIATOR LLC or personally is queued for the CPA call
  (Aria's ledger, Douglas's queue). `FUNDING.yml` is already committed; the
  Sponsor button appears by itself once enrollment completes.

## Repo state

`main` matches GitHub. The 2026-08-14 divergence (local pre-rebase copy vs
the rebased remote) was resolved by aligning to GitHub after saving the old
tip on a backup branch; content was identical, only hashes differed. The
v1.0.0 release artifact is untouched.

<!-- liveness-sweep:begin -->
## Liveness gaps

_This is what was true on 2026-09-21, not necessarily what is true now._ The section is maintained automatically and clears itself once every check is live. Everything outside these markers is left alone.

**Before acting on anything here, re-run the check.** Do not fix from this snapshot - another session may have already closed it.

    python3 ~/.claude/scripts/liveness-sweep.py .

- .github/FUNDING.yml:11, README.md:191, RedButtonQuit/UI/PreferencesView.swift:509, site/index.html:573: https://ko-fi.com/initiatorworks?app=redbuttonquit: Cloudflare blocks scripted checks; load it in a browser and confirm the page renders its form — do not match the title, it changes.
- site/index.html:13: https://redbuttonquit.com/ is dead.
- site/index.html:14: https://redbuttonquit.com/icon-512.png is dead.
- Tag v1.0.0 points to 27117d22758b5743a53d00b0228b45f2f2317434 and is not an ancestor of origin/main. It is a lightweight tag. A diff against this tag lists commits the tag already contains; find the real release point on the branch before using it. This tag carries a published GitHub release. Deleting or force-moving it converts the release to a draft. Leave it; tag the next release correctly.
<!-- liveness-sweep:end -->
