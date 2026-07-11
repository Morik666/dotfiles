import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property color bg0: "#2d353b"
    readonly property color bg5: "#56635f"
    readonly property color fg: "#d3c6aa"
    readonly property color green: "#a7c080"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"
    property bool rightSidebarOpen: false
    property int rightSidebarInitialTab: 1
    property bool launcherOpen: false

    function openRightSidebar(tab: int): void {
        rightSidebarInitialTab = tab;
        rightSidebarOpen = true;
        if (tab === 0)
            notificationService.markAllRead();
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
        }

        function open(): void {
            root.launcherOpen = true;
        }

        function close(): void {
            root.launcherOpen = false;
        }
    }

    NotificationService {
        id: notificationService
        sidebarOpen: root.rightSidebarOpen
    }

    OpenPrograms {
        id: openPrograms
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.launcherOpen
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }

            Launcher {
                anchors.fill: parent
                open: root.launcherOpen
                openPrograms: openPrograms
                bg0: root.bg0
                bg5: root.bg5
                fg: root.fg
                green: root.green
                fontFamily: root.fontFamily
                onCloseRequested: root.launcherOpen = false
            }
        }
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
                        clickable: true
                        onClicked: root.launcherOpen = !root.launcherOpen
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

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: workspaceSwitcher.exec(["hyprctl", "dispatch", "workspace", String(workspaceItem.modelData.id)])
                                }

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

                                        BarAppIcon {
                                            required property HyprlandToplevel modelData

                                            size: 22
                                            color: workspaceItem.modelData.focused ? root.bg0 : root.fg
                                            symbol: openPrograms.symbolFor(modelData)
                                            shape: openPrograms.shapeFor(modelData)
                                            sourceOverride: openPrograms.sourceFor(modelData)
                                            regularIcon: openPrograms.iconFor(modelData)
                                        }
                                    }
                                }

                                Process {
                                    id: workspaceSwitcher
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
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

                    CommandWidget {
                        command: "hyprctl devices 2>/dev/null | awk -F': ' '/active keymap/ {v=tolower($2); if (v ~ /ukrainian|ua/) print \"ua\"; else print \"en\"; exit}'"
                        fallback: "en"
                        interval: 2000
                    }

                    BarStatusGroup {
                        notifications: notificationService.unread
                        onCalendarClicked: root.openRightSidebar(1)
                        onNotificationsClicked: root.openRightSidebar(0)
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: rightSidebarWindow
            required property var modelData

            screen: modelData
            visible: root.rightSidebarOpen
            color: "transparent"
            exclusiveZone: 0

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.rightSidebarOpen = false
            }

            Item {
                anchors {
                    top: parent.top
                    right: parent.right
                    bottom: parent.bottom
                }
                width: sidebar.implicitWidth

                MouseArea {
                    anchors.fill: parent
                }

                RightSidebar {
                    id: sidebar
                    anchors.fill: parent
                    open: root.rightSidebarOpen
                    initialTab: root.rightSidebarInitialTab
                    notificationService: notificationService
                    onCloseRequested: root.rightSidebarOpen = false
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: notificationService.popupList.length > 0
            color: "transparent"
            implicitWidth: 360
            implicitHeight: popupStack.implicitHeight
            exclusiveZone: 0

            anchors {
                top: true
                right: true
            }

            margins {
                top: 42
                right: 12
            }

            NotificationPopupStack {
                id: popupStack
                anchors.fill: parent
                notificationService: notificationService
            }
        }
    }
}
