
// dynamically create modal dialogue window given a component URL and parent pointer
function createModalDialog(parent, url, map) {
  var component = Qt.createComponent(url);
  if (component.status != Component.Ready) {
    if (component.status == Component.Error) {
      console.debug("Error: " + component.errorString());
    }
    return;
  }
  if (!map) { map = {}; } // in case map is null
  return component.createObject(parent, map);
}
