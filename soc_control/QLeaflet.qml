// Leaflet.qml
import QtQuick 2.5
import com.soc.types.Leaflets 1.0

Leaflet {
  id: leaflet
  function isHorizontal() { return orientation === Leaflet.Horizontal }
  function isPositive() { return direction === Leaflet.Positive }
  property var dir: isPositive() ? 1 : -1
  property point startpos
  property int   full_range
  property int   complementary_ext
  x: isHorizontal() ? parseInt(startpos.x+dir*full_range*(extension/max_extension)) : startpos.x
  y: !isHorizontal() ? parseInt(startpos.y+dir*full_range*(extension/max_extension)) : startpos.y
  z: isHorizontal() ? 2 : 1

  // extension: { return 0
  // if (orientation === Leaflet.Horizontal) {
  //     return parseInt(255*dir*(x-start.x)*1.0/(full_range))
  // } else {
  //     return parseInt(255*dir*(y-start.y)*1.0/(full_range))
  // }
  // }

  Rectangle {
    id: compound
    width: isHorizontal() ? rect_leaf.width + rect_stem.width : rect_leaf.width
    height: isHorizontal() ? rect_leaf.height : rect_leaf.height + rect_stem.height
    x: isHorizontal() && isPositive() ? -rect_stem.width : 0
    y: !isHorizontal() && isPositive() ? -rect_stem.height : 0
    color: "transparent"

    Rectangle {
      id: rect_leaf
      width: leaflet.width
      height: leaflet.height
      border.color: Qt.darker(color, 1.4)
      property color base_color: "#e09947"
      color: base_color
      opacity: 0.85
      anchors.right: {
        if (isHorizontal() && isPositive()) {
          return compound.right
        } else { return undefined }
      }
      anchors.left: {
        if (isHorizontal() && !isPositive()) {
          return compound.left
        } else { return undefined }
      }
      anchors.top: {
        if (!isHorizontal() && !isPositive()) {
          return compound.top
        } else { return undefined }
      }
      anchors.bottom: {
        if (!isHorizontal() && isPositive()) {
          return compound.bottom
        } else { return undefined }
      }
    }
    Rectangle {
      id: rect_stem
      color: "#222222"
      border.color: Qt.darker(color, 1.8)
      property var factor: 0.2;
      width: isHorizontal() ? (rect_leaf.width) : (factor*rect_leaf.width)
      height: isHorizontal() ? (factor*rect_leaf.height) : (rect_leaf.height)

      anchors.verticalCenter: isHorizontal() ? rect_leaf.verticalCenter : undefined
      anchors.horizontalCenter: isHorizontal() ? undefined : rect_leaf.horizontalCenter
      anchors.right: {
        if (isHorizontal() && isPositive()) {
          rect_leaf.left
        } else { return undefined }
      }
      anchors.left: {
        if (isHorizontal() && !isPositive()) {
          rect_leaf.right
        } else { undefined }
      }
      anchors.top: {
        if (!isHorizontal() && !isPositive()) {
          rect_leaf.bottom
        } else { undefined }
      }
      anchors.bottom: {
        if (!isHorizontal() && isPositive()) {
          rect_leaf.top
        } else { undefined }
      }
    }
    Text {
      id: leaflet_label
      anchors.horizontalCenter: rect_leaf.horizontalCenter
      anchors.verticalCenter: rect_leaf.verticalCenter
      text: leaflet.index
      color: Qt.darker(rect_leaf.color, 1.05)
      font.pointSize: 14
    }
  }
  MouseArea {
    id: mouseArea
    anchors.fill: compound
    drag.target: parent
    drag.axis: isHorizontal() ? Drag.XAxis : Drag.YAxis

    drag.minimumX: {
      if (isHorizontal()) {
        isPositive() ? parent.startpos.x : parent.startpos.x - (parent.full_range-parent.complementary_ext)
      } else { 0 }
    }
    drag.maximumX: {
      if (isHorizontal()) {
        isPositive() ? parent.startpos.x + (full_range-complementary_ext) : parent.startpos.x
      } else { 0 }
    }
    drag.minimumY: {
      if (!isHorizontal()) {
        isPositive() ? parent.startpos.y : parent.startpos.y - (full_range-complementary_ext)
      } else { 0 }
    }
    drag.maximumY: {
      if (!isHorizontal()) {
        isPositive() ? parent.startpos.y + (full_range-complementary_ext) : parent.startpos.y
      } else { 0 }
    }
    // drag.minimumX: isPositive() ? start.x : start.x + dir*(full_range-complementary_ext)
    // drag.maximumX: isPositive() ? start.x + dir*(full_range-complementary_ext) : start.x
    // drag.minimumY: isPositive() ? start.y : start.y + dir*(full_range-complementary_ext)
    // drag.maximumY: isPositive() ? start.y + dir*(full_range-complementary_ext) : start.y

    onPressed: {
      rect_leaf.color = "#f1aa50"
      console.log("drag.minX: " + drag.minimumX);
      console.log("drag.maxX: " + drag.maximumX);
      console.log("drag.minY: " + drag.minimumY);
      console.log("drag.maxX: " + drag.maximumY);
      console.log("comp:      " + leaflet.complementary_ext);
    }
    onReleased: {
      rect_leaf.color = rect_leaf.base_color
    }
  }
}
