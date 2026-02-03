# Only run for interactive shells
[[ -o interactive ]] || return

# Enable completion system
autoload -Uz compinit
compinit -C

# Enable bash-style completions (for WP-CLI)
autoload -Uz bashcompinit
bashcompinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Files to source
zsh_files=(
  ~/.zsh_prompt
  ~/.aliases
  ~/.functions
  ~/.zsh/completions/wp-completion.bash
  ~/.zsh/completions/_sshconn
)

# Source existing files
for file in $zsh_files; do
  [[ -f $file ]] && source $file
done

export PATH="$HOME/.local/bin:$PATH"
