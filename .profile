
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# Guarded like the RVM line above: these exist on the MacBook but not on the
# Mac Mini, and sourcing them unconditionally errors on every bash login shell
# there.
[[ -s "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"

[[ -s "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Personal scripts (sshconn, etc.)
export PATH="$HOME/bin:$PATH"
