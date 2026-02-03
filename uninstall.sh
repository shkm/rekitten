#!/usr/bin/env bash
#
# rekitten uninstaller
# Removes rekitten from Kitty configuration
#

set -euo pipefail

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

# Remove rekitten package directory
REKITTEN_PKG_DIR="$KITTY_CONFIG_DIR/rekitten"
if [[ -d "$REKITTEN_PKG_DIR" ]]; then
    rm -rf "$REKITTEN_PKG_DIR"
    info "Removed rekitten package"
else
    warn "rekitten package not found at $REKITTEN_PKG_DIR"
fi

# Also clean up old symlink-based installation if present
OLD_WATCHER_LINK="$KITTY_CONFIG_DIR/rekitten_watcher.py"
if [[ -L "$OLD_WATCHER_LINK" ]] || [[ -f "$OLD_WATCHER_LINK" ]]; then
    rm -f "$OLD_WATCHER_LINK"
    info "Removed old watcher symlink/file"
fi

# Remove rekitten lines from kitty.conf
if [[ -f "$KITTY_CONF" ]]; then
    # Create backup
    cp "$KITTY_CONF" "$KITTY_CONF.bak"
    info "Created backup at $KITTY_CONF.bak"

    # Remove rekitten-related lines
    grep -v "rekitten" "$KITTY_CONF.bak" > "$KITTY_CONF" || true
    info "Removed rekitten configuration from kitty.conf"
fi

echo ""
info "Uninstallation complete!"
echo ""
echo "Note: The rekitten state directory was preserved at:"
echo "  $REKITTEN_STATE_DIR"
echo ""
echo "To remove it completely:"
echo "  rm -rf $REKITTEN_STATE_DIR"
echo ""
echo "Please restart Kitty for changes to take effect."
