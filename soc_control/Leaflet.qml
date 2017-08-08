// Leaflet.qml
import QtQuick 2.5

Item {
    id: leaflet
    property int idx: 0
    property alias cellColor: rectangle.color
    signal clicked(color cellColor)
    property point beginDrag;
    property int orientation;

    width: 300; height: 150
    x: -150; y:150

    // Drag.active: mouseArea.drag.active

    Rectangle {
        id: rectangle
        border.color: "gray"
        color: "#1111ee"
        anchors.fill: leaflet
    }
    MouseArea {
        id: mouseArea
        anchors.fill: leaflet
        onClicked: rectangle.color = "red"
        drag.target: leaflet
        drag.axis: Drag.XAxis
        onPressed: {
            parent.beginDrag = Qt.point(parent.x, parent.y);
        }
    }
    Text {
        id: leaflet_label
        anchors.horizontalCenter: leaflet.horizontalCenter
        anchors.verticalCenter: leaflet.verticalCenter
        text: leaflet.idx
        color: "white"
        font.pointSize: 14
    }
}
