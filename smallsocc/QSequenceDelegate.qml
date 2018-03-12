import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Pane {
  id: seqdelegate
  height: seqdelegate_content.height + 8
  padding: 0
  width: seq_list_border.availableWidth-lvseq.spacing*2 /* uniform look on all sides */
  anchors.horizontalCenter: parent.horizontalCenter
  background: Rectangle {
    anchors.fill: parent;
    border.color: seqdelegate.state=="" ? "#B8B8B8"  : Qt.darker(seqdelegate.bgcolor, 1.6);
    radius: 5
    color: seqdelegate.bgcolor
  }
  state: ""

  /* user props */
  property color fgcolor_light: "#FFFFFF"
  property color fgcolor_dark: "#111111"
  property color bgcolor:          "transparent"
  property color content_fgcolor:  fgcolor_dark
  property color index_fgcolor:    fgcolor_dark

  states: [
    State {
      name: "TREAT_SELECTED"
      when: seqdelegate.ListView.isCurrentItem && isTreating
      PropertyChanges {
        target: seqdelegate
        content_fgcolor: fgcolor_light
        index_fgcolor: fgcolor_light
        bgcolor: "#11B84F"
      }
    },
    State {
      name: "SELECTED"
      when: seqdelegate.ListView.isCurrentItem && !is_unsaved
      PropertyChanges {
        target: seqdelegate
        content_fgcolor: fgcolor_light
        index_fgcolor: fgcolor_light
        bgcolor: "#3080ED"
      }
    },
    State {
      name: "MODIFIED"
      when: is_unsaved && !seqdelegate.ListView.isCurrentItem
      PropertyChanges {
        target: seqdelegate
        content_fgcolor: fgcolor_dark
        index_fgcolor: fgcolor_dark
        bgcolor: "#FCA87A"
      }
    },
    State {
      name: "MOD_SELECT"
      when: seqdelegate.ListView.isCurrentItem && is_unsaved
      PropertyChanges {
        target: seqdelegate
        content_fgcolor: fgcolor_light
        index_fgcolor: fgcolor_light
        bgcolor: "#DD4D00"
      }
    }
  ]

  RowLayout {
    anchors.fill: parent
    spacing: 10
    Item { /* print index and duration */
      Layout.preferredHeight: seqdelegate.height
      Layout.preferredWidth: 55
      Layout.leftMargin: lvseq.spacing + parseInt(parent.spacing/2)
      Label { /* print index */
        id: seqdelegate_index_label
        height: parseInt(seqdelegate.height*0.7)
        anchors.left: parent.left;
        anchors.right: parent.right
        anchors.top: parent.top
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: index+1
        color: index_fgcolor
        font.pointSize: 16
      }
      Label { /* print timecode */
        id: seqdelegate_timecode_label
        width: seqdelegate_index_label.width
        height: seqdelegate.height - seqdelegate_index_label.height
        anchors.left: parent.left;
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: Number(timecode_ms).toFixed(0) + ' ms'
        color: index_fgcolor
        font.pointSize: 9
      }
    }
    Column { /* print content */
      id: seqdelegate_content
      Layout.fillWidth: true
      anchors.verticalCenter: parent.verticalCenter
      Text { color: content_fgcolor;
             text: "<b>couch:</b> " + Number(rot_couch_deg).toFixed(1) +
             " deg, <b>gantry:</b> " + Number(rot_gantry_deg).toFixed(1) + " deg"
      }
      Text { color: content_fgcolor; text: "<b>desc:</b>  " + description }
      Text { color: content_fgcolor; text: "<b>added:</b> " + date_created }
      Text { color: content_fgcolor; text: "<b>type:</b>  " + type }
    }
  }
  MouseArea {
    anchors.fill: parent
    onClicked: { lvseq.currentIndex = index }
  }
}
