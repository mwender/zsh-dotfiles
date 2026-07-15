# Only run for interactive shells
[[ -o interactive ]] || return

# Enable completion system
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
compinit -C

# Enable bash-style completions (for WP-CLI)
autoload -Uz bashcompinit
bashcompinit

# Prefer exact matches first, then fall back to case-insensitive matching.
# Note: bashcompinit-backed completions (like WP-CLI's bash completion) may
# not honor zstyle matchers the same way native Zsh completions do.
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Files to source
zsh_files=(
  ~/.zsh_prompt
  ~/.aliases
  ~/.functions
  ~/.zsh/completions/wp-completion.bash
)

# Source existing files
for file in $zsh_files; do
  [[ -f $file ]] && source $file
done

# Keep COLUMNS in sync for tools like icdiff
autoload -Uz add-zsh-hook
add-zsh-hook precmd () {
  export COLUMNS=$(tput cols)
}

export PATH="$HOME/.local/bin:$PATH"

# Personal scripts (sshconn, etc.)
export PATH="$HOME/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
