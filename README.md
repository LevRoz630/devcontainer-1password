# Ultimate Dev Container

A fully-featured development container with secure 1Password credential management. Works with VS Code Dev Containers or standalone Docker.

## Technologies

### Languages & Runtimes
| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20.x | JavaScript/TypeScript runtime |
| npm | 10.x | Node package manager |
| Python | 3.11 | Python runtime |
| pip | Latest | Python package manager |

### Cloud CLIs
| Tool | Purpose |
|------|---------|
| AWS CLI | Amazon Web Services |
| Google Cloud SDK | Google Cloud Platform |
| Azure CLI | Microsoft Azure |

### Development Tools
| Tool | Purpose |
|------|---------|
| Docker CLI | Container management (Docker-in-Docker) |
| Docker Compose | Multi-container orchestration |
| GitHub CLI (`gh`) | GitHub operations, PR management |
| Git | Version control |
| Claude Code | AI-assisted development |

### Security & Credentials
| Tool | Purpose |
|------|---------|
| 1Password CLI (`op`) | Secure credential management |
| ssh-agent | SSH key management |

## Authentication Options

### Option 1: Interactive (Recommended for personal use)

Run `setup-ssh` in the container terminal. First time requires:
- 1Password sign-in address (e.g., `my.1password.eu`)
- Email
- Secret key (starts with `A3-`)
- Master password

After first setup, only master password needed (account config persists via mount).

### Option 2: Service Account (Recommended for automation)

Set on your host machine:
```bash
export OP_SERVICE_ACCOUNT_TOKEN="ops_your_token_here"
```

Credentials load automatically on container start.

## Quick Start

### 1. Prerequisites

- Docker Desktop or Docker Engine
- VS Code with Dev Containers extension (optional)
- 1Password account with a vault containing:
  - `Github SSH Key` - SSH key item with private key
  - `GitHub Token` - API token item

### 2. 1Password Vault Setup

Create a vault called `DevContainer` with:

**SSH Key:**
- Item name: `Github SSH Key`
- Type: SSH Key
- Add your private key

**GitHub Token:**
- Item name: `GitHub Token`
- Type: API Credential
- Field name: `token`
- Value: Your GitHub PAT (needs `repo` scope)

### 3. Open in VS Code

```bash
code /path/to/ultimate-devcontainer
```

Then: `Cmd+Shift+P` → "Dev Containers: Reopen in Container"

### 4. Set Up Credentials

In the container terminal:
```bash
setup-ssh
```

Follow the prompts to sign in to 1Password.

### 5. Clone Repos (Optional)

```bash
clone-repos
```

Interactive selector shows your GitHub repos sorted by recent activity.

## What's Mounted

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `~/.gitconfig` | `/home/devuser/.gitconfig` | Git identity (read-only) |
| `~/.claude/` | `/home/devuser/.claude/` | Claude Code settings |
| `~/.config/op/` | `/home/devuser/.config/op/` | 1Password account config (persists across rebuilds) |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker-in-Docker |

## Security

| Aspect | Implementation |
|--------|----------------|
| Master password | Never stored, entered each session |
| SSH keys | Fetched from 1Password, loaded into ssh-agent only |
| GitHub token | Fetched from 1Password, passed to `gh auth` |
| Account config | Stored on host `~/.config/op/`, contains no secrets |
| Service account token | Optional, for fully automatic setup |

## File Structure

```
.devcontainer/
├── Dockerfile           # Container image definition
├── devcontainer.json    # VS Code Dev Container config
├── setup-ssh.sh         # 1Password auth & credential loading
├── clone-repos.sh       # Interactive GitHub repo cloning
└── tests/
    ├── test-image.sh    # Container test suite
    └── run-tests.sh     # Build & test runner
```

## Testing

Run tests without VS Code:
```bash
.devcontainer/tests/run-tests.sh --verbose
```

Run tests inside container:
```bash
.devcontainer/tests/test-image.sh
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `setup-ssh` | Authenticate with 1Password, load SSH key & GitHub token |
| `setup-ssh --interactive` | Force interactive mode (skip service account) |
| `clone-repos` | Interactive GitHub repo selector |

## Troubleshooting

### "No 1Password account configured"
Run `setup-ssh` and follow the prompts to add your account.

### "Permission denied" on git operations
```bash
# Check SSH key is loaded
ssh-add -l

# Re-run setup if needed
setup-ssh
```

### GitHub CLI not authenticated
```bash
# Check auth status
gh auth status

# Re-run setup
setup-ssh
```

### Container rebuild loses credentials
This is expected. The 1Password account config persists, but you need to re-enter your master password after rebuild:
```bash
setup-ssh
```

## License

MIT
