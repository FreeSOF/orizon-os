import QtQuick 2.5
import QtQuick.Window 2.2

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#000000"

    property int stage

    onStageChanged: {
        if (stage === 1) {
            fadeIn.running = true;
        }
    }

    Image {
        id: logo
        anchors.centerIn: parent
        source: "images/main.png"
        width: Math.min(root.width, root.height) * 0.12
        height: width
        fillMode: Image.PreserveAspectFit
        opacity: 0

        NumberAnimation {
            id: fadeIn
            target: logo
            property: "opacity"
            to: 1
            duration: 500
            running: false
        }
    }

    Rectangle {
        id: spinner
        width: 28
        height: 28
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: "#3d7eff"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: "#3d7eff"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 1200
            loops: Animation.Infinite
            running: true
        }
    }
}
