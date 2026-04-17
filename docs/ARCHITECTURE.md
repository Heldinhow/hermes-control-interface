# HCI Architecture Document
> **Internal only** — living document for codebase auditing, cleanup tracking, and development reference
> 
> Last updated: 2026-04-17 (v3.3.0+ PR #24/#25)
> Status: **ACTIVE** — Post-PR merge phase

---

## Table of Contents
1. [Overview](#1-overview)
2. [Frontend Architecture](#2-frontend-architecture)
3. [Backend Architecture](#3-backend-architecture)
4. [Pages & Features Inventory](#4-pages--features-inventory)
5. [API Reference](#5-api-reference)
6. [Security Model](#6-security-model)
7. [Known Issues & Tech Debt](#7-known-issues--tech-debt)
8. [Audit Checklist](#8-audit-checklist)

---

## 1. Overview

### Project Info
| Field | Value |
|-------|-------|
| **Name** | Hermes Control Interface (HCI) |
| **Type** | Web-based control panel / dashboard overlay for Hermes Agent |
| **Location** | `/root/projects/hci-staging/` (active dev) |
| **Staging** | `agent2.panji.me` — branch: `dev` |
| **Production** | `agent.panji.me` — branch: `main` (v3.3.2 FINAL) |
| **Frontend** | Vanilla JS (~5045 lines in `src/js/main.js`) + Vite build |
| **Backend** | Node.js/Express (~3768 lines in `server.js`) |
| **Auth** | Session cookie + bcrypt + RBAC |

### Architecture Summary
```
┌─────────────────────────────────────────────────────┐
│                    BROWSER                          │
│  ┌──────────────────────────────────────────────┐   │
│  │  HCI Web UI (Vanilla JS SPA)                 │   │
│  │  src/js/main.js  ──build──>  dist/          │   │
│  │  src/index.html                              │   │
│  └──────────────────┬───────────────────────────┘   │
│                     │ HTTP/WebSocket                  │
└─────────────────────┼────────────────────────────────┘
                      │
┌─────────────────────┼────────────────────────────────┐
│                     ▼                                 │
│  ┌──────────────────────────────────────────────┐   │
│  │  HCI Server (Express.js)                     │   │
│  │  server.js  — port 10272                     │   │
│  │  ├── Auth (login, session, RBAC)             │   │
│  │  ├── API routes (~50 endpoints)              │   │
│  │  ├── WebSocket (terminal I/O)                │   │
│  │  └── Static file serving (dist/)             │   │
│  └──────────────────┬───────────────────────────┘   │
│                     │ execFile/spawn                  │
│         ┌───────────┼───────────┐                     │
│         ▼           ▼           ▼                     │
│   ┌─────────┐ ┌──────────┐ ┌────────┐                │
│   │ Hermes  │ │ hermes   │ │ System │                │
│   │ CLI     │ │ profiles │ │ tools  │                │
│   └─────────┘ └──────────┘ └────────┘                │
│                     VPS                               │
└─────────────────────────────────────────────────────┘
```

### Tech Stack
| Layer | Technology |
|-------|------------|
| Frontend | Vanilla JavaScript (no framework), XTerm.js |
| Build | Vite |
| Backend | Node.js, Express.js |
| Auth | bcrypt, express-session (or custom cookie) |
| Rate Limiting | express-rate-limit |
| Security Headers | helmet.js |
| Terminal | node-pty (PTY), xterm.js |
| Templating | None (string concatenation + innerHTML) |

---

## 2. Frontend Architecture

### File Structure
```
src/
├── index.html        # SPA shell — login overlay, app header, page mount points (123 lines)
├── css/
│   ├── components.css  # Component styles (1886 lines)
│   ├── layout.css      # Layout styles
│   └── theme.css       # Theme variables + dark/light
└── js/
    ├── main.js               # Monolith (~5045 lines) — ALL frontend logic
    └── chat-render-utils.mjs # Chat renderer normalization (9 lines, PR #24)

lib/
└── session-list.js           # Session merge logic (103 lines, PR #25)

test/
├── session-list.test.js      # Session merge tests (86 lines)
└── chat-render-utils.test.js # Renderer normalization tests (48 lines)

dist/                # Vite build output (gitignored)
├── index.html
├── assets/
│   └── index-[hash].js
│   └── index-[hash].css
```

### State Management
```javascript
// Global state object (line ~16 in main.js)
const state = {
  page: 'home',
  theme: localStorage.getItem('hci-theme') || 'dark',
  user: null,           // { username, role }
  csrfToken: null,
  chatSidebarOpen: localStorage.getItem('hci-chat-sidebar') !== 'false',
};
```

### Router
```javascript
navigate(page, params = {})  // Hash-based routing (#home, #agents, etc.)
loadPage(page, params)      // Async page loader — switch case for each page
```

### Exposed Globals (for external access / plugin compat)
```javascript
window.loadHome
window.loadAgents
window.loadChatSession
window.loadSkills
window.loadLogs
window.loadCronJobs
window.loadUsage
// ... more
```

---

## 3. Backend Architecture

### File Structure
```
server.js              # ~3768 lines — all Express routes, middleware, WS handler
lib/
└── session-list.js    # Session merge logic (PR #25) — parse CLI output + state.db merge
├── Middleware (auth, CSRF, RBAC, rate limit, helmet)
├── Auth routes (/api/auth/*)
├── User routes (/api/users/*)
├── Profile routes (/api/profiles/*, /api/gateway/*)
├── Session routes (/api/sessions/*)
├── Skill routes (/api/skills/*)
├── File routes (/api/explorer, /api/file)
├── Terminal routes (/api/terminal/*)
├── Chat routes (/api/chat)
├── Cron routes (/api/cron/*)
├── Config routes (/api/config/*, /api/memory/*)
├── Usage routes (/usage, /api/usage/*)
├── System routes (/api/doctor, /api/dump, /api/update, /api/backup, /api/hci-restart)
├── Layout routes (/api/layout)
├── Avatar routes (/api/avatar/*)
├── Notification routes (/api/notifications/*)
├── Insights routes (/api/insights/*)
├── Hermes Cron routes (/api/hermes-cron/*)
└── WebSocket handler (/ws)
```

### Key Server Config
```javascript
PORT = 10272 (default)
AUTH_COOKIE = 'hermes...auth'
CONTROL_HOME = ~/.hermes
CONTROL_STATE_DIR = ~/.hermes/control-interface
```

### Shell Execution
```javascript
// Non-blocking shell (line 17-26)
function shell(cmd, timeout = '8s') {
  execFile('bash', ['-lc', `timeout ${timeout} ${cmd} 2>&1`], ...)
}

// Safer hermes CLI exec (line 29-38)
function execHermes(args, timeout = 30000) {
  execFile('hermes', args, ...)
}
```

---

## 4. Pages & Features Inventory

### Navigation Structure
```html
<a href="#home" class="nav-link active" data-page="home">Home</a>
<a href="#agents" class="nav-link" data-page="agents">Agents</a>
<a href="#usage" class="nav-link" data-page="usage">Usage</a>
<a href="#skills" class="nav-link" data-page="skills">Skills</a>
<a href="#chat" class="nav-link" data-page="chat">Chat</a>
<a href="#logs" class="nav-link" data-page="logs">Logs</a>
<a href="#maintenance" class="nav-link" data-page="maintenance">Maintenance</a>
<a href="#files" class="nav-link" data-page="files">Files</a>
```

### Page Detail Matrix

| # | Page | Route | Loader | Lines | Purpose | Auth | RBAC |
|---|------|-------|--------|-------|---------|------|------|
| 1 | **Home** | `#home` | `loadHome()` | ~730-802 | System overview, metrics, quick actions | ✅ | any |
| 2 | **Agents** | `#agents` | `loadAgents()` | ~966-1022 | List Hermes profiles, status, create/delete | ✅ | any |
| 3 | **Agent Detail** | `#agent-detail` | `loadAgentDetail()` | ~1051-1075 | Per-agent: skills, sessions, config, gateway | ✅ | any |
| 4 | **Usage** | `#usage` | `loadUsage()` | ~2226-2300 | API usage analytics, cost tracking | ✅ | any |
| 5 | **Skills** | `#skills` | `loadSkills()` | ~2545-2720 | Browse/install/update/uninstall skills | ✅ | any |
| 6 | **Maintenance** | `#maintenance` | `loadMaintenance()` | ~2780-2830 | HCI restart, update, health, doctor, backup | ✅ | admin |
| 7 | **Files** | `#files` | `loadFileExplorer()` | ~3881-3960 | Browse `~/.hermes`, view/edit files | ✅ | any |
| 8 | **Chat** | `#chat` | `loadChat()` | ~233-500 | Hermes CLI chat, session management | ✅ | any |
| 9 | **Logs** | `#logs` | `loadLogs()` | ~4145-4465 | Real-time Hermes/system logs | ✅ | any |
| - | **Users** | (none) | (MISSING) | - | User management (backend exists, frontend missing) | ✅ | admin |

### Page Deep Dives

#### 4.1 Home (`loadHome`)
**Lines:** ~733-802
**Purpose:** Dashboard overview with system metrics and quick actions
**Contents:**
- System metrics (CPU, memory, disk, uptime)
- Hermes Agent version & status
- Active profile indicator
- Quick action buttons: Terminal, Refresh
- HCI Info panel (version, environment)
- Auth status panel (login/logout controls)
**Issues:** None known

#### 4.2 Agents (`loadAgents`)
**Lines:** ~966-1022
**Purpose:** Manage Hermes profiles/agents
**Contents:**
- Profile list with status badges (running/stopped)
- Per profile: name, model, alias, active indicator
- Actions: Open (detail), Set Default, Delete
- Create Agent button
**Issues:** None known

#### 4.3 Agent Detail (`loadAgentDetail`)
**Lines:** ~1051-1075 (wrapper), ~1077+ (tabs)
**Purpose:** Deep management of individual agents
**Contents:**
- Tab navigation: Overview, Skills, Sessions, Config, Gateway
- Overview: profile info, status, model
- Skills tab: installed skills list, check updates, install/uninstall
- Sessions tab: session history, resume, rename, export, delete
- Config tab: `hermes config` view/edit
- Gateway tab: start/stop/restart/status
**Issues:** None known

#### 4.4 Usage (`loadUsage`)
**Lines:** ~2226-2300
**Purpose:** API usage analytics and cost tracking
**Contents:**
- Date range selector (days)
- Usage charts/tables
- Per-profile breakdown
- Cost estimation
**Issues:** None known

#### 4.5 Skills (`loadSkills`)
**Lines:** ~2545-2720
**Purpose:** Hermes skills hub integration
**Contents:**
- Browse skills from hub (paginated)
- Search skills
- Inspect skill (preview)
- Install / Uninstall / Update
- Installed skills list per agent
**Issues:** Modal overlay for install confirmation could be improved

#### 4.6 Maintenance (`loadMaintenance`)
**Lines:** ~2780-2830
**Purpose:** HCI system operations
**Contents:**
- HCI Restart button
- HCI Update button
- Health Check button → runs `/api/system/health`
- Doctor diagnose → runs `/api/doctor`
- Auto-fix button
- Dump generation → `/api/dump`
- Hermes Update → `/api/update`
- Backup create → `/api/backup`
**Issues:** Admin-only page but no nav protection (relies on backend RBAC)

#### 4.7 Files (`loadFileExplorer`)
**Lines:** ~3881-3960
**Purpose:** File browser for `~/.hermes`
**Contents:**
- Directory tree sidebar (or overlay on mobile)
- File list with type icons
- File view/edit capability
- Path navigation (breadcrumb)
- Root button, Refresh button
**Issues:** Mobile responsive overlay pattern needs testing

#### 4.8 Chat (`loadChat`)
**Lines:** ~233-500
**Purpose:** In-browser Hermes CLI chat
**Contents:**
- Session sidebar (chat history)
- New Chat button
- Chat messages area (streaming display)
- Tool call display (expandable)
- Message input
- Status bar (model, token count)
- Profile selector dropdown
**Known bugs (fixed):**
- `--continue ""` vs `--continue` behavior
- Session ID extraction (old vs new format)
**Issues:** Session management complexity

#### 4.9 Logs (`loadLogs`)
**Lines:** ~4145-4465
**Purpose:** Real-time system/Hermes logs
**Contents:**
- Journalctl log viewer
- Filter controls (profile, level)
- Auto-scroll
- Search/filter
**Issues:** None known

#### 4.10 Users (MISSING)
**Backend:** `/api/users`, `/api/users/:username`, `/api/audit`
**Frontend:** No `loadUsers()` function, no nav link
**Status:** 🔴 **Missing feature** — backend exists but no UI

---

## 5. API Reference

### Authentication Flow
```
1. GET /api/auth/status         → { first_run: bool }
2. POST /api/auth/setup          → create admin (if first_run)
3. POST /api/auth/login          → sets cookie, rate-limited (5/15min)
4. GET  /api/auth/me             → { user, csrfToken }
5. POST /api/auth/change-password
6. POST /api/auth/logout         → clears cookie
```

### Endpoint Summary (~94 endpoints)

| Method | Endpoint | Auth | RBAC | Purpose |
|--------|----------|------|------|---------|
| GET | `/api/session` | ❌ | - | Auth state check |
| POST | `/api/auth/login` | ❌ | - | Login |
| POST | `/api/auth/logout` | ✅ | any | Logout |
| POST | `/api/auth/change-password` | ✅ | any | Change password |
| GET | `/api/users` | ✅ | admin | List users |
| POST | `/api/users` | ✅ | admin | Create user |
| DELETE | `/api/users/:username` | ✅ | admin | Delete user |
| POST | `/api/users/:username/reset-password` | ✅ | admin | Reset password |
| GET | `/api/audit` | ✅ | admin | Audit log |
| GET | `/api/profiles` | ✅ | any | List profiles |
| POST | `/api/profiles/use` | ✅ | any | Set active profile |
| POST | `/api/profiles/create` | ✅ | admin | Create profile |
| DELETE | `/api/profiles/:name` | ✅ | admin | Delete profile |
| GET | `/api/gateway/:profile` | ✅ | any | Gateway status |
| POST | `/api/gateway/:profile/:action` | ✅ | any | start/stop/restart |
| GET | `/api/gateway/:profile/logs` | ✅ | any | Gateway logs |
| GET | `/api/sessions` | ✅ | any | List sessions |
| GET | `/api/all-sessions` | ✅ | any | All profiles sessions |
| POST | `/api/sessions/:id/rename` | ✅ | any | Rename session |
| DELETE | `/api/sessions/:id` | ✅ | any | Delete session |
| GET | `/api/sessions/:id/export` | ✅ | any | Export session |
| GET | `/api/sessions/stats` | ✅ | any | Session stats |
| GET | `/api/skills/browse/:page` | ✅ | any | Browse skills hub |
| GET | `/api/skills/search/:query` | ✅ | any | Search skills |
| GET | `/api/skills/inspect/:name` | ✅ | any | Inspect skill |
| POST | `/api/skills/install` | ✅ | admin | Install skill |
| POST | `/api/skills/uninstall` | ✅ | admin | Uninstall skill |
| POST | `/api/skills/update` | ✅ | admin | Update skill |
| POST | `/api/skills/check` | ✅ | any | Check skill updates |
| GET | `/api/explorer` | ✅ | any | Directory tree |
| GET | `/api/file` | ✅ | any | Read file |
| POST | `/api/file` | ✅ | any | Write file |
| POST | `/api/terminal/exec` | ✅ | any | Execute command |
| POST | `/api/chat` | ✅ | any | Chat message |
| POST | `/api/cron/:action` | ✅ | any | Cron management |
| GET | `/usage` | ✅ | any | Usage stats |
| GET | `/api/usage/:days` | ✅ | any | Usage by days |
| GET | `/api/insights` | ✅ | any | Insights |
| GET | `/api/insights/:profile/:days` | ✅ | any | Per-profile insights |
| GET | `/api/config/:profile` | ✅ | any | Get config |
| GET | `/api/memory/:profile` | ✅ | any | Get memory info |
| POST | `/api/doctor` | ✅ | admin | Run doctor |
| GET | `/api/dump` | ✅ | admin | Generate dump |
| POST | `/api/update` | ✅ | admin | Update Hermes |
| POST | `/api/backup` | ✅ | admin | Create backup |
| POST | `/api/hci-restart` | ✅ | admin | Restart HCI |
| GET | `/api/layout` | ✅ | any | Get layout |
| POST | `/api/layout` | ✅ | any | Save layout |
| GET | `/api/avatar` | ✅ | any | Avatar metadata |
| POST | `/api/avatar` | ✅ | any | Upload avatar |
| DELETE | `/api/avatar` | ✅ | any | Delete avatar |
| GET | `/api/notifications` | ✅ | any | Get notifications |
| POST | `/api/notifications/:id/dismiss` | ✅ | any | Dismiss notification |
| POST | `/api/notifications/clear` | ✅ | any | Clear all |
| GET | `/api/system/health` | ✅ | any | System health |
| GET | `/api/hermes-cron/:profile` | ✅ | any | Hermes cron jobs |
| POST | `/api/hermes-cron/:profile/create` | ✅ | any | Create cron |
| POST | `/api/hermes-cron/:profile/:jobId/:action` | ✅ | any | Cron action |

---

## 6. Security Model

### Authentication
- **Method:** Session cookie (`hermes...auth`)
- **Storage:** HttpOnly cookie, optional Secure flag (when HTTPS)
- **Password:** bcrypt hashing
- **Rate limiting:** 5 attempts per 15 minutes per IP on login

### RBAC Roles
| Role | Description |
|------|-------------|
| `admin` | Full access — all endpoints |
| `viewer` | Read-only access |
| `custom` | Custom permission set |

### Middleware Stack
```javascript
requireAuth        // Valid session cookie
requireRole(role)  // RBAC role check
requireCsrf        // CSRF double-submit cookie
loginRateLimiter   // express-rate-limit on login endpoint
helmet()           // Security headers (CSP, HSTS, X-Frame-Options, etc.)
```

### CSRF Protection
- Double-submit cookie pattern
- CSRF token stored in `state.csrfToken` (JS state)
- Required for: POST, PUT, DELETE on state-changing endpoints

### Input Validation Areas
| Area | Status | Notes |
|------|--------|-------|
| File explorer path | ⚠️ Review | Path traversal prevention needed |
| Terminal exec | ⚠️ Review | Arbitrary bash — auth + CSRF only |
| User input (forms) | ⚠️ Review | XSS prevention via escapeHtml() |
| File upload (avatar) | ✅ Limited | 10MB limit, base64 only |

---

## 7. Known Issues & Tech Debt

### 🔴 High Priority

| # | Issue | Location | Description | Status |
|---|-------|----------|-------------|--------|
| 1 | **Users page missing** | Frontend | Backend has `/api/users` but no UI page or nav link | OPEN |
| 2 | **Monolith JS** | `src/js/main.js` | 5043 lines in single file — no tests, hard to maintain | OPEN |
| 3 | **No test suite** | Entire codebase | No automated tests | ~~OPEN~~ → ✅ **9 tests passing** (PR #24 + #25) |
| 4 | **Inline CSS in JS** | `main.js` innerHTML | Styles embedded in JS strings — not modular | OPEN |

### 🟡 Medium Priority

| # | Issue | Location | Description | Status |
|---|-------|----------|-------------|--------|
| 5 | **CSRF token in JS state** | main.js | Token exposed in `state.csrfToken` | OPEN |
| 6 | **Terminal exec security** | server.js | Arbitrary bash — relies on auth + CSRF only | OPEN |
| 7 | **File explorer path traversal** | server.js | Needs audit of `req.query.path` validation | OPEN |
| 8 | **Session auth in memory** | server.js | Sessions not persisted to DB — lost on restart | OPEN |
| 9 | **Maintenance page nav exposure** | index.html | Admin-only page accessible via direct URL (backend RBAC only) | OPEN |
| 10 | **No input sanitization audit** | main.js | Full audit of all `innerHTML` usages needed | OPEN |

### 🟢 Low Priority

| # | Issue | Location | Description | Status |
|---|-------|----------|-------------|--------|
| 11 | **Mobile responsive** | Files page | Overlay pattern on mobile could be improved | OPEN |
| 12 | **No loading states** | Multiple pages | Some pages lack loading indicators | OPEN |
| 13 | **Error handling** | Multiple pages | Inconsistent error display patterns | OPEN |

---

## 8. Audit Checklist

### 8.1 Code Quality Audit
- [ ] Find and remove dead code (unused functions)
- [ ] Find and remove duplicate code patterns
- [ ] Audit all `innerHTML` for XSS vectors
- [ ] Check `escapeHtml()` usage coverage
- [ ] Verify all API responses handle errors properly
- [ ] Check memory leaks (event listeners, intervals)

### 8.2 Security Audit
- [ ] Path traversal test (file explorer)
- [ ] CSRF bypass attempt
- [ ] RBAC bypass test (viewer/admin endpoints)
- [ ] Rate limiting verification
- [ ] Password policy check
- [ ] Session fixation prevention
- [ ] XSS test (all user-input fields)
- [ ] SQL/NoSQL injection check (if applicable)
- [ ] Audit log completeness

### 8.3 Performance Audit
- [ ] Bundle size analysis (Vite build)
- [ ] Identify long functions that could be split
- [ ] Check for unnecessary re-renders
- [ ] WebSocket connection handling
- [ ] Memory usage under load

### 8.4 Functionality Audit
- [ ] Test all 9 pages manually
- [ ] Test all nav links
- [ ] Test auth flow (login, logout, session expiry)
- [ ] Test RBAC (admin vs viewer actions)
- [ ] Test file explorer (valid paths, invalid paths)
- [ ] Test terminal (valid commands, invalid commands)
- [ ] Test chat (send, receive, tool calls, sessions)
- [ ] Test notifications (dismiss, clear)
- [ ] Test avatar upload (valid, invalid formats)
- [ ] Test cron (create, edit, delete, pause, resume)

### 8.5 Plugin Architecture Readiness
- [ ] Define plugin manifest schema
- [ ] Define plugin SDK API
- [ ] Plan plugin discovery mechanism
- [ ] Plan plugin installation/uninstallation
- [ ] Plan plugin security sandboxing
- [ ] Design plugin store UI

---

## Appendix: Code Statistics

| File | Lines | Purpose |
|------|-------|---------|
| `src/js/main.js` | ~5045 | All frontend logic |
| `src/js/chat-render-utils.mjs` | 9 | Chat renderer normalization (PR #24) |
| `src/css/components.css` | 1886 | Component styles |
| `src/css/layout.css` | — | Layout styles |
| `src/css/theme.css` | — | Theme variables |
| `src/index.html` | 123 | SPA shell |
| `lib/session-list.js` | 103 | Session merge logic (PR #25) |
| `server.js` | ~3768 | All backend + API (~94 endpoints) |
| `test/` | 134 | Test suite (9 tests, 2 files) |
| `dist/` | (build) | Vite output |

**Total frontend LOC:** ~7063 (main + css + html + chat-utils)
**Total backend LOC:** ~3768 (server + lib)
**Total test LOC:** 134

---

## Appendix: Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | 10272 | Server port |
| `CONTROL_PASSWORD` | (required) | HCI admin password |
| `CONTROL_SECRET` | (required) | Internal API secret |
| `HERMES_PROJECTS_ROOT` | `../` | Projects root for file explorer |
| `HERMES_CONTROL_HOME` | `~/.hermes` | Hermes config directory |
| `HERMES_CONTROL_PASSWORD` | (env) | Legacy env var for password |

---

*Document status: ACTIVE — Post-PR merge phase*
*Next review: After Phase 1 cleanup completion*

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2026-04-17 | v3.3.0+ | PR #24: chat render normalization, PR #25: child sessions in lists, test suite (9 tests), ~94 endpoints |
| 2026-04-17 | v3.3.0 | Initial architecture document, core cleanup phase |
