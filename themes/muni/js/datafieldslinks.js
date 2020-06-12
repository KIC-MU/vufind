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

  var items;

  function getItems() {
    if (items == undefined) {
      items = [];
      var tables = document.getElementsByClassName('items');
      for (var i = 0; i < tables.length; i++) {
        var table = tables[i];
        var rows = table.getElementsByTagName('tr');
        for (var j = 1; j < rows.length; j++) {
          var item = rows[j];
          items.push(item);
        }
      }
    }
    return items;
  }

  function showItemFilters(vuFindId) {
    var itemFilterHolder = document.getElementById('item-filters');
    var itemFilters = [];

    function stringSorter(a, b) {
      if (a < b) {
        return -1;
      } else if(a > b) {
        return 1;
      } else {
        return 0;
      }
    }

    function numberSorter(a, b) {
      if (isNaN(parseFloat(a)) || isNaN(parseFloat(a))) {
        return stringSorter(a, b);
      } else {
        a = parseFloat(a);
        b = parseFloat(b);
        if (a < b) {
          return -1;
        } else if(a > b) {
          return 1;
        } else {
          return 0;
        }
      }
    }

    function refilterItems() {
      var itemFilterValues = {};
      var numFilters = 0;
      for (var i = 0; i < itemFilters.length; i++) {
        var itemFilter = itemFilters[i].childNodes[1];
        if (itemFilter.value != '') {
          itemFilterValues[itemFilter.getAttribute('name')] = itemFilter.value;
          numFilters++;
        }
      }

      var filteredItemTable = document.getElementById('filtered-item-table');
      var locationHeadings = document.getElementsByClassName('items-location');
      if (numFilters == 0) {
        filteredItemTable.className = 'table hidden';
        for (var i = 0; i < locationHeadings; i++) {
          var locationHeading = locationHeadings[i];
          locationHeading.className = 'items-location';
        }
      } else {
        filteredItemTable.className = 'table';
        for (var i = 0; i < locationHeadings; i++) {
          var locationHeading = locationHeadings[i];
          locationHeading.className = 'items-location hidden';
        }
        var filteredItems = filteredItemTable.getElementsByTagName('tr');
        for (var i = 1; i < filteredItems.length; i++) {
          var filteredItem = filteredItems[i];
          filteredItemTable.removeChild(filteredItem);
        }

        var items = getItems();
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          var numPassedFilters = 0;
          for (var type in itemFilterValues) {
            var itemFilterValue = itemFilterValues[type];
            if (itemFilterValue == '') {
              numPassedFilters++;
            } else {
              var itemValue = item.getAttribute('data-' + type);
              if (itemFilterValue != itemValue) {
                break;
              } else {
                numPassedFilters++;
              }
            }
          }
          if (numPassedFilters == numFilters) {
            filteredItemTable.appendChild(item.cloneNode(true));
          }
        }
      }
    }

    function addItemFilter(type, sorter) {
      var itemFilter = document.createElement('form');
      itemFilter.className = 'col-md-4';
      var itemFilterLabel = document.createElement('label');
      itemFilterLabel.setAttribute('for', type);
      itemFilterLabel.appendChild(document.createTextNode(VuFind.translate('muni::Filter by ' + type) + ': '));
      var itemFilterSelect = document.createElement('select');
      itemFilterSelect.setAttribute('name', type);
      itemFilterSelect.onchange = refilterItems;

      function addOption(text, value, selected) {
        var itemFilterOption = document.createElement('option')
        itemFilterOption.setAttribute('value', value);
        if (selected) {
          itemFilterOption.setAttribute('selected', 'selected');
        }
        itemFilterOption.appendChild(document.createTextNode(text));
        itemFilterSelect.appendChild(itemFilterOption);
      }

      var items = getItems();
      values = [];
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (item.hasAttribute('data-' + type)) {
          var value = item.getAttribute('data-' + type);
          if (values.indexOf(value) == -1) {
            values.push(value);
          }
        }
      }
      values.sort(sorter);

      if (values.length > 1) {
        addOption(VuFind.translate('muni::No filters'), '', true);
        for (var i = 0; i < values.length; i++) {
          var value = values[i];
          addOption(value, value, false);
        }

        itemFilter.appendChild(itemFilterLabel);
        itemFilter.appendChild(itemFilterSelect);
        itemFilters.push(itemFilter);
        itemFilterHolder.appendChild(itemFilter);
        itemFilterHolder.className = '';
      }
    }

    addItemFilter('location', stringSorter);
    addItemFilter('year', numberSorter);
    addItemFilter('volume', numberSorter);
  }

  function showItemLocations(language) {
    var items = getItems();
    for (var i = 0; i < items.length; i++) {
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
        } else if(callNumberText != '') {
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

    var items = getItems();
    for (var i = 0; i < items.length; i++) {
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
  window.showItemFilters = showItemFilters;
})();
