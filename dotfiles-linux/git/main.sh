#!/bin/bash

function init_git() {
    echo "# Git"
    echo "Setting config..."

    git config --global credential.helper store
    git config --global core.autocrlf input
    git config --global user.name barts
    git config --global user.email $(rbw_get username $MICROSOFT_ACCOUNT)
    git config --global push.autoSetupRemote yes
    git config --global pull.rebase false

    cat ~/.gitconfig
}

init_git
