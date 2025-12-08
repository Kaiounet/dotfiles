#!/bin/bash
# scripts/check.sh
# Validation and Health Check Script
# Validates symlinks, runs shellcheck, and reports configuration drift
#
# Usage:
#   ./check.sh              # Run all checks
#   ./check.sh --symlinks   # Check symlinks only
#   ./check.sh --shellcheck # Run shellcheck only
#   ./check.sh --drift      # Check for config drift only

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DOTFILES_ROOT="$(get_dotfiles_root)"

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Expected symlinks: source -> destination
declare -A EXPECTED_SYMLINKS=(
    ["$DOTFILES_ROOT/.config/bash/.bashrc"]="$HOME/.bashrc"
    ["$DOTFILES_ROOT/.config/bash/.bashrc_local"]="$HOME/.bashrc_local"
)

# Config files to check for drift (copied, not symlinked)
declare -a CONFIG_DIRS=(
    "$DOTFILES_ROOT/.config/ghostty:$HOME/.config/ghostty"
)

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

check_pass() {
    echo -e "  ${GREEN}✓${NC} $*"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $*"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

check_warn() {
    echo -e "  ${YELLOW}!${NC} $*"
    WARNINGS=$((WARNINGS + 1))
}

# ─────────────────────────────────────────────────────────────────────────────
# Symlink Validation
# ─────────────────────────────────────────────────────────────────────────────

check_symlinks() {
    section_header "Checking symlinks..."

    for src in "${!EXPECTED_SYMLINKS[@]}"; do
        dest="${EXPECTED_SYMLINKS[$src]}"
        dest_name="${dest/#$HOME/\~}"

        if [ ! -e "$src" ]; then
            check_warn "$dest_name: source file missing ($src)"
            continue
        fi

        if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
            check_fail "$dest_name: does not exist"
            continue
        fi

        if [ -L "$dest" ]; then
            current_target="$(readlink -f "$dest" 2>/dev/null || true)"
            expected_target="$(readlink -f "$src" 2>/dev/null || true)"

            if [ "$current_target" = "$expected_target" ]; then
                check_pass "$dest_name -> correctly linked"
            else
                check_fail "$dest_name: wrong target (points to $current_target, expected $expected_target)"
            fi
        else
            check_warn "$dest_name: is a regular file, not a symlink (may have been modified by a package)"
        fi
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# Shellcheck Validation
# ─────────────────────────────────────────────────────────────────────────────

run_shellcheck() {
    section_header "Running shellcheck on scripts..."

    if ! cmd_exists shellcheck; then
        check_warn "shellcheck not installed (install with: sudo dnf install ShellCheck)"
        return 0
    fi

    local scripts_checked=0
    local scripts_passed=0

    # Find all shell scripts
    # Use -P to specify source path and exclude SC1091 (can't follow dynamic source)
    local shellcheck_opts=(-x -P "$SCRIPT_DIR/lib" -e SC1091)

    while IFS= read -r script; do
        scripts_checked=$((scripts_checked + 1))
        script_name="${script/#$SCRIPT_DIR\//}"

        if shellcheck "${shellcheck_opts[@]}" "$script" 2>/dev/null; then
            check_pass "$script_name"
            scripts_passed=$((scripts_passed + 1))
        else
            check_fail "$script_name: shellcheck errors found"
            # Show first few errors
            echo -e "    ${CYAN}Errors:${NC}"
            shellcheck "${shellcheck_opts[@]}" "$script" 2>&1 | head -20 | sed 's/^/      /'
        fi
    done < <(find "$SCRIPT_DIR" -name "*.sh" -type f | sort)

    echo ""
    info "Shellcheck: $scripts_passed/$scripts_checked scripts passed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Configuration Drift Detection
# ─────────────────────────────────────────────────────────────────────────────

check_drift() {
    section_header "Checking for configuration drift..."

    for mapping in "${CONFIG_DIRS[@]}"; do
        src="${mapping%%:*}"
        dest="${mapping##*:}"
        dest_name="${dest/#$HOME/\~}"
        src_name="${src/#$DOTFILES_ROOT/dotfiles}"

        if [ ! -d "$src" ]; then
            check_warn "$src_name: source directory not found"
            continue
        fi

        if [ ! -d "$dest" ]; then
            check_warn "$dest_name: not deployed (run setup scripts first)"
            continue
        fi

        # Compare directories
        if diff -rq "$src" "$dest" >/dev/null 2>&1; then
            check_pass "$dest_name: matches $src_name"
        else
            check_fail "$dest_name: differs from $src_name"
            echo -e "    ${CYAN}Differences:${NC}"
            diff -rq "$src" "$dest" 2>/dev/null | head -10 | sed 's/^/      /' || true
        fi
    done

    # Check for backup files that indicate previous modifications
    echo ""
    step "Checking for backup files..."

    local backups_found=0
    while IFS= read -r backup; do
        if [ -n "$backup" ]; then
            backup_name="${backup/#$HOME/\~}"
            check_warn "Backup found: $backup_name"
            backups_found=$((backups_found + 1))
        fi
    done < <(find "$HOME" -maxdepth 1 -name ".bashrc.bak.*" -o -name ".bashrc_local.bak.*" 2>/dev/null | head -10)

    if [ "$backups_found" -eq 0 ]; then
        check_pass "No shell config backups found"
    else
        info "Found $backups_found backup file(s). These were created when deploying dotfiles."
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Tool Availability Check
# ─────────────────────────────────────────────────────────────────────────────

check_tools() {
    section_header "Checking installed tools..."

    local tools=(
        "git:Version control"
        "tmux:Terminal multiplexer"
        "nvim:Neovim editor"
        "rg:Ripgrep search"
        "fd:Fd file finder"
        "fzf:Fuzzy finder"
        "bat:Better cat"
        "trash-put:Trash CLI"
        "code:VS Code"
        "zed:Zed editor"
        "ghostty:Ghostty terminal"
        "docker:Docker engine"
        "java:Java runtime"
        "node:Node.js"
        "dotnet:DotNet SDK"
        "php:PHP"
        "composer:PHP Composer"
        "symfony:Symfony CLI"
        "conda:Conda (miniconda)"
        "typst:Typst CLI"
        "cargo:Rust cargo"
    )

    local installed=0
    local missing=0

    for tool_entry in "${tools[@]}"; do
        tool="${tool_entry%%:*}"
        desc="${tool_entry##*:}"

        # Handle special cases
        case "$tool" in
            conda)
                if [ -x "$HOME/.local/miniconda3/bin/conda" ]; then
                    check_pass "$tool ($desc)"
                    installed=$((installed + 1))
                else
                    check_warn "$tool ($desc) - not found"
                    missing=$((missing + 1))
                fi
                ;;
            *)
                if cmd_exists "$tool"; then
                    check_pass "$tool ($desc)"
                    installed=$((installed + 1))
                else
                    check_warn "$tool ($desc) - not found"
                    missing=$((missing + 1))
                fi
                ;;
        esac
    done

    echo ""
    info "Tools: $installed installed, $missing not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Check Summary                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $CHECKS_PASSED"
    echo -e "  ${RED}Failed:${NC}   $CHECKS_FAILED"
    echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""

    if [ "$CHECKS_FAILED" -gt 0 ]; then
        err "Some checks failed. Review the output above for details."
        return 1
    elif [ "$WARNINGS" -gt 0 ]; then
        warn "Some warnings were raised. Review the output above."
        return 0
    else
        success "All checks passed!"
        return 0
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    local run_symlinks=false
    local run_shellcheck=false
    local run_drift=false
    local run_tools=false
    local run_all=true

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --symlinks)
                run_symlinks=true
                run_all=false
                ;;
            --shellcheck)
                run_shellcheck=true
                run_all=false
                ;;
            --drift)
                run_drift=true
                run_all=false
                ;;
            --tools)
                run_tools=true
                run_all=false
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --symlinks    Check symlinks only"
                echo "  --shellcheck  Run shellcheck only"
                echo "  --drift       Check for config drift only"
                echo "  --tools       Check installed tools only"
                echo "  --help        Show this help message"
                echo ""
                echo "Without options, all checks are run."
                exit 0
                ;;
            *)
                warn "Unknown argument: $arg"
                ;;
        esac
    done

    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Dotfiles Health Check                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$run_all" = true ] || [ "$run_symlinks" = true ]; then
        check_symlinks
        echo ""
    fi

    if [ "$run_all" = true ] || [ "$run_shellcheck" = true ]; then
        run_shellcheck
        echo ""
    fi

    if [ "$run_all" = true ] || [ "$run_drift" = true ]; then
        check_drift
        echo ""
    fi

    if [ "$run_all" = true ] || [ "$run_tools" = true ]; then
        check_tools
        echo ""
    fi

    print_summary
}

main "$@"
