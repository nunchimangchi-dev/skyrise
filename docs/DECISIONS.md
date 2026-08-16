# Decisions

Short log of choices made while building this, and why — so future-me (or
anyone reading this repo) doesn't have to guess.

## skyrise repo is public

Concrete, current infrastructure/dotfiles work is worth more on a resume than a
private repo nobody can see. Secrets never go in git, so there's nothing public
that shouldn't be.

## Dashboard is served over Tailscale only

It's a personal build log with no reason to be internet-facing. The tailnet
already covers this box, a phone, and the MacBook, so that's the natural
audience. Rejected Cloudflare Tunnel for this specific use for that reason —
it's the right tool when something genuinely needs to be public.

## chezmoi over GNU stow or a plain script

The dotfiles need to reconcile real differences between the Linux box
(pacman, systemd) and macOS (Homebrew, launchd), not just symlink identical
files to two places. chezmoi's templating handles that from one source repo.

## Git commit identity uses GitHub's noreply email

`277221692+nunchimangchi-dev@users.noreply.github.com` instead of the real
iCloud address, set via `git config --global user.email`. Standard privacy
practice — keeps the real address out of public commit metadata without
changing anything on the GitHub account side.

## Interactive auth stays interactive

`gh auth login` and `bw login` are never run non-interactively or scripted with
stored credentials. They're the two places a human has to be at the keyboard,
by design.

## droppdd starts as a Next.js web app, not a native mobile app

Fastest path to something usable on a phone browser today. A native/Expo shell
can wrap it later if an installable app turns out to matter.

## Reboot verification confirmed, not just assumed

Rebooted `box` and walked `docs/POST-REBOOT-CHECKLIST.md` line by line: the
dashboard systemd --user service, tailscale serve, and tmux-continuum's
boot-restore of the pre-reboot `main` session (two windows, correct cwds) all
came back with zero manual intervention. Persistence claims don't count until
they've survived an actual reboot, not just a detach/reattach.
