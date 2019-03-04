import QtQuick 2.5
import QtQuick.Controls 2.4

Item {
  id: root
  property color bgcolor: "red"
  property color textcolor: "white"
  property string button_text: ""
  property string message_text: ""

  Rectangle { /* Error Overlay */
    id: error_bg
    color: root.bgcolor
    opacity: 0.8
    anchors.fill: parent
    MouseArea {
      anchors.fill: parent
    }
  }
  Text {
    text: root.message_text
    font.pointSize: 28*fratio
    color: root.textcolor
    horizontalAlignment: Qt.AlignHCenter
    anchors.horizontalCenter: parent.horizontalCenter
    y: error_button.y - 20 - height
  }
  QStylizedButton { /* Release Lock */
    id: error_button
    visible: root.button_text=="" || root.button_text===null ? false : true
    y: error_bg.height*0.5 - height*0.5 + error_bg.y
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.button_text
    font.pointSize: 20*fratio
    opacity: 1
    onClicked: function() {
      root.visible = false;
    }
  }
}
