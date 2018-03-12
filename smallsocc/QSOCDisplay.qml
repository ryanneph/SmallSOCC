import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ColumnLayout {
  id: ul_col
  property alias soc_display: soc_display

  QLeafletAssembly { /* Leaflet Display */
    id: soc_display
    Layout.fillWidth: true /* dynamically size */
    Layout.preferredHeight: width /* keep square */
    draggable: true
    preventCollisions: false
    color_bg:    "transparent"
    color_field: "#FFFCC1"
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

    GridLayout { /* controls under soc_display */
      anchors.fill: parent
      columns: 2

      Label {
        text: "Leaflet:"
        font.pixelSize: 16
        Layout.column: 0
        Layout.row: 0
      }
      Label {
        text: "Extension:"
        font.pixelSize: 16
        Layout.column: 0
        Layout.row: 1
      }
      SpinBox {
        id: leaflet_spinbox
        Layout.column: 1
        Layout.row: 0
        editable: true
        from: 0
        to: soc_display.nleaflets-1
        value: from
        Component.onCompleted: {
          // change spinbox value when leaflet is clicked
          soc_display.onLeafletPressed.connect(function(index) { value = index; });
        }
      }
      SpinBox {
        id: ext_spinbox
        Layout.column: 1
        Layout.row: 1
        editable: true
        from: 0
        to: soc_display.max_extension
        value: soc_display.leaflets[leaflet_spinbox.value].extension
        onValueModified: {
          soc_display.setExtension(leaflet_spinbox.value, value)
          // TODO: KLUDGE should better differentiate signals from assembly update vs leaflet update
          soc_display.onLeafletReleased(leaflet_spinbox.value)
        }
      }
      Button { /* Save SequenceItem to ListModel */
        Layout.row: 2
        Layout.fillWidth: true
        Layout.columnSpan: 2
        text: "Save Sequence Item"
        onClicked: {
          var extmap = soc_display.getExtension();
          if (qsequencelist.lvseq.currentItem == null) {
            // if no item is selected, insert new item at end of model and save leaflet config to it
            SequenceListModel.insertRows()
            qsequencelist.lvseq.currentIndex = 0;

          }
          if (!SequenceListModel.setData(qsequencelist.lvseq.currentIndex, extmap, 'extension_list')) {
            console.warn("failed to save 'extension_list' to item " + (parseInt(qsequencelist.lvseq.currentIndex, 10)+1));
            return;
          }
          // TODO: maybe we can update display here without publishing same extensions twice
          updateSOCConfig();
          footer_status.text = 'Leaflet configuration saved to item #' + (parseInt(qsequencelist.lvseq.currentIndex, 10)+1);
        }
      }

      // //DEBUG
      // Label {
      //   text: "win width:"
      //   Layout.column: 0
      //   Layout.row: 3
      // }
      // Label {
      //   text: mainwindow.width
      //   Layout.column: 1
      //   Layout.row: 3
      // }
      // Label {
      //   text: "win height:"
      //   Layout.column: 0
      //   Layout.row: 4
      // }
      // Label {
      //   text: mainwindow.height
      //   Layout.column: 1
      //   Layout.row: 4
      // }
      // Label {
      //   text: ul_col.width
      //   Layout.column: 1
      //   Layout.row: 5
      // }
    }
  }
}

