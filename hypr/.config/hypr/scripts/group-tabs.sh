#!/bin/bash

ws=$(hyprctl activeworkspace -j | jq '.id')
hyprctl clients -j | jq -c --argjson ws "$ws" '
  [ .[] | select(.workspace.id == $ws and (.grouped | length) > 1) ] as $c
  | [ $c[] | .grouped ] | unique
  | map(. as $g
      | [ $c[] | select(.address as $a | $g | index($a) != null) ] as $members
      | ($members | min_by(.focusHistoryID)) as $win
      | select($win != null and ($win.fullscreen // 0) == 0)
      | {
          x: $win.at[0],
          y: $win.at[1],
          w: $win.size[0],
          tabs: [ $g[] as $a | $members[] | select(.address == $a) | {address, class, title, active: (.address == $win.address)} ]
        })'
