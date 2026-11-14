#!/bin/bash

width=20
offset=0
last=""

while true; do
    info=$(playerctl -p spotify metadata --format '{{status}}|{{title}} - {{artist}}' 2>/dev/null)
    if [ -z "$info" ]; then
        echo '{"text": ""}'
        sleep 1
        continue
    fi

    status=${info%%|*}
    text=${info#*|}

    if [ "$text" != "$last" ]; then
        offset=0
        last=$text
    fi

    if [ ${#text} -le $width ]; then
        shown=$text
    else
        loop="$text   •   "
        doubled="$loop$loop"
        shown=${doubled:$offset:$width}
        [ "$status" = "Playing" ] && offset=$(( (offset + 1) % ${#loop} ))
    fi

    if [ "$status" = "Playing" ]; then
        icon=$'\uf04c'
        class="playing"
    else
        icon=$'\uf04b'
        class="paused"
    fi

    out="$icon $shown"
    out=${out//\\/\\\\}
    out=${out//\"/\\\"}
    printf '{"text": "%s", "class": "%s"}\n' "$out" "$class"
    sleep 0.15
done
