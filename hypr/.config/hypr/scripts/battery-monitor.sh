#!/bin/bash

dir=$(ls -d /sys/class/power_supply/BAT* | head -n1)
ac_file=/sys/class/power_supply/AC0/online
saving=0
notified=""
last_ac=""

enable_saver() {
    powerprofilesctl set power-saver
    brightnessctl -s set 40% >/dev/null
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false } } })'
    saving=1
}

disable_saver() {
    brightnessctl -r >/dev/null
    hyprctl eval 'hl.config({ animations = { enabled = true }, decoration = { blur = { enabled = true } } })'
    saving=0
}

popup() {
    id=$(cat /tmp/powermode-notify-id 2>/dev/null || echo 0)
    notify-send -p -r "$id" -a powermode -t 1200 "$1" >/tmp/powermode-notify-id
}

while true; do
    capacity=$(cat "$dir/capacity")
    ac=$(cat "$ac_file")

    if [ "$ac" != "$last_ac" ]; then
        if [ "$ac" = "1" ]; then
            [ "$saving" -eq 1 ] && disable_saver
            powerprofilesctl set performance
            notified=""
            [ -n "$last_ac" ] && popup "Plugged in · Performance"
        else
            if [ "$capacity" -le 30 ]; then
                enable_saver
                [ -n "$last_ac" ] && popup "On battery · Power saver"
            else
                powerprofilesctl set balanced
                [ -n "$last_ac" ] && popup "On battery · Balanced"
            fi
        fi
        last_ac=$ac
    fi

    if [ "$ac" = "0" ]; then
        for level in 10 30 50; do
            if [ "$capacity" -le "$level" ] && [[ " $notified " != *" $level "* ]]; then
                case $level in
                10) notify-send -a battery -u critical "Battery critical: ${capacity}%" "Plug in your charger" ;;
                30) notify-send -a battery -t 6000 "Battery low: ${capacity}%" "Battery saver is on" ;;
                50) notify-send -a battery -t 4000 "Battery at ${capacity}%" ;;
                esac
                for l in 10 30 50; do
                    [ "$l" -ge "$level" ] && notified="$notified $l"
                done
                break
            fi
        done

        if [ "$capacity" -le 30 ] && [ "$saving" -eq 0 ]; then
            enable_saver
        fi
    fi

    sleep 1
done
