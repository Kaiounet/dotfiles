# ~/.bashrc
# Clean, minimal user bashrc that delegates personal customizations to ~/.bashrc_local
# Keep this file simple so system upgrades or scripts can safely modify it.

# Source global definitions, if available
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User-specific PATH additions (idempotent)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH";;
esac
case ":$PATH:" in
  *":$HOME/bin:"*) ;; *) PATH="$HOME/bin:$PATH";;
esac
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Source any modular ~/.bashrc.d scripts (optional)
if [ -d "$HOME/.bashrc.d" ]; then
  for rc in "$HOME/.bashrc.d"/*; do
    [ -r "$rc" ] && [ -f "$rc" ] && . "$rc"
  done
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$($HOME/.local/miniconda3/bin/conda 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/.local/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/.local/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/.local/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Rust/Cargo binaries (kept here for compatibility with some tools/scripts)
case ":$PATH:" in
  *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH";;
esac
export PATH

# NOTE: Personal aliases and functions should live in ~/.bashrc_local (tracked in your dotfiles).
# This keeps this file clean and safe to replace or update.
# Source user's local bashrc if present (idempotent)
if [ -f "$HOME/.bashrc_local" ]; then
    . "$HOME/.bashrc_local"
fi

# End of file
