if grep -q microsoft /proc/version; then
    source ~/.config/bash/wsl.sh
fi

source ~/.config/bash/env.sh
source ~/.config/bash/aliases.sh
source ~/.config/bash/settings.sh
source ~/.config/bash/bindings.sh


[ -f ~/.fzf.bash ] && source ~/.fzf.bash


