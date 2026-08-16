# Post-reboot verification

Run after rebooting `box`, to confirm everything auto-recovers with no manual steps.

```sh
# Dashboard back up on its own (systemd --user + linger)
systemctl --user status skyrise-dashboard.service --no-pager
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/

# Tailscale serve still publishing it
tailscale serve status

# tmux auto-started at boot and continuum restored the pre-reboot session
tmux list-sessions
tmux list-windows -t main
```

Expected: a `main` tmux session with two windows, `editor` (cwd
`~/Projects/skyrise`) and `droppdd` (cwd `~/Projects/droppdd`) — created just
before the reboot specifically to prove `tmux-continuum`'s boot-restore works,
not because that layout matters on its own.

If `tmux list-sessions` comes back empty, check
`systemctl --user status tmux.service` first — most likely cause is the unit
didn't fire, not that the restore itself failed.
