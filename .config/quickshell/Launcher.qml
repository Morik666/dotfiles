import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    property bool open: false
    property var openPrograms
    property color bg0: "#2d353b"
    property color bg1: "#343f44"
    property color bg2: "#3d484d"
    property color bg5: "#56635f"
    property color fg: "#d3c6aa"
    property color dim: "#859289"
    property color green: "#a7c080"
    property color blue: "#7fbbb3"
    property string fontFamily: "ComicShannsMono Nerd Font"
    property string query: ""
    property int tabIndex: 0
    property int selectedIndex: 0

    readonly property var tabs: ["All", "Internet", "Development", "System", "Commands", "Workspaces"]
    readonly property var appEntries: [...DesktopEntries.applications.values]
        .filter(entry => entry != null && entry.name.length > 0)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var activeResults: resultsForCurrentState()
    readonly property bool showingWorkspaceTab: tabs[tabIndex] === "Workspaces"

    signal closeRequested()

    LauncherData {
        id: launcherData
    }

    function reset(): void {
        query = "";
        selectedIndex = 0;
        searchField.forceActiveFocus();
    }

    function normalize(value): string {
        return String(value ?? "").toLowerCase();
    }

    function appOverride(entry): var {
        return launcherData.overrideFor(entry.id) ?? launcherData.overrideFor(entry.name) ?? launcherData.overrideFor(entry.icon);
    }

    function appGroup(entry): string {
        const override = appOverride(entry);
        if (override != null && override.group != null)
            return override.group;

        const categories = entry.categories ?? [];
        if (categories.indexOf("Network") !== -1 || categories.indexOf("WebBrowser") !== -1)
            return "Internet";
        if (categories.indexOf("Development") !== -1)
            return "Development";
        if (categories.indexOf("System") !== -1 || categories.indexOf("Settings") !== -1)
            return "System";
        if (categories.indexOf("AudioVideo") !== -1 || categories.indexOf("Graphics") !== -1)
            return "Media";
        if (categories.indexOf("Office") !== -1)
            return "Office";
        return "Utilities";
    }

    function appSearchText(entry): string {
        const override = appOverride(entry);
        const aliases = override?.aliases ?? [];
        return normalize([entry.name, entry.id, entry.icon, entry.genericName, entry.comment, aliases.join(" ")].join(" "));
    }

    function commandSearchText(command): string {
        return normalize([command.name, command.id, command.description, (command.aliases ?? []).join(" ")].join(" "));
    }

    function appResult(entry): var {
        const override = appOverride(entry);
        return {
            kind: "app",
            title: entry.name,
            subtitle: appGroup(entry),
            icon: override?.icon ?? entry.icon,
            symbol: override?.symbol ?? "",
            shape: override?.shape ?? "",
            symbolic: override?.symbolic ?? "",
            source: override?.source ?? "",
            entry: entry
        };
    }

    function commandResult(command): var {
        return {
            kind: "command",
            title: command.name,
            subtitle: command.description,
            icon: command.icon,
            command: command
        };
    }

    function resultsForCurrentState(): var {
        const tab = tabs[tabIndex];
        const q = normalize(query.trim());

        if (tab === "Workspaces")
            return workspaceResults();

        const appResults = tab === "Commands" ? [] : appEntries
            .filter(entry => tab === "All" || appGroup(entry) === tab)
            .filter(entry => q.length === 0 || appSearchText(entry).includes(q))
            .slice(0, q.length === 0 ? 48 : 12)
            .map(entry => appResult(entry));

        const commandResults = (tab === "All" || tab === "Commands") ? launcherData.commands
            .filter(command => q.length === 0 || commandSearchText(command).includes(q))
            .map(command => commandResult(command)) : [];

        if (q.length > 0 && tab === "All")
            return commandResults.concat(appResults);

        return appResults.concat(commandResults);
    }

    function workspaceResults(): var {
        return [...Hyprland.workspaces.values]
            .filter(workspace => workspace.id > 0)
            .sort((a, b) => a.id - b.id)
            .map(workspace => ({
                kind: "workspace",
                title: `Workspace ${workspace.name}`,
                subtitle: `${workspace.toplevels.values.length} windows`,
                workspace: workspace
            }));
    }

    function activate(index: int): void {
        if (index < 0 || index >= activeResults.length)
            return;

        const result = activeResults[index];
        if (result.kind === "app") {
            result.entry.execute();
            closeRequested();
        } else if (result.kind === "command") {
            Quickshell.execDetached(result.command.command);
            closeRequested();
        } else if (result.kind === "workspace") {
            workspaceSwitcher.exec(["hyprctl", "dispatch", "workspace", String(result.workspace.id)]);
            closeRequested();
        }
    }

    onOpenChanged: {
        if (open)
            reset();
    }

    onQueryChanged: selectedIndex = 0
    onTabIndexChanged: selectedIndex = 0

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel

        width: Math.min(760, Math.max(560, root.width * 0.52))
        height: Math.min(560, Math.max(440, root.height * 0.58))
        anchors.centerIn: parent
        visible: root.open
        color: root.bg0
        radius: 8
        border.color: root.bg5
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: root.bg1
                radius: 8
                border.color: searchField.activeFocus ? root.green : "transparent"
                border.width: 1

                TextInput {
                    id: searchField

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    color: root.fg
                    selectionColor: root.green
                    selectedTextColor: root.bg0
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.query
                    clip: true
                    focus: root.open
                    onTextChanged: root.query = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text.length === 0
                        text: "Search apps, commands, workspaces..."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: 16
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.activeResults.length - 1, root.selectedIndex + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.selectedIndex);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            root.tabIndex = (root.tabIndex + 1) % root.tabs.length;
                            event.accepted = true;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.tabs

                    Rectangle {
                        required property int index
                        required property string modelData

                        Layout.preferredHeight: 32
                        Layout.preferredWidth: Math.max(82, tabText.implicitWidth + 22)
                        color: root.tabIndex === index ? root.green : root.bg1
                        radius: 7

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData
                            color: root.tabIndex === index ? root.bg0 : root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.bold: root.tabIndex === index
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.tabIndex = index;
                                searchField.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: resultsColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: resultsColumn

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.open ? root.activeResults : []

                        Rectangle {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: modelData.kind === "workspace" ? 72 : 54
                            color: root.selectedIndex === index ? root.bg2 : "transparent"
                            radius: 7

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Loader {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    sourceComponent: modelData.kind === "workspace" ? workspaceIconComp : appIconComp
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: 15
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.subtitle
                                        color: root.dim
                                        font.family: root.fontFamily
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                RowLayout {
                                    visible: modelData.kind === "workspace"
                                    spacing: 5

                                    Repeater {
                                        model: modelData.kind === "workspace" ? modelData.workspace.toplevels.values.slice(0, 8) : []

                                        LauncherAppIcon {
                                            required property HyprlandToplevel modelData

                                            size: 22
                                            color: root.fg
                                            symbol: root.openPrograms.symbolFor(modelData)
                                            shape: root.openPrograms.shapeFor(modelData)
                                            sourceOverride: root.openPrograms.sourceFor(modelData)
                                            regularIcon: root.openPrograms.iconFor(modelData)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: root.selectedIndex = index
                                onClicked: root.activate(index)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appIconComp

        LauncherAppIcon {
            size: 28
            color: root.fg
            symbol: modelData.symbol ?? ""
            shape: modelData.shape ?? ""
            symbolic: modelData.symbolic ?? ""
            sourceOverride: modelData.source ?? ""
            regularIcon: modelData.icon || "application-x-executable"
        }
    }

    Component {
        id: workspaceIconComp

        Rectangle {
            radius: 6
            color: root.bg1
            border.color: modelData.workspace.focused ? root.green : root.bg5
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: modelData.workspace.name
                color: modelData.workspace.focused ? root.green : root.fg
                font.family: root.fontFamily
                font.pixelSize: 15
                font.bold: true
            }
        }
    }

    Process {
        id: workspaceSwitcher
    }
}
