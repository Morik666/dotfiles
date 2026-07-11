import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    property list<string> pinnedApps: []
    property list<string> ignoredAppRegexes: []

    readonly property var iconAliases: ({
        "nemo": "nemo",
        "zen-beta": "zen-browser"
    })
    readonly property var symbolAliases: ({
        "ghostty": "󰊠",
        "com.mitchellh.ghostty": "󰊠"
    })
    readonly property var shapeAliases: ({
        "zen-beta": "zen",
        "zen-browser": "zen",
        "zen": "zen"
    })
    readonly property var sourceAliases: ({
    })

    readonly property list<var> apps: groupedApps(allToplevels())

    function appIdFor(toplevel): string {
        if (toplevel == null)
            return "application-x-executable";

        if (toplevel.wayland != null && toplevel.wayland.appId.length > 0)
            return toplevel.wayland.appId;

        const ipc = toplevel.lastIpcObject;
        if (ipc != null && ipc.class != null && ipc.class.length > 0)
            return ipc.class;

        return "application-x-executable";
    }

    function desktopEntryFor(appId): var {
        if (appId == null || appId.length === 0)
            return null;

        return DesktopEntries.byId(appId)
            ?? DesktopEntries.byId(`${appId}.desktop`)
            ?? DesktopEntries.heuristicLookup(appId);
    }

    function iconFor(toplevel): string {
        const appId = appIdFor(toplevel);

        if (iconAliases[appId] != null)
            return iconAliases[appId];

        if (iconAliases[appId.toLowerCase()] != null)
            return iconAliases[appId.toLowerCase()];

        const entry = desktopEntryFor(appId);
        if (entry != null && entry.icon.length > 0)
            return entry.icon;

        return appId;
    }

    function symbolFor(toplevel): string {
        const appId = appIdFor(toplevel);

        if (symbolAliases[appId] != null)
            return symbolAliases[appId];

        if (symbolAliases[appId.toLowerCase()] != null)
            return symbolAliases[appId.toLowerCase()];

        const shortName = reverseDomainName(appId).toLowerCase();
        if (symbolAliases[shortName] != null)
            return symbolAliases[shortName];

        return "";
    }

    function sourceFor(toplevel): string {
        const appId = appIdFor(toplevel);

        if (sourceAliases[appId] != null)
            return sourceAliases[appId];

        if (sourceAliases[appId.toLowerCase()] != null)
            return sourceAliases[appId.toLowerCase()];

        const shortName = reverseDomainName(appId).toLowerCase();
        if (sourceAliases[shortName] != null)
            return sourceAliases[shortName];

        return "";
    }

    function shapeFor(toplevel): string {
        const appId = appIdFor(toplevel);

        if (shapeAliases[appId] != null)
            return shapeAliases[appId];

        if (shapeAliases[appId.toLowerCase()] != null)
            return shapeAliases[appId.toLowerCase()];

        const shortName = reverseDomainName(appId).toLowerCase();
        if (shapeAliases[shortName] != null)
            return shapeAliases[shortName];

        return "";
    }

    function reverseDomainName(appId): string {
        if (appId == null || appId.length === 0)
            return "";

        const parts = appId.split(".");
        return parts.length > 0 ? parts[parts.length - 1] : appId;
    }

    function ignored(appId): bool {
        return ignoredAppRegexes.some(pattern => new RegExp(pattern, "i").test(appId));
    }

    function isPinned(appId): bool {
        return pinnedApps.indexOf(appId) !== -1;
    }

    function allToplevels(): list<var> {
        const windows = [];
        const workspaces = Hyprland.workspaces?.values ?? [];

        for (const workspace of workspaces) {
            const toplevels = workspace.toplevels?.values ?? [];
            for (const toplevel of toplevels) {
                if (windows.indexOf(toplevel) === -1)
                    windows.push(toplevel);
            }
        }

        return windows;
    }

    function groupedApps(toplevels): list<var> {
        const map = new Map();

        for (const appId of pinnedApps) {
            const key = appId.toLowerCase();
            if (!map.has(key))
                map.set(key, { appId, pinned: true, toplevels: [] });
        }

        if (pinnedApps.length > 0)
            map.set("SEPARATOR", { appId: "SEPARATOR", pinned: false, toplevels: [] });

        for (const toplevel of toplevels) {
            const appId = appIdFor(toplevel);
            if (ignored(appId))
                continue;

            const key = appId.toLowerCase();
            if (!map.has(key))
                map.set(key, { appId, pinned: false, toplevels: [] });

            map.get(key).toplevels.push(toplevel);
        }

        return Array.from(map.values());
    }
}
