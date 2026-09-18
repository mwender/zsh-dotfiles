#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"

BACKUP=true
DRY_RUN=false
CHECK_ONLY=false
FORCE=false

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--no-backup] [--dry-run] [--check] [--force]

Copies all dotfiles from this repo into $HOME.

Before touching anything it checks for drift: a deployed file that matches no
version this repo has ever had (it was edited in place), or a file inside an
installed directory that the repo does not have (installing would displace it).
Either one stops the install.

Options:
  --no-backup   Overwrite existing files without backing them up
  --dry-run     Show what would happen without making changes
  --check       Only run the drift check; exit 1 if it finds anything
  --force       Install even if the drift check finds something

Example:
  ./install.sh --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-backup)
      BACKUP=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

backup_dir=""
if $BACKUP; then
  ts="$(date +"%Y%m%d_%H%M%S")"
  backup_dir="${HOME_DIR}/.dotfiles-backup-${ts}"
fi

copy_item() {
  local src="$1"
  local dst="$2"

  if $DRY_RUN; then
    echo "📋 copy (dry-run): ${src} -> ${dst}"
    return 0
  fi

  if [[ -e "$dst" ]]; then
    echo "🧹 remove: ${dst}"
    rm -rf -- "$dst"
  fi

  if command -v rsync >/dev/null 2>&1; then
    echo "📋 copy: ${src} -> ${dst}"
    if [[ -d "$src" ]]; then
      rsync -a -- "$src"/ "$dst"/
    else
      rsync -a -- "$src" "$dst"
    fi
  else
    # Fallback for systems without rsync.
    echo "📋 copy: ${src} -> ${dst}"
    if [[ -d "$src" ]]; then
      mkdir -p -- "$dst"
      cp -R -p -- "$src"/ "$dst"/
    else
      cp -R -p -- "$src" "$dst"
    fi
  fi
}

EXCLUDES=(
  ".git"
  "AGENTS.md"
  "install.sh"
)

# Directories whose CONTENTS are symlinked into $HOME/<name>/, one file at a
# time, rather than the directory being copied or replaced wholesale.
#
# Two reasons. Editing a script in the repo takes effect immediately and a
# `git pull` updates the installed command with no second step. And $HOME/bin
# already holds things this repo does not manage (hey, sshconn, subl) -- those
# must survive untouched, which replacing the directory would not allow.
LINK_INTO=(
  "bin"
)

is_link_into() {
  local candidate="$1"
  local d
  for d in "${LINK_INTO[@]}"; do
    [[ "$candidate" == "$d" ]] && return 0
  done
  return 1
}

