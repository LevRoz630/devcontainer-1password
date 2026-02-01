#!/bin/bash
# Test suite for the Ultimate Dev Container image
# Run: ./test-image.sh [--verbose]

# Ensure ~/.local/bin is in PATH (in case bashrc wasn't sourced)
export PATH="$HOME/.local/bin:$PATH"

VERBOSE="${1:-}"
PASSED=0
FAILED=0
declare -a FAILED_TESTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "$@"; }
pass() { ((PASSED++)) || true; log "${GREEN}✓${NC} $1"; }
fail() { ((FAILED++)) || true; FAILED_TESTS+=("$1"); log "${RED}✗${NC} $1: $2"; }
info() { [[ "$VERBOSE" == "--verbose" ]] && log "${YELLOW}→${NC} $1"; return 0; }
skip() { log "${YELLOW}⊘${NC} $1 (skipped)"; }

# ============================================
# Tool Installation Tests
# ============================================

test_tool_installed() {
    local tool="$1"
    local version_cmd="${2:-$tool --version}"

    if command -v "$tool" &>/dev/null; then
        local ver
        ver=$($version_cmd 2>&1 | head -1) || ver="unknown"
        info "$ver"
        pass "$tool installed"
    else
        fail "$tool installed" "command not found"
    fi
}

log "\n=== Tool Installation Tests ==="

test_tool_installed "node" "node --version"
test_tool_installed "npm" "npm --version"
test_tool_installed "python" "python --version"
test_tool_installed "pip" "pip --version"
test_tool_installed "docker" "docker --version"
test_tool_installed "git" "git --version"
test_tool_installed "gh" "gh --version"
test_tool_installed "aws" "aws --version"
test_tool_installed "gcloud" "gcloud --version"
test_tool_installed "az" "az version"
test_tool_installed "op" "op --version"
test_tool_installed "claude" "claude --version"
test_tool_installed "curl" "curl --version"
test_tool_installed "wget" "wget --version"

# ============================================
# User & Permissions Tests
# ============================================

log "\n=== User & Permissions Tests ==="

current_user=$(whoami)
if [[ "$current_user" == "devuser" ]]; then
    pass "Running as devuser"
else
    fail "Running as devuser" "running as $current_user"
fi

current_uid=$(id -u)
if [[ "$current_uid" == "1000" ]]; then
    pass "UID is 1000"
else
    fail "UID is 1000" "UID is $current_uid"
fi

if sudo -n true 2>/dev/null; then
    pass "Passwordless sudo"
else
    fail "Passwordless sudo" "requires password"
fi

# ============================================
# Directory Structure Tests
# ============================================

log "\n=== Directory Structure Tests ==="

check_dir() {
    local dir="$1"
    local perms="${2:-}"

    if [[ -d "$dir" ]]; then
        if [[ -n "$perms" ]]; then
            local actual_perms
            actual_perms=$(stat -c "%a" "$dir" 2>/dev/null) || actual_perms="unknown"
            if [[ "$actual_perms" == "$perms" ]]; then
                pass "$dir exists with perms $perms"
            else
                fail "$dir perms" "expected $perms, got $actual_perms"
            fi
        else
            pass "$dir exists"
        fi
    else
        fail "$dir exists" "directory not found"
    fi
}

check_dir "$HOME/.ssh" "700"
check_dir "$HOME/.config/op"
check_dir "$HOME/.config/gh"
check_dir "$HOME/.local/bin"

# ============================================
# Script Tests
# ============================================

log "\n=== Script Tests ==="

if [[ -x "$HOME/.local/bin/setup-ssh" ]]; then
    pass "setup-ssh script is executable"
else
    if command -v setup-ssh &>/dev/null; then
        pass "setup-ssh found in PATH"
    else
        fail "setup-ssh script" "not found or not executable"
    fi
fi

if [[ -x "$HOME/.local/bin/clone-repos" ]]; then
    pass "clone-repos script is executable"
