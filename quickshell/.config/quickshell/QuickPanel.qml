import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "pages"

Scope {
    id: qp
    property string page: "main"
    property int battery: 0
    property string batStatus: ""
    property int limit: 100
    property bool wifiOn: false
    property string ssid: ""
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
        for (const p of list) {
            if (p.isPlaying) return p
        }
        for (const p of list) {
            if (p.trackTitle !== "") return p
        }
        return null
    }

    function parse(text) {
        const lines = text.split("\n")
        for (const line of lines) {
            const i = line.indexOf("=")
            if (i < 0) continue
            const key = line.slice(0, i)
            const val = line.slice(i + 1)
            if (key === "battery") qp.battery = parseInt(val) || 0
            else if (key === "status") qp.batStatus = val
            else if (key === "limit") qp.limit = parseInt(val) || 100
            else if (key === "wifi") qp.wifiOn = val === "enabled"
            else if (key === "ssid") qp.ssid = val
            else if (key === "profile") qp.profile = val
            else if (key === "volume") qp.volume = parseInt(val) || 0
            else if (key === "muted") qp.muted = val === "yes"
            else if (key === "brightness") qp.brightness = parseInt(val) || 0
            else if (key === "dnd") qp.dnd = val === "on"
            else if (key === "night") qp.night = val === "on"
            else if (key === "night_strength") qp.nightStrength = parseInt(val) || 50
        }
    }

    function exec(cmd) {
        Quickshell.execDetached(cmd)
        refreshSoon.restart()
    }

    function refresh() {
        refreshSoon.restart()
    }

    function launch(cmd) {
        panel.visible = false
        Quickshell.execDetached(cmd)
    }

    function nightTemp() {
        return 6500 - qp.nightStrength * 35
    }

    function playVolumeSound() {
        volumeSound.restart()
    }

    function applyNight() {
        nightApply.restart()
    }

    function openPage(name) {
        qp.page = name
        focusTimer.restart()
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "~/.config/hypr/scripts/panel-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: qp.parse(this.text)
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
        running: panel.visible && qp.player !== null && qp.player.isPlaying
        repeat: true
        onTriggered: qp.player.positionChanged()
    }

    Timer {
        id: volumeSound
        interval: 150
        onTriggered: Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"])
    }

    Timer {
        id: nightApply
        interval: 300
        onTriggered: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/scripts/nightlight-set.sh " + qp.nightStrength])
    }

    Timer {
        id: focusTimer
        interval: 10
        onTriggered: {
            if (qp.page === "bluetooth") btPage.focusFirst()
            else if (qp.page === "wifi") wifiPage.focusFirst()
            else mainPage.focusFirst()
        }
    }

    PanelWindow {
        id: panel
        visible: false
        exclusiveZone: 0
        implicitWidth: 400
        implicitHeight: (qp.page === "bluetooth" ? btPage.implicitHeight : qp.page === "wifi" ? wifiPage.implicitHeight : mainPage.implicitHeight) + 40
        color: "transparent"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        onVisibleChanged: if (!visible) qp.page = "main"

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#1f1f28"
            border.color: "#54546d"
            border.width: 2
            clip: true

            FocusScope {
                anchors.fill: parent
                anchors.margins: 20
                focus: true
                Keys.onEscapePressed: {
                    if (qp.page !== "main") qp.openPage("main")
                    else panel.visible = false
                }

                Item {
                    id: track
                    width: 1160
                    height: parent.height
                    x: qp.page === "bluetooth" ? -400 : qp.page === "wifi" ? -800 : 0
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    MainPage {
                        id: mainPage
                        x: 0
                        ctl: qp
                    }

                    BluetoothPage {
                        id: btPage
                        x: 400
                        ctl: qp
                    }

                    WifiPage {
                        id: wifiPage
                        x: 800
                        ctl: qp
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "panel"

        function toggle(): void {
            panel.visible = !panel.visible
            if (panel.visible) qp.openPage("main")
        }
    }
}
