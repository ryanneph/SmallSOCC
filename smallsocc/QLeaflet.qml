// Leaflet.qml
import QtQuick 2.5
import com.soc.types.Leaflets 1.0

Leaflet {
  id: root
  function isHorizontal() { return orientation === Leaflet.Horizontal }
  function isVertical()   { return !isHorizontal(); }
  function isPositive()   { return direction === Leaflet.Positive }
  function isNegative()   { return !isPositive(); }
  property var dir: isPositive() ? 1 : -1
  property point startpos
  property int   full_range
  property int   compext
  property bool  draggable: false
  property bool  preventCollisions: true
  property int   collide: {
    if (preventCollisions) { compext; }
    else { 0; }
  }

  x: startpos.x
  y: startpos.y
  z: isHorizontal() ? 2 : 1

  // connect signals on construction
  signal onPressed()
  signal onReleased()
  Component.onCompleted: {
    mousearea.onPressed.connect(root.onPressed);
    mousearea.onReleased.connect(root.onReleased);
  }

  // Visual Properties
  property int direction: Leaflet.Positive
  property int orientation: Leaflet.Horizontal

  // update x/y from a change in extension
  property bool enableextsignal: true;
  onExtensionChanged: function() {
    if (enableextsignal) {
      // set x,y appropriately
      // TODO: handle collisions here too
      x = xfromext();
      y = yfromext();
      // console.debug('extension change prompted update to x,y: x='+x+'  y='+y);
    }
  }

  // calculate x, y from extension, orientation, and direction
  function xfromext() {
    if (isHorizontal()) {
      return parseInt(startpos.x+dir*full_range*(extension/max_extension));
    } else { return startpos.x; }
  }
  function yfromext() {
    if (!isHorizontal()) {
      return parseInt(startpos.y+dir*full_range*(extension/max_extension))
    } else { return startpos.y; }
  }
  function extfromxy() {
    if (orientation === Leaflet.Horizontal) {
      return parseInt(max_extension*dir*(x-startpos.x)*1.0/(full_range))
    } else {
      return parseInt(max_extension*dir*(y-startpos.y)*1.0/(full_range))
    }
  }

  Rectangle {
    id: compound
    width: isHorizontal() ? rect_leaf.width + rect_stem.width : rect_leaf.width
    height: isHorizontal() ? rect_leaf.height : rect_leaf.height + rect_stem.height
    x: isHorizontal() && isPositive() ? -rect_stem.width : 0
    y: isVertical() && isPositive() ? -rect_stem.height : 0
    color: "transparent"

    Rectangle {
      id: rect_leaf
      width: root.width
      height: root.height
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
        if (isHorizontal() && isNegative()) {
          return compound.left
        } else { return undefined }
      }
      anchors.top: {
        if (isVertical() && isNegative()) {
          return compound.top
        } else { return undefined }
      }
      anchors.bottom: {
        if (isVertical() && isPositive()) {
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
        if (isHorizontal() && isNegative()) {
          rect_leaf.right
        } else { undefined }
      }
      anchors.top: {
        if (isVertical() && isNegative()) {
          rect_leaf.bottom
        } else { undefined }
      }
      anchors.bottom: {
        if (isVertical() && isPositive()) {
          rect_leaf.top
        } else { undefined }
      }
    }
    Text {
      anchors.horizontalCenter: rect_leaf.horizontalCenter
      anchors.verticalCenter: rect_leaf.verticalCenter
      text: index
      color: Qt.darker(rect_leaf.color, 1.05)
      font.pointSize: 14
    }
  }
  MouseArea {
    id: mousearea
    anchors.fill: compound
    enabled: root.draggable
    drag.target: root
    drag.axis: isHorizontal() ? Drag.XAxis : Drag.YAxis

    drag.minimumX: {
      if (isHorizontal()) {
        isPositive() ? parent.startpos.x : parent.startpos.x - (parent.full_range-root.collide)
      } else { 0 }
    }
    drag.maximumX: {
      if (isHorizontal()) {
        isPositive() ? parent.startpos.x + (root.full_range-root.collide) : parent.startpos.x
      } else { 0 }
    }
    drag.minimumY: {
      if (isVertical()) {
        isPositive() ? parent.startpos.y : parent.startpos.y - (full_range-root.collide)
      } else { 0 }
    }
    drag.maximumY: {
      if (isVertical()) {
        isPositive() ? parent.startpos.y + (full_range-root.collide) : parent.startpos.y
      } else { 0 }
    }

    onPressed: {
      rect_leaf.color = "#f1aa50"
      // console.log("index:     " + index);
      // console.log("drag.minX: " + drag.minimumX);
      // console.log("drag.maxX: " + drag.maximumX);
      // console.log("drag.minY: " + drag.minimumY);
      // console.log("drag.maxX: " + drag.maximumY);
      // console.log("comp:      " + root.collide);
    }
    onReleased: {
      rect_leaf.color = rect_leaf.base_color
      // keep from firing a loop of x/y change -> extChange -> repeat...
      enableextsignal = false;
      extension = extfromxy();
      enableextsignal = true;
    }
  }
}
