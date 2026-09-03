# Session digest: 2026-08-17 → 2026-09-03

Sections 1–8: distilled from the ~2-week "skyrise" marathon session
(transcript `f00f7c72-690d-4dcb-b884-8c6f1773eda1.jsonl`, ~31.8k entries,
6 context compactions) after it froze and terminated on 2026-09-01.
Section 9: the continuation session that recovered from that crash and kept
going (2026-09-01 → 09-03). This captures what isn't already in
`progress.json`, `docs/DECISIONS.md`, droppdd's `HANDOFF.md`, or the memory
files — the working method, the landmines, and the open threads.

Canonical state still lives in those other files. This is the connective tissue.

---

## 1. What shipped

**Infrastructure (see `dashboard/data/progress.json` for the step-by-step):**
- Proxmox (`pveopti`) joined the tailnet with its own identity; `box` accepts
  OPNsense's advertised subnet routes.
- Physical switch trunking gap for VLAN20/30 diagnosed and fixed (was upstream
  Netgear, not Proxmox/OPNsense).
- Isolated VLAN20 LXCs on the same pattern: `web01` (nginx + cloudflared),
  `droppdd-prod`, `unbrokerrdd`, `droppdd-staging`. All public exposure via one
  Cloudflare Tunnel on `alwaysgivealwaysget.com`, zero port-forwarding.
- OPNsense firewall rule isolates VLAN20 from other internal networks while
  allowing internet egress; `config.xml` edited directly (backed up first)
  because the legacy rule wasn't visible to the REST API.
- Internal DNS on `int.nunchimangchi.com` via AdGuard rewrites; wildcard ACME
  DNS-01 cert (`*.int.nunchimangchi.com`) through OPNsense; dedicated certs for
  Home Assistant and the monitoring LXC on the same automation.
- Monitoring LXC 105 (Prometheus + Grafana + exporters), built by the `ops`
  peer session — see `home_infra_monitoring_lxc_built.md`.
- Cloudflare account security cleanup after "the troubles" (identity-theft
  incident): dead tunnels/tokens/Zero-Trust apps removed, compromised
  Super-Admin login stripped, proper 2FA on the login that holds the domains.
- Email forwarding fixed for `somuchcolor.com` (Porkbun) and
  `warren@nunchimangchi.com` (iCloud+ custom domain).

**droppdd (Next.js 16 keto/OMAD accountability beta — see its `HANDOFF.md`):**
- Multi-user beta: self-serve onboarding, username system, consent gate
  (`/welcome`), age/height/meal-preference fields with unit toggles.
- AI meal planning (pantry-driven + macro-driven), **later swapped Gemini →
  Claude permanently** (`@anthropic-ai/sdk`, commit `0493d16`).
- Peer-to-peer wager challenges (callsign *or* email), relative-metrics-only
  leaderboard, self-serve feedback board, `/why` page, branded `/auth-error`.
- Daily check-in redesign: Strength / Movement / Eating three-check model with
  a floating rest day; `/workouts` → `/attack` reference page, DB-backed
  6-exercise home-equipment Strength Protocol.
- Admin panel phase 2 + a full data-rights (export/delete) flow to back the
  Privacy Policy's promises.
- Cloudflare in front: Transform Rule, single Free-tier rate-limit rule, HSTS,
  Bot Fight Mode, Access (email-OTP) then re-evaluated.
- `/api/health` (unauthenticated, for uptime probes); beta cap 10 → 33.

**Other:**
- `nunchimangchi-dev.github.io` portfolio site (design passes via paid Gemini,
  human review before merge).
- `kali-pi-kit` (Raspberry Pi pentest kit) — built by the `builder` peer,
  **private** repo by deliberate exception (injection-capable hardware +
  attack methodology; different risk profile than infra/dotfiles).

---

## 2. The working method that worked

This is the part worth keeping. The session went well because of *how* it ran,
not just what got built.

