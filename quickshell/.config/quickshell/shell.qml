import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris

ShellRoot {
    id: root
    Lock {}
    TabBars {}

    property int battery: 0
    property string batStatus: ""
    property int limit: 100
    property bool wifiOn: false
    property string ssid: ""
    property bool btOn: false
    property string profile: "balanced"
    property int volume: 0
    property bool muted: false
    property int brightness: 0
    property bool dnd: false
    property bool night: false
    property int nightStrength: 50

    property var player: {
        const list = Mpris.players.values
        for (const p of list) {
            if (p.identity.toLowerCase().includes("spotify")) return p
        }
        return list.length > 0 ? list[0] : null
    }

    function parse(text) {
        const lines = text.split("\n")
        for (const line of lines) {
            const i = line.indexOf("=")
            if (i < 0) continue
            const key = line.slice(0, i)
            const val = line.slice(i + 1)
            if (key === "battery") root.battery = parseInt(val) || 0
            else if (key === "status") root.batStatus = val
            else if (key === "limit") root.limit = parseInt(val) || 100
            else if (key === "wifi") root.wifiOn = val === "enabled"
            else if (key === "ssid") root.ssid = val
            else if (key === "bluetooth") root.btOn = val === "on"
            else if (key === "profile") root.profile = val
            else if (key === "volume") root.volume = parseInt(val) || 0
            else if (key === "muted") root.muted = val === "yes"
            else if (key === "brightness") root.brightness = parseInt(val) || 0
            else if (key === "dnd") root.dnd = val === "on"
            else if (key === "night") root.night = val === "on"
            else if (key === "night_strength") root.nightStrength = parseInt(val) || 50
        }
    }

    function exec(cmd) {
        Quickshell.execDetached(cmd)
        refreshSoon.restart()
    }

    function launch(cmd) {
        panel.visible = false
        Quickshell.execDetached(cmd)
    }

    function nightTemp() {
        return 6500 - root.nightStrength * 35
    }

    function formatTime(seconds) {
        const s = Math.max(0, Math.floor(seconds))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "~/.config/hypr/scripts/panel-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: panel.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Timer {
        id: refreshSoon
        interval: 400
        onTriggered: statusProc.running = true
    }

    Timer {
        interval: 1000
        running: panel.visible && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Timer {
        id: volumeSound
        interval: 150
        onTriggered: Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"])
    }

    Timer {
        id: nightApply
        interval: 300
        onTriggered: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/nightlight-set.sh " + root.nightStrength])
    }

    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        property string sub
        property bool on: false
        property bool hasMenu: false
        signal toggled()
        signal menu()

        width: 176
        height: 64
        radius: 14
        color: on ? "#7e9cd8" : (tileArea.containsMouse ? "#363646" : "#2a2a37")
        border.width: activeFocus ? 2 : 0
        border.color: "#dcd7ba"
        activeFocusOnTab: true

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

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: tile.toggled()
        }

        Rectangle {
            visible: tile.hasMenu
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 36
            radius: 14
            color: menuArea.containsMouse ? "#00000030" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uf054"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: tile.on ? "#1f1f28" : "#a8a49a"
            }

            MouseArea {
                id: menuArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: tile.menu()
            }
        }

        Keys.onReturnPressed: tile.toggled()
        Keys.onEnterPressed: tile.toggled()
        Keys.onSpacePressed: tile.toggled()
        Keys.onRightPressed: if (tile.hasMenu) tile.menu()
    }

    component ModeButton: Rectangle {
        id: mode
        property string label
        property bool active: false
        signal activated()

        width: 114
        height: 40
        radius: 10
        color: active ? "#7e9cd8" : (modeArea.containsMouse ? "#363646" : "#2a2a37")
        border.width: activeFocus ? 2 : 0
        border.color: "#dcd7ba"
        activeFocusOnTab: true

        Text {
            anchors.centerIn: parent
            text: mode.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: mode.active ? "#1f1f28" : "#dcd7ba"
        }

        MouseArea {
            id: modeArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mode.activated()
        }

        Keys.onReturnPressed: mode.activated()
        Keys.onEnterPressed: mode.activated()
        Keys.onSpacePressed: mode.activated()
    }

    component MediaButton: Rectangle {
        id: mbtn
        property string icon
        signal activated()

        width: 36
        height: 36
        radius: 18
        color: activeFocus ? "#7e9cd8" : (mArea.containsMouse ? "#363646" : "transparent")
        activeFocusOnTab: true

        Text {
            anchors.centerIn: parent
            text: mbtn.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: mbtn.activeFocus ? "#1f1f28" : "#dcd7ba"
        }

        MouseArea {
            id: mArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mbtn.activated()
        }

        Keys.onReturnPressed: mbtn.activated()
        Keys.onEnterPressed: mbtn.activated()
        Keys.onSpacePressed: mbtn.activated()
    }

    component PowerButton: Rectangle {
        id: btn
        property string icon
        property string label
        signal activated()

        width: 84
        height: 72
        radius: 14
        color: activeFocus ? "#7e9cd8" : (area.containsMouse ? "#363646" : "#2a2a37")
        activeFocusOnTab: true

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: btn.activeFocus ? "#1f1f28" : "#dcd7ba"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: btn.activeFocus ? "#1f1f28" : "#a8a49a"
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.activated()
        }

        Keys.onReturnPressed: btn.activated()
        Keys.onEnterPressed: btn.activated()
        Keys.onSpacePressed: btn.activated()
    }

    PanelWindow {
        id: panel
        visible: false
        exclusiveZone: 0
        implicitWidth: 400
        implicitHeight: content.implicitHeight + 44
        color: "transparent"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#1f1f28"
            border.color: "#54546d"
            border.width: 2

            FocusScope {
                anchors.fill: parent
                anchors.margins: 20
                Keys.onEscapePressed: panel.visible = false

                Column {
                    id: content
                    width: 360
                    spacing: 16

                    Row {
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.batStatus === "Charging" ? "\uf0e7" : "\uf240"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            color: "#dcd7ba"
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: root.battery + "%"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 26
                                color: "#dcd7ba"
                            }

                            Text {
                                text: root.batStatus + (root.limit <= 80 ? "  ·  limit " + root.limit + "%" : "")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: "#a8a49a"
                            }
                        }
                    }

                    Rectangle {
                        visible: root.player !== null
                        width: 360
                        height: mediaRow.implicitHeight + 24
                        radius: 14
                        color: "#2a2a37"

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
                                    source: root.player ? root.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 144
                                    sourceSize.height: 144
                                    asynchronous: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !root.player || root.player.trackArtUrl === ""
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
                                        width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        anchors.left: parent.left
                                        text: root.player ? root.formatTime(root.player.position) : "0:00"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: "#a8a49a"
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        text: root.player ? root.formatTime(root.player.length) : "0:00"
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
                                        onActivated: if (root.player) root.player.previous()
                                    }

                                    MediaButton {
                                        icon: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                                        onActivated: if (root.player) root.player.togglePlaying()
                                    }

                                    MediaButton {
                                        icon: "\uf051"
                                        onActivated: if (root.player) root.player.next()
                                    }
                                }
                            }
                        }
                    }

                    Grid {
                        columns: 2
                        spacing: 8

                        Tile {
                            id: wifiTile
                            icon: "\udb82\udd28"
                            label: "WiFi"
                            sub: root.wifiOn ? (root.ssid !== "" ? root.ssid : "Not connected") : "Off"
                            on: root.wifiOn
                            hasMenu: true
                            onToggled: root.launch(["sh", "-c", "~/.config/hypr/scripts/wifi-menu.sh"])
                            onMenu: root.launch(["sh", "-c", "~/.config/hypr/scripts/wifi-menu.sh"])
                        }

                        Tile {
                            icon: "\uf293"
                            label: "Bluetooth"
                            sub: root.btOn ? "On" : "Off"
                            on: root.btOn
                            hasMenu: true
                            onToggled: root.launch(["blueman-manager"])
                            onMenu: root.launch(["blueman-manager"])
                        }

                        Tile {
                            icon: "\uf186"
                            label: "Night light"
                            sub: root.night ? "On" : "Off"
                            on: root.night
                            onToggled: {
                                if (root.night) root.exec(["pkill", "-x", "hyprsunset"])
                                else root.exec(["hyprsunset", "-t", String(root.nightTemp())])
                                root.night = !root.night
                            }
                        }

                        Tile {
                            icon: "\uf1f6"
                            label: "Do not disturb"
                            sub: root.dnd ? "On" : "Off"
                            on: root.dnd
                            onToggled: {
                                root.exec(["makoctl", "mode", "-t", "do-not-disturb"])
                                root.dnd = !root.dnd
                            }
                        }

                        Tile {
                            icon: "\uf240"
                            label: "Charge limit"
                            sub: root.limit <= 80 ? root.limit + "%" : "Off"
                            on: root.limit <= 80
                            onToggled: root.exec(["sh", "-c", "~/.config/hypr/scripts/battery-limit.sh"])
                        }
                    }

                    Row {
                        spacing: 9

                        ModeButton {
                            label: "Saver"
                            active: root.profile === "power-saver"
                            onActivated: {
                                root.exec(["powerprofilesctl", "set", "power-saver"])
                                root.profile = "power-saver"
                            }
                        }

                        ModeButton {
                            label: "Balanced"
                            active: root.profile === "balanced"
                            onActivated: {
                                root.exec(["powerprofilesctl", "set", "balanced"])
                                root.profile = "balanced"
                            }
                        }

                        ModeButton {
                            label: "Performance"
                            active: root.profile === "performance"
                            onActivated: {
                                root.exec(["powerprofilesctl", "set", "performance"])
                                root.profile = "performance"
                            }
                        }
                    }

                    Column {
                        spacing: 8

                        SliderRow {
                            icon: root.muted ? "\uf026" : "\uf028"
                            value: root.volume
                            onMoved: (v) => {
                                root.volume = v
                                root.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v + "%"])
                                volumeSound.restart()
                            }
                            onIconClicked: {
                                root.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                                root.muted = !root.muted
                            }
                        }

                        SliderRow {
                            icon: "\udb81\udda8"
                            value: root.brightness
                            onMoved: (v) => {
                                root.brightness = v
                                root.exec(["brightnessctl", "set", v + "%"])
                            }
                        }

                        SliderRow {
                            visible: root.night
                            icon: "\uf186"
                            value: root.nightStrength
                            onMoved: (v) => {
                                root.nightStrength = v
                                nightApply.restart()
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        PowerButton {
                            icon: "\uf023"
                            label: "Lock"
                            onActivated: root.launch(["loginctl", "lock-session"])
                        }

                        PowerButton {
                            icon: "\uf236"
                            label: "Sleep"
                            onActivated: root.launch(["systemctl", "suspend"])
                        }

                        PowerButton {
                            icon: "\uf021"
                            label: "Reboot"
                            onActivated: root.launch(["systemctl", "reboot"])
                        }

                        PowerButton {
                            icon: "\uf011"
                            label: "Power"
                            onActivated: root.launch(["systemctl", "poweroff"])
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "panel"

        function toggle(): void {
            panel.visible = !panel.visible
            if (panel.visible) wifiTile.forceActiveFocus()
        }
    }
}
