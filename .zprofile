# Login shell config (Zsh)
# Keep Homebrew on Apple Silicon first and stable.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
