#!/usr/bin/env bash
# Toggle the JBL Flip 7 Bluetooth connection.
MAC="50:1B:6A:D2:A2:FD"

if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$MAC"
    notify-send "JBL Flip 7" "Disconnected"
else
    bluetoothctl connect "$MAC"
    notify-send "JBL Flip 7" "Connected"
fi
