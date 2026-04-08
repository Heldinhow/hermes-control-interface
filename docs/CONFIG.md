# Configuration

Hermes Control Interface is configured entirely through environment variables.
Use `.env` for local development and a secret manager or system service for deployment.

## Required variables

- `HERMES_CONTROL_PASSWORD` - password for the login screen
- `HERMES_CONTROL_SECRET` - HMAC secret for auth cookies and internal requests

## Optional variables

- `PORT` - HTTP port, default `10272`
- `HERMES_HOME` - Hermes state directory, default `/root/.hermes`
- `HERMES_PROJECTS_ROOT` - root used for the projects explorer, default parent of this repo
- `HERMES_CONTROL_ROOTS` - explicit explorer roots

## Explorer roots format

`HERMES_CONTROL_ROOTS` accepts either:

- a JSON array
- a comma-separated path list

Example JSON:

```json
[
  {"key":"projects","label":"/srv/projects","root":"/srv/projects"},
  {"key":"hermes","label":"/home/me/.hermes","root":"/home/me/.hermes"}
]
```

Example CSV:

```bash
HERMES_CONTROL_ROOTS=/srv/projects,/home/me/.hermes
```

## Deployment rule

Keep the password and secret out of the repo. Put them in environment variables or a secret store.
