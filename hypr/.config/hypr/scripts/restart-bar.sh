#!/bin/bash

pkill -f '[w]aybar-autohide'
pkill -x waybar
setsid ~/.config/hypr/scripts/waybar-autohide.sh >/dev/null 2>&1 &
