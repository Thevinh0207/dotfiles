import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    signal toggled()

    width: 40
    height: 22
    radius: 11
    color: checked ? "#7e9cd8" : "#363646"
    border.width: activeFocus ? 2 : 0
    border.color: "#dcd7ba"
    activeFocusOnTab: true
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        y: 3
        x: sw.checked ? sw.width - width - 3 : 3
        color: sw.checked ? "#1f1f28" : "#a8a49a"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled()
    }

    Keys.onReturnPressed: sw.toggled()
    Keys.onEnterPressed: sw.toggled()
    Keys.onSpacePressed: sw.toggled()
}
