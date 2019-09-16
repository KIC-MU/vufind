function showItemLocations(language) {
  var items = document.getElementById('items').getElementsByTagName('tr');
  for (var i = 1; i < items.length; i++) {
    var item = items[i];
    var callNumber = item.getElementsByClassName("call_number")[0];
    var callNumberText = callNumber.textContent.replace(/^\s*/g, '').replace(/\s*$/g, '');
    var collection = item.getElementsByClassName("collection")[0];
    var collectionText = collection.textContent.replace(/^\s*/g, '').replace(/\s*$/g, '');
    var library = item.getElementsByClassName("library")[0];
    var libraryText = library.textContent.replace(/^\s*/g, '').replace(/\s*$/g, '');
    var status = item.getElementsByClassName("status");
    var statusText = status.length > 0 ? status[0].textContent : "";

    if (
      // Faculty of Arts locations.
      libraryText == VuFind.translate('location_FF') &&
      collectionText == 'volný výběr' &&
      ! statusText.match(ffSkipStatusMap[language])
    ) {
      var text;
      var callNumberSeparators = [];
      for (var callNumberSeparator in ffShelfMap) {
        callNumberSeparators.push(callNumberSeparator);
      }
      callNumberSeparators.sort(ffSort);
      for (var j = 0; j < callNumberSeparators.length; j++) {
        var callNumberSeparator = callNumberSeparators[j];
        text = ffShelfMap[callNumberSeparator];
        if (ffSort(callNumberText, callNumberSeparator) >= 1) {
          break;
        }
      }

      collection.appendChild(document.createTextNode(' ('));
      collection.appendChild(document.createTextNode(text));
      collection.appendChild(document.createTextNode(')'));
    } else if (
      // Faculty of Social Studies study room colors.
      libraryText == VuFind.translate('location_FSS') &&
        ! statusText.match(fssSkipStatusMap[language]) &&
        ! callNumber.textContent.match(/^(VHS|CD|DVD|VSKP)-/)
    ) {
      var shelf;
      if (callNumberText in fssShelfHardMap) {
        shelf = fssShelfHardMap[callNumberText][language];
      } else {
        var callNumberIdParts = callNumberText.match(/^([^\d]*)(\d*)-.*$/);
        var callNumberId = callNumberIdParts[1] + pad(callNumberIdParts[2], 'l', '0', 2);
        for (var from in fssShelfMap) {
          shelf = fssShelfMap[from];
          if (callNumberId >= from && (!('to' in shelf) || callNumberId <= shelf['to'])) {
            break;
          }
        }
      }

      var text = shelf[language];
      var symbol = 'symbol' in shelf ? shelf['symbol'] : '●';
      var color = 'rgb' in shelf ? shelf['rgb'] : 'inherit';

      var span = document.createElement('span');
      span.appendChild(document.createTextNode(symbol));
      span.appendChild(document.createTextNode(' '));
      span.appendChild(document.createTextNode(text));
      span.style.color = color;
      collection.appendChild(document.createTextNode(' '));
      collection.appendChild(span);
    }
  }
}
