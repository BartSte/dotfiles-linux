#!/bin/bash
#

echo "Setting up bitwarden cli."
echo "Which bitwarden email to use? Enter below:"
read email
rbw config set email $email
rbw config set lock_timeout 86400
rbw login
rbw sync
echo "Finished setting up bitwarden."