- **Verify every claim by reading the actual code/data — never assume.**
  Repeatedly paid off: found a cross-user data leak by reading `page.tsx`
  before writing a prompt; caught `prisma/seed.ts`'s destructive `deleteMany()`
  by reading it in full before running it; empirically tested cascade-delete,
  `new Date("Aug 25")`, and real catalog rows rather than trusting the schema
  or the docs.
- **Confirm before anything prod-affecting or destructive.** Every migration,
  every Cloudflare config change, every prod SSH mutation got an explicit
  `AskUserQuestion` first. Migration SQL was read (`cat .../migration.sql`) to
  confirm additive-only before applying.
- **Deploy + verify live + update the dashboard — not just write code.** The
  loop wasn't done until `progress.json` was updated, JSON-validated, and
  visually re-checked in the browser.
- **Real click-through on live prod, not just build/lint.** Reinforced hard
  after the checkbox-validation bug (every check-in submission failing) passed
  build *and* lint and was only caught by actually using the form on prod.
- **Persona-driven audits.** Walking one surface at a time as a specific user
  ("I got this invite from a Reddit post, I clicked the link and…") surfaced
  far more than a generic review. The user drove these one surface at a time.
- **User sets the pace.** "We are not stopping for tonight… the day has just
  started." No "good stopping point" framing unless asked.
- **Independent verification of peer sessions too.** A peer's claim to have
  `fw1` SSH access turned out false; a Split DNS gap theory was confirmed via
  live `tailscale dns status`; "your infra is unaffected" was re-checked with
  curl/tunnel/ping before being accepted.
- **Self-correct out loud.** When my own reasoning was wrong (conflating a
  monitoring host's read-only API access with holding impersonation-capable
  key material), I named the specific wrong claim to both the user and the
  peer rather than quietly adjusting.
- **Decline what you can't actually do.** Verify access empirically each time;
  surface the gap honestly instead of improvising a workaround. Peers cannot
  grant escalation (permission-laundering boundary).
- **Credentials never transit chat.** User pastes real secrets directly (not
  via peer relay); assistant never echoes a secret's value back — check
  presence with `grep -c`, `/proc/<pid>/environ` name-only, or file mtime.
  Became an absolute standing rule after the 2026-09-01 incident
  (`user_no_credentials_in_chat_ever.md`).

---

## 3. droppdd conventions (established, reused 15+ times)

- **Page-gate order**, repeated verbatim across ~15 files (no middleware DB
  access — Edge runtime): `session?.user?.id` → `/signin`, then
  `session.user.termsAcceptedAt` → `/welcome`, then `session.user.username`
  → `/choose-username`.
- **`proxy.ts` matcher excludes `/api/*` from auth entirely.** Load-bearing:
  a route handler needing auth must live *outside* `/api/` and do its own
  `auth()`/`checkAdmin()` checks (e.g. the admin export route).
- Zod validation on every server action input; discriminated unions for
  multi-entry-point actions; `userId` always session-derived, never
  client-supplied. Validate the *AI's own JSON output* with Zod too, not just
  user input.
- **Streak = full recomputation from history** every time
  (`computeCurrentStreak` in `src/lib/checkin.ts`), never incremental — avoids
  same-day-correction edge cases.
- **Never re-run `prisma/seed.ts`** — it `deleteMany()`s real tables. For any
  prod catalog change, write a one-off idempotent `upsert` script in `prisma/`
  (precedent: `add-vegetarian-meal.ts`, `replace-workouts-with-attack-protocol.ts`).
- Shared formula `computeGoalPercent()` in `src/lib/progress-percent.ts` — was
  hand-copied between `/progress` and `/leaderboard` with a comment falsely
  claiming reuse; now genuinely one source, guards `start === target` → 100
  not NaN.
