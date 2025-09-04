#!/bin/bash

# Wallpaper directories
DAY_WALLPAPER_DIR="$HOME/wallpapers/Day_Wallpapers"
NIGHT_WALLPAPER_DIR="$HOME/wallpapers/Night_Wallpapers"

# Get current hour (24-hour format)
current_hour=$(date +%H)

# Determine which wallpaper to use
if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 18 ]; then
    # Day time - pick a random day wallpaper
    wallpaper=$(find "$DAY_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
    echo "Setting day wallpaper: $(basename "$wallpaper")"
else
    # Night time - pick a random night wallpaper  
    wallpaper=$(find "$NIGHT_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
    echo "Setting night wallpaper: $(basename "$wallpaper")"
fi

# Check if wallpaper exists
if [ ! -f "$wallpaper" ]; then
    echo "Error: No wallpaper found in the specified directory"
    exit 1
fi

# Set wallpaper with fade transition
swww img "$wallpaper" --transition-type fade --transition-duration 2

# Generate wal colors (with all templates)
wal -i "$wallpaper" -n -t

WAL_DIR="$HOME/.cache/wal"
KITTY_COLORS="$WAL_DIR/colors-kitty.conf"

# Ensure kitty uses wal colors permanently
if ! grep -q "colors-kitty.conf" "$HOME/.config/kitty/kitty.conf"; then
    echo "include $KITTY_COLORS" >> "$HOME/.config/kitty/kitty.conf"
fi

# Apply colors to all running kitty terminals
if pgrep kitty >/dev/null; then
    kitty @ set-colors --all --config-file "$KITTY_COLORS"
fi

# Reload Hyprland
hyprctl reload

# Reload Waybar safely
if pgrep waybar >/dev/null; then
    waybar-msg reload || {
        # fallback: clean restart if reload fails
        pkill waybar
        sleep 0.5
        waybar &
    }
fi

