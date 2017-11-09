import QtQuick 2.5
import QtQuick.Controls 2.0
import com.soc.types.LeafletAssemblies 1.0
import com.soc.types.Leaflets 1.0

LeafletAssembly {
  id: root
  property color color_bg: "#aaaaaa"
  property color color_field: "#F0F6F8"
  property bool draggable: false
  property bool preventCollisions: false
  readonly property int nleaflets: leaflets.length
  property alias max_extension: l0.max_extension
  clip: true

  // connect signals on construction
  signal onLeafletSelected(int index)
  Component.onCompleted: {
    // register leaflet onSelected signals with arg carrying onLeafletSelected sigal
    for (var i=0; i<leaflets.length; ++i) {
      leaflets[i].onPressed.connect( function() {
        // function closure - otherwise i== .length always
        var ii = i;
        return function() { root.onLeafletSelected(ii); };
      }());
    }
  }

  // helper for setting extension on one or many child leaflets
  // we can also access the leaflet members explictly and use:
  //   root.leaflets[index].extension = val
  // which will emit the onExtensionChanged signal and the display and HW
  // positions will be updated automatically
  function setExtension(index, ext) {
    if (index !== null && typeof index === 'object') {
      // index is map of (index: ext) pairs
      for (var key in index) {
        leaflets[key].extension = index[key];
      }
    } else {
      // we are only setting one extension
      leaflets[index].extension = ext;
    }
  }
  function getExtension(index) {
    if (index == null) {
      // get array of extensions
      var extension_list = []
      for (var i=0; i<leaflets.length; ++i) {
        extension_list.push(leaflets[i].extension);
      }
      return extension_list;
    } else {
      // return only requested extension
      return leaflets[index].extension;
    }
  }

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
    color: color_bg
  }
  Rectangle {
    id: beambounds
    width: parent.width/2
    height: parent.height/2
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    border.width: 2
    border.color: "red"
    color: color_field
  }


  // public iterable
  leaflets: [l0, l1, l2, l3, l4, l5, l6, l7]

  QLeaflet {
    id: l0
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Negative
    full_range: beambounds.width
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l5.extension

    startpos.x: (root.width/2) + (beambounds.width/2)
    startpos.y: (root.height/2) - (beambounds.height/2)
  }
  QLeaflet {
    id: l1
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Negative
    full_range: beambounds.width
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l4.extension

    startpos.x: (root.width/2) + (beambounds.width/2)
    startpos.y: (root.height/2)
  }
  QLeaflet {
    id: l2
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Negative
    full_range: beambounds.height
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l7.extension

    startpos.x: (root.width/2)
    startpos.y: (root.height/2) + (beambounds.height/2)
  }
  QLeaflet {
    id: l3
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Negative
    full_range: beambounds.height
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l6.extension

    startpos.x: (root.width/2) - (beambounds.width/2)
    startpos.y: (root.height/2) + (beambounds.height/2)
  }
  QLeaflet {
    id: l4
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Positive
    full_range: beambounds.width
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l1.extension

    startpos.x: (root.width/2) - (3*beambounds.width/2)
    startpos.y: (root.height/2)
  }
  QLeaflet {
    id: l5
    width: beambounds.width
    height: beambounds.height/2
    orientation: Leaflet.Horizontal
    direction: Leaflet.Positive
    full_range: beambounds.width
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l0.extension

    startpos.x: (root.width/2) - (3*beambounds.width/2)
    startpos.y: (root.height/2) - (beambounds.height/2)
  }
  QLeaflet {
    id: l6
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Positive
    full_range: beambounds.height
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l3.extension

    startpos.x: (root.width/2) - (beambounds.width/2)
    startpos.y: (root.height/2) - (3*beambounds.height/2)
  }
  QLeaflet {
    id: l7
    width: beambounds.width/2
    height: beambounds.height
    orientation: Leaflet.Vertical
    direction: Leaflet.Positive
    full_range: beambounds.height
    draggable: root.draggable
    preventCollisions: root.preventCollisions
    compext: l2.extension

    startpos.x: (root.width/2)
    startpos.y: (root.height/2) - (3*beambounds.height/2)
  }
}
