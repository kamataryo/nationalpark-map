(function() {
  var abstract, currentMarker, featureStyle, geojsonAutoload, geojsonLoaded, gradeFill, infomarker, infowindow, initialize, loadTopojson, loadingque, map, timerIDcurrentInactivate, uodateLoadingState;

  map = null;

  geojsonLoaded = {};

  loadingque = [];

  abstract = null;

  currentMarker = null;

  infowindow = null;

  infomarker = null;

  timerIDcurrentInactivate = 0;

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

  initialize = function() {
    var $map, c, error1, options;
    $map = $('#map-canvas');
    try {
      c = new google.maps.LatLng(35.680795, 139.76721);
    } catch (error1) {
      $map.text('Google Maps APIに関する不明なエラーです。');
      console.log(error);
    }
    options = {
      noClear: true,
      center: c,
      zoom: 10,
      mapTypeId: google.maps.MapTypeId.TERRAIN,
      panControl: false,
      zoomControl: false,
      mapTypeControl: true,
      scaleControl: true,
      streetViewControl: true,
      overviewMapControl: false
    };
    map = new google.maps.Map($map[0], options);
    map.addListener('idle', function() {
      if ($('#auto-overlay').is(':checked')) {
        return geojsonAutoload();
      }
    });
    return map.data.addListener('click', function(e) {
      if (infowindow !== null) {
        infowindow.close();
        infowindow = null;
      }
      if (infomarker !== null) {
        infomarker.setMap(null);
        infomarker = null;
      }
      infowindow = new google.maps.InfoWindow({
        content: (e.feature.getProperty('name')) + "国立公園<br>" + (e.feature.getProperty('grade'))
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
  };

  featureStyle = function(grade, opacity) {
    var result;
    result = {
      strokeColor: '#eeeeee',
      strokeWeight: 1.5,
      fillOpacity: 0.40
    };
    if (opacity != null) {
      result.fillOpacity = opacity;
    }
    if (grade != null) {
      result.fillColor = gradeFill[grade];
    }
    return result;
  };

  uodateLoadingState = function(loadStateID, state) {
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
      $('#handy-overlay').children('option').each(function(i, elem) {
        var textModified, textOrigin;
        if ($(elem).val() === basename) {
          textOrigin = $(elem).text();
          textModified = textOrigin.replace(']', ', loaded]');
          return $(elem).text(textModified);
        }
      });
    }
    url = 'topojson/' + basename + '.topojson';
    uodateLoadingState(url, 'start');
    return $.getJSON(url, function(json) {
      json = topojson.feature(json, json.objects[basename]);
      map.data.addGeoJson(json);
      map.data.setStyle(function(feature) {
        var grade;
        grade = feature.getProperty('grade');
        return featureStyle(grade);
      });
      return uodateLoadingState(url, 'finish');
    });
  };

  geojsonAutoload = function() {
    var basename, bottom, c1, c2, c3, c4, information, left, margin, results, right, top;
    if (!abstract) {
      return false;
    }
    margin = -0.2;
    top = map.getBounds().getNorthEast().lat();
    right = map.getBounds().getNorthEast().lng();
    bottom = map.getBounds().getSouthWest().lat();
    left = map.getBounds().getSouthWest().lng();
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
    var display, minified;
    minified = {};
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
      $('<option>').appendTo($('#handy-overlay')).val(basename).text(information.name + " [" + information.size + " " + information.unit + "]");
    }
    $('#handy-overlay').change(function() {
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
    return $('#opacity-range').on('input', function() {
      var opacity;
      opacity = $(this).val();
      return map.data.setStyle(function(feature) {
        var result;
        return result = featureStyle(feature.getProperty('grade'), opacity);
      });
    });
  });

  initialize();

}).call(this);
