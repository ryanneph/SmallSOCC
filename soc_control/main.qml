import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ApplicationWindow {
  visible: true
  title: mainwindow_title // global property injection
  id: mainwindow
  width: 1000
  height: 800
  // minimumHeight: height
  // maximumHeight: height
  // minimumWidth: width
  // maximumWidth: width
  color: "#EEE"

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

        QLeafletAssembly2by2 { /* Leaflet Display */
          id: soc_display
          anchors.top: parent.top
          Layout.fillWidth: true /* dynamically size */
          Layout.preferredHeight: width /* keep square */
          Layout.minimumWidth: 200
          Layout.maximumWidth: 500
          draggable: false
        }
        ColumnLayout { /* Leaflet Positions Controls */
          Layout.fillWidth: true
          Item {
            id: leaflet_editor
            Layout.fillHeight: true
            RowLayout {
              anchors.fill: parent
              Label {
                text: "Extension:"
                font.pixelSize: 16
              }
              SpinBox {
                id: leaflet_spinbox
                objectName: "leaflet_spinbox"
                editable: true
                from: 1
                to: soc_display.nleaflets
                value: to
                enabled: false
              }
              SpinBox {
                id: ext_spinbox
                objectName: "ext_spinbox"
                editable: true
                from: 0
                to: soc_display.max_extension
                value: to
                enabled: false
              }
              Button { /* set ext */
                text: "set"
                font.pointSize: 12
                Layout.preferredWidth: 50
                enabled: false
              }
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

    }
  }
}
