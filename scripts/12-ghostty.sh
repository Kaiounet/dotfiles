#!/usr/bin/env bash
# scripts/12-ghostty.sh
# Install Ghostty on Fedora using the community COPR package if available,
# otherwise attempt the Terra repo, then fall back to a universal AppImage.
#
# Behavior:
#  - If `ghostty` is already installed (in PATH), the script exits successfully.
#  - Prefer the Fedora COPR package (scottames/ghostty).
#  - If COPR install fails, try the Terra repo method shown in upstream docs.
#  - If DNF-based installs aren't possible, attempt to fetch the AppImage from
#    the project's GitHub releases and install it to /usr/local/bin.
#  - Deploys tracked ghostty config from dotfiles repo to ~/.config/ghostty
#
# Notes:
#  - This script assumes a Fedora-like system with `dnf` and `sudo` available.
#  - Run interactively (it will call `sudo`).

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

DOTFILES_ROOT="$(get_dotfiles_root)"
INSTALL_PATH="/usr/local/bin/ghostty"
SRC_CONFIG_DIR="$DOTFILES_ROOT/.config/ghostty"
DEST_CONFIG_DIR="$HOME/.config/ghostty"

# ─────────────────────────────────────────────────────────────────────────────
# Config Deployment
# ─────────────────────────────────────────────────────────────────────────────

# Deploy tracked ghostty configuration directory (if present) into ~/.config
deploy_ghostty_config() {
    if [ ! -d "$SRC_CONFIG_DIR" ]; then
        info "No tracked Ghostty config at $SRC_CONFIG_DIR; skipping deploy"
        return 0
    fi

    step "Deploying tracked Ghostty config from $SRC_CONFIG_DIR"

    # Ensure parent config directory exists
    mkdir -p "$HOME/.config"

    # If destination exists and differs, back it up
    if [ -d "$DEST_CONFIG_DIR" ]; then
        backup_dir "$DEST_CONFIG_DIR"
    fi

    # Copy tracked config into place
    if cp -a "$SRC_CONFIG_DIR" "$DEST_CONFIG_DIR"; then
        success "Ghostty config deployed to $DEST_CONFIG_DIR"
    else
        warn "Failed to copy Ghostty config from $SRC_CONFIG_DIR to $DEST_CONFIG_DIR"
    fi
}

# Ensure config deployment runs at exit (successful or not)
trap deploy_ghostty_config EXIT

# ─────────────────────────────────────────────────────────────────────────────
# Installation Methods
# ─────────────────────────────────────────────────────────────────────────────

# Attempt COPR install
install_via_copr() {
    if ! cmd_exists dnf; then
        warn "dnf not found; cannot use COPR method"
        return 1
    fi

    step "Attempting to enable COPR scottames/ghostty and install via dnf..."

    if sudo dnf copr enable -y scottames/ghostty; then
        if sudo dnf install -y ghostty; then
            success "Installed ghostty via COPR"
            return 0
        else
            warn "dnf install from COPR failed"
            return 1
        fi
    else
        warn "dnf copr enable failed (plugin or network issue)"
        return 1
    fi
}

# Attempt Terra repo install
install_via_terra() {
    if ! cmd_exists dnf; then
        warn "dnf not found; cannot use Terra repo method"
        return 1
    fi

    step "Attempting to install ghostty via Terra repo (community package)..."

    if sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release -y; then
        if sudo dnf install -y ghostty; then
            success "Installed ghostty via Terra repo"
            return 0
        else
            warn "dnf install from Terra repo failed"
            return 1
        fi
    else
        warn "Failed to add Terra repo (network or repo missing)"
        return 1
    fi
}

# Fallback: download AppImage from GitHub releases
install_appimage_fallback() {
    step "Falling back to AppImage install from GitHub releases..."

    local API_URL="https://api.github.com/repos/ghostty-org/ghostty/releases/latest"
    local download_url=""
    local tmpdir=""
    local tmpfile=""

    # Check for required tools
    for cmd in curl sudo; do
        if ! cmd_exists "$cmd"; then
            warn "Required tool '$cmd' not found"
            return 1
        fi
    done

    tmpdir="$(mktemp -d)"
    # Clean up temp directory on function exit
    trap 'rm -rf "$tmpdir"' RETURN

    step "Querying GitHub releases for latest AppImage..."

    # Try to use jq if available for robust parsing
    if cmd_exists jq; then
        download_url=$(curl -sSfL "$API_URL" | jq -r '.assets[] | select(.name|test("(?i)appimage")) | .browser_download_url' | head -n1 || true)
    else
        # Minimal grep/sed fallback (less robust)
        download_url=$(curl -sSfL "$API_URL" | grep -Eo '"browser_download_url":[^,]+' | grep -i appimage | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
    fi

    if [ -z "$download_url" ]; then
        warn "Couldn't find an AppImage asset in the latest release"
        return 1
    fi

    info "Found AppImage: $download_url"
    tmpfile="$tmpdir/Ghostty.appimage"

    step "Downloading AppImage..."
    if ! curl -fSL -o "$tmpfile" "$download_url"; then
        warn "Failed to download AppImage"
        return 1
    fi

    chmod a+x "$tmpfile"

    step "Installing to $INSTALL_PATH (requires sudo)..."
    if sudo mkdir -p "$(dirname "$INSTALL_PATH")" && sudo mv "$tmpfile" "$INSTALL_PATH"; then
        sudo chmod a+x "$INSTALL_PATH"
        success "Installed ghostty AppImage to $INSTALL_PATH"
        return 0
    else
        warn "Failed to move AppImage to $INSTALL_PATH"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    section_header "Installing Ghostty Terminal..."

    # Quick check: already installed?
    if cmd_exists ghostty; then
        info "ghostty is already installed at $(command -v ghostty)"
        return 0
    fi

    # Try installation methods in order of preference
    if install_via_copr; then
        return 0
    fi

    if install_via_terra; then
        return 0
    fi

    if install_appimage_fallback; then
        return 0
    fi

    # All methods failed
    err "All install methods failed. Please install ghostty manually:"
    echo ""
    echo "  COPR:"
    echo "    sudo dnf copr enable scottames/ghostty"
    echo "    sudo dnf install ghostty"
    echo ""
    echo "  Terra (community):"
    echo "    sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra\$releasever' terra-release"
    echo "    sudo dnf install ghostty"
    echo ""
    echo "  AppImage (manual):"
    echo "    Download the .appimage from https://github.com/ghostty-org/ghostty/releases"
    echo "    chmod a+x Ghostty-*.appimage"
    echo "    sudo mv Ghostty-*.appimage /usr/local/bin/ghostty"
    return 1
}

main "$@"
script_complete "Ghostty setup"
