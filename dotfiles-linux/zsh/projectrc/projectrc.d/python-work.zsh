dir="$HOME/dotfiles-linux/aider/prompts"
export AIDER_READ="[$dir/python-work-conventions.md]"

if is_running wsl; then
    name="$(basename $(pwd))"
    export WVENV=$WH/venvs/$name
    export WPY=$WVENV/Scripts/python.exe

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