link_contents() {
  local src_dir="$1"
  local dst_dir="$2"

  if ! $DRY_RUN; then
    mkdir -p -- "$dst_dir"
  fi

  local src base dst
  for src in "$src_dir"/*; do
    [[ -e "$src" ]] || continue
    base="$(basename -- "$src")"
    dst="${dst_dir}/${base}"

    # Already pointing at the right place: nothing to do, and nothing to back up.
    if [[ -L "$dst" && "$(readlink -- "$dst")" == "$src" ]]; then
      echo "✅ already linked: ${dst}"
      continue
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
      if $DRY_RUN; then
        echo "🧳 backup (dry-run): ${dst} -> ${backup_dir:-<no backup>}/"
      elif $BACKUP; then
        mkdir -p -- "$backup_dir"
        echo "🧳 backup: ${dst} -> ${backup_dir}/"
        mv -- "$dst" "$backup_dir/"
      else
        rm -rf -- "$dst"
      fi
    fi

    if $DRY_RUN; then
      echo "🔗 symlink (dry-run): ${dst} -> ${src}"
    else
      echo "🔗 symlink: ${dst} -> ${src}"
      ln -s -- "$src" "$dst"
    fi
  done
}

items=()
while IFS= read -r -d '' item; do
  base="$(basename -- "$item")"
  if [[ "$base" == "." || "$base" == ".." ]]; then
    continue
  fi
  for exclude in "${EXCLUDES[@]}"; do
    if [[ "$base" == "$exclude" ]]; then
      echo "⏭  skip: ${base}"
      continue 2
    fi
  done
  items+=("$item")
done < <(find "$REPO_DIR" -maxdepth 1 -mindepth 1 -print0)

if [[ ${#items[@]} -eq 0 ]]; then
  echo "No files found to install." >&2
  exit 1
fi

# Drift check. A deployed file is safe to overwrite if its content matches some
# version the repo has had -- current or older -- because then nothing is lost.
# Content that matches no version was edited in place, and a file inside an
# installed directory that the repo does not track (~/.zsh/completions/_hey,
# written by the HEY CLI) would be swept into the backup folder and stop
# working. Either is drift. Content is compared by git blob hash, so the check
# needs no record of what was installed when. Written for bash 3.2: the Mini's
# /usr/bin/env bash is the one macOS ships.
drift_check() {
  if ! command -v git >/dev/null 2>&1 || ! git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "⚠️  drift check skipped: needs git and a git checkout" >&2
    return 0
  fi

  local known found=0 item base dst rel f h
  known="$(mktemp)"
  git -C "$REPO_DIR" rev-list --objects --all | awk '{print $1}' > "$known"

  for item in "${items[@]}"; do
    base="$(basename -- "$item")"
    dst="${HOME_DIR}/${base}"

    if is_link_into "$base"; then
      for f in "$item"/*; do
        [[ -e "$f" ]] || continue
        rel="${base}/$(basename -- "$f")"
        if [[ -e "${HOME_DIR}/${rel}" && ! ( -L "${HOME_DIR}/${rel}" && "$(readlink -- "${HOME_DIR}/${rel}")" == "$f" ) ]]; then
          echo "  ✋ ~/${rel}: not a link to this repo"
          found=1
        fi
      done
      continue
    fi

    [[ -e "$dst" ]] || continue
    while IFS= read -r rel; do
      if [[ ! -e "${REPO_DIR}/${rel}" ]]; then
        echo "  ✋ ~/${rel}: not in the repo; installing would move it to the backup"
        found=1
        continue
      fi
      h="$(git hash-object -- "${HOME_DIR}/${rel}")"
      if [[ "$h" != "$(git hash-object -- "${REPO_DIR}/${rel}")" ]] && ! grep -qx "$h" "$known"; then
        echo "  ✋ ~/${rel}: edited in place (matches no repo version)"
        echo "       see: diff ~/${rel} ${REPO_DIR}/${rel}"
        found=1
      fi
    done < <(cd "$HOME_DIR" && find "$base" \( -type f -o -type l \))
  done

  rm -f -- "$known"
  return "$found"
}

echo "🔍 checking deployed files for drift"
if drift_check; then
  echo "✅ no drift: every deployed file matches a version of this repo"
  $CHECK_ONLY && exit 0
else
  $CHECK_ONLY && exit 1
  if $FORCE; then
    echo "⚠️  drift found; installing anyway (--force)"
  elif $DRY_RUN; then
    echo "⚠️  drift found; a real install would stop here (--force overrides)"
  else
    echo "🛑 drift found; nothing installed. Fold those changes into the repo, or rerun with --force." >&2
    exit 1
  fi
fi

if $BACKUP; then
  for item in "${items[@]}"; do
    base="$(basename -- "$item")"
    # Handled per-file by link_contents, which backs up only what it replaces.
    if is_link_into "$base"; then
      continue
    fi
    target="${HOME_DIR}/${base}"
    if [[ -e "$target" ]]; then
      if $DRY_RUN; then
        echo "🧳 backup (dry-run): ${target} -> ${backup_dir}/"
      else
        mkdir -p -- "$backup_dir"
        echo "🧳 backup: ${target} -> ${backup_dir}/"
        mv -- "$target" "$backup_dir/"
      fi
    fi
  done
fi

for item in "${items[@]}"; do
  base="$(basename -- "$item")"
  target="${HOME_DIR}/${base}"
  if is_link_into "$base"; then
    link_contents "$item" "$target"
  else
    copy_item "$item" "$target"
  fi
done

if $BACKUP; then
  if $DRY_RUN; then
    echo "🧳 backup dir (dry-run): ${backup_dir}"
  else
    echo "🧳 backups stored in: ${backup_dir}"
  fi
fi

echo "✅ install complete."
