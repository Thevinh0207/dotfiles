import QtQuick

Rectangle {
    id: btn
    property string icon
    property string label
    signal activated()

    width: 84
    height: 72
    radius: 14
    color: activeFocus ? "#7e9cd8" : (area.containsMouse ? "#363646" : "#2a2a37")
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: 150 } }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            color: btn.activeFocus ? "#1f1f28" : "#dcd7ba"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: btn.activeFocus ? "#1f1f28" : "#a8a49a"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }

    Keys.onReturnPressed: btn.activated()
    Keys.onEnterPressed: btn.activated()
    Keys.onSpacePressed: btn.activated()
}
