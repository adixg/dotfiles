#!/usr/bin/env bash

WALLDIR="/home/aditya/wallpapers"

mapfile -d '' wallpapers < <(
    find "$WALLDIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -print0 | sort -z
)

count=${#wallpapers[@]}

if (( count == 0 )); then
    echo "No wallpapers found in $WALLDIR"
    exit 1
fi

# Get exact current wallpaper path
current="$(
    hyprctl hyprpaper listactive |
    sed -n 's/^eDP-1: //p'
)"

echo "Current: $current"

index=-1

for i in "${!wallpapers[@]}"; do
    if [[ "${wallpapers[$i]}" == "$current" ]]; then
        index=$i
        break
    fi
done

# Select next wallpaper and wrap back to 0
next_index=$(( (index + 1) % count ))
next="${wallpapers[$next_index]}"

echo "Next: $next"

hyprctl hyprpaper wallpaper "eDP-1, $next, cover"
hyprctl hyprpaper wallpaper "HDMI-A-1, $next, cover"
