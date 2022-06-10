#!/bin/sh
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources

# Set laptop monitor as primary, optional external to the left
sleep 2
xrandr --output LVDS1 --mode 1920x1080 --rate 60 --primary
xrandr --output HDMI1 --mode 1920x1080 --rate 60 --right-of LVDS1

# Start background processes
nitrogen --restore &
picom &
dunst &
alacritty &

exec i3
