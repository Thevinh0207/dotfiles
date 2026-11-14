import QtQuick

Rectangle {
    id: row
    property string icon
    property string title
    property string sub
    property color subColor: "#a8a49a"
    property bool active: false
    property bool busy: false
    signal clicked()
    signal rightClicked()

    width: 360
    height: 52
    radius: 12
    color: active ? "#7e9cd826" : ((area.containsMouse || activeFocus) ? "#363646" : "#2a2a37")
    border.width: activeFocus ? 2 : (active ? 1 : 0)
    border.color: activeFocus ? "#dcd7ba" : "#7e9cd8"
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        horizontalAlignment: Text.AlignHCenter
        text: row.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: row.active ? "#7e9cd8" : "#dcd7ba"
    }

    Column {
        anchors.left: iconText.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 44
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: row.title
            elide: Text.ElideRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: "#dcd7ba"
        }

        Text {
            width: parent.width
            visible: row.sub !== ""
            text: row.sub
            elide: Text.ElideRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: row.subColor
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: row.busy
        text: "\uf110"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        color: "#7e9cd8"
        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            running: row.busy
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: !row.busy && row.active
        text: "\uf00c"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        color: "#7e9cd8"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) row.rightClicked()
            else row.clicked()
        }
    }

    Keys.onReturnPressed: row.clicked()
    Keys.onEnterPressed: row.clicked()
    Keys.onSpacePressed: row.clicked()
    Keys.onDeletePressed: row.rightClicked()
}
