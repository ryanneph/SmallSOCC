import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3

Dialog {
  title: "Sequence Item Editor"
  standardButtons: Dialog.Save | Dialog.Discard
  width: 600
  height: 500

  // pass new data back to handler
  signal onSubmitted(var newdata)
  onAccepted: onSubmitted({
    "rot_gantry_deg": text_gantry.text,
    "rot_couch_deg":  text_couch.text,
    "description":    text_desc.text,
    "extension_list": [0,0,0,0,0,0,0,0]
  })

  // populate with current data
  property var formdata: undefined
  onVisibleChanged: {
    if (visible && formdata) {
      text_gantry.text = formdata.rot_gantry_deg;
      text_couch.text  = formdata.rot_couch_deg;
      text_desc.text   = formdata.description;
    }
  }

  GridLayout {
    anchors.fill: parent

    Label {
      Layout.row: 1
      Layout.column: 1
      text: "Gantry Angle (Deg):"
    }
    TextField {
      id: text_gantry
      Layout.row: 1
      Layout.column: 2
      Layout.fillWidth: true
    }

    Label {
      Layout.row: 2
      Layout.column: 1
      text: "Couch Angle (Deg):"
    }
    TextField {
      id: text_couch
      Layout.row: 2
      Layout.column: 2
      Layout.fillWidth: true
    }

    Label {
      Layout.row: 3
      Layout.column: 1
      text: "Description"
    }
    TextField {
      id: text_desc
      Layout.row: 3
      Layout.column: 2
      Layout.fillWidth: true
    }
  }
}
