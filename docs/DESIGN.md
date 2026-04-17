# Hermes Control Interface — Design System

> AI agent control dashboard with monospace precision and data-dense terminal aesthetic.
> Dark-mode-first, monospace-driven, gold-accented.

---

## 1. Visual Theme & Atmosphere

**Philosophy:** Terminal-native meets modern dashboard. The UI feels like a sophisticated command center — dense with information, yet breathable through disciplined spacing and subtle depth cues. Every element serves the power user who lives in terminals.

**Mood:** Professional dark workspace. Like a well-configured terminal emulator crossed with a premium analytics platform. Not flashy — purposeful.

**Density:** High information density with clear visual hierarchy. Compact rows, tight letter-spacing in labels, generous padding in interactive zones.

**Character:** Monospace typography signals developer-first. Gold accents mark primary actions and active states. Teal and coral provide semantic color coding for system states.

---

## 2. Color Palette & Roles

### Primary Theme (Dark Mode)

```css
/* Surfaces */
--bg: #0b201f;           /* Deep teal-black canvas */
--bg-base: #0b201f;       /* Base background */
--bg-panel: rgba(220, 203, 181, 0.06);   /* Panel/card surfaces */
--bg-panel-hover: rgba(220, 203, 181, 0.10); /* Hover state */
--bg-input: rgba(220, 203, 181, 0.05);   /* Input fields */
--bg-card: rgba(0, 0, 0, 0.2);           /* Elevated cards */

/* Foreground */
--fg: #dccbb5;            /* Primary text (warm cream) */
--fg-base: #dccbb5;       /* Base text color */
--fg-muted: rgba(220, 203, 181, 0.50);   /* Secondary text */
--fg-subtle: rgba(220, 203, 181, 0.30);  /* Tertiary/disabled */

/* Borders */
--border: rgba(220, 203, 181, 0.10);     /* Default borders */
--border-strong: rgba(220, 203, 181, 0.20); /* Emphasized borders */

/* Semantic Colors */
--accent: #7c945c;        /* Sage green — links, active states */
--accent-dim: rgba(124, 148, 92, 0.15);  /* Accent backgrounds */
--green: #7c945c;        /* Success states */
--blue: #6f9ac3;          /* Info, secondary actions */
--red: #c45c5c;           /* Error, danger, delete */
--amber: #c4a44c;         /* Warning states */
--yellow: #d4c47c;        /* Highlight */
--pink: #b07c9c;          /* Special/pink accent */

/* Effects */
--shadow: 0 20px 70px rgba(0, 0, 0, 0.4); /* Elevation shadow */
--radius: 8px;            /* Standard corners */
--radius-lg: 16px;         /* Large card corners */
```

### Accent Highlights (Override/Dynamic)

```css
--gold: #ffac02;   /* Primary CTA, active nav, important metrics */
--teal: #4ecdc4;   /* System info, links, component tags */
--coral: #ff6b6b;  /* Errors, warnings, delete actions */
--purple: #a78bfa; /* User-generated content, special badges */
--green: #34d399;  /* Success, online status */
```

### Light Mode

```css
/* Surfaces */
--bg: #e4ebdf;      /* Soft sage canvas */
--bg-base: #e4ebdf;
--bg-panel: rgba(11, 32, 31, 0.05);
--bg-panel-hover: rgba(11, 32, 31, 0.08);
--bg-input: rgba(11, 32, 31, 0.04);
--bg-card: rgba(255, 255, 255, 0.5);

/* Foreground */
--fg: #0b201f;      /* Dark teal text */
--fg-muted: rgba(11, 32, 31, 0.55);
--fg-subtle: rgba(11, 32, 31, 0.35);

/* Semantic */
--accent: #2e6fb0;  /* Blue in light mode */
--green: #7c945c;
--red: #b04c4c;
```

---

## 3. Typography Rules

### Font Stack

```css
--font: 'JetBrains Mono', ui-monospace, monospace;
```

**Primary Font:** JetBrains Mono — developer-focused monospace with excellent legibility at small sizes.

**Fallbacks:** `ui-monospace` (system), `monospace` (generic).

**Rationale:** Monospace throughout reinforces the terminal/developer aesthetic. No mixing with proportional fonts for UI chrome.

### Type Scale

| Element | Size | Weight | Transform | Letter-spacing |
|---------|------|--------|-----------|----------------|
| Nav items | 11px | 500 | Uppercase | 0.08em |
| Labels | 11px | 700 | Uppercase | 0.05em |
| Body | 14px | 400 | None | 0 |
| Card titles | 14px | 600 | Uppercase | 0.04em |
| Section headings | 16px | 600 | None | 0 |
| Page headings | 18px | 700 | None | 0 |
| Large metrics | 20px | 700 | None | 0 |
| Hero text | 22px | 700 | None | 0 |

