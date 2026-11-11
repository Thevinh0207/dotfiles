#!/bin/bash

grouped=$(hyprctl activewindow -j | jq '.grouped | length')

if [ "$grouped" -gt 1 ]; then
    if [ "$1" = "prev" ]; then
        hyprctl eval 'hl.dispatch(hl.dsp.group.prev())'
    else
        hyprctl eval 'hl.dispatch(hl.dsp.group.next())'
    fi
else
    if [ "$1" = "prev" ]; then
        hyprctl eval 'hl.dispatch(hl.dsp.window.cycle_next({ next = false }))'
    else
        hyprctl eval 'hl.dispatch(hl.dsp.window.cycle_next())'
    fi
fi
