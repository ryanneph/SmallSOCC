import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import "dynamicqml.js" as DynamicQML


ApplicationWindow {
  visible: true
  title: mainwindow_title // global property injection
  id: mainwindow
  width: 1000
  height: 800
  minimumHeight: 700
  minimumWidth: 850
  // maximumHeight: height
  // maximumWidth: width
  color: "#EEE"
  footer: QTimedText {id: "footer_status"; interval: 5000}

  ColumnLayout {
    /* split into two horizontal control containers */
    id: controls_container
    anchors.fill: parent
    anchors.margins: 20
    spacing: controls_container.anchors.margins
    RowLayout {
      id: upper_half
      spacing: controls_container.anchors.margins

      QSOCDisplay { id: displaycontainer }   /* QLeafletAssembly + controls */
      QSequenceList { id: seqlist } /* ListView + Buttons */
    }

    Pane { /* filedialog controls */
      id: bottom_frame
      Layout.maximumHeight: 200
      Layout.minimumHeight: 75
      Layout.fillWidth: true
      background: QDebugBorder {}

      RowLayout {
        anchors.fill: parent
        TextInput {
          id: field_json_path
          Layout.fillWidth: true
          readOnly: true
          text: "json_path"
        }
        Button { /* Load JSON */
          text: "Load"
          Layout.alignment: Qt.AlignRight
          onClicked: {
            var d = DynamicQML.createModalDialog(mainwindow, "QFileDialog.qml", {"intent": "load"});
            d.open();
            d.onSubmitted.connect( function(obj) {
              if (SequenceListModel.readFromJson(obj.path)) {
                field_json_path.text = obj.path;
                var msg = "Sequence list loaded from \""+obj.path+"\"";
                console.debug(msg);
                footer_status.text = msg;
                field_json_path.text = obj.path;
              }
              obj.destroy(); /* cleanup */
            });
          }
        }
        Button { /* Save JSON */
          text: "Save"
          Layout.alignment: Qt.AlignRight
          onClicked:{
            var d = DynamicQML.createModalDialog(mainwindow, "QFileDialog.qml", {"intent": "save"});
            d.open();
            d.onSubmitted.connect( function(obj) {
              if (SequenceListModel.writeToJson(obj.path)) {
                var msg = "Sequence list saved to \""+obj.path+"\"";
                console.debug(msg);
                footer_status.text = msg;
                field_json_path.text = obj.path;
              }
              obj.destroy(); /* cleanup */
            });
          }
        }
      }

    }
  }
}
