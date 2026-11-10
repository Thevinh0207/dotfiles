#!/bin/bash

count=$(hyprctl activeworkspace -j | jq '.windows')

for ((i = 0; i < count; i++)); do
    hyprctl eval 'hl.dispatch(hl.dsp.window.kill())'
    sleep 0.1
done
hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))'
