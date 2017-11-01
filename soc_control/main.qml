import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ApplicationWindow {
  visible: true
  title: mainwindow_title // global property injection
  id: mainwindow
  width: 1000
  height: 800
  // minimumHeight: height
  // maximumHeight: height
  // minimumWidth: width
  // maximumWidth: width
  color: "#EEE"

  ColumnLayout {
    /* split into two horizontal control containers */
    id: controls_container
    anchors.fill: parent
    anchors.margins: 20
    spacing: controls_container.anchors.margins
    RowLayout {
      id: upper_half
      spacing: controls_container.anchors.margins
      ColumnLayout {
        id: ul_col

        QLeafletAssembly2by2 { /* Leaflet Display */
          id: soc_display
          anchors.top: parent.top
          Layout.fillWidth: true /* dynamically size */
          Layout.preferredHeight: width /* keep square */
          Layout.minimumWidth: 200
          Layout.maximumWidth: 500
          draggable: false
        }
        ColumnLayout {
          Layout.fillWidth: true
          Item {
            id: leaflet_editor
            Layout.fillHeight: true
            RowLayout {
              anchors.fill: parent
              Label {
                text: "Extension:"
                font.pixelSize: 16
              }
              SpinBox {
                id: leaflet_spinbox
                objectName: "leaflet_spinbox"
                editable: true
                from: 1
                to: soc_display.nleaflets
                value: to
                enabled: false
              }
              SpinBox {
                id: ext_spinbox
                objectName: "ext_spinbox"
                editable: true
                from: 0
                to: soc_display.max_extension
                value: to
                enabled: false
              }
              Button { /* set ext */
                text: "set"
                font.pointSize: 12
                Layout.preferredWidth: 50
                enabled: false
              }
            }
          }
        }
      }
      Pane { /* Sequence List + Buttons */
        id: seq_list_border
        clip: true
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.minimumWidth: 270
        property int borderwidth: 2
        padding: borderwidth
        background: Rectangle { anchors.fill: parent; border.color: "black"; border.width: parent.borderwidth; color: "#eee" }

        ListView {
          id: listview_sequence
          orientation: Qt.Vertical
          verticalLayoutDirection: ListView.TopToBottom
          spacing: 2
          focus: true
          currentIndex: 0
          anchors.fill: parent
          ScrollBar.vertical: ScrollBar {}

          delegate: QSequenceDelegate {}
          model: SequenceListModel  // see main.py for contextvariable setting
        }
      }
      Pane {
        id: button_pane
        height: list_buttons.height + 2*padding
        anchors.top: parent.top
        padding: 3
        background: Rectangle { anchors.fill: parent; color: "#333" }
        ColumnLayout {
          id: list_buttons
          property int btn_width: 65
          property int btn_height: 50
          property color btn_bgcolor: "#555"
          property color btn_fgcolor: "#ededed"
          width: btn_width
          spacing: button_pane.padding

          Button { /* move up */
            text: "\u25B2"
            Layout.preferredWidth: parent.btn_width
            height: parent.btn_height
            font.pointSize: 12
            onClicked: {
              if (SequenceListModel.moveRows(listview_sequence.currentIndex, 1, listview_sequence.currentIndex-1)) {
                listview_sequence.currentIndex = listview_sequence.currentIndex-1;
              }
            }
          }
          // Button { /* insert before */
          //   text: "\u2B11+"
          //   Layout.preferredWidth: parent.btn_width
          //   height: parent.btn_height
          //   font.pointSize: 20
          //   onClicked: SequenceListModel.insertRows(listview_sequence.currentIndex, 1)
          // }
          Button { /* insert after */
            // text: "\u2B10+"
            text: "+"
            Layout.preferredWidth: parent.btn_width
            height: parent.btn_height
            font.pointSize: 20
            onClicked: SequenceListModel.insertRows(listview_sequence.currentIndex+1, 1)
          }
          Button { /* remove */
            text: "\u274C"
            Layout.preferredWidth: parent.btn_width
            height: parent.btn_height
            font.pointSize: 12
            onClicked: SequenceListModel.removeRows(listview_sequence.currentIndex, 1)
          }
          Button { /* move down */
            text: "\u25BC"
            Layout.preferredWidth: parent.btn_width
            height: parent.btn_height
            font.pointSize: 12
            onClicked: {
              if (SequenceListModel.moveRows(listview_sequence.currentIndex, 1, listview_sequence.currentIndex+1)) {
                listview_sequence.currentIndex = listview_sequence.currentIndex+1;
              }
            }
          }
        }
      }
    }
    Pane {
      id: bottom_frame
      Layout.maximumHeight: 200
      Layout.minimumHeight: 75
      Layout.fillWidth: true
      background: Rectangle {
        anchors.fill: parent
        border.color: "orange"
        border.width: 2
        color: "transparent"
      }

    }
  }
}
