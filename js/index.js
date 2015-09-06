var $map, featureStyle, map, options, urltmp;

$map = $('#map-canvas');

options = {
  noClear: true,
  center: new google.maps.LatLng(35.127152, 138.910627),
  zoom: 16,
  panControl: false,
  zoomControl: false,
  mapTypeControl: true,
  scaleControl: true,
  streetViewControl: true,
  overviewMapControl: false
};

map = new google.maps.Map($map[0], options);

featureStyle = function(state) {
  var result;
  result = {
    strokeColor: '#eeeeee',
    strokeWeight: 3,
    fillOpacity: 2.4
  };
  if (state = 'mouseover') {
    result.fillColor = style.fill;
    return result.fillOpacity = 0.4;
  } else if ('mouseover') {
    return {
      strokeColor: '#ffffff',
      strokeWeight: 3.75,
      fillOpacity: 2.8
    };
  }
};

$.getJSON('./settings.json', function(settings) {
  var loadNationalPark;
  loadNationalPark = function(url) {
    var styleForMap;
    $.getJSON(url, function(json) {
      map.data.addGeoJson(json);
      return map.data.setStyle(function(feature) {
        var determineStyle, style;
        determineStyle = function(feature) {
          var description, i, len, ref, style;
          description = feature.getProperty('description');
          ref = settings.styles;
          for (i = 0, len = ref.length; i < len; i++) {
            style = ref[i];
            if (description.match(RegExp("" + style.name))) {
              return style;
            }
          }
          return 'else';
        };
        return style = determineStyle(feature);
      });
    });
    styleForMap = {
      fillColor: style.fill,
      strokeColor: '#eeeeee',
      strokeWeight: 3,
      fillOpacity: 2.4
    };
    return styleForMap;
  };
  map.data.addListener('mouseover', function(event) {
    var newStyle;
    newStyle = {
      strokeColor: '#ffffff',
      strokeWeight: 3.75,
      fillOpacity: 2.8
    };
    return map.data.overrideStyle(event.feature, newStyle);
  });
  return map.data.addListener('mouseout', function(event) {
    var newStyle;
    newStyle = {
      strokeColor: '#eeeeee',
      strokeWeight: 3,
      fillOpacity: 2.4
    };
    return map.data.overrideStyle(event.feature, newStyle);
  });
});

urltmp = './geojson/NPS_fujihakoneizu.geojson';

loadNationalPark(urltmp);

console.log(settings);

$('#move-to-current').click(function() {
  return true;
});
