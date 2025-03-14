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
    append_to_path /mnt/c/Python310/

    export WH=$(wslpath "$(_winenv USERPROFILE)")
    export WSLVENVS="$WH/venvs"
    export PWSH="/mnt/c/Program\ Files/PowerShell/7-preview/pwsh.exe"

    set_tmux="\$Env:TMUX=\"${TMUX:-}\""
    alias wh="cd $WH"
    alias mirror='echo $(pwd | sed "s|$HOME|$WH|")'
    alias winmirror='wslpath -w $(mirror)'

    alias pow="$PWSH -NoLogo -NoExit -Command '$set_tmux'"
    alias powc="$PWSH -NoLogo -Command $@"
    alias powh="$PWSH -NoLogo -NoExit -Command 'cd ~;$set_tmux'"
    alias powm="$PWSH -NoLogo -NoExit -Command 'cd $(winmirror);$set_tmux'"

    alias wjava="/mnt/c/Program\\ Files/Eclipse\\ Adoptium/jre-*-hotspot/bin/java.exe"
    alias plantuml='wjava -jar C:\\ProgramData\\chocolatey\\lib\\plantuml\\tools\\plantuml.jar'
}
if is_running wsl; then
    reload-wsl
fi
