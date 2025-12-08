#!/bin/bash
# scripts/09-docker.sh
# Docker & Container Tools
# Installs Docker and docker-compose with proper user setup

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Installing Docker..."

# Install Docker packages
ensure_packages moby-engine docker-compose

# Enable and start Docker service
step "Enabling Docker service..."
sudo systemctl enable --now docker

# Add user to docker group if not already a member
if groups "$USER" | grep -q '\bdocker\b'; then
    info "User $USER is already in the docker group"
else
    step "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    warn "You may need to log out and back in for docker group membership to take effect"
fi

script_complete "Docker setup"
