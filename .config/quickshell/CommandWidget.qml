import QtQuick
import Quickshell.Io

StatusWidget {
    id: root

    property string icon: ""
    property string command
    property string fallback: ""
    property int interval: 10000
    property string value: fallback

    text: icon.length > 0 ? `${icon} ${value}` : value

    function refresh(): void {
        runner.exec(["sh", "-c", command]);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: runner

        stdout: StdioCollector {
            onStreamFinished: {
                const next = this.text.trim();
                root.value = next.length > 0 ? next : root.fallback;
            }
        }
    }
}
