import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"

Column {
    id: page
    required property var ctl
    property var adapter: Bluetooth.defaultAdapter
    property bool active: ctl.page === "bluetooth"
    property bool btOn: adapter !== null && adapter.enabled
    width: 360
    spacing: 10
    enabled: active

    onActiveChanged: {
        if (!page.adapter) return
        page.adapter.discovering = page.active && page.adapter.enabled
    }

    function focusFirst() {
        header.focusBack()
    }

    function deviceIcon(d) {
        const i = d.icon || ""
        if (i.includes("headset") || i.includes("headphone")) return "\uf025"
        if (i.includes("audio") || i.includes("speaker")) return "\uf028"
        if (i.includes("keyboard")) return "\uf11c"
        if (i.includes("mouse")) return "\udb80\udf7d"
        if (i.includes("phone")) return "\uf10b"
        return "\uf293"
    }

    function deviceSub(d) {
        if (d.pairing) return "Pairing…"
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (d.connected) return "Connected" + (d.batteryAvailable ? "  ·  " + Math.round(d.battery * 100) + "%" : "")
        if (d.paired) return "Not connected"
        return "Click to pair"
    }

    function hasRealName(d) {
        return d.name !== "" && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name)
    }

    PageHeader {
        id: header
        title: "Bluetooth"
        toggleVisible: page.adapter !== null
        checked: page.btOn
        onBack: page.ctl.openPage("main")
        onToggled: {
            page.adapter.enabled = !page.adapter.enabled
            if (page.adapter.enabled) page.adapter.discovering = true
        }
    }

    Text {
        visible: page.adapter === null
        text: "No Bluetooth adapter found"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#a8a49a"
    }

    Text {
        visible: page.adapter !== null && !page.btOn
        text: "Bluetooth is off"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#a8a49a"
    }

    Text {
        visible: page.btOn
        topPadding: 4
        text: "My devices"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        color: "#727169"
    }

    Repeater {
        model: page.btOn ? page.adapter.devices : null

        DeviceRow {
            required property var modelData
            visible: modelData.paired
            icon: page.deviceIcon(modelData)
            title: modelData.name
            sub: page.deviceSub(modelData)
            active: modelData.connected
            busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            onRightClicked: modelData.forget()
        }
    }

    Item {
        visible: page.btOn
        width: 360
        height: 24

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: "Available devices"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: "#727169"
        }

        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: page.adapter !== null && page.adapter.discovering
            text: "Scanning…"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: "#727169"
        }
    }

    Repeater {
        model: page.btOn ? page.adapter.devices : null

        DeviceRow {
            id: newRow
            required property var modelData
            visible: !modelData.paired && page.hasRealName(modelData)
            icon: page.deviceIcon(modelData)
            title: modelData.name
            sub: page.deviceSub(modelData)
            busy: modelData.pairing
            onClicked: modelData.pair()

            Connections {
                target: newRow.modelData
                function onPairedChanged() {
                    if (newRow.modelData.paired) {
                        newRow.modelData.trusted = true
                        newRow.modelData.connect()
                    }
                }
            }
        }
    }

    Text {
        visible: page.btOn
        topPadding: 4
        text: "Right-click a device to forget it"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 10
        color: "#54546d"
    }
}
