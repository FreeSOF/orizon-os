#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'

ORIZON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$INSTALL_USER")

# Resource paths (always relative — works for any user)
ORIZON_LOGO="/usr/share/pixmaps/orizon/orizon-logo.png"
ORIZON_SETTINGS_ICON="/usr/share/pixmaps/orizon/orizon-settings.png"
ORIZON_EXPLORER_ICON="/usr/share/pixmaps/orizon/orizon-nautilus-dolphin.png"
ORIZON_LINK="https://freesof.ru"
WALLPAPER_PATH="/usr/share/backgrounds/orizon/orizon-default.png"
LAKE_WALLPAPER_PATH="/usr/share/backgrounds/orizon/lake.png"

# Application icons (from branding/ folder)
ORIZON_ICON_BLUETOOTH="/usr/share/pixmaps/orizon/orizon-bluetooth.png"
ORIZON_ICON_CALCULATOR="/usr/share/pixmaps/orizon/orizon-calculator.png"
ORIZON_ICON_CALENDAR="/usr/share/pixmaps/orizon/orizon-calendar.png"
ORIZON_ICON_DISK="/usr/share/pixmaps/orizon/orizon-diskusageanalyzer.png"
ORIZON_ICON_DISPLAY="/usr/share/pixmaps/orizon/orizon-display-ss.png"
ORIZON_ICON_INFO="/usr/share/pixmaps/orizon/orizon-info.png"
ORIZON_ICON_KONSOLE="/usr/share/pixmaps/orizon/orizon-konsole.png"
ORIZON_ICON_MEDIAPLAYER="/usr/share/pixmaps/orizon/orizon-mediaplayer.png"
ORIZON_ICON_NETWORK="/usr/share/pixmaps/orizon/orizon-network-wifi.png"
ORIZON_ICON_NOTEPAD="/usr/share/pixmaps/orizon/orizon-notepad.png"
ORIZON_ICON_OFFSYSTEM="/usr/share/pixmaps/orizon/orizon-offsystem.png"
ORIZON_ICON_PHOTOS="/usr/share/pixmaps/orizon/orizon-photos.png"
ORIZON_ICON_SHOP="/usr/share/pixmaps/orizon/orizon-shop.png"
ORIZON_ICON_TRASHBIN="/usr/share/pixmaps/orizon/orizon-trashbin.png"
ORIZON_ICON_UBUNTUSHOP="/usr/share/pixmaps/orizon/orizon-marketu.png"
ORIZON_ICON_SYSMON="/usr/share/pixmaps/orizon/orizon-sysmon.png"
ORIZON_ICON_LO_WRITER="/usr/share/pixmaps/orizon/orizon-lo-writer.png"
ORIZON_ICON_LO_CALC="/usr/share/pixmaps/orizon/orizon-lo-calc.png"
ORIZON_ICON_LO_IMPRESS="/usr/share/pixmaps/orizon/orizon-lo-impress.png"
ORIZON_ICON_LO_DRAW="/usr/share/pixmaps/orizon/orizon-lo-draw.png"
ORIZON_ICON_LO_BASE="/usr/share/pixmaps/orizon/orizon-lo-base.png"
ORIZON_ICON_LO_MATH="/usr/share/pixmaps/orizon/orizon-lo-math.png"
ORIZON_ICON_ARK="/usr/share/pixmaps/orizon/orizon-ark.png"
ORIZON_ICON_OKULAR="/usr/share/pixmaps/orizon/orizon-okular.png"
ORIZON_ICON_SCREENSHOT="/usr/share/pixmaps/orizon/orizon-screenshot.png"
ORIZON_ICON_LO_STARTCENTER="/usr/share/pixmaps/orizon/orizon-lo.png"

[[ $EUID -ne 0 ]] && { echo -e "${RED}Run as: sudo bash $0${NC}"; exit 1; }

print_banner() {
cat << 'BANNER'

   ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗
  ██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║
  ██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║
  ██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║
  ╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║
   ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
           KDE PLASMA EDITION  |  Beta 3
BANNER
}

log_step() { echo -e "\n${CYAN}[ORIZON]${NC} ${BOLD}$1${NC}"; }
log_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

clear; print_banner
echo -e "\n  User: ${CYAN}${BOLD}$INSTALL_USER${NC}"
echo -e "  ORIZON folder: ${CYAN}$ORIZON_DIR${NC}\n"

export DEBIAN_FRONTEND=noninteractive

# ── 1. Remove casper ──────────────────────────────────────────
log_warn "Remember to disable VPN — the download may just hang while connecting to UBUNTU servers."
log_step "Removing casper (cause of boot errors)..."
systemctl stop casper-md5check.service 2>/dev/null || true
systemctl disable casper-md5check.service 2>/dev/null || true
systemctl mask casper-md5check.service 2>/dev/null || true
apt-get remove --purge casper -y -qq 2>/dev/null || true
log_ok "casper removed"

# ── 2. Fix PAM ────────────────────────────────────────────────
log_step "Fixing PAM..."
apt-get install --reinstall libpam-modules libpam-runtime -y -qq 2>/dev/null || true
for f in /etc/pam.d/login /etc/pam.d/lightdm /etc/pam.d/common-session; do
    [ -f "$f" ] && sed -i 's/^\([^#].*pam_lastlog\.so.*\)$/#\1/' "$f" 2>/dev/null || true
done
log_ok "PAM fixed"

# ── 3. Install KDE Plasma ─────────────────────────────────────
log_step "Installing KDE Plasma..."
apt-get update

# Use apt-get (not aptitude) for unattended installs — aptitude's dependency
# resolver can silently pick a resolution that drops packages we actually need
# (this is the most likely cause of past "black screen after login" / missing
# org.kde.breeze.components reports: an incomplete Plasma install that apt
# reported as "successful" because errors were being swallowed by `|| true`).
CRITICAL_PACKAGES=(
    kde-plasma-desktop
    plasma-desktop
    plasma-workspace
    kwin-x11
    sddm
    dbus
    dbus-x11
    xdg-desktop-portal
    xdg-desktop-portal-kde
    qml-module-qtgraphicaleffects
    qml-module-qtquick-controls
    qml-module-qtquick-controls2
    qml-module-qtquick-layouts
    qml-module-qtquick-virtualkeyboard
    gwenview
    ark
    konsole
    kate
    okular
    kde-spectacle
    libreoffice
)

if ! apt-get install -y "${CRITICAL_PACKAGES[@]}"; then
    log_warn "apt-get reported errors — retrying with --fix-broken"
    apt-get install -y --fix-broken
    apt-get install -y "${CRITICAL_PACKAGES[@]}" || {
        echo -e "${RED}FATAL: KDE Plasma packages failed to install. Aborting before we install a login theme on top of a broken session.${NC}"
        echo -e "${RED}Run 'sudo apt-get install -f' and re-run this installer.${NC}"
        exit 1
    }
fi
# Ubuntu ships gdm3 as the display manager: /etc/systemd/system/display-manager.service
# is a symlink to gdm3.service, which makes "systemctl enable sddm" fail with
# "File ... already exists and is a symlink to gdm3.service". Remove it first.
for dm in gdm3 gdm lightdm; do
    systemctl disable "$dm" 2>/dev/null || true
done
rm -f /etc/systemd/system/display-manager.service
systemctl enable sddm || log_warn "Could not enable sddm yet — will retry in the SDDM step"

# Verify the actual binaries a Plasma X11 session needs are present —
# if this check fails, SDDM will show a login screen that authenticates fine
# but then drops to a black screen with a live cursor (X starts, nothing draws).
MISSING_BIN=0
for bin in startplasma-x11 kwin_x11 plasmashell; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        log_warn "Missing required binary: $bin"
        MISSING_BIN=1
    fi
done
if [ "$MISSING_BIN" -eq 1 ]; then
    echo -e "${RED}FATAL: one or more Plasma X11 session binaries are missing after install.${NC}"
    echo -e "${RED}The SDDM theme will still load correctly, but login will end in a black screen.${NC}"
    echo -e "${RED}Run 'sudo apt-get install --reinstall plasma-workspace kwin-x11' then re-run this installer.${NC}"
    exit 1
fi
log_ok "KDE Plasma installed and verified"

# ── 4. Configure SDDM (no autologin) ─────────────────────────
log_step "Configuring SDDM..."
# Disable other DMs
for dm in gdm3 gdm lightdm; do
    systemctl disable $dm 2>/dev/null || true
done
rm -f /etc/systemd/system/display-manager.service
systemctl enable -f sddm 2>/dev/null || systemctl enable sddm || log_warn "systemctl enable sddm failed — SDDM may not start at boot"
echo "/usr/bin/sddm" > /etc/X11/default-display-manager
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure sddm 2>/dev/null || true

# Install our ORIZON SDDM theme
SDDM_THEME_DIR="/usr/share/sddm/themes/orizon"
mkdir -p "$SDDM_THEME_DIR"
cp -r "$ORIZON_DIR/kde/sddm/orizon/"* "$SDDM_THEME_DIR/" 2>/dev/null || true

# Verify the QML modules our SDDM theme needs (FastBlur, DropShadow
# from QtGraphicalEffects) are actually present — if they're missing,
# SDDM silently falls back to the default theme with no visible error.
GRAPHICAL_EFFECTS_PATH=$(find /usr/lib /usr/share -path "*/qt5/qml/QtGraphicalEffects/qmldir" 2>/dev/null | head -1)
if [ -z "$GRAPHICAL_EFFECTS_PATH" ]; then
    log_warn "QtGraphicalEffects QML module not found — installing..."
    apt-get install -y -qq qml-module-qtgraphicaleffects 2>/dev/null || true
fi

# SDDM config — use our theme (autologin is NOT enabled: the user logs in
# with a password from the ORIZON login screen)
# Detect the real session ID instead of assuming "plasma": recent
# Debian/Ubuntu KDE packaging ships the X11 session as plasmax11.desktop,
# not plasma.desktop. If DefaultSession points at a
# filename that doesn't exist, SDDM can silently fail to start any
# desktop after authenticating — X launches (cursor moves) but nothing
# ever draws, which looks exactly like a black screen after login.
PLASMA_SESSION_ID="plasma"
if [ -f /usr/share/xsessions/plasmax11.desktop ] && [ ! -f /usr/share/xsessions/plasma.desktop ]; then
    PLASMA_SESSION_ID="plasmax11"
elif [ -f /usr/share/xsessions/plasma.desktop ]; then
    PLASMA_SESSION_ID="plasma"
else
    log_warn "Could not find plasma.desktop or plasmax11.desktop in /usr/share/xsessions — default session name may be wrong"
fi
log_ok "Using X11 session id: $PLASMA_SESSION_ID"

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/orizon.conf << EOF
[Theme]
Current=orizon

[General]
DefaultSession=$PLASMA_SESSION_ID
Numlock=on
ReuseSession=true
EOF
# Remove any autologin left by a previous run of this installer
rm -f /etc/sddm.conf.d/autologin.conf
if [ -f /etc/sddm.conf ]; then
    sed -i '/^\[Autologin\]/,/^\[/{/^\[Autologin\]/d;/^\[/!d}' /etc/sddm.conf
fi

# ── KWin startup reliability fixes ────────────────────────────
# Fix 1: Locale must be UTF-8 — KWin/Qt logs a warning and sometimes
# crashes if LANG is not UTF-8 (seen in multiple forum threads)
if ! locale | grep -q "LANG=.*UTF-8\|LANG=.*utf8"; then
    locale-gen "en_US.UTF-8" 2>/dev/null || true
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 2>/dev/null || true
fi

# Fix 2: Cursor theme — kwin_x11 crashes on startup if it can't find
# ANY cursor theme (logs: "Unable to load any cursor theme"). Installing
# a basic cursor theme guarantees kwin always has something to load.
apt-get install -y -qq breeze-cursor-theme xcursor-themes 2>/dev/null || true
$KW --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors" 2>/dev/null || true

