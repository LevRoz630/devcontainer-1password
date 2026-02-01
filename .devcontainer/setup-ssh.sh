#!/bin/bash
# Load credentials from 1Password for devcontainer
#
# Authentication priority:
#   1. Service account token (OP_SERVICE_ACCOUNT_TOKEN) - fully automatic
#   2. Existing account config - just enter master password
#   3. No account - guided setup, then enter master password
#
# Usage:
#   setup-ssh                # Auto-detect best method
#   setup-ssh --interactive  # Skip service account, use interactive

# Check for op CLI
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI not found"
    exit 1
fi

# Check if running interactively
if [ ! -t 0 ]; then
    # Non-interactive (e.g., postStartCommand)
    if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
        echo "Using 1Password service account..."
    else
        echo "No OP_SERVICE_ACCOUNT_TOKEN set."
        echo "Run 'setup-ssh' in a terminal to set up credentials."
        exit 0
    fi
else
    # Interactive terminal
    FORCE_INTERACTIVE=false
    [[ "$1" == "--interactive" || "$1" == "-i" ]] && FORCE_INTERACTIVE=true

    # Source .env if token not set
    if [ -z "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
        for f in "/workspaces/devcontainer-1password/.env" "$HOME/.env" "./.env"; do
            [ -f "$f" ] && source "$f" 2>/dev/null && break
        done
    fi

    # Use service account if available (unless forced interactive)
    if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ] && [ "$FORCE_INTERACTIVE" = false ]; then
        echo "Using 1Password service account..."
    else
        # Interactive signin
        echo ""

        # Check if any accounts are configured
        if op account list 2>/dev/null | grep -q "\.1password\."; then
            # Account exists, just need to signin
            echo "1Password account found. Enter your master password:"
            echo ""
            if ! eval $(op signin 2>&1); then
                echo "Signin failed"
                exit 1
            fi
        else
            # No account, need to add one first
            echo "No 1Password account configured. Let's set one up."
            echo ""
            echo "You'll need:"
            echo "  - Sign-in address (e.g., my.1password.com or my.1password.eu)"
            echo "  - Email address"
            echo "  - Secret key (starts with A3-)"
            echo "  - Master password"
            echo ""
            read -p "Continue? [Y/n] " confirm
            [[ "$confirm" =~ ^[Nn] ]] && exit 0
            echo ""

            # Get account details
            read -p "Sign-in address (e.g., my.1password.eu): " signin_address
            read -p "Email: " email
            read -p "Secret key: " secret_key
            echo ""

            # Add and signin
            echo "Adding account and signing in..."
            echo "(Enter your master password when prompted)"
            echo ""
            if ! eval $(op account add --address "$signin_address" --email "$email" --secret-key "$secret_key" --signin 2>&1); then
                echo ""
                echo "Failed to add account. Please check your details and try again."
                exit 1
            fi
        fi
        echo ""
        echo "Signed in to 1Password!"
    fi
fi

# Verify authentication works
if ! op vault list &>/dev/null 2>&1; then
    echo "Error: 1Password authentication failed"
    exit 1
fi

# --- SSH Setup ---
echo ""
echo "Setting up SSH..."

# Start agent if needed
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Configure SSH
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat > ~/.ssh/config << 'EOF'
Host *
    AddKeysToAgent yes
EOF
chmod 600 ~/.ssh/config

# Load key from 1Password
if op read "op://DevContainer/Github SSH Key/private_key?ssh-format=openssh" 2>/dev/null | ssh-add - 2>/dev/null; then
    echo "  SSH key loaded"
else
    echo "  Warning: Failed to load SSH key"
    echo "  (Ensure 'DevContainer' vault has 'Github SSH Key' item)"
fi

# --- GitHub CLI ---
echo "Setting up GitHub CLI..."
if GH_TOKEN=$(op read "op://DevContainer/GitHub Token/token" 2>/dev/null); then
    if echo "$GH_TOKEN" | gh auth login --with-token 2>/dev/null; then
        echo "  Authenticated"
    else
        echo "  Warning: Failed to authenticate"
    fi
else
    echo "  Warning: Could not read token"
    echo "  (Ensure 'DevContainer' vault has 'GitHub Token' item)"
fi

# Summary
echo ""
echo "=== Done ==="
echo "SSH keys: $(ssh-add -l 2>/dev/null | wc -l | tr -d ' ')"
echo "GitHub: $(gh api user --jq '.login' 2>/dev/null || echo 'not authenticated')"
