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

    function appIdCandidates(appId): var {
        const raw = String(appId ?? "");
        if (raw.length === 0)
            return [];

        const withoutDesktop = raw.endsWith(".desktop") ? raw.slice(0, -8) : raw;
        const shortName = reverseDomainName(withoutDesktop);
        const candidates = [raw, withoutDesktop, shortName];

        return candidates.filter((candidate, index) => candidate.length > 0 && candidates.indexOf(candidate) === index);
    }

    function aliasFor(aliases, appId): string {
        for (const candidate of appIdCandidates(appId)) {
            if (aliases[candidate] != null)
                return aliases[candidate];

            const lower = candidate.toLowerCase();
            if (aliases[lower] != null)
                return aliases[lower];
        }

        return "";
    }

    function iconFor(toplevel): string {
        const appId = appIdFor(toplevel);

        const alias = aliasFor(iconAliases, appId);
        if (alias.length > 0)
            return alias;

        const entry = desktopEntryFor(appId);
        if (entry != null && entry.icon.length > 0)
            return entry.icon;

        return appId;
    }

    function iconForEntry(entry): string {
        if (entry == null)
            return "application-x-executable";

        const iconAlias = aliasFor(iconAliases, entry.id);
        if (iconAlias.length > 0)
            return iconAlias;

        const entryIconAlias = aliasFor(iconAliases, entry.icon);
        if (entryIconAlias.length > 0)
            return entryIconAlias;

        return entry.icon.length > 0 ? entry.icon : entry.id;
    }

    function symbolFor(toplevel): string {
        const appId = appIdFor(toplevel);

        return aliasFor(symbolAliases, appId);
    }

    function symbolForEntry(entry): string {
        if (entry == null)
            return "";

        return aliasFor(symbolAliases, entry.id) || aliasFor(symbolAliases, entry.icon);
    }

    function sourceFor(toplevel): string {
        const appId = appIdFor(toplevel);

        return aliasFor(sourceAliases, appId);
    }

    function sourceForEntry(entry): string {
        if (entry == null)
            return "";

        return aliasFor(sourceAliases, entry.id) || aliasFor(sourceAliases, entry.icon);
    }

    function shapeFor(toplevel): string {
        const appId = appIdFor(toplevel);

        return aliasFor(shapeAliases, appId);
    }

    function shapeForEntry(entry): string {
        if (entry == null)
            return "";

        return aliasFor(shapeAliases, entry.id) || aliasFor(shapeAliases, entry.icon);
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
