#!/usr/bin/bash
systemctl start bluetooth
bluetoothctl power on
bluetoothctl discoverable on
bluetoothctl pairable on
