import QtQuick

Item {
    id: root

    property alias text: label.text
    property int leftPadding: 2
    property int rightPadding: 2
    property bool clickable: false

    signal clicked()

    readonly property color fg: "#d3c6aa"
    readonly property color green: "#a7c080"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    implicitWidth: label.implicitWidth + leftPadding + rightPadding
    implicitHeight: 30

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.leftPadding
        anchors.right: parent.right
        anchors.rightMargin: root.rightPadding
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: 16
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: root.green
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
