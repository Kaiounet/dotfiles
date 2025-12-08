#!/bin/bash
# scripts/05-typst.sh
# Documentation Tools
# Installs Typst CLI for document generation

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Setting up Typst..."

if cmd_exists typst; then
    info "Typst is already installed: $(typst --version)"
else
    step "Installing Typst CLI via cargo..."
    cargo install typst-cli --locked
fi

script_complete "Typst setup"
