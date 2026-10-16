#!/bin/bash
# ORIZON Updater (KDE-safe)
#
# Updates ORIZON itself to the latest version — pulls the latest repo,
# re-applies branding/theme/config (same steps as install-kde.sh), and
# upgrades system packages — all while running inside a live Plasma
# session, without needing a logout or getting stuck on needrestart
# dialogs / active Plasma processes.
[[ $EUID -ne 0 ]] && exec sudo "$0" "$@"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'

log_step() { echo -e "\n${CYAN}[ORIZON]${NC} ${BOLD}$1${NC}"; }
log_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
log_err()  { echo -e "${RED}  ✗ $1${NC}"; }

echo ""
echo -e "  ${CYAN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}${BOLD}║   ORIZON Updater — KDE-safe          ║${NC}"
echo -e "  ${CYAN}${BOLD}╚══════════════════════════════════════╝${NC}"

# ── 0. Locate the ORIZON repo and the real logged-in user ─────────────────
ORIZON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$ORIZON_DIR/install-kde.sh"
[ -f "$INSTALL_SCRIPT" ] || INSTALL_SCRIPT="$ORIZON_DIR/scripts/install-kde.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    log_err "install-kde.sh not found next to this script — cannot re-apply ORIZON."
    log_warn "Run this script from inside your orizon-os clone (e.g. scripts/update-kde.sh)."
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"

CURRENT_VERSION="$(grep -oP '^VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")"
log_step "Current version: ${BOLD}${CURRENT_VERSION}${NC}"

# ── 1. Fully non-interactive apt/dpkg — nothing should prompt us ──────────
export DEBIAN_FRONTEND=noninteractive
export UCF_FORCE_CONFFOLD=1
export NEEDRESTART_MODE=a       # 'a' = auto-restart services, no dialog list
export NEEDRESTART_SUSPEND=1    # keep needrestart out of the way during the update
DPKG_OPTS=(-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/^#\?\$nrconf{restart}\s*=.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf 2>/dev/null || true
fi

# ── 2. Wait for the dpkg lock instead of failing instantly ────────────────
log_step "Checking dpkg/apt locks..."
WAITED=0
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    if [ "$WAITED" -eq 0 ]; then
        log_warn "Another process is holding the apt lock (e.g. Discover). Waiting..."
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    if [ "$WAITED" -ge 60 ]; then
        log_warn "Lock held too long — clearing it by force."
        pkill -f plasma-discover 2>/dev/null || true
        systemctl stop packagekit 2>/dev/null || true
        break
    fi
done
log_ok "apt is free"

# ── 3. Pull the latest ORIZON version from the repo ────────────────────────
log_step "Fetching the latest ORIZON version..."
if [ -d "$ORIZON_DIR/.git" ]; then
    git -C "$ORIZON_DIR" fetch --quiet origin
    git -C "$ORIZON_DIR" reset --quiet --hard origin/main
    log_ok "Repo updated to the latest commit on main"
else
    log_warn "$ORIZON_DIR is not a git checkout — skipping repo update."
    log_warn "Re-clone https://github.com/FreeSOF/orizon-os for automatic version pulls."
fi

# ── 4. System package upgrade (Plasma keeps running as-is) ─────────────────
log_step "Refreshing package lists..."
apt-get update -qq
log_ok "Package lists updated"

log_step "Upgrading system packages..."
apt-get dist-upgrade -y "${DPKG_OPTS[@]}"
log_ok "System packages upgraded"

# ── 5. Re-apply ORIZON branding/theme/config — same as a fresh install ────
# install-kde.sh is written defensively (mkdir -p, cp ... || true), so
# re-running it only refreshes what changed between versions instead of
# breaking anything already in place.
log_step "Re-applying ORIZON branding, theme and scripts..."
bash "$INSTALL_SCRIPT"
log_ok "ORIZON layer re-applied"

# ── 6. Live-reload Plasma instead of forcing a logout ──────────────────────
if id -u "$REAL_USER" >/dev/null 2>&1; then
    USER_ID=$(id -u "$REAL_USER")
    USER_RUNTIME_DIR="/run/user/$USER_ID"
    if [ -S "$USER_RUNTIME_DIR/bus" ]; then
        log_step "Reloading Plasma Shell to pick up the update..."
        RUN_AS_USER=(sudo -u "$REAL_USER" \
            XDG_RUNTIME_DIR="$USER_RUNTIME_DIR" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_RUNTIME_DIR/bus")

        "${RUN_AS_USER[@]}" kbuildsycoca6 --noincremental 2>/dev/null || \
        "${RUN_AS_USER[@]}" kbuildsycoca5 --noincremental 2>/dev/null || true

        "${RUN_AS_USER[@]}" gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null || true
        "${RUN_AS_USER[@]}" rm -f ~/.cache/icon-cache.kcache 2>/dev/null || true
        "${RUN_AS_USER[@]}" rm -rf ~/.cache/plasma-svgelements-* 2>/dev/null || true

        "${RUN_AS_USER[@]}" kquitapp5 plasmashell 2>/dev/null || \
        "${RUN_AS_USER[@]}" kquitapp6 plasmashell 2>/dev/null || true
        sleep 1
        "${RUN_AS_USER[@]}" nohup plasmashell >/dev/null 2>&1 &
        disown
        log_ok "Plasma Shell reloaded"
    fi
fi

# ── 7. Cleanup ──────────────────────────────────────────────────────────────
log_step "Cleaning up..."
apt-get autoremove -y -qq
apt-get autoclean -qq
log_ok "Done"

# ── 8. Report the result ────────────────────────────────────────────────────
NEW_VERSION="$(grep -oP '^VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "unknown")"

echo ""
if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
    echo -e "  ${GREEN}${BOLD}✓ ORIZON updated: ${CURRENT_VERSION} → ${NEW_VERSION}${NC}"
else
    echo -e "  ${GREEN}${BOLD}✓ ORIZON is already on the latest version (${NEW_VERSION})${NC}"
fi
log_warn "SDDM/login-screen theme changes only take effect after your next login."
if [ -f /var/run/reboot-required ]; then
    echo -e "  ${YELLOW}⚠ A reboot is required (kernel or system libs were updated):${NC} ${BOLD}sudo reboot${NC}"
fi
echo ""
