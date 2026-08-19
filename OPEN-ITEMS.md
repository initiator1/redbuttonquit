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
