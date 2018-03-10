import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3

Dialog {
  title: "Sequence Item Editor"
  standardButtons: Dialog.Save | Dialog.Discard
  // width: 600
  // height: 500

  // pass new data back to handler
  signal onSubmitted(var newdata)
  onAccepted: onSubmitted({
    "rot_couch_deg":  text_couch.text,
    "rot_gantry_deg": text_gantry.text,
    "description":    text_desc.text,
    "timecode_ms":    text_timecode.text
    // "extension_list": [0,0,0,0,0,0,0,0]
  })

  // populate with current data
  property var formdata: undefined
  onVisibleChanged: {
    if (visible && formdata) {
      text_gantry.text   = formdata.rot_gantry_deg;
      text_couch.text    = formdata.rot_couch_deg;
      text_desc.text     = formdata.description;
      text_timecode.text = formdata.timecode_ms;
    }
  }

  GridLayout {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    columns: 2
    rowSpacing: 2

    Label { text: "Couch Angle (Deg):" }
    TextField {
      id: text_couch
      Layout.fillWidth: true
      validator: IntValidator {bottom: -360; top: 360}
    }
    Label { text: "Gantry Angle (Deg):" }
    TextField {
      id: text_gantry
      Layout.fillWidth: true
      validator: IntValidator {bottom: -360; top: 360}
    }
    Label { text: "Description" }
    TextField {
      id: text_desc
      Layout.fillWidth: true
    }
    Label { text: "Timecode (ms)" }
    TextField {
      id: text_timecode
      Layout.fillWidth: true
      validator: DoubleValidator {bottom: 0}
    }
  }
}