### Usage Rules

- **Uppercase** for: navigation, labels, badges, button text
- **700 weight** reserved for: metric values, headings, primary actions
- **Letter-spacing 0.04–0.08em** on uppercase text only

---

## 4. Component Stylings

### Buttons

```css
/* Base Button */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 16px;
  font-family: var(--font);
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  border: 1px solid var(--border);
  border-radius: var(--radius); /* 8px */
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

/* Primary Button — Gold accent */
.btn-primary {
  background: color-mix(in oklab, #ffac02 15%, transparent);
  border-color: color-mix(in oklab, #ffac02 25%, transparent);
  color: var(--fg);
}
.btn-primary:hover {
  background: color-mix(in oklab, #ffac02 25%, transparent);
  border-color: color-mix(in oklab, #ffac02 40%, transparent);
  transform: translateY(-1px);
}

/* Ghost Button — Minimal */
.btn-ghost {
  background: transparent;
  color: var(--fg-muted);
}
.btn-ghost:hover {
  background: var(--bg-panel-hover);
  color: var(--fg);
}

/* Danger Button — Red accent */
.btn-danger {
  background: color-mix(in oklab, #fb2c36 15%, transparent);
  border-color: color-mix(in oklab, #fb2c36 25%, transparent);
  color: var(--red);
}

/* Success Button — Green accent */
.btn-success {
  background: color-mix(in oklab, #67f0a2 15%, transparent);
  border-color: color-mix(in oklab, #67f0a2 25%, transparent);
  color: var(--green);
}

/* Small Button */
.btn-sm {
  padding: 5px 10px;
  font-size: 12px;
}
```

### Cards

```css
.card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius); /* 8px */
  padding: 20px;
  transition: all 0.2s ease;
}

.card:hover {
  border-color: var(--border-strong);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.card-title {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--fg);
}
```

### Form Inputs

```css
input, textarea, select {
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  color: var(--fg);
  font-family: var(--font);
  font-size: 13px;
  padding: 8px 12px;
  transition: border-color 0.2s ease;
}

input:focus, textarea:focus {
  outline: none;
  border-color: var(--gold, #ffac02);
}
```

### Badges & Tags

```css
/* Notification Badge */
.notif-badge {
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  background: var(--red);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  border-radius: 999px;
}

/* Component Tag */
.component-tag {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gold);
}

/* Status Indicators */
.status-online { color: var(--green); }
.status-error { color: var(--coral); }
.status-warning { color: var(--amber); }
```

### Navigation

```css
.nav-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  font-size: 11px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--fg-muted);
  border-left: 3px solid transparent;
  transition: all 0.2s ease;
  cursor: pointer;
}

.nav-item:hover {
  background: var(--bg-panel);
  color: var(--fg);
}

.nav-item.active {
  background: var(--bg-panel);
  color: var(--gold);
  border-left-color: var(--gold);
}
```

---

## 5. Layout Principles

### Grid & Spacing Scale

**Base unit:** 4px

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | 4px | Tight gaps, icon margins |
| `--space-sm` | 8px | Button padding, input padding |
| `--space-md` | 16px | Card padding, section gaps |
| `--space-lg` | 24px | Section separation |
| `--space-xl` | 32px | Page margins |

### Page Structure

```
┌─────────────────────────────────────────────────────┐
│  Header (fixed)                           48-56px  │
├──────────┬──────────────────────────────────────────┤
│          │                                          │
│  Sidebar │           Main Content                   │
│  (fixed) │           (scrollable)                   │
│  200px   │                                          │
│          │                                          │
│          │                                          │
├──────────┴──────────────────────────────────────────┤
│  (no footer — dashboard style)                      │
└─────────────────────────────────────────────────────┘
```

### Responsive Strategy

| Breakpoint | Behavior |
|------------|----------|
| `< 480px` | Sidebar collapses to icon-only (36px), nav text hidden |
| `480–768px` | Sidebar 180px, condensed padding |
| `> 768px` | Full sidebar 200px+ |

### Background Texture

Subtle grid overlay on body (40px grid, 1px lines at 1.5% opacity) with radial gradient vignette. Creates depth without distraction.

---

## 6. Depth & Elevation

### Shadow System

```css
/* Card Elevation */
.card {
  box-shadow: var(--shadow); /* 0 20px 70px rgba(0,0,0,0.4) */
}

/* Modal Elevation */
.modal {
  box-shadow: 0 25px 80px rgba(0, 0, 0, 0.5);
}

/* Dropdown Elevation */
.dropdown {
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
}
```

### Surface Hierarchy

| Level | Surface | Usage |
|-------|---------|-------|
| Base | `--bg` | Page background |
| Panel | `--bg-panel` | Sidebar, header |
| Card | `--bg-card` | Content cards |
| Elevated | `--bg-input` | Inputs, dropdowns |
| Overlay | rgba(0,0,0,0.5) | Modal backdrop |

