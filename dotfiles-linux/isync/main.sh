#!/bin/bash
#
source="$HOME/dotfiles-linux/isync/.mbsyncrc_$MICROSOFT_ACCOUNT"
destination="$HOME/.mbsyncrc"

[ -f $source ] || { echo "Source: $source does not exist!"; exit; }

echo "Remove $destination"
rm $destination

echo "Symlink $source to $destination"
ln --symbolic $source $destination
