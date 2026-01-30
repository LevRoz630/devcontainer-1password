#!/bin/bash
# Load credentials from 1Password for devcontainer

set -e

# Check for OP_SERVICE_ACCOUNT_TOKEN
if [ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    echo "Warning: OP_SERVICE_ACCOUNT_TOKEN not set, skipping credential setup"
    exit 0
fi

# Check for op CLI
if ! command -v op &> /dev/null; then
    echo "Warning: 1Password CLI not found, skipping credential setup"
    exit 0
fi

# --- SSH Key ---
echo "Setting up SSH..."
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >> ~/.bashrc
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.bashrc
fi

op read "op://DevContainer/Github SSH Key/private_key" | ssh-add - && echo "SSH key loaded" || echo "Warning: Failed to load SSH key"

# --- GitHub CLI ---
echo "Setting up GitHub CLI..."
GH_TOKEN=$(op read "op://DevContainer/GitHub Token/credential" 2>/dev/null) && \
    echo "$GH_TOKEN" | gh auth login --with-token && \
    echo "GitHub CLI authenticated" || echo "Warning: Failed to authenticate gh"

echo "Credential setup complete"
