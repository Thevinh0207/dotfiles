#!/bin/bash

id=0

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case "$line" in
    workspace\>\>*)
        ws=${line#workspace>>}
        id=$(notify-send -p -r "$id" -a workspace -t 500 "Workspace $ws")
        ;;
    esac
done