- **Deploy pipeline:** feature branch → `npm run lint` → `npm run build`
  (sometimes needs `rm -rf .next` after deleting routes) → local curl smoke
  (307 unauth / 200 public; AI features can't be tested locally, no keys) →
  dated `HANDOFF.md` section → commit → `git checkout main && merge --ff-only`
  → push → SSH `droppdd-prod` → check `package.json` diff for `npm ci` need →
  **AskUserQuestion before `prisma migrate deploy`** → `npm run build` →
  `export XDG_RUNTIME_DIR=/run/user/$(id -u) && systemctl --user restart droppdd`
  → internal curl verify → **real click-through on prod** → update
  `progress.json` (Python `json.load`/`dump`, `ensure_ascii=False`, then a
  separate validation load) → browser re-check → commit/push dashboard.

---

## 4. Gotchas / landmines (not already in memory files)

- **`formData.get()` returns `null` (not `undefined`) for an unchecked
  checkbox.** Zod `.optional()` alone rejects `null`; every optional/checkbox
  field needs `.nullable().optional()` together. This was the check-in bug that
  passed build+lint.
- **`"use server"` files can only export async functions**, never plain
  constants — `BETA_USER_LIMIT` in `admin/actions.ts` was a real build
  failure; it lives in its own `src/lib/beta-limit.ts`.
- **Cloudflare Access:** `decision: "allow"` + `include: everyone` *still*
  shows the login prompt. Only `decision: "bypass"` actually removes Access
  interception.
- **`systemctl --user` on droppdd-prod needs `XDG_RUNTIME_DIR=/run/user/$(id -u)`
  prefixed every time** — recurring dbus session-bus error otherwise.
- **`new Date("Aug 25")` silently returns year 2001.** Root cause of an admin
  panel date-corruption bug. Also: a field rename (`date` → `recordedAt`) must
  be chased to *every* consumer — an admin page still on the old field caused
  both wrong dates and non-chronological sort.
- **Next.js `react-hooks/purity` lint** flags inline `new Date()` / `Date.now()`
  during render. Hoist one `const now = new Date()` at the top of the server
  component.
- **Auth.js `AccessDenied`** (rejected sign-in) redirects to
  `/api/auth/error?error=AccessDenied` and renders `@auth/core`'s bare
  unstyled template unless `pages.error` is set in the NextAuth config. Traced
  through installed `@auth/core` source, not guessed.
- **Free Cloudflare plan specifics** (discovered via API errors, not docs):
  exactly 1 rate-limit rule; `mitigation_timeout` forced to 10s;
  `characteristics` must include `cf.colo.id` alongside `ip.src`; 5 WAF custom
  rules; 10 Transform Rules, no regex; Bot Fight Mode is domain-wide and can't
  be scoped; its PUT body must match the OpenAPI "default example" exactly
  (`cf_robots_variant: "off"`, not `"policy_only"`).
- **tmux + interactive Gemini:** a message containing `@path/to/file` triggers
  a file-autocomplete popup that eats the first Enter — always send a second
  bare Enter. `tmux capture-pane` intermittently returns empty; just re-run.
- **`pveopti` is root-on-the-hypervisor access.** Used it (with user
  confirmation of the host's legitimacy) to `pct exec` Tailscale SSH onto
  `droppdd-staging`. High privilege — scope narrowly, don't make it routine.
  (`Bash(ssh root@pveopti:*)` was added to the global allowlist 2026-09-03
  during the outage recovery below — kept, per the user.)
- **The VLAN20 app LXCs are 1 GB RAM — an on-box `next build` OOM-wedges
  them.** ct103 (droppdd-prod) runs the app fine on ~200 MB but a
  from-scratch `next build` (Next 16 + Turbopack) blew past 1 GB and
  thrashed the container unresponsive — a ~20 min prod outage on 2026-09-03.
  Before any on-box build, check `pct config <vmid> | grep memory`; if ~1024,
  `pct set <vmid> -memory 3072 -swap 1024` first and build with
  `NODE_OPTIONS="--max-old-space-size=2048"`. ct103 is now 3 GB
  (persisted). ct102/104 are likely still 1 GB.
  (`vlan20_lxc_build_oom.md`)
- **Gemini CLI can hang 30+ min with zero tool calls**, surviving model
  switches. After 2–3 stalls on one prompt, stop retrying and build from the
  spec directly. droppdd features from peer-wagers onward were built directly,
  not via Gemini. (See `gemini_cli_can_hang_indefinitely.md`.)

---

## 5. Real bugs found + the lesson each

| Bug | Lesson |
|---|---|
| `page.tsx` called `prisma.progress.findFirst()` with no `where` and no session check — every user saw whichever row was first | Read the data-access line before trusting a page is scoped |
| `Progress.currentStreak` was never incremented *anywhere* in the app's history — every streak frozen at 0, and `WEIGHT_TARGET` wagers could never resolve `WON` | A displayed number isn't a working feature; grep for where it's *written*, not just read |
| Admin panel showed weigh-in dates as year 2001, sorted non-chronologically | A changed field must be updated in every consumer |
| Privacy Policy promised export/deletion with zero admin capability to do it | Ship the mechanism with the promise, or don't make the promise |
| Every check-in submission silently failed validation; build + lint clean | Live click-through on prod is not optional |
| `GEMINI_API_KEY is missing…` and `Verify server credentials…` shown to end users (twice) | Ops/debug text leaking to users is a recurring bug class — sanitize catch-all error messages |

---

## 6. droppdd product canon (not obvious from code)

Most is in memory (`droppdd_omad_founder_proof`, `droppdd_wagers_flywheel`,
`droppdd_no_real_money_wagers`, `droppdd_meal_planning_philosophy`,
`droppdd_future_native_app_wishlist`). Additions:

- **The three-check streak model.** A green day = Strength (≥3 of 6 home
  exercises) *and* Movement (broad: walking/running/cycling/swimming, ~10k
  steps as the walking bar) *and* Eating (within window). Or a claimed **Rest
  Day** — a floating pass, once per rolling 7 days. Weight logging is part of
  check-in but never mandatory.
- **"No gym required" is founder-proven** (20 lb dumbbells + a pull-up bar).
  A request to add that line to the pitch became a full product redesign
  because 3 of 4 old workouts needed real gym equipment — the copy would have
  been a lie. Pattern worth remembering: *check the claim against the live
  product before writing marketing.*
- **Beta cap raised 10 → 33 on 2026-08-30**, ahead of a planned X /
  build-in-public push and using Discord as a testing pipeline. 33 is still
  deliberately small — "cap as a feature" / build-in-public framing holds.
- **AI meal planning is Claude now, not Gemini** — permanent swap.

---

## 7. Cross-session ecosystem (as of 2026-09-01)

| Session | Owns | Repo / dir |
|---|---|---|
| **skyrise** (this one) | Connective tissue across the body of work; the dashboard; droppdd's *execution* (app, Discord server setup, build tracking); ran the initial Reddit outreach | `~/Projects/skyrise` (public) |
| **pitch** | *All* external-comms strategy incl. droppdd's — calendar, copy, timing, voice, cross-platform sequencing. droppdd Reddit/Discord/X posts route through it | `~/Projects/pitch` → `github.com/nunchimangchi-dev/pitch` (private) |
| **career-ops** / "career-coach" | Personal detail, job search, LinkedIn, writing style/voice. Dislikes: em-dashes, AI word salad. Bridge is one-way (its replies don't reach here — relay via file/paste) | Mac |
| **ops** (was `network-ops-02`) | Network/infra: Cloudflare DNS, Tailscale Split DNS, TLS architecture, the monitoring LXC | infra docs, `network-inventory.md` |
| **builder** | `kali-pi-kit` | `github.com/nunchimangchi-dev/kali-pi-kit` (private) |

skyrise is **not** a co-owner of comms strategy anywhere, droppdd included —
it's a consulted input on product substance. This boundary was explicitly
drawn because the first draft of Pitch's prompt left it ambiguous.

Standing terminology rule (all sessions): never "homelab" or "home
infrastructure" — just "infrastructure" / "the stack". See `never_say_homelab.md`.

---

## 8. Open / dropped threads

Things that were genuinely left hanging when the session died:

1. **Pre-launch / beta-launch strategy.** The user asked (2026-08-26, before
   a compaction): *"What should the user story and experience look like
   before the website is even visited or the beta link has even been
   clicked? What are best practices and how do we launch this beta?"* — it
   was lost to compaction and never answered. PARTLY ADDRESSED 2026-09-03:
   Pitch now owns the channel plan, and the biggest concrete blocker (no
   self-serve on-ramp — a cold visitor hit a Google-login wall with no way
   to ask in) is fixed by `/request-access` (§9). Still no written
   beta-launch doc; still open: a current shareable demo asset (the
   screenshot set is a week stale) and the Discord server.
2. **Two onboarding-audit items deferred by the user:** (a) the Cloudflare
   Access allowlist decision — less pressing now that `/request-access` is
   the on-ramp regardless of Access state; (b) a "look around before
   onboarding" read-only browse mode — still open.
3. **droppdd-prod's `GEMINI_API_KEY` shares box's own CLI key** — deliberate
   speed tradeoff, flagged for a dedicated key. Note the meal-planning swap to
   Claude may have narrowed what still depends on it — worth re-checking what
   `GEMINI_API_KEY` on prod is actually used for now.
   (`droppdd_shared_gemini_key_tech_debt.md`)
4. **Attack-page AI assist** ("I only have a jump rope / I want to focus on
   abs — where does this fit?") — named as a real future feature, not built.
5. **`deepmerge-ts` CVE** in droppdd's lockfile — surfaced by an unrelated
   `npm install`, deliberately left out of scope, flagged for separate work.
6. **Discord server** — still not set up (no server, no invite link). Pitch
   owns X/Reddit/Discord *strategy* now; the Discord server *setup itself*
   is skyrise execution and remains undone. This is the top remaining gap
   for any droppdd growth channel.
7. **Mac `gh auth login`** for the career-ops repo needed re-running (invalid
   stored token) — may be stale by now; verify before relying on it.
8. **Pitch's comms board** (`board/` folder, on-demand write server, 15-min
   idle auto-stop, single allowlisted `/api/move` write path, typed confirm
   on the `approved` transition, commit-per-move + batch-push) — designed
   with skyrise input. RESOLVED 2026-09-02: Phase 1 (readable board) and
   Phase 2 (drag-to-advance server) both built and pushed to the pitch repo.

---

## 9. Continuation session (2026-09-01 → 09-03)

This session recovered from the crash above and kept working. Highlights
not already in `progress.json` / `HANDOFF.md` / memory:

**Recovery + housekeeping**
- Rebuilt context from repo + memory + git + a briefing from Pitch. Wrote
  this digest (§1–8).
- Beta fill count re-verified against prod: **still 1 / 33** (1 non-admin
  allowlisted, 1 user connected + onboarded, 0 pending invite requests, 1
  wager, 3 check-ins). `droppdd/docs/OUTREACH-LOG.md` denominator corrected
  10 → 33.
- `pitch` added to the dashboard as a minimal entry (private repo; no
  campaign content, scaffolding note only).

**Permissions overhaul** (`permissions_setup.md`)
- Global `~/.claude/settings.json` given a "Balanced" allow list (~99 rules:
  git inspection + normal writes + push, read tools, `npm run build/lint/ci`,
  `tailscale`/`gh` reads, `jq`/`python3 -c`, ssh to the app hosts) + a small
  deny list (`sudo`, force-push, `rm -rf /`). Anything not listed still
  prompts (`npx prisma migrate*`, `curl`, `npm install <pkg>`, etc.).
- **Root cause of the `git push` blocks:** a stale `autoMode.environment`
  block in the *global* settings described the `pitch` repo and asserted
  "this repo is never pushed" — the classifier acted on that everywhere.
  Cleared it. If classifier behaviour ever seems to act on wrong project
  context, check that key first.
- `Bash(ssh root@pveopti:*)` added 09-03 during the outage recovery; kept.

**droppdd features shipped to prod** (both verified end-to-end)
- **`/request-access`** — public, Turnstile-gated self-serve beta requests,
  feeding the existing `/admin` invite queue (still a manual human approve,
  no auto-provision, no email sent). `InviteRequest` schema: `invitedById`
  nullable + `source` (`self_request` | `peer_wager`). Layered defense:
  honeypot → Zod → Cloudflare Turnstile (canonical fail-closed siteverify:
  `success` + `action` + hostname allowlist) → dedupe with no enumeration →
  rolling-hour cap. Linked from `/signin`, `/auth-error` (AccessDenied), and
  `/why`. Turnstile widget created via the Cloudflare MCP (`challenges/widgets`,
  managed, `no_clearance`); public sitekey baked into `src/lib/turnstile.ts`,
  secret only in each env's `.env`. Local dev uses CF's always-passes test
  keypair (the code relaxes the action/hostname checks *only* for that
  known test secret).
- **AI meal-planning spend cap** — new `AiMealGeneration` meter table (one
  row per attempt that reaches the paid Anthropic call), `AI_MEAL_DAILY_PER_USER
  = 15` / `AI_MEAL_DAILY_GLOBAL = 250` in `src/lib/ai-limits.ts`, UTC-day
  reset. Was cost-unbounded before (only a 60s cooldown).
- **Eating personas** — `Progress.persona` (`KETO` / `OMAD` / `CALORIE` /
  `KETO_OMAD`, existing users default `KETO_OMAD`) + optional free-text
  `eatingTargetNote`. Drives *only* the daily "Eating" check-in prompt;
  Strength, Movement, streak math, wagers, leaderboard untouched. No
  number-logging — one self-reported checkbox per persona. The broadening
  from "OMAD + keto" was reviewed with Pitch first; **both sessions
  independently landed on the same guardrails** (persona 3 stays y/n or
  gets cut; persona 4 is a content proof story, not the outreach lead).
  Pitch's key point: the beta is empty because ~nobody's been asked, not
  because the pitch is narrow — so recruiting is the unblock, this is a
  parallel refinement.
- **Site copy reposition** (`cd6287e`) — Pitch drafted the replacement
  `/signin` + `/why` copy for the four personas, Warren approved, skyrise
  shipped it. New tagline "You already know what to eat. This is for
  actually doing it." (replaces "Aggressive Fitness & Fasting" / "NO
  EXCUSES…"); `/signin` grid now leads with the loop (CHECK-IN / WAGERS /
  STREAK / LEADERBOARD); `/why` gets a method-neutral insert + explicit
  "no food diary, no macro math" moat line. Clean split: Pitch owns the
  words, skyrise ships them. Pitch's "real-money in /why" flag was a
  misread — the page never said that. AI meal-planner persona-awareness
  still the outstanding fast-follow.
- All migrations additive; each deployed staging → prod under a migration
  confirm.

**Prod outage (2026-09-03, ~20 min)** — see §4. The prod-deploy `next build`
OOM-wedged the 1 GB `droppdd-prod` LXC. Recovered via `pveopti`: raised
ct103 to 3 GB, rebooted, rebuilt with a Node heap cap, restarted. No data
loss (migrations had already applied; additive). Landmine + procedure now
in §4 and `vlan20_lxc_build_oom.md`.

**Misc**
- `shush` (macOS pre-call "quiet the machine" script from the career-coach
  session) saved into `dotfiles/dot_local/bin/executable_shush`,
  chezmoi-managed, macOS-guarded via a new `dotfiles/.chezmoiignore`.
  Rationale in `DECISIONS.md`. Purpose: confidence going into a call that
  nothing local is lurking (camera/mic held by Zoom, a notification
  mid-share, a resource hog).

**Cross-session ecosystem note:** `network-ops-02` → renamed `ops`;
`career-coach` bridge is still one-way (relay replies via file/paste).
