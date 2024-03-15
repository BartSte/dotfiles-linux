#!/usr/bin/env bash

open_url() {
    echo 'Url detected, opening in browser.' >>$debug
    if running_wsl; then
        echo "Opening url with WSLBROWSER: $WSLBROWSER" >>$debug
        "$WSLBROWSER" $1 >>$debug 2>&1 &
    else
        echo "Opening url with BROWSER: $BROWSER" >>$debug
        $BROWSER $1 &>/dev/null &
    fi
}

open_img() {
    echo "Opening image $1 with imv" >>$debug
    imv $1 &>>$debug &
}

open_text() {
    local path=$1
    local file=$(echo $path | cut -d ':' -f 1)
    local line=$(echo $path | cut -d ':' -f 2 -s) # -s ensures nothing is returned if ':' is not found
    line=${line:-1}
    echo "Opening python file: $file at line $line at window:pane $TVIM_WINDOW:$TVIM_PANE" >>$debug
    if running_tmux; then
        tvim -d /tmp/tvim.log -l $line $file
    else
        nvim -c ":e $file|$line"
    fi
}
