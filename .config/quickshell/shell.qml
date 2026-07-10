import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property color bg0: "#2d353b"
    readonly property color bg5: "#56635f"
    readonly property color fg: "#d3c6aa"
    readonly property color green: "#a7c080"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    OpenPrograms {
        id: openPrograms
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData

            screen: modelData
            color: root.bg0
            implicitHeight: 30
            exclusiveZone: 30

            anchors {
                left: true
                right: true
                top: true
            }

            Rectangle {
                anchors.fill: parent
                color: root.bg0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 15

                    StatusWidget {
                        text: ""
                        leftPadding: 15
                        rightPadding: 21
                    }

                    RowLayout {
                        id: workspaces
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: Hyprland.workspaces

                            Rectangle {
                                id: workspaceItem
                                required property HyprlandWorkspace modelData

                                readonly property list<QtObject> windows: modelData.toplevels.values
                                readonly property bool empty: windows.length === 0

                                implicitWidth: empty ? 32 : Math.max(32, windowIcons.implicitWidth + 16)
                                implicitHeight: 30
                                color: modelData.focused ? root.green : "transparent"
                                visible: modelData.id > 0

                                Text {
                                    id: workspaceText
                                    anchors.centerIn: parent
                                    visible: parent.empty
                                    text: modelData.name
                                    color: modelData.focused ? root.bg0 : root.fg
                                    font.family: root.fontFamily
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                RowLayout {
                                    id: windowIcons
                                    anchors.centerIn: parent
                                    visible: !parent.empty
                                    spacing: 3

                                    Repeater {
                                        model: workspaceItem.windows

                                        SymbolicAppIcon {
                                            required property HyprlandToplevel modelData

                                            size: 22
                                            color: workspaceItem.modelData.focused ? root.bg0 : root.fg
                                            symbol: openPrograms.symbolFor(modelData)
                                            shape: openPrograms.shapeFor(modelData)
                                            sourceOverride: openPrograms.sourceFor(modelData)
                                            regularIcon: openPrograms.iconFor(modelData)
                                            symbolicIcons: openPrograms.symbolicIconsFor(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    CommandWidget {
                        icon: ""
                        command: "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, \"\", $4); print $4 \"%\"}'"
                        fallback: "0%"
                        interval: 60000
                    }

                    StatusWidget {
                        text: {
                            const sink = Pipewire.defaultAudioSink;
                            if (sink == null || sink.audio == null)
                                return " 0%";

                            if (sink.audio.muted)
                                return "muted";

                            const icons = ["", "", ""];
                            const volume = Math.round(sink.audio.volume * 100);
                            const icon = icons[Math.min(2, Math.floor(volume / 34))];
                            return `${icon} ${volume}%`;
                        }

                        PwObjectTracker {
                            objects: Pipewire.defaultAudioSink == null ? [] : [Pipewire.defaultAudioSink]
                        }
                    }

                    CommandWidget {
                        icon: ""
                        command: "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print tolower($2); found=1} END {if (!found) print \"off\"}'"
                        fallback: "off"
                        interval: 30000
                    }

                    CommandWidget {
                        command: "nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | awk -F: '$1==\"wifi\" && $2==\"connected\" {print \" \" $3; found=1; exit} $1==\"ethernet\" && $2==\"connected\" {print \"\"; found=1; exit} END {if (!found) print \"󰤭\"}'"
                        fallback: "󰤭"
                        interval: 15000
                    }

                    CommandWidget {
                        command: "bat=BAT1; [ -d /sys/class/power_supply/$bat ] || bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -printf '%f\\n' 2>/dev/null | head -n1); [ -n \"$bat\" ] || exit 0; cap=$(cat /sys/class/power_supply/$bat/capacity 2>/dev/null); st=$(cat /sys/class/power_supply/$bat/status 2>/dev/null); [ -n \"$cap\" ] || exit 0; if [ \"$st\" = Charging ]; then printf '󰂄 %s%%\\n' \"$cap\"; elif [ \"$st\" = Full ]; then printf ' 100%%\\n'; else awk -v c=\"$cap\" 'BEGIN{split(\"󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅\",i,\" \"); n=int(c/10)+1; if(n>10)n=10; printf \"%s %d%%\\n\", i[n], c}'; fi"
                        fallback: "󰂑 0%"
                        interval: 60000
                    }

                    StatusWidget {
                        text: Qt.formatDateTime(clock.date, "HH:mm")

                        SystemClock {
                            id: clock
                            precision: SystemClock.Minutes
                        }
                    }

                    CommandWidget {
                        command: "hyprctl devices 2>/dev/null | awk -F': ' '/active keymap/ {v=tolower($2); if (v ~ /ukrainian|ua/) print \"ua\"; else print \"en\"; exit}'"
                        fallback: "en"
                        interval: 2000
                    }
                }
            }
        }
    }
}
