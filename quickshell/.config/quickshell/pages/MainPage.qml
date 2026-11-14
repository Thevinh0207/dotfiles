import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"

Column {
    id: page
    required property var ctl
    width: 360
    spacing: 16
    enabled: ctl.page === "main"

    property string btSub: {
        const a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) return "Off"
        for (const d of a.devices.values) {
            if (d.connected) return d.name
        }
        return "On"
    }

    function focusFirst() {
        wifiTile.forceActiveFocus()
    }

    Row {
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: page.ctl.batStatus === "Charging" ? "\uf0e7" : "\uf240"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 28
            color: "#dcd7ba"
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: page.ctl.battery + "%"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 26
                color: "#dcd7ba"
            }

            Text {
                text: page.ctl.batStatus + (page.ctl.limit <= 80 ? "  ·  limit " + page.ctl.limit + "%" : "")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: "#a8a49a"
            }
        }
    }

    MediaCard {
        visible: page.ctl.player !== null
        player: page.ctl.player
    }

    Grid {
        columns: 2
        spacing: 8

        Tile {
            id: wifiTile
            icon: "\udb82\udd28"
            label: "WiFi"
            sub: page.ctl.wifiOn ? (page.ctl.ssid !== "" ? page.ctl.ssid : "Not connected") : "Off"
            on: page.ctl.wifiOn
            hasMenu: true
            onToggled: page.ctl.openPage("wifi")
        }

        Tile {
            icon: "\uf293"
            label: "Bluetooth"
            sub: page.btSub
            on: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
            hasMenu: true
            onToggled: page.ctl.openPage("bluetooth")
        }

        Tile {
            icon: "\uf186"
            label: "Night light"
            sub: page.ctl.night ? "On" : "Off"
            on: page.ctl.night
            onToggled: {
                if (page.ctl.night) page.ctl.exec(["pkill", "-x", "hyprsunset"])
                else page.ctl.exec(["hyprsunset", "-t", String(page.ctl.nightTemp())])
                page.ctl.night = !page.ctl.night
            }
        }

        Tile {
            icon: "\uf1f6"
            label: "Do not disturb"
            sub: page.ctl.dnd ? "On" : "Off"
            on: page.ctl.dnd
            onToggled: {
                page.ctl.exec(["makoctl", "mode", "-t", "do-not-disturb"])
                page.ctl.dnd = !page.ctl.dnd
            }
        }

        Tile {
            icon: "\uf240"
            label: "Charge limit"
            sub: page.ctl.limit <= 80 ? page.ctl.limit + "%" : "Off"
            on: page.ctl.limit <= 80
            onToggled: page.ctl.exec(["sh", "-c", "~/.config/hypr/scripts/battery-limit.sh"])
        }
    }

    Row {
        spacing: 9

        ModeButton {
            label: "Saver"
            active: page.ctl.profile === "power-saver"
            onActivated: {
                page.ctl.exec(["powerprofilesctl", "set", "power-saver"])
                page.ctl.profile = "power-saver"
            }
        }

        ModeButton {
            label: "Balanced"
            active: page.ctl.profile === "balanced"
            onActivated: {
                page.ctl.exec(["powerprofilesctl", "set", "balanced"])
                page.ctl.profile = "balanced"
            }
        }

        ModeButton {
            label: "Performance"
            active: page.ctl.profile === "performance"
            onActivated: {
                page.ctl.exec(["powerprofilesctl", "set", "performance"])
                page.ctl.profile = "performance"
            }
        }
    }

    Column {
        spacing: 8

        SliderRow {
            icon: page.ctl.muted ? "\uf026" : "\uf028"
            value: page.ctl.volume
            onMoved: (v) => {
                page.ctl.volume = v
                page.ctl.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v + "%"])
                page.ctl.playVolumeSound()
            }
            onIconClicked: {
                page.ctl.exec(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                page.ctl.muted = !page.ctl.muted
            }
        }

        SliderRow {
            icon: "\udb81\udda8"
            value: page.ctl.brightness
            onMoved: (v) => {
                page.ctl.brightness = v
                page.ctl.exec(["brightnessctl", "set", v + "%"])
            }
        }

        SliderRow {
            visible: page.ctl.night
            icon: "\uf186"
            value: page.ctl.nightStrength
            onMoved: (v) => {
                page.ctl.nightStrength = v
                page.ctl.applyNight()
            }
        }
    }

    Row {
        spacing: 8

        PowerButton {
            icon: "\uf023"
            label: "Lock"
            onActivated: page.ctl.launch(["loginctl", "lock-session"])
        }

        PowerButton {
            icon: "\uf236"
            label: "Sleep"
            onActivated: page.ctl.launch(["systemctl", "suspend"])
        }

        PowerButton {
            icon: "\uf021"
            label: "Reboot"
            onActivated: page.ctl.launch(["systemctl", "reboot"])
        }

        PowerButton {
            icon: "\uf011"
            label: "Power"
            onActivated: page.ctl.launch(["systemctl", "poweroff"])
        }
    }
}
