import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

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

      delegate: QSequenceDelegate {}
      model: SequenceListModel  // see main.py for contextvariable setting
    }
  }



  Pane { /* vstack of ListView buttons */
    id: btn_pane
    height: btn_height*list_buttons.length
    width: btn_width
    anchors.top: parent.top
    padding: 2
    background: Rectangle { anchors.fill: parent; color: "#333" }

    /* user props */
    property int btn_width: 65
    property int btn_height: 50
    property color btn_bgcolor: "#555"
    property color btn_fgcolor: "#ededed"
    property font btn_font: Qt.font({ pointSize: 12, bold: true})

    ColumnLayout {
      id: list_buttons
      spacing: btn_pane.padding

      Button { /* move up */
        id: btn_moveup
        text: "\u25B2"
        font.pointSize: 12
        onClicked: {
          if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex-1)) {
            lvseq.currentIndex = lvseq.currentIndex-1;
          }
        }
      }
      // Button { /* insert before */
      //   text: "\u2B11+"
      //   font.pointSize: 20
      //   onClicked: SequenceListModel.insertRows(lvseq.currentIndex, 1)
      // }
      Button { /* insert after */
        // text: "\u2B10+"
        text: "+"
        font.pointSize: 20
        onClicked: SequenceListModel.insertRows(lvseq.currentIndex+1, 1)
      }
      Button { /* remove */
        text: "X"
        font: btn_pane.btn_font
        onClicked: SequenceListModel.removeRows(lvseq.currentIndex, 1)
      }
      Button { /* move down */
        id: btn_movedown
        text: "\u25BC"
        font.pointSize: 12
        onClicked: {
          if (SequenceListModel.moveRows(lvseq.currentIndex, 1, lvseq.currentIndex+1)) {
            lvseq.currentIndex = lvseq.currentIndex+1;
          }
        }
      }
      Button { /* Load JSON */
        text: "Load"
        font: btn_pane.btn_font
        onClicked: null
      }
      Button { /* Load JSON */
        text: "Save"
        font: btn_pane.btn_font
        onClicked: null
      }

    }
  }
}
