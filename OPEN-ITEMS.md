# Open Items — RedButtonQuit

Durable ledger. Extracted 2026-08-16 from the accessibility/domain thread
before archiving it. The app itself is SHIPPED: v1.0.0 is live on GitHub,
notarized, verified by downloading from the public URL and checking the
notarization ticket survived the round trip.

## The domain: redbuttonquit.com is suspended and the fix did not take

State verified against the registry and the registrar on 2026-08-14:

- **Status: Suspended (Whois Verification), nameservers parked on
  `NS1/NS2.VERIFICATION-HOLD.SUSPENDED-DOMAIN.COM`.** Public DNS returns
  nothing. The domain has been dead since 2026-01-14.
- BOSS clicked Resend on 2026-08-13, received the mail, clicked the link, and
  got a success page. **The verification did not go through** — the registry
  record still reads 2026-01-14. The success page was a claim, not an outcome.
- Cause of the original failure: the registrant of record is the privacy proxy
  `redbuttonquit.com@respectmyprivacy.com`, so ICANN's January verification
  mail never reached a human.
- Storefront: **NearlyFreeSpeech.NET**, member account `6440-1F0BFCDF` (the
  registrar of record, PublicDomainRegistry, is wholesale-only — no direct
  accounts). Their member UI blocks direct URL jumps (referer guard); navigate
  from `/domains`.
- Misread hazard: whois prints `status: ACTIVE` for the `.com` registry
  itself. That line is not about this domain.

### Next action — BOSS sends this to NFSN support (draft ready, never sent)

> Subject: redbuttonquit.com still suspended after Whois verification
>
> My domain redbuttonquit.com is suspended for Whois Verification. The
> nameservers are still NS1/NS2.VERIFICATION-HOLD.SUSPENDED-DOMAIN.COM.
>
> On 2026-08-13 I used Resend, received the email, and clicked the
> verification link. The page confirmed success. More than 24 hours later the
> domain is still suspended, and public DNS returns nothing.
>
> The registrant contact is the privacy proxy
> redbuttonquit.com@respectmyprivacy.com.
>
> Please confirm whether the verification was received, and restore my
> nameservers.
>
> Please do not change the registrant contact. I plan to transfer this domain,
> and I must avoid a 60-day transfer lock.
>
> Member account: 6440-1F0BFCDF

### Standing warnings

- **Do not click Resend again** — it does nothing against a processing
  failure, and some registrars rate-limit it.
- **Never use NFSN's "Remove RespectMyPrivacy" action.** It looks like the
  obvious fix for a proxy eating mail. It changes the registrant of record,
  which is a Change of Registrant and can start a **60-day inter-registrar
  transfer lock**, pushing the Cloudflare move to mid-October. Real details go
  on the domain at Cloudflare, after the transfer, where privacy is free.

### The clock

Expires **2026-12-29**, renewal type **Manual** — it will not renew itself.
Estimated deletion 2027-03-14 if it lapses. The Cloudflare transfer solves
this: it adds a year (to 2027-12-29) and turns on auto-renew.

### Cloudflare move, once the domain is live again (every step is BOSS's login)

1. Cloudflare → Add a site → redbuttonquit.com → Free plan.
2. Copy the two nameservers Cloudflare assigns.
3. NFSN `/domains` → the domain → set nameservers to Cloudflare's two.
4. Wait for Cloudflare to report the zone **Active** (it emails).
5. NFSN: Unlock Domain.
6. NFSN: request the auth/EPP code.
7. Cloudflare → Domain Registration → Transfer Domains → enter the code.
   Up to 5 business days.

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