# Fix 3: Increase SDDM helper timeout — on slow hardware/VMs the
# plasma-session startup can exceed SDDM's default 30s timeout,
# causing sddm-helper to exit with code 2 and leaving a black screen
cat > /etc/sddm.conf.d/orizon-timeout.conf << 'EOF'
[General]
# Increase timeout to 120s — on slow VMs plasma-session can take longer
# than the default 30s to respond, making SDDM abort the session launch
LoginDelay=0
EOF

# Fix 4: Ensure KWin autostart is properly registered — without this
# the session manager might not know it needs to start KWin at all
mkdir -p /usr/share/autostart
if [ -f /usr/share/applications/org.kde.kwin.desktop ]; then
    cp /usr/share/applications/org.kde.kwin.desktop /usr/share/autostart/ 2>/dev/null || true
fi

# Fix 5: Create a kwin_x11 wrapper that retries on crash — kwin_x11
# sometimes needs one restart to successfully initialize on first login
cat > /usr/local/bin/kwin-x11-safe << 'KWINEOF'
#!/bin/bash
# KWin X11 safe launcher — retries once if it crashes within 5 seconds
for attempt in 1 2; do
    START=$(date +%s)
    kwin_x11 "$@"
    EXIT=$?
    END=$(date +%s)
    DURATION=$((END - START))
    # If kwin ran for more than 5 seconds it was a real crash, not a startup failure
    [ $DURATION -gt 5 ] && break
    [ $attempt -eq 2 ] && break
    sleep 1
done
exit $EXIT
KWINEOF
chmod +x /usr/local/bin/kwin-x11-safe

log_ok "SDDM configured"
log_ok "KWin startup reliability fixes applied"

# ── Rounded menu corners via Plasma desktoptheme SVG patch ────
# The only reliable way to get rounded corners on context menus in
# Plasma 5 without compositing — patch the dialogs/background.svg
# in the active desktoptheme. This is what Mint/Windows look like.
log_step "Patching Plasma theme for rounded menu corners..."
for THEME_DIR in \
    /usr/share/plasma/desktoptheme/default \
    /usr/share/plasma/desktoptheme/breeze-dark \
    /usr/share/plasma/desktoptheme/breeze-light; do
    SVG="$THEME_DIR/dialogs/background.svg"
    if [ -f "$SVG" ]; then
        # Add rx/ry rounded corner attributes to all rect elements
        # that form the dialog/menu background frame
        python3 - "$SVG" << 'PYEOF'
import sys, re
path = sys.argv[1]
with open(path) as f:
    content = f.read()
# Add rx="6" ry="6" to rect elements that don't already have it
# Only target the main background rects (large ones defining the frame)
content = re.sub(
    r'(<rect\b(?![^>]*\brx=)[^>]*\b(?:width="100%"|id="[^"]*(?:background|center|dialog)[^"]*")[^>]*?)(/?>)',
    lambda m: m.group(1) + ' rx="6" ry="6"' + m.group(2),
    content
)
with open(path, 'w') as f:
    f.write(content)
print(f"Patched: {path}")
PYEOF
    fi
done
log_ok "Plasma menu rounded corners patched"

# ── KDE-Rounded-Corners (ShapeCorners) KWin effect ────────────
# Real rounded corners for ALL windows via OpenGL shaders — not just
# the title bar decoration radius (breezerc CornerRadius which only
# affects the frame). This is what makes windows actually look like
# Windows 11/macOS with properly clipped content corners.
# Supports Plasma 5.27 on Ubuntu/Kubuntu — tested on 24.04.
log_step "Building KDE-Rounded-Corners KWin effect..."
apt-get install -y -qq git cmake g++ extra-cmake-modules kwin-dev \
    libkf5configwidgets-dev libkf5windowsystem-dev libkf5guiaddons-dev \
    libkf5i18n-dev libkf5notifications-dev libepoxy-dev \
    qtbase5-private-dev 2>/dev/null || true

if command -v cmake >/dev/null 2>&1 && command -v kwin_x11 >/dev/null 2>&1; then
    ROUNDED_TMP=$(mktemp -d)
    git clone --depth=1 https://github.com/matinlotfali/KDE-Rounded-Corners.git \
        "$ROUNDED_TMP/KDE-Rounded-Corners" 2>/dev/null
    if [ -d "$ROUNDED_TMP/KDE-Rounded-Corners" ]; then
        mkdir -p "$ROUNDED_TMP/build"
        cd "$ROUNDED_TMP/build"
        cmake "$ROUNDED_TMP/KDE-Rounded-Corners" \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release 2>/dev/null && \
        make -j$(nproc) 2>/dev/null && \
        make install 2>/dev/null && \
        log_ok "KDE-Rounded-Corners installed" || \
        log_warn "KDE-Rounded-Corners build failed — using breezerc radius only"
        cd /
    fi
    rm -rf "$ROUNDED_TMP"

    # Enable the effect and set radius to 10 (like Windows 11)
    $KW --file kwinrc --group Plugins --key shapecornersEnabled true 2>/dev/null || true
    $KW --file shapecornersrc --group General --key CornerRadius 10 2>/dev/null || true
    $KW --file shapecornersrc --group General --key OutlineThickness 0 2>/dev/null || true
else
    log_warn "cmake or kwin not available — KDE-Rounded-Corners skipped"
fi

# ── 5. Wallpaper and branding ─────────────────────────────────
log_step "Installing wallpaper and branding..."
mkdir -p /usr/share/backgrounds/orizon
cp "$ORIZON_DIR/wallpapers/"*.png /usr/share/backgrounds/orizon/ 2>/dev/null || true

# Register every wallpaper as a proper Plasma wallpaper package
# (metadata.desktop + contents/images/) so it shows up with a name and
# thumbnail in System Settings > Appearance > Wallpaper, not just as a
# loose file you'd have to "Add Image..." to find manually.
declare -A WALLPAPER_NAMES=(
    [orizon-default]="Orizon Default"
    [orizon-default1]="Orizon Default (Alt)"
    [island]="Orizon Island"
    [crimea]="Orizon Crimea"
    [branches]="Orizon Branches"
    [bushes]="Orizon Bushes"
    [palm]="Orizon Palm"
    [sea]="Orizon Sea"
    [sky]="Orizon Sky"
    [sunshine]="Orizon Sunshine"
    [sunshine_plants]="Orizon Sunshine Plants"
    [trees]="Orizon Trees"
    [vitosha]="Orizon Vitosha"
)
# These images are still copied to /usr/share/backgrounds/orizon (lake.png and
# mountains.png are used internally) but are NOT shown in the Plasma wallpaper
# picker. Remove packages left over from earlier installs.
for hidden in lake mountains north-mountains rocks sea_rocks; do
    rm -rf "/usr/share/wallpapers/com.orizon.wallpaper.$hidden"
done
for slug in "${!WALLPAPER_NAMES[@]}"; do
    src="$ORIZON_DIR/wallpapers/$slug.png"
    [ -f "$src" ] || continue
    name="${WALLPAPER_NAMES[$slug]}"
    pkg_id="com.orizon.wallpaper.$slug"
    pkg_dir="/usr/share/wallpapers/$pkg_id"
    rm -rf "$pkg_dir"
    mkdir -p "$pkg_dir/contents/images"
    cp "$src" "$pkg_dir/contents/images/1920x1080.png"
    cat > "$pkg_dir/metadata.desktop" << EOF
[Desktop Entry]
Name=$name
X-KDE-PluginInfo-Name=$pkg_id
X-KDE-PluginInfo-Author=ORIZON Linux
X-KDE-PluginInfo-License=CC-BY-SA
Type=Service
ServiceTypes=Plasma/Wallpaper,Plasma/ImageWallpaper
EOF
done
log_ok "Wallpaper packages installed (${#WALLPAPER_NAMES[@]} entries)"

