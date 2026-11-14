#!/bin/bash

pkill -f 'hypr/scripts/[w]allpaper.sh'
setsid ~/.config/hypr/scripts/wallpaper.sh >/dev/null 2>&1 &
