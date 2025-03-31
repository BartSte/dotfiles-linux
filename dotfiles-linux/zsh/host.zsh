# Source the zsh file in `dotfiles-linux/zsh/hosts` that corresponds to the hostname.
# If no such file exists, source the default file.
source "$HOME/dotfiles-linux/zsh/hosts/$(hostname).zsh"
