'use strict'

# application definition
app = angular.module 'nationalpark-map', [
    'ngMap'
    'ngMdIcons'
    'ngTouch'
]


# The urlParserService parses and interprets $location as inner page information(npid & mapPosition).
# The inner page information will be serialized as on $rootScope.
app.service 'urlParser', [
    '$location'
    '$rootScope'
    ($location, $rootScope) ->
        #TokyoStation
        defaultPosition =
            zoom:10
            latitude: 35.680795
            longitude: 139.76721
        return {
            getDefaultPosition: ->
                defaultPosition
            parse: ->
                #get location data
                elements = $location.path().split('/').filter (e) -> e isnt ''
                queries = $location.search()
                # get default values
                npid = ''
                zoom = defaultPosition.zoom
                latitude = defaultPosition.latitude
                longitude = defaultPosition.longitude
                pin = ''
                # support multiple type arguments from /a/b/c/..
                if elements.length > 3 # id, zoom, lat, lng
                    npid = elements[0]
                    _zoom = parseInt elements[1],10
                    _latitude = parseFloat elements[2]
                    _longitude = parseFloat elements[3]
                else if elements.length is 3 # zoom, lat, lng
                    _zoom = parseInt elements[0],10
                    _latitude = parseFloat elements[1]
                    _longitude = parseFloat elements[2]
                else if elements.length is 2
                    npid = elements[0]
                else if elements.length is 1
                    npid = elements[0]

                # override
                unless isNaN(_zoom) or isNaN(_latitude) or isNaN(_longitude)
                    zoom = Math.min(_zoom, 18)
                    latitude = _latitude
                    longitude = _longitude
                pin = if queries.pin? then queries.pin else ''

                $rootScope.serial =
                    npid: npid
                    mapPosition:
                        zoom: zoom
                        latitude: latitude
                        longitude: longitude
                    pin: pin
        }
]

# The urlEncoder service read $rootScope and get serialized inner page information.
# The URL will be rewrited with these values.
app.service 'urlEncoder', [
    '$location'
    '$rootScope'
    ($location, $rootScope) ->
        return {
            encode: ->
                path = [
                    $rootScope.serial.npid
                    $rootScope.serial.mapPosition.zoom
                    $rootScope.serial.mapPosition.latitude
                    $rootScope.serial.mapPosition.longitude
                ].join '/'
                $location.path path
                if $rootScope.serial.pin is ''
                    $location.search pin: null
                else
                    $location.search pin: $rootScope.serial.pin
        }
]

# ajax load of abstract.json
app.service 'abstractLoader', [
    '$http'
    '$rootScope'
    ($http, $rootScope) ->
        query =
            url: './topojson/abstract.json'
            method: 'GET'
        return {
            load: ->
                $http(query).success (data) ->
                    $rootScope.abstract = data
                    $rootScope.$emit 'abstractLoaded'
        }
]

#ajax load of topojson
app.service 'topojsonLoader', [
    '$http'
    '$rootScope'
    ($http, $rootScope) ->
        return {
            load: ->
                unless $rootScope.serial then return false
                unless $rootScope.serial.npid then return false
                query =
                    url: "./topojson/#{$rootScope.serial.npid}.topojson"
                    method: 'GET'
                $http(query).success (json) ->
                    $rootScope.geojson = (topojson.feature json, json.objects[$rootScope.serial.npid]) #TopoJSON -> GeoJSON
        }
]

app.service 'mapFocuser', [
    'NgMap'
    (NgMap) ->
        return {
            focus: (lat, lng) ->
                NgMap.getMap().then (map) ->
                    map.panTo new google.maps.LatLng lat, lng
        }
]

