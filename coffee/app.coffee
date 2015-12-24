'use strict'

# angular controller definition
app = angular.module 'nationalpark-map', ['ngMap']

app.controller 'mainCtrl', [
    '$scope'
    '$location'
    '$http'
    'NgMap'
    ($scope, $location, $http, NgMap) ->
        # read abstract json of national park datum
        query =
            url: './topojson/abstract.json'
            method: 'GET'
        $http(query).success (data, status) ->
            $scope.nps = data
            # hash routing
            urlHash = if $location.path()[0] is '/' then $location.path()[1..] else ''
            if urlHash in Object.keys $scope.nps
                $scope.onSelect(urlHash)

        # define style
        $scope.styles =
            "特別保護地区": "#dd6"
            "海域公園地区": "#23d"
            "海中公園地区": "#23d"
            "第1種特別地域": "#d6d"
            "第2種特別地域": "#d66"
            "第3種特別地域": "#6d6"
            "普通地域": "#6dd"
            "else": "#666"


        # nationalpark selected
        $scope.onSelect = (id) ->
            np = $scope.nps[id]
            $scope.selected =
                url:  "./topojson/#{id}.topojson"
                name: np.name + '国立公園'
                center:
                    lat: (np.left + np.right)  / 2
                    lng: (np.top  + np.bottom) / 2
            query =
                url: $scope.selected.url
                method: 'GET'

            $http(query).success (json, status) ->
                $scope.geoJSON = (topojson.feature json, json.objects[id])#.features #TopoJSON -> GeoJSON
                NgMap.getMap().then (map) ->

                    mapStyler = (feature) ->
                        grade = feature.getProperty 'grade'
                        {
                            strokeColor: $scope.lineColor
                            strokeWeight: $scope.lineWidth
                            fillOpacity: $scope.opacity
                            fillColor: if grade? then $scope.styles[grade] else $scope.styles['else']
                        }

                    map.data.addGeoJson $scope.geoJSON
                    map.data.setStyle mapStyler

                    # bind style values
                    for style in ['opacity', 'lineColor', 'lineWidth']
                        $scope.$watch style ,() ->
                            map.data.setStyle mapStyler




]










return


# 一回だけ現在地を取得
geolocatorOptions =
    enableHighAccuracy: true
    timeout: 8000
    maximumAge: 1000

if navigator.geolocation
    # the device offer geolocation
    navigator.geolocation.getCurrentPosition (pos) ->
        # geolocation success
        console.log pos.coords.latitude, pos.coords.longitude
        # return new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
    ,(error) ->
        # geolocation failed
        msg=
            0:'unknown error'
            1:'access permission denied'
            2:'due to device or environment'
            3:'timeout'
        console.log "error #{error.code}:#{msg[error.code]}"
    ,geolocatorOptions
else
    # the device donot offer geolocation
    console.log 'your device donot offer geolocation.'


# 現在地をwatch
watchState =
    id: null
    count: 0
    lastUpdated: 0
    map: null
    marker: null
if navigator.geolocation
    # the device offer geolocation
    watchState.id = navigator.geolocation.watchPosition (pos) ->
        # geolocation success
        watchState.count++
        now = Math.floor(new Date() / 1000)
        if watchState.lastUpdated + 3 > now
            return false
        else
            watchState.lastUpdate = now
        console.log pos.coords.latitude, pos.coords.longitude
        # return new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
    ,(error) ->
        # geolocation failed
        msg=
            0:'unknown error'
            1:'access permission denied'
            2:'due to device or environment'
            3:'timeout'
        console.log "error #{error.code}:#{msg[error.code]}"
    ,geolocatorOptions
else
    # the device donot offer geolocation
    console.log 'your device donot offer geolocation.'
