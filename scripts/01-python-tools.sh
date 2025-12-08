#!/bin/bash
# scripts/01-python-tools.sh
# Python Tools via PIPX
# Installs pipx for isolated Python tool management

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

header "Installing Pipx..."

ensure_packages pipx

# Fallback if pipx package name differs
if ! cmd_exists pipx; then
    step "Trying alternative package name: python3-pipx"
    sudo dnf install -y python3-pipx
fi

info "PATH is managed via dotfiles shell templates; skipping pipx ensurepath"

script_complete "Python tools setup"
