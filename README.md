# Hermes Control Interface

A self-hosted web dashboard for the [Hermes AI agent](https://github.com/NousResearch/hermes-agent) stack. Browser-based terminal, file explorer, session management, cron scheduling, token analytics, and multi-agent administration — all behind a password gate.

**Status:** v3.0.0 — Production-ready (revamp/v2 branch)
**Stack:** Vanilla JS + Vite · Node.js · Express · WebSocket · xterm.js

---

## Features

### Pages (7 pages + File Explorer)

**Home** — System overview: CPU/RAM/Disk/Uptime, agent status (model, provider, gateway, platforms), per-profile gateway status, token usage (7d)

**Agents** — Agent list with create/clone/delete/switch. Gateway start/stop per profile.

**Agent Detail** — 6 tabs per agent:
- **Dashboard** — Identity, API keys, gateway status, token usage
- **Sessions** — List, search, rename, delete, export, resume in CLI
- **Gateway** — Start/stop/restart, real-time logs, systemd service management
- **Config** — 13 categories, 80+ settings, structured form + raw YAML
- **Memory** — Dynamic provider panel (built-in, honcho, external)
- **Cron** — List/create/pause/resume/run/remove jobs with schedule presets and 17 delivery targets

**Usage & Analytics** — Full token breakdown: time range (1d/7d/30d/90d), agent filter, per-model, per-platform, top tools

**Skills** — Installed skills list with category, source, trust level

**Maintenance** — Doctor diagnostics, dump, update, user management, auth providers, audit log

**File Explorer** — Split view: directory tree (left) + text editor (right). Read and save files.

### Terminal
- Real PTY shell via node-pty + xterm.js over WebSocket
- Touch controls (↑↓␣↵) for mobile
- Fullscreen toggle
- Auto-cleanup: Ctrl+C → clear → command flow

### Notifications
- Bell icon with unread count badge
- System alerts (disk/RAM/CPU)
- Action notifications (gateway, sessions, users, profiles)
- Persistent storage (~/.hermes/hci-notifications.json)

### Theme
- Dark mode: `#0b201f` background, `#dccbb5` foreground, `#7c945c` accent
- Light mode: `#e4ebdf` background, `#0b201f` foreground, `#2e6fb0` accent
- Toggle via header button, persisted in localStorage

### Security
- Multi-user auth (admin + viewer roles)
- bcrypt password hashing
- CSRF tokens on all mutating requests
- Conditional Secure cookie flag (HTTPS detection)
- WebSocket origin verification
- Input sanitization (strict regex on all user inputs)
- Path traversal prevention
- Rate limiting on login

---

## Quick Start

```bash
# Clone
git clone https://github.com/xaspx/hermes-control-interface.git
cd hermes-control-interface

# Install
npm install

# Configure
cp .env.example .env
# Edit .env with HERMES_CONTROL_PASSWORD and HERMES_CONTROL_SECRET

# Build frontend
npx vite build

# Start
npm start
# Or with systemd (recommended for production)
# See docs/DEPLOY.md
```

Access at `http://localhost:10272` (or your configured PORT).

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `HERMES_CONTROL_PASSWORD` | Yes | Login password |
| `HERMES_CONTROL_SECRET` | Yes | CSRF + internal auth secret |
| `PORT` | No | Server port (default: 10272) |
| `HERMES_CONTROL_HOME` | No | Hermes home directory (default: ~/.hermes) |
| `HERMES_CONTROL_ROOTS` | No | Allowed file explorer roots (JSON array) |
| `HERMES_PROJECTS_ROOT` | No | Projects directory root |

## Architecture

```
src/                    # Vite source (ES modules)
├── index.html          # Entry point
├── js/main.js          # App logic (~2400 lines)
├── css/
│   ├── theme.css       # Color palette (dark/light)
│   ├── layout.css      # Topbar, modals, dropdowns
│   └── components.css  # Cards, tables, forms, editor
└── assets/             # SVG icons

dist/                   # Vite build output (served by Express)
server.js               # Express + WebSocket + PTY + API
auth.js                 # Multi-user auth system
```

## Development

```bash
# Edit source in src/
# Build
npx vite build
# Restart server
kill $(lsof -t -i:10274) 2>/dev/null; sleep 1; nohup node server.js &>/dev/null & disown
```

## API Endpoints

60+ endpoints covering auth, sessions, profiles, gateway, cron, config, memory, skills, file operations, system health, token insights, and more. See `docs/API.md` for full reference.

## Security

See `docs/SECURITY-AUDIT.md` for the full security audit report. Score: 7.2/10.

## Screenshots

### Home
![Home](docs/screenshots/01-home.png)

### Agents
![Agents](docs/screenshots/02-agents.png)

### Usage & Analytics
![Usage](docs/screenshots/03-usage.png)

### Skills Marketplace
![Skills](docs/screenshots/04-skills.png)

### Maintenance
![Maintenance](docs/screenshots/05-maintenance.png)

### File Explorer
![Files](docs/screenshots/06-files.png)

### Agent Detail
![Agent Detail](docs/screenshots/07-agent-detail.png)

### Cron Jobs
![Cron](docs/screenshots/08-cron-tab.png)

---

## License

MIT

## Credits

Built for the [Hermes Agent](https://github.com/NousResearch/hermes-agent) ecosystem by [Nous Research](https://nousresearch.com).
