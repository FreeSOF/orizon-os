#!/bin/bash
# ============================================================
#  ORIZON - Theme Watcher
#
#  Bridges System Settings > Appearance > Global Theme to our full
#  theme application. Picking "Orizon Light"/"Orizon Dark" there and
#  hitting Apply reliably writes kdeglobals' LookAndFeelPackage key —
#  it just never used to do anything else (icon theme variant,
#  wallpaper, Kvantum, "About This System" branding, a plasmashell
#  restart). This script watches kdeglobals, and whenever it notices
#  LookAndFeelPackage has changed to one of ours, runs the same
#  apply-kde-theme.sh used by `orizon --theme light|dark`.
#
#  Runs once per user session, started from autostart.
# ============================================================

KDEGLOBALS="$HOME/.config/kdeglobals"
STATE_FILE="$HOME/.config/orizon-theme-state"
APPLY_SCRIPT="/opt/orizon/scripts/apply-kde-theme.sh"
LOG_FILE="$HOME/.config/orizon-theme-watcher.log"

mkdir -p "$HOME/.config"
[ -f "$STATE_FILE" ] || : > "$STATE_FILE"
: > "$LOG_FILE" 2>/dev/null || true

log() { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }

# Nothing to watch (fresh account, kdeglobals not created yet) — wait for it.
while [ ! -f "$KDEGLOBALS" ]; do
    sleep 5
done

if ! command -v inotifywait >/dev/null 2>&1; then
    log "inotifywait not found (inotify-tools not installed) — watcher exiting"
    exit 0
fi

READCFG="kreadconfig5"
command -v kreadconfig5 >/dev/null 2>&1 || READCFG="kreadconfig6"

log "watcher started, watching $(dirname "$KDEGLOBALS") (using $READCFG)"

# IMPORTANT: -m (monitor mode) is required. Without it, inotifywait reports
# a single event and exits — piping that through `grep -q` as a `while`
# condition means the loop terminates the moment ANY other file in
# ~/.config changes (which happens constantly in a live Plasma session),
# long before the user ever touches Global Theme. -m keeps one long-lived
# inotifywait process emitting one line per event, which the `while read`
# loop below can filter safely without killing the watch itself.
#
# IMPORTANT #2: KConfig (which kdeglobals is) normally does NOT write to
# the file in place — it writes a temp file and atomically renames it over
# kdeglobals. That produces a MOVED_TO event, not CLOSE_WRITE. Missing
# -e moved_to here means the watcher silently never sees KDE's own writes
# (confirmed: kdeglobals' value changes, but no event ever reaches us).
inotifywait -m -e close_write -e create -e moved_to --format '%f' "$(dirname "$KDEGLOBALS")" 2>>"$LOG_FILE" |
while read -r changed_file; do
    [ "$changed_file" == "kdeglobals" ] || continue

    # Give KDE a moment to finish writing before we read the file — its
    # native Global Theme apply touches several files in sequence
    # (kdeglobals, wallpaper, ksplashrc, kscreenlockerrc) and re-runs
    # layout.js to rebuild the panel, so 1s wasn't always enough for
    # that to fully settle before we ran on top of it.
    sleep 3

    CURRENT=$("$READCFG" --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null)
    LAST=$(cat "$STATE_FILE" 2>/dev/null)

    # Not one of ours (Breeze, etc.) — leave it alone.
    case "$CURRENT" in
        com.orizon.orizon-light)    MODE="light" ;;
        com.orizon.orizon-dark)     MODE="dark" ;;
        com.orizon.orizon-twilight) MODE="twilight" ;;
        *) continue ;;
    esac

    # Already applied — this write was either our own or a duplicate
    # "Apply" click; nothing new to do.
    if [ "$CURRENT" == "$LAST" ]; then
        continue
    fi

    echo "$CURRENT" > "$STATE_FILE"
    log "detected LookAndFeelPackage=$CURRENT -> applying mode=$MODE"

    if [ -x "$APPLY_SCRIPT" ]; then
        bash "$APPLY_SCRIPT" "$MODE" >> "$LOG_FILE" 2>&1
        log "apply-kde-theme.sh $MODE finished (exit $?)"
    else
        log "ERROR: $APPLY_SCRIPT not found or not executable"
    fi
done
