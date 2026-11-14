import QtQuick

Item {
    id: header
    property string title
    property bool toggleVisible: false
    property bool checked: false
    signal back()
    signal toggled()

    width: 360
    height: 36

    function focusBack() {
        backBtn.forceActiveFocus()
    }

    Rectangle {
        id: backBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        radius: 16
        color: (backArea.containsMouse || activeFocus) ? "#363646" : "transparent"
        activeFocusOnTab: true

        Text {
            anchors.centerIn: parent
            text: "\uf053"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: "#dcd7ba"
        }

        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.back()
        }

        Keys.onReturnPressed: header.back()
        Keys.onEnterPressed: header.back()
        Keys.onSpacePressed: header.back()
        Keys.onLeftPressed: header.back()
    }

    Text {
        anchors.left: backBtn.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: "#dcd7ba"
    }

    ToggleSwitch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: header.toggleVisible
        checked: header.checked
        onToggled: header.toggled()
    }
}
