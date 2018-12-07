import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import "dynamicqml.js" as DynamicQML


ApplicationWindow {
  visible: true
  title: mainwindow_title // global property injection
  id: mainwindow
  width: 1200*sratio
  height: 900*sratio
  minimumHeight: 700*sratio
  minimumWidth: 850*sratio
  // maximumHeight: height
  // maximumWidth: width
  property color color_bgbase: "#F4F4F4"
  color: color_bgbase
  footer: QTimedText {id: "footer_status"; interval: 5000}

  // global state variables TODO: Replace with application state
  property bool isTreating: false

  // prompt a refresh of the SOC display using data from the currently selected SequenceItem
  // note: this will also prompt a change in HW positions to match display unless 'false' is passed as argument
  function updateSOCConfig(publishtohw) {
    if (publishtohw === undefined) { publishtohw = true; }
    if (qsequencelist.lvseq.currentIndex < 0 || SequenceListModel.rowCount() <= 0) {
      leaflet_assembly.reset();
    } else {
      var map = {};
      var extarray = SequenceListModel.data(qsequencelist.lvseq.currentIndex, 'extension_list')
      if (extarray != null) {
        for (var i=0; i<extarray.length; ++i) {
          map[i] = extarray[i];
        }
        leaflet_assembly.setExtension(map);
      }
    }
    // TODO: KLUDGE should better differentiate signals from assembly update vs leaflet update
    if (publishtohw) {
      leaflet_assembly.publishToHW()
    }
  }

  StateGroup {
    id: app_state
    state: 'MODE_NORMAL'
    states: [
      State {
        name: "MODE_NORMAL"
        PropertyChanges { target: btn_calibrate_accept; visible: false }
        PropertyChanges { target: btn_calibrate_cancel; visible: false }
        PropertyChanges { target: btn_calibrate; visible: true }
        StateChangeScript {
          // script: leaflet_assembly.enableHWLink();
        }
      },
      State {
        name: "MODE_CALIBRATE"
        PropertyChanges { target: btn_calibrate; visible: false }
        PropertyChanges { target: btn_calibrate_accept; visible: true }
        PropertyChanges { target: btn_calibrate_cancel; visible: true }
        PropertyChanges { target: leaflet_assembly; preventCollisions: false; limitTravel: false }
        PropertyChanges { target: qsequencelist; enabled:false }
        StateChangeScript {
          // script: leaflet_assembly.disableHWLink();
        }
      }
    ]
  }

  // startup signal/slot connections
  Component.onCompleted: {
    // deselect items when loading new list and reset display and hw
    SequenceListModel.onModelReset.connect(function() {
      qsequencelist.lvseq.currentIndex = -1;
      updateSOCConfig(true);
    });

    // Keep SOC Display valid on window resize - no HW changes occur
    mainwindow.onWidthChanged.connect(function() { leaflet_assembly.refresh(); });
    mainwindow.onHeightChanged.connect(function() { leaflet_assembly.refresh(); });

    // select nothing and prevent hardware from synchronizing on application launch
    qsequencelist.lvseq.currentIndex = -1;

    // keep SOC Display and HW in sync with currentIndex in listview
    qsequencelist.lvseq.onCurrentItemChanged.connect(updateSOCConfig);
  }


  ColumnLayout {
    /* split into two horizontal control containers */
    id: controls_container
    anchors.fill: parent
    anchors.margins: 10
    anchors.bottomMargin: 0
    spacing: controls_container.anchors.margins
    RowLayout {
      id: upper_half
      spacing: controls_container.anchors.margins
      Layout.fillWidth: true

      ColumnLayout {
        id: qsocdisplay
        Layout.alignment: Qt.AlignTop
        Layout.fillHeight: true
        Layout.minimumWidth: 250*sratio
        Layout.maximumWidth: 500*sratio
        enabled: !isTreating

        QLeafletAssembly { /* Leaflet Display */
          id: leaflet_assembly
          Layout.fillWidth: true /* dynamically size */
          Layout.preferredHeight: width /* keep square */
          draggable: true
          limitTravel: true
          preventCollisions: true
          collision_buffer: 0 /* set spacing between companion leaflets to prevent hw issues */
          color_bg:    "transparent"
          color_field: "#FFFEE5"
          color_leaf:  "#7B7B7B"
          color_stem:  "#000000"
          opacity_leaf: 0.90
        }
        Pane {
          id: leaflet_editor
          clip: true
          Layout.fillWidth: true

          // TODO: DEBUG
          background: QDebugBorder {}

          GridLayout { /* controls under leaflet_assembly */
            anchors.fill: parent
            columns: 2

            Label {
              text: "Leaflet:"
              font.pointSize: 12*fratio
              Layout.column: 0
              Layout.row: 0
            }
            Label {
              text: "Extension:"
              font.pointSize: 12*fratio
              Layout.column: 0
              Layout.row: 1
            }
            SpinBox {
              id: leaflet_spinbox
              Layout.column: 1
              Layout.row: 0
              editable: true
              from: 0
              to: leaflet_assembly.nleaflets-1
              value: from
              Component.onCompleted: {
                // change spinbox value when leaflet is clicked
                leaflet_assembly.onLeafletPressed.connect(function(index) { value = index; });
              }
            }
            SpinBox {
              id: ext_spinbox
              Layout.column: 1
              Layout.row: 1
              editable: true
              from: leaflet_assembly.leaflets[leaflet_spinbox.value].min_safe_extension
              to: leaflet_assembly.leaflets[leaflet_spinbox.value].max_safe_extension
              value: leaflet_assembly.leaflets[leaflet_spinbox.value].extension
              onValueModified: {
                leaflet_assembly.setExtension(leaflet_spinbox.value, value)
                // TODO: KLUDGE should better differentiate signals from assembly update vs leaflet update
                leaflet_assembly.onLeafletReleased(leaflet_spinbox.value)
              }
            }
            Button { /* Save SequenceItem to ListModel */
              Layout.row: 2
              Layout.fillWidth: true
              text: "Save Leaflet Configuration"
              onClicked: {
                var extmap = leaflet_assembly.getExtension();
                if (qsequencelist.lvseq.currentItem == null) {
                  // if no item is selected, insert new item at end of model and save leaflet config to it
                  SequenceListModel.insertRows()
                  qsequencelist.lvseq.currentIndex = 0;

                }
                var _data = {'extension_list': extmap, 'type': 'Manual'}
                if (!SequenceListModel.setData(qsequencelist.lvseq.currentIndex, _data)) {
                  console.warn("failed to save 'extension_list' to item " + (parseInt(qsequencelist.lvseq.currentIndex, 10)+1));
                  return;
                }
                updateSOCConfig(false);
                footer_status.text = 'Leaflet configuration saved to item #' + (parseInt(qsequencelist.lvseq.currentIndex, 10)+1);
              }
            }
            Button { /* Reset SequenceItem */
              Layout.row: 2
              Layout.column: 1
              Layout.fillWidth: true
              text: "Reset Leaflet Configuration"
              onClicked: {
                updateSOCConfig();
                footer_status.text = 'Leaflet configuration reset';
              }
            }
            RowLayout {
              Layout.row: 3
              Layout.columnSpan: 2
              Layout.fillWidth: true


              QStylizedButton { /* Start/Accept Calibration */
                id: btn_calibrate
                Layout.fillWidth: true
                borderwidth: 0
                textcolor: '#333'
                bgcolor: '#ddd'
                text: "Calibrate Leaflet Positions"
                onClicked: {
                  leaflet_assembly.setOpened()
                  footer_status.text = 'Begin Calibration';
                  app_state.state = "MODE_CALIBRATE"
                }
              }
              QStylizedButton { /* Start Calibration */
                id: btn_calibrate_accept
                visible: false
                Layout.fillWidth: true
                bgcolor: "#37ee44"
                borderwidth: 0
                text: "Accept Calibration"
                onClicked: {
                  leaflet_assembly.setCalibration()
                  updateSOCConfig()
                  footer_status.text = "Calibration Accepted";
                  app_state.state = "MODE_NORMAL"
                }
              }
              QStylizedButton { /* Cancel Calibration */
                id: btn_calibrate_cancel
                visible: false
                Layout.fillWidth: true
                // textcolor: '#333'
                // bgcolor: '#ddd'
                bgcolor: "#ff4f4f"
                borderwidth: 0
                text: "Cancel Calibration"
                onClicked: {
                  updateSOCConfig()
                  footer_status.text = "Calibration Cancelled";
                  app_state.state = "MODE_NORMAL"
                }
              }
            }

            //DEBUG
            GridLayout { /* controls under leaflet_assembly */
              // anchors.fill: parent
              columns: 2
              visible: debug_mode

              Label {
                text: "win width:"
                Layout.column: 0
                Layout.row: 0
              }
              Label {
                text: mainwindow.width
                Layout.column: 1
                Layout.row: 0
              }
              Label {
                text: "win height:"
                Layout.column: 0
                Layout.row: 1
              }
              Label {
                text: mainwindow.height
                Layout.column: 1
                Layout.row: 1
              }
              Label {
                text: "win height:"
                Layout.column: 0
                Layout.row: 2
              }
              Label {
                text: controls_container.width
                Layout.column: 1
                Layout.row: 2
              }
            }
          }
        }
      }
      QSequenceList { /* ListView + Buttons */
        id: qsequencelist
        Layout.fillWidth: true
      }
    }

    Pane { /* filedialog controls */
      id: bottom_frame
      Layout.maximumHeight: 200*sratio
      Layout.minimumHeight: 40*sratio
      Layout.fillWidth: true
      enabled: !isTreating
      background: QDebugBorder {}

      RowLayout {
        anchors.fill: parent

        TextInput {
          id: field_json_path
          Layout.fillWidth: true
          readOnly: true
          text: "Load a treatment plan..."
        }
        Button { /* Load JSON */
          text: "Load"
          Layout.alignment: Qt.AlignRight
          onClicked: {
            var d = DynamicQML.createDynamicObject(mainwindow, "QFileDialog.qml", {"intent": "load"});
            d.onAccepted.connect( function() {
              if (SequenceListModel.readFromJson(d.path)) {
                field_json_path.text = d.path;
                var msg = "Sequence list loaded from \""+d.path+"\"";
                footer_status.text = msg;
                field_json_path.text = d.path;
              }
              d.destroy(); /* cleanup */
            });
            d.open();
          }
        }
        Button { /* Save JSON */
          text: "Save"
          Layout.alignment: Qt.AlignRight
          onClicked:{
            var d = DynamicQML.createDynamicObject(mainwindow, "QFileDialog.qml", {"intent": "save"});
            d.onAccepted.connect( function() {
              if (SequenceListModel.writeToJson(d.path)) {
                var msg = "Sequence list saved to \""+d.path+"\"";
                footer_status.text = msg;
                field_json_path.text = d.path;
              }
              d.destroy(); /* cleanup */
            });
            d.open();
          }
        }
      }

    }
  }
}
