#!/bin/bash
# scripts/03-terminal-utilities.sh
# Terminal Utilities & Tmux Configuration
# Installs CLI tools and configures tmux with gpakosz/.tmux

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Installing CLI Utilities..."

ensure_packages tmux ripgrep fd-find wl-clipboard fzf trash-cli bat neovim ShellCheck

section_header "Installing gpakosz/.tmux configuration..."

if [ -f "$HOME/.tmux/.tmux.conf" ]; then
    info "gpakosz/.tmux already installed, skipping"
else
    step "Downloading and installing gpakosz/.tmux..."
    curl -fsSL "https://github.com/gpakosz/.tmux/raw/refs/heads/master/install.sh" | bash
fi

script_complete "Terminal utilities setup"
