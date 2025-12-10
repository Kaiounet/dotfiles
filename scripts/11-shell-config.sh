#!/bin/bash
# scripts/11-shell-config.sh
# Shell Configuration
# Symlinks (default) or copies ~/.bashrc and ~/.bashrc_local from dotfiles
#
# Usage:
#   ./11-shell-config.sh          # Uses symlinks (default, recommended)
#   ./11-shell-config.sh --copy   # Copies files instead of symlinking
#   COPY_MODE=1 ./11-shell-config.sh  # Alternative way to enable copy mode

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

DOTFILES_ROOT="$(get_dotfiles_root)"

# Source files in the dotfiles repo
SRC_BASHRC="$DOTFILES_ROOT/.config/bash/.bashrc"
SRC_BASHRC_LOCAL="$DOTFILES_ROOT/.config/bash/.bashrc_local"
SRC_STARSHIP="$DOTFILES_ROOT/.config/starship/starship.toml"

# Destination files in user's home
DEST_BASHRC="$HOME/.bashrc"
DEST_BASHRC_LOCAL="$HOME/.bashrc_local"
DEST_STARSHIP="$HOME/.config/starship.toml"

# Determine mode: symlink (default) or copy
USE_COPY_MODE="${COPY_MODE:-0}"

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        --copy)
            USE_COPY_MODE=1
            ;;
        --symlink)
            USE_COPY_MODE=0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --symlink   Use symlinks (default, recommended for dotfiles management)"
            echo "  --copy      Copy files instead of symlinking (for standalone customization)"
            echo "  --help      Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  COPY_MODE=1   Enable copy mode (equivalent to --copy)"
            exit 0
            ;;
        *)
            warn "Unknown argument: $arg"
            ;;
    esac
done

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

section_header "Finalizing shell configuration..."

if [ "$USE_COPY_MODE" = "1" ]; then
    info "Using COPY mode (files will be copied, not symlinked)"
    DEPLOY_FUNC="safe_copy"
else
    info "Using SYMLINK mode (recommended for dotfiles management)"
    DEPLOY_FUNC="safe_symlink"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Deploy ~/.bashrc
# ─────────────────────────────────────────────────────────────────────────────

step "Deploying ~/.bashrc..."

if [ -f "$SRC_BASHRC" ]; then
    $DEPLOY_FUNC "$SRC_BASHRC" "$DEST_BASHRC" || true
else
    warn "Tracked .bashrc template not found at $SRC_BASHRC; skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Deploy ~/.bashrc_local
# ─────────────────────────────────────────────────────────────────────────────

step "Deploying ~/.bashrc_local..."

if [ -f "$SRC_BASHRC_LOCAL" ]; then
    $DEPLOY_FUNC "$SRC_BASHRC_LOCAL" "$DEST_BASHRC_LOCAL" || true
else
    warn "Tracked .bashrc_local not found at $SRC_BASHRC_LOCAL"

    # Create an empty .bashrc_local if it doesn't exist
    if [ ! -e "$DEST_BASHRC_LOCAL" ]; then
        step "Creating empty ~/.bashrc_local..."
        cat > "$DEST_BASHRC_LOCAL" <<'EOF'
# Local bash customizations
# This file is sourced by ~/.bashrc
# Add your personal aliases, exports, and functions here.

EOF
        info "Created empty $DEST_BASHRC_LOCAL"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Deploy Starship configuration
# ─────────────────────────────────────────────────────────────────────────────

step "Deploying Starship configuration..."

# Ensure ~/.config exists
mkdir -p "$HOME/.config"

if [ -f "$SRC_STARSHIP" ]; then
    $DEPLOY_FUNC "$SRC_STARSHIP" "$DEST_STARSHIP" || true
else
    warn "Starship config not found at $SRC_STARSHIP; skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Create ~/.bashrc.d directory (optional modular config)
# ─────────────────────────────────────────────────────────────────────────────

BASHRC_D="$HOME/.bashrc.d"
if [ ! -d "$BASHRC_D" ]; then
    step "Creating ~/.bashrc.d directory for modular configs..."
    mkdir -p "$BASHRC_D"
    info "Created $BASHRC_D (you can place additional shell snippets here)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo ""
if [ "$USE_COPY_MODE" = "1" ]; then
    info "Shell config files have been COPIED to your home directory."
    info "You can freely edit them without affecting the dotfiles repo."
else
    info "Shell config files have been SYMLINKED to the dotfiles repo."
    info "Changes in the repo will be reflected immediately."
    info "To switch to copy mode, run: $0 --copy"
fi

script_complete "Shell configuration"
