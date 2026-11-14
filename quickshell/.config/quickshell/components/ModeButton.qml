import QtQuick

Rectangle {
    id: mode
    property string label
    property bool active: false
    signal activated()

    width: 114
    height: 40
    radius: 10
    color: active ? "#7e9cd8" : ((modeArea.containsMouse || activeFocus) ? "#363646" : "#2a2a37")
    border.width: activeFocus ? 2 : 0
    border.color: "#dcd7ba"
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: mode.label
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: mode.active ? "#1f1f28" : "#dcd7ba"
    }

    MouseArea {
        id: modeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mode.activated()
    }

    Keys.onReturnPressed: mode.activated()
    Keys.onEnterPressed: mode.activated()
    Keys.onSpacePressed: mode.activated()
}