else
    if command -v clone-repos &>/dev/null; then
        pass "clone-repos found in PATH"
    else
        fail "clone-repos script" "not found or not executable"
    fi
fi

if [[ -f "$HOME/.bashrc" ]] && grep -q 'setup-ssh\|\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    pass "Scripts configured in .bashrc"
else
    skip "Scripts in .bashrc (may not be baked in yet)"
fi

# ============================================
# Environment Tests
# ============================================

log "\n=== Environment Tests ==="

if [[ -n "$BASH_VERSION" ]]; then
    pass "Bash shell"
else
    fail "Bash shell" "not running bash"
fi

python_ver=$(python --version 2>&1)
if echo "$python_ver" | grep -q "3.11"; then
    pass "Python 3.11 is default"
else
    fail "Python 3.11 is default" "$python_ver"
fi

node_ver=$(node --version 2>&1)
if echo "$node_ver" | grep -q "v20"; then
    pass "Node.js 20 installed"
else
    fail "Node.js 20 installed" "$node_ver"
fi

# ============================================
# 1Password Tests (only if token set)
# ============================================

log "\n=== 1Password Tests ==="

if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    if op account list &>/dev/null; then
        pass "1Password authentication works"

        # Test SSH key retrieval
        if op read "op://DevContainer/Github SSH Key/private_key?ssh-format=openssh" &>/dev/null; then
            pass "Can read SSH key from 1Password"
        else
            fail "Can read SSH key from 1Password" "access denied or not found"
        fi

        # Test GitHub token retrieval
        if op read "op://DevContainer/GitHub Token/token" &>/dev/null; then
            pass "Can read GitHub token from 1Password"
        else
            fail "Can read GitHub token from 1Password" "access denied or not found"
        fi
    else
        fail "1Password authentication works" "op account list failed"
    fi
else
    skip "1Password tests (no token set)"
fi

# ============================================
# SSH Agent Tests
# ============================================

log "\n=== SSH Agent Tests ==="

if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    ssh_result=$(ssh-add -l 2>&1) || true
    if echo "$ssh_result" | grep -q "SHA256\|RSA\|ED25519"; then
        key_count=$(echo "$ssh_result" | wc -l)
        pass "SSH agent running with $key_count key(s)"
    elif echo "$ssh_result" | grep -q "no identities"; then
        pass "SSH agent running (no keys loaded)"
    else
        fail "SSH agent running" "agent not responding"
    fi
else
    skip "SSH agent tests (no agent socket)"
fi

# ============================================
# GitHub CLI Tests
# ============================================

log "\n=== GitHub CLI Tests ==="

if gh auth status &>/dev/null 2>&1; then
    user=$(gh api user --jq '.login' 2>/dev/null) || user="unknown"
    pass "GitHub CLI authenticated as $user"
else
    skip "GitHub CLI tests (not authenticated)"
fi

# ============================================
# Docker Tests
# ============================================

log "\n=== Docker Tests ==="

if [[ -S /var/run/docker.sock ]]; then
    pass "Docker socket mounted"

    if docker ps &>/dev/null 2>&1; then
        pass "Docker daemon accessible"
    else
        # Check if it's a permission issue (expected in standalone tests)
        if docker ps 2>&1 | grep -q "permission denied"; then
            skip "Docker daemon (permission denied - normal in standalone test)"
        else
            fail "Docker daemon accessible" "cannot connect to docker"
        fi
    fi
else
    skip "Docker tests (no socket)"
fi

# ============================================
# Summary
# ============================================

log "\n${BLUE}========================================${NC}"
log "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
log "${BLUE}========================================${NC}"

if [[ $FAILED -gt 0 ]]; then
    log "\nFailed tests:"
    for t in "${FAILED_TESTS[@]}"; do
        log "  ${RED}✗${NC} $t"
    done
    exit 1
fi

exit 0
