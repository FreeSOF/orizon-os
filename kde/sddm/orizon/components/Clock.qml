/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

ColumnLayout {
    spacing: 2

        FontLoader {
        id: clockfont
        source: "../fonts/Schulevetica-Regular.otf"
    }
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property date currentTime: new Date()
    Label {
        text: Qt.formatDateTime(currentTime, "h:mm")
        color: "white"
        opacity: 1
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? "black" : "transparent" //no outline, doesn't matter
        font.pointSize: 100
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
        font.family: clockfont.name

    }
    Label {
        text: Qt.formatDateTime(currentTime, "dddd, d MMMM")
        color: "white"
        opacity: 1
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? "black" : "transparent" //no outline, doesn't matter
        font.pointSize: 20
        font.weight: Font.DemiBold
        font.capitalization: Font.Capitalize
        Layout.alignment: Qt.AlignHCenter
        font.family: clockfont.name

    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }

}
