function winenv() {
    cwd=$pwd
    cd /mnt/c
    cmd.exe /C "echo %$*%" | tr -d '\r'
    cd $cwd
}

export WH=$(wslpath "$(winenv USERPROFILE)")
alias wh='cd $WH'
alias pow="powershell.exe -NoExit -Command 'cls'"
alias powh="powershell.exe -NoExit -Command 'cd ~'"
alias ex="Explorer.exe ."

