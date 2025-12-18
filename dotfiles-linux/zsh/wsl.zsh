_winenv() {
    cwd=$PWD
    cd /mnt/c
    /mnt/c/Windows/System32/cmd.exe /C "echo %$*%" | tr -d '\r'
    cd $cwd
}

reload-wsl() {
    append_to_path /mnt/c/Windows/System32
    append_to_path /mnt/c/Windows/System32/WindowsPowerShell/v1.0/
    append_to_path /mnt/c/Program\ Files/PowerShell/7-preview/

    export WH=$(wslpath "$(_winenv USERPROFILE)")
    export APPDATA="$WH/AppData/Roaming"
    export LOCALAPPDATA="$WH/AppData/Local"
    export WSLBROWSER="$LOCALAPPDATA/Programs/qutebrowser/qutebrowser.exe"
    export WINWSLBROWSER=$(wslpath -m "$WSLBROWSER")
    export WIN_PY="$APPDATA/uv/python/cpython-3.13.7-windows-x86_64-none/python.exe"

    set_tmux="\$Env:TMUX=\"${TMUX:-}\""
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
if is_running wsl; then
    reload-wsl
fi
