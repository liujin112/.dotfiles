# Import devbox
export DEVBOX_ROOT=${DEVBOX_ROOT:-"$HOME/.devbox"}
[[ -d $DEVBOX_ROOT/libexec ]] && export PATH="$DEVBOX_ROOT/libexec:$PATH"
if [[ $- == *i* ]]; then
    eval "$(devbox init - bash)"
else
    eval "$(devbox init - --no-rehash bash)"
fi
source $DEVBOX_ROOT/completions/devbox.bash
