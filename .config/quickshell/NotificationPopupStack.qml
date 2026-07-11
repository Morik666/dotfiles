import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var notificationService: null

    readonly property color bg0: "#2d353b"
    readonly property color bg1: "#343f44"
    readonly property color bg2: "#3d484d"
    readonly property color bg5: "#56635f"
    readonly property color fg: "#d3c6aa"
    readonly property color dim: "#859289"
    readonly property color green: "#a7c080"
    readonly property color red: "#e67e80"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    implicitWidth: 360
    implicitHeight: popupColumn.implicitHeight

    ColumnLayout {
        id: popupColumn
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: root.notificationService?.popupList ?? []

            NotificationPopup {
                required property var modelData
                notification: modelData
            }
        }
    }

    component NotificationPopup: Rectangle {
        id: popup

        required property var notification

        Layout.fillWidth: true
        implicitHeight: Math.max(84, content.implicitHeight + 20)
        radius: 8
        color: root.bg1
        border.width: 1
        border.color: root.bg5

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => {
                if (event.button === Qt.RightButton)
                    root.notificationService.discardNotification(popup.notification.notificationId);
                else
                    root.notificationService.timeoutNotification(popup.notification.notificationId);
            }
        }

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: closeButton.left
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 8
            }
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: popup.notification.appName.length > 0 ? popup.notification.appName : "Notification"
                color: root.green
                font.family: root.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: popup.notification.summary
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: popup.notification.body.length > 0
                text: popup.notification.body
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        Text {
            id: closeButton
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
                onClicked: root.notificationService.discardNotification(popup.notification.notificationId)
            }
        }
    }
}
