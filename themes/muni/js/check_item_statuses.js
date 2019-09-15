/*global Hunt, VuFind */
/*exported checkItemStatuses, itemStatusFail */

function linkCallnumbers(callnumber, callnumber_handler) {
  if (callnumber_handler) {
    var cns = callnumber.split(',\t');
    for (var i = 0; i < cns.length; i++) {
      cns[i] = '<a href="' + VuFind.path + '/Alphabrowse/Home?source=' + encodeURI(callnumber_handler) + '&amp;from=' + encodeURI(cns[i]) + '">' + cns[i] + '</a>';
    }
    return cns.join(',\t');
  }
  return callnumber;
}
function displayItemStatus(result, $item) {
  $item.removeClass('js-item-pending');
  $item.find('.status').empty().append(result.availability_message);
  $item.find('.ajax-availability').removeClass('ajax-availability hidden');
  if (typeof(result.error) != 'undefined'
    && result.error.length > 0
  ) {
    // Only show error message if we also have a status indicator active:
    if ($item.find('.status').length > 0) {
      $item.find('.callnumAndLocation').empty().addClass('text-danger').append(result.error);
    } else {
      $item.find('.callnumAndLocation').addClass('hidden');
    }
    $item.find('.callnumber,.hideIfDetailed,.location').addClass('hidden');
  } else if (typeof(result.full_status) != 'undefined'
    && result.full_status.length > 0
    && $item.find('.callnumAndLocation').length > 0
  ) {
    // Full status mode is on -- display the HTML and hide extraneous junk:
    $item.find('.callnumAndLocation').empty().append(result.full_status);
    $item.find('.callnumber,.hideIfDetailed,.location,.status').addClass('hidden');
  } else if (typeof(result.missing_data) != 'undefined'
    && result.missing_data
  ) {
    // No data is available -- hide the entire status area:
    $item.find('.callnumAndLocation,.status').addClass('hidden');
  } else if (result.locationList) {
    // We have multiple locations -- build appropriate HTML and hide unwanted labels:
    $item.find('.callnumber,.hideIfDetailed,.location').addClass('hidden');
    var locationListHTML = "";
    var skippedLocations = false;
    var uriSearch = decodeURIComponent(location.search);
    for (var x = 0; x < result.locationList.length; x++) {
      var locationId = result.locationList[x].location_id;
      var uriSearchRegex = new RegExp('filter\\[\\]=building:\\"?' + locationId + '\\"?');
      if (uriSearch.indexOf('filter[]=building:') != -1 && uriSearch.search(uriSearchRegex) == -1) {
          skippedLocations = true;
          continue;
      }
      locationListHTML += '<div class="groupLocation">';
      if (result.locationList[x].availability) {
        locationListHTML += '<span class="text-success"><i class="fa fa-check" aria-hidden="true"></i> '
          + result.locationList[x].location + '</span> ';
      } else if (typeof(result.locationList[x].status_unknown) !== 'undefined'
          && result.locationList[x].status_unknown
      ) {
        if (result.locationList[x].location) {
          locationListHTML += '<span class="text-warning"><i class="fa fa-status-unknown" aria-hidden="true"></i> '
            + result.locationList[x].location + '</span> ';
        }
      } else {
        locationListHTML += '<span class="text-danger"><i class="fa fa-remove" aria-hidden="true"></i> '
          + result.locationList[x].location + '</span> ';
      }
      locationListHTML += '</div>';
      locationListHTML += '<div class="groupCallnumber">';
      locationListHTML += (result.locationList[x].callnumbers)
        ? linkCallnumbers(result.locationList[x].callnumbers, result.locationList[x].callnumber_handler) : '';
      locationListHTML += '</div>';
    }
    if (skippedLocations) {
        locationListHTML += '<div><strong>…</strong></div>';
    }
    $item.find('.locationDetails').removeClass('hidden');
    $item.find('.locationDetails').html(locationListHTML);
  } else {
    // Default case -- load call number and location into appropriate containers:
    $item.find('.callnumber').empty().append(linkCallnumbers(result.callnumber, result.callnumber_handler) + '<br/>');
    $item.find('.location').empty().append(
      result.reserve === 'true'
        ? result.reserve_message
        : result.location
    );
  }
}
function itemStatusFail(response, textStatus) {
  if (textStatus === 'abort' || typeof response.responseJSON === 'undefined') {
    return;
  }
  // display the error message on each of the ajax status place holder
  $('.js-item-pending .callnumAndLocation').addClass('text-danger').empty().removeClass('hidden')
    .append(typeof response.responseJSON.data === 'string' ? response.responseJSON.data : VuFind.translate('error_occurred'));
}

var itemStatusIds = [];
var itemStatusEls = {};
var itemStatusTimer = null;
var itemStatusDelay = 200;
var itemStatusRunning = false;

function runItemAjaxForQueue() {
  // Only run one item status AJAX request at a time:
  if (itemStatusRunning) {
    itemStatusTimer = setTimeout(runItemAjaxForQueue, itemStatusDelay);
    return;
  }
  itemStatusRunning = true;
  $.ajax({
    dataType: 'json',
    method: 'POST',
    url: VuFind.path + '/AJAX/JSON?method=getItemStatuses',
    data: { 'id': itemStatusIds }
  })
    .done(function checkItemStatusDone(response) {
      for (var j = 0; j < response.data.statuses.length; j++) {
        var status = response.data.statuses[j];
        displayItemStatus(status, itemStatusEls[status.id]);
        itemStatusIds.splice(itemStatusIds.indexOf(status.id), 1);
      }
      itemStatusRunning = false;
    })
    .fail(function checkItemStatusFail(response, textStatus) {
      itemStatusFail(response, textStatus);
      itemStatusRunning = false;
    });
}

function itemQueueAjax(id, el) {
  if (el.hasClass('js-item-pending')) {
    return;
  }
  clearTimeout(itemStatusTimer);
  itemStatusIds.push(id);
  itemStatusEls[id] = el;
  itemStatusTimer = setTimeout(runItemAjaxForQueue, itemStatusDelay);
  el.addClass('js-item-pending').removeClass('hidden');
  el.find('.callnumAndLocation').removeClass('hidden');
  el.find('.callnumAndLocation .ajax-availability').removeClass('hidden');
  el.find('.status').removeClass('hidden');
}

function checkItemStatus(el) {
  var $item = $(el);
  if ($item.find('.hiddenId').length === 0) {
    return false;
  }
  var id = $item.find('.hiddenId').val();
  itemQueueAjax(id + '', $item);
}

var itemStatusObserver = null;
function checkItemStatuses(_container) {
  var container = typeof _container === 'undefined'
    ? document.body
    : _container;

  var ajaxItems = $(container).find('.ajaxItem');
  for (var i = 0; i < ajaxItems.length; i++) {
    var id = $(ajaxItems[i]).find('.hiddenId').val();
    itemQueueAjax(id, $(ajaxItems[i]));
  }
  // Stop looking for a scroll loader
  if (itemStatusObserver) {
    itemStatusObserver.disconnect();
  }
}
$(document).ready(function checkItemStatusReady() {
  if (typeof Hunt === 'undefined') {
    checkItemStatuses();
  } else {
    itemStatusObserver = new Hunt(
      $('.ajaxItem').toArray(),
      { enter: checkItemStatus }
    );
  }
});
