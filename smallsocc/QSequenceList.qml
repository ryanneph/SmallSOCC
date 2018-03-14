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
        if (currentIndex >= 0 && currentIndex < model.size-1) {
          currentIndex += 1;
        }
      }
      function previous() {
        if (currentIndex >= 1 && currentIndex < model.size) {
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
        font.pointSize: root.fontsize
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

      function canStartTreatment() {
        if (SequenceListModel.size <= 0) {
          footer_status.text = 'Cannot start treatment without a valid leaflet configuration';
          return false;
        }
        return true;
      }
      function startTreatment() {
        if (!canStartTreatment()) { return; }
        if (lvseq.currentIndex < 0) { lvseq.currentIndex = 0; }
        footer_status.text = "Treatment started";
        timer_treat.start()
        timer_elapsed.restart()
      }
      function restartTreatment() {
        if (!canStartTreatment()) { return; }
        footer_status.text = "Treatment reset";
        lvseq.currentIndex = 0;
        timer_treat.restart();
        timer_elapsed.restart();
      }
      function stopTreatment() {
        if (isTreating) {
          footer_status.text = "Treatment stopped";
          timer_treat.stop();
          timer_elapsed.stop();
        }
      }


      Label {
        text: "Treatment"
        font.pointSize: root.fontsize
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
      }
      Timer {
        id: timer_treat
        repeat: true
        property int steps: 1
        onRunningChanged: {
          if (running == true) {
            isTreating = true
            interval = SequenceListModel.data(lvseq.currentIndex, 'timecode_ms');
          } else {
            isTreating = false
          }
        }
        onTriggered: {
          if (lvseq.currentIndex == -1 || lvseq.currentIndex >= (SequenceListModel.size-1)) {
            stop()
            if (running == false) {
              footer_status.text = "Treatment finished"
              var d = DynamicQML.createDynamicObject(mainwindow, "QMessageDialog.qml", {
                'title': 'Treatment Completed',
                'text': "Treatment delivery finished for " + steps + " segments in " + timer_elapsed.ftime_elapsed,
                'standardButtons': 0x400 /* StandardButton.Ok | StandardButton.Cancel */
              })
              d.onAccepted.connect( function() { d.destroy(); /* cleanup */ });
              d.open()
            } else {
              console.error("Error ending treatment")
            }
          } else {
            // console.debug('advancing to next leaflet configuration')
            do {
              steps++;
              lvseq.next()
              var duration = SequenceListModel.data(lvseq.currentIndex, 'timecode_ms')
              if (duration <= 0) { console.warn('Skipping configuration #' + lvseq.currentIndex + ' with duration: ' + duration + ' ms'); }
            } while (duration <= 0);
            interval = duration;
          }
        }
      }
      Timer {
        id: timer_elapsed
        property int secs_elapsed: 0
        property string ftime_elapsed: "00:00"
        property string ftime_total: "00:00"

        onRunningChanged: {
          if (running == true) {
            reset();
            // calculate total time
            var total = 0;
            for (var i=lvseq.currentIndex; i<SequenceListModel.size; i++) {
              total += parseFloat(SequenceListModel.data(i, 'timecode_ms'));
            }
            timer_elapsed.ftime_total = timer_elapsed.format_time(total/1000);
          }
        }

        function pad_num(num, sz) {
          var s = String(num.toFixed(0));
          while(s.length < (sz || 2)) {s= "0" + s;}
          return s;
        }
        function format_time(t) {
          var mins = Math.floor(t/60);
          var secs = t % 60;
          return pad_num(mins, 2) + ":" + pad_num(secs, 2);
        }
        function update_time() {
          ftime_elapsed = format_time(secs_elapsed);
        }
        function reset() {
          secs_elapsed = 0;
          update_time();
        }

        repeat: true
        interval: 1000
        onTriggered: {
          secs_elapsed++;
          update_time();
        }
      }
      QStylizedButton { /* Start Treatment */
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: !isTreating ? "Start" : "Stop"
        font.pointSize: root.fontsize
        onClicked: {
          if (!isTreating) { treat_control_group.startTreatment(); }
          else             { treat_control_group.stopTreatment(); }
        }
      }
      QStylizedButton { /* Reset Treatment */
        Layout.preferredHeight: root.btn_height
        Layout.fillWidth: true
        text: "Reset"
        font.pointSize: root.fontsize
        onClicked: { treat_control_group.restartTreatment(); }
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
        font.bold: true
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
      Label {
        text: "Elapsed:"
        font.pointSize: root.fontsize
        font.bold: true
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
      Label {
        id: treat_time_elapsed
        text: timer_elapsed.ftime_elapsed;
        font.pointSize: root.fontsize + 8*fratio
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
      Label {
        text: "Total:"
        font.pointSize: root.fontsize //- 2*fratio
        font.bold: true
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
      Label {
        id: treat_time_total
        text: timer_elapsed.ftime_total;
        font.pointSize: root.fontsize //- 2*fratio
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
