'use strict'

# application definition
app = angular.module 'nationalpark-map', ['ngMap']

# Shared State Service
app.factory 'SSS', () ->
        return {
            text: 'Shared State Service'
        }


# http request for abstract of topojson files
app.service 'requestAbstract', [
    'SSS'
    '$http'
    (SSS, $http) ->
        #Angular create method `success` of this automatically.
        $http
            url: './topojson/abstract.json'
            method: 'GET'
        .success (list) ->
            SSS.nplist = list
]


# bind map location and URL
app.service 'clientSideRouting', [
    'SSS'
    '$location'
    'requestAbstract'
    (SSS, $location, requestAbstract) ->
        service = this
        requestAbstract.success (data) ->
            # validate =
            #     id: (id) -> id in Object.keys(data)
            #     zoom: (zoom) -> zoom in [1..20]
            #     latitude: (lat)  -> (-90 < lat) and (lat < 90)
            #     longitude: (lng) -> return
            locationElements = $location.path().split('/').filter (e) -> e isnt ''
            SSS.located = {}
            SSS.located.id = locationElements[0]
            SSS.located.zoom = locationElements[1]
            SSS.located.latitude = locationElements[2]
            SSS.located.longitude = locationElements[3]
]


app.controller 'navCtrl', [
    'SSS'
    '$scope'
    'requestAbstract'
    (SSS, $scope, requestAbstract) ->
        return
]

app.controller 'mapCtrl', [
    '$scope'
    ($scope) ->
        return
]





app.controller 'mainCtrl', [
    'SSS'
    '$scope'
    '$location'
    '$http'
    'requestAbstract'
    'clientSideRouting'
    'NgMap'
    (SSS, $scope, $location, $http,requestAbstract,clientSideRouting, NgMap) ->
        # read abstract json of national park datum
        $scope.selected = {}
        requestAbstract.success (data) ->
            $scope.nplist = SSS.nplist
            id = SSS.located.id
            $scope.onSelect(id)


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


        mapStyler = (feature) ->
            grade = feature.getProperty 'grade'
            {
                strokeColor: $scope.lineColor
                strokeWeight: $scope.lineWidth
                fillOpacity: $scope.opacity
                fillColor: if grade? then $scope.styles[grade] else $scope.styles['else']
            }

        # nationalpark selected
        $scope.onSelect = (id) ->
            if $scope.selected
                if id is $scope.selected.id then return

            np = $scope.nplist[id]
            console.log np
            url = "./topojson/#{id}.topojson"
            $scope.selected =
                id: id
                url:  url
                name: np.name + '国立公園'
                center:
                    lat: (np.left + np.right)  / 2
                    lng: (np.top  + np.bottom) / 2
            query =
                url: url
                method: 'GET'

            $http(query).success (json, status) ->
                $scope.selected.geoJSON = (topojson.feature json, json.objects[id])# #TopoJSON -> GeoJSON

                # google map manipulation
                NgMap.getMap().then (map) ->
                    map.data.forEach (feature) ->
                        map.data.remove feature
                    map.data.addGeoJson $scope.selected.geoJSON
                    map.data.setStyle mapStyler
                    unless $scope.tracking then map.panTo new google.maps.LatLng $scope.selected.center.lng, $scope.selected.center.lat



        NgMap.getMap().then (map) ->
            # bind style values
            for style in ['opacity', 'lineColor', 'lineWidth']
                $scope.$watch style ,() ->
                    map.data.setStyle mapStyler

            # for client side routing
            map.addListener 'idle', () ->
                $scope.selected.id = $scope.id
                $scope.selected.zoom = map.zoom
                $scope.selected.lat = map.center.lat()
                $scope.selected.lng = map.center.lng()

                $location.path [
                    $scope.selected.id
                    $scope.selected.zoom
                    $scope.selected.lat
                    $scope.selected.lng
                ].join '/'

                $location.search {
                    id:$scope.selected.id
                }
                # console.log $scope.selected.id
                console.log $location.path()

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
