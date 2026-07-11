import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool open: false
    property int initialTab: 1
    property var notificationService: null
    signal closeRequested()

    readonly property color bg0: "#2d353b"
    readonly property color bg1: "#343f44"
    readonly property color bg2: "#3d484d"
    readonly property color bg5: "#56635f"
    readonly property color fg: "#d3c6aa"
    readonly property color dim: "#859289"
    readonly property color green: "#a7c080"
    readonly property color red: "#e67e80"
    readonly property color yellow: "#dbbc7f"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    property int selectedTab: 0
    property int brightness: 0
    property string uptime: "0h 0m"

    implicitWidth: 390
    implicitHeight: parent?.height ?? 720

    Component.onCompleted: {
        refreshUptime();
        refreshBrightness();
    }

    onOpenChanged: {
        if (open) {
            selectedTab = initialTab;
            refreshUptime();
            refreshBrightness();
        }
    }

    onInitialTabChanged: {
        if (open)
            selectedTab = initialTab;
    }

    function refreshUptime(): void {
        uptimeReader.exec(["sh", "-c", "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); if (d>0) printf \"%dd %dh %dm\", d, h, m; else printf \"%dh %dm\", h, m}' /proc/uptime"]);
    }

    function refreshBrightness(): void {
        brightnessReader.exec(["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, \"\", $4); print int($4)}'"]);
    }

    Process {
        id: uptimeReader
        stdout: StdioCollector {
            onStreamFinished: {
                const value = this.text.trim();
                if (value.length > 0)
                    root.uptime = value;
            }
        }
    }

    Process {
        id: brightnessReader
        stdout: StdioCollector {
            onStreamFinished: {
                const value = Number(this.text.trim());
                if (!isNaN(value))
                    root.brightness = Math.max(0, Math.min(100, value));
            }
        }
    }

    Process {
        id: brightnessSetter
    }

    Process {
        id: powerRunner
    }

    Timer {
        interval: 60000
        running: root.open
        repeat: true
        onTriggered: root.refreshUptime()
    }

    Timer {
        interval: 30000
        running: root.open
        repeat: true
        onTriggered: root.refreshBrightness()
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg0
        border.width: 1
        border.color: root.bg5

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 38
                Layout.minimumHeight: 38
                Layout.maximumHeight: 38
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: root.bg1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: ""
                            color: root.green
                            font.family: root.fontFamily
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: `Up ${root.uptime}`
                            color: root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    id: powerButton
                    Layout.preferredWidth: 40
                    Layout.fillHeight: true
                    radius: 8
                    color: powerMouse.containsMouse || powerMenu.visible ? root.bg5 : root.bg1

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: root.red
                        font.family: root.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: powerMenu.visible = !powerMenu.visible
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 64
                Layout.minimumHeight: 64
                Layout.maximumHeight: 64
                radius: 8
                color: root.bg1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: ""
                        color: root.yellow
                        font.family: root.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Slider {
                        id: brightnessSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: root.brightness
                        live: true
                        onMoved: {
                            const next = Math.round(value);
                            root.brightness = next;
                            brightnessSetter.exec(["brightnessctl", "set", `${next}%`]);
                        }
                    }

                    Text {
                        Layout.preferredWidth: 44
                        text: `${root.brightness}%`
                        color: root.fg
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: root.bg1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TabButton {
                            label: "Notifications"
                            active: root.selectedTab === 0
                            onClicked: root.selectedTab = 0
                        }

                        TabButton {
                            label: "Calendar"
                            active: root.selectedTab === 1
                            onClicked: root.selectedTab = 1
                        }

                        TabButton {
                            label: "Todo"
                            active: root.selectedTab === 2
                            onClicked: root.selectedTab = 2
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: {
                            if (root.selectedTab === 0)
                                return notificationsPage;
                            if (root.selectedTab === 1)
                                return calendarPage;
                            return todoPage;
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: powerMenu
        visible: false
        width: 170
        implicitHeight: powerMenuColumn.implicitHeight + 12
        radius: 8
        color: root.bg1
        border.width: 1
        border.color: root.bg5
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 58
        anchors.rightMargin: 12
        z: 20

        ColumnLayout {
            id: powerMenuColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            PowerAction {
                label: "Logout"
                command: ["hyprctl", "dispatch", "exit"]
            }
            PowerAction {
                label: "Sleep"
                command: ["systemctl", "suspend"]
            }
            PowerAction {
                label: "Power down"
                command: ["systemctl", "poweroff"]
                danger: true
            }
            PowerAction {
                label: "Restart"
                command: ["systemctl", "reboot"]
                danger: true
            }
        }
    }

    Component {
        id: notificationsPage

        ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                SmallButton {
                    label: root.notificationService?.silent ? "Resume" : "Pause"
                    active: root.notificationService?.silent ?? false
                    onClicked: if (root.notificationService) root.notificationService.silent = !root.notificationService.silent
                }

                Text {
                    Layout.fillWidth: true
                    text: `${root.notificationService?.list.length ?? 0} notifications`
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                SmallButton {
                    label: "Clear"
                    onClicked: root.notificationService?.discardAllNotifications()
                }
            }

            ListView {
                id: notificationList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.notificationService?.list ?? []

                delegate: NotificationItem {
                    required property var modelData
                    width: notificationList.width
                    notification: modelData
                }

                Text {
                    visible: (root.notificationService?.list.length ?? 0) === 0
                    anchors.centerIn: parent
                    text: root.notificationService?.silent ? "Notifications paused" : "No notifications"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }
            }
        }
    }

    Component {
        id: calendarPage

        Item {
            CalendarPopup {
                anchors.centerIn: parent
            }
        }
    }

    Component {
        id: todoPage

        Rectangle {
            radius: 8
            color: root.bg0
            border.width: 1
            border.color: root.bg2

            Text {
                anchors.centerIn: parent
                text: "Todo will go here"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: 15
                font.bold: true
            }
        }
    }

    component TabButton: Rectangle {
        id: tabButton

        signal clicked()
        property string label: ""
        property bool active: false

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 8
        color: active ? root.green : (tabMouse.containsMouse ? root.bg5 : root.bg2)

        Text {
            anchors.centerIn: parent
            text: tabButton.label
            color: tabButton.active ? root.bg0 : root.fg
            font.family: root.fontFamily
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: tabButton.clicked()
        }
    }

    component SmallButton: Rectangle {
        id: smallButton

        signal clicked()
        property string label: ""
        property bool active: false

        Layout.preferredWidth: 76
        implicitHeight: 30
        radius: 8
        color: active ? root.yellow : (smallMouse.containsMouse ? root.bg5 : root.bg2)

        Text {
            anchors.centerIn: parent
            text: smallButton.label
            color: smallButton.active ? root.bg0 : root.fg
            font.family: root.fontFamily
            font.pixelSize: 13
            font.bold: true
        }

        MouseArea {
            id: smallMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: smallButton.clicked()
        }
    }

    component NotificationItem: Rectangle {
        id: notificationItem

        required property var notification

        radius: 8
        color: root.bg0
        border.width: 1
        border.color: root.bg2
        implicitHeight: Math.max(76, notificationContent.implicitHeight + 18)

        ColumnLayout {
            id: notificationContent
            anchors {
                left: parent.left
                right: dismissButton.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 8
            }
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: notificationItem.notification.appName.length > 0 ? notificationItem.notification.appName : "Notification"
                color: root.green
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: notificationItem.notification.summary
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: notificationItem.notification.body.length > 0
                text: notificationItem.notification.body
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Text {
            id: dismissButton
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 8
                rightMargin: 10
            }
            text: "x"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: 13
            font.bold: true

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notificationService.discardNotification(notificationItem.notification.notificationId)
            }
        }
    }

    component PowerAction: Rectangle {
        id: powerAction

        required property string label
        required property var command
        property bool danger: false

        Layout.fillWidth: true
        implicitHeight: 32
        radius: 6
        color: powerActionMouse.containsMouse ? root.bg5 : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: powerAction.label
            color: powerAction.danger ? root.red : root.fg
            font.family: root.fontFamily
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea {
            id: powerActionMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                powerMenu.visible = false;
                powerRunner.exec(powerAction.command);
            }
        }
    }
}
