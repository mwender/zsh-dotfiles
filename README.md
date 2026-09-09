# Zsh Dotfiles

Personal Zsh dotfiles for a clean, fast CLI experience. This repo includes a custom prompt, aliases, helper functions, Zsh completions, and a simple installer that copies everything into your `$HOME` directory.

## Contents

```
.
├── bin/                      # Executables, symlinked into ~/bin (not copied)
│   ├── proj                  # Open a project in its own tmux session
│   └── pm                    # The same, on the Mac Mini, over Tailscale
├── .aliases                  # Shell aliases (navigation, ls defaults, shortcuts)
├── .functions                # Helper functions (mkd, shrinkpng, t, renamefiles)
├── .gitconfig                # Git aliases + user identity
├── .vimrc                    # Vim defaults (Solarized, UX, backups, etc.)
├── .zprofile                 # Login shell config (ARM Homebrew init)
├── .zsh/                     # Zsh extras
│   └── completions/          # Zsh + bash-style completions
│       ├── _sshconn          # Zsh completion for sshconn
│       ├── _proj             # Zsh completion for proj (local project names)
│       ├── _pm               # Zsh completion for pm (cached remote names)
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

Everything at the top level is **copied** into `$HOME`, except `bin/`, whose
contents are **symlinked** one file at a time into `~/bin`. That means editing
`bin/proj` in this repo takes effect immediately and a `git pull` updates the
installed command with no second step. It also leaves anything already in
`~/bin` that this repo does not manage — `hey`, `sshconn`, `subl` — untouched.

## Project sessions: `proj` and `pm`

`proj` gives every project its own persistent tmux session, named after its
directory. Sessions outlive your connection, so an agent left running mid-task
is still running when you come back.

```
proj                    fuzzy-pick a project (needs fzf), then attach
proj <name>             attach to that project's session, creating it if needed
proj <name> claude      ... and start Claude Code in it
proj <name> codex       ... and start Codex in it
proj -l                 list projects, marking live sessions
proj -k <name>          kill a session
```

`pm` is the same set of commands, run on the headless Mac Mini over Tailscale —
so it works from any network, not just the LAN. On the Mini itself `pm` simply
becomes `proj`, so the same muscle memory works from either seat.

```
pm -l                   list the Mini's projects
pm google-services claude
pm -s                   plain shell on the Mini
```

Both read `PROJECTS_DIR`, which `.zprofile` sets per machine: `~/Dropbox/Projects`
on the MacBook, `~/Projects` on the Mini. Override the `pm` target with `PM_HOST`.

Tab-completion for `pm` fetches the Mini's project list over SSH and caches it at
`~/.cache/pm-projects`, because a round-trip on every `<TAB>` is too slow. Delete
that file to force a refresh.

## Changelog

### 0.1.4 (2026-09-09)
- Added `bin/proj` — per-project tmux sessions, with optional Claude Code or Codex.
- Added `bin/pm` — the same commands against the headless Mac Mini over Tailscale.
- Added `_proj` and `_pm` Zsh completions; `_pm` caches the remote list at `~/.cache/pm-projects`.
- `install.sh` now symlinks the contents of `bin/` into `~/bin` per file, instead of copying, so edits are live and unmanaged files in `~/bin` survive.
- `.zprofile` now puts `~/bin` and `~/.local/bin` on `PATH` and sets `PROJECTS_DIR` per machine.

### 0.1.3 (2026-05-11)
- Prompting `cpath` alias to a function to allow for tab-completion.

### 0.1.2 (2026-05-11)
- Adding `cpath` alias for extracting the full path to a given file (e.g. `$ cpath {$filename}`).
- Adding `AGENTS.md`.
- Fine-tuning case-insensitve path completion.

### 0.1.1 (2026-02-04)
- Added ARM-only Homebrew via `.zprofile`

### 0.1.0 (2026-02-03)
- Added `install.sh` to copy dotfiles into `$HOME`
- Added backup and dry-run modes
- Added exclude list + skip logging to avoid copying `.git`
- Added emoji logging for backup/copy/remove/finish
