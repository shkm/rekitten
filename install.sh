#!/usr/bin/env bash
#
# rekitten installer
# Sets up rekitten for use with Kitty terminal
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG Base Directories
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Kitty config directory (respect Kitty's own env var)
KITTY_CONFIG_DIR="${KITTY_CONFIG_DIRECTORY:-$XDG_CONFIG_HOME/kitty}"
KITTY_CONF="$KITTY_CONFIG_DIR/kitty.conf"

# rekitten state directory
REKITTEN_STATE_DIR="${REKITTEN_STATE_DIR:-$XDG_STATE_HOME/rekitten}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Kitty is installed
if ! command -v kitty &> /dev/null && ! command -v kitten &> /dev/null; then
    error "Kitty terminal not found. Please install Kitty first."
    exit 1
fi

# Ensure Kitty config directory exists
mkdir -p "$KITTY_CONFIG_DIR"

# Copy rekitten package to Kitty config directory
REKITTEN_PKG_DIR="$KITTY_CONFIG_DIR/rekitten"
REKITTEN_SOURCE="$SCRIPT_DIR/rekitten"

if [[ -d "$REKITTEN_PKG_DIR" ]]; then
    info "Removing existing rekitten package"
    rm -rf "$REKITTEN_PKG_DIR"
fi

# Also clean up old symlink-based installation if present
OLD_WATCHER_LINK="$KITTY_CONFIG_DIR/rekitten_watcher.py"
if [[ -L "$OLD_WATCHER_LINK" ]] || [[ -f "$OLD_WATCHER_LINK" ]]; then
    info "Removing old watcher symlink/file"
    rm -f "$OLD_WATCHER_LINK"
fi

info "Copying rekitten package to $REKITTEN_PKG_DIR"
cp -R "$REKITTEN_SOURCE" "$REKITTEN_PKG_DIR"

WATCHER_PATH="$REKITTEN_PKG_DIR/watcher.py"

# Create rekitten state directory and empty session file
mkdir -p "$REKITTEN_STATE_DIR"
touch "$REKITTEN_STATE_DIR/session"
info "Created state directory at $REKITTEN_STATE_DIR"

# Check if kitty.conf exists
if [[ ! -f "$KITTY_CONF" ]]; then
    info "Creating kitty.conf"
    touch "$KITTY_CONF"
fi

# Comment out existing config line if present (not from rekitten)
comment_out_existing() {
    local key="$1"
    if grep -q "^${key}" "$KITTY_CONF" 2>/dev/null; then
        # Don't comment out rekitten lines
        if ! grep "^${key}" "$KITTY_CONF" | grep -q "rekitten"; then
            local tmp="$KITTY_CONF.tmp"
            sed "s/^${key}/# &/" "$KITTY_CONF" > "$tmp" && mv "$tmp" "$KITTY_CONF"
            info "Commented out existing ${key} line"
        fi
    fi
}

# Add config line
add_config_line() {
    local line="$1"
    local pattern="$2"

    if grep -q "^${pattern}" "$KITTY_CONF" 2>/dev/null; then
        warn "Config already contains: $pattern (skipping)"
    else
        echo "$line" >> "$KITTY_CONF"
        info "Added to kitty.conf: $line"
    fi
}

echo ""
info "Updating kitty.conf..."

# Comment out existing watcher/startup_session if not from rekitten
comment_out_existing "watcher"
comment_out_existing "startup_session"

# Add rekitten section if not present
if ! grep -q "^# rekitten" "$KITTY_CONF" 2>/dev/null; then
    echo "" >> "$KITTY_CONF"
    echo "# rekitten - persistent tab sessions" >> "$KITTY_CONF"
fi

add_config_line "watcher $WATCHER_PATH" "watcher.*rekitten"
add_config_line "startup_session $REKITTEN_STATE_DIR/session" "startup_session.*rekitten"

echo ""
info "Installation complete! Restart Kitty for changes to take effect."
