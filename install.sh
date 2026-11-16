#!/bin/sh
# Clippy installer: checks dependencies, installs the daemon's sprite and sets up autostart.
# Usage: ./install.sh [--no-autostart | --uninstall]
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$HOME/.config/clippy"
AUTOSTART="$HOME/.config/autostart/Clippy.desktop"

if [ "$1" = "--uninstall" ]; then
    rm -f "$AUTOSTART"
    echo "Removed autostart entry. Your settings in $CONF were left alone."
    exit 0
fi

echo "Checking dependencies..."
missing=""
command -v python3 >/dev/null || missing="$missing python3"
python3 -c "import PyQt6" 2>/dev/null || missing="$missing python3-pyqt6"
for tool in brightnessctl playerctl rg bwrap; do
    command -v "$tool" >/dev/null || case $tool in
        rg) missing="$missing ripgrep" ;;
        bwrap) missing="$missing bubblewrap" ;;
        *) missing="$missing $tool" ;;
    esac
done
if [ -n "$missing" ]; then
    echo "  Missing:$missing"
    echo "  Install with: sudo dnf install -y$missing"
else
    echo "  All found."
fi
command -v lms >/dev/null || echo "  Note: LM Studio's 'lms' CLI isn't on PATH. Install LM Studio and run 'lms bootstrap'."

mkdir -p "$CONF"
if [ ! -e "$CONF/clippy_daemon.png" ]; then
    cp "$DIR/assets/clippy_daemon.png" "$CONF/"
    echo "Installed the daemon sprite to $CONF/clippy_daemon.png"
fi
chmod +x "$DIR/clippy.py" "$DIR/clippy_daemon.py"

if [ "$1" != "--no-autostart" ]; then
    mkdir -p "$(dirname "$AUTOSTART")"
    sed "s|@CLIPPY_DIR@|$DIR|g" "$DIR/autostart/Clippy.desktop" > "$AUTOSTART"
    echo "Clippy will start when you log in ($AUTOSTART)."
fi
echo "Done. Start it now with: python3 $DIR/clippy.py &"
