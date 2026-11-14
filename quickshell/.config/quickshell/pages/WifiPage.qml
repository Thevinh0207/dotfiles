import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Column {
    id: page
    required property var ctl
    property var networks: []
    property var known: []
    property string selected: ""
    property string statusSsid: ""
    property string status: ""
    property bool active: ctl.page === "wifi"
    readonly property var bars: ["\udb82\udd2f", "\udb82\udd1f", "\udb82\udd22", "\udb82\udd25", "\udb82\udd28"]
    width: 360
    spacing: 10
    enabled: active

    onActiveChanged: {
        if (!page.active) return
        page.selected = ""
        page.status = ""
        page.refresh()
        rescanProc.running = true
    }

    function focusFirst() {
        header.focusBack()
    }

    function refresh() {
        if (!listProc.running) listProc.running = true
        if (!knownProc.running) knownProc.running = true
    }

    function parse(text) {
        const map = {}
        for (const line of text.split("\n")) {
            const m = line.match(/^(\*?):(\d*):(.*?):(.*)$/)
            if (!m) continue
            const ssid = m[4].replace(/\\:/g, ":")
            if (ssid === "") continue
            const net = map[ssid] || { ssid: ssid, signal: 0, inUse: false, secure: false }
            net.signal = Math.max(net.signal, parseInt(m[2]) || 0)
            net.inUse = net.inUse || m[1] === "*"
            net.secure = net.secure || (m[3] !== "" && m[3] !== "--")
            map[ssid] = net
        }
        const out = Object.values(map)
        out.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
        page.networks = out
    }

    function run(cmd, ssid) {
        page.statusSsid = ssid
        page.status = "connecting"
        connectProc.command = cmd
        connectProc.running = true
    }

    function choose(net) {
        if (net.inUse) page.run(["nmcli", "connection", "down", "id", net.ssid], net.ssid)
        else if (page.known.includes(net.ssid)) page.run(["nmcli", "connection", "up", "id", net.ssid], net.ssid)
        else if (net.secure) page.selected = net.ssid
        else page.run(["nmcli", "dev", "wifi", "connect", net.ssid], net.ssid)
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: page.parse(this.text)
        }
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: page.known = this.text.split("\n").filter(s => s !== "")
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        onExited: page.refresh()
    }

    Process {
        id: connectProc
        onExited: (exitCode, exitStatus) => {
            page.status = exitCode === 0 ? "" : "failed"
            if (exitCode === 0) page.selected = ""
            page.refresh()
            page.ctl.refresh()
        }
    }

    Timer {
        id: rescanTimer
        interval: 2500
        onTriggered: rescanProc.running = true
    }

    PageHeader {
        id: header
        title: "WiFi"
        toggleVisible: true
        checked: page.ctl.wifiOn
        onBack: page.ctl.openPage("main")
        onToggled: {
            page.ctl.exec(["nmcli", "radio", "wifi", page.ctl.wifiOn ? "off" : "on"])
            page.ctl.wifiOn = !page.ctl.wifiOn
            if (page.ctl.wifiOn) rescanTimer.restart()
        }
    }

    Text {
        visible: !page.ctl.wifiOn
        text: "WiFi is off"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#a8a49a"
    }

    Item {
        visible: page.ctl.wifiOn
        width: 360
        height: 24

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: "Networks"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: "#727169"
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: rescanProc.running ? "Scanning…" : "Refresh"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: refreshArea.containsMouse ? "#7e9cd8" : "#727169"

            MouseArea {
                id: refreshArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (!rescanProc.running) rescanProc.running = true
            }
        }
    }

    Repeater {
        model: page.ctl.wifiOn ? page.networks : []

        Column {
            id: netItem
            required property var modelData
            property bool failed: page.status === "failed" && page.statusSsid === modelData.ssid
            width: 360
            spacing: 6

            DeviceRow {
                icon: page.bars[Math.min(4, Math.floor(netItem.modelData.signal / 25))]
                title: netItem.modelData.ssid
                sub: netItem.failed ? "Couldn't connect" : (netItem.modelData.inUse ? "Connected" : (netItem.modelData.secure ? "\uf023  Secured" : "Open"))
                subColor: netItem.failed ? "#e46876" : "#a8a49a"
                active: netItem.modelData.inUse
                busy: page.status === "connecting" && page.statusSsid === netItem.modelData.ssid
                onClicked: page.choose(netItem.modelData)
                onRightClicked: {
                    if (page.known.includes(netItem.modelData.ssid)) {
                        page.ctl.exec(["nmcli", "connection", "delete", "id", netItem.modelData.ssid])
                        page.refresh()
                    }
                }
            }

            Rectangle {
                visible: page.selected === netItem.modelData.ssid
                width: 360
                height: 44
                radius: 12
                color: "#2a2a37"
                border.width: 1
                border.color: "#54546d"

                TextInput {
                    id: pw
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: connectBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: "#dcd7ba"
                    onVisibleChanged: {
                        if (visible) {
                            text = ""
                            forceActiveFocus()
                        }
                    }
                    onAccepted: if (text !== "") page.run(["nmcli", "dev", "wifi", "connect", netItem.modelData.ssid, "password", text], netItem.modelData.ssid)
                    Keys.onEscapePressed: (event) => {
                        page.selected = ""
                        event.accepted = true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pw.text === ""
                        text: "Password"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#727169"
                    }
                }

                Rectangle {
                    id: connectBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 84
                    height: 30
                    radius: 15
                    color: connectArea.containsMouse ? "#8ba4e0" : "#7e9cd8"

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: "#1f1f28"
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (pw.text !== "") page.run(["nmcli", "dev", "wifi", "connect", netItem.modelData.ssid, "password", pw.text], netItem.modelData.ssid)
                    }
                }
            }
        }
    }

    DeviceRow {
        icon: "\uf013"
        title: "More settings"
        sub: "Open nmtui"
        onClicked: page.ctl.launch(["kitty", "-e", "nmtui"])
    }
}
