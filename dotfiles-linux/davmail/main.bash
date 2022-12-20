. ~/dotfiles-linux/davmail/helpers.bash

directory_config=/etc/conf.d
source=~/dotfiles-linux/davmail/davmail.properties
service=~/dotfiles-linux/davmail/davmail.service

copy_config $source $directory_config;
# activate_as_service $service
