_winenv() {
    local name=$1
    /mnt/c/Windows/System32/cmd.exe /D /C "echo %${name}%" | tr -d '\r'
}

reload-wsl() {
    append_to_path /mnt/c/Windows/System32
    append_to_path /mnt/c/Windows/System32/WindowsPowerShell/v1.0/
    append_to_path /mnt/c/Program\ Files/PowerShell/7/
    append_to_path /mnt/c/Program\ Files/PowerShell/7-preview/

    if [[ -n ${APPDATA:-} ]]; then
        if [[ $APPDATA == [[:alpha:]]:\\* ]]; then
            APPDATA=$(wslpath -u "$APPDATA")
        fi
        export WH=${APPDATA:h:h}
    else
        export WH=$(wslpath -u "$(_winenv USERPROFILE)")
    fi
    export APPDATA="$WH/AppData/Roaming"
    export LOCALAPPDATA="$WH/AppData/Local"
    export WSLBROWSER="$WH/scoop/apps/firefox/current/firefox.exe"
    export WINWSLBROWSER=$(wslpath -m "$WSLBROWSER")
    export WIN_PY="$APPDATA/uv/python/cpython-3.13-windows-x86_64-none/python.exe"

    local set_tmux="\$Env:TMUX=\"${TMUX:-}\""
    alias wh="cd $WH"
    alias mirror='echo $(pwd | sed "s|$HOME|$WH|")'
    alias winmirror='wslpath -w $(mirror)'

    alias dotnet="/mnt/c/Program\ Files/dotnet/dotnet.exe"
    alias pow="pwsh.exe -NoLogo -NoExit -Command '$set_tmux'"
    alias powc="pwsh.exe -NoLogo -Command $@"
    alias powh="pwsh.exe -NoLogo -NoExit -Command 'cd ~;$set_tmux'"
    alias powm="pwsh.exe -NoLogo -NoExit -Command 'cd $(winmirror);$set_tmux'"

    alias wjava="/mnt/c/Program\\ Files/Eclipse\\ Adoptium/jre-*-hotspot/bin/java.exe"
    alias plantuml='wjava -jar C:\\ProgramData\\chocolatey\\lib\\plantuml\\tools\\plantuml.jar'
}

if [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]]; then
    reload-wsl
fi
