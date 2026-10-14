# Import devbox (fish counterpart of shell/zsh/00_devbox.zshrc)
set -q DEVBOX_ROOT; or set -gx DEVBOX_ROOT "$HOME/.devbox"
if test -d "$DEVBOX_ROOT/libexec"; and not contains -- "$DEVBOX_ROOT/libexec" $PATH
    set -gx PATH "$DEVBOX_ROOT/libexec" $PATH
end
# A standalone conf.d/devbox.fish may already have initialized this shell.
# Check the function as well: DEVBOX_SHELL alone is inherited by child shells.
if not functions -q devbox; or test "$DEVBOX_SHELL" != fish
    # This devbox distribution has no rehash command.
    command devbox init - --no-rehash fish | source
end
