echo "# Neomutt"
repo_gruvbox=https://git.sthu.org/repos/mutt-gruvbox.git 
repo_powerline=https://github.com/sheoak/neomutt-powerline-nerdfonts.git
directory=~/.config/neomutt
cache="~/.cache/neomutt/$MUTT_ACCOUNT"

mkdir $directory
rm $directory/muttrc
ln ~/dotfiles-linux/mutt/muttrc $directory/muttrc

touch $cache/header_cache

git clone $repo_gruvbox $directory/gruvbox
git clone $repo_powerline $directory/powerline

echo "# Downloading emails"
mbsync $MUTT_ACCOUNT
