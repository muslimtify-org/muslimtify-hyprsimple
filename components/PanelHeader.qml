import QtQuick
import QtQuick.Layouts
import Hyprsimple
import "../lib/Model.js" as Model

// Logo, title and subtitle, with the refresh and settings buttons on the
// right. Shared by both pages.
RowLayout {
    id: root

    property string title
    property string meta
    property bool metaIsError: false
    property bool settingsOpen: false
    signal refreshClicked()
    signal settingsClicked()

    spacing: Theme.md

    Image {
        Layout.preferredWidth: Model.LOGO_SIZE
        Layout.preferredHeight: Model.LOGO_SIZE
        source: Qt.resolvedUrl("../assets/muslimtify.webp")
        sourceSize: Qt.size(2 * Model.LOGO_SIZE, 2 * Model.LOGO_SIZE)
        fillMode: Image.PreserveAspectFit
        mipmap: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            text: root.title
            font.bold: true
        }
        StyledText {
            Layout.fillWidth: true
            text: root.meta
            color: root.metaIsError ? Theme.danger : Theme.muted
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }

    IconButton {
        icon: Theme.icon.refresh
        onClicked: root.refreshClicked()
    }

    IconButton {
        icon: Theme.icon.settings
        filled: root.settingsOpen
        onClicked: root.settingsClicked()
    }
}
