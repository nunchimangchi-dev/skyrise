# New-project security baseline (template)

Copy this into `docs/SECURITY-BASELINE.md` in any new project scaffolded
through skyrise's process, and fill in the status table at the bottom as the
project actually gets built. Don't skip the copy step because "we'll add it
later" — that's exactly the pattern that produced the gap this template
exists to close: droppdd's first security review (2026-08-21) found that
everything which turned out fine did so by tooling-default accident, not by
a deliberate standard applied at project start.

Two tiers: things every new project should have from its first commit, and
things that must be true before a project goes from tailscale-only/allowlisted
to actually public.

## Day-one baseline (every project, from the start)

- **Schema-validate every Server Action / API route input.** Client-side
  form constraints are UX, not security. Use Zod (or equivalent) at the
  boundary; never pass raw client input straight into a DB call or an LLM
  prompt.
- **Ownership is always session-derived, never client-supplied.** Every
  query scoped to a user must get `userId` from the server-side session, not
  from a client-passed field or URL param. The moment a route fetches an
  object *by ID* on behalf of a specific user, that route needs an explicit
  ownership check — don't assume "nothing exploits it yet" holds once new
  routes get added.
- **`.env*` gitignored from the first commit**, not added after a scare.
  Never expose anything sensitive to the client bundle (e.g. `NEXT_PUBLIC_*`)
  that isn't meant to be world-readable.
- **Lockfile committed, CI installs with `npm ci` (not `npm install`), and
  an `npm audit` gate runs in CI.** Set the severity bar deliberately (see
  droppdd's `ci.yml` for a real example of why "critical" beat "high" for
  that project at that time) — a gate nobody can ever pass gets ignored, not
  fixed.
- **ORM/parameterized queries only.** No raw SQL string-building. If a raw
  query ever becomes necessary, it gets a second pair of eyes, specifically
  for injection.

## Launch gates (required before going public / handling real money or PII at scale)

Not needed for a tailscale-only, allowlisted app used by a handful of known
people. Required before that changes.

- **Rate limiting** on auth, password/session flows, and any LLM/email/SMS
  endpoint.
- **Real staging environment** — a separate deploy, separate database, not
  "push to main and hope."
- **Privacy Policy + Terms**, with an actual acceptance flow.
- **GDPR baseline**: a real "export my data" and "delete my account" path,
  and consent-gating before any analytics library fires.
- **PII-shape review** on any newly-public-facing API/page response —
  specifically triggered the moment a feature shows one user data belonging
  to another user.
- **Backups that have actually been restore-tested**, not backups that
  merely run.
- **Error tracking / monitoring wired in before the first public user**, not
  after the first incident makes it obvious it's needed.

## `<project>`'s current status against this

| Item | Status |
|---|---|
| Zod validation on Server Actions | |
| Session-derived ownership scoping | |
| `.env*` gitignored | |
| Lockfile + `npm ci` + audit gate | |
| ORM-only queries | |
| Backup restore-tested | |
| Rate limiting | |
| Staging environment | |
| Privacy Policy + Terms | |
| GDPR export/delete | |
| Error tracking | |
| Known accepted risks | |
