# Gateway Health Check Panel — Implementation Plan

> **For David:** Implement this plan on `/root/projects/hci-staging/`. Follow HCI dev flow: fix → build → commit local.

**Goal:** Add a health check panel on Agent Detail > Gateway page that shows gateway status, connectivity, and auto-fix capability.

**Architecture:** New backend endpoint + frontend panel. Shows gateway port, connection status, API health, and issues. Auto-fix button to restart gateway service if down.

---

## Task 1: Add `GET /api/gateway/:profile/health` endpoint

**File:** `server.js` — insert near existing gateway endpoints (~line 2140)

```javascript
// Gateway health check for a specific profile
app.get('/api/gateway/:profile/health', requireAuth, async (req, res) => {
  try {
    const profile = sanitizeProfileName(req.params.profile) || 'default';
    const port = gatewayPorts[profile];
    const issues = [];
    const checks = {};

    // Check 1: Port discovered
    checks.port_discovered = !!port;
    if (!port) issues.push('Gateway port not configured in config.yaml (platforms.api_server.extra.port)');

    // Check 2: Gateway process running
    let gatewayRunning = false;
    try {
      const svcName = `hermes-gateway-${profile}`;
      const status = (await shell(`systemctl is-active ${svcName} 2>&1`, '5s')).trim();
      gatewayRunning = status === 'active';
      checks.service_status = status;
    } catch {}
    if (!gatewayRunning) {
      // Fallback: check if something is listening on the port
      if (port) {
        const listening = (await shell(`ss -tlnp | grep :${port}`, '5s')).trim();
        checks.port_listening = !!listening;
        if (!listening) issues.push(`Nothing listening on port ${port}`);
      }
    }

    // Check 3: API responds
    checks.api_reachable = false;
    if (port) {
      try {
        const healthRes = await fetch(`http://127.0.0.1:${port}/health`, { 
          signal: AbortSignal.timeout(3000) 
        });
        checks.api_reachable = healthRes.ok;
        if (!healthRes.ok) issues.push(`Gateway API returned ${healthRes.status}`);
      } catch (e) {
        issues.push(`Gateway API unreachable: ${e.message}`);
      }
    }

    // Check 4: Profile routing (does gateway support this profile?)
    checks.profile_supported = profile === 'default'; // Only default is natively supported
    if (profile !== 'default') {
      issues.push('Gateway API only supports default profile. Other profiles use CLI fallback (slower).');
    }

    // Check 5: Config exists
    const configPath = profile === 'default' 
      ? path.join(HERMES_HOME, 'config.yaml')
      : path.join(HERMES_HOME, 'profiles', profile, 'config.yaml');
    checks.config_exists = fs.existsSync(configPath);
    if (!checks.config_exists) issues.push(`Config not found: ${configPath}`);

    const healthy = checks.port_discovered && checks.api_reachable && checks.config_exists;

    res.json({
      ok: true,
      profile,
      port: port || null,
      healthy,
      checks,
      issues,
      gatewayMode: healthy ? 'Gateway API (fast)' : 'CLI fallback (slow)',
    });
  } catch (e) {
    res.json({ ok: false, error: e.message });
  }
});
```

**Step 2: Test**

```bash
curl -s -c /tmp/hci-cookies -X POST http://localhost:10274/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"bayendor","password":"pxnji2727"}' \
&& curl -s -b /tmp/hci-cookies http://localhost:10274/api/gateway/default/health | python3 -m json.tool
```

Expected: JSON with `healthy: true`, `port: 8642`, `checks` object, `issues` array.

**Step 3: Commit**

```bash
node -c server.js && git add -A && git commit -m "feat(gateway): add health check endpoint per profile"
```

---

## Task 2: Add health check panel to Agent Detail > Gateway tab

**File:** `src/js/main.js` — find the `loadAgentTab('gateway', name)` function and update it.

**Step 1: Add health check rendering function**

```javascript
async function renderGatewayHealth(container, profile) {
  try {
    const res = await api(`/api/gateway/${profile}/health`);
    if (!res.ok) { container.innerHTML = '<div class="error-msg">Failed to check health</div>'; return; }
    
    const statusIcon = res.healthy ? '🟢' : '🔴';
    const statusText = res.healthy ? 'Healthy' : 'Issues Found';
    
    let html = `<div class="gateway-health-card">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px;">
        <span style="font-size:20px;">${statusIcon}</span>
        <div>
          <div style="font-weight:600;font-size:14px;">${statusText}</div>
          <div style="font-size:12px;color:var(--fg-muted);">Profile: ${profile} · Port: ${res.port || 'N/A'} · Mode: ${res.gatewayMode}</div>
        </div>
      </div>`;
    
    // Checks list
    html += '<div class="health-checks">';
    for (const [key, value] of Object.entries(res.checks)) {
      const icon = value ? '✅' : '❌';
      const label = key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
      html += `<div class="health-check-row">${icon} <span>${label}</span></div>`;
    }
    html += '</div>';
    
    // Issues
    if (res.issues.length > 0) {
      html += '<div class="health-issues" style="margin-top:8px;">';
      for (const issue of res.issues) {
        html += `<div class="health-issue">⚠️ ${escapeHtml(issue)}</div>`;
      }
      html += '</div>';
    }
    
    // Auto-fix button
    if (!res.healthy) {
      html += `<div style="margin-top:12px;">
        <button class="btn btn-primary btn-sm" onclick="fixGateway('${profile}')">🔧 Auto-Fix</button>
      </div>`;
    }
    
    html += '</div>';
    container.innerHTML = html;
  } catch (e) {
    container.innerHTML = '<div class="error-msg">Health check failed</div>';
  }
}

async function fixGateway(profile) {
  const confirmed = await showModal({
    title: 'Fix Gateway',
    message: `Restart gateway service for profile <code>${profile}</code>?`,
    buttons: [
      { text: 'Cancel', value: false },
      { text: 'Restart', value: true, primary: true },
    ],
  });
  if (!confirmed?.action) return;
  
  try {
    const res = await api(`/api/gateway/${profile}/start`, { method: 'POST' });
    if (res.ok) {
      showToast('Gateway restarted', 'success');
      // Re-check health after a moment
      setTimeout(() => {
        const el = document.getElementById('gateway-health');
        if (el) renderGatewayHealth(el, profile);
      }, 3000);
    } else {
      showToast('Failed: ' + (res.error || 'unknown'), 'error');
    }
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
  }
}
```

**Step 2: Export to window**

```javascript
window.fixGateway = fixGateway;
```

**Step 3: Add CSS for health check**

```css
.gateway-health-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px;
  margin-bottom: 12px;
}

.health-check-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 3px 0;
  font-size: 12px;
}

.health-issue {
  font-size: 12px;
  color: var(--coral);
  padding: 2px 0;
}
```

**Step 4: Commit**

```bash
node -c src/js/main.js && npm run build && git add -A && git commit -m "feat(gateway): health check panel with auto-fix on Agent Detail Gateway tab"
```

---

## Notes

- Gateway API only supports `default` profile natively. Other profiles (soci, david, cuan) will show "issues" because they use CLI fallback — this is expected behavior, not a bug.
- Auto-fix restarts the gateway service via `systemctl` or the existing `/api/gateway/:profile/start` endpoint.
- Health check is read-only (no side effects) — safe to call on page load.
