#!/bin/bash

url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
[ -z "$url" ] && exit 0

file=/tmp/waybar-art.jpg
if [ "$url" != "$(cat /tmp/waybar-art.url 2>/dev/null)" ]; then
    curl -s -o "$file" "$url" && echo "$url" >/tmp/waybar-art.url
fi
echo "$file"
