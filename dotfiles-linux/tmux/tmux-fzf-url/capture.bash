#!/usr/bin/env bash
tmux capture-pane -J -p -e -S 0 -E 5000 > /tmp/tmux-fzf-url-capture
