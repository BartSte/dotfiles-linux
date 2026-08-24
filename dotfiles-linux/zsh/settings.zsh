unsetopt beep
setopt autocd extendedglob nomatch notify

# History
HISTFILE=$HOME/.histfile
HISTSIZE=200000
SAVEHIST=200000
setopt histignorealldups
setopt incappendhistory

# Interactive-only settings
KEYTIMEOUT=1
VI_MODE_SET_CURSOR=true

EARBUDS='30:53:C1:B8:CE:F6'
HEADPHONES='28:11:A5:A4:3A:CF'
SONY='AC:80:0A:C8:77:2C'

if [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
else
    unset GPG_TTY
fi