---

## 7. Do's and Don'ts

### ✅ Do

- **Use gold for primary CTAs** — buttons, active states, key metrics
- **Use teal for system elements** — links, component labels, info states
- **Use coral/red for destructive actions** — delete buttons, error messages
- **Use monospace font throughout** — never mix with proportional fonts for UI
- **Use uppercase for labels and navigation** — 0.05–0.08em letter-spacing
- **Use subtle borders over shadows** — for most UI chrome
- **Keep information dense** — tight spacing for data tables, compact rows

### ❌ Don't

- **Don't use more than 3 accent colors in one view** — limits visual noise
- **Don't use bold text for body copy** — only headings and metrics
- **Don't use serif fonts** — breaks the terminal aesthetic
- **Don't use bright backgrounds** — dark mode is primary
- **Don't use emoji in UI labels** — use icons instead (emoji OK for decorative)
- **Don't use full rounded pills** — stick to 8px radius maximum

---

## 8. Responsive Behavior

### Breakpoints

```css
--bp-sm: 480px;
--bp-md: 768px;
--bp-lg: 1024px;
--bp-xl: 1280px;
```

### Touch Targets

- Minimum touch target: **44×44px** on mobile
- Buttons scale up padding on touch devices
- Sidebar tap areas expand on mobile

### Collapsing Strategy

| Element | Desktop | Mobile |
|---------|---------|--------|
| Sidebar | Full (200px) | Icon-only (36px) |
| Nav labels | Visible | Hidden |
| Card grids | 3-4 columns | 1-2 columns |
| Tables | Full width | Horizontal scroll |

---

## 9. Agent Prompt Guide

### Quick Color Reference

```
HCI Color Tokens:
- --gold (#ffac02): Primary actions, active states, key metrics
- --teal (#4ecdc4): Links, system info, component labels
- --coral (#ff6b6b): Errors, warnings, delete actions
- --purple (#a78bfa): User content, special badges
- --green (#34d399): Success states, online indicators
- Background: #0b201f (dark), #e4ebdf (light)
- Text: #dccbb5 (cream), rgba(220,203,181,0.50) muted
- Font: JetBrains Mono (monospace only)
```

### Sample Prompts for AI Agents

**"Build a new dashboard page following HCI design:"**
```
Create a new page for [feature name] following these design rules:
- Dark theme: background #0b201f, text #dccbb5
- Primary accent: #ffac02 (gold) for CTAs and active states
- Use JetBrains Mono font throughout, 14px base size
- Uppercase + letter-spacing 0.05em for labels
- 8px border-radius on cards and buttons
- Compact spacing: 8-16px padding on components
- Follow the card patterns with border: 1px solid rgba(220,203,181,0.10)
```

**"Add a new metric card to the usage page:"**
```
Add a metric card with:
- Gold (#ffac02) for the numeric value at 20px/700 weight
- Label in uppercase, 11px, 0.05em letter-spacing
- Muted secondary text for supporting info
- Card with --bg-card background and --border
- Hover state: border-color to --border-strong
```

**"Create a form section:"**
```
Build a form section with:
- Inputs: background rgba(220,203,181,0.05), border rgba(220,203,181,0.10)
- Focus state: border-color #ffac02
- Labels: uppercase, 11px, 700 weight, gold color
- 8px border-radius on all inputs
- 16px gap between form groups
```

**"Style a data table:"**
```
Style a table with:
- Monospace font throughout
- Uppercase headers, 11px, 700 weight, muted color
- Dense row spacing (8-12px vertical padding)
- Alternating row backgrounds at 5% opacity difference
- Hover: background var(--bg-panel-hover)
- Gold accent for sortable column headers
```

---

## Appendix: CSS Variables Reference

```css
/* Colors - Dark Mode */
--bg: #0b201f;
--bg-panel: rgba(220, 203, 181, 0.06);
--bg-card: rgba(0, 0, 0, 0.2);
--fg: #dccbb5;
--fg-muted: rgba(220, 203, 181, 0.50);
--border: rgba(220, 203, 181, 0.10);
--border-strong: rgba(220, 203, 181, 0.20);

/* Accents */
--gold: #ffac02;
--teal: #4ecdc4;
--coral: #ff6b6b;
--purple: #a78bfa;
--green: #34d399;

/* Typography */
--font: 'JetBrains Mono', ui-monospace, monospace;
--radius: 8px;
--radius-lg: 16px;

/* Effects */
--shadow: 0 20px 70px rgba(0, 0, 0, 0.4);
--transition: 0.2s ease;
```

---

*This design system is for Hermes Control Interface (HCI) — an AI agent control dashboard. Version 3.3.x*
