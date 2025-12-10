#!/bin/bash
# scripts/10-user-apps.sh
# User Applications
# Installs Flatpak apps (keeps user-level app selection minimal)

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Flatpak Setup
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing Flatpak Apps..."

# Ensure Flathub remote is configured
if ! flatpak remote-list | grep -q flathub; then
    step "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    info "Flathub remote already configured"
fi

# Install Flatpak applications (leave browser choice to each user)
ensure_flatpak com.bitwarden.desktop
ensure_flatpak com.mattjakeman.ExtensionManager
ensure_flatpak org.libreoffice.LibreOffice

script_complete "User apps setup"
