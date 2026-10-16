#!/bin/bash

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'

ORIZON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$INSTALL_USER")

# Resource paths (always relative — works for any user)
ORIZON_LOGO="$ORIZON_DIR/branding/orizon-logo.png"
ORIZON_SETTINGS_ICON="$ORIZON_DIR/branding/orizon-settings.png"
ORIZON_EXPLORER_ICON="$ORIZON_DIR/branding/orizon-nautilus-dolphin.png"
ORIZON_LINK="https://freesof.ru/orizon-os"
WALLPAPER_PATH="/usr/share/backgrounds/orizon/orizon-default.png"

# Application icons (from branding/ folder)
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
ORIZON_ICON_LO_STARTCENTER="$ORIZON_DIR/branding/orizon-lo.png"

[[ $EUID -ne 0 ]] && { echo -e "${RED}Run as: sudo bash $0${NC}"; exit 1; }

print_banner() {
cat << 'BANNER'

   ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗
  ██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║
  ██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║
  ██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║
  ╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║
   ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
           KDE PLASMA EDITION  |  Beta 2 / Fix 4
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
sudo apt update
sudo apt install -y aptitude
sudo aptitude install -y kde-plasma-desktop
sudo aptitude install -y gwenview
sudo aptitude install -y ark
sudo aptitude install -y konsole
sudo aptitude install -y kate
sudo aptitude install -y okular
sudo aptitude install -y kde-spectacle
sudo aptitude install -y libreoffice
sudo apt install -y sddm
sudo systemctl enable sddm
log_ok "KDE Plasma installed"

# ── 4. Configure SDDM (WITH AUTOLOGIN) ───────────────────────
log_step "Configuring SDDM and Autologin..."
# Disable other DMs
for dm in gdm3 gdm lightdm; do
    systemctl disable $dm 2>/dev/null || true
done
systemctl enable sddm 2>/dev/null || true
echo "/usr/bin/sddm" > /etc/X11/default-display-manager
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure sddm 2>/dev/null || true

# Install our ORIZON SDDM theme
SDDM_THEME_DIR="/usr/share/sddm/themes/orizon"
mkdir -p "$SDDM_THEME_DIR"
cp -r "$ORIZON_DIR/kde/sddm/orizon/"* "$SDDM_THEME_DIR/" 2>/dev/null || true

# SDDM config — use our theme AND ENABLE AUTOLOGIN
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/orizon.conf << EOF
[Theme]
Current=orizon

[General]
DefaultSession=plasma
Numlock=on

[Autologin]
User=$INSTALL_USER
Session=plasma
EOF

log_ok "SDDM configured"

# ── 5. Wallpaper and branding ─────────────────────────────────
log_step "Installing wallpaper and branding..."
mkdir -p /usr/share/backgrounds/orizon
cp "$ORIZON_DIR/wallpapers/"*.png /usr/share/backgrounds/orizon/ 2>/dev/null || true
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
log_step "Installing Papirus icons..."
apt-get install -y -qq papirus-icon-theme 2>/dev/null || true
log_ok "Papirus-Dark installed"

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

# ── 9. Look-and-Feel package ──────────────────────────────────
log_step "Installing Look-and-Feel theme..."
LAF="/usr/share/plasma/look-and-feel/com.orizon.orizon-dark"
mkdir -p "$LAF/contents/"{defaults,layouts,previews,splash/images,lockscreen}
cp -r "$ORIZON_DIR/kde/look-and-feel/"* "$LAF/" 2>/dev/null || true
cp "$ORIZON_DIR/branding/orizon-logo-256.png" "$LAF/contents/previews/preview.png" 2>/dev/null || true
cp "$ORIZON_DIR/wallpapers/orizon-splash.png" "$LAF/contents/splash/images/main.png" 2>/dev/null || true
# Also for the user
USER_LAF="$USER_HOME/.local/share/plasma/look-and-feel/com.orizon.orizon-dark"
mkdir -p "$USER_LAF/contents/"{defaults,layouts,previews,splash/images}
cp -r "$ORIZON_DIR/kde/look-and-feel/"* "$USER_LAF/" 2>/dev/null || true
cp "$ORIZON_DIR/branding/orizon-logo-256.png" "$USER_LAF/contents/previews/preview.png" 2>/dev/null || true
cp "$ORIZON_DIR/wallpapers/orizon-splash.png" "$USER_LAF/contents/splash/images/main.png" 2>/dev/null || true
chown -R "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.local/share/plasma" 2>/dev/null || true
log_ok "Look-and-Feel installed"

# ── 10. Kvantum ───────────────────────────────────────────────
log_step "Installing Kvantum theme..."
mkdir -p /usr/share/Kvantum/Orizon
cp "$ORIZON_DIR/kde/kvantum/Orizon/"* /usr/share/Kvantum/Orizon/ 2>/dev/null || true
mkdir -p "$USER_HOME/.config/Kvantum/Orizon"
cp "$ORIZON_DIR/kde/kvantum/Orizon/"* "$USER_HOME/.config/Kvantum/Orizon/" 2>/dev/null || true
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

# System Settings icon
SYS_DESKTOP="/usr/share/applications/systemsettings.desktop"
if [ -f "$SYS_DESKTOP" ]; then
    cp "$SYS_DESKTOP" "$USER_HOME/.local/share/applications/"
    sed -i "s|^Icon=.*|Icon=$ORIZON_SETTINGS_ICON|g" \
        "$USER_HOME/.local/share/applications/systemsettings.desktop"
fi

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
Opacity=0.88

[Background]
Color=13,17,23

[BackgroundIntense]
Color=22,33,45

[Foreground]
Color=230,237,243

[ForegroundIntense]
Color=255,255,255

[Color0]
Color=33,41,54

[Color1]
Color=248,81,73

[Color2]
Color=63,185,80

[Color3]
Color=210,153,34

[Color4]
Color=88,166,255

[Color5]
Color=188,140,255

[Color6]
Color=57,212,207

[Color7]
Color=177,186,196

[Color0Intense]
Color=48,54,61

[Color1Intense]
Color=255,120,112

[Color2Intense]
Color=86,211,100

[Color3Intense]
Color=229,176,58

[Color4Intense]
Color=121,192,255

[Color5Intense]
Color=210,168,255

[Color6Intense]
Color=86,212,221

[Color7Intense]
Color=230,237,243
EOF

cat > "$KONSOLE_DIR/Orizon.profile" << 'EOF'
[Appearance]
ColorScheme=Orizon
Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0

[General]
Name=Orizon
Parent=FALLBACK/
TerminalColumns=110
TerminalRows=30

[Scrolling]
HistorySize=10000
ScrollBarPosition=2
EOF

cat > "$USER_HOME/.config/konsolerc" << 'EOF'
[Desktop Entry]
DefaultProfile=Orizon.profile
EOF
chown -R "$INSTALL_USER:$INSTALL_USER" "$KONSOLE_DIR" "$USER_HOME/.config/konsolerc"
log_ok "Konsole configured"

# ── 13. Apply KDE settings AND HOTKEYS ────────────────────────
log_step "Applying KDE settings, hotkeys and session..."
KW="sudo -u $INSTALL_USER kwriteconfig5"

# DISABLE APP RESTORE ON LOGIN
$KW --file ksmserverrc --group General --key loginMode "emptySession" 2>/dev/null || true
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


# Light theme by default
$KW --file kdeglobals --group General --key ColorScheme "Orizon-Light" 2>/dev/null || true
$KW --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breeze.desktop" 2>/dev/null || true

# Icons
$KW --file kdeglobals --group Icons --key Theme "Papirus" 2>/dev/null || true

# Fonts
$KW --file kdeglobals --group General --key font "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key fixed "JetBrains Mono,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key toolBarFont "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true
$KW --file kdeglobals --group General --key menuFont "Ubuntu,11,-1,5,50,0,0,0,0,0" 2>/dev/null || true

# KWin
$KW --file kwinrc --group Compositing --key Enabled true 2>/dev/null || true
$KW --file kwinrc --group Compositing --key Backend OpenGL 2>/dev/null || true

# ── FIX: Start button icon via direct config write ────────────
# If the Plasma config file already exists (reinstall),
# update icon= in all Kickoff/Kicker/SimpleMenu sections
PLASMA_CFG="$USER_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$PLASMA_CFG" ]; then
    python3 - "$PLASMA_CFG" "$ORIZON_LOGO" << 'PYEOF'