app.service 'geoLocator', [
    '$rootScope'
    'NgMap'
    ($rootScope, NgMap) ->
        geolocatorOptions =
            enableHighAccuracy: true
            timeout: 8000
            maximumAge: 1000
        watchState =
            id: null
            count: 0
            lastUpdated: 0
            map: null
            marker: null
        return {
            start: (tracking) ->
                if navigator.geolocation
                    # the device offer geolocation
                    watchState.id = navigator.geolocation.watchPosition (pos) ->
                        # geolocation success
                        watchState.count++
                        now = Math.floor(new Date() / 1000)
                        if watchState.lastUpdated + 3 > now
                            return false
                        else if $rootScope.dragging
                            return false
                        else
                            watchState.lastUpdate = now
                            $rootScope.current = (pos.coords.latitude + ',' + pos.coords.longitude)
                            $rootScope.$emit 'currentMoved'
                            if tracking is true
                                NgMap.getMap().then (map) ->
                                    map.panTo new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
                        # return new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
                    ,(error) ->
                        # geolocation failed
                        msg=
                            0:'unknown error'
                            1:'access permission denied'
                            2:'due to device or environment'
                            3:'timeout'
                        console.log "error #{error.code}:#{msg[error.code]}"
                        if error.code is 1 then $rootScope.$emit 'geolocationFailed'

                    ,geolocatorOptions
                else
                    # the device donot offer geolocation
                    console.log 'your device donot offer geolocation.'
                    $rootScope.$emit 'geolocationFailed'

            stop: ->
                if navigator.geolocation
                    # the device offer geolocation
                    navigator.geolocation.clearWatch watchState.id
                    $rootScope.$emit 'geolocationStopped'

        }
]

app.controller 'mainCtrl', [
    '$scope'
    '$rootScope'
    'urlParser'
    'abstractLoader'
    'geoLocator'
    ($scope,$rootScope, urlParser, abstractLoader, geoLocator) ->
        #define fill style
        $rootScope.fillStyles =
            '特別保護地区': '#dddd66'
            '海域公園地区': '#2233dd'
            '海中公園地区': '#2233dd'
            '第1種特別地域': '#dd66dd'
            '第2種特別地域': '#dd6666'
            '第3種特別地域': '#66dd66'
            '特別地域': '#343265'
            '普通地域': '#66dddd'
            'else': '#666666'
        $scope.fiiStyles = $rootScope.fillStyles
        urlParser.parse()
        abstractLoader.load()

        #navbar firstsetting
        $scope.navOpen = true
        #toggle side navbar
        $scope.toggleNav = ->
            $scope.navOpen = ! $scope.navOpen

        $scope.locatingButtonIcon = 'gps_fixed'
        $scope.toggleLocator = ->
            if $scope.locatingButtonIcon is 'gps_fixed'
                geoLocator.start(true)
                $scope.locatingButtonIcon = 'gps_off'
            else
                $scope.locatingButtonIcon = 'gps_fixed'
                geoLocator.stop()
        $scope.$on 'geolocationFailed', ->
            $rootScope.locatingButtonIcon = 'gps_fixed'

        $scope.pinButtonIcon = if $rootScope.serial.pin is '' then 'location_on' else 'location_off'
        $scope.togglePin = ->
            if $scope.pinButtonIcon is 'location_on'
                $scope.$broadcast 'force:pinSet'
                $scope.pinButtonIcon = 'location_off'
            else
                $scope.$broadcast 'force:pinRemove'
                $scope.pinButtonIcon = 'location_on'

        $scope.$on 'pinSet', ->
            $scope.pinButtonIcon = 'location_off'

        $scope.$on 'pinRemove', ->
            $scope.pinButtonIcon = 'location_on'
]



