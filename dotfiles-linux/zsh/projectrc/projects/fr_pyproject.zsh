#!/bin/env zsh

this_dir=$(readlink -f "$(dirname "$0")")
source $this_dir/pyprojects.zsh

if is_running wsl; then
    name="$(basename $(pwd))"
    export WINVENV=$WH/venvs/$name
    export WINCODE=$WH/code/$name

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
