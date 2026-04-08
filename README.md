# Hermes Control Interface

Hermes Control Interface is a web dashboard for the Hermes stack.
It provides a browser-based terminal, file explorer, session overview, cron status, system metrics, and a small agent/status dashboard.

## What it expects

- Node.js 20+
- npm
- A Hermes installation available on the same machine
- `hermes` on your PATH
- `HERMES_CONTROL_PASSWORD` and `HERMES_CONTROL_SECRET` in your environment

## Quick start

```bash
cd hermes-control-interface
cp .env.example .env
npm install
npm start
```

Then open `http://127.0.0.1:10272`.

## Configuration

See `docs/CONFIG.md` for every supported setting.
Security and exposure notes are in `docs/SECURITY.md`.
Install and first-run instructions are in `docs/INSTALL.md`.

## Default behavior

- The dashboard binds to `PORT=10272` by default
- Auth is required for the UI and WebSocket session
- Explorer roots default to the repo parent directory and `HERMES_HOME`
- The terminal panel runs the real local shell in the repo root

## Repo layout

- `server.js` - Express server, auth, websocket bridge, shell session, APIs
- `website/` - frontend assets
- `docs/` - setup, config, and security docs
- `.env.example` - sample runtime config

## Notes

This repo is meant to be portable. It should not depend on `/root/projects/...` or any other hardcoded machine path.
