#!/bin/bash
# ============================================================
#  ORIZON - Apply KDE Plasma Theme
#  Usage: orizon --theme [light|dark]
# ============================================================

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

# ── Paths ─────────────────────────────────────────────────────
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
ORIZON_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

ORIZON_LOGO="$ORIZON_DIR/branding/orizon-logo.png"
ORIZON_LINK="https://freesof.ru/orizon-os"
WALLPAPER_PATH="/usr/share/backgrounds/orizon/orizon-default.png"

# Application icons
ORIZON_SETTINGS_ICON="$ORIZON_DIR/branding/orizon-settings.png"
ORIZON_EXPLORER_ICON="$ORIZON_DIR/branding/orizon-nautilus-dolphin.png"
ORIZON_ICON_BLUETOOTH="$ORIZON_DIR/branding/orizon-bluetooth.png"
ORIZON_ICON_CALCULATOR="$ORIZON_DIR/branding/orizon-calculator.png"
ORIZON_ICON_CALENDAR="$ORIZON_DIR/branding/orizon-calendar.png"
ORIZON_ICON_DISK="$ORIZON_DIR/branding/orizon-diskusageanalyzer.png"
ORIZON_ICON_DISPLAY="$ORIZON_DIR/branding/orizon-display-ss.png"
ORIZON_ICON_INFO="$ORIZON_DIR/branding/orizon-info.png"
ORIZON_ICON_KONSOLE="$ORIZON_DIR/branding/orizon-konsole.png"
ORIZON_ICON_MEDIAPLAYER="$ORIZON_DIR/branding/orizon-mediaplayer.png"
ORIZON_ICON_NETWORK="$ORIZON_DIR/branding/orizon-network-wifi.png"
ORIZON_ICON_NOTEPAD="$ORIZON_DIR/branding/orizon-notepad.png"
ORIZON_ICON_OFFSYSTEM="$ORIZON_DIR/branding/orizon-offsystem.png"
ORIZON_ICON_PHOTOS="$ORIZON_DIR/branding/orizon-photos.png"
ORIZON_ICON_SHOP="$ORIZON_DIR/branding/orizon-shop.png"
ORIZON_ICON_TRASHBIN="$ORIZON_DIR/branding/orizon-trashbin.png"
ORIZON_ICON_UBUNTUSHOP="$ORIZON_DIR/branding/orizon-marketu.png"
ORIZON_ICON_SYSMON="$ORIZON_DIR/branding/orizon-sysmon.png"
ORIZON_ICON_LO_WRITER="$ORIZON_DIR/branding/orizon-lo-writer.png"
ORIZON_ICON_LO_CALC="$ORIZON_DIR/branding/orizon-lo-calc.png"
ORIZON_ICON_LO_IMPRESS="$ORIZON_DIR/branding/orizon-lo-impress.png"
ORIZON_ICON_LO_DRAW="$ORIZON_DIR/branding/orizon-lo-draw.png"
ORIZON_ICON_LO_BASE="$ORIZON_DIR/branding/orizon-lo-base.png"
ORIZON_ICON_LO_MATH="$ORIZON_DIR/branding/orizon-lo-math.png"
ORIZON_ICON_ARK="$ORIZON_DIR/branding/orizon-ark.png"
ORIZON_ICON_OKULAR="$ORIZON_DIR/branding/orizon-okular.png"
ORIZON_ICON_SCREENSHOT="$ORIZON_DIR/branding/orizon-screenshot.png"

MODE="${1:-light}"

# ── Helper: apply icon to a .desktop file ────────────────────
# Searches for .desktop in standard paths AND snap paths
set_icon() {
    local icon_path="$1"; shift
    local desktops=("$@")

    if [ ! -f "$icon_path" ]; then
        echo -e "${YELLOW}  ! Icon not found: $icon_path${NC}"
        return 0
    fi

    mkdir -p "$HOME/.local/share/applications"
    for desktop in "${desktops[@]}"; do
        local found=0
        for src_dir in \
            /usr/share/applications \
            /var/lib/snapd/desktop/applications \
            /snap/bin/../current/meta/gui
        do
            if [ -f "$src_dir/$desktop" ]; then
                cp "$src_dir/$desktop" "$HOME/.local/share/applications/$desktop"
                sed -i "s|^Icon=.*|Icon=$icon_path|g" "$HOME/.local/share/applications/$desktop"
                found=1
                break
            fi
        done
        # Warning only in explicit debug mode — don't clutter output
        # [ $found -eq 0 ] && echo -e "${YELLOW}  ! .desktop not found: $desktop${NC}"
    done
}

# ── Helper: icon for snap package (snap-specific filename snap_snap.desktop) ──
# Ubuntu/snap creates files like appname_appname.desktop
set_icon_snap() {
    local icon_path="$1"
    local snap_desktop="$2"   # e.g.: snap-store_snap-store.desktop

    [ ! -f "$icon_path" ] && return 0

    mkdir -p "$HOME/.local/share/applications"
    for src_dir in \
        /var/lib/snapd/desktop/applications \
        /usr/share/applications
    do
        if [ -f "$src_dir/$snap_desktop" ]; then
            cp "$src_dir/$snap_desktop" "$HOME/.local/share/applications/$snap_desktop"
            sed -i "s|^Icon=.*|Icon=$icon_path|g" "$HOME/.local/share/applications/$snap_desktop"
            return 0
        fi
    done
}

echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   ORIZON — applying KDE Plasma theme     ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

if [[ "$MODE" == "dark" ]]; then
    echo -e "  Mode: ${BOLD}Dark theme (Orizon-Dark)${NC}\n"
    COLOR_SCHEME="Orizon-Dark"
    LOOK_AND_FEEL="com.orizon.orizon-dark"
    ICON_THEME="Papirus-Dark"
else
    echo -e "  Mode: ${BOLD}Light theme (Orizon-Light)${NC}\n"
    COLOR_SCHEME="Orizon-Light"
    LOOK_AND_FEEL="org.kde.breeze.desktop"
    ICON_THEME="Papirus"
fi

# ── 1. Color scheme ───────────────────────────────────────────
echo -e "${CYAN}[1/8]${NC} Color scheme $COLOR_SCHEME..."
mkdir -p "$HOME/.local/share/color-schemes"
if [ -f "$ORIZON_DIR/kde/color-scheme/$COLOR_SCHEME.colors" ]; then
    cp "$ORIZON_DIR/kde/color-scheme/$COLOR_SCHEME.colors" "$HOME/.local/share/color-schemes/"
fi
plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "$LOOK_AND_FEEL"
echo -e "${GREEN}  ✓ Done${NC}"

# ── 2. Icons and fonts ────────────────────────────────────────
echo -e "${CYAN}[2/8]${NC} Icons $ICON_THEME and fonts..."
kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_THEME"
kwriteconfig5 --file kdeglobals --group General --key font "Ubuntu,11,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file kdeglobals --group General --key fixed "JetBrains Mono,11,-1,5,50,0,0,0,0,0"
echo -e "${GREEN}  ✓ Done${NC}"

# ── 3. Wallpaper ──────────────────────────────────────────────
echo -e "${CYAN}[3/8]${NC} ORIZON wallpaper..."
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        d.writeConfig('Image', 'file://$WALLPAPER_PATH');
    }
" 2>/dev/null
plasma-apply-wallpaperimage "$WALLPAPER_PATH" 2>/dev/null
echo -e "${GREEN}  ✓ Done${NC}"

# ── 4. About This System ──────────────────────────────────────
echo -e "${CYAN}[4/8]${NC} Customizing 'About This System'..."
mkdir -p "$HOME/.config"
cat > "$HOME/.config/kcm-about-distrorc" << EOF
[General]
LogoPath=$ORIZON_LOGO
Website=$ORIZON_LINK
EOF
echo -e "${GREEN}  ✓ Done${NC}"

# ── 5. Application icons ──────────────────────────────────────
echo -e "${CYAN}[5/8]${NC} ORIZON application icons..."

# File managers (Nautilus + Dolphin)
set_icon "$ORIZON_EXPLORER_ICON" \
    org.gnome.Nautilus.desktop \
    org.kde.dolphin.desktop
# Rename to "Files"
for desktop in org.gnome.Nautilus.desktop org.kde.dolphin.desktop; do
    dst="$HOME/.local/share/applications/$desktop"
    [ -f "$dst" ] && sed -i "s|^Name=.*|Name=Files|g" "$dst"
done

# System Settings
set_icon "$ORIZON_SETTINGS_ICON"  systemsettings.desktop

# Applications
set_icon "$ORIZON_ICON_KONSOLE"     org.kde.konsole.desktop  konsole.desktop
set_icon "$ORIZON_ICON_NOTEPAD"     org.kde.kate.desktop     kate.desktop
set_icon "$ORIZON_ICON_PHOTOS"      org.kde.gwenview.desktop gwenview.desktop
set_icon "$ORIZON_ICON_MEDIAPLAYER" vlc.desktop              org.videolan.VLC.desktop
set_icon "$ORIZON_ICON_CALCULATOR"  org.kde.kcalc.desktop    kcalc.desktop
set_icon "$ORIZON_ICON_CALENDAR"    org.kde.korganizer.desktop org.gnome.Calendar.desktop
set_icon "$ORIZON_ICON_SHOP"        org.kde.discover.desktop

# Ubuntu Shop / Snap Store — standard .desktop + snap-specific names
set_icon "$ORIZON_ICON_UBUNTUSHOP" \
    org.gnome.Software.desktop \
    ubuntu-software.desktop \
    snap-store.desktop
set_icon_snap "$ORIZON_ICON_UBUNTUSHOP" "snap-store_snap-store.desktop"

# System Monitor — standard + snap-specific name
set_icon "$ORIZON_ICON_SYSMON" \
    org.kde.plasma-systemmonitor.desktop \
    gnome-system-monitor.desktop \
    org.gnome.SystemMonitor.desktop \
    ksysguard.desktop
