if grep -q microsoft /proc/version; then
    source ~/.bash/wsl.sh
    clear
fi

source ~/.bash/env.sh
source ~/.bash/aliases.sh
source ~/.bash/settings.sh
source ~/.bash/bindings.sh


[ -f ~/.fzf.bash ] && source ~/.fzf.bash

