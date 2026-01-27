# Only run for interactive shells
[[ -o interactive ]] || return

# Files to source
zsh_files=(
  ~/.zsh_prompt
  ~/.aliases
  ~/.functions
)

# Source existing files
for file in $zsh_files; do
  [[ -f $file ]] && source $file
done

# Enable completion system
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

export PATH="$PATH:$HOME/.local/bin"
