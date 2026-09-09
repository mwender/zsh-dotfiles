# Login shell config (Zsh)
# Keep Homebrew on Apple Silicon first and stable.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Commands from this dotfiles repo (~/bin is a symlink to zsh-dotfiles/bin),
# plus ~/.local/bin, which holds the Claude Code shim.
for d in "$HOME/bin" "$HOME/.local/bin"; do
  [ -d "$d" ] || continue
  case ":$PATH:" in
    *":$d:"*) ;;
    *) PATH="$d:$PATH" ;;
  esac
done
export PATH

# Where `proj` looks for projects. The two machines keep them in different
# places: the MacBook under Dropbox, the Mac Mini directly in $HOME. First
# match wins, so order matters.
if [ -z "${PROJECTS_DIR:-}" ]; then
  for d in "$HOME/Dropbox/Projects" "$HOME/Projects"; do
    if [ -d "$d" ]; then export PROJECTS_DIR="$d"; break; fi
  done
fi
