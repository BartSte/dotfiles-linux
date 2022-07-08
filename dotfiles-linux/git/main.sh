function init_git() {
    echo "# Git"
    echo "Setting config..."

    git config --global credential.helper store
    git config --global core.autocrlf input
    git config --global user.name $GIT_NAME
    git config --global user.email "$MUTT_USERNAME@$MUTT_DOMAIN"

    batcat ~/.gitconfig
}

init_git
