# Security

This dashboard exposes a real terminal and file editor. Treat it like root access, because that is effectively what it is.

## Security model

- UI access requires login
- Auth cookies are HMAC-protected
- Internal cron endpoints require `HERMES_CONTROL_SECRET`
- The server refuses to start if `HERMES_CONTROL_PASSWORD` or `HERMES_CONTROL_SECRET` are missing

## Hard rules

- Do not commit `.env`
- Do not commit `node_modules`
- Do not hardcode machine-specific paths
- Do not expose the raw port to the internet without TLS and a reverse proxy

## Recommended production setup

- Bind the app to localhost
- Put nginx or Caddy in front of it
- Terminate TLS at the proxy
- Restrict access by IP or VPN if possible
- Use a unique strong password and secret per deployment

## Things to audit before publishing

- Password handling
- Cookie flags
- WebSocket auth
- Internal API auth
- Any path that writes to disk
- Any hardcoded path or secret left in source
