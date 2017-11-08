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

  Item {
    id: debugborder
    Rectangle {
      anchors.fill: parent
      border.color: "red"
      color: "#EEE"
    }
  }

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

        QLeafletAssembly { /* Leaflet Display */
          id: soc_display
          anchors.top: parent.top
          Layout.fillWidth: true /* dynamically size */
          Layout.preferredHeight: width /* keep square */
          Layout.minimumWidth: 200
          Layout.maximumWidth: 500
          draggable: true
          preventCollisions: false
        }
        Pane {
          id: leaflet_editor
          clip: true
          Layout.fillHeight: true
          Layout.fillWidth: true

          // TODO: DEBUG
          background: debugborder

          GridLayout { /* controls under soc_display */
            columns: 3
            Label {
              text: "Leaflet:"
              font.pixelSize: 16
              Layout.column: 1
              Layout.row: 1
            }
            Label {
              text: "Extension:"
              font.pixelSize: 16
              Layout.column: 1
              Layout.row: 2
            }
            SpinBox {
              id: leaflet_spinbox
              Layout.column: 2
              Layout.row: 1
              objectName: "leaflet_spinbox"
              editable: true
              from: 0
              to: soc_display.nleaflets-1
              value: from
              Component.onCompleted: {
                // change spinbox value when leaflet is clicked
                soc_display.onLeafletSelected.connect(function(index) { value = index; });
              }
            }
            SpinBox {
              id: ext_spinbox
              Layout.column: 2
              Layout.row: 2
              objectName: "ext_spinbox"
              editable: true
              from: 0
              to: soc_display.max_extension
              value: soc_display.leaflets[leaflet_spinbox.value].extension
              onValueModified: {
                soc_display.setExtension(leaflet_spinbox.value, value)
              }
            }
            Button { /* set ext */
              Layout.column: 3
              Layout.row: 2
              Layout.preferredWidth: 50
              text: "set"
              font.pointSize: 12
              visible: false
            }

            //DEBUG
            Label {
              text: "win width:"
              Layout.column: 1
              Layout.row: 4
            }
            Label {
              text: mainwindow.width
              Layout.column: 2
              Layout.row: 4
            }
            Label {
              text: "win height:"
              Layout.column: 1
              Layout.row: 5
            }
            Label {
              text: mainwindow.height
              Layout.column: 2
              Layout.row: 5
            }
          }
        }
      }
      QSequenceList {} /* ListView + Buttons */
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

      RowLayout {
        TextInput {
          id: field_json_path
          width: 100
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
