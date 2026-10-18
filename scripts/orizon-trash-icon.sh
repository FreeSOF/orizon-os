#!/bin/bash
# ============================================================
#  ORIZON - force the ORIZON bin icon into every icon theme
#
#  Why this exists: the active icon theme is ePapirus, which ships
#  user-trash / user-trash-full as SVG files (often symlinks) in
#  <size>/places and <size>/panel. A PNG dropped in hicolor is only a
#  FALLBACK that is never reached, because ePapirus already has the
#  icon — so Dolphin / the Trash widget kept showing the stock icon.
#  This replaces those files inside each theme with our PNGs, sized to
#  the directory they live in.
#
#  Usage: orizon-trash-icon.sh [branding_dir]   (run as root)
#  Re-run automatically after every apt/dpkg run (see apt hook), since
#  upgrading papirus-icon-theme restores the stock files.
# ============================================================
SRC="${1:-/opt/orizon/branding}"
SET="$SRC/orizon-trash-icons"
FALLBACK="$SRC/orizon-trashbin.png"
SIZES="16 22 24 32 48 64 128 256"
THEMES="ePapirus ePapirus-Dark Papirus Papirus-Dark Papirus-Light hicolor"

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
[ -d "$SET" ] || [ -f "$FALLBACK" ] || { echo "no trash icons in $SRC" >&2; exit 1; }

# best source PNG for a wanted pixel size
pick() {
    local want="$1" best="" bestd=99999 s d
    for s in $SIZES; do
        [ -f "$SET/trash-empty-$s.png" ] || continue
        d=$(( s > want ? s - want : want - s ))
        if [ "$d" -lt "$bestd" ]; then bestd=$d; best="$SET/trash-empty-$s.png"; fi
    done
    [ -n "$best" ] && echo "$best" || echo "$FALLBACK"
}

# size (px) of an icon dir like .../48x48/places or .../16x16@2x/places
dir_px() {
    if [[ "$1" =~ /([0-9]+)x[0-9]+(@([0-9]+)x)?/ ]]; then
        echo $(( ${BASH_REMATCH[1]} * ${BASH_REMATCH[3]:-1} ))
    else
        echo 48
    fi
}

replace_icon() {   # dir name
    local dir="$1" name="$2" px src
    px=$(dir_px "$dir/")
    src=$(pick "$px")
    [ -f "$src" ] || return 0
    rm -f "$dir/$name".svg "$dir/$name".svgz "$dir/$name".png "$dir/$name".xpm
    install -m644 "$src" "$dir/$name.png"
}

for T in $THEMES; do
    ROOT="/usr/share/icons/$T"
    [ -d "$ROOT" ] || continue

    # every place the theme already has these icons
    while IFS= read -r -d '' f; do
        d=$(dirname "$f"); b=$(basename "$f"); n="${b%.*}"
        replace_icon "$d" "$n"
    done < <(find "$ROOT" \( -type f -o -type l \) \
                \( -name 'user-trash.*' -o -name 'user-trash-full.*' \) -print0 2>/dev/null)

    # hicolor: make sure every size has the icon even if the theme had none
    if [ "$T" = "hicolor" ]; then
        for s in $SIZES; do
            d="$ROOT/${s}x${s}/places"
            [ -d "$ROOT/${s}x${s}" ] || continue
            mkdir -p "$d"
            replace_icon "$d" user-trash
            replace_icon "$d" user-trash-full
        done
    fi
    gtk-update-icon-cache -f -t "$ROOT" >/dev/null 2>&1 || true
done
touch /usr/share/icons
exit 0
