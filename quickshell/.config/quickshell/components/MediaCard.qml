import QtQuick
import Quickshell.Widgets

Rectangle {
    id: card
    property var player: null

    width: 360
    height: mediaRow.implicitHeight + 24
    radius: 14
    color: "#2a2a37"

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    Row {
        id: mediaRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            width: 72
            height: 72
            radius: 10
            color: "#363646"

            Image {
                anchors.fill: parent
                source: card.player ? card.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 144
                sourceSize.height: 144
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: !card.player || card.player.trackArtUrl === ""
                text: "\uf001"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 24
                color: "#727169"
            }
        }

        Column {
            width: 252
            spacing: 6

            Text {
                width: parent.width
                text: card.player && card.player.trackTitle !== "" ? card.player.trackTitle : "Unknown"
                elide: Text.ElideRight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: "#dcd7ba"
            }

            Text {
                width: parent.width
                text: card.player ? card.player.trackArtist : ""
                elide: Text.ElideRight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: "#a8a49a"
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: "#363646"

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: "#7e9cd8"
                    width: card.player && card.player.length > 0 ? parent.width * Math.min(1, card.player.position / card.player.length) : 0
                }
            }

            Item {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    text: card.player ? card.formatTime(card.player.position) : "0:00"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: "#a8a49a"
                }

                Text {
                    anchors.right: parent.right
                    text: card.player ? card.formatTime(card.player.length) : "0:00"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: "#a8a49a"
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                MediaButton {
                    icon: "\uf048"
                    onActivated: if (card.player) card.player.previous()
                }

                MediaButton {
                    icon: card.player && card.player.isPlaying ? "\uf04c" : "\uf04b"
                    onActivated: if (card.player) card.player.togglePlaying()
                }

                MediaButton {
                    icon: "\uf051"
                    onActivated: if (card.player) card.player.next()
                }
            }
        }
    }
}