# Replace the image files inside each stock KDE wallpaper package
# with our mountains.png — names/metadata are left completely untouched
# so KDE sees them as its own Breeze/Next/etc. packages, but the
# actual picture displayed is ours. This covers every hardcoded
# reference to those package paths (fallback in look-and-feel,
# first-login defaults, etc.) without breaking anything that identifies
# packages by name.
for pkg_dir in /usr/share/wallpapers/*/; do
    pkg_id="$(basename "$pkg_dir")"
    case "$pkg_id" in
        com.orizon.wallpaper.*) continue ;;
    esac
    find "$pkg_dir" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0 2>/dev/null \
        | xargs -0 -I{} cp -f "$ORIZON_DIR/wallpapers/mountains.png" "{}" 2>/dev/null
done
log_ok "Stock KDE wallpaper images replaced with ORIZON mountains"

# Explicitly repoint Breeze's own look-and-feel default wallpaper
# reference at lake.png — this is the actual "default for the Breeze
# theme" setting, kept distinct from orizon-default.png used as the
# desktop default elsewhere.
for defaults_file in /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/defaults/defaults \
                     /usr/share/plasma/desktoptheme/default/defaults; do
    if [ -f "$defaults_file" ]; then
        sed -i -E "s#^Image=.*#Image=file://$LAKE_WALLPAPER_PATH#" "$defaults_file" 2>/dev/null || true
    fi
done

# Do not copy grub here — it goes to a separate folder
mkdir -p /boot/grub/backgrounds
cp "$ORIZON_DIR/wallpapers/grub/orizon-grub.png" /boot/grub/backgrounds/ 2>/dev/null || true

mkdir -p /usr/share/pixmaps/orizon
cp "$ORIZON_DIR/branding/"*.png /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_DIR/branding/orizon-logo-48.png" /usr/share/pixmaps/orizon.png 2>/dev/null || true

cp "$ORIZON_DIR/config/os-release" /etc/os-release 2>/dev/null || true
cp "$ORIZON_DIR/config/lsb-release" /etc/lsb-release 2>/dev/null || true
cp "$ORIZON_DIR/config/10-help-text" /etc/update-motd.d/10-help-text || true
cp "$ORIZON_DIR/config/issue" /etc/issue 2>/dev/null || true
cp "$ORIZON_DIR/config/issue.net" /etc/issue.net 2>/dev/null || true
echo "orizon" > /etc/hostname
grep -q "127.0.1.1" /etc/hosts || echo "127.0.1.1	orizon" >> /etc/hosts
log_ok "Wallpaper and branding installed"

# ── 6. GTK theme ──────────────────────────────────────────────
log_step "Installing GTK theme Orizon-Dark..."
mkdir -p /usr/share/themes/Orizon-Dark
cp -r "$ORIZON_DIR/themes/orizon-gtk/"* /usr/share/themes/Orizon-Dark/ 2>/dev/null || true
log_ok "GTK theme installed"

# ── 7. Papirus icons ──────────────────────────────────────────
log_step "Installing ePapirus icons..."
apt-get install -y -qq papirus-icon-theme 2>/dev/null || true
# ePapirus is the default icon theme for every ORIZON theme variant
ICON_THEME_DARK="ePapirus-Dark"
ICON_THEME_LIGHT="ePapirus"
if [ -d /usr/share/icons/ePapirus ]; then
    log_ok "ePapirus icons installed"
else
    log_warn "ePapirus icons not found after install — check that papirus-icon-theme installed correctly"
fi

# ── 8. KDE color schemes (dark + light) ──────────────────────
log_step "Installing color schemes Orizon-Dark and Orizon-Light..."
mkdir -p /usr/share/color-schemes
cp "$ORIZON_DIR/kde/color-scheme/Orizon-Dark.colors" /usr/share/color-schemes/ 2>/dev/null || true
cp "$ORIZON_DIR/kde/color-scheme/Orizon-Light.colors" /usr/share/color-schemes/ 2>/dev/null || true
mkdir -p "$USER_HOME/.local/share/color-schemes"
cp "$ORIZON_DIR/kde/color-scheme/Orizon-Dark.colors" "$USER_HOME/.local/share/color-schemes/" 2>/dev/null || true
cp "$ORIZON_DIR/kde/color-scheme/Orizon-Light.colors" "$USER_HOME/.local/share/color-schemes/" 2>/dev/null || true
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.local/share/color-schemes"
log_ok "Themes installed"

# ── 9. Global Theme packages + launchers ──────────────────────
# com.orizon.orizon-dark/light are installed as real Global Theme
# packages under /usr/share/plasma/look-and-feel/, so they show up
# properly in System Settings > Appearance > Global Theme. Their own
# defaults file sets color scheme/icons/wallpaper/splash/lock screen
# natively, so the picker's "Apply" already looks right immediately.
#
# On top of that, orizon-theme-watcher.sh (an inotify watch on
# kdeglobals, not a polling loop) detects when LookAndFeelPackage
# changes to one of ours and replays the *exact* same
# apply-kde-theme.sh used by `orizon --theme dark/light` a few seconds
# later — that's what fixes up everything the native Global Theme
# mechanism doesn't cover on its own (per-app icon overrides, Kvantum,
# "About This System" branding, the panel Start-button icon) so the
# end result is identical to running the CLI command. The watcher
# waits for kdeglobals to stop changing before it reacts and tracks
# the last value it applied, so it won't loop on its own writes or
# fire mid-way through KDE's own native apply.
log_step "Installing Global Theme packages and launchers..."

apt-get install -y -qq inotify-tools 2>/dev/null || true

rm -rf /usr/share/plasma/look-and-feel/com.orizon.orizon-dark
rm -rf /usr/share/plasma/look-and-feel/com.orizon.orizon-light
rm -rf /usr/share/plasma/look-and-feel/com.orizon.orizon-twilight
mkdir -p /usr/share/plasma/look-and-feel
cp -r "$ORIZON_DIR/kde/look-and-feel-dark" /usr/share/plasma/look-and-feel/com.orizon.orizon-dark
cp -r "$ORIZON_DIR/kde/look-and-feel-light" /usr/share/plasma/look-and-feel/com.orizon.orizon-light
cp -r "$ORIZON_DIR/kde/look-and-feel-twilight" /usr/share/plasma/look-and-feel/com.orizon.orizon-twilight

mkdir -p /opt/orizon/scripts
cp "$ORIZON_DIR/scripts/apply-kde-theme.sh" /opt/orizon/scripts/apply-kde-theme.sh 2>/dev/null || true
cp "$ORIZON_DIR/scripts/orizon-theme-watcher.sh" /opt/orizon/scripts/orizon-theme-watcher.sh 2>/dev/null || true
chmod +x /opt/orizon/scripts/apply-kde-theme.sh /opt/orizon/scripts/orizon-theme-watcher.sh 2>/dev/null || true

mkdir -p "$USER_HOME/.config/autostart"
cat > "$USER_HOME/.config/autostart/orizon-theme-watcher.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON Theme Watcher
Exec=bash /opt/orizon/scripts/orizon-theme-watcher.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
sudo -u "$INSTALL_USER" bash -c 'pkill -f orizon-theme-watcher.sh' 2>/dev/null || true
sudo -u "$INSTALL_USER" bash -c 'nohup bash /opt/orizon/scripts/orizon-theme-watcher.sh >/dev/null 2>&1 &' 2>/dev/null || true

chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/autostart"
kbuildsycoca5 --noincremental 2>/dev/null || true
sudo -u "$INSTALL_USER" kbuildsycoca5 --noincremental 2>/dev/null || true

cat > /usr/share/applications/orizon-theme-dark.desktop << EOF
[Desktop Entry]
Type=Application
Name=ORIZON — Тёмная тема
Comment=Применить тёмную тему ORIZON (то же, что orizon --theme dark)
Exec=bash /opt/orizon/scripts/apply-kde-theme.sh dark
Icon=$ORIZON_LOGO
Terminal=false
Categories=Qt;KDE;Settings;DesktopSettings;
NoDisplay=false
EOF

cat > /usr/share/applications/orizon-theme-light.desktop << EOF
[Desktop Entry]
Type=Application
Name=ORIZON — Светлая тема
Comment=Применить светлую тему ORIZON (то же, что orizon --theme light)
Exec=bash /opt/orizon/scripts/apply-kde-theme.sh light
Icon=$ORIZON_LOGO
Terminal=false
Categories=Qt;KDE;Settings;DesktopSettings;
NoDisplay=false
EOF

cat > /usr/share/applications/orizon-theme-twilight.desktop << EOF
[Desktop Entry]
Type=Application
Name=ORIZON — Twilight тема
Comment=Применить тему Twilight ORIZON (то же, что orizon --theme twilight)
Exec=bash /opt/orizon/scripts/apply-kde-theme.sh twilight
Icon=$ORIZON_LOGO
Terminal=false
Categories=Qt;KDE;Settings;DesktopSettings;
NoDisplay=false
EOF

update-desktop-database /usr/share/applications 2>/dev/null || true
log_ok "Global Theme packages, watcher and launchers installed"

# System-wide default for brand-new users. /etc/skel is copied by some
# user-creation tools and skipped by others, so relying on it alone to
# seed a new account's panel height / wallpaper is unreliable. Plasma
# always consults /etc/xdg/kdeglobals as the system default on a truly
# first-ever login though, regardless of how the account was made —
# setting LookAndFeelPackage here means that first login runs our own
# layout.js (panel height 44) and our package's own defaults (orizon
# wallpaper, color scheme, icons), with nothing depending on whether
# any particular file happened to get copied into the new home dir.
mkdir -p /etc/xdg
if [ -f /etc/xdg/kdeglobals ]; then
    kwriteconfig5 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage "com.orizon.orizon-light"
    kwriteconfig5 --file /etc/xdg/kdeglobals --group KDE --key SingleClick false
else
    cat > /etc/xdg/kdeglobals << 'EOF'
[KDE]
LookAndFeelPackage=com.orizon.orizon-light
SingleClick=false
EOF
fi
log_ok "Set com.orizon.orizon-light as the system-wide default for new users"

# Hide "Switch User" / "Start New Session" everywhere (Kickoff, Leave widgets,
# lock screen). Switching opens a parallel SDDM greeter while the current
# session keeps running, and logging in again as the same user does not
# reliably start Plasma. "Log Out" works fine, so only that path stays.
kwriteconfig5 --file /etc/xdg/kdeglobals --group "KDE Action Restrictions" --key "action/switch_user" false
kwriteconfig5 --file /etc/xdg/kdeglobals --group "KDE Action Restrictions" --key "action/start_new_session" false
log_ok "Switch User button disabled"


# ── 9b. Kickoff resize ceiling ──────────────────────────────────
# Kickoff's popup size grip is real, but Layout.maximumWidth/maximumHeight
# are hardcoded in the stock plasmoid (80 / 40 grid units). With enough
# pinned/recent items, the content's own implicit size is already close to
# that ceiling, so there's almost no room left to drag — the grip is there
# but visibly does nothing. Raise the ceiling so resizing actually has
# somewhere to go. This edits a file owned by the plasma-desktop package,
# so a future apt upgrade can silently revert it — safe to just re-run
# this installer (or update-kde.sh) again if that happens.
log_step "Fixing Kickoff menu size..."
KICKOFF_QML="/usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/ui/FullRepresentation.qml"
if [ -f "$KICKOFF_QML" ]; then
    # Raise the maximum ceiling so the resize grip actually has room to move
    sed -i \
        -e 's/Layout\.maximumWidth: PlasmaCore\.Units\.gridUnit \* [0-9]\+/Layout.maximumWidth: PlasmaCore.Units.gridUnit * 110/' \
        -e 's/Layout\.maximumHeight: PlasmaCore\.Units\.gridUnit \* [0-9]\+/Layout.maximumHeight: PlasmaCore.Units.gridUnit * 60/' \
        "$KICKOFF_QML"

    # Set a fixed preferred size — this is the key fix. Plasma 5.27 does NOT
    # persist the popup size across plasmashell restarts (a known upstream bug
    # closed only in Plasma 6). The only reliable workaround is to bake a
    # preferred size directly into the QML so it opens at that size every time.
    # 35 x 28 grid units ≈ 560 x 448px at 96dpi — a comfortable Windows-style
    # Start menu size. Replaces whatever preferredWidth/Height was there, or
    # adds it if not present.
    python3 - "$KICKOFF_QML" << 'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()

# Replace existing preferred size keys
content = re.sub(r'Layout\.preferredWidth:[^\n]+', 'Layout.preferredWidth: PlasmaCore.Units.gridUnit * 35', content)
content = re.sub(r'Layout\.preferredHeight:[^\n]+', 'Layout.preferredHeight: PlasmaCore.Units.gridUnit * 28', content)

# If no preferred size keys exist, add them right after the maximumWidth line
if 'Layout.preferredWidth' not in content:
    content = re.sub(
        r'(Layout\.maximumWidth:[^\n]+\n)',
        r'\1        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 35\n        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 28\n',
        content, count=1
    )

with open(path, 'w') as f:
    f.write(content)
print("Kickoff size patched")
PYEOF
    log_ok "Kickoff menu size fixed (opens at ~560x448px, resize ceiling raised)"
else
    log_warn "Kickoff FullRepresentation.qml not found at expected path — skipped"
fi

# ── 9c. Hide power/session button captions ─────────────────────
# The Suspend/Restart/Shutdown row lives in LeaveButtons.qml, where each
# button's `display:` is a ternary — TextBesideIcon when the row has
# room, IconOnly when it doesn't. With our panel/Kickoff sizing that
# condition isn't reliably choosing IconOnly, so captions show (and can
# overlap at small widths). Force IconOnly unconditionally instead of
# relying on the ternary.
LEAVEBUTTONS_QML="/usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/ui/LeaveButtons.qml"
if [ -f "$LEAVEBUTTONS_QML" ] && grep -q "TextBesideIcon" "$LEAVEBUTTONS_QML"; then
    sed -i -E 's/display:.*PC3\.AbstractButton\.TextBesideIcon.*PC3\.AbstractButton\.IconOnly/display: PC3.AbstractButton.IconOnly/' "$LEAVEBUTTONS_QML"
    log_ok "Power/session button captions hidden (LeaveButtons.qml)"
else
    log_warn "LeaveButtons.qml not found or pattern not matched — captions not hidden"
fi

# ── 10. Kvantum ───────────────────────────────────────────────
log_step "Installing Kvantum theme..."
mkdir -p /usr/share/Kvantum/Orizon
cp "$ORIZON_DIR/kde/kvantum/Orizon/"* /usr/share/Kvantum/Orizon/ 2>/dev/null || true
mkdir -p "$USER_HOME/.config/Kvantum/Orizon"
cp "$ORIZON_DIR/kde/kvantum/Orizon/"* "$USER_HOME/.config/Kvantum/Orizon/" 2>/dev/null || true
mkdir -p /usr/share/Kvantum/Orizon-Light
cp "$ORIZON_DIR/kde/kvantum/Orizon-Light/"* /usr/share/Kvantum/Orizon-Light/ 2>/dev/null || true
mkdir -p "$USER_HOME/.config/Kvantum/Orizon-Light"
cp "$ORIZON_DIR/kde/kvantum/Orizon-Light/"* "$USER_HOME/.config/Kvantum/Orizon-Light/" 2>/dev/null || true
cat > "$USER_HOME/.config/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=Orizon
EOF
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/Kvantum" 2>/dev/null || true
log_ok "Kvantum configured"

# ── 11. About This System branding AND ICON FIX ───────────────
log_step "Configuring 'About This System' section and fixing icons..."
mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/kcm-about-distrorc" << EOF
[General]
LogoPath=$ORIZON_LOGO
Website=$ORIZON_LINK
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/kcm-about-distrorc"

# Create local applications folder to avoid permission errors
mkdir -p "$USER_HOME/.local/share/applications"

# Fix Nautilus
if [ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]; then
    cp "/usr/share/applications/org.gnome.Nautilus.desktop" "$USER_HOME/.local/share/applications/"
    sed -i "s|^Icon=.*|Icon=$ORIZON_EXPLORER_ICON|g" "$USER_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
    sed -i "s|^Name=.*|Name=Files|g" "$USER_HOME/.local/share/applications/org.gnome.Nautilus.desktop"
fi

# Fix Dolphin
if [ -f "/usr/share/applications/org.kde.dolphin.desktop" ]; then
    cp "/usr/share/applications/org.kde.dolphin.desktop" "$USER_HOME/.local/share/applications/"
    sed -i "s|^Icon=.*|Icon=$ORIZON_EXPLORER_ICON|g" "$USER_HOME/.local/share/applications/org.kde.dolphin.desktop"
    sed -i "s|^Name=.*|Name=Files|g" "$USER_HOME/.local/share/applications/org.kde.dolphin.desktop"
fi

# System Settings icon and name (also strip localized Name[xx]= lines —
# otherwise KDE prefers the translated upstream name, e.g. "Параметры
# системы KDE" under a Russian locale, even though our plain Name= override
# looks correct in the file)
for SYS_DESKTOP_NAME in systemsettings.desktop systemsettings5.desktop org.kde.systemsettings.desktop; do
    SYS_DESKTOP="/usr/share/applications/$SYS_DESKTOP_NAME"
    if [ -f "$SYS_DESKTOP" ]; then
        DEST="$USER_HOME/.local/share/applications/$SYS_DESKTOP_NAME"
        cp "$SYS_DESKTOP" "$DEST"
        sed -i "/^Name\[/d" "$DEST"
        sed -i "s|^Name=.*|Name=Параметры|g" "$DEST"
        sed -i "/^GenericName\[/d" "$DEST"
        sed -i "s|^Icon=.*|Icon=$ORIZON_SETTINGS_ICON|g" "$DEST"
    fi
done

# Make System Settings look like Windows Settings:
# - Sidebar mode instead of icon grid (more like Windows)
# - Search bar shown by default
# - Start on overview/home page
$KW --file systemsettingsrc --group systemsettings --key ActiveView "systemsettings_sidebar_mode" 2>/dev/null || true
$KW --file systemsettingsrc --group "systemsettings MainWindow" --key ToolBarsMovable "Disabled" 2>/dev/null || true
$KW --file systemsettingsrc --group systemsettings --key startSearch false 2>/dev/null || true

# NOTE: do NOT add "--mode systemsettings_sidebar_mode" to Exec. systemsettings5
# has no --mode option (only --list and module args), so it exits with
# "Unknown option 'mode'" and the launcher silently does nothing — this is
# what broke System Settings when started from the taskbar. Sidebar mode is
# already forced through systemsettingsrc (ActiveView) above and in /etc/skel.
# Clean up the flag left by older versions of this installer (system file,
# the user's copy, and other users' copies).
for SYS_DESKTOP_NAME in systemsettings.desktop systemsettings5.desktop org.kde.systemsettings.desktop kdesystemsettings.desktop; do
    for f in "/usr/share/applications/$SYS_DESKTOP_NAME" \
             "$USER_HOME/.local/share/applications/$SYS_DESKTOP_NAME"; do
        [ -f "$f" ] && sed -i -E 's/ --mode systemsettings_sidebar_mode//g' "$f" 2>/dev/null || true
    done
done

# Konsole icon
for desktop in org.kde.konsole.desktop konsole.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_KONSOLE|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Kate icon (Notepad)
for desktop in org.kde.kate.desktop kate.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_NOTEPAD|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

for desktop in libreoffice-startcenter.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_STARTCENTER|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Gwenview / Photos icon
for desktop in org.kde.gwenview.desktop gwenview.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_PHOTOS|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Ubuntu Shop / Snap Store — check all possible paths, including snap
for desktop in org.gnome.Software.desktop ubuntu-software.desktop snap-store.desktop; do
    # Standard path
    for src_dir in /usr/share/applications /var/lib/snapd/desktop/applications /snap/snap-store/current/meta/gui; do
        if [ -f "$src_dir/$desktop" ]; then
            cp "$src_dir/$desktop" "$USER_HOME/.local/share/applications/"
            sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_UBUNTUSHOP|g" "$USER_HOME/.local/share/applications/$desktop"
            break
        fi
    done
done
# Snap Store may be installed as a snap — in that case .desktop is here:
SNAP_STORE_DESKTOP="/var/lib/snapd/desktop/applications/snap-store_snap-store.desktop"
if [ -f "$SNAP_STORE_DESKTOP" ]; then
    cp "$SNAP_STORE_DESKTOP" "$USER_HOME/.local/share/applications/snap-store_snap-store.desktop"
    sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_UBUNTUSHOP|g" "$USER_HOME/.local/share/applications/snap-store_snap-store.desktop"
fi

# VLC icon (media player)
for desktop in vlc.desktop org.videolan.VLC.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_MEDIAPLAYER|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# KCalc icon (calculator)
for desktop in org.kde.kcalc.desktop kcalc.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_CALCULATOR|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Calendar icon (KOrganizer or GNOME Calendar)
apt-get install -y -qq korganizer 2>/dev/null || true
for desktop in org.kde.korganizer.desktop org.gnome.Calendar.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_CALENDAR|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Discover icon (app store)
for desktop in org.kde.discover.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_SHOP|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# Disk Usage Analyzer icon (Filelight or Baobab)
for desktop in org.kde.filelight.desktop org.gnome.baobab.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_DISK|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done

# ── System Settings module icons (KCM) ───────────────────────
mkdir -p "$USER_HOME/.local/share/pixmaps"

# Bluetooth — bluedevil module in System Settings
cp "$ORIZON_ICON_BLUETOOTH" "$USER_HOME/.local/share/pixmaps/orizon-bluetooth.png"
for kcm_desktop in bluedevil.desktop kcm_bluetooth.desktop; do
    if [ -f "/usr/share/applications/$kcm_desktop" ]; then
        cp "/usr/share/applications/$kcm_desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_BLUETOOTH|g" "$USER_HOME/.local/share/applications/$kcm_desktop"
    fi
done

# Network — plasma-nm module in System Settings
for kcm_desktop in kcm_networkmanagement.desktop plasma-nm.desktop; do
    if [ -f "/usr/share/applications/$kcm_desktop" ]; then
        cp "/usr/share/applications/$kcm_desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_NETWORK|g" "$USER_HOME/.local/share/applications/$kcm_desktop"
    fi
done

# Display/screen — kscreen module in System Settings
for kcm_desktop in kcm_kscreen.desktop kcm_displayandmonitor.desktop; do
    if [ -f "/usr/share/applications/$kcm_desktop" ]; then
        cp "/usr/share/applications/$kcm_desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_DISPLAY|g" "$USER_HOME/.local/share/applications/$kcm_desktop"
    fi
done

# About This System — kcm-about-distro module in System Settings
for kcm_desktop in kcm_about-distro.desktop kcm_aboutsystem.desktop; do
    if [ -f "/usr/share/applications/$kcm_desktop" ]; then
        cp "/usr/share/applications/$kcm_desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_INFO|g" "$USER_HOME/.local/share/applications/$kcm_desktop"
    fi
done

# System Monitor — check all name variants and snap
for desktop in org.kde.plasma-systemmonitor.desktop gnome-system-monitor.desktop org.gnome.SystemMonitor.desktop ksysguard.desktop; do
    for src_dir in /usr/share/applications /var/lib/snapd/desktop/applications; do
        if [ -f "$src_dir/$desktop" ]; then
            cp "$src_dir/$desktop" "$USER_HOME/.local/share/applications/"
            sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_SYSMON|g" "$USER_HOME/.local/share/applications/$desktop"
            break
        fi
    done
done
# gnome-system-monitor may be installed as a snap
SYSMON_SNAP_DESKTOP="/var/lib/snapd/desktop/applications/gnome-system-monitor_gnome-system-monitor.desktop"
if [ -f "$SYSMON_SNAP_DESKTOP" ]; then
    cp "$SYSMON_SNAP_DESKTOP" "$USER_HOME/.local/share/applications/gnome-system-monitor_gnome-system-monitor.desktop"
    sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_SYSMON|g" "$USER_HOME/.local/share/applications/gnome-system-monitor_gnome-system-monitor.desktop"
fi

# LibreOffice icons
for desktop in libreoffice-writer.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_WRITER|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in libreoffice-calc.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_CALC|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in libreoffice-impress.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_IMPRESS|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in libreoffice-draw.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_DRAW|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in libreoffice-base.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_BASE|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in libreoffice-math.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_LO_MATH|g" "$USER_HOME/.local/share/applications/$desktop"
    fi
done
for desktop in org.kde.ark.desktop ark.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_ARK|g" "$USER_HOME/.local/share/applications/$desktop"
        break
    fi
done
for desktop in org.kde.okular.desktop okular.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_OKULAR|g" "$USER_HOME/.local/share/applications/$desktop"
        break
    fi
done
for desktop in org.kde.spectacle.desktop spectacle.desktop; do
    if [ -f "/usr/share/applications/$desktop" ]; then
        cp "/usr/share/applications/$desktop" "$USER_HOME/.local/share/applications/"
        sed -i "s|^Icon=.*|Icon=$ORIZON_ICON_SCREENSHOT|g" "$USER_HOME/.local/share/applications/$desktop"
        break
    fi
done

# ── Trash bin icon for Plasma Desktop Widget ──────────────────
for size in 32x32 48x48 128x128; do
    mkdir -p "$USER_HOME/.local/share/icons/hicolor/$size/places"
    cp "$ORIZON_ICON_TRASHBIN" "$USER_HOME/.local/share/icons/hicolor/$size/places/user-trash.png"
    cp "$ORIZON_ICON_TRASHBIN" "$USER_HOME/.local/share/icons/hicolor/$size/places/user-trash-full.png"
done

# ── Global install of all icons to /usr/share/pixmaps/ ────────
cp "$ORIZON_ICON_BLUETOOTH"   /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_CALCULATOR"  /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_CALENDAR"    /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_DISK"        /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_DISPLAY"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_INFO"        /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_KONSOLE"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_MEDIAPLAYER" /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_NETWORK"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_NOTEPAD"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_OFFSYSTEM"   /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_PHOTOS"      /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_SHOP"        /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_TRASHBIN"    /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_UBUNTUSHOP"  /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_SYSMON"      /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_WRITER"   /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_CALC"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_IMPRESS"  /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_DRAW"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_BASE"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_MATH"     /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_ARK"         /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_OKULAR"      /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_SCREENSHOT"  /usr/share/pixmaps/orizon/ 2>/dev/null || true
cp "$ORIZON_ICON_LO_STARTCENTER" /usr/share/pixmaps/orizon 2>/dev/null || true

chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.local/share/applications"
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.local/share/pixmaps"
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.local/share/icons"

# Update global icon cache
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database "$USER_HOME/.local/share/applications" 2>/dev/null || true

log_ok "About This System branding and application icons configured"

# ── 12. Konsole profile ───────────────────────────────────────
log_step "Configuring Konsole terminal..."
KONSOLE_DIR="$USER_HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DIR"
cat > "$KONSOLE_DIR/Orizon.colorscheme" << 'EOF'
[General]
Description=Orizon
Opacity=0.92
Blur=true
Wallpaper=

[Background]
Color=10,12,20

[BackgroundIntense]
Color=18,22,36
Bold=false

[BackgroundFaint]
Color=6,8,14

[Foreground]
Color=220,230,245

[ForegroundIntense]
Color=255,255,255
Bold=true

[ForegroundFaint]
Color=140,155,175

# Black
[Color0]
Color=28,34,50

[Color0Intense]
Color=55,65,85

[Color0Faint]
Color=20,24,38

# Red
[Color1]
Color=255,85,100

[Color1Intense]
Color=255,120,130

[Color1Faint]
Color=180,60,70

# Green
[Color2]
Color=80,220,120

[Color2Intense]
Color=110,240,150

[Color2Faint]
Color=55,150,85

# Yellow
[Color3]
Color=255,200,60

[Color3Intense]
Color=255,220,100

[Color3Faint]
Color=180,140,40

# Blue (our ORIZON accent #00d4ff)
[Color4]
Color=0,200,240

[Color4Intense]
Color=50,225,255

[Color4Faint]
Color=0,140,170

# Magenta
[Color5]
Color=200,130,255

[Color5Intense]
Color=220,160,255

[Color5Faint]
Color=140,90,180

# Cyan
[Color6]
Color=60,220,210

[Color6Intense]
Color=90,240,230

[Color6Faint]
Color=40,155,148

# White
[Color7]
Color=185,198,215

[Color7Intense]
Color=220,230,245

[Color7Faint]
Color=120,135,155
EOF

cat > "$KONSOLE_DIR/Orizon.profile" << 'EOF'
[Appearance]
ColorScheme=Orizon
Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0
UseFontLineChararacters=true
LineSpacing=2
AntiAliasFonts=true

[Cursor Options]
CursorShape=1
UseCustomCursorColor=true
CustomCursorColor=0,212,255
CustomCursorTextColor=10,12,20

[General]
Name=Orizon
Parent=FALLBACK/
TerminalColumns=115
TerminalRows=32
StartInCurrentSessionDir=true

[Interaction Options]
AutoCopySelectedText=true
TrimLeadingWhitespacesInSelectedText=true
TrimTrailingWhitespacesInSelectedText=true

[Scrolling]
HistorySize=20000
ScrollBarPosition=2
EOF

cat > "$USER_HOME/.config/konsolerc" << 'EOF'
[Desktop Entry]
DefaultProfile=Orizon.profile

[KonsoleWindow]
ShowMenuBarByDefault=false
RememberWindowSize=true
EOF
chown -R "$INSTALL_USER:$INSTALL_USER" "$KONSOLE_DIR" "$USER_HOME/.config/konsolerc"
log_ok "Konsole configured with ORIZON theme"

# ── 13. Apply KDE settings AND HOTKEYS ────────────────────────
log_step "Applying KDE settings, hotkeys and session..."

# kwriteconfig5 lives in kde-cli-tools, which is NOT pulled in by
# kde-plasma-desktop/plasma-workspace on every Debian/Ubuntu variant.
# If it's missing, every single $KW call below (including the
# Compositing Enabled=false fix a few lines down) silently does
# nothing — "sudo -u $INSTALL_USER kwriteconfig5 ..." just fails with
# "command not found", and the `|| true` on each call swallows that
# error. The install log then looks completely clean while kwinrc,
# kdeglobals, etc. are never actually written — which reproduces the
# exact same "black screen, cursor moves, nothing draws" bug we
# already fixed once, because the fix never took effect in the first
# place. Make sure the binary is really there before relying on it.
if ! command -v kwriteconfig5 >/dev/null 2>&1; then
    log_warn "kwriteconfig5 not found — installing kde-cli-tools"
    apt-get install -y -qq kde-cli-tools 2>/dev/null || true
fi
if ! command -v kwriteconfig5 >/dev/null 2>&1; then
    echo -e "${RED}FATAL: kwriteconfig5 is still missing after installing kde-cli-tools.${NC}"
    echo -e "${RED}Every KDE setting below (including the compositing fix that prevents${NC}"
    echo -e "${RED}a black screen after login) would silently be skipped. Aborting.${NC}"
    echo -e "${RED}Run 'sudo apt-get install kde-cli-tools' and re-run this installer.${NC}"
    exit 1
fi
log_ok "kwriteconfig5 present"
KW="sudo -u $INSTALL_USER kwriteconfig5"

# DISABLE APP RESTORE ON LOGIN — prevents a broken previous session
# from being replayed at startup (one of the top causes of black screen
# with cursor: ksmserver tries to restore apps that no longer exist)
$KW --file ksmserverrc --group General --key loginMode "emptySession" 2>/dev/null || true
$KW --file ksmserverrc --group General --key confirmLogout false 2>/dev/null || true

# Disable the "offer to restore apps" prompt that blocks startup
$KW --file ksmserverrc --group General --key offerShutdownOptions true 2>/dev/null || true

# Make sure dbus-x11 is enabled and running — a missing session bus is
# reported on multiple forums as a cause of black-screen-with-cursor
# (plasmashell starts but can't connect to dbus, then crashes silently)
systemctl enable --now dbus 2>/dev/null || true
if ! command -v dbus-launch >/dev/null 2>&1; then
    apt-get install -y -qq dbus-x11 2>/dev/null || true
fi

# Ensure xdg-desktop-portal-kde is installed — it crashes silently on
# some systems without it, and a crashed portal can block plasmashell
# initialization entirely (seen in multiple forum threads, Arch + Ubuntu)
apt-get install -y -qq xdg-desktop-portal xdg-desktop-portal-kde 2>/dev/null || true

DOCS_URL="https://docs.google.com/document/d/1kA9LK5qkzpukMxPUKEU55RwFFWAMBbIhvoPwDbxWHHc/edit?usp=sharing"
# HOTKEYS (Win Style)
$KW --file kglobalshortcutsrc --group "org.kde.konsole.desktop" --key "_launch" "Ctrl+Alt+T,none,Konsole" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "org.kde.dolphin.desktop" --key "_launch" "Meta+E,none,Dolphin" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "kwin" --key "Show Desktop" "Meta+D,Meta+D,Show Desktop" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "org.kde.krunner.desktop" --key "_launch" "Meta+R,Alt+F2,KRunner" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "ksmserver" --key "Lock Session" "Meta+L,Meta+L,Lock Session" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "_launch" "Print,Print,Spectacle" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Select region" 2>/dev/null || true
$KW --file kglobalshortcutsrc --group "org.kde.ark.desktop" --key "_launch" "Meta+Shift+A,none,Ark" 2>/dev/null || true


# Keyboard layouts: US + RU, switch with Alt+Shift or Win+Space
$KW --file kxkbrc --group Layout --key Use true 2>/dev/null || true
$KW --file kxkbrc --group Layout --key LayoutList "us,ru" 2>/dev/null || true
$KW --file kxkbrc --group Layout --key Options "grp:alt_shift_toggle,grp:win_space_toggle" 2>/dev/null || true
$KW --file kxkbrc --group Layout --key ResetOldOptions true 2>/dev/null || true
# Same for the login screen (SDDM/X11) and the console
if [ -f /etc/default/keyboard ]; then
    sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="us,ru"/; s/^XKBOPTIONS=.*/XKBOPTIONS="grp:alt_shift_toggle,grp:win_space_toggle"/' /etc/default/keyboard
    grep -q '^XKBOPTIONS=' /etc/default/keyboard || echo 'XKBOPTIONS="grp:alt_shift_toggle,grp:win_space_toggle"' >> /etc/default/keyboard
    grep -q '^XKBLAYOUT=' /etc/default/keyboard || echo 'XKBLAYOUT="us,ru"' >> /etc/default/keyboard
