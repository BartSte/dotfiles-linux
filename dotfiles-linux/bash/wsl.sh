function winenv() {
    cwd=$pwd
    cd /mnt/c
    cmd.exe /C "echo %$*%" | tr -d '\r'
    cd $cwd
}

export WH=$(wslpath "$(winenv USERPROFILE)")

set_tmux="\$Env:TMUX=\"$TMUX\""
alias pow="/mnt/c/Program\ Files/PowerShell/7/pwsh.exe -NoExit -Command 'cls;$set_tmux'"
alias powh="/mnt/c/Program\ Files/PowerShell/7/pwsh.exe -NoExit -Command 'cls;cd ~;$set_tmux'"
alias ex="Explorer.exe ."

