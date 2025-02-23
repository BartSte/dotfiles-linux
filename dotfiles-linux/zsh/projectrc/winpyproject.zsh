#!/bin/env zsh

# Use this configuration when you are doing a pyton project for windows. This
# way you can work in wsl and call to windows executables when running code.

if is_running wsl; then
    name="$(basename $(pwd))"
    export WINVENV=$WH/venvs/$name
    export WINCODE=$WH/code/$name

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi

