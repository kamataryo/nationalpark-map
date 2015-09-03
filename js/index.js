var initialPosition, map, mapElement, myOptions;

mapElement = document.getElementById('map-canvas');

initialPosition = new google.maps.LatLng(35.127152, 138.910627);

myOptions = {
  noClear: true,
  center: initialPosition,
  zoom: 16,
  mapTypeId: google.maps.MapTypeId.ROADMAP
};

map = new google.maps.Map(mapElement, myOptions);

d3.json('./NPs.json', function(data) {
  var styles;
  styles = data.styles;
  return d3.json('./geojson/NPS_fujihakoneizu.geojson', function(data) {
    var styleFeature;
    styleFeature = function(feature) {
      var determineStyle, style, styleForMap;
      determineStyle = function(feature) {
        var description, i, len, style;
        description = feature.getProperty('description');
        for (i = 0, len = styles.length; i < len; i++) {
          style = styles[i];
          if (description.match(RegExp("" + style.name))) {
            return style;
          }
        }
        return 'else';
      };
      style = determineStyle(feature);
      styleForMap = {
        fillColor: style.fill,
        strokeColor: '#eeeeee',
        strokeWeight: 1,
        fillOpacity: 0.4
      };
      return styleForMap;
    };
    map.data.addGeoJson(data);
    map.data.setStyle(styleFeature);
    map.data.addListener('mouseover', function(event) {
      var newStyle;
      newStyle = {
        strokeColor: '#ffffff',
        strokeWeight: 1,
        fillOpacity: 0.8
      };
      return map.data.overrideStyle(event.feature, newStyle);
    });
    return map.data.addListener('mouseout', function(event) {
      var newStyle;
      newStyle = {
        strokeColor: '#eeeeee',
        strokeWeight: 1,
        fillOpacity: 0.4
      };
      return map.data.overrideStyle(event.feature, newStyle);
    });
  });
});
