#!/bin/bash
set -e

echo "Setting up 1Password-based credential configuration..."
echo ""

# Check for 1Password CLI
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) not found."
    echo "Install it from: https://1password.com/downloads/command-line/"
    exit 1
fi

# Check if 1Password agent socket exists
if [ ! -S ~/.1password/agent.sock ]; then
    echo "Warning: 1Password agent socket not found at ~/.1password/agent.sock"
    echo "Make sure:"
    echo "  1. 1Password desktop app is running"
    echo "  2. SSH Agent is enabled in 1Password Settings > Developer"
    echo ""
fi

# Create SSH config directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create SSH config pointing to 1Password agent
if [ ! -f ~/.ssh/config ]; then
    echo "Creating ~/.ssh/config..."
    cat > ~/.ssh/config << 'EOF'
Host *
    IdentityAgent ~/.1password/agent.sock
EOF
    chmod 600 ~/.ssh/config
    echo "Created ~/.ssh/config"
else
    echo "~/.ssh/config already exists - skipping"
    echo "  Make sure it contains: IdentityAgent ~/.1password/agent.sock"
fi

# Configure git if not already configured
echo ""
echo "Checking git configuration..."

if ! git config --global user.name > /dev/null 2>&1; then
    read -p "Enter your git user.name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
    echo "Set git user.name to: $GIT_NAME"
else
    echo "git user.name already set: $(git config --global user.name)"
fi

if ! git config --global user.email > /dev/null 2>&1; then
    read -p "Enter your git user.email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
    echo "Set git user.email to: $GIT_EMAIL"
else
    echo "git user.email already set: $(git config --global user.email)"
fi

# Set SSH as default for GitHub
git config --global url."git@github.com:".insteadOf "https://github.com/"
echo "Configured git to use SSH for GitHub"

# Set up 1Password credential helper for HTTPS (optional)
git config --global credential.helper "!op plugin run -- gh auth git-credential"
echo "Configured git credential helper for 1Password"

# Create 1Password env reference files
echo ""
echo "Creating 1Password environment reference files..."
mkdir -p ~/.config/op

# AWS
if [ ! -f ~/.config/op/aws.env ]; then
    cat > ~/.config/op/aws.env << 'EOF'
AWS_ACCESS_KEY_ID=op://Personal/AWS Credentials/access_key_id
AWS_SECRET_ACCESS_KEY=op://Personal/AWS Credentials/secret_access_key
EOF
    echo "Created ~/.config/op/aws.env"
else
    echo "~/.config/op/aws.env already exists - skipping"
fi

# GCloud
if [ ! -f ~/.config/op/gcloud.env ]; then
    cat > ~/.config/op/gcloud.env << 'EOF'
GOOGLE_APPLICATION_CREDENTIALS=op://Personal/GCloud/service_account_json
EOF
    echo "Created ~/.config/op/gcloud.env"
else
    echo "~/.config/op/gcloud.env already exists - skipping"
fi

# Azure
if [ ! -f ~/.config/op/azure.env ]; then
    cat > ~/.config/op/azure.env << 'EOF'
AZURE_CLIENT_ID=op://Personal/Azure Credentials/client_id
AZURE_CLIENT_SECRET=op://Personal/Azure Credentials/client_secret
AZURE_TENANT_ID=op://Personal/Azure Credentials/tenant_id
EOF
    echo "Created ~/.config/op/azure.env"
else
    echo "~/.config/op/azure.env already exists - skipping"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create SSH key in 1Password (SSH Key item, Ed25519 recommended)"
echo "  2. Add public key to GitHub: Settings > SSH Keys"
echo "  3. Store cloud credentials in 1Password with matching field names"
echo "  4. Test SSH: ssh -T git@github.com"
echo ""
echo "To use cloud CLIs with 1Password credentials:"
echo "  op run --env-file=~/.config/op/aws.env -- aws s3 ls"
echo ""
