# AGENTS.md

## Purpose

This repository contains Michael Wender's personal shell dotfiles. The main goal when working here is to make small, predictable changes to interactive shell behavior without breaking login shell startup or overwriting machine-specific state.

Future agents should read this file before making changes.

## Working Style For This Repo

Before any non-trivial change, state assumptions explicitly:

```text
ASSUMPTIONS I'M MAKING:
1. ...
2. ...
→ Correct me now or I'll proceed with these.
```

For multi-step work, emit a short plan before editing:

```text
PLAN:
1. ...
2. ...
3. ...
→ Executing unless you redirect.
```

If repo contents or behavior conflict with the request, stop and surface the confusion instead of guessing.

## Repo Map

- `.zprofile`
  Login-shell setup. Initializes Apple Silicon Homebrew from `/opt/homebrew/bin/brew`, puts `$HOME/bin` and `$HOME/.local/bin` on `PATH` (both guarded against double-prepending), and sets `PROJECTS_DIR` to the first of `~/Dropbox/Projects` or `~/Projects` that exists. That last one is how the same file works on two machines that keep projects in different places — order matters, and the MacBook has only the Dropbox path.

- `bin/`
  Executables. **Symlinked** into `~/bin` per file by `install.sh`, not copied — see the installer note below.
  - `bin/proj` — one tmux session per project, named after the directory, optionally starting Claude Code or Codex in it. Reads `PROJECTS_DIR`. Requires `tmux`; the bare `proj` picker also requires `fzf`.
  - `bin/pm` — the same commands run against the headless Mac Mini over Tailscale, so they work from any network. On the Mini itself it `exec`s `proj`, detected by comparing `hostname -s` against `PM_LOCAL_HOSTNAME` (default `wenmark-macmini`). Target host is `PM_HOST` (default `macmini@macs-mac-mini`).

- `.zshrc`
  Interactive-shell entrypoint. It returns immediately for non-interactive shells, configures completion, enables `bashcompinit`, and sources the main dotfiles.

- `.zsh_prompt`
  Custom prompt implementation. Handles terminal color setup, terminal title, and Git branch/status markers.

- `.aliases`
  Alias definitions. This file may contain machine-specific shortcuts to local directories and apps.

- `.functions`
  Shell helper functions. Includes convenience helpers and a few environment-specific helpers such as the OpenClaw SSH tunnel commands.

- `.zsh/completions/_sshconn`
  Zsh completion definition that reads connection names from `$HOME/.connections`.

- `.zsh/completions/_proj`
  Completes local project names, using the same definition `proj` does: top-level directories under `PROJECTS_DIR` that contain a `.git`.

- `.zsh/completions/_pm`
  Completes project names that live on the Mac Mini. Fetches them over SSH and caches to `~/.cache/pm-projects` (TTL via `PM_CACHE_TTL`), because a round-trip on every `<TAB>` is unusable. Never blocks on an unreachable machine — a stale list beats a hung shell.

- `.zsh/completions/wp-completion.bash`
  WP-CLI bash completion loaded via `bashcompinit`.

- `install.sh`
  Installer that copies top-level repo items into `$HOME`, excluding `.git`, `AGENTS.md`, and `install.sh`. Existing targets are optionally moved into a timestamped backup directory first.

  **Exception: `LINK_INTO`.** Directories named there (currently just `bin`) have their *contents* symlinked into `$HOME/<name>/` one file at a time, rather than the directory being replaced. Two reasons, both load-bearing. Editing a script in the repo takes effect immediately, and `git pull` updates the installed command with no second step. And `~/bin` already contains things this repo does not manage — `hey`, `sshconn`, `httpcompression`, and symlinks to `bash` and `subl` — which replacing the directory wholesale would move into the backup folder and break. The per-file path also skips the wholesale backup loop and backs up only the individual files it actually replaces, and leaves a correct existing symlink alone.

