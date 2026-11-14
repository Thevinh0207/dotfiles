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
                root.failed = false
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
            property string pendingAction: ""
            property string confirmAction: ""
            property string openApps: ""

            function wake() {
                surface.awake = true
                sleepTimer.restart()
                input.forceActiveFocus()
            }

            function runAction(action) {
                surface.confirmAction = ""
                if (action === "suspend") Quickshell.execDetached(["systemctl", "suspend"])
                else if (action === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
                else if (action === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"])
            }

            function request(action) {
                surface.wake()
                if (action === "suspend") {
                    surface.runAction(action)
                    return
                }
                surface.pendingAction = action
                appsProc.running = true
            }

            Process {
                id: appsProc
                command: ["sh", "-c", "hyprctl clients -j | jq -r '[.[].class | select(. != \"\")] | unique | join(\", \")'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const apps = this.text.trim()
                        if (apps === "") {
                            surface.runAction(surface.pendingAction)
                        } else {
                            surface.openApps = apps
                            surface.confirmAction = surface.pendingAction
                        }
                    }
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
                    surface.confirmAction = ""
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
                source: "file:///home/vinh/.cache/current-wallpaper"
                cache: false
                fillMode: Image.PreserveAspectCrop
                playing: sessionLock.locked
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wallpaper
                blurEnabled: true
                blurMax: 32
                blur: surface.awake ? 0.3 : 0.0
                brightness: surface.awake ? -0.275 : 0.0
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
                opacity: surface.awake && surface.confirmAction === "" ? 1 : 0
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
                            surface.confirmAction = ""
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

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 40
                anchors.bottomMargin: 36
                spacing: 20
                opacity: surface.awake && surface.confirmAction === "" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Repeater {
                    model: [
                        { icon: "\uf236", label: "Sleep", action: "suspend" },
                        { icon: "\uf01e", label: "Restart", action: "reboot" },
                        { icon: "\uf011", label: "Power off", action: "poweroff" }
                    ]

                    Column {
                        id: powerButton
                        required property var modelData
                        spacing: 8

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 40
                            height: 40
                            radius: 20
                            color: powerArea.containsMouse ? "#1f1f28cc" : "#1f1f2840"
                            border.width: 1
                            border.color: powerArea.containsMouse ? "#7fb4ca" : "#72716999"
                            scale: powerArea.pressed ? 0.92 : 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: powerButton.modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: powerArea.containsMouse ? "#7fb4ca" : "#a8a49a"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: powerArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: surface.wake()
                                onClicked: surface.request(powerButton.modelData.action)
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: powerButton.modelData.label
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: "#dcd7ba"
                            opacity: powerArea.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 420
                height: confirmColumn.implicitHeight + 48
                radius: 20
                color: "#1f1f28e6"
                border.width: 1
                border.color: "#72716999"
                visible: surface.confirmAction !== ""

                Column {
                    id: confirmColumn
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 16

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: (surface.confirmAction === "reboot" ? "Restart" : "Power off") + " with apps still open?"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "#dcd7ba"
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: surface.openApps
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: "#a8a49a"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Rectangle {
                            width: 150
                            height: 36
                            radius: 18
                            color: cancelArea.containsMouse ? "#363646" : "#2a2a37"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: "#dcd7ba"
                            }

                            MouseArea {
                                id: cancelArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: surface.wake()
                                onClicked: surface.confirmAction = ""
                            }
                        }

                        Rectangle {
                            width: 150
                            height: 36
                            radius: 18
                            color: confirmArea.containsMouse ? "#e82424" : "#c34043"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: surface.confirmAction === "reboot" ? "Restart anyway" : "Power off anyway"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: confirmArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: surface.wake()
                                onClicked: surface.runAction(surface.confirmAction)
                            }
                        }
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
