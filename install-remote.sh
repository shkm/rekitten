#!/usr/bin/env bash
#
# rekitten remote installer
# Usage: curl -fsSL https://raw.githubusercontent.com/shkm/rekitten/main/install-remote.sh | bash
#

set -euo pipefail

REPO_URL="https://github.com/shkm/rekitten.git"
TMPDIR="${TMPDIR:-/tmp}"
INSTALL_DIR="$TMPDIR/rekitten-install-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
  fi
}

trap cleanup EXIT

# Check dependencies
if ! command -v git &>/dev/null; then
  error "git is required but not installed"
  exit 1
fi

if ! command -v kitty &>/dev/null && ! command -v kitten &>/dev/null; then
  error "Kitty terminal not found. Please install Kitty first."
  exit 1
fi

info "Cloning rekitten..."
git clone --depth 1 --quiet "$REPO_URL" "$INSTALL_DIR"

info "Running installer..."
"$INSTALL_DIR/install.sh"

info "Cleaning up..."
# cleanup runs via trap
