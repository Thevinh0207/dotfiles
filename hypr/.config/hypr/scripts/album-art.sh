#!/bin/bash

file=/tmp/waybar-art.jpg
url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)

if [ -z "$url" ]; then
    rm -f "$file" /tmp/waybar-art.url
    echo "/tmp/waybar-art-none"
    exit 0
fi

if [ "$url" != "$(cat /tmp/waybar-art.url 2>/dev/null)" ]; then
    curl -s -o "$file" "$url" && echo "$url" > /tmp/waybar-art.url
fi
echo "$file"
