import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal calendarClicked()
    signal notificationsClicked()

    property int brightness: 0
    property int notifications: 0

    readonly property color bg0: "#2d353b"
    readonly property color fg: "#d3c6aa"
    readonly property color green: "#a7c080"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 30

    function brightnessIcon(): string {
        if (brightness <= 20)
            return "󰃞";
        if (brightness <= 65)
            return "󰃟";
        return "󰃠";
    }

    function refreshBrightness(): void {
        brightnessReader.exec(["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/, \"\", $4); print int($4)}'"]);
    }

    Component.onCompleted: refreshBrightness()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshBrightness()
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

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Segment {
            text: root.brightnessIcon()
            widthHint: 30
            onClicked: root.calendarClicked()
        }

        Segment {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            widthHint: 54
            onClicked: root.calendarClicked()
        }

        Segment {
            text: root.notifications > 0 ? ` ${root.notifications}` : " 0"
            widthHint: 54
            onClicked: root.notificationsClicked()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: root.green
    }

    component Segment: Item {
        id: segment

        signal clicked()
        property string text: ""
        property int widthHint: 32

        Layout.preferredWidth: Math.max(widthHint, label.implicitWidth + 12)
        implicitHeight: 30

        Text {
            id: label
            anchors.centerIn: parent
            text: segment.text
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: segment.clicked()
        }
    }
}
