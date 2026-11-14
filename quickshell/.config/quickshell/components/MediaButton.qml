import QtQuick

Rectangle {
    id: mbtn
    property string icon
    signal activated()

    width: 36
    height: 36
    radius: 18
    color: activeFocus ? "#7e9cd8" : (mArea.containsMouse ? "#363646" : "transparent")
    activeFocusOnTab: true

    Text {
        anchors.centerIn: parent
        text: mbtn.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: mbtn.activeFocus ? "#1f1f28" : "#dcd7ba"
    }

    MouseArea {
        id: mArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mbtn.activated()
    }

    Keys.onReturnPressed: mbtn.activated()
    Keys.onEnterPressed: mbtn.activated()
    Keys.onSpacePressed: mbtn.activated()
}
