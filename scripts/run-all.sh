#!/bin/bash
# scripts/run-all.sh
# Master execution script
# Runs all setup scripts in sequence with error handling and progress tracking

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Array of scripts to execute in order
SCRIPTS=(
    "00-system-core.sh"
    "01-python-tools.sh"
    "02-gnome-extensions.sh"
    "03-terminal-utilities.sh"
    "04-fonts.sh"
    "05-typst.sh"
    "06-editors-ides.sh"
    "07-backend-stack.sh"
    "08-data-science.sh"
    "09-docker.sh"
    "10-user-apps.sh"
    "11-shell-config.sh"
    "12-ghostty.sh"
    "13-python-dojo.sh"
)

# ─────────────────────────────────────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Fedora 43 Post-Install Setup (Modular Edition)     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Execution
# ─────────────────────────────────────────────────────────────────────────────

# Track execution
COMPLETED=0
FAILED=0
FAILED_SCRIPTS=()

# Execute each script
for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$script"

    if [ ! -f "$SCRIPT_PATH" ]; then
        err "Script not found: $script"
        FAILED=$((FAILED + 1))
        FAILED_SCRIPTS+=("$script (not found)")
        continue
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    step "Executing: $script"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if bash "$SCRIPT_PATH"; then
        COMPLETED=$((COMPLETED + 1))
    else
        err "Failed: $script"
        FAILED=$((FAILED + 1))
        FAILED_SCRIPTS+=("$script")
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Setup Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Completed:${NC} $COMPLETED"
echo -e "  ${RED}Failed:${NC}    $FAILED"

if [ ${#FAILED_SCRIPTS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed scripts:${NC}"
    for failed in "${FAILED_SCRIPTS[@]}"; do
        echo -e "  - $failed"
    done
fi

echo ""
echo -e "${YELLOW}POST-INSTALL CHECKLIST:${NC}"
echo "  1. Run 'java -version' to confirm Java version"
echo "  2. Run '/opt/jetbrains/jetbrains-toolbox' to launch JetBrains Toolbox"
echo "  3. Log out and back in for group permissions to take effect (docker)"
echo "  4. Launch Ghostty to verify terminal configuration"
echo "  5. Open a new terminal to verify shell configuration"
echo ""

# Exit with error if any script failed
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
