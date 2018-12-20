import QtQuick 2.5
import QtQuick.Controls 2.4

Item {
  id: root

  Rectangle { /* Error Overlay */
    id: error_bg
    color: "red"
    opacity: 0.8
    anchors.fill: parent
    MouseArea {
      anchors.fill: parent
    }
  }
  Text {
    text: "Hardware Positioning Error Detected"
    font.pointSize: 28*fratio
    color: "white"
    horizontalAlignment: Qt.AlignHCenter
    anchors.horizontalCenter: parent.horizontalCenter
    y: error_button.y - 20 - height
  }
  QStylizedButton { /* Release Lock */
    id: error_button
    y: error_bg.height*0.5 - height*0.5 + error_bg.y
    anchors.horizontalCenter: parent.horizontalCenter
    text: "Release Error Interlock"
    font.pointSize: 20*fratio
    opacity: 1
    onClicked: function() {
      root.visible = false;
    }
  }
}
