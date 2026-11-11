#!/bin/bash

dir=~/Pictures/wallpapers
interval=1800

pkill -x swaybg
current=""

while true; do
    file=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n 1)
    swaybg -i "$file" -m fill &
    new=$!
    sleep 1
    [ -n "$current" ] && kill "$current"
    current=$new
    sleep "$interval"
done
