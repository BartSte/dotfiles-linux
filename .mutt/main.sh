#!/bin/bash
directory=~/.mutt
config_files=(.signature .user .mailing_lists .mutt_oauth2.py .aliases .gal)

function copy_default_configs() {
    for file_name in "$@"
    do
        default_config="$directory/$file_name"
        user_config="$directory/${file_name:1}"
        cp $default_config $user_config --no-clobber
    done
}

function clone_gruvbox() {
    git clone https://git.sthu.org/repos/mutt-gruvbox.git ~/.mutt/gruvbox
}

copy_default_configs "${config_files[@]}"
clone_gruvbox