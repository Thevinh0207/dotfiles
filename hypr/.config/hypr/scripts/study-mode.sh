#!/bin/bash

flag=/tmp/study-mode
pkill -x hypridle
if [ -f "$flag" ]; then
    rm "$flag"
    setsid hypridle >/dev/null 2>&1 &
    notify-send -a powermode -t 1200 "Study mode off"
else
    touch "$flag"
    setsid hypridle -c ~/.config/hypr/hypridle-study.conf >/dev/null 2>&1 &
    notify-send -a powermode -t 1200 "Study mode on"
fi
