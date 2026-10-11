if [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]]; then
    export WIN_VENV="$WH/venvs/${${PROJECTRC_PROJECT_DIRECTORY:-$PWD}:t}"
    export WIN_PY="$WIN_VENV/Scripts/python.exe"

    alias wpip='wpy -m pip'
    alias wipdb='wpy -m ipdb'
    alias wpytest='wpy -m pytest'
fi
