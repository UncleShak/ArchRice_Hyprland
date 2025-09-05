#!/bin/bash

# -----------------------------
# Directories
# -----------------------------
DAY_WALLPAPER_DIR="$HOME/wallpapers/Day_Wallpapers"
NIGHT_WALLPAPER_DIR="$HOME/wallpapers/Night_Wallpapers"
WAL_DIR="$HOME/.cache/wal"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
VSCODE_USER_DIR="$HOME/.config/Code/User"

# -----------------------------
# Select wallpaper based on time
# -----------------------------
current_hour=$(date +%H)

if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 18 ]; then
    wallpaper=$(find "$DAY_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
    echo "Setting day wallpaper: $(basename "$wallpaper")"
else
    wallpaper=$(find "$NIGHT_WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
    echo "Setting night wallpaper: $(basename "$wallpaper")"
fi

if [ ! -f "$wallpaper" ]; then
    echo "Error: No wallpaper found"
    exit 1
fi

# -----------------------------
# Set wallpaper with fade
# -----------------------------
swww img "$wallpaper" --transition-type fade --transition-duration 2

# -----------------------------
# Generate wal colors
# -----------------------------
wal -i "$wallpaper" -n -t

# -----------------------------
# Apply Kitty colors (permanent & running)
# -----------------------------
KITTY_COLORS="$WAL_DIR/colors-kitty.conf"

# Include wal colors in kitty.conf if not already included
if ! grep -q "colors-kitty.conf" "$KITTY_CONF"; then
    echo "include $KITTY_COLORS" >> "$KITTY_CONF"
fi

# Apply colors to running kitty windows
if pgrep kitty >/dev/null; then
    kitty @ set-colors --all --config-file "$KITTY_COLORS"
fi

# -----------------------------
# Reload Hyprland
# -----------------------------
hyprctl reload

# -----------------------------
# Reload Waybar safely
# -----------------------------
if pgrep waybar >/dev/null; then
    waybar-msg reload || {
        pkill waybar
        sleep 0.5
        waybar &
    }
fi

# -----------------------------
# Update VSCode theme
# -----------------------------
# Generate VSCode theme from wal
wal -i "$wallpaper" --vscode

# Copy theme to VSCode User folder
mkdir -p "$VSCODE_USER_DIR"
cp "$WAL_DIR/colors-vscode.json" "$VSCODE_USER_DIR/wal-theme.json"

# Update settings.json to use wal-theme
SETTINGS_FILE="$VSCODE_USER_DIR/settings.json"

# Add or update workbench color theme
if ! grep -q "wal-theme" "$SETTINGS_FILE" 2>/dev/null; then
    # If settings.json doesn't exist or doesn't have wal-theme, append it
    jq '. + { "workbench.colorCustomizations": import("./wal-theme.json"), "workbench.colorTheme": "wal-theme" }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" 2>/dev/null || echo '{}' > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
fi

echo "Wallpaper, colors, and themes updated successfully!"

