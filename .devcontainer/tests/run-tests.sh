#!/bin/bash
# Build and test the devcontainer image
# Run from repo root: .devcontainer/tests/run-tests.sh [--no-build] [--verbose] [--shell]
#
# Options:
#   --no-build    Skip building, just run tests against existing image
#   --verbose     Show detailed test output
#   --shell       After tests, drop into interactive shell

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE_NAME="ultimate-devcontainer-test"

BUILD=true
VERBOSE=""
SHELL_AFTER=false

for arg in "$@"; do
    case $arg in
        --no-build) BUILD=false ;;
        --verbose) VERBOSE="--verbose" ;;
        --shell) SHELL_AFTER=true ;;
    esac
done

cd "$REPO_ROOT"

# Build the image
if $BUILD; then
    echo "Building image..."
    docker build -t "$IMAGE_NAME" -f .devcontainer/Dockerfile .
    echo "Build complete."
    echo
fi

# Prepare env vars
ENV_ARGS=""
if [[ -f .env ]]; then
    source .env
fi
if [[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
    ENV_ARGS="-e OP_SERVICE_ACCOUNT_TOKEN=$OP_SERVICE_ACCOUNT_TOKEN"
fi

# Run tests
echo "Running tests..."
docker run --rm \
    $ENV_ARGS \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$SCRIPT_DIR/test-image.sh:/tmp/test-image.sh:ro" \
    "$IMAGE_NAME" \
    bash /tmp/test-image.sh $VERBOSE

# Optional interactive shell
if $SHELL_AFTER; then
    echo
    echo "Dropping into interactive shell..."
    docker run --rm -it \
        $ENV_ARGS \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "$IMAGE_NAME" \
        bash
fi
