import QtQuick
import QtQuick.Layouts
import "calendar_layout.js" as CalendarLayout

Item {
    id: root

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)

    readonly property color bg0: "#2d353b"
    readonly property color bg1: "#343f44"
    readonly property color bg5: "#56635f"
    readonly property color fg: "#d3c6aa"
    readonly property color dim: "#859289"
    readonly property color green: "#a7c080"
    readonly property string fontFamily: "ComicShannsMono Nerd Font"

    implicitWidth: calendarColumn.implicitWidth
    implicitHeight: calendarColumn.implicitHeight

    Keys.onPressed: event => {
        if (event.key === Qt.Key_PageDown && event.modifiers === Qt.NoModifier) {
            monthShift++;
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp && event.modifiers === Qt.NoModifier) {
            monthShift--;
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y > 0)
                monthShift--;
            else if (event.angleDelta.y < 0)
                monthShift++;
        }
    }

    ColumnLayout {
        id: calendarColumn
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            HeaderButton {
                text: (root.monthShift === 0 ? "" : "* ") + Qt.formatDate(root.viewingDate, "MMMM yyyy")
                Layout.fillWidth: true
                onClicked: root.monthShift = 0
            }

            HeaderButton {
                text: "<"
                fixedWidth: 30
                onClicked: root.monthShift--
            }

            HeaderButton {
                text: ">"
                fixedWidth: 30
                onClicked: root.monthShift++
            }
        }

        RowLayout {
            spacing: 5

            Repeater {
                model: CalendarLayout.weekDays

                CalendarDay {
                    day: modelData.day
                    bold: true
                    todayState: 0
                    enabled: false
                }
            }
        }

        Repeater {
            model: root.calendarLayout

            RowLayout {
                required property var modelData
                spacing: 5

                Repeater {
                    model: parent.modelData

                    CalendarDay {
                        day: modelData.day
                        todayState: modelData.today
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: headerButton

        signal clicked()
        property alias text: label.text
        property int fixedWidth: 0

        Layout.preferredWidth: fixedWidth > 0 ? fixedWidth : implicitWidth
        implicitWidth: fixedWidth > 0 ? fixedWidth : label.implicitWidth + 18
        implicitHeight: 30
        radius: 6
        color: headerMouse.containsMouse ? root.bg5 : root.bg1

        Text {
            id: label
            anchors.centerIn: parent
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 15
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: headerButton.clicked()
        }
    }

    component CalendarDay: Rectangle {
        id: dayButton

        property string day: ""
        property int todayState: 0
        property bool bold: false

        implicitWidth: 34
        implicitHeight: 32
        radius: 6
        color: todayState === 1 ? root.green : "transparent"

        Text {
            anchors.centerIn: parent
            text: dayButton.day
            color: dayButton.todayState === 1 ? root.bg0 : (dayButton.todayState === -1 ? root.dim : root.fg)
            font.family: root.fontFamily
            font.pixelSize: 15
            font.bold: dayButton.bold || dayButton.todayState === 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