import sys, re

path = sys.argv[1]
icon = sys.argv[2]

with open(path, 'r') as f:
    lines = f.readlines()

in_kickoff_section = False
result = []

for line in lines:
    # Check if we're entering a menu widget section
    if line.startswith('['):
        in_kickoff_section = any(x in line for x in ['kickoff', 'kicker', 'simplemenu', 'Kickoff', 'Kicker', 'SimpleMenu'])
    # If in the right section and we find icon= — replace it
    if in_kickoff_section and re.match(r'^icon\s*=', line):
        line = f'icon={icon}\n'
    result.append(line)

with open(path, 'w') as f:
    f.writelines(result)
PYEOF
    log_ok "Start button icon updated in existing config"
fi

mkdir -p "$USER_HOME/.config"
cat > "$USER_HOME/.config/orizon-kickoff-icon" << EOF
$ORIZON_LOGO
EOF
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.config/orizon-kickoff-icon" 2>/dev/null || true

$KW --file ksplashrc --group KSplash --key Theme "com.orizon.orizon-dark" 2>/dev/null || true
$KW --file ksplashrc --group KSplash --key Engine "KSplash" 2>/dev/null || true

# Lock screen
$KW --file kscreenlockerrc --group Greeter --key Theme "com.orizon.orizon-dark" 2>/dev/null || true
$KW --file kscreenlockerrc --group Greeter --key WallpaperPlugin "org.kde.image" 2>/dev/null || true
$KW --file kscreenlockerrc --group "Greeter/Wallpaper/org.kde.image/General" \
    --key Image "file:///usr/share/backgrounds/orizon/orizon-default.png" 2>/dev/null || true
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
# Wait for Plasma to fully load (with check instead of blind sleep)
for i in \$(seq 1 30); do
    qdbus org.kde.plasmashell /PlasmaShell 2>/dev/null && break
    sleep 2
