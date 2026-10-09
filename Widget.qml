import QtQuick
import Hyprsimple
import "lib/Model.js" as Model

// Left click opens the panel. Right click switches to the countdown.
Capsule {
    id: root
    required property var context
    readonly property var service: context.service
    property bool showRemaining: false
    readonly property bool active: context.panelOpen
    readonly property string label: service.next ? Model.barLabel(service.next, showRemaining) : ""
    readonly property bool soon: !!service.next && service.next.remaining <= Model.SOON_MINUTES
    visible: !!service.next

    StatusButton {
        label: root.label
        active: root.active
        highlighted: root.soon
        tooltip: root.service.next ? `${Model.title(root.service.next.name)} at ${root.service.next.time}, in ${Model.formatDuration(root.service.next.remaining)}` : ""
        onClicked: root.context.togglePanel()
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.showRemaining = !root.showRemaining
        }
    }
}
