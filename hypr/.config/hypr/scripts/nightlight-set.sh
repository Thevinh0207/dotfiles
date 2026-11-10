#!/bin/bash

strength=$1
echo "$strength" >~/.cache/nightlight-strength
pgrep -x hyprsunset >/dev/null || exit 0
temp=$((6500 - strength * 35))
pkill -x hyprsunset
while pgrep -x hyprsunset >/dev/null; do sleep 0.05; done
setsid hyprsunset -t "$temp" >/dev/null 2>&1 &