set_icon_snap "$ORIZON_ICON_SYSMON" "gnome-system-monitor_gnome-system-monitor.desktop"

set_icon "$ORIZON_ICON_DISK"        org.kde.filelight.desktop org.gnome.baobab.desktop

# LibreOffice
set_icon "$ORIZON_ICON_LO_WRITER"  libreoffice-writer.desktop
set_icon "$ORIZON_ICON_LO_CALC"    libreoffice-calc.desktop
set_icon "$ORIZON_ICON_LO_IMPRESS" libreoffice-impress.desktop
set_icon "$ORIZON_ICON_LO_DRAW"    libreoffice-draw.desktop
set_icon "$ORIZON_ICON_LO_BASE"    libreoffice-base.desktop
set_icon "$ORIZON_ICON_LO_MATH"    libreoffice-math.desktop
set_icon "$ORIZON_ICON_ARK"        org.kde.ark.desktop        ark.desktop
set_icon "$ORIZON_ICON_OKULAR"     org.kde.okular.desktop     okular.desktop
set_icon "$ORIZON_ICON_SCREENSHOT" org.kde.spectacle.desktop  spectacle.desktop

# System Settings modules (KCM)
set_icon "$ORIZON_ICON_BLUETOOTH"   bluedevil.desktop           kcm_bluetooth.desktop
set_icon "$ORIZON_ICON_NETWORK"     kcm_networkmanagement.desktop plasma-nm.desktop
set_icon "$ORIZON_ICON_DISPLAY"     kcm_kscreen.desktop          kcm_displayandmonitor.desktop
set_icon "$ORIZON_ICON_INFO"        kcm_about-distro.desktop     kcm_aboutsystem.desktop

# Trash bin — embed into all required hicolor sizes
for size in 32x32 48x48 128x128; do
    mkdir -p "$HOME/.local/share/icons/hicolor/$size/places"
    if [ -f "$ORIZON_ICON_TRASHBIN" ]; then
        cp "$ORIZON_ICON_TRASHBIN" \
            "$HOME/.local/share/icons/hicolor/$size/places/user-trash.png"
        cp "$ORIZON_ICON_TRASHBIN" \
            "$HOME/.local/share/icons/hicolor/$size/places/user-trash-full.png"
    fi
done

# Refresh .desktop database
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo -e "${GREEN}  ✓ Done${NC}"

# ── 6. Start button icon ──────────────────────────────────────
echo -e "${CYAN}[6/8]${NC} Start button icon..."
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    function fixIcon(container) {
        var ws = container.widgets;
        for (var i = 0; i < ws.length; i++) {
            var w = ws[i];
            if (w.type === 'org.kde.plasma.kickoff' ||
                w.type === 'org.kde.plasma.kicker' ||
                w.type === 'org.kde.plasma.simplemenu') {
                w.currentConfigGroup = ['General'];
                w.writeConfig('icon', '$ORIZON_LOGO');
            }
        }
    }
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) { fixIcon(allPanels[i]); }
" 2>/dev/null
echo -e "${GREEN}  ✓ Done${NC}"

# ── 7. Lock screen ────────────────────────────────────────────
echo -e "${CYAN}[7/8]${NC} Lock screen..."
kwriteconfig5 --file kscreenlockerrc \
    --group "Greeter/Wallpaper/org.kde.image/General" \
    --key Image "file://$WALLPAPER_PATH" 2>/dev/null
echo -e "${GREEN}  ✓ Done${NC}"

# ── 8. Kvantum + cache cleanup ───────────────────────────────
echo -e "${CYAN}[8/8]${NC} Kvantum and cache cleanup..."
if [ -d "$ORIZON_DIR/kde/kvantum/Orizon" ]; then
    mkdir -p "$HOME/.config/Kvantum/Orizon"
    cp -r "$ORIZON_DIR/kde/kvantum/Orizon/"* "$HOME/.config/Kvantum/Orizon/" 2>/dev/null
    cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=Orizon
EOF
    kwriteconfig5 --file kdeglobals --group General --key widgetStyle "kvantum" 2>/dev/null
fi

# Reset KDE and hicolor icon cache
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
rm -f "$HOME/.cache/icon-cache.kcache"
rm -rf "$HOME/.cache/plasma-svgelements-"*
kbuildsycoca5 --noincremental 2>/dev/null || true

echo -e "${GREEN}  ✓ Done${NC}"

USER_HOME=$(eval echo "~$INSTALL_USER")
BIN_DIR="$USER_HOME/.local/bin"
sudo rm "$BIN_DIR/orizon-first-run.sh"

# ── Restart Plasma ────────────────────────────────────────────
echo -e "\n  Restarting Plasma..."
kquitapp5 plasmashell >/dev/null 2>&1 || kquitapp6 plasmashell >/dev/null 2>&1
sleep 2
kstart5 plasmashell >/dev/null 2>&1 &
kstart6 plasmashell >/dev/null 2>&1 &

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ORIZON theme applied successfully!  ✓  ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
