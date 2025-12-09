#!/bin/bash
# scripts/00-system-core.sh
# System Core & Build Tools
# Updates system and installs essential build dependencies

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Updating System & Installing Build Essentials"

step "Updating system packages..."
sudo dnf update -y

step "Refreshing DNF metadata..."
if ! sudo dnf makecache --refresh; then
    warn "DNF metadata refresh failed; package groups might be stale"
fi

step "Installing Development Tools group..."
if ! sudo dnf group install "Development Tools" -y; then
    warn "Development Tools group unavailable; installing essential packages individually"
fi

step "Installing essential build dependencies..."
ensure_packages git curl wget unzip tar cmake fuse-libs openssl-devel rust cargo

script_complete "System core setup"
