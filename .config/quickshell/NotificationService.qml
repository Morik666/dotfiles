import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    component StoredNotification: QtObject {
        required property int notificationId
        property Notification notification
        property bool popup: false
        property string appName: notification?.appName ?? ""
        property string appIcon: notification?.appIcon ?? ""
        property string summary: notification?.summary ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property double time: Date.now()
        property string urgency: notification?.urgency.toString() ?? "normal"

        onNotificationChanged: {
            if (notification === null)
                root.discardNotification(notificationId);
        }
    }

    property bool silent: false
    property bool sidebarOpen: false
    property int unread: 0
    property list<StoredNotification> list: []
    property list<StoredNotification> popupList: list.filter(notif => notif.popup)

    Component {
        id: storedNotificationComponent
        StoredNotification {}
    }

    Component {
        id: popupTimerComponent

        Timer {
            required property int notificationId
            interval: 7000
            running: true
            repeat: false
            onTriggered: {
                root.timeoutNotification(notificationId);
                destroy();
            }
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: false

        onNotification: notification => {
            notification.tracked = true;

            const stored = storedNotificationComponent.createObject(root, {
                notificationId: notification.id,
                notification: notification,
                time: Date.now(),
            });

            root.list = [stored, ...root.list];

            if (!root.silent && !root.sidebarOpen) {
                stored.popup = true;
                root.unread++;

                if (notification.expireTimeout !== 0) {
                    popupTimerComponent.createObject(root, {
                        notificationId: stored.notificationId,
                        interval: notification.expireTimeout < 0 ? 7000 : notification.expireTimeout,
                    });
                }
            }
        }
    }

    function markAllRead(): void {
        unread = 0;
    }

    function timeoutNotification(notificationId: int): void {
        const index = list.findIndex(notif => notif.notificationId === notificationId);
        if (index !== -1) {
            list[index].popup = false;
            triggerListChange();
        }
    }

    function timeoutAll(): void {
        for (const notif of list)
            notif.popup = false;
        triggerListChange();
    }

    function discardNotification(notificationId: int): void {
        const index = list.findIndex(notif => notif.notificationId === notificationId);
        if (index === -1)
            return;

        const notif = list[index];
        if (notif.notification)
            notif.notification.dismiss();

        list.splice(index, 1);
        triggerListChange();
    }

    function discardAllNotifications(): void {
        for (const notif of list) {
            if (notif.notification)
                notif.notification.dismiss();
        }
        list = [];
        unread = 0;
    }

    function invokeAction(notificationId: int, actionIdentifier: string): void {
        const index = list.findIndex(notif => notif.notificationId === notificationId);
        if (index === -1 || !list[index].notification)
            return;

        const action = list[index].notification.actions.find(action => action.identifier === actionIdentifier);
        if (action)
            action.invoke();

        discardNotification(notificationId);
    }

    function triggerListChange(): void {
        list = list.slice(0);
    }
}
