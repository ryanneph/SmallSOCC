// Leaflet.qml
import QtQuick 2.5
import LeafletBase 1.0

Item {
    id: leaflet
    property alias leaflet_index: leaflet_base.index
    property alias orientation: leaflet_base.orientation
    property alias direction: leaflet_base.direction
    property alias extension: leaflet_base.extension
    property point beginDrag: Qt.point(0, 0)
    property int   full_range: 1

    x: 0; y: 0
    z: leaflet.orientation === LeafletBase.Horizontal ? 2 : 1

    property point start
    Component.onCompleted: {
        start = Qt.point(x, y);
    }

    function isHorizontal() {
        return leaflet.orientation === LeafletBase.Horizontal ? true : false
    }
    function isPositive() {
        return leaflet.direction === LeafletBase.Positive ? true : false
    }

    LeafletBase {
        property var dir: leaflet.direction === LeafletBase.Positive ? 1 : -1
        id: leaflet_base
        extension: {
            if (leaflet.orientation === LeafletBase.Horizontal) {
                return parseInt(255*dir*(parent.x-parent.start.x)*1.0/(leaflet.full_range))
            } else {
                return parseInt(255*dir*(parent.y-parent.start.y)*1.0/(leaflet.full_range))
            }
        }
    }
    Rectangle {
        id: compound
        width: childrenRect.width
        height: childrenRect.height
        color: "transparent"
        x: isHorizontal() && isPositive() ? -rect_stem.width : 0
        y: !isHorizontal() && isPositive() ? -rect_stem.height : 0

        Rectangle {
            id: rect_leaf
            width: leaflet.width
            height: leaflet.height
            border.color: "gray"
            color: "#67707F"
            // color: "#1111ee"
            opacity: 0.9
            anchors.right: {
                if (leaflet.orientation === LeafletBase.Horizontal && leaflet.direction === LeafletBase.Positive) {
                    return compound.right
                } else { return undefined }
            }
            anchors.left: {
                if (leaflet.orientation === LeafletBase.Horizontal && leaflet.direction === LeafletBase.Negative) {
                    return compound.left
                } else { return undefined }
            }
            anchors.top: {
                if (leaflet.orientation === LeafletBase.Vertical && leaflet.direction === LeafletBase.Negative) {
                    return compound.top
                } else { return undefined }
            }
            anchors.bottom: {
                if (leaflet.orientation === LeafletBase.Vertical && leaflet.direction === LeafletBase.Positive) {
                    return compound.bottom
                } else { return undefined }
            }
        }
        Rectangle {
            id: rect_stem
            color: "#222222"
            border.color: rect_leaf.border.color
            property var factor: 0.2;
            width: leaflet.orientation === LeafletBase.Horizontal ? (rect_leaf.width) : (factor*rect_leaf.width)
            height: leaflet.orientation === LeafletBase.Horizontal ? (factor*rect_leaf.height) : (rect_leaf.height)

            anchors.verticalCenter: leaflet.orientation === LeafletBase.Horizontal ? rect_leaf.verticalCenter : undefined
            anchors.horizontalCenter: leaflet.orientation === LeafletBase.Horizontal ? undefined : rect_leaf.horizontalCenter
            anchors.right: {
                if (leaflet.orientation === LeafletBase.Horizontal && leaflet.direction === LeafletBase.Positive) {
                    return rect_leaf.left
                } else { return undefined }
            }
            anchors.left: {
                if (leaflet.orientation === LeafletBase.Horizontal && leaflet.direction === LeafletBase.Negative) {
                    return rect_leaf.right
                } else { return undefined }
            }
            anchors.top: {
                if (leaflet.orientation === LeafletBase.Vertical && leaflet.direction === LeafletBase.Negative) {
                    return rect_leaf.bottom
                } else { return undefined }
            }
            anchors.bottom: {
                if (leaflet.orientation === LeafletBase.Vertical && leaflet.direction === LeafletBase.Positive) {
                    return rect_leaf.top
                } else { return undefined }
            }
        }
        Text {
            id: leaflet_label
            anchors.horizontalCenter: rect_leaf.horizontalCenter
            anchors.verticalCenter: rect_leaf.verticalCenter
            text: leaflet.leaflet_index
            color: "white"
            font.pointSize: 14
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: compound
        drag.target: leaflet
        drag.axis: leaflet.orientation === LeafletBase.Horizontal ? Drag.XAxis : Drag.YAxis
        property var dir: leaflet.direction === LeafletBase.Positive ? 1 : -1

        drag.minimumX: isPositive() ? start.x : start.x + dir*full_range
        drag.maximumX: isPositive() ? start.x + dir*full_range : start.x
        drag.minimumY: isPositive() ? start.y : start.y + dir*full_range
        drag.maximumY: isPositive() ? start.y + dir*full_range : start.y

        onPressed: {
            rect_leaf.color = "#59616d"
            // parent.beginDrag = Qt.point(parent.x, parent.y);
            console.log(parent.x, parent.y)
            console.log(drag.minimumX, drag.maximumX, drag.minimumY, drag.maximumY)
        }
        onReleased: {
            rect_leaf.color = "#67707F"
            // if (leaflet.orientation === LeafletBase.Horizontal) {
            //     leaflet.extension = parseInt(255*dir*(parent.x-parent.start.x)*1.0/(leaflet.full_range))
            // } else {
            //     leaflet.extension = parseInt(255*dir*(parent.y-parent.start.y)*1.0/(leaflet.full_range))
            // }
        }
    }
}
