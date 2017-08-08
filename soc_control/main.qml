import QtQuick 2.5
import QtQuick.Controls 1.0  // ApplicationWindow
import QtQuick.Controls.Styles 1.3  // ApplicationWindowStyle
// import Leaflets 1.0

ApplicationWindow {
    visible: true
    title: "SOC Controller - v0.1"
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
        color: "#F0F6F8"

        Rectangle {
            id: beambounds
            width: soc_display.height/2
            height: soc_display.height/2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            border.width: 2
            border.color: "red"
            color: "transparent"
        }

        Leaflet {
            id: leaflet0
            idx: 0
            width: beambounds.width
            height: beambounds.height/2
            orientation: Leaflet.Orientation.Horizontal

            x: (soc_display.width/2) + (beambounds.width/2)
            y: (soc_display.height/2) - (beambounds.height/2)
        }
        Leaflet {
            id: leaflet1
            idx: 1
            width: beambounds.width
            height: beambounds.height/2
            x: (soc_display.width/2) + (beambounds.width/2)
            y: (soc_display.height/2)
        }
        Leaflet {
            id: leaflet2
            idx: 2
            width: beambounds.width/2
            height: beambounds.height
            x: (soc_display.width/2)
            y: (soc_display.height/2) + (beambounds.height/2)
        }
        Leaflet {
            id: leaflet3
            idx: 3
            width: beambounds.width/2
            height: beambounds.height
            x: (soc_display.width/2) - (beambounds.width/2)
            y: (soc_display.height/2) + (beambounds.height/2)
        }
        Leaflet {
            id: leaflet4
            idx: 4
            width: beambounds.width
            height: beambounds.height/2
            x: (soc_display.width/2)-(3*beambounds.width/2)
            y: (soc_display.height/2)
        }
        Leaflet {
            id: leaflet5
            idx: 5
            width: beambounds.width
            height: beambounds.height/2
            x: (soc_display.width/2)-(3*beambounds.width/2)
            y: (soc_display.height/2) - (beambounds.height/2)
        }
        Leaflet {
            id: leaflet6
            idx: 6
            width: beambounds.width/2
            height: beambounds.height
            x: (soc_display.width/2) - (beambounds.width/2)
            y: (soc_display.height/2) - (3*beambounds.height/2)
        }
        Leaflet {
            id: leaflet7
            idx: 7
            width: beambounds.width/2
            height: beambounds.height
            x: (soc_display.width/2)
            y: (soc_display.height/2) - (3*beambounds.height/2)
        }
    }
}
