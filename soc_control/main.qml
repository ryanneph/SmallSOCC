import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ApplicationWindow {
    visible: true
    title: mainwindow_title // global property injection
    id: mainwindow
    width: 1400; height: parseInt(width*3/4)
    // minimumHeight: height
    // maximumHeight: height
    // minimumWidth: width
    // maximumWidth: width
    color: "#EEE"

    GridLayout {
        /* wrapper for all controls with margins */
        id: controls_container
        columns: 1; rows: 1 
        anchors.fill: parent
        anchors.margins: 20

        ColumnLayout {
            /* split into two horizontal control containers */
            spacing: controls_container.anchors.margins
            Row {
                id: upper_half
                spacing: controls_container.anchors.margins
                height: 600

                QLeafletAssembly2by2 {
                    id: soc_display
                    property int iso_size: parent.height
                    height: iso_size; width: iso_size; 
                    anchors.top: parent.top
                    Layout.minimumWidth: iso_size
                    Layout.minimumHeight: iso_size
                }
                Frame {
                    id: seq_list_border
                    clip: true
                    width: 400
                    height: parent.height
                    property int borderwidth: 2
                    padding: borderwidth
                    background: Rectangle { anchors.fill: parent; border.color: "black"; border.width: parent.borderwidth; color: "#eee" }

                    ListView {
                        id: seq_list_view
                        orientation: Qt.Vertical
                        verticalLayoutDirection: ListView.TopToBottom
                        spacing: 2
                        focus: true
                        currentIndex: 0
                        anchors.fill: parent

                        highlight: Rectangle { color: "steelblue"; border.color: "white"; radius: 5 }

                        delegate: Component {
                            id: sequenceDelegate
                            Frame {
                                height: 70
                                width: seq_list_border.availableWidth-seq_list_view.spacing*2
                                anchors.horizontalCenter: parent.horizontalCenter
                                background: Rectangle {anchors.fill: parent; border.color: "transparent"; color: "transparent" }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: "Couch: " + couch_angle + " deg, Gantry: " + gantry_angle + " deg" }
                                    Text { text: "desc:  " + "\"Insert Description Here\"" }
                                    Text { text: "added: " + "24 Sept. 2017" }
                                    Text { text: "type:  " + "automatic" }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: seq_list_view.currentIndex = index
                                }
                            }
                        }

                        model: ListModel {
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 0; gantry_angle: 45; }
                            ListElement { couch_angle: 1; gantry_angle: 45; }
                            ListElement { couch_angle: 2; gantry_angle: 45; }
                            ListElement { couch_angle: 3; gantry_angle: 45; }
                            ListElement { couch_angle: 4; gantry_angle: 45; }
                        }
                    }
                }
                Frame {
                    id: button_frame
                    height: list_buttons.height + 2*padding
                    padding: 3
                    background: Rectangle { anchors.fill: parent; color: "#333" }
                    ColumnLayout {
                        id: list_buttons
                        property int btn_width: 90
                        property int btn_height: 50
                        property color btn_bgcolor: "#555"
                        property color btn_fgcolor: "#ededed"
                        width: btn_width
                        spacing: button_frame.padding
                        
                        Button {
                            text: "move up"
                            width: parent.btn_width
                            height: parent.btn_height
                        }
                        Button {
                            text: "insert before"
                            width: parent.btn_width
                            height: parent.btn_height
                        }
                        Button {
                            text: "insert after"
                            width: parent.btn_width
                            height: parent.btn_height
                        }
                        Button {
                            text: "remove"
                            width: parent.btn_width
                            height: parent.btn_height
                        }
                        Button {
                            text: "move down"
                            width: parent.btn_width
                            height: parent.btn_height
                        }
                    }
                }
            }
            RowLayout {
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    anchors.fill: parent
                    border.color: "orange"
                    border.width: 2
                    color: "transparent"
                }
            }
        }
    }
}
