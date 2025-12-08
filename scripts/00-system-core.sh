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

step "Installing Development Tools group..."
sudo dnf group install "Development Tools" -y

step "Installing essential build dependencies..."
ensure_packages git curl wget unzip tar cmake fuse-libs openssl-devel rust cargo

script_complete "System core setup"
