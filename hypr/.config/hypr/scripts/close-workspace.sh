#!/bin/bash

ws=$(hyprctl activeworkspace -j | jq '.id')
count=$(hyprctl activeworkspace -j | jq '.windows')

if [ "$count" -eq 0 ]; then
    hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))'
    exit 0
fi

answer=$(printf "No, keep it\nYes, close workspace $ws ($count windows)" | wofi --dmenu --hide-search --style ~/.config/wofi/confirm.css --width 380 --lines 2 --cache-file /dev/null)
if [ "$answer" = "Yes, close workspace $ws ($count windows)" ]; then
    for ((i = 0; i < count; i++)); do
        hyprctl eval 'hl.dispatch(hl.dsp.window.close())'
        sleep 0.1
    done
    hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))'
fi
