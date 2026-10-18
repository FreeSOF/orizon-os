#!/bin/bash
# ============================================================
#  ORIZON - Apply KDE Plasma Theme
#  Usage: orizon --theme [light|twilight|dark]
# ============================================================

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

# ── Paths ─────────────────────────────────────────────────────
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
ORIZON_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

ORIZON_LOGO="/usr/share/pixmaps/orizon/orizon-logo.png"
ORIZON_LINK="https://freesof.ru/orizon-os"
WALLPAPER_PATH="/usr/share/backgrounds/orizon/orizon-default.png"
LAKE_WALLPAPER_PATH="/usr/share/backgrounds/orizon/lake.png"

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
    ICON_THEME="ePapirus-Dark"
    USE_KVANTUM=1
    PLASMA_STYLE="breeze-dark"
    PANEL_ICON="/usr/share/pixmaps/orizon/orizon-logo-mono.png"
elif [[ "$MODE" == "twilight" ]]; then
    echo -e "  Mode: ${BOLD}Twilight theme (Orizon-Light + dark panel)${NC}\n"
    COLOR_SCHEME="Orizon-Light"
    LOOK_AND_FEEL="com.orizon.orizon-twilight"
    ICON_THEME="ePapirus"
    USE_KVANTUM=1
    PLASMA_STYLE="breeze-dark"
    PANEL_ICON="/usr/share/pixmaps/orizon/orizon-logo-mono.png"
else
    MODE="light"
    echo -e "  Mode: ${BOLD}Light theme (Orizon-Light)${NC}\n"
    COLOR_SCHEME="Orizon-Light"
    LOOK_AND_FEEL="com.orizon.orizon-light"
    ICON_THEME="ePapirus"
    USE_KVANTUM=1
    KVANTUM_THEME="Orizon-Light"
    PLASMA_STYLE="default"
    PANEL_ICON="/usr/share/pixmaps/orizon/orizon-logo-black.png"
fi

# Light theme needs a black Start-button logo; build it from the mono/main
# logo if the installer has not already (alpha kept, colour forced to black).
if [ "$PANEL_ICON" = "/usr/share/pixmaps/orizon/orizon-logo-black.png" ] && [ ! -f "$PANEL_ICON" ]; then
    for _src in /usr/share/pixmaps/orizon/orizon-logo-mono.png \
                /usr/share/pixmaps/orizon/orizon-logo-48.png \
                /usr/share/pixmaps/orizon/orizon-logo.png; do
        [ -f "$_src" ] || continue
        mkdir -p "$HOME/.local/share/orizon"
        BLACK_LOGO="$HOME/.local/share/orizon/orizon-logo-black.png"
        if python3 - "$_src" "$BLACK_LOGO" 2>/dev/null << 'PYEOF'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGBA")
r, g, b, a = im.split()
z = r.point(lambda _: 0)
Image.merge("RGBA", (z, z, z, a)).save(sys.argv[2])
PYEOF
        then PANEL_ICON="$BLACK_LOGO"
        elif convert "$_src" -channel RGB -evaluate set 0 +channel "$BLACK_LOGO" 2>/dev/null; then PANEL_ICON="$BLACK_LOGO"
        else PANEL_ICON="$_src"; fi
        break
    done
fi

# Refresh the service/desktop cache before applying anything.
kbuildsycoca5 --noincremental 2>/dev/null || true

# ── 1. Color scheme ─────────────────────────────────────────────
# We no longer install com.orizon.orizon-dark/light as a Global Theme
# package (it never worked from System Settings' Apply button and only
# confused people by showing up as a broken option there). Instead this
# script applies the color scheme, icons, and wallpaper directly — this
# is exactly what "orizon --theme dark/light" is for.
echo -e "${CYAN}[1/8]${NC} Color scheme $COLOR_SCHEME..."
mkdir -p "$HOME/.local/share/color-schemes"
if [ -f "$ORIZON_DIR/kde/color-scheme/$COLOR_SCHEME.colors" ]; then
    cp "$ORIZON_DIR/kde/color-scheme/$COLOR_SCHEME.colors" "$HOME/.local/share/color-schemes/"
fi
plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "$LOOK_AND_FEEL"

# Windows 11-style rounded corners — Breeze decoration corner radius
kwriteconfig5 --file breezerc --group Windeco --key CornerRadius 6 2>/dev/null
kwriteconfig5 --file breezerc --group Windeco --key DrawBorderOnMaximizedWindows false 2>/dev/null

# Breeze window decoration with large buttons
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.style.breeze"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "MF"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file breezerc --group Windeco --key ButtonSize 3

qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
# Plasma Style (desktoptheme) — this is what actually colors the panel
# and Kickoff chrome/background, separate from Kvantum (which only
# styles buttons/widgets inside apps). Without this the panel just
# inherits whatever the system's stock default happens to be.
plasma-apply-desktoptheme "$PLASMA_STYLE" 2>/dev/null
kwriteconfig5 --file plasmarc --group Theme --key name "$PLASMA_STYLE"
# Force the panel to re-read the desktoptheme immediately via DBus,
# without waiting for a plasmashell restart — without this, the panel
# keeps its previous chrome color even though plasmarc is already updated.
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.refreshCurrentShell 2>/dev/null || true
# Tell orizon-theme-watcher.sh this theme is already applied, so it doesn't
# see our own kdeglobals write and redundantly run this whole script again
# (it's only meant to react to a change made from System Settings).
mkdir -p "$HOME/.config"
echo "$LOOK_AND_FEEL" > "$HOME/.config/orizon-theme-state" 2>/dev/null || true
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
# Rename to "Files" — also strip localized Name[xx]=, otherwise KDE prefers
# the translated upstream name over our plain Name= under non-English locales
for desktop in org.gnome.Nautilus.desktop org.kde.dolphin.desktop; do
    dst="$HOME/.local/share/applications/$desktop"
    if [ -f "$dst" ]; then
        sed -i "/^Name\[/d" "$dst"
        sed -i "s|^Name=.*|Name=Files|g" "$dst"
    fi
done

# System Settings — check all known desktop-file IDs (varies by distro/version),
# rename and strip localized Name[xx]= for the same reason as above (this is
# what was showing "Параметры системы KDE" instead of our branding)
for desktop in systemsettings.desktop systemsettings5.desktop org.kde.systemsettings.desktop; do
    set_icon "$ORIZON_SETTINGS_ICON" "$desktop"
    dst="$HOME/.local/share/applications/$desktop"
    if [ -f "$dst" ]; then
        sed -i "/^Name\[/d" "$dst"
        sed -i "s|^Name=.*|Name=Параметры системы|g" "$dst"
        sed -i "/^GenericName\[/d" "$dst"
        # older installers added a bogus --mode flag that systemsettings5 rejects
        sed -i -E 's/ --mode systemsettings_sidebar_mode//g' "$dst"
    fi
done

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

# ── 7. Lock screen ────────────────────────────────────────────
echo -e "${CYAN}[7/8]${NC} Lock screen..."
kwriteconfig5 --file kscreenlockerrc --group Greeter --key Theme "$LOOK_AND_FEEL" 2>/dev/null
kwriteconfig5 --file kscreenlockerrc \
    --group "Greeter/Wallpaper/org.kde.image/General" \
    --key Image "file://$LAKE_WALLPAPER_PATH" 2>/dev/null
echo -e "${GREEN}  ✓ Done${NC}"

# ── 8. Kvantum + cache cleanup ───────────────────────────────
echo -e "${CYAN}[8/8]${NC} Widget style and cache cleanup..."
KV_THEME="${KVANTUM_THEME:-Orizon}"
if [ "$USE_KVANTUM" = "1" ] && [ -d "$ORIZON_DIR/kde/kvantum/$KV_THEME" ]; then
    mkdir -p "$HOME/.config/Kvantum/$KV_THEME"
    cp -r "$ORIZON_DIR/kde/kvantum/$KV_THEME/"* "$HOME/.config/Kvantum/$KV_THEME/" 2>/dev/null
    cat > "$HOME/.config/Kvantum/kvantum.kvconfig" << EOF
[General]
theme=$KV_THEME
EOF
    kwriteconfig5 --file kdeglobals --group General --key widgetStyle "kvantum" 2>/dev/null
else
    kwriteconfig5 --file kdeglobals --group General --key widgetStyle "Breeze" 2>/dev/null
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

# ── Rebuild panel widgets in the correct order ──────────────
# Live-adding/swapping individual widgets doesn't fix ORDER on panels
# that already existed before these features did — Plasma's scripting
# API has no simple "move to position" call. So instead: wipe every
# widget off each panel and re-add them in the exact order we want,
# guaranteeing Kickoff is leftmost and Show Desktop is rightmost every
# time, regardless of whatever order was there before.
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) {
        var p = allPanels[i];
        var ws = p.widgets();
        for (var j = 0; j < ws.length; j++) {
            ws[j].remove();
        }
        p.addWidget('org.kde.plasma.kickoff');
        p.addWidget('org.kde.plasma.marginsseparator');
        var tasks = p.addWidget('org.kde.plasma.icontasks');
        tasks.currentConfigGroup = ['Configuration', 'General'];
        tasks.writeConfig('showOnlyCurrentDesktop', true);
        tasks.writeConfig('groupingStrategy', 1);
        p.addWidget('org.kde.plasma.marginsseparator');
        p.addWidget('org.kde.plasma.systemtray');
        var clock = p.addWidget('org.kde.plasma.digitalclock');
        clock.currentConfigGroup = ['Configuration', 'Appearance'];
        clock.writeConfig('showDate', true);
        clock.writeConfig('dateFormat', 'shortDate');
        p.addWidget('org.kde.plasma.showdesktop');
    }
