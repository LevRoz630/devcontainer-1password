# Ultimate Dev Container

A portable development container that uses 1Password Service Accounts for credential management. Works on any machine or VM without requiring the 1Password desktop app.

## Features

- **Portable** - Works on VMs, remote servers, anywhere Docker runs
- **Secure** - Credentials fetched from 1Password on container start, never stored on disk
- **Zero config** - SSH keys, GitHub CLI, and tools auto-configured via service account

## Included Tools

| Tool | Purpose |
|------|---------|
| Node.js 20.x | JavaScript runtime |
| Python 3.11 | Python runtime |
| Docker CLI | Container management |
| GitHub CLI | GitHub operations |
| Claude Code | AI-assisted development |
| 1Password CLI | Credential management |

## Quick Start

### 1. Create 1Password Service Account

1. Go to [1Password.com](https://my.1password.com) > **Developer Tools** > **Service Accounts**
2. Create a new service account
3. Grant access to a vault (e.g., "DevContainer") containing:
   - `Github SSH Key` - SSH key with `private_key` field
   - `GitHub Token` - Personal access token with `credential` field

### 2. Configure Environment

Create `.env` in the project root (gitignored):
```
OP_SERVICE_ACCOUNT_TOKEN=ops_your_token_here
```

### 3. Build and Run

```bash
# Build
docker compose -f .devcontainer/docker-compose.yml build

# Run
docker compose -f .devcontainer/docker-compose.yml up -d

# Enter container
docker compose -f .devcontainer/docker-compose.yml exec devcontainer bash
```

Credentials are automatically loaded on container start via `setup-ssh.sh`.

### 4. Clone Repos (Optional)

Inside the container, run the interactive repo selector:
```bash
.devcontainer/clone-repos.sh
```

This lists your GitHub repos by recent activity and lets you pick which to clone.

## VS Code Dev Containers

1. Open this folder in VS Code
2. Press `F1` > "Dev Containers: Reopen in Container"

## What's Mounted

| Host | Container | Purpose |
|------|-----------|---------|
| `~/.gitconfig` | `~/.gitconfig` | Git identity (read-only) |
| `~/.claude/` | `~/.claude/` | Claude Code config |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker-in-Docker |

## Security

- Service account token stored in `.env` (gitignored, never committed)
- SSH keys fetched on-demand from 1Password, not persisted
- Service account scoped to specific vault only
- Credentials injected into ssh-agent/gh, not written to files

## File Structure

```
.devcontainer/
├── Dockerfile           # Container image
├── docker-compose.yml   # Volume mounts, env config
├── devcontainer.json    # VS Code integration
├── setup-ssh.sh         # Loads credentials from 1Password
└── clone-repos.sh       # Interactive repo cloning
```

## Troubleshooting

### "Permission denied" on git operations
- Check `OP_SERVICE_ACCOUNT_TOKEN` is set in `.env`
- Verify service account has vault access
- Run `op read "op://DevContainer/Github SSH Key/private_key"` to test

### GitHub CLI not authenticated
- Ensure `GitHub Token` item exists in your 1Password vault
- Token needs `repo` scope
