import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool popupOpen: false

    implicitWidth: clockStatus.implicitWidth
    implicitHeight: clockStatus.implicitHeight

    StatusWidget {
        id: clockStatus
        text: Qt.formatDateTime(clock.date, "HH:mm")
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.popupOpen = !root.popupOpen
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Loader {
        active: root.popupOpen

        sourceComponent: PopupWindow {
            id: popupWindow

            visible: true
            color: "transparent"
            implicitWidth: popupBackground.implicitWidth + 16
            implicitHeight: popupBackground.implicitHeight + 16

            anchor {
                item: root
                edges: Edges.Bottom
                gravity: Edges.Bottom
                adjustment: PopupAdjustment.Slide
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                Rectangle {
                    id: popupBackground
                    anchors.centerIn: parent
                    implicitWidth: calendar.implicitWidth + 20
                    implicitHeight: calendar.implicitHeight + 20
                    color: "#2d353b"
                    radius: 8
                    border.width: 1
                    border.color: "#56635f"

                    CalendarPopup {
                        id: calendar
                        anchors.centerIn: parent
                        focus: true
                    }
                }
            }
        }
    }
}
