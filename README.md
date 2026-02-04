# Zsh Dotfiles

Personal Zsh dotfiles for a clean, fast CLI experience. This repo includes a custom prompt, aliases, helper functions, Zsh completions, and a simple installer that copies everything into your `$HOME` directory.

## Contents

```
.
├── .aliases                  # Shell aliases (navigation, ls defaults, shortcuts)
├── .functions                # Helper functions (mkd, shrinkpng, t, renamefiles)
├── .gitconfig                # Git aliases + user identity
├── .vimrc                    # Vim defaults (Solarized, UX, backups, etc.)
├── .zprofile                 # Login shell config (ARM Homebrew init)
├── .zsh/                     # Zsh extras
│   └── completions/          # Zsh + bash-style completions
│       ├── _sshconn          # Zsh completion for sshconn
│       └── wp-completion.bash# WP-CLI bash completion
├── .zsh_prompt               # Solarized-ish prompt with Git status
├── .zshrc                    # Zsh entry point; sources other files
└── install.sh                # Installer (copy + optional backup)
```

## Install

⚠️ On macOS, `.zprofile` is used for login shell setup (e.g. Homebrew). `.zshrc` is for interactive config.

```
./install.sh
```

Dry run:

```
./install.sh --dry-run
```

## Changelog

### 0.1.1 (2026-02-04)
- Added ARM-only Homebrew via `.zprofile`

### 0.1.0 (2026-02-03)
- Added `install.sh` to copy dotfiles into `$HOME`
- Added backup and dry-run modes
- Added exclude list + skip logging to avoid copying `.git`
- Added emoji logging for backup/copy/remove/finish
