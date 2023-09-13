#!/bin/bash

export MS_EMAIL=$(rbw_get username $MICROSOFT_ACCOUNT)
export MS_REALNAME=$(rbw_get name $MICROSOFT_ACCOUNT)

gpg --batch --gen-key ~/dotfiles-linux/gpg/gen-key-script

unset MS_EMAIL
unset MS_REALNAME
