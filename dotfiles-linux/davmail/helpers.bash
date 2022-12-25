#######################################
# The davmail config will be occupied with sensitive information hence it is
# copied to the config directory instead of a symlink. The config contains
# documentation for setting up calendar synchronization
#######################################
copy_config() { 
    source=$1
    directory_config=$2
    destination="$directory_config/davmail.properties"

    rm $destination || mkdir $directory_config
    cp $source $destination
    echo "Davmail: copied $source to $destination"
}

activate_as_service() {
    killall davmail
    systemctl --user disable davmail.service
    systemctl --user daemon-reload
    systemctl --user enable davmail.service
    systemctl --user start davmail.service
}
