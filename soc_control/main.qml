import QtQuick 2.5
import QtQuick.Controls 1.0  // ApplicationWindow
import QtQuick.Controls.Styles 1.3  // ApplicationWindowStyle
import LeafletBase 1.0

ApplicationWindow {
    visible: true
    title: mainwindow_title
    id: mainwindow
    width: 600; height: 600
    style: ApplicationWindowStyle {
        background: Rectangle{
            color: "#FFFFFF"
        }
    }

    Rectangle {
        id: soc_display
        width: 600; height: 600
        color: "#aaaaaa"

        Rectangle {
            id: beambounds
            width: soc_display.height/2
            height: soc_display.height/2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            border.width: 4
            border.color: "red"
            color: "#F0F6F8"

            // Path {
            //     id: left_bound
            //     startX: 100
            //     startY: 100
            //     PathLine {
            //         relativeX: soc_display.width
            //         relativeY: soc_display.height
            //     }
            //     PathAttribute { name: "color"; value: "black" }
            // }
        }

        Leaflet {
            leaflet_index: 0
            width: beambounds.width
            height: beambounds.height/2
            orientation: LeafletBase.Horizontal
            direction: LeafletBase.Negative
            full_range: soc_display.width/2

            x: (soc_display.width/2) + (beambounds.width/2)
            y: (soc_display.height/2) - (beambounds.height/2)
        }
        Leaflet {
            leaflet_index: 1
            width: beambounds.width
            height: beambounds.height/2
            orientation: LeafletBase.Horizontal
            direction: LeafletBase.Negative
            full_range: soc_display.width/2

            x: (soc_display.width/2) + (beambounds.width/2)
            y: (soc_display.height/2)
        }
        Leaflet {
            leaflet_index: 2
            width: beambounds.width/2
            height: beambounds.height
            orientation: LeafletBase.Vertical
            direction: LeafletBase.Negative
            full_range: soc_display.height/2

            x: (soc_display.width/2)
            y: (soc_display.height/2) + (beambounds.height/2)
        }
        Leaflet {
            leaflet_index: 3
            width: beambounds.width/2
            height: beambounds.height
            orientation: LeafletBase.Vertical
            direction: LeafletBase.Negative
            full_range: soc_display.height/2

            x: (soc_display.width/2) - (beambounds.width/2)
            y: (soc_display.height/2) + (beambounds.height/2)
        }
        Leaflet {
            leaflet_index: 4
            width: beambounds.width
            height: beambounds.height/2
            orientation: LeafletBase.Horizontal
            full_range: soc_display.width/2

            x: (soc_display.width/2)-(3*beambounds.width/2)
            y: (soc_display.height/2)
        }
        Leaflet {
            leaflet_index: 5
            width: beambounds.width
            height: beambounds.height/2
            orientation: LeafletBase.Horizontal
            full_range: soc_display.width/2

            x: (soc_display.width/2)-(3*beambounds.width/2)
            y: (soc_display.height/2) - (beambounds.height/2)
        }
        Leaflet {
            leaflet_index: 6
            width: beambounds.width/2
            height: beambounds.height
            orientation: LeafletBase.Vertical
            full_range: soc_display.height/2

            x: (soc_display.width/2) - (beambounds.width/2)
            y: (soc_display.height/2) - (3*beambounds.height/2)
        }
        Leaflet {
            leaflet_index: 7
            width: beambounds.width/2
            height: beambounds.height
            orientation: LeafletBase.Vertical
            full_range: soc_display.height/2

            x: (soc_display.width/2)
            y: (soc_display.height/2) - (3*beambounds.height/2)
        }
    }
}
