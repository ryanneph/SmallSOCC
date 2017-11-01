import QtQuick 2.5
import com.soc.types.LeafletAssemblies 1.0
import com.soc.types.Leaflets 1.0

LeafletAssembly2by2 {
  id: assembly2by2
  property color color_bg: "#aaaaaa"
  property color color_field: "#F0F6F8"
  property alias max_extension: l0.max_extension
  property bool draggable: false
  readonly property int nleaflets: 8
  clip: true

  Rectangle {
    id: border
    width: parent.width
    height: parent.height
    z: 99
    color: "transparent"
    border.color: "black"
    border.width: 2
  }
  Rectangle {
    id: background
    width: parent.width
    height: parent.height
    color: parent.color_bg
  }
  Rectangle {
    id: beambounds
    width: parent.width/2
    height: parent.height/2
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    border.width: 2
    border.color: "red"
    color: parent.color_field

    // Path {
    //     id: left_bound
    //     startX: 100
    //     startY: 100
    //     PathLine {
    //         relativeX: parent.width
    //         relativeY: parent.height
    //     }
    //     PathAttribute { name: "color"; value: "black" }
    // }
  }

  QLeaflet {
    id: l0
    index: 0
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Negative
    full_range: beambounds.width
    draggable: parent.draggable
    // complementary_ext: l5.extension

    startpos.x: (parent.width/2) + (beambounds.width/2)
    startpos.y: (parent.height/2) - (beambounds.height/2)
  }
  QLeaflet {
    id: l1
    index: 1
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Negative
    full_range: beambounds.width
    draggable: parent.draggable

    startpos.x: (parent.width/2) + (beambounds.width/2)
    startpos.y: (parent.height/2)
  }
  QLeaflet {
    id: l2
    index: 2
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Negative
    full_range: beambounds.height
    draggable: parent.draggable

    startpos.x: (parent.width/2)
    startpos.y: (parent.height/2) + (beambounds.height/2)
  }
  QLeaflet {
    id: l3
    index: 3
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Negative
    full_range: beambounds.height
    draggable: parent.draggable

    startpos.x: (parent.width/2) - (beambounds.width/2)
    startpos.y: (parent.height/2) + (beambounds.height/2)
  }
  QLeaflet {
    id: l4
    index: 4
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Positive
    full_range: beambounds.width
    draggable: parent.draggable

    startpos.x: (parent.width/2) - (3*beambounds.width/2)
    startpos.y: (parent.height/2)
  }
  QLeaflet {
    id: l5
    index: 5
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Positive
    full_range: beambounds.width
    draggable: parent.draggable
    complementary_ext: l0.extension

    startpos.x: (parent.width/2) - (3*beambounds.width/2)
    startpos.y: (parent.height/2) - (beambounds.height/2)
  }
  QLeaflet {
    id: l6
    index: 6
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Positive
    full_range: beambounds.height
    draggable: parent.draggable

    startpos.x: (parent.width/2) - (beambounds.width/2)
    startpos.y: (parent.height/2) - (3*beambounds.height/2)
  }
  QLeaflet {
    id: l7
    index: 7
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Positive
    full_range: beambounds.height
    draggable: parent.draggable

    startpos.x: (parent.width/2)
    startpos.y: (parent.height/2) - (3*beambounds.height/2)
  }
}
