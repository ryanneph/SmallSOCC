import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQml.Models 2.2
import QtQuick.Layouts 1.3
import "dynamicqml.js" as DynamicQML

RowLayout {
  id: root
  property alias lvseq: lvseq

  Pane { /* Sequence List */
    id: seq_list_border
    clip: true
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: 270*sratio
    property int borderwidth: 2
    padding: borderwidth
    background: Rectangle { anchors.fill: parent; border.color: "black"; border.width: parent.borderwidth; color: "transparent" }

    ListView {
      id: lvseq
      orientation: Qt.Vertical
      verticalLayoutDirection: ListView.TopToBottom
      spacing: 2
      focus: true
      anchors.fill: parent
      ScrollBar.vertical: ScrollBar {}
      cacheBuffer: 0
      enabled: !isTreating

      function next() {
        if (currentIndex >= 0 && currentIndex < model.rowCount()-1) {
          currentIndex += 1;
        }
      }
      function previous() {
        if (currentIndex >= 1 && currentIndex < model.rowCount()) {
          currentIndex -= 1;
        }
      }

      model: SequenceListModel  // see main.py for contextvariable setting
      delegate: QSequenceDelegate {}
    }
  }


  /* user props */
  property int btn_width: 93*sratio
  property int btn_height: 35*sratio
  property int fontsize: 12*fratio
  ColumnLayout {
    id: list_buttons
    Layout.minimumWidth: root.btn_width
    Layout.maximumWidth: root.btn_width
    Layout.alignment: Qt.AlignTop

    ColumnLayout {
      id: list_control_group
      enabled: !isTreating
      Layout.fillWidth: true
      spacing: -1*children[0].borderwidth

      QStylizedButton { /* move up */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "\u25B2"
        font.pointSize: root.fontsize
        onClicked: {
          if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex-1)) {
            lvseq.currentIndex -= 1;
          }
        }
      }
      QStylizedButton { /* insert after */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "+"
        font.pointSize: root.fontsize + 4*fratio
        textcolor: "#007B08"
        onClicked: {
          if (lvseq.currentIndex < 0) { SequenceListModel.insertRows() }
          else {
            SequenceListModel.insertRows(lvseq.currentIndex+1, 1)
            lvseq.currentIndex += 1;
          }
        }
      }
      QStylizedButton { /* Edit Item Data */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "Edit"
        onClicked: {
          if (!lvseq.currentItem) { console.debug('current item is null'); return null; }
          var itemdata = SequenceListModel.data(lvseq.currentIndex);
          if (!itemdata) { console.debug('data for current item is null'); return null; }
          var d = DynamicQML.createDynamicObject(mainwindow, "QEditDialog.qml");
          d.formdata = {
            "rot_couch_deg":  itemdata.rot_couch_deg,
            "rot_gantry_deg": itemdata.rot_gantry_deg,
            "description":    itemdata.description,
            "timecode_ms":    itemdata.timecode_ms,
          };
          d.onSubmitted.connect( function(newdata) {
            SequenceListModel.setData(lvseq.currentIndex, newdata);
            d.destroy();
          });
          d.open();
        }
      }
      QStylizedButton { /* remove */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "X"
        font.pointSize: root.fontsize
        textcolor: "#FF5151"
        onClicked: {
          SequenceListModel.removeRows(lvseq.currentIndex, 1)
        }
      }
      QStylizedButton { /* move down */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "\u25BC"
        font.pointSize: root.fontsize
        onClicked: {
          if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex+1)) {
            lvseq.currentIndex = lvseq.currentIndex+1;
          }
        }
      }
      Rectangle { /* spacer */
        Layout.preferredHeight: 10
        Layout.fillWidth: true
        color: "transparent"
      }
      QStylizedButton { /* clear list */
        enabled: !isTreating
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "Clear"
        font.pointSize: root.fontsize
        onClicked: {
          var d = DynamicQML.createDynamicObject(mainwindow, "QMessageDialog.qml", {
            'title': 'Clear All Leaflet Configurations?',
            'text': "Are you sure you want to clear all leaflet configurations from the list?",
            'standardButtons': 4195328 /* StandardButton.Ok | StandardButton.Cancel */
          })
          d.onAccepted.connect( function() {
            SequenceListModel.clear()
            footer_status.text = "Cleared all leaflet configurations"
            d.destroy(); /* cleanup */
          });
          d.onRejected.connect( function() { d.destroy(); /* cleanup */ });
          d.open()
        }
      }
    }

    Rectangle { /* spacer */
      Layout.preferredHeight: 10
      Layout.fillWidth: true
      color: "transparent"
    }
    ColumnLayout {
      id: treat_control_group
      Layout.fillWidth: true
      spacing: -1*children[2].borderwidth

      Label {
        text: "Treatment"
        font.pointSize: root.fontsize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
      }
      Timer {
        id: treatment_timer
        repeat: true
        onRunningChanged: {
          if (running == true) {
            isTreating = true
            interval = SequenceListModel.data(lvseq.currentIndex, 'timecode_ms');
          } else {
            isTreating = false
          }
        }
        onTriggered: {
          if (lvseq.currentIndex == -1 || lvseq.currentIndex >= (SequenceListModel.rowCount()-1)) {
            stop()
            if (running == false) {
              footer_status.text = "Treatment finished"
            } else {
              console.error("Error ending treatment")
            }
          } else {
            // console.debug('advancing to next leaflet configuration')
            lvseq.next()
            var duration = SequenceListModel.data(lvseq.currentIndex, 'timecode_ms')
            // console.debug('beam-on duration is ' + duration + ' ms');
            interval = duration;
          }
        }
      }
      QStylizedButton { /* Start Treatment */
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: !isTreating ? "Start" : "Pause"
        font.pointSize: root.fontsize
        onClicked: {
          if (!isTreating) {
            footer_status.text = "Treatment started";
            treatment_timer.start()
          } else {
            footer_status.text = "Treatment paused";
            treatment_timer.stop();
          }
        }
      }
      QStylizedButton { /* Reset Treatment */
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "Reset"
        font.pointSize: root.fontsize
        onClicked: {
          footer_status.text = "Treatment reset";
          lvseq.currentIndex = 0;
          treatment_timer.restart();
        }
      }
    }
    Rectangle { /* spacer */
      Layout.preferredHeight: 10
      Layout.fillWidth: true
      color: "transparent"
    }
    ColumnLayout {
      id: treat_indicators
      visible: isTreating
      Layout.fillWidth: true

      Label {
        text: "Sequence"
        font.pointSize: root.fontsize
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        Label {
          id: treat_cur_index
          text: (parseInt(lvseq.currentIndex, 10) + 1)
          font.pointSize: root.fontsize
          horizontalAlignment: Text.AlignHCenter
        }
        Label {
          text: " of "
          font.pointSize: root.fontsize
          horizontalAlignment: Text.AlignHCenter
        }
        Label {
          id: treat_tot_index
          text: SequenceListModel.size
          font.pointSize: root.fontsize
          horizontalAlignment: Text.AlignHCenter
        }
      }
      Rectangle { /* spacer */
        Layout.preferredHeight: 15
        Layout.fillWidth: true
        color: "transparent"
      }
      Label {
        // TODO: FINISH
        id: treat_time_elapsed
        text: "00:00"
        visible: false
        font.pointSize: root.fontsize + 8*fratio
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
