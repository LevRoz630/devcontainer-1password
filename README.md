# Ultimate Dev Container

A portable, secure development container that uses 1Password as the single source of truth for all credentials. SSH keys and secrets live in your 1Password vault—never on disk, never in the container.

## The Problem

Traditional devcontainer setups have credential management issues:

1. **SSH keys on disk** - Private keys sitting in `~/.ssh/` are vulnerable if the machine is compromised
2. **Scattered credentials** - AWS in `~/.aws/`, GCloud in `~/.config/gcloud/`, Azure in `~/.azure/`—hard to track and rotate
3. **Encrypted folder dependencies** - If you use ecryptfs or similar to protect `~/.ssh/`, the folder locks on logout/reboot, breaking devcontainers
4. **Mounting secrets into containers** - Copying credential files into containers creates more copies to manage and secure
5. **No audit trail** - You don't know when or how your credentials are being used

## The Solution

This devcontainer uses **1Password SSH Agent** and **1Password CLI** to solve all of these:

- **SSH keys never touch disk** - Keys exist only in your 1Password vault, accessed via agent socket
- **Single credential store** - All secrets in one place with 1Password's encryption and sync
- **No encrypted folder dependency** - Works as long as 1Password app is running (survives logout/reboot)
- **Socket mounting, not file copying** - Container accesses credentials through the agent socket, not copied files
- **Per-use approval** - 1Password prompts you each time a credential is used (configurable)
- **Audit trail** - 1Password logs credential access

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                     HOST MACHINE                                 │
│                                                                  │
│  ┌──────────────────────┐    ┌─────────────────────────────┐   │
│  │   1Password App      │    │      ~/.ssh/config          │   │
│  │                      │    │  IdentityAgent              │   │
│  │  ┌────────────────┐  │    │  ~/.1password/agent.sock    │   │
│  │  │ SSH Keys       │  │    └─────────────────────────────┘   │
│  │  │ AWS Creds      │──┼──► ~/.1password/agent.sock            │
│  │  │ Cloud Secrets  │  │                 │                     │
│  │  └────────────────┘  │                 │                     │
│  └──────────────────────┘                 │                     │
│                                           │ (socket mount)      │
│  ┌────────────────────────────────────────┼───────────────────┐ │
│  │              DEVCONTAINER              │                   │ │
│  │                                        ▼                   │ │
│  │  ~/.1password/agent.sock ◄─────────────┘                   │ │
│  │         │                                                  │ │
│  │         ▼                                                  │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │   git/ssh   │  │  gh CLI     │  │  Cloud CLIs │        │ │
│  │  │             │  │             │  │  (via op)   │        │ │
│  │  │ git clone   │  │ gh pr       │  │ aws, gcloud │        │ │
│  │  │ git push    │  │ gh issue    │  │ az          │        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Key insight**: The container doesn't contain any credentials. It only has a socket connection to the 1Password agent running on your host. When you run `git push`, the request goes through the socket to 1Password, which prompts you for approval.

## Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 20.x | JavaScript runtime |
| **Python** | 3.11 | Python runtime |
| **Docker CLI** | Latest | Container management (Docker-in-Docker) |
| **GitHub CLI** | Latest | GitHub operations (`gh pr`, `gh issue`) |
| **Claude Code** | Latest | AI-assisted development |
| **AWS CLI** | v2 | Amazon Web Services |
| **Google Cloud SDK** | Latest | Google Cloud Platform |
| **Azure CLI** | Latest | Microsoft Azure |
| **1Password CLI** | Latest | Credential injection (`op run`) |

## Quick Start

### Prerequisites

- Docker installed on host
- 1Password desktop app installed
- 1Password CLI installed (`op`)

### 1. Enable 1Password SSH Agent

1. Open **1Password desktop app**
2. Go to **Settings > Developer**
3. Enable **"Use the SSH agent"**
4. (Optional) Configure approval settings—per-use, per-session, or timeout-based

### 2. Create SSH Key in 1Password

1. In 1Password: **+ New Item > SSH Key**
2. Click **Generate a New Key**
3. Select **Ed25519** (recommended—more secure, shorter)
4. Name it (e.g., "GitHub SSH Key")
5. **Save**

### 3. Add Public Key to GitHub

