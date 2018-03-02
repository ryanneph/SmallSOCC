import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ColumnLayout {
  id: ul_col
  property alias soc_display: soc_display

  QLeafletAssembly { /* Leaflet Display */
    id: soc_display
    Layout.alignment: Qt.AlignTop
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
    // Layout.preferredWidth: soc_display.width

    // TODO: DEBUG
    background: QDebugBorder {}

    GridLayout { /* controls under soc_display */
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
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
        objectName: "leaflet_spinbox"
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
        objectName: "ext_spinbox"
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
            return;
            //TODO: finish implementation here
            // if no item is selected, insert new item at end of model and save leaflet config to it
            SequenceListModel.insertRows()
            qsequencelist.lvseq.currentIndex = SequenceListModel.rowCount()-1;
          }
          if (!qsequencelist.lvseq.currentItem.setData( {'extension_list': extmap} )) {
            console.warn("failed to save 'extension_list' to item "+qsequencelist.lvseq.currentIndex);
            return;
          }
          footer_status.text = 'Leaflet configuration saved to item #' + qsequencelist.lvseq.currentIndex;
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
    }
  }
}

