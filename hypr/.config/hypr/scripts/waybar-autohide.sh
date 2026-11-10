!/bin/bash

BAR_HEIGHT=44
HIDE_DELAY_TICKS=10
PEEK_TICKS=20
PEEK_FILE=/tmp/waybar-peek

pkill -x waybar
waybar &
shown=0
away=0

while true; do
    y=$(hyprctl cursorpos | cut -d',' -f2 | tr -d ' ')

    if [ -f "$PEEK_FILE" ]; then
        rm -f "$PEEK_FILE"
        if [ "$shown" -eq 0 ]; then
            pkill -SIGUSR1 -x waybar
            shown=1
        fi
        away=-$PEEK_TICKS
    fi

    if [ "$shown" -eq 0 ] && [ "$y" -le 2 ]; then
        pkill -SIGUSR1 -x waybar
        shown=1
        away=0
    elif [ "$shown" -eq 1 ]; then
        if [ "$y" -le "$BAR_HEIGHT" ]; then
            away=0
        else
            away=$((away + 1))
            if [ "$away" -ge "$HIDE_DELAY_TICKS" ]; then
                pkill -SIGUSR1 -x waybar
                shown=0
                away=0
            fi
        fi
    fi

    sleep 0.1
done
