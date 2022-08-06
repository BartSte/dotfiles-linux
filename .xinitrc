#!/bin/sh

# Set laptop monitor as primary, optional external to the right
xrandr --output LVDS1 --mode 1920x1080 --rate 60 --primary
xrandr --output HDMI1 --mode 1920x1080 --rate 60 --right-of LVDS1
exec i3
