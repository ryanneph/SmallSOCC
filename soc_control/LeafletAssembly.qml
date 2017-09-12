import QtQuick 2.5
import com.soc.types.LeafletAssemblyBase 1.0
import com.soc.types.LeafletBase 1.0

LeafletAssembly2by2 {
    id: assembly2by2
    width: 600; height: 600;
    property color color_bg: "#aaaaaa"
    property color color_field: "#F0F6F8"
    
    Rectangle {
        id: background
        width: parent.width;
        height: parent.height;
        color: parent.color_bg;
    }
    Rectangle {
        id: beambounds
        width: parent.width/2
        height: parent.height/2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        border.width: 4
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

    Leaflet {
        id: l0
        leaflet_index: 0
        width: beambounds.width
        height: beambounds.height/2
        orientation: LeafletBase.Horizontal
        direction: LeafletBase.Negative
        full_range: beambounds.width
        complementary_ext: l5.extension

        x: (parent.width/2) + (beambounds.width/2)
        y: (parent.height/2) - (beambounds.height/2)
    }
    Leaflet {
        id: l1
        leaflet_index: 1
        width: beambounds.width
        height: beambounds.height/2
        orientation: LeafletBase.Horizontal
        direction: LeafletBase.Negative
        full_range: beambounds.width

        x: (parent.width/2) + (beambounds.width/2)
        y: (parent.height/2)
    }
    Leaflet {
        id: l2
        leaflet_index: 2
        width: beambounds.width/2
        height: beambounds.height
        orientation: LeafletBase.Vertical
        direction: LeafletBase.Negative
        full_range: beambounds.height

        x: (parent.width/2)
        y: (parent.height/2) + (beambounds.height/2)
    }
    Leaflet {
        id: l3
        leaflet_index: 3
        width: beambounds.width/2
        height: beambounds.height
        orientation: LeafletBase.Vertical
        direction: LeafletBase.Negative
        full_range: beambounds.height

        x: (parent.width/2) - (beambounds.width/2)
        y: (parent.height/2) + (beambounds.height/2)
    }
    Leaflet {
        id: l4
        leaflet_index: 4
        width: beambounds.width
        height: beambounds.height/2
        orientation: LeafletBase.Horizontal
        full_range: beambounds.width

        x: (parent.width/2)-(3*beambounds.width/2)
        y: (parent.height/2)
    }
    Leaflet {
        id: l5
        leaflet_index: 5
        width: beambounds.width
        height: beambounds.height/2
        orientation: LeafletBase.Horizontal
        full_range: beambounds.width
        complementary_ext: l0.extension

        x: (parent.width/2)-(3*beambounds.width/2)
        y: (parent.height/2) - (beambounds.height/2)
    }
    Leaflet {
        id: l6
        leaflet_index: 6
        width: beambounds.width/2
        height: beambounds.height
        orientation: LeafletBase.Vertical
        full_range: beambounds.height

        x: (parent.width/2) - (beambounds.width/2)
        y: (parent.height/2) - (3*beambounds.height/2)
    }
    Leaflet {
        id: l7
        leaflet_index: 7
        width: beambounds.width/2
        height: beambounds.height
        orientation: LeafletBase.Vertical
        full_range: beambounds.height

        x: (parent.width/2)
        y: (parent.height/2) - (3*beambounds.height/2)
    }
}
