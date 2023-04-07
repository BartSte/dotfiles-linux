#!/bin/bash
#

echo "Setting up bitwarden cli."
source ~/dotfiles-linux/sh/env.sh
rbw config set email $BW_EMAIL
rbw login
rbw sync

