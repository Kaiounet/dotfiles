#!/bin/bash
# scripts/08-data-science.sh
# Data Science & ML Setup
# Installs Miniconda for conda environment management

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Installing Miniconda..."

MINICONDA_DIR="$HOME/.local/miniconda3"

if [ -d "$MINICONDA_DIR" ] && [ -x "$MINICONDA_DIR/bin/conda" ]; then
    info "Miniconda already installed at $MINICONDA_DIR"
    info "Conda version: $("$MINICONDA_DIR/bin/conda" --version 2>/dev/null || echo 'unknown')"
else
    step "Downloading Miniconda installer..."
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    TMP_INSTALLER="/tmp/miniconda.sh"

    if wget -q "$MINICONDA_URL" -O "$TMP_INSTALLER"; then
        step "Installing Miniconda to $MINICONDA_DIR..."
        bash "$TMP_INSTALLER" -b -p "$MINICONDA_DIR"
        rm -f "$TMP_INSTALLER"

        step "Configuring conda (disabling auto_activate_base)..."
        "$MINICONDA_DIR/bin/conda" config --set auto_activate_base false

        info "Shell init skipped; managed by dotfiles templates"
        success "Miniconda installed successfully"
    else
        warn "Failed to download Miniconda installer from $MINICONDA_URL"
    fi
fi

script_complete "Data science setup"
