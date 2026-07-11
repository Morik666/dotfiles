import QtQuick

QtObject {
    readonly property var apps: [
        {
            id: "zen-beta",
            name: "Zen Browser",
            exec: "zen-beta",
            icon: "zen-browser",
            symbolic: "zen-symbolic",
            shape: "zen",
            match: ["zen-beta", "zen-browser", "zen"],
            group: "Internet",
            aliases: ["browser", "web", "firefox"]
        },
        {
            id: "ghostty",
            name: "Ghostty",
            exec: "ghostty",
            icon: "com.mitchellh.ghostty",
            symbol: "󰊠",
            match: ["ghostty", "com.mitchellh.ghostty"],
            group: "Development",
            aliases: ["terminal", "term", "shell"]
        }
    ]

    readonly property var commands: [
        {
            id: "manitx",
            name: "Manitx",
            description: "Run manitx",
            command: ["manitx"],
            icon: "utilities-terminal",
            group: "Commands",
            aliases: ["manitx"],
            terminal: false,
            confirm: false
        }
    ]

    function overrideFor(value): var {
        if (value == null || value.length === 0)
            return null;

        const needle = value.toLowerCase();
        for (const app of apps) {
            const matches = app.match ?? [];
            if (app.id.toLowerCase() === needle || matches.some(match => match.toLowerCase() === needle))
                return app;
        }

        return null;
    }
}
