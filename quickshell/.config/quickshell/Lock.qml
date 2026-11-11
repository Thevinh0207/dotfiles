import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root
    property string password: ""
    property bool failed: false
    property int lastIndex: -1

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
                root.failed = false
                root.failed = true
            }
        }
    }

    FolderListModel {
        id: images
        folder: "file:///home/vinh/Pictures/lockscreen"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif"]
        showDirs: false
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

            function pickImage() {
                if (images.count === 0) return
                let i = Math.floor(Math.random() * images.count)
                if (images.count > 1 && i === root.lastIndex) i = (i + 1) % images.count
                root.lastIndex = i
                wallpaper.source = images.get(i, "fileUrl")
            }

            Component.onCompleted: surface.pickImage()

            Connections {
                target: images
                function onCountChanged() {
                    if (wallpaper.source == "") surface.pickImage()
                }
            }

            Connections {
                target: root
                function onFailedChanged() {
                    if (root.failed) {
                        surface.wake()
                        shake.restart()
                    }
                }
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

            AnimatedImage {
                id: wallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                playing: sessionLock.locked
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wallpaper
                blurEnabled: true
                blurMax: 64
                blur: surface.awake ? 0.5 : 0.0
                brightness: surface.awake ? -0.15 : 0.0
                Behavior on blur { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on brightness { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: surface.awake ? Qt.ArrowCursor : Qt.BlankCursor
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
                    id: passwordBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 260
                    height: 40

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -10; duration: 70 }
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -5; duration: 60 }
                        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
                    }

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
                            if (input.text !== "") root.failed = false
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
                        color: root.failed ? "#e82424" : "#ffffffcc"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: root.failed ? 2 : 1
                        color: root.failed ? "#e82424" : "#ffffffcc"
                        Behavior on color { ColorAnimation { duration: 150 } }
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
