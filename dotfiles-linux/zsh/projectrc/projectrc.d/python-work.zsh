if [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]]; then
    name=${PWD:t}
    export WIN_VENV="$WH/venvs/$name"
    export WIN_PY="$WIN_VENV/Scripts/python.exe"

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
