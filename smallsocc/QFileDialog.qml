import QtQuick 2.5
import QtQuick.Dialogs 1.2

FileDialog {
  property string intent: "load"
  function isLoad() { return (intent=="load"); }
  title: isLoad() ? "Select a file to load" : "Select a location to save the file"
  nameFilters: ["json files (*.json)", "All files (*)"]
  selectMultiple: false
  selectExisting: isLoad() ? true : false;

  // pass dialog data to handlers
  property string path: ""
  signal onSubmitted(var thisdialog)
  onAccepted: {
    // cleanup url to get path
    var p = this.fileUrl.toString();
    path = p.replace(/^(file:\/{3})|(qrc:\/{3})|(http:\/{3})/, "");
    path = PathHandler.cleanpath(path)
    onSubmitted(this); // emit signal and return this object as argument
  }
}
