#!/bin/bash

bat=/sys/class/power_supply/BAT0
echo "battery=$(cat $bat/capacity)"
echo "status=$(cat $bat/status)"
echo "limit=$(cat $bat/charge_control_end_threshold)"
echo "wifi=$(nmcli radio wifi)"
echo "ssid=$(nmcli -t -f ACTIVE,SSID device wifi list --rescan no | grep '^yes' | cut -d: -f2-)"
echo "bluetooth=$(bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off)"
echo "profile=$(powerprofilesctl get)"
echo "volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')"
echo "muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo yes || echo no)"
echo "brightness=$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
echo "dnd=$(makoctl mode | grep -q do-not-disturb && echo on || echo off)"
echo "night=$(pgrep -x hyprsunset >/dev/null && echo on || echo off)"
echo "night_strength=$(cat ~/.cache/nightlight-strength 2>/dev/null || echo 50)"
echo "media_status=$(playerctl status 2>/dev/null)"
echo "media_title=$(playerctl metadata title 2>/dev/null)"
echo "media_artist=$(playerctl metadata artist 2>/dev/null)"
