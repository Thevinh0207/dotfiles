#!/bin/bash

file=$(ls /sys/class/power_supply/BAT*/charge_control_end_threshold | head -n1)
current=$(cat "$file")

if [ "$current" -le 80 ]; then
    echo 100 >"$file"
    label="Charge limit off"
else
    echo 80 >"$file"
    label="Charge limit 80%"
fi

id=$(cat /tmp/battery-notify-id 2>/dev/null || echo 0)
notify-send -p -r "$id" -a powermode -t 1200 "$label" >/tmp/battery-notify-id
