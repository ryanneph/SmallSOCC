import QtQuick 2.5
import QtQuick.Controls 1.0  // ApplicationWindow
import QtQuick.Controls.Styles 1.3  // ApplicationWindowStyle

ApplicationWindow {
    visible: true
    title: mainwindow_title // global property injection
    id: mainwindow
    width: 600; height: 600
    minimumHeight: height
    maximumHeight: height
    minimumWidth: width
    maximumWidth: width
    color: "white"

    LeafletAssembly {
        id: soc_display
        width: 600; height: 600
    }
}