fi

# Light theme by default
$KW --file kdeglobals --group General --key ColorScheme "Orizon-Light" 2>/dev/null || true
$KW --file kdeglobals --group KDE --key LookAndFeelPackage "com.orizon.orizon-light" 2>/dev/null || true
$KW --file plasmarc --group Theme --key name "default" 2>/dev/null || true

# Icons
$KW --file kdeglobals --group Icons --key Theme "$ICON_THEME_LIGHT" 2>/dev/null || true

# Fonts
$KW --file kdeglobals --group General --key font "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key fixed "JetBrains Mono,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key toolBarFont "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key menuFont "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true

# Double-click to open (Windows-style) instead of single-click.
# KDE defaults to single-click which confuses users coming from Windows.
$KW --file kdeglobals --group KDE --key SingleClick false 2>/dev/null || true
# Dolphin file manager has its own override for this
$KW --file dolphinrc --group General --key DoubleClickActivation true 2>/dev/null || true

# Make Dolphin look and feel more like Windows Explorer
# Details view by default (like Windows Explorer's default)
$KW --file dolphinrc --group General --key ViewPropertiesDialog false 2>/dev/null || true
$KW --file dolphinrc --group "Desktop View" --key ViewMode 1 2>/dev/null || true

# Always-visible editable address/navigation bar (like Windows address bar)
$KW --file dolphinrc --group General --key EditableUrl false 2>/dev/null || true
$KW --file dolphinrc --group General --key ShowFullPath true 2>/dev/null || true

