import QtQuick
import QtQuick.Layouts
import Quickshell
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
    property var tabs: ["Home", "Development", "Internet", "Office", "Utilities", "Games"]
    property var appGroupOverrides: ({})
    property int renamingTabIndex: -1
    property string renamingGroupName: ""

    readonly property var appEntries: [...DesktopEntries.applications.values]
        .filter(entry => entry != null && entry.name.length > 0)
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var activeResults: resultsForCurrentState()
    readonly property int gridColumns: 7
    readonly property int gridRows: 3
    readonly property int gridCapacity: gridColumns * gridRows

    signal closeRequested()

    LauncherData {
        id: launcherData
    }

    FileView {
        id: defaultsFile
        path: Qt.resolvedUrl("data/launcher.defaults.json")
        printErrors: false
    }

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("data/launcher.settings.json")
        printErrors: false
        atomicWrites: true
        watchChanges: true
        onFileChanged: root.loadLauncherConfig()
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

    function parseConfigText(text): var {
        const raw = String(text ?? "").trim();
        if (raw.length === 0)
            return null;

        try {
            return JSON.parse(raw);
        } catch (error) {
            console.warn(`Failed to parse launcher config: ${error}`);
            return null;
        }
    }

    function normalizedGroups(groups): var {
        if (!Array.isArray(groups))
            return null;

        const seen = new Set();
        const result = [];
        for (const group of groups) {
            const name = String(group ?? "").trim();
            if (name.length === 0 || seen.has(name))
                continue;

            seen.add(name);
            result.push(name);
        }

        return result.length > 0 ? result : null;
    }

    function loadLauncherConfig(): void {
        const settings = parseConfigText(settingsFile.text());
        const defaults = settings == null ? parseConfigText(defaultsFile.text()) : null;
        const config = settings ?? defaults ?? {};
        const groups = normalizedGroups(config.groups);

        tabs = groups ?? ["Home", "Development", "Internet", "Office", "Utilities", "Games"];
        appGroupOverrides = config.appGroups ?? {};

        if (tabIndex >= tabs.length)
            tabIndex = Math.max(0, tabs.length - 1);
        if (renamingTabIndex >= tabs.length)
            renamingTabIndex = -1;
    }

    function saveLauncherSettings(): void {
        const config = {
            groups: tabs,
            appGroups: appGroupOverrides
        };
        settingsFile.setText(`${JSON.stringify(config, null, 2)}\n`);
    }

    function nextGroupName(): string {
        const base = "New Group";
        if (tabs.indexOf(base) === -1)
            return base;

        let index = 2;
        while (tabs.indexOf(`${base} ${index}`) !== -1)
            index++;

        return `${base} ${index}`;
    }

    function createGroup(): void {
        const group = nextGroupName();
        tabs = [...tabs, group];
        tabIndex = tabs.length - 1;
        renamingTabIndex = -1;
        saveLauncherSettings();
        searchField.forceActiveFocus();
    }

    function uniqueGroupName(name, ignoreIndex: int): string {
        const base = String(name ?? "").trim();
        const fallback = tabs[ignoreIndex] ?? "New Group";
        const normalized = base.length > 0 ? base : fallback;

        if (tabs.every((group, index) => index === ignoreIndex || group !== normalized))
            return normalized;

        let index = 2;
        while (tabs.some((group, groupIndex) => groupIndex !== ignoreIndex && group === `${normalized} ${index}`))
            index++;

        return `${normalized} ${index}`;
    }

    function updateAppGroupOverrides(oldGroup: string, newGroup: string): void {
        const next = {};
        for (const key of Object.keys(appGroupOverrides)) {
            const group = appGroupOverrides[key];
            next[key] = group === oldGroup ? newGroup : group;
        }

        appGroupOverrides = next;
    }

    function removeAppGroupOverrides(groupName: string): void {
        const next = {};
        for (const key of Object.keys(appGroupOverrides)) {
            if (appGroupOverrides[key] !== groupName)
                next[key] = appGroupOverrides[key];
        }

        appGroupOverrides = next;
    }

    function startRenamingGroup(index: int): void {
        if (index < 0 || index >= tabs.length)
            return;

        tabIndex = index;
        renamingTabIndex = index;
        renamingGroupName = tabs[index];
    }

    function finishRenamingGroup(index: int, name: string): void {
        if (index !== renamingTabIndex || index < 0 || index >= tabs.length)
            return;

        const oldGroup = tabs[index];
        const newGroup = uniqueGroupName(name, index);
        const next = [...tabs];
        next[index] = newGroup;
        tabs = next;
        updateAppGroupOverrides(oldGroup, newGroup);
        renamingTabIndex = -1;
        renamingGroupName = "";
        saveLauncherSettings();
    }

    function cancelRenamingGroup(): void {
        renamingTabIndex = -1;
        renamingGroupName = "";
        searchField.forceActiveFocus();
    }

    function deleteGroup(index: int): void {
        if (index < 0 || index >= tabs.length || tabs.length <= 1)
            return;

        const removed = tabs[index];
        tabs = tabs.filter((_, groupIndex) => groupIndex !== index);
        removeAppGroupOverrides(removed);
        tabIndex = Math.min(tabIndex >= index ? Math.max(0, tabIndex - 1) : tabIndex, tabs.length - 1);
        renamingTabIndex = -1;
        renamingGroupName = "";
        saveLauncherSettings();
        searchField.forceActiveFocus();
    }

    function configuredGroup(entry): string {
        const candidates = [entry.id, entry.name, entry.icon];
        for (const candidate of candidates) {
            if (candidate == null)
                continue;

            const key = String(candidate);
            const group = appGroupOverrides[key] ?? appGroupOverrides[key.toLowerCase()];
            if (group != null && tabs.indexOf(group) !== -1)
                return group;
        }

        return "";
    }

    function appGroup(entry): string {
        const configured = configuredGroup(entry);
        if (configured.length > 0)
            return configured;

        const override = appOverride(entry);
        if (override != null && override.group != null && tabs.indexOf(override.group) !== -1)
            return override.group;

        const categories = entry.categories ?? [];
        if (categories.indexOf("Office") !== -1 && tabs.indexOf("Office") !== -1)
            return "Office";
        if (categories.indexOf("Game") !== -1 && tabs.indexOf("Games") !== -1)
            return "Games";
        if ((categories.indexOf("Utility") !== -1 || categories.indexOf("System") !== -1 || categories.indexOf("Settings") !== -1) && tabs.indexOf("Utilities") !== -1)
            return "Utilities";
        return tabs.indexOf("Home") !== -1 ? "Home" : tabs[0];
    }

    function appSearchText(entry): string {
        const override = appOverride(entry);
        const aliases = override?.aliases ?? [];
        return normalize([entry.name, entry.id, entry.icon, entry.genericName, entry.comment, aliases.join(" ")].join(" "));
    }

    function barIconOverride(entry): var {
        if (root.openPrograms == null)
            return {};

        return {
            icon: root.openPrograms.iconForEntry(entry),
            symbol: root.openPrograms.symbolForEntry(entry),
            shape: root.openPrograms.shapeForEntry(entry),
            source: root.openPrograms.sourceForEntry(entry)
        };
    }

    function appResult(entry): var {
        const override = appOverride(entry);
        const barOverride = barIconOverride(entry);
        return {
            kind: "app",
            title: entry.name,
            subtitle: appGroup(entry),
            icon: barOverride.icon || override?.icon || entry.icon,
            symbol: barOverride.symbol || override?.symbol || "",
            shape: barOverride.shape || override?.shape || "",
            symbolic: override?.symbolic ?? "",
            source: barOverride.source || override?.source || "",
            entry: entry
        };
    }

    function resultsForCurrentState(): var {
        const tab = tabs[tabIndex];
        const q = normalize(query.trim());

        return appEntries
            .filter(entry => appGroup(entry) === tab)
            .filter(entry => q.length === 0 || appSearchText(entry).includes(q))
            .slice(0, root.gridCapacity)
            .map(entry => appResult(entry));
    }

    function activate(index: int): void {
        if (index < 0 || index >= activeResults.length)
            return;

        const result = activeResults[index];
        if (result.kind === "app") {
            result.entry.execute();
            closeRequested();
        }
    }

    onOpenChanged: {
        if (open)
            reset();
    }

    onQueryChanged: selectedIndex = 0
    onTabIndexChanged: selectedIndex = 0
    Component.onCompleted: loadLauncherConfig()

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel

        width: Math.min(860, Math.max(680, root.width * 0.58))
        height: Math.min(600, Math.max(500, root.height * 0.62))
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
                Layout.fillHeight: false
                Layout.preferredHeight: 46
                Layout.minimumHeight: 46
                Layout.maximumHeight: 46
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
                        text: "Search apps..."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: 16
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.selectedIndex = Math.min(root.activeResults.length - 1, root.selectedIndex + root.gridColumns);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectedIndex = Math.max(0, root.selectedIndex - root.gridColumns);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            root.selectedIndex = Math.min(root.activeResults.length - 1, root.selectedIndex + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
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
                Layout.fillHeight: false
                Layout.preferredHeight: 32
                Layout.minimumHeight: 32
                Layout.maximumHeight: 32
                spacing: 6

                Repeater {
                    model: root.tabs

                    Rectangle {
                        required property int index
                        required property string modelData
                        readonly property bool renaming: root.renamingTabIndex === index

                        Layout.preferredHeight: 32
                        Layout.preferredWidth: renaming ? Math.max(138, renameInput.implicitWidth + 56) : Math.max(82, tabText.implicitWidth + 22)
                        color: root.tabIndex === index ? root.green : root.bg1
                        radius: 7

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            visible: !parent.renaming
                            text: modelData
                            color: root.tabIndex === index ? root.bg0 : root.fg
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            font.bold: root.tabIndex === index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 5
                            visible: parent.renaming
                            spacing: 4

                            TextInput {
                                id: renameInput

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: parent.visible ? root.renamingGroupName : modelData
                                color: root.tabIndex === index ? root.bg0 : root.fg
                                selectionColor: root.bg0
                                selectedTextColor: root.green
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                selectByMouse: true
                                onTextEdited: root.renamingGroupName = text
                                onVisibleChanged: {
                                    if (visible) {
                                        forceActiveFocus();
                                        selectAll();
                                    }
                                }
                                onEditingFinished: {
                                    if (root.renamingTabIndex === index)
                                        root.finishRenamingGroup(index, text);
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.cancelRenamingGroup();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.finishRenamingGroup(index, text);
                                        event.accepted = true;
                                    }
                                }
                            }

                            Rectangle {
                                id: deleteButton

                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                color: deleteMouse.containsMouse ? root.bg0 : "transparent"
                                radius: 5

                                Text {
                                    anchors.centerIn: parent
                                    text: "x"
                                    color: deleteMouse.containsMouse ? root.fg : (root.tabIndex === index ? root.bg0 : root.fg)
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: root.deleteGroup(index)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !parent.renaming
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.tabIndex = index;
                                searchField.forceActiveFocus();
                            }
                            onDoubleClicked: root.startRenamingGroup(index)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 32
                    color: root.bg1
                    radius: 7
                    border.color: addGroupMouse.containsMouse ? root.green : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: root.fg
                        font.family: root.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: addGroupMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.createGroup()
                    }
                }
            }

            Item {
                id: appArea

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property int gap: 8
                readonly property real cellWidth: Math.floor((width - gap * (root.gridColumns - 1)) / root.gridColumns)
                readonly property real cellHeight: Math.floor((height - gap * (root.gridRows - 1)) / root.gridRows)

                Repeater {
                    model: root.open ? root.activeResults : []

                    Rectangle {
                        required property int index
                        required property var modelData

                        readonly property int column: index % root.gridColumns
                        readonly property int row: Math.floor(index / root.gridColumns)

                        x: column * (appArea.cellWidth + appArea.gap)
                        y: row * (appArea.cellHeight + appArea.gap)
                        width: appArea.cellWidth
                        height: appArea.cellHeight
                        color: root.selectedIndex === index ? root.bg2 : root.bg1
                        radius: 7
                        border.color: root.selectedIndex === index ? root.green : "transparent"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 58

                                LauncherAppIcon {
                                    anchors.centerIn: parent
                                    size: 58
                                    color: root.fg
                                    symbol: modelData.symbol ?? ""
                                    shape: modelData.shape ?? ""
                                    symbolic: modelData.symbolic ?? ""
                                    sourceOverride: modelData.source ?? ""
                                    regularIcon: modelData.icon || "application-x-executable"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                text: modelData.title
                                color: root.fg
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignTop
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
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
