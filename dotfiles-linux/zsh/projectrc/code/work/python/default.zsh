# Activate virtualenv if .venv exists
source .venv/bin/activate 2>/dev/null || true

if is_running wsl; then
    name="$(basename $(pwd))"
    export WVENV=$WH/venvs/$name
    export WPY=$WVENV/Scripts/python.exe

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