# Show breadcrumb/path bar (like Windows breadcrumbs in Explorer)
$KW --file dolphinrc --group "KFileDialog Settings" --key "Show Bookmarks" true 2>/dev/null || true

# Show status bar at the bottom (like Windows Explorer)
$KW --file dolphinrc --group General --key ShowStatusBar true 2>/dev/null || true

# Show sidebar with Places panel on the left (like Windows left panel)
$KW --file dolphinrc --group General --key ShowSidePanel true 2>/dev/null || true
$KW --file dolphinrc --group General --key SidePanelWidth 180 2>/dev/null || true

# Show file preview (thumbnails) like Windows Explorer
$KW --file dolphinrc --group General --key ShowPreviewsInSplitView false 2>/dev/null || true
$KW --file dolphinrc --group "Local Settings" --key ShowPreview true 2>/dev/null || true

# Details view settings — show columns like Windows Explorer
$KW --file dolphinrc --group "DetailsModeSettings" --key PreviewSize 22 2>/dev/null || true

# Hide menu bar by default (more Windows-like, menus in hamburger/toolbar)
$KW --file dolphinrc --group General --key ShowMenuBar false 2>/dev/null || true

# Toolbar — show text labels next to icons (more clear/Windows-like)
$KW --file dolphinrc --group "MainWindow Toolbar mainToolBar" --key "IconSize" 22 2>/dev/null || true

# KWin — enable compositing but do NOT force the backend on real hardware.
# Forcing Backend=OpenGL is a real bug: in VMs or on hardware where GL/GLX
# isn't properly available, KWin's compositor fails to initialize with that
# forced value instead of using its own built-in fallback logic — which
# looks exactly like "X starts, cursor works, nothing ever draws". Confirmed
# on VMware: attempting OpenGL/GLX compositing crashed the X server itself
# outright (not just KWin) when going through SDDM's session launch.
#
# We first tried forcing Backend=XRender instead of disabling compositing
# outright — that stopped the X-server crash, but kwin_x11/plasmashell
# still stayed alive while drawing nothing at all (confirmed via `ps aux`
# during a live black screen: both processes were running, just nothing
# rendered). Only fully disabling compositing actually produced a visible
# desktop. So: no compositing effects out of the box on this distro, but a
# guaranteed-working desktop beats a possibly-broken "better" one.
# Compositing: disable ONLY on VMware (causes black screen there),
# enable on real hardware so rounded corners and effects work.
if grep -qi "vmware\|virtualbox\|qemu\|kvm" /sys/class/dmi/id/sys_vendor 2>/dev/null || \
   grep -qi "vmware\|virtualbox\|qemu" /proc/cpuinfo 2>/dev/null; then
    log_warn "VMware/VM detected — disabling compositing to prevent black screen"
    $KW --file kwinrc --group Compositing --key Enabled false
    $KW --file kwinrc --group Compositing --key OpenGLIsUnsafe true
    KWINRC_PATH="$USER_HOME/.config/kwinrc"
    if [ -f "$KWINRC_PATH" ] && grep -q "^Enabled=false$" "$KWINRC_PATH"; then
        log_ok "Compositing disabled in kwinrc (verified on disk)"
    else
        echo -e "${RED}FATAL: could not verify Compositing Enabled=false in $KWINRC_PATH${NC}"
        exit 1
    fi
else
    log_ok "Real hardware detected — compositing enabled (rounded corners will work)"
    $KW --file kwinrc --group Compositing --key Enabled true
    $KW --file kwinrc --group Compositing --key Backend "OpenGL"
    $KW --file kwinrc --group Compositing --key GLCore true
    $KW --file kwinrc --group Compositing --key OpenGLIsUnsafe false
fi

