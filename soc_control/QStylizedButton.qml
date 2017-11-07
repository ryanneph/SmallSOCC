import QtQuick 2.5
import QtQuick.Controls 2.0

Button {
  id: button
  property color textcolor: "black"
  property color bgcolor: "#ededed"
  property color bordercolor: "#555"
  property int borderwidth: 2

  background: Rectangle {
    border.color: !button.down ? bordercolor : Qt.darker(bordercolor, 1.2)
    border.width: borderwidth
    color: !button.down ? bgcolor : Qt.darker(bgcolor, 1.2)
    opacity: enabled ? 1.0 : 0.3
  }
  font {
    pointSize: 12;
    bold: true
  }
  contentItem: Text {
    text: button.text
    font: button.font
    opacity: enabled ? 1.0 : 0.3
    color: !button.down ? button.textcolor : Qt.darker(button.textcolor, 1.2)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}

