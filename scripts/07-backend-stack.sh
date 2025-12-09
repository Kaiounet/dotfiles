#!/bin/bash
# scripts/07-backend-stack.sh
# Backend & Development Stack
# Installs Java 25, Maven, Node.js, .NET, PHP, Composer, and Symfony CLI
# Ensures Java 25 remains the system default when available.

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

JAVA25_PKG="java-25-openjdk-devel"
JAVA25_HOME="/usr/lib/jvm/java-25-openjdk"
JAVA25_BIN="${JAVA25_HOME}/bin/java"
JAVA25_JAVAC="${JAVA25_HOME}/bin/javac"
JAVA_LATEST_PKG="java-latest-openjdk-devel"

section_header "Installing Backend Stack (Java 25 Priority)..."

step "Installing Java 25 (LTS) or closest fallback..."
if sudo dnf list available "$JAVA25_PKG" &>/dev/null; then
    ensure_packages "$JAVA25_PKG"
else
    warn "$JAVA25_PKG not available; falling back to $JAVA_LATEST_PKG"
    ensure_packages "$JAVA_LATEST_PKG"
fi

step "Installing .NET SDK, Node.js, and Maven..."
ensure_packages dotnet-sdk-9.0 nodejs maven

step "Installing PHP and related tools..."
ensure_packages php php-cli php-json php-mbstring php-xml php-intl php-mysqlnd composer

step "Ensuring Java 25 is the system default (if present)..."
if [ -x "$JAVA25_BIN" ]; then
    if sudo alternatives --set java "$JAVA25_BIN"; then
        info "System default java now points to Java 25 ($JAVA25_BIN)"
    else
        warn "Failed to set java alternative to $JAVA25_BIN; leaving current java provider as-is"
    fi

    if [ -x "$JAVA25_JAVAC" ]; then
        if sudo alternatives --set javac "$JAVA25_JAVAC"; then
            info "System default javac now points to Java 25 ($JAVA25_JAVAC)"
        else
            warn "Failed to set javac alternative to $JAVA25_JAVAC (javac may not be registered yet)"
        fi
    fi
else
    warn "Java 25 not detected at $JAVA25_BIN; current java provider remains in place"
fi

if cmd_exists symfony; then
    info "Symfony CLI already installed: $(symfony version --short 2>/dev/null || echo 'unknown version')"
else
    step "Installing Symfony CLI..."
    if curl -sS https://get.symfony.com/cli/installer | bash; then
        SYMFONY_BIN=""
        for candidate in \
            "$HOME/.symfony5/bin/symfony" \
            "$HOME/.symfony/bin/symfony" \
            "$HOME/.local/bin/symfony"; do
            if [ -x "$candidate" ]; then
                SYMFONY_BIN="$candidate"
                break
            fi
        done

        if [ -z "$SYMFONY_BIN" ]; then
            SYMFONY_BIN="$(find "$HOME" -path "*/.symfony*/bin/symfony" -type f -executable 2>/dev/null | head -1 || true)"
        fi

        if [ -n "$SYMFONY_BIN" ] && [ -x "$SYMFONY_BIN" ]; then
            step "Moving Symfony CLI to /usr/local/bin..."
            sudo mv "$SYMFONY_BIN" /usr/local/bin/symfony
            sudo chmod +x /usr/local/bin/symfony
            success "Symfony CLI installed to /usr/local/bin/symfony"
        else
            warn "Symfony installer succeeded but binary was not found under the usual directories"
        fi
    else
        warn "Failed to download/run Symfony CLI installer"
    fi
fi

script_complete "Backend stack setup"
