#!/bin/bash
# scripts/14-starship.sh
# Starship Prompt Installation & Configuration
# Installs Starship cross-shell prompt and deploys configuration

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

DOTFILES_ROOT="$(get_dotfiles_root)"
STARSHIP_CONFIG_SRC="$DOTFILES_ROOT/.config/starship/starship.toml"
STARSHIP_CONFIG_DEST="$HOME/.config/starship.toml"

# ─────────────────────────────────────────────────────────────────────────────
# Install Starship
# ─────────────────────────────────────────────────────────────────────────────

section_header "Installing Starship prompt..."

if cmd_exists starship; then
    info "Starship is already installed: $(starship --version)"
else
    step "Installing Starship via official installer..."
    # The official installer detects the platform and installs to ~/.local/bin
    # We use -y to skip confirmation
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"

    # Verify installation
    if cmd_exists starship; then
        success "Starship installed successfully: $(starship --version)"
    else
        # ~/.local/bin might not be in PATH yet in this session
        if [ -x "$HOME/.local/bin/starship" ]; then
            success "Starship installed to ~/.local/bin/starship"
            info "It will be available after reloading your shell"
        else
            err "Starship installation failed"
            exit 1
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Deploy Starship configuration
# ─────────────────────────────────────────────────────────────────────────────

section_header "Deploying Starship configuration..."

# Ensure config directory exists
mkdir -p "$HOME/.config"

if [ -f "$STARSHIP_CONFIG_SRC" ]; then
    safe_symlink "$STARSHIP_CONFIG_SRC" "$STARSHIP_CONFIG_DEST" || true
else
    warn "Starship config not found at $STARSHIP_CONFIG_SRC"

    if [ ! -f "$STARSHIP_CONFIG_DEST" ]; then
        step "Creating default Starship configuration..."
        cat > "$STARSHIP_CONFIG_DEST" <<'EOF'
# Starship Configuration
# Documentation: https://starship.rs/config/
#
# Starship has excellent defaults - we only override what we want different.
# Most modules auto-detect and display only when relevant.

# Timeout for commands executed by starship (in milliseconds)
command_timeout = 1000

# Show exit code on failure
[status]
disabled = false
EOF
        info "Created default config at $STARSHIP_CONFIG_DEST"
    else
        info "Starship config already exists at $STARSHIP_CONFIG_DEST"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo ""
info "Starship is ready!"
info "Make sure your ~/.bashrc_local initializes Starship with:"
echo ""
echo '    eval "$(starship init bash)"'
echo ""
info "Configuration file: $STARSHIP_CONFIG_DEST"
info "Customize it by editing the TOML file or run: starship configure"

script_complete "Starship prompt setup"
