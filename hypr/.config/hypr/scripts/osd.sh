#!/bin/bash

id_file=/tmp/osd-notify-id
id=$(cat "$id_file" 2>/dev/null || echo 0)

case "$1" in
volume-up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
brightness-up) brightnessctl -e4 -n2 set 5%+ >/dev/null ;;
brightness-down) brightnessctl -e4 -n2 set 5%- >/dev/null ;;
esac

case "$1" in
volume-*)
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    value=$(echo "$vol" | awk '{print int($2*100)}')
    if echo "$vol" | grep -q MUTED; then
        icon=$'\uf026'
        shown=0
    else
        icon=$'\uf028'
        shown=$value
        pw-play /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga &
    fi
    ;;
brightness-*)
    value=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    icon=$'\U000F05A8'
    shown=$value
    ;;
esac

filled=$((shown / 5))
bar_on=""
bar_off=""
for ((i = 0; i < 20; i++)); do
    if [ "$i" -lt "$filled" ]; then
        bar_on+="━"
    else
        bar_off+="━"
    fi
done

number=$(printf '%3d' "$value")
text="$icon  <span foreground='#7e9cd8'>$bar_on</span><span foreground='#54546d'>$bar_off</span>  $number"

notify-send -p -r "$id" -a osd -t 1200 "osd" "$text" >"$id_file"