# Keep compositing ALWAYS on. By default KWin suspends compositing while a
# fullscreen app runs ("unredirect fullscreen") and when an app asks to block
# it; the ShapeCorners effect is dropped at that point and does not come back,
# so rounded corners vanish after leaving fullscreen.
$KW --file kwinrc --group Compositing --key UnredirectFullscreen false 2>/dev/null || true
$KW --file kwinrc --group Compositing --key WindowsBlockCompositing false 2>/dev/null || true

# ── Windows 11-style rounded window corners ────────────────────
# Breeze window decoration supports configurable corner radius via
# breezerc. Windows 11 uses ~8px radius. KDE Breeze default is 3.
# Also sets a thin border and compact buttons — closer to Win11 look.
$KW --file breezerc --group Windeco --key CornerRadius 6 2>/dev/null || true
$KW --file breezerc --group Windeco --key DrawBorderOnMaximizedWindows false 2>/dev/null || true
$KW --file breezerc --group Windeco --key TitleBarOpacity 100 2>/dev/null || true

# Breeze window decoration with large buttons
$KW --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.style.breeze" 2>/dev/null || true
$KW --file kwinrc --group org.kde.kdecoration2 --key theme "" 2>/dev/null || true
$KW --file kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal" 2>/dev/null || true
# Icon + title on left, buttons on right — Windows style
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "MF" 2>/dev/null || true
$KW --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX" 2>/dev/null || true
# Large button size in Breeze
$KW --file breezerc --group Windeco --key ButtonSize 3 2>/dev/null || true
log_ok "Breeze window decoration with large buttons installed"

# Menu/popup corner radius — controls the rounding of context menus,
# tooltips, dropdowns. Separate from window decoration radius above.
# KDE reads this from kdeglobals MenuCornerRadius (Plasma 5.25+)
$KW --file kdeglobals --group KDE --key MenuCornerRadius 6 2>/dev/null || true

# ── Compact minimal context menu like Linux Mint ──────────────
# Hide bloat items
$KW --file kservicemenurc --group "ServiceMenu Settings" \
    --key "ark_addtoarchive.desktop" false 2>/dev/null || true
$KW --file kservicemenurc --group "ServiceMenu Settings" \
    --key "ark_extracthere.desktop" false 2>/dev/null || true
$KW --file kservicemenurc --group "ServiceMenu Settings" \
    --key "ark_extract.desktop" false 2>/dev/null || true
$KW --file kservicemenurc --group "ServiceMenu Settings" \
    --key "kmail_attachmentservicemenu.desktop" false 2>/dev/null || true
$KW --file kservicemenurc --group "ServiceMenu Settings" \
    --key "rootactions_servicemenu.desktop" false 2>/dev/null || true

rm -f /usr/share/kio/servicemenus/orizon-more-options.desktop 2>/dev/null || true
rm -f /usr/share/kio/servicemenus/orizon-contextmenu.desktop 2>/dev/null || true
rm -f /usr/share/kio/servicemenus/orizon-hide.desktop 2>/dev/null || true

# Compact menu appearance — small padding/font like Linux Mint Cinnamon.
# KDE reads these from kdeglobals and the Qt stylesheet.
$KW --file kdeglobals --group General --key menuFont "Ubuntu,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true

# Write a Qt stylesheet that makes ALL menus compact, narrow and
# monochrome — exactly like Linux Mint's Nemo/GTK menus look:
# small padding, tight items, thin separator, no icon background.
# Compact menu font and spacing — like Linux Mint Cinnamon
$KW --file kdeglobals --group General --key menuFont "Ubuntu,10,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group KDE --key MenuItemHMargin 2 2>/dev/null || true
$KW --file kdeglobals --group KDE --key MenuItemVMargin 1 2>/dev/null || true
$KW --file kdeglobals --group KDE --key SmallIconSize 16 2>/dev/null || true

# Qt stylesheet for compact rounded menus — applied system-wide via
# ~/.config/kdeglobals stylesheet override. Light theme version.
mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/orizon-menu-light.css" << 'CSSEOF'
QMenu {
    padding: 3px 0px;
    border: 1px solid #d0d0d0;
    border-radius: 6px;
    background: #ffffff;
    min-width: 160px;
    max-width: 260px;
}
QMenu::item {
    padding: 3px 20px 3px 6px;
    color: #1a1a1a;
    background: transparent;
    border-radius: 3px;
    margin: 0px 2px;
}
QMenu::item:selected {
    background: #e0e0e0;
    color: #1a1a1a;
}
QMenu::item:disabled {
    color: #999999;
}
QMenu::separator {
    height: 1px;
    background: #e0e0e0;
    margin: 2px 4px;
}
QMenu::icon {
    padding-left: 4px;
}
QMenu::right-arrow {
    width: 8px;
    height: 8px;
}
CSSEOF

cat > "$USER_HOME/.config/orizon-menu-dark.css" << 'CSSEOF'
QMenu {
    padding: 3px 0px;
    border: 1px solid #333333;
    border-radius: 6px;
    background: #1e1e1e;
    min-width: 160px;
    max-width: 260px;
}
QMenu::item {
    padding: 3px 20px 3px 6px;
    color: #e0e0e0;
    background: transparent;
    border-radius: 3px;
    margin: 0px 2px;
}
QMenu::item:selected {
    background: #333333;
    color: #ffffff;
}
QMenu::item:disabled {
    color: #666666;
}
QMenu::separator {
    height: 1px;
    background: #333333;
    margin: 2px 4px;
}
QMenu::icon {
    padding-left: 4px;
}
CSSEOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/orizon-menu-light.css"
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/orizon-menu-dark.css"

log_ok "Compact Linux Mint-style context menu configured"

# ── Custom trash (bin) icon ────────────────────────────────────
log_step "Installing custom trash icon..."
# The active theme is ePapirus, which already contains user-trash /
# user-trash-full, so icons dropped into hicolor are never used. The helper
# script overwrites the icon inside every theme (ePapirus, Papirus, hicolor).
mkdir -p /opt/orizon/scripts
cp "$ORIZON_DIR/scripts/orizon-trash-icon.sh" /opt/orizon/scripts/orizon-trash-icon.sh
chmod +x /opt/orizon/scripts/orizon-trash-icon.sh
/opt/orizon/scripts/orizon-trash-icon.sh "$ORIZON_DIR/branding" || log_warn "Trash icon helper reported an error"
# papirus-icon-theme upgrades restore the stock icon — re-apply after every dpkg run
cat > /etc/apt/apt.conf.d/99orizon-trash-icon << 'APTEOF'
DPkg::Post-Invoke { "if [ -x /opt/orizon/scripts/orizon-trash-icon.sh ] && [ -d /opt/orizon/branding ]; then /opt/orizon/scripts/orizon-trash-icon.sh >/dev/null 2>&1 || true; fi"; };
APTEOF
log_ok "Custom trash icon installed"
# Rounded corners also need kwin's compositor to know about them —
# set InternalBorderRadius for software compositing path
$KW --file kwinrc --group Compositing --key GLPreferBufferSwap a 2>/dev/null || true

# ── FIX: Start button icon + panel height via direct config write ──
# If the Plasma config file already exists (reinstall), fix up the
# Start-button icon and set the default panel height to 44. Matches
# applets/containments by their plugin= line (kickoff/kicker/
# simplemenu for the icon, org.kde.panel for the panel) rather than
# guessing from section-header text — section headers are just
# numeric IDs, they never contain the word "kickoff" themselves.
PLASMA_CFG="$USER_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$PLASMA_CFG" ]; then
    python3 - "$PLASMA_CFG" "$ORIZON_LOGO" << 'PYEOF'
import re
import sys

path, icon = sys.argv[1], sys.argv[2]

with open(path) as f:
    lines = f.readlines()

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
    log_ok "Start button icon and panel height updated in existing config"
fi

mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/orizon-kickoff-icon" << EOF
$ORIZON_LOGO
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/orizon-kickoff-icon" 2>/dev/null || true

$KW --file ksplashrc --group KSplash --key Theme "com.orizon.orizon-light" 2>/dev/null || true
$KW --file ksplashrc --group KSplash --key Engine "KSplashQML" 2>/dev/null || true

# Lock screen
$KW --file kscreenlockerrc --group Greeter --key Theme "com.orizon.orizon-light" 2>/dev/null || true
$KW --file kscreenlockerrc --group Greeter --key WallpaperPlugin "org.kde.image" 2>/dev/null || true
$KW --file kscreenlockerrc --group "Greeter/Wallpaper/org.kde.image/General" \
    --key Image "file:///usr/share/backgrounds/orizon/lake.png" 2>/dev/null || true
$KW --file kscreenlockerrc --group Daemon --key Autolock true 2>/dev/null || true
$KW --file kscreenlockerrc --group Daemon --key Timeout 10 2>/dev/null || true

log_ok "KDE settings, hotkeys and autostart lock applied"

# ── 14. Plasma: first run — wallpaper and Start button ────────
log_step "Setting up autostart for wallpaper and Start button..."
BIN_DIR="$USER_HOME/.local/bin"
AUTOSTART_DIR="$USER_HOME/.config/autostart"
mkdir -p "$BIN_DIR" "$AUTOSTART_DIR"

cat > "$BIN_DIR/orizon-first-run.sh" << FIRSTRUN
#!/bin/bash
# Guard: if the Plasma config is missing or corrupted, restore the
# known-good template before plasmashell tries to use it.
PLASMA_CFG="\$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
TEMPLATE="/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ ! -f "\$PLASMA_CFG" ] || [ "\$(wc -c < "\$PLASMA_CFG")" -lt 200 ]; then
    if [ -f "\$TEMPLATE" ]; then
        cp "\$TEMPLATE" "\$PLASMA_CFG"
    fi
fi

# Wait for Plasma to fully load (with check instead of blind sleep)
for i in \$(seq 1 30); do
    qdbus org.kde.plasmashell /PlasmaShell 2>/dev/null && break
    sleep 2
done
# Extra pause for stability — plasmashell responds to qdbus before it's
# fully initialized; give it a moment to finish loading all applets.
sleep 5

# Apply only the lightweight parts here — do NOT run the full
# apply-kde-theme.sh because that kills and restarts plasmashell,
# which is unsafe timing during the very first login and is the exact
# cause of the "black screen + cursor only" symptom on the main user.
# Wallpaper and kickoff icon are safe to set live once plasma is up.
WALLPAPER="file:///usr/share/backgrounds/orizon/orizon-default.png"
LOGO="$ORIZON_LOGO"
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        d.writeConfig('Image', '\$WALLPAPER');
    }
    var allWidgets = widgets();
    for (var j = 0; j < allWidgets.length; j++) {
        var w = allWidgets[j];
        if (w.type === 'org.kde.plasma.kickoff' ||
            w.type === 'org.kde.plasma.kicker' ||
            w.type === 'org.kde.plasma.simplemenu') {
            w.currentConfigGroup = ['General'];
            w.writeConfig('icon', '\$LOGO');
            w.reloadConfig();
        }
    }
" 2>/dev/null || true

plasma-apply-wallpaperimage "/usr/share/backgrounds/orizon/orizon-default.png" 2>/dev/null || true

rm -f "$AUTOSTART_DIR/orizon-first-run.desktop"
FIRSTRUN

chmod +x "$BIN_DIR/orizon-first-run.sh"

cat > "$AUTOSTART_DIR/orizon-first-run.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON First Run
Exec=$BIN_DIR/orizon-first-run.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

chown -R "$INSTALL_USER:$INSTALL_USER" "$BIN_DIR" "$AUTOSTART_DIR"
log_ok "Autostart for wallpaper and Start button ready"

# ── 15. GRUB configuration ────────────────────────────────────
log_step "Configuring GRUB..."
if [ -f /etc/default/grub ]; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
    sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="ORIZON"/' /etc/default/grub
    if ! grep -q "GRUB_BACKGROUND" /etc/default/grub; then
        echo 'GRUB_BACKGROUND="/boot/grub/backgrounds/orizon-grub.png"' >> /etc/default/grub
    else
        sed -i 's|^GRUB_BACKGROUND=.*|GRUB_BACKGROUND="/boot/grub/backgrounds/orizon-grub.png"|' /etc/default/grub
    fi
    update-grub 2>/dev/null || true
