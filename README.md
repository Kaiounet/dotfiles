# Kai's Dotfiles

Personal dotfiles and automated setup scripts for Fedora 43 Workstation.

## Quick Start

```bash
# Clone the repository (yes I like to put it in ~/dev/dotfiles)
git clone https://github.com/Kaiounet/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Run all setup scripts
chmod +x scripts/*.sh
bash scripts/run-all.sh
```

## What's Included

### Setup Scripts

Modular, idempotent setup scripts located in `scripts/`:

| Script | Purpose |
|--------|---------|
| `00-system-core.sh` | System updates & build tools |
| `01-python-tools.sh` | Pipx for Python tool isolation |
| `02-gnome-extensions.sh` | GNOME shell extensions |
| `03-terminal-utilities.sh` | CLI utilities (tmux, ripgrep, fzf, etc.) |
| `04-fonts.sh` | JetBrains Mono & Nerd Fonts |
| `05-typst.sh` | Typst document generation |
| `06-editors-ides.sh` | VS Code, Zed, JetBrains Toolbox |
| `07-backend-stack.sh` | Java, Maven, Node, .NET, PHP, Symfony |
| `08-data-science.sh` | Miniconda for ML/AI |
| `09-docker.sh` | Docker & docker-compose |
| `10-user-apps.sh` | Flatpak apps, LibreWolf, Brave |
| `11-shell-config.sh` | Shell configuration (symlinks) |
| `12-ghostty.sh` | Ghostty terminal emulator |

### Configuration Files

Located in `.config/`:

```
.config/
├── bash/
│   ├── .bashrc        # Minimal shell config (symlinked to ~/.bashrc)
│   └── .bashrc_local  # Personal aliases & functions (symlinked to ~/.bashrc_local)
└── ghostty/
    └── config         # Ghostty terminal configuration
```

## Usage

### Full Installation

```bash
bash scripts/run-all.sh
```

### Individual Scripts

```bash
# Run only what you need
bash scripts/03-terminal-utilities.sh
bash scripts/06-editors-ides.sh
```

### Shell Configuration

The shell config script supports two modes:

```bash
# Symlink mode (default, recommended)
bash scripts/11-shell-config.sh

# Copy mode (for standalone customization)
bash scripts/11-shell-config.sh --copy
```

**Symlink mode** keeps your shell config in sync with this repo.  
**Copy mode** gives you full local control without repo dependencies.

### Health Check

Validate your setup:

```bash
# Run all checks
bash scripts/check.sh

# Specific checks
bash scripts/check.sh --symlinks    # Verify symlink integrity
bash scripts/check.sh --shellcheck  # Lint scripts
bash scripts/check.sh --drift       # Detect config drift
bash scripts/check.sh --tools       # Check installed tools
```

## Shell Features

After setup, you'll have:

- **Prompt**: User@host, working directory, git branch, exit status
- **Aliases**: `ll`, `la`, `gs`, `ga`, `gc`, `gp`, `gl`, `gcb`
- **Safe rm**: `rm` aliased to `trash-put` (if installed)
- **VS Code profiles**: `code-java`, `code-csharp`, `code-ds`, `code-php` (I use custom profiles, you can create your own)
- **Functions**: `ta` (tmux attach), `venv` (quick virtualenv), `dfh` (human df)
- **FZF integration**: Fuzzy file finder with bat preview

## Post-Installation

After running the scripts:

1. **Log out and back in** for group permissions (docker) to take effect
2. **Verify Java**: `java -version`
3. **Launch JetBrains Toolbox**: `/opt/jetbrains/jetbrains-toolbox`
4. **Open new terminal** to load shell configuration
5. **Run health check**: `bash scripts/check.sh`

## Directory Structure

```
dotfiles/
├── .config/
│   ├── bash/           # Shell configuration
│   └── ghostty/        # Terminal configuration
├── scripts/
│   ├── lib/
│   │   └── common.sh   # Shared functions
│   ├── 00-12-*.sh      # Setup scripts
│   ├── run-all.sh      # Master executor
│   ├── check.sh        # Health checker
│   └── README.md       # Scripts documentation
├── assets/             # Icons and resources
└── README.md           # This file
```

## Customization

### Adding Personal Aliases

Edit `.config/bash/.bashrc_local` and add your customizations at the bottom:

```bash
# My custom aliases
alias myalias='my-command'
export MY_VAR="value"
```

### Adding New Setup Scripts

1. Create `scripts/NN-description.sh` following the naming convention
2. Source the common library: `source "$SCRIPT_DIR/lib/common.sh"`
3. Use `set -euo pipefail` for strict error handling
4. Add to `scripts/run-all.sh` in the appropriate order

## Troubleshooting

### Symlinks not working

```bash
bash scripts/check.sh --symlinks
bash scripts/11-shell-config.sh  # Re-run to fix
```

### Package modified ~/.bashrc

```bash
# Check what changed
git status

# Restore symlink
bash scripts/11-shell-config.sh
```

### Finding backup files

```bash
ls -la ~/.bashrc.bak.* ~/.bashrc_local.bak.* 2>/dev/null
```

## License

MIT License - Feel free to use and modify as needed.
