import QtQuick
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    property int size: 18
    property color color: "#d3c6aa"
    property string regularIcon: "application-x-executable"
    property list<string> symbolicIcons: []
    property string resolvedIcon: regularIcon

    readonly property string resolver: Qt.resolvedUrl("scripts/resolve-icon").toString().replace("file://", "")

    implicitWidth: size
    implicitHeight: size

    function refresh(): void {
        resolverProcess.exec(["sh", resolver, regularIcon].concat(symbolicIcons));
    }

    Component.onCompleted: refresh()
    onRegularIconChanged: refresh()
    onSymbolicIconsChanged: refresh()

    IconImage {
        id: icon

        anchors.fill: parent
        implicitSize: root.size
        source: `image://icon/${root.resolvedIcon}`
    }

    Process {
        id: resolverProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const icon = this.text.trim();
                root.resolvedIcon = icon.length > 0 ? icon : root.regularIcon;
            }
        }
    }
}
