#!/bin/bash

flag=/tmp/study-mode
id=$(cat /tmp/powermode-notify-id 2>/dev/null || echo 0)
pkill -x hypridle
if [ -f "$flag" ]; then
    rm "$flag"
    setsid hypridle >/dev/null 2>&1 &
    notify-send -p -r "$id" -a powermode -t 1200 "Study mode off" > /tmp/powermode-notify-id
else
    touch "$flag"
    setsid hypridle -c ~/.config/hypr/hypridle-study.conf >/dev/null 2>&1 &
    notify-send -p -r "$id" -a powermode -t 1200 "Study mode on" > /tmp/powermode-notify-id
fi