app.controller 'navCtrl', [
    '$scope'
    '$rootScope'
    'topojsonLoader'
    'urlEncoder'
    'mapFocuser'
    ($scope, $rootScope, topolsonLoader, urlEncoder, mapFocuser) ->
        $rootScope.$on 'abstractLoaded', ->
            $scope.npAbstract = $rootScope.abstract
            if $rootScope.serial then $scope.onSelect($rootScope.serial.npid, false)

        $scope.description = '国立公園の区域を閲覧し、位置情報を共有するためのサービスです。'
        $scope.keywords = '国立公園,地図,マップ,規制,区域'
        $scope.ogurl = "http://kamataryo.github.io/nationalpark-map/"

        $scope.onSelect = (npid, focus) ->
            if $scope.selected
                if npid is $scope.selected then return
            $scope.selected = npid
            $rootScope.serial.npid = npid
            $scope.description = $scope.npAbstract[npid].name + '国立公園の区域を閲覧し、位置情報を共有するためのサービスです。'
            $scope.keywords = $scope.npAbstract[npid].name + '国立公園,地図,マップ,規制,区域'
            $scope.ogurl = "http://kamataryo.github.io/nationalpark-map/\#/#{npid}"

            if focus
                top = $scope.npAbstract[npid].top
                bottom = $scope.npAbstract[npid].bottom
                left = $scope.npAbstract[npid].left
                right = $scope.npAbstract[npid].right
                mapFocuser.focus  (top + bottom) / 2, (right + left) / 2

            topolsonLoader.load()
            urlEncoder.encode()

        reflectStyles = ->
            $rootScope.lineColor = $scope.lineColor
            $rootScope.lineWidth = $scope.lineWidth
            $rootScope.opacity = $scope.opacity

        getStyleId = ->
            '' + $scope.lineColor + $scope.lineWidth + $scope.opacity

        $scope.getRGBA = (color, a) ->
            return "rgba(#{color},#{a}"

        # for first
        reflectStyles()

        #bind style values
        $rootScope.$watch getStyleId, reflectStyles
]

app.controller 'mapCtrl', [
    '$scope'
    '$rootScope'
    'NgMap'
    'urlEncoder'
    ($scope, $rootScope, NgMap, urlEncoder) ->
        # reflect to the scope and initialize map
        # TODO:$watchで書き換え
        $scope.zoom = $rootScope.serial.mapPosition.zoom
        $scope.latlng = $rootScope.serial.mapPosition.latitude + ',' + $rootScope.serial.mapPosition.longitude
        $scope.pin = '100000,100000'
        $scope.current = '100000,100000'

        NgMap.getMap().then (map) ->

            $scope.mapStyler = (feature) ->
                grade = feature.getProperty 'grade'
                return {
                    strokeColor: $rootScope.lineColor
                    strokeWeight: $rootScope.lineWidth
                    fillOpacity: $rootScope.opacity
                    fillColor: if grade? then $rootScope.fillStyles[grade] else $scope.styles['else']
                }

            # set initial pin if queried
            if $rootScope.serial.pin isnt ''
                $scope.pin = $rootScope.serial.pin

            $scope.$on 'force:pinSet', ->
                # set pin at map center
                $scope.pin = $rootScope.serial.mapPosition.latitude + ',' + $rootScope.serial.mapPosition.longitude
                $rootScope.serial.pin = $scope.pin
                urlEncoder.encode()

            $scope.$on 'force:pinRemove', ->
                $scope.pin = '1000000,1000000'
                $rootScope.serial.pin = ''
                urlEncoder.encode()

            $scope.pinSetCallback = (event) ->
                $scope.pin = [
                    event.latLng.lat()
                    event.latLng.lng()
                ].join ','
                $rootScope.serial.pin = $scope.pin
                urlEncoder.encode()
                $scope.$emit 'pinSet'
                $scope.$apply()

            $scope.addData = ->
                map.data.forEach (feature) -> map.data.remove feature # synchronous
                map.data.addGeoJson $rootScope.geojson
                map.data.setStyle $scope.mapStyler
                map.data.addListener 'click', $scope.pinSetCallback

            $rootScope.$watch ->
                return $rootScope.geojson
            , $scope.addData

            map.addListener 'click', $scope.pinSetCallback

            # rewrite URL when map have finished moving
            map.addListener 'idle', ->
                $rootScope.serial.mapPosition =
                    zoom: map.getZoom()
                    latitude : map.getCenter().lat()
                    longitude: map.getCenter().lng()
                urlEncoder.encode()
                $rootScope.$apply()

            # Dragging must not interrupts geolocational.
            map.addListener 'dragstart', ->
                $rootScope.dragging = true
            map.addListener 'dragend', ->
                $rootScope.dragging = false

            #current position marker move
            $rootScope.$on 'currentMoved', ->
                $scope.current = $rootScope.current
            $rootScope.$on 'geolocationStopped', ->
                $scope.current = '100000,100000'

            # bind style values
            for style in ['opacity', 'lineColor', 'lineWidth']
                $rootScope.$watch style ,->
                    map.data.setStyle $scope.mapStyler
]
