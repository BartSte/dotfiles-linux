#!/usr/bin/bash

systemctl --user enable mailcalsync.timer
systemctl --user start mailcalsync.timer
