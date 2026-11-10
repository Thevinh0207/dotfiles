#!/bin/bash

dir=$(ls -d /sys/class/power_supply/BAT* | head -n1)
saving=0

while true; do
    capacity=$(cat "$dir/capacity")
    status=$(cat "$dir/status")

    if [ "$status" = "Discharging" ] && [ "$capacity" -le 30 ] && [ "$saving" -eq 0 ]; then
        powerprofilesctl set power-saver
        brightnessctl -s set 40% >/dev/null
        hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false } } })'
        notify-send -a powermode -t 2000 "Battery saver"
        saving=1
    elif [ "$status" != "Discharging" ] && [ "$saving" -eq 1 ]; then
        powerprofilesctl set balanced
        brightnessctl -r >/dev/null
        hyprctl eval 'hl.config({ animations = { enabled = true }, decoration = { blur = { enabled = true } } })'
        saving=0
    fi

    sleep 30
done
