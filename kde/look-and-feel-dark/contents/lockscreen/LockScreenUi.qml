import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents

Rectangle {
    id: root
    color: "#0d1117"

    FontLoader { id: fontClock; source: "../fonts/Schulevetica-Regular.otf" }
    FontLoader { id: fontBold; source: "../fonts/SFUIText-Semibold.otf" }

    // Фон — наши обои (Orizon Lake)
    Image {
        anchors.fill: parent
        source: "../wallpapers/lake.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }

    // Тёмный оверлей
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d1117"; }
            GradientStop { position: 0.55; color: "#0d1117"; }
            GradientStop { position: 1.0; color: "#0d1117"; }
        }
        opacity: 0.55
    }

    // Центральная панель
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        // Логотип
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: "../images/orizon-logo.png"
            width: 84; height: 84
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.95
        }

        // Надпись LOCKED
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18
            text: "ЗАБЛОКИРОВАНО"
            color: "#8b949e"
            font.family: fontBold.name
            font.pixelSize: 12
            font.letterSpacing: 5
        }

        // Разделитель
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
            width: 300; height: 1
            color: "#30363d"
        }

        // Поле пароля
        TextField {
            id: passwordField
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.preferredWidth: 300
            Layout.preferredHeight: 46
            echoMode: TextInput.Password
            placeholderText: "Введи пароль..."
            placeholderTextColor: "#484f58"
            color: "#e6edf3"
            font.family: fontBold.name
            font.pixelSize: 14
            leftPadding: 16
            horizontalAlignment: TextInput.AlignHCenter
            background: Rectangle {
                color: "#161b22"
                border.color: passwordField.activeFocus ? "#00d4ff" : "#30363d"
                border.width: 1
                radius: 6
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
            Component.onCompleted: forceActiveFocus()
            Keys.onReturnPressed: unlockButton.clicked()
        }

        // Кнопка разблокировки
        Button {
            id: unlockButton
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            Layout.preferredWidth: 300
            Layout.preferredHeight: 46
            text: "РАЗБЛОКИРОВАТЬ"
            font.family: fontBold.name
            font.pixelSize: 12
            font.letterSpacing: 3
            font.weight: Font.Bold
            background: Rectangle {
                color: unlockButton.pressed ? "#0088cc" : (unlockButton.hovered ? "#33ddff" : "#00d4ff")
                radius: 6
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Text {
                text: unlockButton.text
                color: "#0d1117"
                font: unlockButton.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: authenticator.tryUnlock(passwordField.text)
        }
    }

    // Часы — снизу слева
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 48
        spacing: 4

        Text {
            id: clockTime
            color: "#e6edf3"
            font.family: fontClock.name
            font.pixelSize: 72
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clockTime.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }
        Text {
            id: clockDate
            color: "#8b949e"
            font.family: fontBold.name
            font.pixelSize: 16
            // Без года — только день недели, число и месяц
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
            Timer {
                interval: 60000; running: true; repeat: true
                onTriggered: clockDate.text = Qt.formatDate(new Date(), "dddd, d MMMM")
            }
        }
    }

    // Синяя линия снизу
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: "#00d4ff"
        opacity: 0.5
    }
}
