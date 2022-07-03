function init_git() {
    git config --global credential.helper store
    git config --global core.autocrlf input
    git config --global user.name $GIT_NAME
    git config --global user.email "$MUTT_USERNAME@$MUTT_DOMAIN"
    git config --global status.showUntrackedFiles = no
}

init_git
