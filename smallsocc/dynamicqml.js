
// dynamically create visual object (Qt Item) given a component URL and parent pointer
function createDynamicObject(parent, url, map) {
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