" 2>/dev/null || true

# ── Restart Plasma ────────────────────────────────────────────
# Quit plasmashell BEFORE touching the panel icon, not after. The
# previous version wrote the Start-button icon via a live qdbus
# evaluateScript call and only then restarted plasmashell — but
# plasmashell can flush its own in-memory applet state back to
# plasma-org.kde.plasma.desktop-appletsrc when it quits, which raced
# with (and silently undid) the icon we'd just written. Killing it
# first and editing the config file directly while nothing is running
# to overwrite it is what actually sticks.
echo -e "\n  Restarting Plasma..."
kquitapp5 plasmashell >/dev/null 2>&1 || kquitapp6 plasmashell >/dev/null 2>&1
sleep 2

# ── 6. Start button icon ──────────────────────────────────────
echo -e "${CYAN}[6/8]${NC} Start button icon..."
PLASMA_CFG="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$PLASMA_CFG" ]; then
    python3 - "$PLASMA_CFG" "$PANEL_ICON" << 'PYEOF'
import re
import sys

path, icon = sys.argv[1], sys.argv[2]

with open(path) as f:
    lines = f.readlines()

# Find every top-level Applet section, e.g. "[Containments][2][Applets][36]",
# and check its plugin= line for the Start-button widget (the plugin id
# varies: Kickoff, Kicker, or SimpleMenu depending on distro/version).
# Matching on plugin= is what actually identifies the right applet —
# section headers are just numeric IDs, they never contain the word
# "kickoff" themselves.
applet_re = re.compile(r'^\[Containments\]\[\d+\]\[Applets\]\[\d+\]$')
targets = []
i = 0
while i < len(lines):
    line = lines[i].rstrip('\n')
    if applet_re.match(line):
        prefix = line
        j = i + 1
        plugin = None
        while j < len(lines) and not lines[j].startswith('['):
            m = re.match(r'^plugin=(.*)$', lines[j].rstrip('\n'))
            if m:
                plugin = m.group(1)
            j += 1
        if plugin in (
            'org.kde.plasma.kickoff',
            'org.kde.plasma.kicker',
            'org.kde.plasma.simplemenu',
        ):
            targets.append(prefix)
        i = j
    else:
        i += 1

for prefix in targets:
    target_header = f'{prefix}[Configuration][General]\n'
    idx = lines.index(target_header) if target_header in lines else None

    if idx is not None:
        j = idx + 1
        replaced = False
        while j < len(lines) and not lines[j].startswith('['):
            if lines[j].startswith('icon='):
                lines[j] = f'icon={icon}\n'
                replaced = True
                break
            j += 1
        if not replaced:
            lines.insert(idx + 1, f'icon={icon}\n')
    else:
        lines.append(target_header)
        lines.append(f'icon={icon}\n')

# Default panel height: 44. Panel containments are top-level
# "[Containments][N]" sections (no [Applets] in the path) whose own
# plugin= line is org.kde.panel — the height itself lives in that same
# containment's own "[Containments][N][General]" group.
panel_re = re.compile(r'^\[Containments\]\[\d+\]$')
panel_targets = []
i = 0
while i < len(lines):
    line = lines[i].rstrip('\n')
    if panel_re.match(line):
        prefix = line
        j = i + 1
        plugin = None
        while j < len(lines) and not lines[j].startswith('['):
            m = re.match(r'^plugin=(.*)$', lines[j].rstrip('\n'))
            if m:
                plugin = m.group(1)
            j += 1
        if plugin == 'org.kde.panel':
            panel_targets.append(prefix)
        i = j
    else:
        i += 1

for prefix in panel_targets:
    target_header = f'{prefix}[General]\n'
    idx = lines.index(target_header) if target_header in lines else None

    if idx is not None:
        j = idx + 1
        replaced = False
        while j < len(lines) and not lines[j].startswith('['):
            if lines[j].startswith('height='):
                lines[j] = 'height=44\n'
                replaced = True
                break
            j += 1
        if not replaced:
            lines.insert(idx + 1, 'height=44\n')
    else:
        lines.append(target_header)
        lines.append('height=44\n')

with open(path, 'w') as f:
    f.writelines(lines)
PYEOF
fi
echo -e "${GREEN}  ✓ Done${NC}"

kstart5 plasmashell >/dev/null 2>&1 &
kstart6 plasmashell >/dev/null 2>&1 &

# Re-apply the Plasma Style (panel/Kickoff chrome background) again
# now that plasmashell has actually restarted — writing plasmarc
# before the restart wasn't reliably enough to make an already-running
# panel repaint with the new background, so do it again live once the
# new process is up.
( sleep 2
  plasma-apply-desktoptheme "$PLASMA_STYLE" 2>/dev/null
  kwriteconfig5 --file plasmarc --group Theme --key name "$PLASMA_STYLE"
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.refreshCurrentShell 2>/dev/null || true
) &

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ORIZON theme applied successfully!  ✓  ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
