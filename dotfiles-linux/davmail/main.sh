#######################################
# The davmail config will be occupied with sensitive information hence it is
# copied to the config directory instead of a symlink. The config contains
# documentation for setting up calendar synchronization
#######################################
copy_config() { 
    source=$1
    directory_config=$2
    destination="$directory_config/davmail.properties"

    mkdir $directory_config --parents 
    rm $destination 
    cp $source $destination
    echo "Davmail: copied $source to $destination"
}

directory_config=~/.config/davmail 
source=~/dotfiles-linux/davmail/davmail.properties

yay -S davmail
sudo pacman -S java-openjfx
copy_config $source $directory_config;
