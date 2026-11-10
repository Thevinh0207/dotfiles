import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root
    property string password: ""
    property bool failed: false

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"
        onResponseRequiredChanged: {
            if (responseRequired) respond(root.password)
        }
        onCompleted: (result) => {
            root.password = ""
            if (result === PamResult.Success) {
                root.failed = false
                sessionLock.locked = false
            } else {
                root.failed = true
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: surface
            color: "black"
            property bool awake: false
            property string timeText: ""
            property string dateText: ""

            function wake() {
                surface.awake = true
                sleepTimer.restart()
                input.forceActiveFocus()
            }

            Timer {
                id: sleepTimer
                interval: 8000
                onTriggered: {
                    surface.awake = false
                    input.text = ""
                    root.failed = false
                }
            }

            Timer {
                interval: 1000
                running: sessionLock.locked
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    const now = new Date()
                    surface.timeText = Qt.formatDateTime(now, "HH:mm")
                    surface.dateText = Qt.formatDateTime(now, "dddd d MMMM")
                }
            }

            Image {
                id: wallpaper
                anchors.fill: parent
                source: "file:///home/vinh/Pictures/wallpaper.jpg"
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wallpaper
                blurEnabled: true
                blurMax: 64
                blur: surface.awake ? 1.0 : 0.0
                brightness: surface.awake ? -0.3 : 0.0
                Behavior on blur { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on brightness { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: surface.wake()
                onClicked: surface.wake()
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                opacity: surface.awake ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: surface.timeText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 96
                    color: "#dcd7ba"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: surface.dateText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: "#a8a49a"
                }

                Item {
                    width: 1
                    height: 24
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 260
                    height: 40

                    TextInput {
                        id: input
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        cursorVisible: false
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.letterSpacing: 4
                        color: "#dcd7ba"
                        focus: true
                        onTextChanged: {
                            surface.wake()
                            root.failed = false
                        }
                        Keys.onPressed: (event) => surface.wake()
                        Keys.onEscapePressed: {
                            input.text = ""
                            surface.awake = false
                        }
                        onAccepted: {
                            if (input.text === "" || pam.active) return
                            root.password = input.text
                            input.text = ""
                            pam.start()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: input.text === ""
                        text: root.failed ? "Wrong password" : "Enter password"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: root.failed ? "#c34043aa" : "#ffffffcc"
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 1
                        color: root.failed ? "#c34043aa" : "#ffffffcc"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            sessionLock.locked = true
        }
    }
}
