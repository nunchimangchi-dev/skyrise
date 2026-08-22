# Runbook: adding/removing a user for a public app

Applies to any app reachable through the `alwaysgivealwaysget.com` Cloudflare
Tunnel and gated by Cloudflare Access (currently: droppdd, unbrokerrdd).

**This is a stopgap, not the intended end state.** Neither app has its own
admin panel yet, so user management currently has to happen in Cloudflare's
dashboard instead of the app itself. That's a tracked requirement, not an
accepted permanent design — see "Known gap" below.

## How the gate works

Every request to `<app>.alwaysgivealwaysget.com` hits Cloudflare Access
before it ever reaches the app. Access checks the visitor's email against an
allowlist. If they're not on it, they never see the app - not even its own
login page. If they are, they get a one-time numeric code by email (no
password, no Cloudflare account needed on their end), then get forwarded to
the app itself, which may have its own separate login on top (droppdd does;
unbrokerrdd doesn't).

## Add a user

1. Go to `https://one.dash.cloudflare.com/` → select the `nunchimangchi`
   account → **Access** → **Applications**.
2. Click the app (`droppdd` or `unbrokerrdd`).
3. Open the **Policies** tab → edit the **Allow owner** policy.
4. Under **Include**, add a rule: **Emails** → the person's email address.
5. Save. Takes effect immediately, no deploy needed.

## Remove a user

Same path - open the policy, remove their email from the Include list, save.

## Known gap: no per-app admin panel

Relying on Cloudflare's dashboard for user management works but isn't the
real answer long-term:

- It's not visible or attributable to either app - someone looking at
  droppdd or unbrokerrdd has no way to see this exists.
- It doesn't demonstrate full-stack ownership of the access-control layer
  (L1-L7) the way an in-app admin view would.

**Backlog**: build a real admin view in each app (droppdd already has a user
table via its `AllowedEmail` model; unbrokerrdd has no user concept at all
yet and would need one added). Cloudflare Access should stay in place
either way as the outer gate - defense in depth, not a replacement for an
app-level admin panel.
