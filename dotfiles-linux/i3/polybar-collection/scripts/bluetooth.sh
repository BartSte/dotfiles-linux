#!/bin/sh

disabled_fg='#fb4934'
disabled_bg='#cc241d'
connected='#2832c9'
background='#282828'
foreground='#fbf1c7'

function bluetooth_is_off() {
    [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
}

function not_connected() {
    [ $(echo info | bluetoothctl | grep 'Device' | wc -c) -eq 0 ]
}

function get_device() {
    device=$(bluetoothctl info | grep 'Name' | sed 's/^.*Name: //')
}

function echo_power_if_off() {
    echo "%{T6}%{F${disabled_bg}}%{T-} %{B${background}} %{T2}%{F${disabled_fg}}Disabled%{T-}"
}

function echo_no_connection() {
    echo "%{T6}%{F${background}}%{T-} %{B${background}} %{T2}%{F${foreground}}No device%{T-}"
}

function echo_connected() {
    get_device
    echo "%{F${connected}}%{T6}%{T-} %{B${background}} %{T2}%{F${foreground}}$device%{T-}"
}

if bluetooth_is_off
then
    echo_power_if_off
else
    if not_connected
    then 
        echo_no_connection
      fi
    echo_connected
fi

