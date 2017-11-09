import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

RowLayout {
  property alias interval: o_timer.interval
  Timer {
    id: o_timer
    interval: 3000 // 3 seconds

    onTriggered: o_text.text = ""
  }

  property alias font: o_text.font
  property alias text: o_text.text
  Label {
    Layout.fillWidth: true
    Layout.margins: 10;
    id: o_text
    text: ""

    onTextChanged: o_timer.restart()
  }
}
