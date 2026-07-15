# Login shell config (Bash)
# Keep Homebrew on Apple Silicon first and stable.
# Mirrors .zprofile: /etc/profile's path_helper puts /usr/local/bin ahead
# of /opt/homebrew/bin for every login shell, so re-prepend Homebrew here.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# bash previously fell through to ~/.profile (no ~/.bash_profile existed);
# source it here so rvm/atuin/volta setup still runs for login shells.
[ -r ~/.profile ] && . ~/.profile
