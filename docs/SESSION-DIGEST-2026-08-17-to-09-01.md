# Session digest: 2026-08-17 → 2026-09-01

Distilled from the ~2-week "skyrise" marathon session (transcript
`f00f7c72-690d-4dcb-b884-8c6f1773eda1.jsonl`, ~31.8k entries, 6 context
compactions) after it froze and terminated on 2026-09-01. This captures what
isn't already in `progress.json`, `docs/DECISIONS.md`, droppdd's `HANDOFF.md`,
or the memory files — the working method, the landmines, and the threads that
were still open when it died.

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

1. **Pre-launch / beta-launch strategy was never answered.** The user asked
   (2026-08-26, right before a compaction): *"What should the user story and
   experience look like before the website is even visited or the beta link
   has even been clicked? What are best practices and how do we launch this
   beta?"* — compaction ate it, the next window opened on a different topic,
   and it was never returned to. There is no beta-launch doc in droppdd. This
   is now partly Pitch's territory (strategy/calendar) but the pre-signin
   experience and Cloudflare Access gating are skyrise execution concerns.
2. **Two onboarding-audit items deferred by the user, still open:**
   (a) the Cloudflare Access allowlist decision — whether/when to open it
   beyond the owner; (b) a "look around before onboarding" read-only browse
   mode.
3. **droppdd-prod's `GEMINI_API_KEY` shares box's own CLI key** — deliberate
   speed tradeoff, flagged for a dedicated key. Note the meal-planning swap to
   Claude may have narrowed what still depends on it — worth re-checking what
   `GEMINI_API_KEY` on prod is actually used for now.
   (`droppdd_shared_gemini_key_tech_debt.md`)
4. **Attack-page AI assist** ("I only have a jump rope / I want to focus on
   abs — where does this fit?") — named as a real future feature, not built.
5. **`deepmerge-ts` CVE** in droppdd's lockfile — surfaced by an unrelated
   `npm install`, deliberately left out of scope, flagged for separate work.
6. **Discord server structure + X posting cadence** — offered to help draft,
   never picked up. Discord *installation* on this host was asked about and
   answered but never actioned.
7. **Mac `gh auth login`** for the career-ops repo needed re-running (invalid
   stored token) — may be stale by now; verify before relying on it.
8. **Phase 2 of Pitch's comms board** (on-demand write server, `board/` folder,
   15-min idle auto-stop, commit-per-move + batch-push) — designed with
   skyrise input, not yet built by Pitch as of the last message.
