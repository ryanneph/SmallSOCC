import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQml.Models 2.2
import QtQuick.Layouts 1.3
import "dynamicqml.js" as DynamicQML

RowLayout {
  Pane { /* Sequence List */
    id: seq_list_border
    clip: true
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: 270
    property int borderwidth: 2
    padding: borderwidth
    background: Rectangle { anchors.fill: parent; border.color: "black"; border.width: parent.borderwidth; color: "#eee" }

    ListView {
      id: lvseq
      orientation: Qt.Vertical
      verticalLayoutDirection: ListView.TopToBottom
      spacing: 2
      focus: true
      currentIndex: 0
      anchors.fill: parent
      ScrollBar.vertical: ScrollBar {}

      model: SequenceListModel  // see main.py for contextvariable setting
      delegate: QSequenceDelegate {}
    }
  }



  /* user props */
  property int btn_width: 45
  property int btn_height: 45
  ColumnLayout {
    id: list_buttons
    clip: true
    spacing: -1*children[0].borderwidth
    width: btn_width
    Layout.alignment: Qt.AlignTop

    QStylizedButton { /* move up */
      Layout.preferredHeight: btn_height
      Layout.fillWidth: true
      text: "\u25B2"
      font.pointSize: 12
      onClicked: {
        if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex-1)) {
          lvseq.currentIndex = lvseq.currentIndex-1;
        }
      }
    }
    // QStylizedButton { /* insert before */
    // Layout.preferredHeight: btn_height
    // Layout.fillWidth: true
    //   text: "\u2B11+"
    //   font.pointSize: 20
    //   onClicked: SequenceListModel.insertRows(lvseq.currentIndex, 1)
    // }
    QStylizedButton { /* insert after */
      Layout.preferredHeight: btn_height
      Layout.fillWidth: true
      // text: "\u2B10+"
      text: "+"
      font.pointSize: 20
      onClicked: SequenceListModel.insertRows(lvseq.currentIndex+1, 1)
    }
    QStylizedButton { /* remove */
      Layout.preferredHeight: btn_height
      Layout.fillWidth: true
      text: "X"
      onClicked: SequenceListModel.removeRows(lvseq.currentIndex, 1)
    }
    QStylizedButton { /* move down */
      Layout.preferredHeight: btn_height
      Layout.fillWidth: true
      text: "\u25BC"
      font.pointSize: 12
      onClicked: {
        if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex+1)) {
          lvseq.currentIndex = lvseq.currentIndex+1;
        }
      }
    }
    QStylizedButton { /* Edit Item Data */
      Layout.preferredHeight: btn_height
      Layout.fillWidth: true
      text: "Edit"
      onClicked: {
        // Access SequenceItem properties through lvseq.model.get(lvseq.currentIndex)[property]
        var d = DynamicQML.createModalDialog(mainwindow, "QEditDialog.qml");
        var row = lvseq.currentIndex;
        var modelData = lvseq.model.getItem(row).get();
        console.debug(Object.getOwnPropertyNames(modelData));
        d.formdata = {
          "rot_gantry_deg": modelData.rot_couch_deg,
          "rot_couch_deg":  modelData.rot_gantry_deg,
          "description":    modelData.description
        };
        d.open();
        d.onSubmitted.connect( function(newdata) {
          console.debug("couch:"+newdata.rot_couch_deg+" gantry:"+newdata.rot_gantry_deg+" desc:"+newdata.description);
          if (lvseq.model.getItem(row).set(newdata)) {
            console.debug("NEED TO UPDATE VIEW")
          }
        } );
      }
    }

  }
}
