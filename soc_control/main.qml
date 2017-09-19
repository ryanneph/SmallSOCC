import QtQuick 2.5
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

ApplicationWindow {
    visible: true
    title: mainwindow_title // global property injection
    id: mainwindow
    width: 1000
    height: 800
    // minimumHeight: height
    // maximumHeight: height
    // minimumWidth: width
    // maximumWidth: width
    color: "#EEE"

    ColumnLayout {
        /* split into two horizontal control containers */
        id: controls_container
        anchors.fill: parent
        anchors.margins: 20
        spacing: controls_container.anchors.margins
        RowLayout {
            id: upper_half
            spacing: controls_container.anchors.margins

            QLeafletAssembly2by2 {
                id: soc_display
                anchors.top: parent.top
                Layout.fillWidth: true /* dynamically size */
                Layout.preferredHeight: width /* keep square */
                Layout.minimumWidth: 200
                Layout.maximumWidth: 500
            }
            Frame {
                id: seq_list_border
                clip: true
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumWidth: 270
                property int borderwidth: 2
                padding: borderwidth
                background: Rectangle { anchors.fill: parent; border.color: "black"; border.width: parent.borderwidth; color: "#eee" }

                ListView {
                    id: listview_sequence
                    orientation: Qt.Vertical
                    verticalLayoutDirection: ListView.TopToBottom
                    spacing: 2
                    focus: true
                    currentIndex: 0
                    anchors.fill: parent
                    ScrollBar.vertical: ScrollBar {}

                    delegate: Component {
                        id: sequenceDelegate
                        Frame {
                            id: listitem
                            height: 65
                            padding: 0
                            width: seq_list_border.availableWidth-listview_sequence.spacing*2
                            anchors.horizontalCenter: parent.horizontalCenter
                            background: Rectangle { anchors.fill: parent; border.color: "#bbb"; radius: 5
                                color: parent.ListView.isCurrentItem ? "steelblue" : "transparent"
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                Label { /* print index */
                                    id: listitem_index_label
                                    Layout.preferredWidth: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: index;
                                    color: listitem.ListView.isCurrentItem ? "#d9d9d9" : "gray"
                                    font.pointSize: 16
                                }
                                Column { /* print content */
                                    id: listitem_content
                                    Layout.fillWidth: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    property color inactivecolor: "black"
                                    property color activecolor: "white"
                                    property color textcolor: listitem.ListView.isCurrentItem ? "white" : "black"
                                    Text { color: parent.textcolor; text: "<b>Couch:</b> " + couch_angle + " deg, Gantry: " + gantry_angle + " deg" }
                                    Text { color: parent.textcolor; text: "<b>desc:</b>  " + "\"Insert Description Here\"" }
                                    Text { color: parent.textcolor; text: "<b>added:</b> " + "24 Sept. 2017" }
                                    Text { color: parent.textcolor; text: "<b>type:</b>  " + "automatic" }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { listview_sequence.currentIndex = index }
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
                anchors.verticalCenter: parent.verticalCenter
                padding: 3
                background: Rectangle { anchors.fill: parent; color: "#333" }
                ColumnLayout {
                    id: list_buttons
                    property int btn_width: 65
                    property int btn_height: 50
                    property color btn_bgcolor: "#555"
                    property color btn_fgcolor: "#ededed"
                    width: btn_width
                    spacing: button_frame.padding

                    Button { /* move up */
                        text: "\u25B2"
                        Layout.preferredWidth: parent.btn_width
                        height: parent.btn_height
                        font.pointSize: 12
                    }
                    Button { /* insert before */
                        text: "\u2B11+"
                        Layout.preferredWidth: parent.btn_width
                        height: parent.btn_height
                        font.pointSize: 20
                    }
                    Button { /* insert after */
                        text: "\u2B10+"
                        Layout.preferredWidth: parent.btn_width
                        height: parent.btn_height
                        font.pointSize: 20
                    }
                    Button { /* remove */
                        text: "\u274C"
                        Layout.preferredWidth: parent.btn_width
                        height: parent.btn_height
                        font.pointSize: 12
                    }
                    Button { /* move down */
                        text: "\u25BC"
                        Layout.preferredWidth: parent.btn_width
                        height: parent.btn_height
                        font.pointSize: 12
                    }
                }
            }
        }
        Frame {
            Layout.maximumHeight: 200
            Layout.minimumHeight: 75
            Layout.fillWidth: true
            background: Rectangle {
                anchors.fill: parent
                border.color: "orange"
                border.width: 2
                color: "transparent"
            }

            RowLayout {
                anchors.fill: parent
            }
        }
    }
}
