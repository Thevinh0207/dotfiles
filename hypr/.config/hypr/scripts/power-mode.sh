#!/bin/bash

modes=(power-saver balanced performance)
current=$(powerprofilesctl get)
next=${modes[0]}

for i in "${!modes[@]}"; do
    if [ "${modes[$i]}" = "$current" ]; then
        next=${modes[$(((i + 1) % ${#modes[@]}))]}
    fi
done

powerprofilesctl set "$next"

case "$next" in
power-saver) label="Power saver" ;;
balanced) label="Balanced" ;;
performance) label="Performance" ;;
esac

id=$(cat /tmp/powermode-notify-id 2>/dev/null || echo 0)
notify-send -p -r "$id" -a powermode -t 800 "$label" >/tmp/powermode-notify-id
