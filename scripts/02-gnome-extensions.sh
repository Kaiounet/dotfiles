#!/bin/bash
# scripts/02-gnome-extensions.sh
# GNOME Extensions Setup
# Installs GNOME shell extensions and extension manager

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Installing GNOME Extensions..."

# Install GNOME extensions from DNF
ensure_packages \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-blur-my-shell

# Install gnome-extensions-cli via pipx if not available
if ! cmd_exists gext; then
    step "Installing gnome-extensions-cli via pipx..."
    pipx install gnome-extensions-cli --force
fi

# Install community extensions
step "Fetching Community Extensions..."
GEXT_BIN="$HOME/.local/bin/gext"

if [ -x "$GEXT_BIN" ]; then
    "$GEXT_BIN" install Vitals@CoreCoding.com || warn "Failed to install Vitals extension"
    "$GEXT_BIN" install clipboard-indicator@tudmotu.com || warn "Failed to install clipboard-indicator extension"
else
    warn "gext not found at $GEXT_BIN, skipping community extensions"
fi

script_complete "GNOME extensions setup"
