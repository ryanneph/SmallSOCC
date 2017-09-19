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
                            width: seq_list_border.availableWidth-listview_sequence.spacing*2 /* uniform look on all sides */
                            anchors.horizontalCenter: parent.horizontalCenter
                            property color content_fgcolor: ListView.isCurrentItem ? "white" : "black" 
                            background: Rectangle { anchors.fill: parent; border.color: "#bbb"; radius: 5
                                color: listitem.ListView.isCurrentItem ? "steelblue" : "transparent"
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 10
                                Item { /* print index and time */
                                    Layout.preferredHeight: listitem.height
                                    Layout.preferredWidth: 45
                                    Layout.leftMargin: listview_sequence.spacing + parseInt(parent.spacing/2)
                                    property color index_fgcolor: listitem.ListView.isCurrentItem ? "#d9d9d9" : "gray"
                                    Label { /* print index */
                                        id: listitem_index_label
                                        height: parseInt(listitem.height*0.7)
                                        anchors.left: parent.left;
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: index;
                                        color: parent.index_fgcolor
                                        font.pointSize: 16
                                    }
                                    Label { /* print timecode */
                                        id: listitem_timecode_label
                                        width: listitem_index_label.width
                                        height: listitem.height - listitem_index_label.height
                                        anchors.left: parent.left;
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        text: timecode
                                        color: parent.index_fgcolor
                                        font.pointSize: 9
                                    }
                                }
                                Column { /* print content */
                                    id: listitem_content
                                    Layout.fillWidth: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { color: listitem.content_fgcolor; text: "<b>Couch:</b> " + couch_angle + " deg, Gantry: " + gantry_angle + " deg" }
                                    Text { color: listitem.content_fgcolor; text: "<b>desc:</b>  " + "\"" + description + "\"" }
                                    Text { color: listitem.content_fgcolor; text: "<b>added:</b> " + date_created }
                                    Text { color: listitem.content_fgcolor; text: "<b>type:</b>  " + type }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { listview_sequence.currentIndex = index }
                            }
                        }
                    }

                    model: SampleListModelData {}
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
