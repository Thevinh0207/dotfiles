#!/bin/bash

strength=$(cat ~/.cache/nightlight-strength 2>/dev/null || echo 50)
temp=$((6500 - strength * 35))

if pgrep -x hyprsunset >/dev/null; then
    pkill -x hyprsunset
    label="Night light off"
else
    setsid hyprsunset -t "$temp" >/dev/null 2>&1 &
    label="Night light on"
fi

id=$(cat /tmp/powermode-notify-id 2>/dev/null || echo 0)
notify-send -p -r "$id" -a powermode -t 1000 "$label" >/tmp/powermode-notify-id
