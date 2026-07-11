import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property int size: 28
    property color color: "#d3c6aa"
    property string symbol: ""
    property string shape: ""
    property string symbolic: ""
    property url sourceOverride: ""
    property string regularIcon: "application-x-executable"
    property string fallbackIcon: "application-x-executable"
    property string resolvedIcon: resolveIcon(regularIcon)

    implicitWidth: size
    implicitHeight: size

    readonly property url localSymbolicSource: symbolic.length > 0 ? Qt.resolvedUrl(`assets/icons/${symbolic}.svg`) : ""
    readonly property string mode: {
        if (sourceOverride.toString().length > 0)
            return "image";
        if (symbolic.length > 0 && !Quickshell.hasThemeIcon(symbolic))
            return "localSymbolic";
        if (symbolic.length > 0 && Quickshell.hasThemeIcon(symbolic))
            return "themeSymbolic";
        if (resolvedIcon.length > 0)
            return "themeIcon";
        if (shape === "zen")
            return "zen";
        if (symbol.length > 0)
            return "symbol";
        return "placeholder";
    }

    function isImageSource(value): bool {
        const source = String(value ?? "");
        return source.startsWith("/") || source.startsWith("file:") || source.startsWith("qrc:") || source.includes("://");
    }

    function resolveIcon(icon): string {
        const name = String(icon ?? "");
        if (name.length > 0) {
            if (isImageSource(name))
                return name;
            if (Quickshell.hasThemeIcon(name))
                return Quickshell.iconPath(name);
        }

        if (fallbackIcon.length > 0 && Quickshell.hasThemeIcon(fallbackIcon))
            return Quickshell.iconPath(fallbackIcon);

        return "";
    }

    IconImage {
        anchors.fill: parent
        visible: root.mode === "themeIcon"
        implicitSize: root.size
        source: root.resolvedIcon
    }

    IconImage {
        anchors.fill: parent
        visible: root.mode === "themeSymbolic"
        implicitSize: root.size
        source: Quickshell.iconPath(root.symbolic)
    }

    Image {
        anchors.fill: parent
        visible: root.mode === "image" || root.mode === "localSymbolic"
        source: root.mode === "image" ? root.sourceOverride : root.localSymbolicSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: root.size
        sourceSize.height: root.size
    }

    Text {
        anchors.centerIn: parent
        visible: root.mode === "symbol"
        text: root.symbol
        color: root.color
        font.pixelSize: root.size
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Item {
        anchors.centerIn: parent
        width: 80
        height: 80
        scale: root.size / 80
        visible: root.mode === "zen"

        Shape {
            anchors.fill: parent

            ShapePath {
                fillColor: root.color
                strokeWidth: 0
                PathSvg {
                    path: "M63.4352,57.677c-.0536,3.2125-2.7416,5.7589-5.9546,5.7589h-22.0762c-1.1221,0-1.8295-1.2103-1.2751-2.1859,1.4628-2.5738,4.3202-6.7829,8.5529-9.1539.4406-.2468.9366-.3783,1.4416-.3783h13.4532c3.2692,0,5.9129,2.6774,5.8582,5.9591Z"
                }
            }

            ShapePath {
                fillColor: root.color
                strokeWidth: 0
                PathSvg {
                    path: "M45.8707,18.7498c-1.4628,2.5738-4.3202,6.7829-8.5529,9.1539-.4406.2468-.9366.3783-1.4416.3783h-13.3567c-3.213,0-5.901-2.5464-5.9546-5.7589-.0547-3.2817,2.589-5.9591,5.8582-5.9591h22.1726c1.1221,0,1.8295,1.2103,1.2751,2.1859Z"
                }
            }

            ShapePath {
                fillColor: root.color
                strokeWidth: 0
                PathSvg {
                    path: "M22.4207,63.4375c-.7473,0-1.5065-.1438-2.2398-.4475-2.9896-1.2383-4.4093-4.6657-3.171-7.6551,1.9045-4.5977,4.6342-8.7196,8.1136-12.2511,3.6044-3.6585,7.8551-6.5172,12.6343-8.4968,6.5691-2.7211,11.6853-7.8373,14.4061-14.4061,1.2383-2.9896,4.6658-4.409,7.6551-3.171,2.9896,1.2383,4.4093,4.6657,3.171,7.6551-1.9045,4.5977-4.6342,8.7196-8.1136,12.2511-3.6044,3.6585-7.8551,6.5172-12.6343,8.4968-6.5691,2.7211-11.6853,7.8373-14.4061,14.4061-.9345,2.2562-3.1164,3.6185-5.4153,3.6185Z"
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        visible: root.mode === "placeholder"
        width: Math.max(10, root.size * 0.72)
        height: width
        radius: 4
        color: root.color
        opacity: 0.9
    }
}
