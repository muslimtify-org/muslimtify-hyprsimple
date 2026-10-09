import QtQuick
import Hyprsimple

// One line of error text. Hidden while empty.
StyledText {
    visible: text !== ""
    color: Theme.danger
    font.pixelSize: Theme.fontSizeSmall
    wrapMode: Text.WordWrap
}
