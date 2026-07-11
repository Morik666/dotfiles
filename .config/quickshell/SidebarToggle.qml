import QtQuick

Item {
    id: root

    property bool toggled: false
    signal clicked()

    implicitWidth: status.implicitWidth
    implicitHeight: status.implicitHeight

    StatusWidget {
        id: status
        text: "󰍜"
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: root.toggled ? "#d699b6" : "#a7c080"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
