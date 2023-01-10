function winenv() {
    cwd=$pwd
    cd /mnt/c
    cmd.exe /C "echo %$*%" | tr -d '\r'
    cd $cwd
}

export WH=$(wslpath "$(winenv USERPROFILE)")

set_tmux="\$Env:TMUX=\"$TMUX\""
alias pow="/mnt/c/Program\ Files/PowerShell/7-preview/pwsh.exe -NoLogo -NoExit -Command '$set_tmux'"
alias powh="/mnt/c/Program\ Files/PowerShell/7-preview/pwsh.exe -NoLogo -NoExit -Command 'cd ~;$set_tmux'"
alias ex="Explorer.exe ."
alias wh="cd $WH"
