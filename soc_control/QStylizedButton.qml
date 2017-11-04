import QtQuick 2.5
import QtQuick.Controls 2.0

Button {
  property int borderwidth: 2
  background: Rectangle {
    border.color: "#555"
    border.width: borderwidth
    color: "#ededed"
  }
  font {
    pointSize: 12;
    bold: true
  }
}

