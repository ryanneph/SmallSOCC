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
    Layout.minimumWidth: 270
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

      model: SequenceListModel  // see main.py for contextvariable setting
      delegate: QSequenceDelegate {}
    }
  }


  /* user props */
  property int btn_width: 90
  property int btn_height: 45
  property int fontsize: 12
  Column {
    id: list_buttons
    clip: true
    spacing: -1*children[0].borderwidth
    Layout.minimumWidth: root.btn_width
    Layout.maximumWidth: root.btn_width
    Layout.alignment: Qt.AlignTop

    QStylizedButton { /* move up */
      height: root.btn_height
      width: root.btn_width
      text: "\u25B2"
      font.pointSize: root.fontsize
      onClicked: {
        if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex-1)) {
          lvseq.currentIndex -= 1;
        }
      }
    }
    QStylizedButton { /* insert after */
      height: root.btn_height
      width: root.btn_width
      text: "+"
      font.pointSize: 16
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
      height: root.btn_height
      width: root.btn_width
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
        d.onSubmitted.connect( function(newdata) { SequenceListModel.setData(lvseq.currentIndex, newdata); } );
        d.open();
      }
    }
    QStylizedButton { /* remove */
      height: root.btn_height
      width: root.btn_width
      text: "X"
      font.pointSize: root.fontsize
      textcolor: "#FF5151"
      onClicked: {
        SequenceListModel.removeRows(lvseq.currentIndex, 1)
      }
    }
    QStylizedButton { /* move down */
      height: root.btn_height
      width: root.btn_width
      text: "\u25BC"
      font.pointSize: root.fontsize
      onClicked: {
        if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex+1)) {
          lvseq.currentIndex = lvseq.currentIndex+1;
        }
      }
    }

  }
}
