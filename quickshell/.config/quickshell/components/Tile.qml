import QtQuick

Rectangle {
    id: tile
    property string icon
    property string label
    property string sub
    property bool on: false
    property bool hasMenu: false
    signal toggled()

    width: 176
    height: 64
    radius: 14
    color: on ? "#7e9cd8" : ((tileArea.containsMouse || activeFocus) ? "#363646" : "#2a2a37")
    border.width: activeFocus ? 2 : 0
    border.color: "#dcd7ba"
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: tile.on ? "#1f1f28" : "#dcd7ba"
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: tile.label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: tile.on ? "#1f1f28" : "#dcd7ba"
            }

            Text {
                width: 100
                text: tile.sub
                elide: Text.ElideRight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: tile.on ? "#2a2a37" : "#a8a49a"
            }
        }
    }

    Text {
        visible: tile.hasMenu
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf054"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        color: tile.on ? "#1f1f28" : "#727169"
    }

    MouseArea {
        id: tileArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }

    Keys.onReturnPressed: tile.toggled()
    Keys.onEnterPressed: tile.toggled()
    Keys.onSpacePressed: tile.toggled()
    Keys.onRightPressed: if (tile.hasMenu) tile.toggled()
}
