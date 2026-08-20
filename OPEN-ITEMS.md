# Open Items — RedButtonQuit

Durable ledger. Extracted 2026-08-16 from the accessibility/domain thread
before archiving it. The app itself is SHIPPED: v1.0.0 is live on GitHub,
notarized, verified by downloading from the public URL and checking the
notarization ticket survived the round trip.

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

### The Cloudflare move is now unblocked — every step is BOSS's login

1. Cloudflare → Add a site → redbuttonquit.com → Free plan.
2. Copy the two nameservers Cloudflare assigns.
3. NFSN `/domains` → the domain → set nameservers to Cloudflare's two.
4. Wait for Cloudflare to report the zone **Active** (it emails).
5. NFSN: Unlock Domain.
6. NFSN: request the auth/EPP code.
7. Cloudflare → Domain Registration → Transfer Domains → enter the code.
   Up to 5 business days.

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
Ko-fi's advanced-feature tier. **Corrected 2026-08-20: that tier is not a paid
monthly account.** Ko-fi's own pricing page lists three levels — Ko-fi free (0%
on tips, "no advanced features"), Standard (5% service fee on all payment types,
unlocks the extra tools, no monthly charge), and Gold ($12/month, 0% fee). The
advanced tier is the "Get all of Ko-fi" toggle on the Payment settings tab, and
it costs 5% of every tip rather than a subscription. It is reversible.

Not independently confirmed: whether GA4 specifically is one of the features
behind that tier. Ko-fi's pricing page says "advanced features" without naming
it. Do not tell BOSS he can see click counts today — he cannot, the toggle is off.

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

**BOSS's action, web-only, no API exists for it:** each repo's Settings →
General → Features → tick **Sponsorships**. Four repos, four ticks
(redbuttonquit, unstray, timeannouncer, portmanager). Found by the timeannouncer
session, reproduced here.

**Still open:** the other three apps (unstray, timeannouncer, portmanager) are
being handled in their own sessions.

**Verify before relying on it:** `support@initiatorworks.com` is printed in the
Ko-fi auto thank-you message. Confirm it actually delivers mail.

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

### The Cloudflare move is now unblocked — every step is BOSS's login

1. Cloudflare → Add a site → redbuttonquit.com → Free plan.
2. Copy the two nameservers Cloudflare assigns.
3. NFSN `/domains` → the domain → set nameservers to Cloudflare's two.
4. Wait for Cloudflare to report the zone **Active** (it emails).
5. NFSN: Unlock Domain.
6. NFSN: request the auth/EPP code.
7. Cloudflare → Domain Registration → Transfer Domains → enter the code.
   Up to 5 business days.

### Standing warning — still live

**Never use NFSN's "Remove RespectMyPrivacy" action.** It changes the
registrant of record, which is a Change of Registrant and can start a
**60-day inter-registrar transfer lock**. Real details go on the domain at
Cloudflare, after the transfer, where privacy is free.

## The website: none exists, and there is a placement decision already made

Checked 2026-08-19. There is no site, no landing page, and no `docs/` branch
in this repo or anywhere under `/Users/db1/Projects`. Nothing was ever
started.

A prior decision already covers where this app is presented:
`ai-initiator/PRODUCT-LAB-PLACEMENT-RULE.md` places RedButtonQuit on the
AI-Initiator Product Lab under **More Apps**, linking to GitHub releases.
`domains/INVENTORY.md` lists redbuttonquit.com among the domains that are
"paid for and pointing nowhere". Building a standalone site is a live
question against that rule, not a blank slate — decide the two together.

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
