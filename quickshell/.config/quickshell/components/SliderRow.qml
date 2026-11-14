import QtQuick

Item {
    id: slider
    property string icon
    property int value: 0
    signal moved(int v)
    signal iconClicked()

    width: 360
    height: 32
    activeFocusOnTab: true

    Text {
        id: sliderIcon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        text: slider.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        color: "#dcd7ba"

        MouseArea {
            anchors.fill: parent
            onClicked: slider.iconClicked()
        }
    }

    Item {
        id: track
        anchors.left: sliderIcon.right
        anchors.leftMargin: 8
        anchors.right: valueText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: "#2a2a37"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * slider.value / 100
            height: 6
            radius: 3
            color: "#7e9cd8"
        }

        Rectangle {
            x: parent.width * slider.value / 100 - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: "#dcd7ba"
            border.width: slider.activeFocus ? 3 : 0
            border.color: "#7e9cd8"
        }

        MouseArea {
            id: trackArea
            anchors.fill: parent
            function setFromX(x) {
                slider.moved(Math.max(0, Math.min(100, Math.round(x / trackArea.width * 100))))
            }
            onPressed: (mouse) => setFromX(mouse.x)
            onPositionChanged: (mouse) => setFromX(mouse.x)
        }
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: slider.value + "%"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#a8a49a"
    }

    Keys.onLeftPressed: slider.moved(Math.max(0, slider.value - 5))
    Keys.onRightPressed: slider.moved(Math.min(100, slider.value + 5))
}
