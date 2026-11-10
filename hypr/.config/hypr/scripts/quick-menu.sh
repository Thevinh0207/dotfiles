#!/bin/bash

options=$(printf '%s\n' \
    $'\U000F05A9  WiFi' \
    $'\uf293  Bluetooth' \
    $'\uf028  Audio' \
    $'\uf0e7  Power mode' \
    $'\uf240  Charge limit' \
    $'\uf023  Lock' \
    $'\uf08b  Log out' \
    $'\uf021  Reboot' \
    $'\uf011  Shut down')

choice=$(echo "$options" | wofi --dmenu --style ~/.config/wofi/menu.css --width 320 --lines 9 --cache-file /dev/null --prompt "Quick settings")

case "$choice" in
*WiFi) ~/.config/hypr/scripts/wifi-menu.sh ;;
*Bluetooth) blueman-manager ;;
*Audio) pavucontrol ;;
*"Power mode") ~/.config/hypr/scripts/power-mode.sh ;;
*"Charge limit") ~/.config/hypr/scripts/battery-limit.sh ;;
*Lock) loginctl lock-session ;;
*"Log out") hyprctl dispatch 'hl.dsp.exit()' ;;
*Reboot) systemctl reboot ;;
*"Shut down") systemctl poweroff ;;
esac
