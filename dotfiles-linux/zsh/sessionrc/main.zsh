# This file should be sourced from .zshrc. It will load extra zsh
# configurations based on the name of the current directory. This is useful for
# loading project specific configurations.
reload-session() {
    local name=$(basename $PWD)
    local this_dir=$HOME/dotfiles-linux/zsh/sessionrc

    [[ "$name" == "snapshot" ]] && source $this_dir/snapshotrc.zsh

    # If a project is a python project that is developed for windows, then
    # loading the winpyprojectrc.zsh file is nice as it allows you to call the
    # python windows interpreter from wsl. See the wpy executable for more
    # info.
    local winpyprojects=(navigation fc-sonar-server)
    [[ " ${winpyprojects[@]} " =~ " $name " ]] && source $this_dir/winpyprojectrc.zsh
}
reload-session
