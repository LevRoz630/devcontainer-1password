#!/bin/bash
# Interactive repo cloning from GitHub

set -e

CLONE_DIR="${1:-/workspace/projects}"
mkdir -p "$CLONE_DIR"

# Check gh auth
if ! gh auth status &>/dev/null; then
    echo "Error: GitHub CLI not authenticated. Run setup-ssh.sh first."
    exit 1
fi

echo "Fetching your repositories..."
repos=$(gh repo list --limit 50 --json nameWithOwner,pushedAt --jq 'sort_by(.pushedAt) | reverse | .[].nameWithOwner')

if [ -z "$repos" ]; then
    echo "No repositories found."
    exit 0
fi

# Display repos with numbers
echo ""
echo "Your repositories (sorted by recent activity):"
echo "------------------------------------------------"
i=1
declare -a repo_array
while IFS= read -r repo; do
    repo_array+=("$repo")
    echo "  $i) $repo"
    ((i++))
done <<< "$repos"

echo ""
echo "Enter numbers to clone (e.g., 1,3,5 or 1-3 or 'all'):"
echo "Press Enter to skip."
read -r selection

if [ -z "$selection" ]; then
    echo "No repos selected."
    exit 0
fi

# Parse selection
selected=()
if [ "$selection" = "all" ]; then
    selected=("${repo_array[@]}")
else
    IFS=',' read -ra parts <<< "$selection"
    for part in "${parts[@]}"; do
        part=$(echo "$part" | tr -d ' ')
        if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start=${BASH_REMATCH[1]}
            end=${BASH_REMATCH[2]}
            for ((j=start; j<=end; j++)); do
                idx=$((j-1))
                if [ $idx -ge 0 ] && [ $idx -lt ${#repo_array[@]} ]; then
                    selected+=("${repo_array[$idx]}")
                fi
            done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            idx=$((part-1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#repo_array[@]} ]; then
                selected+=("${repo_array[$idx]}")
            fi
        fi
    done
fi

# Clone selected repos
echo ""
echo "Cloning ${#selected[@]} repo(s) to $CLONE_DIR..."
cd "$CLONE_DIR"

for repo in "${selected[@]}"; do
    repo_name=$(basename "$repo")
    if [ -d "$repo_name" ]; then
        echo "Skipping $repo (already exists)"
    else
        echo "Cloning $repo..."
        gh repo clone "$repo" -- --depth=1
    fi
done

echo ""
echo "Done! Repos cloned to $CLONE_DIR"
