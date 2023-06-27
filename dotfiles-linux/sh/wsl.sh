function winenv() {
    cwd=$pwd
    cd /mnt/c
    /mnt/c/Windows/System32/cmd.exe /C "echo %$*%" | tr -d '\r'
    cd $cwd
}

path_wsl=/mnt/c/Windows/System32:
path_wsl+=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:
path_wsl+=/mnt/c/Program\ Files/PowerShell/7-preview/:
path_wsl+=/mnt/c/Python310/
typeset -U PATH path  # remove duplicat entries from $PATH
export PATH=$PATH:$path_wsl
export WH=$(wslpath "$(winenv USERPROFILE)")

set_tmux="\$Env:TMUX=\"$TMUX\""
alias wh="cd $WH"
alias ex="/mnt/c/Windows/explorer.exe ."
alias mirror='echo $(pwd | sed "s|$HOME|$WH|")'
alias winmirror='wslpath -w $(mirror)'

pwsh="/mnt/c/Program\ Files/PowerShell/7-preview/pwsh.exe"
alias pow="$pwsh -NoLogo -NoExit -Command '$set_tmux'"
alias powc="$pwsh -NoLogo -Command $@"
alias powh="$pwsh -NoLogo -NoExit -Command 'cd ~;$set_tmux'"
alias powm="$pwsh -NoLogo -NoExit -Command 'cd $(winmirror);$set_tmux'"
