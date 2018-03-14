import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

RowLayout {
  id: root
  property bool keep_hidden: false
  property int interval: 3000 // 3 seconds
  property alias font: o_text.font
  property alias text: o_text.text

  Component.onCompleted: {
    if (keep_hidden) { visible = false; }
  }

  Timer {
    id: o_timer
    interval: root.interval

    onTriggered: {
      o_text.text = "";
      if (root.keep_hidden) { root.visible = false; }
    }
  }

  Label {
    Layout.fillWidth: true
    Layout.margins: 4
    id: o_text
    text: ""
    color: '#555555'

    onTextChanged: {
      o_timer.restart();
      if (text != "") { console.info(text); }
      if (root.keep_hidden) { root.visible = true; }
    }
  }
}
