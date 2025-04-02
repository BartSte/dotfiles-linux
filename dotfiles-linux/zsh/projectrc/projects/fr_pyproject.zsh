#!/bin/env zsh

this_dir=$(readlink -f "$(dirname "$0")")
source $this_dir/pyprojects.zsh

# Use this configuration when you are doing a python project for windows. This
# way you can work in wsl and call to windows executables when running code.
<<<<<<< HEAD:dotfiles-linux/zsh/projectrc/projects/fr_pyproject.zsh
=======
prompts="$HOME/dotfiles-linux/aider/prompts"
export AIDER_READ="[$dir/conventions.md, $dir/python/conventions.md]"

>>>>>>> 6a88397b3271b0bda35e667efebef63fee8d456a:dotfiles-linux/zsh/projectrc/projects/winpyproject.zsh
if is_running wsl; then
    name="$(basename $(pwd))"
    export WINVENV=$WH/venvs/$name
    export WINCODE=$WH/code/$name

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
