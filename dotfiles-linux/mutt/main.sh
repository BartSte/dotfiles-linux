echo "# Neomutt"
repo_gruvbox=https://git.sthu.org/repos/mutt-gruvbox.git 
repo_powerline=https://github.com/sheoak/neomutt-powerline-nerdfonts.git
directory=~/.config/neomutt

mkdir $directory
mkdir $directory/message_cache
touch $directory/header_cache
rm $directory/muttrc
ln ~/dotfiles-linux/mutt/muttrc $directory/muttrc
git clone $repo_gruvbox $directory/gruvbox
git clone $repo_powerline $directory/powerline

