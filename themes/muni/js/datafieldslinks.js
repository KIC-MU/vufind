(function() {
  var collectionRename = {
    'FF - ustredni knihovna': 'location_FF',
    'Fac. Arts - central library': 'location_FF',
    'FF - katedry a ustavy': 'location_FF-K',
    'Fac. Arts - departments': 'location_FF-K',
    'FF - studovna': 'location_FF-S',
    'Fac. Arts - Study room': 'location_FF-S',
    'FF - hudebni veda': 'location_FFHUD',
    'Fac. Arts - Music': 'location_FFHUD',
    'Fakulta sociálních studií': 'location_FSS',
    'Faculty of Social Studies': 'location_FSS',
    'Knihovna univ. kampusu': 'location_KUK',
    'Campus Library': 'location_KUK',
    'Lékařská fakulta': 'location_LF',
    'Faculty of Medicine': 'location_LF',
    'Přírodovědecká fakulta': 'location_PRIF',
    'Faculty of Science': 'location_PRIF',
    'Přír. fakulta - Matematika': 'location_PRIMA',
    'Faculty of Sci. - Mathematics': 'location_PRIMA',
  };
  var defaultSymbol = '●';

  function strip(str) {
    return str.replace(/^\s*/g, '').replace(/\s*$/g, '');
  }

  function showItemLocations(language) {
    var items = document.getElementById('items').getElementsByTagName('tr');
    for (var i = 1; i < items.length; i++) {
      var item = items[i];
      var barcode = item.getElementsByClassName('barcode')[0];
      var barcodeText = strip(barcode.textContent);
      var callNumber = item.getElementsByClassName('call_number')[0];
      var callNumberText = strip(callNumber.textContent);
      var collection = item.getElementsByClassName('collection')[0];
      var collectionText = strip(collection.textContent);
      var library = item.getElementsByClassName('library')[0];
      var libraryText = strip(library.textContent);
      var status = item.getElementsByClassName('status');
      var statusText = status.length > 0 ? strip(status[0].textContent) : '';

      var text;
      if (
        // Faculty of Arts locations.
        libraryText == VuFind.translate('location_FF')
        && collectionText == 'volný výběr'
        && ! statusText.match(ffSkipStatusMap[language])
      ) {
        var callNumberSeparators = [];
        for (var callNumberSeparator in ffShelfMap) {
          callNumberSeparators.push(callNumberSeparator);
        }
        callNumberSeparators.sort(ffSort);
        for (var j = 0; j < callNumberSeparators.length; j++) {
          callNumberSeparator = callNumberSeparators[j];
          if (ffSort(callNumberText, callNumberSeparator) < 1) {
            break;
          }
          text = ffShelfMap[callNumberSeparator];
        }

        collection.appendChild(document.createTextNode(' ('));
        collection.appendChild(document.createTextNode(text));
        collection.appendChild(document.createTextNode(')'));
      } else if (
        // Faculty of Social Studies study room colors.
        libraryText == VuFind.translate('location_FSS')
        && ! statusText.match(fssSkipStatusMap[language])
        && ! callNumber.textContent.match(/^(VHS|CD|DVD|VSKP)-/)
      ) {
        var shelf;
        if (callNumberText in fssShelfHardMap) {
          shelf = fssShelfHardMap[callNumberText][language];
        } else {
          var callNumberIdParts = callNumberText.match(/^([^\d]*)(\d*)-.*$/);
          var callNumberId = callNumberIdParts[1] + pad(callNumberIdParts[2], 'l', '0', 2);
          for (var from in fssShelfMap) {
            shelf = fssShelfMap[from];
            if (callNumberId >= from && (!('to' in shelf) || callNumberId <= shelf.to)) {
              text = shelf[language];
              var symbol = 'symbol' in shelf ? shelf.symbol : defaultSymbol;
              var color = 'rgb' in shelf ? shelf.rgb : 'inherit';

              var span = document.createElement('span');
              span.appendChild(document.createTextNode(symbol));
              span.appendChild(document.createTextNode(' '));
              span.style.color = color;
              collection.appendChild(document.createTextNode(' '));
              collection.appendChild(span);
              if (shelf.en == 'Yellow Study Room') {
                // Make the study room text black for the yellow study room.
                collection.appendChild(document.createTextNode(text));
              } else {
                // Otherwise, make the text the color of the study room.
                span.appendChild(document.createTextNode(text));
              }
              break;
            }
          }
        }
      } else if (
        // Campus Library call number colors.
        libraryText == VuFind.translate('location_KUK')
        && collectionText in kukCollectionMap[language]
      ) {
        var callNumberId = callNumberText.substring(0, 2);
        var color, title;
        if (kukCollectionMap[language][collectionText] === null) {
            color = kukShelfHardMap[callNumberId].rgb;
            title = kukShelfHardMap[callNumberId][language];
        } else if (callNumberId in kukShelfHardMap) {
            color = kukCollectionMap[language][collectionText].rgb;
            title = kukCollectionMap[language][collectionText].title;
        }
        if (color && title) {
            var span = document.createElement('span');
            span.appendChild(document.createTextNode(defaultSymbol));
            span.appendChild(document.createTextNode(' '));
            span.style.color = color;
            span.title = title;
            while (callNumber.childNodes.length > 0) {
              callNumber.removeChild(callNumber.childNodes[0]);
            }
            callNumber.appendChild(span);
            if (
              color == 'rgb(255, 255, 0)'
              || color == 'rgb(0, 203, 255)'
              || color == 'rgb(247, 171, 240)'
              || color == 'rgb(140, 237, 203)'
            ) {
              callNumber.appendChild(document.createTextNode(callNumberText));
            } else {
              span.appendChild(document.createTextNode(callNumberText));
            }
        }
      }
    }
  }

  function showItemLinks(language, vuFindId) {
    for (var oldName in collectionRename) {
      // Renaming misnamed collections from Aleph.
      var newName = VuFind.translate(collectionRename[oldName]);
      if (oldName in collections) {
        collections[newName] = collections[oldName];
      }
    }

    var items = document.getElementById('items').getElementsByTagName('tr');
    for (var i = 1; i < items.length; i++) {
      var item = items[i];
      var barcode = item.getElementsByClassName('barcode')[0];
      var barcodeText = strip(barcode.textContent);
      var collection = item.getElementsByClassName('collection')[0];
      var collectionText = strip(collection.textContent);
      var library = item.getElementsByClassName('library')[0];
      var libraryText = strip(library.textContent);
      var status = item.getElementsByClassName('status');
      var statusText = status.length > 0 ? strip(status[0].textContent) : '';
      var sysno = vuFindId.replace(/.*MUB[0-9]{2}/, '');

      if(
        libraryText in collections
        && statusText == VuFind.translate('muni::Long term loan')
        && collections[libraryText]['__longtermloan__']
        && collections[libraryText][userIsLoggedIn ? '__bor__' : '__nobor__']
      ) {
        // Long term loan links
        var d = collections[libraryText][collectionText];
        var label = collections[libraryText]['__linklabel__'];
        var url = collections[libraryText]['__url__'];
        var icon = document.createElement('i');
        icon.className = 'fa fa-flag';
        icon.setAttribute('aria-hidden', 'true');
        var a = document.createElement('a');
        a.target = '_blank';
        a.href = url + '?d=' + d + '&sysno=' + sysno + '&bc=' + barcodeText + '&reqtype=longtermloan&lang=' + language;
        a.appendChild(icon);
        a.appendChild(document.createTextNode(' ' + label));
        var td = status[0].parentElement.parentElement;
        td.appendChild(a);
      }

      if(
        libraryText in collections
        && collections[libraryText]['__collection__']
      ) {
        // Collection links
        var d = collections[libraryText][collectionText];
        var label = collections[libraryText]['__linklabel__'];
        var url = collections[libraryText]['__url__'];
        var a = document.createElement('a');
        a.target = '_blank';
        a.href = url + '?d=' + d + '&sysno=' + sysno + '&bc=' + barcodeText + '&reqtype=collection&lang=' + language;
        a.appendChild(document.createTextNode(collectionText));
        while (collection.childNodes.length > 0) {
          collection.removeChild(collection.childNodes[0]);
        }
        collection.appendChild(a);
      }
    }
  }

  window.showItemLocations = showItemLocations;
  window.showItemLinks = showItemLinks;
})();
