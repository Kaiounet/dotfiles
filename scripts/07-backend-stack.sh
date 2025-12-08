#!/bin/bash
# scripts/07-backend-stack.sh
# Backend & Development Stack
# Installs Java 25, Maven, Node.js, .NET, PHP, Composer, and Symfony CLI

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Installing Backend Stack (Java 25 Priority)..."

# Install Java 25 FIRST so it becomes the default provider
step "Installing Java 25 (LTS)..."
if sudo dnf list available "java-25-openjdk-devel" &>/dev/null; then
    ensure_packages java-25-openjdk-devel
else
    warn "java-25-openjdk-devel not found, using java-latest-openjdk..."
    ensure_packages java-latest-openjdk-devel
fi

# Install Maven/Node/.NET (Maven will now use the existing Java 25)
step "Installing .NET SDK, Node.js, and Maven..."
ensure_packages dotnet-sdk-9.0 nodejs maven

step "Installing PHP and related tools..."
ensure_packages php php-cli php-json php-mbstring php-xml php-intl php-mysqlnd composer

# Ensure Java 25 is the system default
step "Enforcing Java 25 as system default..."
sudo alternatives --auto java

# Install Symfony CLI if not present
if cmd_exists symfony; then
    info "Symfony CLI already installed: $(symfony version --short 2>/dev/null || echo 'unknown version')"
else
    step "Installing Symfony CLI..."

    # Download and run the Symfony installer
    if curl -sS https://get.symfony.com/cli/installer | bash; then
        # Find the symfony binary (location may vary by version)
        SYMFONY_BIN=""

        # Check common locations
        for candidate in \
            "$HOME/.symfony5/bin/symfony" \
            "$HOME/.symfony/bin/symfony" \
            "$HOME/.local/bin/symfony"; do
            if [ -x "$candidate" ]; then
                SYMFONY_BIN="$candidate"
                break
            fi
        done

        # Fallback: search for it
        if [ -z "$SYMFONY_BIN" ]; then
            SYMFONY_BIN="$(find "$HOME" -path "*/.symfony*/bin/symfony" -type f -executable 2>/dev/null | head -1 || true)"
        fi

        if [ -n "$SYMFONY_BIN" ] && [ -x "$SYMFONY_BIN" ]; then
            step "Moving Symfony CLI to /usr/local/bin..."
            sudo mv "$SYMFONY_BIN" /usr/local/bin/symfony
            sudo chmod +x /usr/local/bin/symfony
            success "Symfony CLI installed to /usr/local/bin/symfony"
        else
            warn "Symfony installer ran but binary not found. Check ~/.symfony* directories"
        fi
    else
        warn "Failed to download/run Symfony CLI installer"
    fi
fi

script_complete "Backend stack setup"
