'use strict'
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

            capital = $location.path()[0]
            initialId = if capital is '/' then $location.path()[1..]
            if initialId in Object.keys $scope.nps
              $scope.onSelect(initialId)
            else
              $location.path ''

      $scope.onSelect = (id)->
        np = $scope.nps[id]
        $scope.selected =
          url:  "./topojson/#{id}.topojson"
          name: np.name + '国立公園'
          center:
              lat: (np.left + np.right)  / 2
              lng: (np.top  + np.bottom) / 2
]
