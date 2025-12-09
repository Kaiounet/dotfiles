# Fedora 43 Modular Setup Scripts

This directory contains modular setup scripts for Fedora 43 Workstation post-installation configuration, including the new `13-python-dojo.sh` environment provisioner for AI/ML workflows.

## Overview

Instead of one monolithic script, the setup is broken into focused, independent modules:

| Script | Purpose |
|--------|---------|
| `00-system-core.sh` | System updates & build tools |
| `01-python-tools.sh` | Pipx for Python tool isolation |
| `02-gnome-extensions.sh` | GNOME shell extensions |
| `03-terminal-utilities.sh` | CLI utilities & tmux config |
| `04-fonts.sh` | JetBrains Mono & Nerd Fonts |
| `05-typst.sh` | Typst document generation |
| `06-editors-ides.sh` | VS Code, Zed, JetBrains Toolbox |
| `07-backend-stack.sh` | Java, Maven, Node, .NET, PHP, Symfony |
| `08-data-science.sh` | Miniconda for ML/AI |
| `09-docker.sh` | Docker & docker-compose |
| `10-user-apps.sh` | Flatpak apps, browsers |
| `11-shell-config.sh` | Shell configuration (symlinks or copies) |
| `12-ghostty.sh` | Ghostty terminal emulator |
| `13-python-dojo.sh` | Dojo conda environment for Python, AI & ML tooling |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `run-all.sh` | Execute all setup scripts in sequence |
| `check.sh` | Validate symlinks, run shellcheck, detect drift |
| `lib/common.sh` | Shared functions and utilities |

## Usage

### Run All Scripts (Recommended for Fresh Install)

```bash
chmod +x scripts/*.sh
bash scripts/run-all.sh
```

### Run Individual Scripts

```bash
bash scripts/03-terminal-utilities.sh
```

### Run Selective Scripts

```bash
bash scripts/00-system-core.sh
bash scripts/01-python-tools.sh
bash scripts/03-terminal-utilities.sh
```

### Health Check

Validate your dotfiles setup:

```bash
# Run all checks
bash scripts/check.sh

# Run specific checks
bash scripts/check.sh --symlinks    # Check symlink integrity
bash scripts/check.sh --shellcheck  # Lint all scripts
bash scripts/check.sh --drift       # Detect config drift
bash scripts/check.sh --tools       # Check installed tools
```

## Shell Configuration

## Python & AI Environment

The `13-python-dojo.sh` script creates a reproducible `dojo` conda environment that installs NumPy, pandas, Jupyter, Poetry, PyTorch, FastAPI, LangChain, and other core tools, then registers the kernel and outputs a `pip freeze` manifest under `.config/dotfiles/envs/dojo-requirements.txt`.

The `11-shell-config.sh` script manages your shell configuration files.

### Symlink Mode (Default, Recommended)

```bash
bash scripts/11-shell-config.sh
```

- Creates symlinks from `~/.bashrc` and `~/.bashrc_local` to the dotfiles repo
- **Pros**: Single source of truth, changes sync automatically, easy version control
- **Cons**: Risk of package installers modifying the symlink target

### Copy Mode

```bash
bash scripts/11-shell-config.sh --copy
# or
COPY_MODE=1 bash scripts/11-shell-config.sh
```

- Copies files from the dotfiles repo to your home directory
- **Pros**: Full control over local files, immune to package modifications
- **Cons**: Changes don't sync back to the repo, harder to keep in version control

### Shell Files

| File | Purpose |
|------|---------|
| `~/.bashrc` | Main shell config (minimal, sources .bashrc_local) |
| `~/.bashrc_local` | Personal aliases, functions, and customizations |
| `~/.bashrc.d/` | Directory for modular shell snippets (optional) |

## Features

- ✅ **Modular**: Each script is independent and can be run separately
- ✅ **Idempotent**: Safe to re-run; checks for existing installations
- ✅ **Non-destructive**: No package removal, only additions
- ✅ **Color-coded output**: Clear progress tracking
- ✅ **Strict error handling**: `set -euo pipefail` catches errors early
- ✅ **Shared library**: Common functions in `lib/common.sh`
- ✅ **Backup support**: Existing files are backed up with timestamps
- ✅ **Health checks**: `check.sh` validates the entire setup

## Architecture

```
scripts/
├── lib/
│   └── common.sh          # Shared functions, colors, utilities
├── 00-system-core.sh      # Foundation
├── 01-python-tools.sh
├── ...
├── 12-ghostty.sh
├── run-all.sh             # Master executor
├── check.sh               # Health checker
└── README.md
```

### Common Library (`lib/common.sh`)

All scripts source `lib/common.sh` which provides:

- **Colors**: `$GREEN`, `$RED`, `$YELLOW`, `$BLUE`, `$NC`
- **Logging**: `info()`, `warn()`, `err()`, `step()`, `success()`, `header()`
- **File operations**: `backup_file()`, `backup_dir()`, `safe_symlink()`, `safe_copy()`
- **Commands**: `cmd_exists()`, `require_cmd()`
- **Package management**: `pkg_installed()`, `ensure_packages()`, `add_dnf_repo()`, `ensure_flatpak()`
- **Utilities**: `get_script_dir()`, `get_dotfiles_root()`, `confirm()`, `script_complete()`

## Post-Installation Checklist

After running the setup:

1. **Verify Java**: `java -version`
2. **Launch JetBrains Toolbox**: `/opt/jetbrains/jetbrains-toolbox`
3. **Log out and back in** for Docker group permissions to take effect
4. **Launch Ghostty** to verify terminal configuration
5. **Open a new terminal** to verify shell configuration
6. **Run health check**: `bash scripts/check.sh`

## Troubleshooting

### Symlinks not working

```bash
# Check symlink status
bash scripts/check.sh --symlinks

# Re-run shell config
bash scripts/11-shell-config.sh
```

### Package installer modified ~/.bashrc

If a package (like pipx or conda) modified your `~/.bashrc`:

1. Check `git status` in your dotfiles repo
2. Review the changes
3. Either:
   - Accept the changes and commit them
   - Revert with `git checkout .config/bash/.bashrc`
   - Re-run `bash scripts/11-shell-config.sh` to restore the symlink

### Finding backup files

```bash
# List backup files in home directory
ls -la ~/.bashrc.bak.* ~/.bashrc_local.bak.* 2>/dev/null

# List Ghostty config backups
ls -la ~/.config/ghostty.bak.* 2>/dev/null
```

## Contributing

When adding new scripts:

1. Follow the naming convention: `NN-description.sh`
2. Source the common library: `source "$SCRIPT_DIR/lib/common.sh"`
3. Use `set -euo pipefail` for strict error handling
4. Use helper functions from `common.sh` instead of raw commands
5. Add the script to `run-all.sh` in the appropriate order
6. Update this README