- `.gitconfig`, `.vimrc`
  Personal editor and Git configuration also managed by this repo.

## Boot / Load Order

This matters whenever you change startup behavior:

1. Login shells read `.zprofile`.
2. Interactive Zsh shells read `.zshrc`.
3. `.zshrc` sets `fpath`, runs `compinit -C`, enables `bashcompinit`, and applies case-insensitive completion.
4. `.zshrc` sources these files in order if they exist:
   - `~/.zsh_prompt`
   - `~/.aliases`
   - `~/.functions`
   - `~/.zsh/completions/wp-completion.bash`
5. `.zshrc` adds a `precmd` hook to keep `COLUMNS` synced and prepends `$HOME/.local/bin` to `PATH`.

Important detail: `.zsh_prompt` also defines `precmd()`. If you change prompt hooks, be careful not to accidentally clobber behavior from `.zshrc` or vice versa. Prefer additive hook patterns when possible.

## Repo-Specific Constraints

- Treat this as a personal environment repo, not a reusable framework.
- Prefer small edits over abstraction. New helper layers are usually the wrong move here.
- Do not remove machine-specific aliases, paths, hostnames, or helper functions unless explicitly asked.
- Expect local assumptions:
  - macOS utilities such as `open`, `pbcopy`, and BSD `ls -G`
  - Apple Silicon Homebrew in `/opt/homebrew`
  - WP-CLI installed and available on `PATH`
  - Optional external tools such as `pngquant` and `tree`
- `.aliases` and `.functions` may intentionally reference directories or hosts that only exist on the user's machine.
- `.zsh/completions/_sshconn` depends on `$HOME/.connections`, which is not stored in this repo.
- `bin/proj` needs `tmux`, and `fzf` for the bare picker. Neither is installed on the MacBook, where `pm` is the intended entry point — `proj` there exits with a clear message rather than failing obscurely.
- `bin/pm` assumes Tailscale is up on both machines and that SSH key auth works. It does not fall back to the LAN address, deliberately: the tailnet name survives the Mini's DHCP lease changing.

## Editing Guidance

- Touch only the file needed for the requested behavior.
- Keep shell code boring and readable. Prefer plain Zsh or POSIX-style shell over clever one-liners unless the file already uses them.
- Preserve current comments unless they are clearly incorrect and directly related to the task.
- When changing startup files, think about:
  - login vs interactive shell scope
  - prompt hook interactions
  - whether completion initialization order still works
  - whether the change depends on tools that may not exist everywhere
- When changing `install.sh`, remember it is destructive to existing targets after backup because it removes the destination before copying.

## Safe Validation

Use lightweight checks first:

```sh
zsh -n .zshrc .zsh_prompt .aliases .functions .zprofile
./install.sh --dry-run
```

If behavior needs a real shell session, prefer a temporary home instead of the user's real one:

```sh
tmp_home="$(mktemp -d /tmp/zsh-dotfiles.XXXXXX)"
HOME="$tmp_home" ./install.sh --no-backup
HOME="$tmp_home" zsh -lic 'echo shell started'
```

Notes:

- `zsh -n` is syntax-only; it will not catch runtime issues from missing commands.
- A temp-`HOME` install is the safest way to test sourcing order and copied file layout.
- Avoid running `install.sh` against the real home directory unless the user explicitly wants that.

## What A Good Change Looks Like

- The changed shell file still parses cleanly.
- The load order remains intentional.
- Any environment-specific dependency is either preserved or clearly guarded.
- The installer still does what the README says.
- The change is easy for a human reviewing side-by-side in an IDE to understand quickly.

## Communication Expectations

After modifying files, summarize using this shape:

```text
CHANGES MADE:
- [file]: [what changed and why]

THINGS I DIDN'T TOUCH:
- [file]: [intentionally left alone because...]

POTENTIAL CONCERNS:
- [risk or follow-up check]
```

If your change leaves dead code behind, list it explicitly and ask whether it should be removed.