fi
log_ok "GRUB configured"

# ── 16. Plymouth ──────────────────────────────────────────────
log_step "Installing Plymouth theme..."
apt-get install -y -qq plymouth plymouth-themes 2>/dev/null || true
PDIR="/usr/share/plymouth/themes/orizon"
mkdir -p "$PDIR"
cp -r "$ORIZON_DIR/plymouth/orizon/"* "$PDIR/" 2>/dev/null || true
update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
    default.plymouth "$PDIR/orizon.plymouth" 100 2>/dev/null || true
update-alternatives --set default.plymouth \
    "$PDIR/orizon.plymouth" 2>/dev/null || true
update-initramfs -u 2>/dev/null || true
log_ok "Plymouth installed"

# ── 17. Force Plasma session ──────────────────────────────────
log_step "Setting Plasma as default session..."
mkdir -p /var/lib/AccountsService/users/
cat > "/var/lib/AccountsService/users/$INSTALL_USER" << EOF
[User]
Session=plasma
SystemAccount=false
Icon=/usr/share/pixmaps/orizon/orizon-avatar.png
EOF
cp "$ORIZON_DIR/branding/orizon-avatar.png" "$USER_HOME/.face" 2>/dev/null || true
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.face" 2>/dev/null || true
echo -e "[Desktop]\nSession=plasma" > "$USER_HOME/.dmrc"
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.dmrc"
update-alternatives --set x-session-manager /usr/bin/startplasma-x11 2>/dev/null || true
log_ok "Plasma session set as default"

# ── 18. Fonts and additional apps ─────────────────────────────
log_step "Installing fonts and apps..."

# Icons: ePapirus / ePapirus-Dark are set in step 7 (no Fluent override).

apt-get install -y -qq \
    fonts-ubuntu fonts-noto fonts-jetbrains-mono fonts-firacode \
    neofetch htop btop curl wget git \
    zip unzip p7zip-full \
    vlc korganizer \
    2>/dev/null || true
log_ok "Fonts and apps installed"

# ── 18g. Google Chrome browser ─────────────────────────────────
log_step "Installing Google Chrome..."
if ! command -v google-chrome-stable >/dev/null 2>&1; then
    CHROME_DEB="$(mktemp --suffix=.deb)"
    if curl -fsSL -o "$CHROME_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
        # installing the .deb also adds Google's apt repository for updates
        apt-get install -y -qq "$CHROME_DEB" 2>/dev/null || true
    fi
    rm -f "$CHROME_DEB"
fi
if command -v google-chrome-stable >/dev/null 2>&1; then
    # Set Chrome as the default browser
    sudo -u "$INSTALL_USER" xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null || true
    sudo -u "$INSTALL_USER" xdg-mime default google-chrome.desktop text/html 2>/dev/null || true
    sudo -u "$INSTALL_USER" xdg-mime default google-chrome.desktop x-scheme-handler/http 2>/dev/null || true
    sudo -u "$INSTALL_USER" xdg-mime default google-chrome.desktop x-scheme-handler/https 2>/dev/null || true
    $KW --file kdeglobals --group General --key BrowserApplication "google-chrome.desktop" 2>/dev/null || true
    log_ok "Google Chrome installed and set as default browser"
else
    log_warn "Google Chrome installation failed — Firefox will be used as fallback"
fi

# ── 18f. Safe NTFS driver (ntfs3 + ntfs-3g fallback) ──────────
# The old default NTFS driver on Linux (ntfs-3g via FUSE) has known
# metadata-consistency issues that can corrupt NTFS volumes in ways
# Windows then can't repair automatically — annoying for dual-boot.
# ntfs3 is the Paragon-donated in-kernel driver (Linux 5.15+): proper
# kernel-level read/write, safe for dual-boot, Windows-compatible.
# ntfs-3g stays installed as a fallback for older kernels or edge cases.
log_step "Configuring safe NTFS support (ntfs3)..."
apt-get install -y -qq ntfs-3g 2>/dev/null || true

# Tell the kernel to use ntfs3 instead of ntfs-3g (FUSE) for all
# NTFS mounts. The udev rule fires before mount and overrides the
# driver selection. The udisks2 helper config does the same for
# desktop auto-mount (when you plug in a USB NTFS drive in Dolphin).
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/99-ntfs3.rules << 'EOF'
# Use the in-kernel ntfs3 driver instead of ntfs-3g (FUSE) for all
# NTFS volumes. ntfs3 is safer for dual-boot: proper kernel-level I/O,
# full Windows metadata compatibility, no FUSE overhead.
ENV{ID_FS_TYPE}=="ntfs", ENV{ID_FS_TYPE}="ntfs3"
EOF

# udisks2 (the desktop auto-mount daemon used by Dolphin/KDE) needs
# its own config to prefer ntfs3.
mkdir -p /etc/udisks2
cat > /etc/udisks2/mount_options.conf << 'EOF'
[defaults]
ntfs_defaults=uid=$UID,gid=$GID,noatime,nls=utf8,windows_names
ntfs_allow=uid,gid,umask,dmask,fmask,iocharset,nls,noatime,windows_names

[ntfs]
_driver=ntfs3
EOF

udevadm control --reload-rules 2>/dev/null || true
log_ok "ntfs3 driver configured as default for NTFS volumes"

# ── 18a. Install ORIZON fonts system-wide ─────────────────────
log_step "Installing ORIZON fonts..."
mkdir -p /usr/share/fonts/orizon
cp "$ORIZON_DIR/kde/sddm/orizon/fonts/"*.otf /usr/share/fonts/orizon/ 2>/dev/null || true
fc-cache -f /usr/share/fonts/orizon >/dev/null 2>&1 || true
log_ok "ORIZON fonts installed"

# ── 18b. Windows application support (Wine) ──────────────────
log_step "Installing Wine + Bottles..."
dpkg --add-architecture i386 2>/dev/null || true
apt-get update -qq 2>/dev/null || true
apt-get install -y -qq wine wine32 wine64 winetricks cabextract 2>/dev/null \
    || apt-get install -y -qq wine winetricks cabextract 2>/dev/null || true

# Bottles — modern GUI for Wine environments (Flatpak)
if command -v flatpak >/dev/null 2>&1 || apt-get install -y -qq flatpak 2>/dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak install -y --noninteractive flathub com.usebottles.bottles 2>/dev/null || true
fi

WINE_CMD="wine"

# Set Wine to appear as Windows 11
sudo -u "$INSTALL_USER" bash -c "
    export HOME=$USER_HOME
    export WINEARCH=win64
    timeout 300 xvfb-run -a winetricks -q win11 2>/dev/null || true
    timeout 900 xvfb-run -a winetricks -q dotnet45 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q vcrun2022 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q corefonts 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q d3dcompiler_47 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q dxvk 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q gdiplus 2>/dev/null || true
    timeout 300 xvfb-run -a winetricks -q msxml6 2>/dev/null || true
    wine reg add 'HKCU\\Software\\Wine\\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f 2>/dev/null || true
    wine reg add 'HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\AeDebug' /v Auto /t REG_SZ /d 0 /f 2>/dev/null || true
" > /tmp/orizon-wine.log 2>&1
apt-get purge -y -qq xvfb 2>/dev/null || true
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.wine" 2>/dev/null || true
log_ok "Wine installed and configured"

# .exe/.msi file associations
mkdir -p /usr/share/applications
cat > /usr/share/applications/orizon-wine-exe.desktop << EOF
[Desktop Entry]
Type=Application
Name=Запустить через Wine
Exec=wine "%f"
Icon=wine
NoDisplay=false
MimeType=application/x-ms-dos-executable;
Categories=System;Emulator;
EOF
cat > /usr/share/applications/orizon-wine-exe-normaluser.desktop << EOF
[Desktop Entry]
Type=Application
Name=Запустить через Wine (обычный пользователь)
Exec=wine runas /trustlevel:0x20000 "%f"
Icon=wine
NoDisplay=false
MimeType=application/x-ms-dos-executable;
Categories=System;Emulator;
EOF
cat > /usr/share/applications/orizon-wine-msi.desktop << EOF
[Desktop Entry]
Type=Application
Name=Установить через Wine (MSI)
Exec=wine msiexec /i "%f"
Icon=wine
NoDisplay=false
MimeType=application/x-msi;
Categories=System;Emulator;
EOF
update-desktop-database /usr/share/applications 2>/dev/null || true
mkdir -p /usr/share/applications
cat > /usr/share/applications/mimeapps.list << EOF
[Default Applications]
application/x-ms-dos-executable=orizon-wine-exe.desktop
application/x-msi=orizon-wine-msi.desktop
EOF
sudo -u "$INSTALL_USER" xdg-mime default orizon-wine-exe.desktop application/x-ms-dos-executable 2>/dev/null || true

# ── 18e. TruckersMP launcher script ──────────────────────────
cat > /opt/orizon/scripts/orizon-truckersmp.sh << 'TMPEOF'
#!/bin/bash
export WINEPREFIX="${HOME}/.wine-truckersmp"
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
if [ ! -d "$WINEPREFIX" ]; then
    WINEARCH=win64 wine wineboot --init 2>/dev/null
    winetricks -q win11 vcrun2019 dotnet48 2>/dev/null || true
fi
if [ -n "$1" ]; then
    wine runas /trustlevel:0x20000 "$@"
fi
TMPEOF
chmod +x /opt/orizon/scripts/orizon-truckersmp.sh

# ── 18f. Windows XP classic games ────────────────────────────
log_step "Installing classic games (Minesweeper, Solitaire etc.)..."
apt-get install -y -qq aisleriot gnome-mines kmines 2>/dev/null || true
# KDE alternatives for XP games
apt-get install -y -qq kmahjongg kpat klines ksudoku 2>/dev/null || true

# Custom .desktop for them with familiar Windows names
cat > /usr/share/applications/orizon-minesweeper.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Minesweeper
Name[ru]=Сапёр
Comment=Classic Minesweeper game
Comment[ru]=Классическая игра Сапёр
Exec=kmines
Icon=kmines
Categories=Game;
EOF
cat > /usr/share/applications/orizon-solitaire.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Solitaire
Name[ru]=Косынка
Comment=Classic Solitaire card game
Comment[ru]=Классический пасьянс Косынка
Exec=kpat
Icon=kpat
Categories=Game;
EOF
# Patch ALL games with Russian names (only shown when system is in Russian)
declare -A GAME_RU_NAMES=(
    ["kmahjongg.desktop"]="Маджонг|Классический маджонг"
    ["klines.desktop"]="Линии|Тактическая игра Линии"
    ["ksudoku.desktop"]="Судоку|Классическое судоку"
    ["kmines.desktop"]="Сапёр|Классическая игра Сапёр"
    ["kpat.desktop"]="Косынка|Классический пасьянс"
    ["sol.desktop"]="Пасьянс|Карточные пасьянсы AisleRiot"
    ["gnome-mines.desktop"]="Сапёр (GNOME)|Классическая игра Сапёр"
    ["kmahjongg.desktop"]="Маджонг|Классический маджонг"
    ["ksquares.desktop"]="Квадраты|Игра Квадраты"
    ["kbounce.desktop"]="Прыгунок|Игра Прыгунок"
    ["kapman.desktop"]="Пакман|Классический Пакман"
    ["ksnakeduel.desktop"]="Змейка|Классическая змейка"
    ["kolf.desktop"]="Гольф|Мини-гольф"
    ["kblocks.desktop"]="Блоки|Игра Тетрис"
    ["kbreakout.desktop"]="Арканоид|Классический арканоид"
    ["kiriki.desktop"]="Ямб|Игра в кости"
    ["kfourinline.desktop"]="Четыре в ряд|Четыре в ряд"
    ["kjumpingcube.desktop"]="Кубики|Прыгающие кубики"
    ["klickety.desktop"]="Кликети|Стратегическая игра"
    ["knetwalk.desktop"]="Сеть|Игра Сеть"
    ["kreversi.desktop"]="Реверси|Классическое реверси"
    ["kshisen.desktop"]="Шисэн|Маджонг Шисэн"
    ["ksirk.desktop"]="Риск|Стратегическая игра"
    ["kspaceduel.desktop"]="Космическая дуэль|Космическая дуэль"
    ["ktuberling.desktop"]="Картофельный человечек|Детская игра"
    ["kubrick.desktop"]="Кубик Рубика|Кубик Рубика"
    ["lskat.desktop"]="Офицерский скат|Карточная игра скат"
    ["granatier.desktop"]="Гранатир|Бомбермен"
    ["picmi.desktop"]="Пикми|Японский кроссворд"
    ["palapeli.desktop"]="Пазл|Собери пазл"
)

