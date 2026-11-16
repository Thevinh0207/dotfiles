import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pam
import Quickshell.Services.Mpris

Scope {
    id: root
    property string password: ""
    property bool failed: false

    property var player: {
        const list = Mpris.players.values
        for (const p of list) {
            if (p.identity.toLowerCase().includes("spotify")) return p
        }
        for (const p of list) {
            if (p.isPlaying) return p
        }
        for (const p of list) {
            if (p.trackTitle !== "") return p
        }
        return null
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

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
            property bool powerMenuOpen: false
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
                surface.powerMenuOpen = false
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
                    surface.powerMenuOpen = false
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

            Timer {
                interval: 1000
                running: sessionLock.locked && surface.awake && root.player !== null && root.player.isPlaying
                repeat: true
                onTriggered: root.player.positionChanged()
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
                brightness: surface.awake ? -0.3 : 0.0
                Behavior on blur { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on brightness { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: surface.awake ? Qt.ArrowCursor : Qt.BlankCursor
                onPositionChanged: surface.wake()
                onClicked: {
                    surface.powerMenuOpen = false
                    surface.wake()
                }
            }

            Column {
                id: centerColumn
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
                    color: "#c8c093"
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
                        Keys.onPressed: (event) => {
                            if (!surface.awake) {
                                surface.wake()
                                event.accepted = true
                                return
                            }
                            surface.wake()
                        }
                        Keys.onEscapePressed: {
                            if (surface.powerMenuOpen) {
                                surface.powerMenuOpen = false
                                return
                            }
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
                        color: root.failed ? "#e82424" : "#ccffffff"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: root.failed ? 2 : 1
                        color: root.failed ? "#e82424" : "#ccffffff"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            Rectangle {
                anchors.top: centerColumn.bottom
                anchors.topMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: lockMedia.implicitHeight + 24
                radius: 16
                color: "#e6181616"
                border.width: 1
                border.color: "#cc625e5a"
                visible: opacity > 0
                opacity: surface.awake && surface.confirmAction === "" && root.player !== null ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: surface.wake()
                }

                Row {
                    id: lockMedia
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 12

                    ClippingRectangle {
                        width: 64
                        height: 64
                        radius: 10
                        color: "#393836"

                        Image {
                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 128
                            sourceSize.height: 128
                            asynchronous: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !root.player || root.player.trackArtUrl === ""
                            text: "\uf001"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            color: "#727169"
                        }
                    }

                    Column {
                        width: 240
                        spacing: 5

                        Text {
                            width: parent.width
                            text: root.player && root.player.trackTitle !== "" ? root.player.trackTitle : "Unknown"
                            elide: Text.ElideRight
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#dcd7ba"
                        }

                        Text {
                            width: parent.width
                            text: root.player ? root.player.trackArtist : ""
                            elide: Text.ElideRight
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: "#c8c093"
                        }

                        Item {
                            width: parent.width
                            height: 14

                            Text {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                text: root.player ? root.formatTime(root.player.position) : "0:00"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: "#c8c093"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                text: root.player ? root.formatTime(root.player.length) : "0:00"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                color: "#c8c093"
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 2
                            color: "#cc625e5a"

                            Rectangle {
                                height: parent.height
                                radius: 2
                                color: "#c5c9c5"
                                width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Repeater {
                                model: [
                                    { icon: "\uf048", action: "previous" },
                                    { icon: "play", action: "toggle" },
                                    { icon: "\uf051", action: "next" }
                                ]

                                Rectangle {
                                    id: mediaBtn
                                    required property var modelData
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: mediaArea.containsMouse ? "#cc282727" : "transparent"
                                    border.width: 1
                                    border.color: mediaArea.containsMouse ? "#c5c9c5" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: mediaBtn.modelData.icon === "play" ? (root.player && root.player.isPlaying ? "\uf04c" : "\uf04b") : mediaBtn.modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: mediaArea.containsMouse ? "#c5c9c5" : "#dcd7ba"
                                    }

                                    MouseArea {
                                        id: mediaArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPositionChanged: surface.wake()
                                        onClicked: {
                                            surface.wake()
                                            if (!root.player) return
                                            if (mediaBtn.modelData.action === "previous") root.player.previous()
                                            else if (mediaBtn.modelData.action === "next") root.player.next()
                                            else root.player.togglePlaying()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 40
                anchors.bottomMargin: 36
                width: 160
                height: 40
                opacity: surface.awake && surface.confirmAction === "" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: powerMenu
                    anchors.right: parent.right
                    anchors.bottom: powerBtn.top
                    anchors.bottomMargin: 10
                    width: 160
                    height: menuColumn.implicitHeight + 12
                    radius: 14
                    color: "#e6181616"
                    border.width: 1
                    border.color: "#625e5a"
                    opacity: surface.powerMenuOpen ? 1 : 0
                    scale: surface.powerMenuOpen ? 1 : 0.92
                    transformOrigin: Item.BottomRight
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    Column {
                        id: menuColumn
                        anchors.centerIn: parent
                        width: parent.width - 12
                        spacing: 2

                        Repeater {
                            model: [
                                { icon: "\uf236", label: "Sleep", action: "suspend", accent: "#7fb4ca" },
                                { icon: "\uf01e", label: "Restart", action: "reboot", accent: "#e6c384" },
                                { icon: "\uf011", label: "Power off", action: "poweroff", accent: "#e46876" }
                            ]

                            Rectangle {
                                id: menuItem
                                required property var modelData
                                width: parent.width
                                height: 36
                                radius: 9
                                color: itemArea.containsMouse ? "#282727" : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: itemIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: menuItem.modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: itemArea.containsMouse ? menuItem.modelData.accent : "#c8c093"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    anchors.left: itemIcon.right
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: menuItem.modelData.label
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: itemArea.containsMouse ? menuItem.modelData.accent : "#dcd7ba"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    id: itemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPositionChanged: surface.wake()
                                    onClicked: surface.request(menuItem.modelData.action)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: powerBtn
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 40
                    height: 40
                    radius: 20
                    color: (powerArea.containsMouse || surface.powerMenuOpen) ? "#cc282727" : "#66181616"
                    border.width: 1
                    border.color: (powerArea.containsMouse || surface.powerMenuOpen) ? "#7fb4ca" : "#625e5a"
                    scale: powerArea.pressed ? 0.92 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf011"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: (powerArea.containsMouse || surface.powerMenuOpen) ? "#7fb4ca" : "#c8c093"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: surface.wake()
                        onClicked: {
                            surface.wake()
                            surface.powerMenuOpen = !surface.powerMenuOpen
                        }
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 420
                height: confirmColumn.implicitHeight + 48
                radius: 20
                color: "#e6181616"
                border.width: 1
                border.color: "#625e5a"
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
                        color: "#c8c093"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Rectangle {
                            width: 150
                            height: 36
                            radius: 18
                            color: cancelArea.containsMouse ? "#393836" : "#282727"
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
