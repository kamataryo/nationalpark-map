'use strict'

# initialize google map
try
  c = new google.maps.LatLng 35.680795, 139.76721
catch
  console.log 'google map error'
options =
  noClear : true
  center : c
  zoom : 10
  mapTypeId: google.maps.MapTypeId.TERRAIN
  panControl: false
  zoomControl: false
  mapTypeControl: true
  scaleControl: true
  streetViewControl: true
  overviewMapControl: false
map = new google.maps.Map document.getElementById('map'), options

# angular controller definition
app = angular.module 'nationalpark-map', []
app.controller 'mainCtrl', [
    '$scope'
    '$location'
    '$http'
    ($scope, $location, $http) ->
      # read abstract json of national park datum
      $http
          url: './topojson/abstract.json'
          method: 'GET'
        .success (data, status) ->
          if status
            $scope.nps = data
            # hash routing
            initialId = if $location.path()[0] is '/' then $location.path()[1..] else ''
            if initialId in Object.keys $scope.nps
              $scope.onSelect(initialId)


      $scope.onSelect = (id)->
        np = $scope.nps[id]
        $scope.selected =
          url:  "./topojson/#{id}.topojson"
          name: np.name + '国立公園'
          center:
              lat: (np.left + np.right)  / 2
              lng: (np.top  + np.bottom) / 2
        # $http
        #     url: $scope.selected.url
        #     method: 'GET'
        #   .success (data, status) ->
        #     json = topojson.feature data, data.objects[id] #TopoJSON -> GeoJSON
        #     map.data.addGeoJson json
          #   map.data.setStyle (feature) ->
          #       grade = feature.getProperty('grade')
          #       return featureStyle grade

]
