#!/bin/bash

lock_icon=$' \uf023'
check_icon=$' \uf00c'
settings_entry=$'\uf013  More settings'
switch_on=$'\U000F0521'
switch_off=$'\U000F0522'

wifi_state=$(nmcli radio wifi)
if [ "$wifi_state" = "enabled" ]; then
    toggle="WiFi  $switch_on"
else
    toggle="WiFi  $switch_off"
fi

list=""
if [ "$wifi_state" = "enabled" ]; then
    nmcli device wifi rescan >/dev/null 2>&1 &
    list=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no | {
        declare -A seen
        while IFS=: read -r inuse signal security ssid; do
            ssid=${ssid//\\:/:}
            [ -z "$ssid" ] && continue
            [ -n "${seen[$ssid]}" ] && continue
            seen[$ssid]=1
            if [ "$signal" -ge 75 ]; then
                icon=$'\U000F0928'
            elif [ "$signal" -ge 50 ]; then
                icon=$'\U000F0925'
            elif [ "$signal" -ge 25 ]; then
                icon=$'\U000F0922'
            else icon=$'\U000F091F'; fi
            line="$icon  $ssid"
            [ -n "$security" ] && [ "$security" != "--" ] && line="$line$lock_icon"
            [ "$inuse" = "*" ] && line="$line$check_icon"
            echo "$line"
        done
    })
fi

choice=$(printf '%s\n%s\n%s\n' "$toggle" "$list" "$settings_entry" | sed '/^$/d' | wofi --dmenu --style ~/.config/wofi/menu.css --width 420 --lines 10 --cache-file /dev/null --prompt "WiFi")

[ -z "$choice" ] && exit 0

case "$choice" in
"$toggle")
    [ "$wifi_state" = "enabled" ] && nmcli radio wifi off || nmcli radio wifi on
    exit 0
    ;;
*"More settings")
    kitty --class nmtui -e nmtui
    exit 0
    ;;
esac

ssid=${choice#*  }
connected=0
[[ "$ssid" == *"$check_icon" ]] && connected=1
ssid=${ssid%"$check_icon"}
secured=0
[[ "$ssid" == *"$lock_icon" ]] && secured=1
ssid=${ssid%"$lock_icon"}

if [ "$connected" -eq 1 ]; then
    nmcli connection down id "$ssid" >/dev/null && notify-send -a powermode -t 1200 "Disconnected"
    exit 0
fi

if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
        notify-send -a powermode -t 1500 "Connected to $ssid"
    else
        notify-send -a powermode -t 2000 "Couldn't connect to $ssid"
    fi
    exit 0
fi

if [ "$secured" -eq 1 ]; then
    password=$(wofi --dmenu --password --style ~/.config/wofi/menu.css --width 420 --lines 1 --cache-file /dev/null --prompt "Password for $ssid" </dev/null)
    [ -z "$password" ] && exit 0
    if nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
        notify-send -a powermode -t 1500 "Connected to $ssid"
    else
        nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify-send -a powermode -t 2000 "Wrong password or couldn't connect"
    fi
else
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify-send -a powermode -t 1500 "Connected to $ssid"
    else
        notify-send -a powermode -t 2000 "Couldn't connect to $ssid"
    fi
fi