for desktop in "${!GAME_RU_NAMES[@]}"; do
    FILE="/usr/share/applications/$desktop"
    if [ -f "$FILE" ]; then
        IFS='|' read -r RU_NAME RU_COMMENT <<< "${GAME_RU_NAMES[$desktop]}"
        # Replace existing Name[ru] if present, otherwise add it
        if grep -q "^Name\[ru\]" "$FILE"; then
            sed -i "s|^Name\[ru\]=.*|Name[ru]=$RU_NAME|" "$FILE"
        else
            sed -i "/^Name=/a Name[ru]=$RU_NAME" "$FILE"
        fi
        # Replace existing Comment[ru] if present, otherwise add it
        if grep -q "^Comment\[ru\]" "$FILE"; then
            sed -i "s|^Comment\[ru\]=.*|Comment[ru]=$RU_COMMENT|" "$FILE"
        else
            grep -q "^Comment=" "$FILE" && \
                sed -i "/^Comment=/a Comment[ru]=$RU_COMMENT" "$FILE" || true
        fi
    fi
done
update-desktop-database /usr/share/applications 2>/dev/null || true
log_ok "Classic games installed"

# ── 19. Bash config ───────────────────────────────────────────
log_step "Configuring terminal..."
BASHRC="$USER_HOME/.bashrc"
# Remove old config version if present, write a fresh one
if grep -q "ORIZON Linux System" "$BASHRC" 2>/dev/null; then
    sed -i '/# ═══.*ORIZON Linux System/,$d' "$BASHRC" 2>/dev/null || true
fi
cat "$ORIZON_DIR/config/bashrc-orizon.sh" >> "$BASHRC"
chown "$INSTALL_USER:$INSTALL_USER" "$BASHRC"
log_ok "Bash configured"

# ── 20. Install ORIZON CLI and scripts ────────────────────────
log_step "Installing ORIZON CLI..."
mkdir -p /opt/orizon/scripts
cp "$ORIZON_DIR/scripts/update.sh"  /opt/orizon/scripts/update.sh
cp "$ORIZON_DIR/scripts/apply-kde-theme.sh" /opt/orizon/scripts/apply-kde-theme.sh
cp "$ORIZON_DIR/scripts/hotkeys.sh" /opt/orizon/scripts/hotkeys.sh
cp "$ORIZON_DIR/scripts/orizon-welcome.sh" /opt/orizon/scripts/orizon-welcome.sh
chmod +x /opt/orizon/scripts/*.sh

# One-shot panel-height enforcer — runs only on first login (removes
# its own autostart entry afterward), forcing the panel to 44 via live
# qdbus regardless of whatever's on disk. The static appletsrc seeding
# alone wasn't reliably reaching every account, so this is a guaranteed
# one-time correction rather than something that reruns forever.
cat > /opt/orizon/scripts/orizon-panel-height.sh << 'PANELHEIGHT'
#!/bin/bash
for i in $(seq 1 30); do
    qdbus org.kde.plasmashell /PlasmaShell 2>/dev/null && break
    sleep 1
done
sleep 2
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) {
        allPanels[i].height = 44;
    }
" 2>/dev/null || true
rm -f "$HOME/.config/autostart/orizon-panel-height.desktop"
PANELHEIGHT
chmod +x /opt/orizon/scripts/orizon-panel-height.sh

cat > "$USER_HOME/.config/autostart/orizon-panel-height.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON Panel Height
Exec=bash /opt/orizon/scripts/orizon-panel-height.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/autostart/orizon-panel-height.desktop"

# One-shot wallpaper enforcer — runs only on first login (removes its
# own autostart entry afterward), forcing ORIZON DEFAULT via live qdbus
# + plasma-apply-wallpaperimage regardless of whatever's on disk. Same
# guaranteed one-time correction as the panel-height enforcer above.
cat > /opt/orizon/scripts/orizon-wallpaper.sh << WALLPAPERENFORCE
#!/bin/bash
for i in \$(seq 1 30); do
    qdbus org.kde.plasmashell /PlasmaShell 2>/dev/null && break
    sleep 1
done
sleep 2
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        d.writeConfig('Image', 'file://$WALLPAPER_PATH');
    }
" 2>/dev/null || true
plasma-apply-wallpaperimage "$WALLPAPER_PATH" 2>/dev/null || true
rm -f "\$HOME/.config/autostart/orizon-wallpaper.desktop"
WALLPAPERENFORCE
chmod +x /opt/orizon/scripts/orizon-wallpaper.sh

cat > "$USER_HOME/.config/autostart/orizon-wallpaper.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON Wallpaper
Exec=bash /opt/orizon/scripts/orizon-wallpaper.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/autostart/orizon-wallpaper.desktop"

# Copy hotkeys.sh to first-login autostart — runs once
mkdir -p "$USER_HOME/.config/autostart"
cat > "$USER_HOME/.config/autostart/orizon-hotkeys.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON Hotkeys
Exec=bash /opt/orizon/scripts/hotkeys.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/autostart/orizon-hotkeys.desktop"
cat > "$USER_HOME/.config/autostart/orizon-welcome.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ORIZON Welcome
Exec=bash /opt/orizon/scripts/orizon-welcome.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/autostart/orizon-welcome.desktop"
log_ok "ORIZON CLI and hotkeys ready"

# /opt/orizon/branding must be a real copy, not a symlink back to the
# install folder — apply-kde-theme.sh (run on every `orizon --theme`,
# every Global Theme pick via the watcher, and both launchers) resolves
# ORIZON_DIR from its own location under /opt/orizon/scripts and reads
# every per-app icon from $ORIZON_DIR/branding/. A symlink here dangles
# the moment the extracted install folder gets deleted, which is
# exactly what was making icons disappear system-wide after cleanup.
rm -rf /opt/orizon/branding
mkdir -p /opt/orizon/branding
cp -r "$ORIZON_DIR/branding/"* /opt/orizon/branding/
sudo apt install -y xorg

# ── 21. Propagate per-user branding to other existing local users ──
# Everything above (icons, wallpaper, colorscheme, the `orizon --theme`
# CLI in .bashrc, theme-watcher/hotkeys/welcome autostart, konsole
# profile) was only ever written into $USER_HOME for $INSTALL_USER —
# the account that ran this installer with sudo. Any other pre-existing
# local account (a second admin, a family profile, etc.) never gets any
# of it: their desktop works fine (that part is system-wide), but they
# see stock KDE with no ORIZON branding and none of the orizon commands.
# Replay the same per-user files onto every other real local user, and
# stage the same set into /etc/skel/ so brand-new accounts created after
# install pick it up automatically too.
log_step "Propagating ORIZON branding to other existing users..."

# Relative to a user's $HOME — the exact set of files/dirs the sections
# above wrote for $INSTALL_USER.
ORIZON_USER_FILES=(
    .dmrc
    .face
    .config/kdeglobals
    .config/kwinrc
    .config/kxkbrc
    .config/kscreenlockerrc
    .config/ksplashrc
    .config/kglobalshortcutsrc
    .config/ksmserverrc
    .config/systemsettingsrc
    .config/dolphinrc
    .config/breezerc
    .config/konsolerc
    .config/kcm-about-distrorc
    .config/plasma-org.kde.plasma.desktop-appletsrc
    .config/orizon-theme-state
    .config/orizon-kickoff-icon
    .config/Kvantum
    .config/autostart/orizon-hotkeys.desktop
    .config/autostart/orizon-theme-watcher.desktop
    .config/autostart/orizon-welcome.desktop
    .config/autostart/orizon-first-run.desktop
    .config/autostart/orizon-panel-height.desktop
    .config/autostart/orizon-wallpaper.desktop
    .wine
    .local/bin/orizon-first-run.sh
    .local/share/color-schemes
    .local/share/konsole
    .local/share/pixmaps
    .local/share/icons/hicolor
    .local/share/applications
)

propagate_orizon_branding() {
    target_home="$1"
    target_owner="$2"   # "" for /etc/skel (no chown)

    for rel in "${ORIZON_USER_FILES[@]}"; do
        src="$USER_HOME/$rel"
        [ -e "$src" ] || continue
        dest="$target_home/$rel"
        mkdir -p "$(dirname "$dest")"
        cp -rT "$src" "$dest" 2>/dev/null || cp -r "$src" "$dest" 2>/dev/null || true
    done

    # .bashrc: append the ORIZON block, guarding against duplicates —
    # same guard used earlier for $INSTALL_USER.
    if [ -f "$ORIZON_DIR/config/bashrc-orizon.sh" ]; then
        target_bashrc="$target_home/.bashrc"
        touch "$target_bashrc"
        if grep -q "ORIZON Linux System" "$target_bashrc" 2>/dev/null; then
            sed -i '/# ═══.*ORIZON Linux System/,$d' "$target_bashrc" 2>/dev/null || true
        fi
        cat "$ORIZON_DIR/config/bashrc-orizon.sh" >> "$target_bashrc"
    fi

    if [ -n "$target_owner" ]; then
        chown -R "$target_owner:$target_owner" "$target_home/.config" "$target_home/.local" \
            "$target_home/.dmrc" "$target_home/.face" "$target_home/.bashrc" 2>/dev/null || true
        cat > "/var/lib/AccountsService/users/$target_owner" << ACCTEOF
[User]
Session=plasma
SystemAccount=false
Icon=/usr/share/pixmaps/orizon/orizon-avatar.png
ACCTEOF
    fi
}

# Stage into /etc/skel for accounts created after install.
propagate_orizon_branding /etc/skel ""

# Belt-and-suspenders: don't rely solely on the Global Theme cascade
# (/etc/xdg/kdeglobals -> layout.js) actually running for a brand-new
# profile — seed the actual Plasma config directly so panel height and
# wallpaper are correct for new users regardless.
mkdir -p /etc/skel/.config
cp "$ORIZON_DIR/kde/plasma-appletsrc-default" /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

# Replay onto every other existing real local user (UID 1000-59999,
# has a real home dir, has a real login shell — skips system/service
# accounts), excluding the one already fully handled above.
while IFS=: read -r uname _pass uid _gid _gecos uhome ushell; do
    [ "$uid" -ge 1000 ] && [ "$uid" -lt 60000 ] || continue
    [ "$uname" = "$INSTALL_USER" ] && continue
    [ -d "$uhome" ] || continue
    case "$ushell" in
        */nologin|*/false) continue ;;
    esac

    log_step "Applying ORIZON branding to existing user: $uname"
    propagate_orizon_branding "$uhome" "$uname"
    sudo -u "$uname" kbuildsycoca5 --noincremental 2>/dev/null || true
    log_ok "Branding applied for $uname (they need to log out and back in to see it)"
done < /etc/passwd

log_ok "Branding propagated to other existing users and /etc/skel"

# ── 22. Cleanup ───────────────────────────────────────────────
log_step "Cleaning up system..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true
log_ok "Done"


echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   ORIZON installed successfully!  🚀          ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Reboot the system:${NC} ${BOLD}sudo reboot${NC}"
echo -e "  ${CYAN}Documentation, new OS version, support and Telegram channel: https://freesof.ru${NC}"
echo -e ""
