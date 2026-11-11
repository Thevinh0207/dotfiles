import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: tabs
    property var groups: []
    property string lastText: ""

    function refresh() {
        if (!proc.running) proc.running = true
    }

    Process {
        id: proc
        command: ["sh", "-c", "~/.config/hypr/scripts/group-tabs.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === tabs.lastText) return
                tabs.lastText = this.text
                try {
                    tabs.groups = JSON.parse(this.text)
                } catch (e) {
                    tabs.groups = []
                }
            }
        }
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: tabs.refresh()
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: tabs.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            debounce.restart()
        }
    }

    Variants {
        model: tabs.groups

        PanelWindow {
            id: bar
            required property var modelData
            anchors {
                top: true
                left: true
            }
            margins {
            top: bar.modelData.y - 31
                left: bar.modelData.x
            }
            exclusiveZone: 0
            implicitWidth: bar.modelData.w
            implicitHeight: 24
            color: "transparent"

            Row {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: bar.modelData.tabs

                    Rectangle {
                        id: tab
                        required property var modelData
                        width: (bar.implicitWidth - 4 * (bar.modelData.tabs.length - 1)) / bar.modelData.tabs.length
                        height: 20
                        radius: 8
                        color: tab.modelData.active ? "#7e9cd8dd" : (tabArea.containsMouse ? "#363646dd" : "#2a2a37dd")

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                sourceSize.width: 14
                                sourceSize.height: 14
                                opacity: tab.modelData.active ? 1 : 0.6
                                source: {
                                    const entry = DesktopEntries.heuristicLookup(tab.modelData.class)
                                    return Quickshell.iconPath(entry ? entry.icon : tab.modelData.class, "application-x-executable")
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, tab.width - 40)
                                text: tab.modelData.title
                                elide: Text.ElideRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: tab.modelData.active
                                color: tab.modelData.active ? "#1f1f28" : "#a8a49a"
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ window = \"address:" + tab.modelData.address + "\" }))"])
                                debounce.restart()
                            }
                        }
                    }
                }
            }
        }
    }
}
