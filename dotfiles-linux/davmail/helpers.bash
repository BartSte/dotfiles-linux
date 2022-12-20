#######################################
# The davmail config will be occupied with sensitive information hence it is
# copied to the config directory instead of a symlink. The config contains
# documentation for setting up calendar synchronization
#######################################
copy_config() { 
    source=$1
    directory_config=$2
    destination="$directory_config/davmail.properties"

    sudo rm $destination 
    sudo cp $source $destination
    echo "Davmail: copied $source to $destination"
}

activate_as_service() {
    source=$1
    destination=/etc/systemd/system/davmail.service
    sudo rm $destination
    sudo cp $source $destination

    sudo useradd --system davmail
    sudo systemctl daemon-reload
    sudo systemctl enable davmail
    sudo systemctl start davmail
}
