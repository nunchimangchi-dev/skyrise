# skyrise

A repeatable bootstrap for my dev environment: git, GitHub, tmux, fish, Bitwarden,
and [chezmoi](https://www.chezmoi.io/)-managed dotfiles. One source of truth,
applied the same way on a Linux server and a MacBook.

## Why this exists

I wanted a dev setup that's boring and reproducible, not hand-tuned one command at
a time and forgotten. This repo is the record of that setup, plus the scripts that
recreate it on a new machine. [`droppdd`](https://github.com/nunchimangchi-dev/droppdd)
is the first project scaffolded through this process, as a real test of it.

## Live status

A small dashboard tracks what's actually built vs. still pending, updated as each
piece lands: **https://box.tail2b3f17.ts.net/** (Tailscale-only — reachable from
devices on the tailnet, not the public internet). Source is in `dashboard/`.

## Bootstrapping a new host

```sh
git clone git@github.com:nunchimangchi-dev/skyrise.git
cd skyrise
./scripts/bootstrap.sh
```

Some steps are intentionally manual and the script will tell you when to run
them yourself:

- `gh auth login` — browser OAuth, needs a human to approve it.
- `bw login` — your Bitwarden master password never touches a script.

After bootstrap, dotfiles are applied with chezmoi:

```sh
chezmoi init --apply --source ~/Projects/skyrise/dotfiles
```

## Layout

```
scripts/install/   one script per tool, idempotent, called by bootstrap.sh
dotfiles/           chezmoi source: fish, tmux, git config
dashboard/           static site + data/progress.json (the status dashboard)
docs/DECISIONS.md   why things were chosen, not just what
```

## Starting a new project

Copy [`docs/NEW-PROJECT-SECURITY-BASELINE.md`](docs/NEW-PROJECT-SECURITY-BASELINE.md)
into the new repo as `docs/SECURITY-BASELINE.md` at scaffold time, not after
the fact — see droppdd's copy for a filled-in real example. This exists
because droppdd's first security review found that everything which turned
out fine did so by tooling-default accident, not a deliberate standard
applied at project start.

## Principles

- **No secrets in git.** Ever. Vault access is through Bitwarden CLI at runtime.
- **Nothing interactive gets automated away.** Auth flows that need a human stay
  manual on purpose.
- **Private by default.** The dashboard and any other host-local services sit
  behind Tailscale, not exposed publicly, unless there's a specific reason to.
