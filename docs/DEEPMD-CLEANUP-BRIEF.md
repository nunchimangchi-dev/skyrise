# Brief: deep.md (DATABROKER.deep) — pre-publish hygiene pass

For whichever Claude Code session ends up working in `~/Projects/deep.md`
on the Mac. Paste this in as the opening brief once that session starts.

## Context

`deep.md` is DATABROKER.deep — a privacy automation platform targeting 85
data brokers across six opt-out strategy types (Go backend, WebSocket
agent, real-time operational dashboard). It's real, working code, but it
was built with heavy Gemini involvement across a span of model
generations, including earlier/weaker ones — expect inconsistency, dead
ends, and non-idiomatic patterns that a more disciplined build wouldn't
have. It currently lives Mac-local only: not properly git-tracked, never
pushed anywhere. It's not live/in production, so there's no harm in
something breaking here — this is a hygiene and publishing pass, not a
feature pass, and definitely not a rewrite.

Goal: get it safe and presentable, then a fresh public GitHub repo under
`nunchimangchi-dev`, MIT-licensed, matching the discipline already
established on `droppdd` and `skyrise` — no secrets in git, ever, a real
README, honest about how it was built.

## Priority 1 — secrets and sensitive data (do this first, before anything else)

- Search the entire tree for hardcoded credentials: API keys, tokens,
  passwords, connection strings, webhook URLs with embedded secrets.
- Check for `.env` or config files carrying real values — confirm they're
  gitignored, or that they don't need to exist at all going forward.
- This project automates against 85 real data-broker sites specifically —
  check hard for:
  - Any real personal data (names, addresses, emails, phone numbers) used
    as test/example data. This is a *privacy* tool; leaking real PII in
    its own repo would be a genuinely bad look, not just an oversight.
  - Login credentials, session tokens, or scraping API keys for the data
    broker sites themselves.
  - Any config referencing real personal accounts or identifiers.
- If a local git repo already exists with commit history (not just the
  working tree), secrets baked into *old* commits are just as exposed
  once pushed as current ones — check history, not just HEAD.
- When in doubt, treat it as sensitive and exclude it rather than risk it.

## Priority 2 — AI-generated cruft

- Remove dead code, commented-out blocks, and abandoned experiments left
  over from iterating across different tools/models.
- Remove leftover scratch files, prompt dumps, or tool-specific artifacts
  that aren't meant to be public — unless deliberately kept as a
  transparency choice (droppdd keeps its `GEMINI-*-PROMPT.md` files on
  purpose; that's a legitimate option here too, but should be a decision,
  not an accident).
- Clear out TODO/FIXME/placeholder text that reads as unfinished or
  embarrassing rather than as an honest open item.
- Confirm the code actually still runs and does what it claims — a
  project iterated across model generations may have half-finished
  features or a broken entry point somewhere.

## Priority 3 — repo hygiene

- A real `.gitignore` for a Go project on macOS: build artifacts/binaries,
  `.env`, any local DB/state files, `.DS_Store`.
- A real README: what it is, what it does, how to run it, honest about
  current state and how it was built.
- Add a LICENSE now (MIT — matches the call already made on droppdd)
  rather than leaving the repo unlicensed.
- Prefer a fresh `git init` with one clean, well-formed initial commit
  over preserving whatever local history already exists, given that
  history was never held to a "no secrets" standard from the start.

## Priority 4 — before the first push

- One more full repo-wide secret scan right before publishing (`gitleaks`
  or `trufflehog` if available; otherwise a careful manual grep for
  `key`, `secret`, `token`, `password`, `Authorization`, and
  suspicious-looking base64 strings).
- Confirm with the user before actually running `gh repo create` — public
  visibility and MIT license should be a stated, confirmed choice for
  this specific repo, not assumed from precedent.
- **Do not push without the user looking it over first.** This is
  explicitly the concern that prompted this whole cleanup pass — don't
  skip the human review step to save time.

## Explicit boundary

- This is a hygiene and publishing pass, not a feature pass. Don't change
  runtime behavior or logic unless something's broken or a secret needs
  to be swapped for an env-var reference.
- Don't create the GitHub repo or push anything without explicit
  confirmation from the user first.
