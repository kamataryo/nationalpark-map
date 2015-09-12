var abstract, changeLoadingState, currentMarker, featureStyle, geojsonAutoload, geojsonLoaded, gradeFill, initialize, loadTopojson, loadingque, map, timerIDcurrentInactivate;

map = null;

geojsonLoaded = {};

abstract = null;

loadingque = [];

currentMarker = null;

timerIDcurrentInactivate = 0;

initialize = function() {
  var $map, options;
  $map = $('#map-canvas');
  options = {
    noClear: true,
    center: new google.maps.LatLng(35.127152, 138.910627),
    zoom: 10,
    mapTypeId: google.maps.MapTypeId.SATELLITE,
    panControl: false,
    zoomControl: false,
    mapTypeControl: true,
    scaleControl: true,
    streetViewControl: true,
    overviewMapControl: false
  };
  map = new google.maps.Map($map[0], options);
  return map.addListener('idle', function() {
    if ($('#auto-overlay').is(':checked')) {
      return geojsonAutoload();
    }
  });
};

gradeFill = {
  "特別保護地区": "#dddd66",
  "海域公園地区": "#2233dd",
  "海中公園地区": "#2233dd",
  "第1種特別地域": "#dd66dd",
  "第2種特別地域": "#dd6666",
  "第3種特別地域": "#66dd66",
  "普通地域": "#66dddd",
  "else": "#666666"
};

featureStyle = function(state, grade) {
  var result;
  result = {
    strokeColor: '#eeeeee',
    strokeWeight: 1,
    fillOpacity: 0.4
  };
  if (grade != null) {
    result.fillColor = gradeFill[grade];
  }
  if (state === 'mouseover') {
    ({
      strokeColor: '#ffffaa'
    });
    result.fillOpacity = 0.7;
    result.strokeWeight = 2.5;
  }
  return result;
};

changeLoadingState = function(loadStateID, state) {
  if (state === 'start') {
    loadingque.push(loadStateID);
    return $('#load-statement').addClass('fa-spin');
  } else if ('finish') {
    loadingque.pop(loadStateID);
    if (loadingque.length === 0) {
      return $('#load-statement').removeClass('fa-spin');
    }
  }
};

loadTopojson = function(basename) {
  var url;
  if (geojsonLoaded[basename]) {
    return false;
  } else {
    geojsonLoaded[basename] = true;
  }
  url = 'topojson/' + basename + '.topojson';
  changeLoadingState(url, 'start');
  return $.getJSON(url, function(json) {
    json = topojson.feature(json, json.objects[basename]);
    map.data.addGeoJson(json);
    map.data.setStyle(function(feature) {
      var grade;
      grade = feature.getProperty('grade');
      return featureStyle('', grade);
    });
    changeLoadingState(url, 'finish');
    map.data.addListener('mouseover', function(e) {
      return map.data.overrideStyle(e.feature, featureStyle('mouseover'));
    });
    map.data.addListener('click', function(e) {
      var grade, infomarker, infowindow, npname;
      npname = e.feature.getProperty('name');
      grade = e.feature.getProperty('grade');
      infowindow = new google.maps.InfoWindow({
        content: e.feature.getProperty('description')
      });
      infomarker = new google.maps.Marker({
        position: e.latLng,
        map: map,
        icon: './img/selected-feature.svg'
      });
      infowindow.addListener('closeclick', function() {
        infomarker.setMap(null);
        return infomarker = null;
      });
      return infowindow.open(map, infomarker);
    });
    return map.data.addListener('mouseout', function(e) {
      return map.data.overrideStyle(e.feature, featureStyle());
    });
  });
};

geojsonAutoload = function() {
  var basename, bottom, c1, c2, c3, c4, information, left, margin, results, right, top;
  if (!abstract) {
    return false;
  }
  margin = -0.3;
  top = map.getBounds().getNorthEast().G;
  right = map.getBounds().getNorthEast().K;
  bottom = map.getBounds().getSouthWest().G;
  left = map.getBounds().getSouthWest().K;
  top += (1 + margin) * (top - bottom);
  right += (1 + margin) * (right - left);
  bottom -= (1 + margin) * (top - bottom);
  left -= (1 + margin) * (right - left);
  results = [];
  for (basename in abstract) {
    information = abstract[basename];
    c1 = information.top > bottom;
    c2 = information.bottom < top;
    c3 = information.right > left;
    c4 = information.left < right;
    if (c1 && c2 && c3 && c4) {
      results.push(loadTopojson(basename));
    } else {
      results.push(void 0);
    }
  }
  return results;
};

$('#auto-overlay').change(function() {
  var state;
  state = $(this).is(':checked');
  if (state === true) {
    return geojsonAutoload();
  }
});

$('#move-to-current').click(function() {
  var result, theClass;
  theClass = $('#geolocation-statement').attr('class');
  result = false;
  if (navigator.geolocation) {
    return navigator.geolocation.getCurrentPosition(function(pos) {
      var theCurrent;
      theCurrent = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
      $('#geolocation-statement').removeClass(theClass).addClass('fa fa-check-circle').css('color', 'green');
      map.panTo(theCurrent);
      if (!currentMarker) {
        currentMarker = new google.maps.Marker({
          position: theCurrent,
          map: map,
          icon: './img/marker-current.svg'
        });
      } else {
        currentMarker.setPosition(theCurrent);
        currentMarker.setIcon('./img/marker-current.svg');
        clearTimeout(timerIDcurrentInactivate);
      }
      return timerIDcurrentInactivate = setTimeout(function() {
        currentMarker.setIcon('./img/marker-inactive.svg');
        return $('#geolocation-statement').removeClass(theClass).addClass('fa fa-question').css('color', 'black');
      }, 5000);
    }, function(e) {
      $('#geolocation-statement').removeClass(theClass).addClass('fa fa-plus-circle fa-rotate-45').css('color', 'red');
      return console.log('現在地取得エラー:' + e);
    });
  } else {
    $('#geolocation-statement').removeClass(theClass).addClass('fa fa-exclamation-triangle').css('color', 'yellow');
    return console.log('位置情報使用不可');
  }
});

$('.toggle-next').each(function(i, elem) {
  var $i, display;
  $(elem).prepend('<i class="fa"></i>');
  $i = $(elem).children('i');
  display = $(elem).next().css('display');
  if (display === 'none') {
    return $i.addClass('fa-angle-double-right');
  } else {
    return $i.addClass('fa-angle-double-down');
  }
});

$('.toggle-next').click(function() {
  var display;
  display = $(this).next().css('display');
  if (display === 'none') {
    $(this).children('i').removeClass('fa-angle-double-right').addClass('fa-angle-double-down');
    return $(this).next().show('fast');
  } else {
    $(this).children('i').removeClass('fa-angle-double-down').addClass('fa-angle-double-right');
    return $(this).next().hide('fast');
  }
});

$.getJSON('./topojson/abstract.json', function(json) {
  var basename, information;
  abstract = json;
  for (basename in json) {
    information = json[basename];
    $('<option>').appendTo($('#handy-overlay')).val(basename + '.topojson').text(information.name + " [" + information.size + " MB]");
  }
  return $('#handy-overlay').change(function() {
    var Clat, Clon, geojsonCenter;
    basename = $(this).val();
    if (basename === '') {
      return false;
    }
    loadTopojson(basename);
    Clat = (json[basename].top + json[basename].bottom) / 2;
    Clon = (json[basename].right + json[basename].left) / 2;
    geojsonCenter = new google.maps.LatLng(Clat, Clon);
    return map.panTo(geojsonCenter);
  });
});

initialize();
