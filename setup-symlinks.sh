#!/bin/bash
set -e

echo "Setting up symlinks to centralize credentials..."
echo ""
echo "This will:"
echo "1. Backup your current credential files/directories"
echo "2. Replace them with symlinks to ~/.devcontainer-secrets/"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

BACKUP_DIR=~/.credentials-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

echo ""
echo "Creating backup at: $BACKUP_DIR"

# SSH
if [ -d ~/.ssh ] && [ ! -L ~/.ssh ]; then
    echo "Backing up ~/.ssh..."
    mv ~/.ssh "$BACKUP_DIR/ssh"
    ln -s ~/.devcontainer-secrets/ssh ~/.ssh
    echo "✓ ~/.ssh → ~/.devcontainer-secrets/ssh"
fi

# Git config
if [ -f ~/.gitconfig ] && [ ! -L ~/.gitconfig ]; then
    echo "Backing up ~/.gitconfig..."
    mv ~/.gitconfig "$BACKUP_DIR/gitconfig"
    ln -s ~/.devcontainer-secrets/gitconfig ~/.gitconfig
    echo "✓ ~/.gitconfig → ~/.devcontainer-secrets/gitconfig"
fi

# GitHub CLI
if [ -d ~/.config/gh ] && [ ! -L ~/.config/gh ]; then
    echo "Backing up ~/.config/gh..."
    mv ~/.config/gh "$BACKUP_DIR/gh"
    ln -s ~/.devcontainer-secrets/gh ~/.config/gh
    echo "✓ ~/.config/gh → ~/.devcontainer-secrets/gh"
fi

# AWS
if [ -d ~/.aws ] && [ ! -L ~/.aws ]; then
    echo "Backing up ~/.aws..."
    mv ~/.aws "$BACKUP_DIR/aws"
    ln -s ~/.devcontainer-secrets/aws ~/.aws
    echo "✓ ~/.aws → ~/.devcontainer-secrets/aws"
fi

# Docker
if [ -d ~/.docker ] && [ ! -L ~/.docker ]; then
    echo "Backing up ~/.docker..."
    mv ~/.docker "$BACKUP_DIR/docker"
    ln -s ~/.devcontainer-secrets/docker ~/.docker
    echo "✓ ~/.docker → ~/.devcontainer-secrets/docker"
fi

# Claude
if [ -d ~/.claude ] && [ ! -L ~/.claude ]; then
    echo "Backing up ~/.claude..."
    mv ~/.claude "$BACKUP_DIR/claude"
    ln -s ~/.devcontainer-secrets/claude ~/.claude
    echo "✓ ~/.claude → ~/.devcontainer-secrets/claude"
fi

# GCloud
if [ -d ~/.config/gcloud ] && [ ! -L ~/.config/gcloud ]; then
    echo "Backing up ~/.config/gcloud..."
    mv ~/.config/gcloud "$BACKUP_DIR/gcloud"
    ln -s ~/.devcontainer-secrets/gcloud ~/.config/gcloud
    echo "✓ ~/.config/gcloud → ~/.devcontainer-secrets/gcloud"
fi

# Azure
if [ -d ~/.azure ] && [ ! -L ~/.azure ]; then
    echo "Backing up ~/.azure..."
    mv ~/.azure "$BACKUP_DIR/azure"
    ln -s ~/.devcontainer-secrets/azure ~/.azure
    echo "✓ ~/.azure → ~/.devcontainer-secrets/azure"
fi

echo ""
echo "✓ Symlinks created successfully!"
echo ""
echo "Backups stored in: $BACKUP_DIR"
echo ""
echo "To rollback if needed:"
echo "  rm ~/.ssh ~/.gitconfig ~/.config/gh ~/.aws ~/.docker ~/.claude"
echo "  mv $BACKUP_DIR/* ~/"
echo ""
echo "Testing credentials..."
echo ""

# Test commands
echo "SSH config:"
ls -la ~/.ssh/config 2>/dev/null && echo "  ✓ SSH config accessible" || echo "  ✗ SSH config not found"

echo "Git config:"
git config user.name 2>/dev/null && echo "  ✓ Git config accessible" || echo "  ✗ Git config not found"

echo "GitHub CLI:"
gh --version 2>/dev/null && echo "  ✓ gh CLI accessible" || echo "  ✗ gh CLI not found"

echo "Claude:"
claude --version 2>/dev/null && echo "  ✓ Claude CLI accessible" || echo "  ✗ Claude CLI not found"

echo ""
echo "All credentials now managed from: ~/.devcontainer-secrets/"
echo "✓ One source of truth for host AND containers!"