done
# Extra pause for stability
sleep 3

# Set our wallpaper via official Plasma API
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        d.writeConfig('Image', 'file://$WALLPAPER_PATH');
    }
" 2>/dev/null || true

# Fallback
plasma-apply-wallpaperimage "$WALLPAPER_PATH" 2>/dev/null || true

# Start button icon — our logo
# Iterate over all known menu widget types
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allWidgets = widgets();
    for (var i = 0; i < allWidgets.length; i++) {
        var w = allWidgets[i];
        if (w.type === 'org.kde.plasma.kickoff' ||
            w.type === 'org.kde.plasma.kicker' ||
            w.type === 'org.kde.plasma.simplemenu') {
            w.currentConfigGroup = ['General'];
            w.writeConfig('icon', '$ORIZON_LOGO');
            w.reloadConfig();
        }
    }
" 2>/dev/null || true

# Trash bin icon on desktop via Plasma API
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allWidgets = widgets();
    for (var i = 0; i < allWidgets.length; i++) {
        var w = allWidgets[i];
        if (w.type === 'org.kde.plasma.trash') {
            w.currentConfigGroup = ['General'];
            w.writeConfig('icon', '$ORIZON_ICON_TRASHBIN');
            w.reloadConfig();
        }
    }
" 2>/dev/null || true

# Update gtk + hicolor icon cache
gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null || true

# Clear KDE icon cache
rm -f ~/.cache/icon-cache.kcache
rm -rf ~/.cache/plasma-svgelements-*
kbuildsycoca5 --noincremental 2>/dev/null || true

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
EOF
echo -e "[Desktop]\nSession=plasma" > "$USER_HOME/.dmrc"
chown "$INSTALL_USER:$INSTALL_USER" "$USER_HOME/.dmrc"
update-alternatives --set x-session-manager /usr/bin/startplasma-x11 2>/dev/null || true
log_ok "Plasma session set as default"

# ── 18. Fonts and additional apps ─────────────────────────────
log_step "Installing fonts and apps..."
apt-get install -y -qq \
    fonts-ubuntu fonts-noto fonts-jetbrains-mono fonts-firacode \
    neofetch htop btop curl wget git \
    zip unzip p7zip-full \
    vlc conky-all yad zenity \
    2>/dev/null || true
log_ok "Fonts and apps installed"

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

sudo ln -sfn "$ORIZON_DIR/branding" /opt/orizon/branding
sudo apt install -y xorg

# ── 21. Cleanup ───────────────────────────────────────────────
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
echo -e "  ${CYAN}Documentation, new OS version, support and Telegram channel: https://freesof.ru/orizon-os${NC}"
echo -e ""
