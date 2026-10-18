#!/bin/bash
# ============================================================
#  ORIZON - Start menu (Kickoff) size: resizable AND remembered
#
#  Plasma 5.27's Kickoff has a resize grip, but the size lives only in
#  memory: FullRepresentation.qml binds
#      Layout.preferredWidth:  Math.max(implicitWidth,  width)
#      Layout.preferredHeight: Math.max(implicitHeight, height)
#  so after plasmashell restarts (login/reboot) the menu is back to its
#  implicit size. An older ORIZON fix replaced those bindings with fixed
#  numbers, which made the menu snap back every time it was reopened.
#
#  This script patches the plasmoid so that
#    * the size the user drags to is stored in the applet's own config
#      (keys orizonWidth / orizonHeight in appletsrc) and
#    * the stored size (or a 35x28 grid-unit default) is used when
#      plasmashell starts; during a session the stock binding is used again.
#  The resize ceiling (80x40 grid units upstream) is raised too.
#
#  Idempotent. Needs root. Re-run after plasma-desktop upgrades — the
#  installer registers it as an apt DPkg::Post-Invoke hook.
# ============================================================
DIR="/usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents"
QML="$DIR/ui/FullRepresentation.qml"
XML="$DIR/config/main.xml"

[ -f "$QML" ] || { echo "Kickoff FullRepresentation.qml not found — skipped"; exit 0; }

python3 - "$QML" "$XML" << 'PYEOF'
import re, sys
qml_path, xml_path = sys.argv[1], sys.argv[2]
MARK = "ORIZON-SIZE"

# ---- config keys --------------------------------------------------------
try:
    xml = open(xml_path).read()
except OSError:
    xml = None
if xml is not None and 'name="orizonWidth"' not in xml:
    entries = ('        <entry name="orizonWidth" type="Int"><default>0</default></entry>\n'
               '        <entry name="orizonHeight" type="Int"><default>0</default></entry>\n')
    m = re.search(r'<group name="General">\s*\n', xml)
    if m:
        xml = xml[:m.end()] + entries + xml[m.end():]
    else:
        xml = xml.replace('</kcfg>', '    <group name="General">\n' + entries + '    </group>\n</kcfg>')
    open(xml_path, 'w').write(xml)

# ---- QML ------------------------------------------------------------------
q = open(qml_path).read()

# Raise the resize ceiling (upstream: 80 x 40 grid units)
q = re.sub(r'Layout\.maximumWidth:\s*PlasmaCore\.Units\.gridUnit \* \d+',
           'Layout.maximumWidth: PlasmaCore.Units.gridUnit * 110', q)
q = re.sub(r'Layout\.maximumHeight:\s*PlasmaCore\.Units\.gridUnit \* \d+',
           'Layout.maximumHeight: PlasmaCore.Units.gridUnit * 60', q)

if MARK not in q:
    # Preferred size: saved/default size until the popup has been shown once,
    # then the stock "follow the current size" behaviour.
    q, n1 = re.subn(r'Layout\.preferredWidth:[^\n]+',
        'Layout.preferredWidth: Math.max(implicitWidth, orizonSettled ? width : orizonWantedWidth)', q, count=1)
    q, n2 = re.subn(r'Layout\.preferredHeight:[^\n]+',
        'Layout.preferredHeight: Math.max(implicitHeight, orizonSettled ? height : orizonWantedHeight)', q, count=1)

    block = '''
    // %s: remember the popup size the user picked (saved in the applet config)
    property bool orizonSettled: false
    readonly property real orizonWantedWidth: (plasmoid.configuration.orizonWidth > 0)
        ? plasmoid.configuration.orizonWidth : PlasmaCore.Units.gridUnit * 35
    readonly property real orizonWantedHeight: (plasmoid.configuration.orizonHeight > 0)
        ? plasmoid.configuration.orizonHeight : PlasmaCore.Units.gridUnit * 28
    Timer {
        id: orizonSizeSaver
        interval: 700
        onTriggered: {
            if (!root.visible || root.width <= 0 || root.height <= 0) {
                return;
            }
            root.orizonSettled = true;
            var w = Math.round(root.width), h = Math.round(root.height);
            if (plasmoid.configuration.orizonWidth !== w) {
                plasmoid.configuration.orizonWidth = w;
            }
            if (plasmoid.configuration.orizonHeight !== h) {
                plasmoid.configuration.orizonHeight = h;
            }
        }
    }
    onWidthChanged: orizonSizeSaver.restart()
    onHeightChanged: orizonSizeSaver.restart()
    onVisibleChanged: if (visible) orizonSizeSaver.restart()
''' % MARK
    if n1 and n2:
        # insert right after "id: root" of the root object
        q, n3 = re.subn(r'(\n[ \t]*id: root[ \t]*\n)', lambda m: m.group(1) + block, q, count=1)
        if not n3:
            sys.exit("could not find 'id: root' — Kickoff QML layout changed, nothing patched")
    else:
        sys.exit("could not find Layout.preferredWidth/Height — Kickoff QML layout changed, nothing patched")
    open(qml_path, 'w').write(q)
    print("Kickoff size persistence patched")
else:
    open(qml_path, 'w').write(q)
    print("Kickoff size persistence already present")
PYEOF
rc=$?

# Drop compiled-QML caches so the patched file is picked up on next login
for h in /home/*/.cache/plasmashell /root/.cache/plasmashell; do
    [ -d "$h" ] && rm -rf "$h/qmlcache" 2>/dev/null
done
exit $rc