1. In 1Password, open your SSH Key item
2. Copy the **public key**
3. Go to [GitHub SSH Keys](https://github.com/settings/keys)
4. Click **New SSH key**
5. Paste and save

### 4. Configure Host

Run the setup script:
```bash
./setup-credentials.sh
```

Or manually:
```bash
# SSH config
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'Host *
    IdentityAgent ~/.1password/agent.sock' > ~/.ssh/config
chmod 600 ~/.ssh/config

# Git config
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### 5. Verify Setup

```bash
# Should prompt 1Password, then show "Hi <username>!"
ssh -T git@github.com
```

### 6. Build and Run Container

```bash
cd ultimate-devcontainer

# Build
docker compose -f .devcontainer/docker-compose.yml build

# Run
docker compose -f .devcontainer/docker-compose.yml up -d

# Enter container
docker compose -f .devcontainer/docker-compose.yml exec devcontainer bash
```

## Usage Patterns

### VS Code Dev Containers

1. Copy `.devcontainer/` folder to your project
2. Open project in VS Code
3. Press `F1` > "Dev Containers: Reopen in Container"

### Reference from Other Projects

Create `.devcontainer/devcontainer.json` in your project:
```json
{
  "name": "My Project",
  "dockerComposeFile": [
    "/path/to/ultimate-devcontainer/.devcontainer/docker-compose.yml"
  ],
  "service": "devcontainer",
  "workspaceFolder": "/workspace"
}
```

### Standalone Usage

```bash
# Start container in background
docker compose -f .devcontainer/docker-compose.yml up -d

# Get a shell
docker compose -f .devcontainer/docker-compose.yml exec devcontainer bash

# Stop when done
docker compose -f .devcontainer/docker-compose.yml down
```

## Cloud CLI Credentials

Cloud CLIs (AWS, GCloud, Azure) don't use SSH keys—they need API credentials. Use 1Password CLI's `op run` to inject these on-demand.

### Setup

1. **Store credentials in 1Password** as a secure note or login item with custom fields

2. **Create environment reference files** on your host:

**~/.config/op/aws.env:**
```
AWS_ACCESS_KEY_ID=op://Personal/AWS Credentials/access_key_id
AWS_SECRET_ACCESS_KEY=op://Personal/AWS Credentials/secret_access_key
```

**~/.config/op/gcloud.env:**
```
GOOGLE_APPLICATION_CREDENTIALS=op://Personal/GCloud/service_account_json
```

**~/.config/op/azure.env:**
```
AZURE_CLIENT_ID=op://Personal/Azure Credentials/client_id
AZURE_CLIENT_SECRET=op://Personal/Azure Credentials/client_secret
AZURE_TENANT_ID=op://Personal/Azure Credentials/tenant_id
```

### Usage Inside Container

```bash
# One-off command with credentials injected
op run --env-file=~/.config/op/aws.env -- aws s3 ls

# Add aliases to ~/.bashrc for convenience
alias aws='op run --env-file=~/.config/op/aws.env -- aws'
alias gcloud='op run --env-file=~/.config/op/gcloud.env -- gcloud'
alias az='op run --env-file=~/.config/op/azure.env -- az'
```

1Password will prompt for approval, inject the credentials as environment variables for that single command, then discard them.

## What Gets Mounted

| Host | Container | Purpose |
|------|-----------|---------|
| `~/.1password/agent.sock` | `~/.1password/agent.sock` | SSH agent socket (the magic) |
| `~/.gitconfig` | `~/.gitconfig` | Git user identity (read-only) |
| `~/.config/op/` | `~/.config/op/` | 1Password env reference files (read-only) |
| `~/.claude/` | `~/.claude/` | Claude Code config and auth |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker-in-Docker |

**Note**: No SSH keys, no AWS credentials, no cloud secrets are mounted. Only the socket and non-sensitive config. Claude credentials are mounted from your host's `~/.claude/` directory.

## Security Model

### What's Protected

| Asset | Protection |
|-------|------------|
| SSH private keys | Never on disk—only in 1Password vault |
| Cloud credentials | Injected per-command via `op run`, never persisted |
| Git identity | Only name/email in `.gitconfig` (not sensitive) |

### Access Control

- **Per-use approval**: 1Password can prompt every time a credential is used
- **Biometric option**: Require Touch ID/fingerprint for each use
- **Visibility**: You see exactly which app requested which credential
- **Revocation**: Delete or rotate keys in 1Password—takes effect immediately everywhere

### Trust Boundaries

- The container has no credentials of its own
- Credential access requires 1Password app to be running and unlocked
- If 1Password locks (timeout/manual), container loses credential access
- Compromising the container doesn't leak credentials (no files to steal)

## Troubleshooting

### "Permission denied" on git/ssh

1. Is 1Password desktop app running?
2. Is the vault unlocked?
3. Is SSH agent enabled? (Settings > Developer)
4. Does `~/.1password/agent.sock` exist?

```bash
ls -la ~/.1password/agent.sock
```

### 1Password not prompting

- Check 1Password is in foreground or notifications are enabled
- Try: Settings > Developer > "Ask approval for each new application"

### Container can't connect to socket

Verify the socket is mounted:
```bash
# Inside container
ls -la ~/.1password/agent.sock
```

If missing, check docker-compose.yml volume mounts.

### SSH works on host but not in container

The container's `~/.ssh/config` must also point to the agent:
```bash
# Inside container
cat ~/.ssh/config
# Should show: IdentityAgent ~/.1password/agent.sock
```

### "Host key verification failed"

Add GitHub's host key:
```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

## File Reference

```
ultimate-devcontainer/
├── .devcontainer/
│   ├── Dockerfile          # Container image definition
│   ├── docker-compose.yml  # Volume mounts, environment
│   └── devcontainer.json   # VS Code integration
├── setup-credentials.sh    # Host setup automation
└── README.md              # This file
```

## Comparison: Traditional vs 1Password Approach

| Aspect | Traditional | 1Password |
|--------|-------------|-----------|
| SSH keys | Files in `~/.ssh/` | In vault, accessed via socket |
| Key backup | Manual | Automatic (1Password sync) |
| Key rotation | Edit files everywhere | Update once in 1Password |
| Multi-device | Copy keys around | Automatic sync |
| Audit trail | None | 1Password logs access |
| Container access | Mount key files | Mount socket only |
| If laptop stolen | Keys on disk (encrypted maybe) | Keys in cloud vault only |
| Encrypted folder locked | Devcontainer breaks | Still works |
