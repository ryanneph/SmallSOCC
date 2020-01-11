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
  property int   full_range // full range of motion in pixels
  property int   compext // complementary leaflet's current extension
  property bool  draggable: false
  property bool  preventCollisions: false
  // property bool  limitTravel: true #defined in leaflet.py
  // mapping of max_safe_extension to pixels from startpos
  property int   collidepos: {
    if (preventCollisions) { compext/max_extension*full_range; }
    else { 0; }
  }
  // max extension given that compext is set and collisions are avoided
  property int max_safe_extension: {
    if (preventCollisions) { max_extension - compext; }
    else {
      limitTravel ? max_extension : 9999; }
  }
  property int min_safe_extension: {
    limitTravel ? 0 : -9999
  }
  x: startpos.x
  y: startpos.y
  z: isHorizontal() ? 2 : 1

  // connect signals on construction
  signal onPressed()
  signal onReleased()
  Component.onCompleted: {
    // connect mouseArea signals to accessible component signals
    mousearea.onPressed.connect(root.onPressed);
    mousearea.onReleased.connect(root.onReleased);
  }

  // Visual Properties
  property int direction: Leaflet.Positive
  property int orientation: Leaflet.Horizontal
  property color color_leaf: "#e09947"
  property color color_stem: "#222222"
  property real  opacity_leaf: 0.85

  // reset x,y to start value
  function reset() { extension = 0; }

  // refresh x,y from the current extension value
  function refreshXY() {
    // TODO: handle collisions here too
    x = xfromext();
    y = yfromext();
  }
  // update x/y from a change in extension
  property bool enableextsignal: true;
  onExtensionChanged: function() {
    if (enableextsignal) {
      refreshXY();
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
    opacity: root.opacity_leaf

    Rectangle {
      id: rect_leaf
      width: root.width
      height: root.height
      border.color: Qt.darker(color, 1.25)
      color: color_leaf
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
      color: root.color_stem
      border.color: Qt.darker(color, 1.4)
      property var heightfactor: 0.2;
      property var lengthfactor: 20;
      width: isHorizontal() ? (lengthfactor*rect_leaf.width) : (heightfactor*rect_leaf.width)
      height: isHorizontal() ? (heightfactor*rect_leaf.height) : (lengthfactor*rect_leaf.height)

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
      color: Qt.darker(rect_leaf.color, 1.1)
      font.pointSize: 12
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
        if (limitTravel) {
          isPositive() ? parent.startpos.x : parent.startpos.x - (parent.full_range-root.collidepos)
        } else { -9999 }
      } else { 0 }
    }
    drag.maximumX: {
      if (isHorizontal()) {
        if (limitTravel) {
          isPositive() ? parent.startpos.x + (root.full_range-root.collidepos) : parent.startpos.x
        } else { 9999 }
      } else { 0 }
    }
    drag.minimumY: {
      if (isVertical()) {
        if (limitTravel) {
          isPositive() ? parent.startpos.y : parent.startpos.y - (full_range-root.collidepos)
        } else { -9999 }
      } else { 0 }
    }
    drag.maximumY: {
      if (isVertical()) {
        if (limitTravel) {
          isPositive() ? parent.startpos.y + (full_range-root.collidepos) : parent.startpos.y
        } else { 9999 }
      } else { 0 }
    }

    onPressed: {
      rect_leaf.color = Qt.darker(root.color_leaf, 1.1)
    }
    onReleased: {
      rect_leaf.color = root.color_leaf
      // keep from firing a loop of x/y change -> extChange -> repeat...
      enableextsignal = false;
      extension = extfromxy();
      enableextsignal = true;
    }
  }
}
