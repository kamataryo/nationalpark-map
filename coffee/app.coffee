'use strict'

# application definition
app = angular.module 'nationalpark-map', [
    'ngMap'
    'ngMdIcons'
    'ngTouch'
    # 'angular-loading-bar'
]

# The urlParserService parses and interprets $location as inner page information(npid & mapPosition).
# The inner page information will be serialized as  on $rootScope.
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
            getDefaultPosition: () ->
                defaultPosition
            parse: () ->
                # get default values
                npid = ''
                zoom = defaultPosition.zoom
                latitude = defaultPosition.latitude
                longitude = defaultPosition.longitude
                elements = $location.path().split('/').filter (e) -> e isnt ''
                queries = $location.search()

                if elements.length > 3
                    npid = elements[0]
                    _zoom = parseInt elements[1]
                    _latitude = parseFloat elements[2]
                    _longitude = parseFloat elements[3]
                else if elements.length is 3
                    _zoom = parseInt elements[0]
                    _latitude = parseFloat elements[1]
                    _longitude = parseFloat elements[2]
                else if elements.length is 2
                    npid = elements[0]
                else if elements.length is 1
                    npid = elements[0]

                unless isNaN(_zoom) or isNaN(_latitude) or isNaN(_longitude)
                    zoom = _zoom
                    latitude = _latitude
                    longitude = _longitude

                serial =
                    npid: npid
                    mapPosition:
                        zoom: zoom
                        latitude: latitude
                        longitude: longitude
                    pin: if queries.pin? then queries.pin else ''
                $rootScope.serial = serial
                $rootScope.$emit 'urlParsed'
                return serial
        }
]

# The urlEncoder service read $rootScope and get serialized inner page information.
# The URL will be rewrited with these values.
app.service 'urlEncoder', [
    '$location'
    '$rootScope'
    ($location, $rootScope) ->
        return {
            encode: () ->
                path = [
                    $rootScope.serial.npid
                    $rootScope.serial.mapPosition.zoom
                    $rootScope.serial.mapPosition.latitude
                    $rootScope.serial.mapPosition.longitude
                ].join '/'
                $location.path path
                if $rootScope.serial.pin
                    $location.search pin:$rootScope.serial.pin
                # TODO $applyを適切に使うようにする
                $rootScope.$apply()
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
            load: () ->
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
            load: () ->
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

app.controller 'mainCtrl', [
    '$scope'
    '$rootScope'
    'urlParser'
    'abstractLoader'
    ($scope,$rootScope, urlParser, abstractLoader) ->
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
        $scope.toggleNav = () ->
            $scope.navOpen = ! $scope.navOpen

        $scope.locating = false
        $scope.locatingIcon = 'my_location'
        $scope.locationIconColorOpacity = 1
        $scope.locateMe = () ->
            $scope.locating = ! $scope.locating
            if $scope.locating
                $scope.locatingIcon = 'gps_off'
                $scope.locationIconColorOpacity = .5
            else
                $scope.locatingIcon = 'my_location'
                $scope.locationIconColorOpacity = 1
]

app.controller 'navCtrl', [
    '$scope'
    '$rootScope'
    'topojsonLoader'
    'urlEncoder'
    'mapFocuser'
    ($scope, $rootScope, topolsonLoader, urlEncoder, mapFocuser) ->
        $rootScope.$on 'abstractLoaded', () ->
            $scope.npAbstract = $rootScope.abstract
            if $rootScope.serial then $scope.onSelect($rootScope.serial.npid, false)

        $scope.onSelect = (npid, focus) ->
            if $scope.selected
                if npid is $scope.selected then return
            $scope.selected = npid
            $rootScope.serial.npid = npid

            if focus
                top = $scope.npAbstract[npid].top
                bottom = $scope.npAbstract[npid].bottom
                left = $scope.npAbstract[npid].left
                right = $scope.npAbstract[npid].right
                mapFocuser.focus  (top + bottom) / 2, (right + left) / 2

            topolsonLoader.load()
            urlEncoder.encode()
            # https://docs.angularjs.org/error/$rootScope/inprog?p0=$apply
            # $apply()の意味を私がわかっていない。2度目以降は失敗する。最初に一度$apply()しておけばいいのか..?
            # TODO encoderサービスを治す

        reflectStyles = () ->
            $rootScope.lineColor = $scope.lineColor
            $rootScope.lineWidth = $scope.lineWidth
            $rootScope.opacity = $scope.opacity
        getStyleId = () ->
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
        $scope.pin = ''

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
            # TODO:$watchで書き換え
            if $rootScope.serial.pin
                 $scope.pin = $rootScope.serial.pin

            $scope.pinSetCallback = (event) ->
                $scope.pin = [
                    event.latLng.lat()
                    event.latLng.lng()
                ].join ','
                $rootScope.serial.pin = $scope.pin
                urlEncoder.encode()
                $scope.$apply()

            $scope.addData = () ->
                map.data.forEach (feature) -> map.data.remove feature # synchronous
                map.data.addGeoJson $rootScope.geojson
                map.data.setStyle $scope.mapStyler
                map.data.addListener 'click', $scope.pinSetCallback

            $rootScope.$watch () ->
                return $rootScope.geojson
            , $scope.addData

            map.addListener 'click', $scope.pinSetCallback

            # rewrite URL when map have finished moving
            map.addListener 'idle', () ->
                $rootScope.serial.mapPosition =
                    zoom: map.getZoom()
                    latitude : map.getCenter().lat()
                    longitude: map.getCenter().lng()
                urlEncoder.encode()

            # bind style values
            for style in ['opacity', 'lineColor', 'lineWidth']
                $rootScope.$watch style ,() ->
                    map.data.setStyle $scope.mapStyler
]





return

#
#
# # 一回だけ現在地を取得
# geolocatorOptions =
#     enableHighAccuracy: true
#     timeout: 8000
#     maximumAge: 1000
#
# if navigator.geolocation
#     # the device offer geolocation
#     navigator.geolocation.getCurrentPosition (pos) ->
#         # geolocation success
#         console.log pos.coords.latitude, pos.coords.longitude
#         # return new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
#     ,(error) ->
#         # geolocation failed
#         msg=
#             0:'unknown error'
#             1:'access permission denied'
#             2:'due to device or environment'
#             3:'timeout'
#         console.log "error #{error.code}:#{msg[error.code]}"
#     ,geolocatorOptions
# else
#     # the device donot offer geolocation
#     console.log 'your device donot offer geolocation.'
#
#
# # 現在地をwatch
# watchState =
#     id: null
#     count: 0
#     lastUpdated: 0
#     map: null
#     marker: null
# if navigator.geolocation
#     # the device offer geolocation
#     watchState.id = navigator.geolocation.watchPosition (pos) ->
#         # geolocation success
#         watchState.count++
#         now = Math.floor(new Date() / 1000)
#         if watchState.lastUpdated + 3 > now
#             return false
#         else
#             watchState.lastUpdate = now
#         console.log pos.coords.latitude, pos.coords.longitude
#         # return new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
#     ,(error) ->
#         # geolocation failed
#         msg=
#             0:'unknown error'
#             1:'access permission denied'
#             2:'due to device or environment'
#             3:'timeout'
#         console.log "error #{error.code}:#{msg[error.code]}"
#     ,geolocatorOptions
# else
#     # the device donot offer geolocation
#     console.log 'your device donot offer geolocation.'
#
#
#
#
#
# # old
#
#
# map = null#googlemapオブジェクトを格納
# geojsonLoaded = {}#マップへの読み込み済みgeojsonを判別する
# loadingque = []#geojsonの読み込み状態を管理
# abstract = null# geojsonのabstractを読み込む
# currentMarker = null #現在地を表示するマーカー
# infowindow = null#ポップする情報ウィンドウを1つにするためグローバルに参照を格納する
# infomarker = null#同上
# timerIDcurrentInactivate = 0 # 現在地表示有効期間を設定するためのtimeout用ID
# gradeFill =　#地種区分ごとの色を定義
# 	"特別保護地区": "#dddd66"
# 	"海域公園地区": "#2233dd"
# 	"海中公園地区": "#2233dd"
# 	"第1種特別地域": "#dd66dd"
# 	"第2種特別地域": "#dd6666"
# 	"第3種特別地域": "#66dd66"
# 	"普通地域": "#66dddd"
# 	"else": "#666666"
#
#
# # googlemapの初期設定
# googleMapInitialize = (mapId) ->
# 	options =
# 		noClear : true
# 		center : new google.maps.LatLng 35.680795, 139.76721
# 		zoom : 10
# 		mapTypeId: google.maps.MapTypeId.TERRAIN
# 		panControl: false
# 		zoomControl: false
# 		mapTypeControl: true
# 		scaleControl: true
# 		streetViewControl: true
# 		overviewMapControl: false
# 	map = new google.maps.Map Document.getElementById(mapId), options
#
# 	# autoloadの実行
# 	map.addListener 'idle', () ->
# 		if $('#auto-overlay').is ':checked' then geojsonAutoload()
#
#

#

#

#
#
# # geojson layerの追加と設定
# # topojsonファイルのbasenameをキーにしている
# loadTopojson = (basename) ->
# 	if geojsonLoaded[basename]
# 		return false
# 	else
# 		geojsonLoaded[basename] = true
# 		$('#handy-overlay').children('option').each (i, elem) ->
# 			if $(elem).val() is basename
# 				textOrigin = $(elem).text()
# 				textModified = textOrigin.replace ']', ', loaded]'
# 				$(elem).text textModified
#
# 	url = 'topojson/' + basename + '.topojson'
# 	uodateLoadingState url,'start'
# 	$.getJSON url, (json) ->
# 		json = topojson.feature json,json.objects[basename] #TopoJSON -> GeoJSON
# 		map.data.addGeoJson json
# 		map.data.setStyle (feature) ->
# 			grade = feature.getProperty('grade')
# 			return featureStyle grade
# 		uodateLoadingState url,'finish'
#
#
#
#
#
# #自動読み込みのオンオフ
# $('#auto-overlay').change () ->
# 	state = $(this).is ':checked'
# 	if state is true then geojsonAutoload()
#
#
# #現在地にpanする
# $('#move-to-current').click () ->
# 	theClass = $('#geolocation-statement').attr 'class'
# 	result = false
# 	if navigator.geolocation
# 		navigator.geolocation.getCurrentPosition (pos) ->
# 			theCurrent = new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
# 			$('#geolocation-statement')
# 				.removeClass theClass
# 				.addClass 'fa fa-check-circle'
# 				.css 'color', 'green'
# 			map.panTo theCurrent
# 			#現在地にマーカーを追加
# 			if !currentMarker
# 			#marker追加
# 				currentMarker = new google.maps.Marker
# 					position: theCurrent
# 					map: map
# 					icon: './img/marker-current.svg'
# 			else
# 				currentMarker.setPosition theCurrent
# 				currentMarker.setIcon './img/marker-current.svg'
# 				clearTimeout timerIDcurrentInactivate
# 			#timeoutをセットし、5秒くらいでdeactiate
# 			timerIDcurrentInactivate = setTimeout () ->
# 				currentMarker.setIcon './img/marker-inactive.svg'
# 				$('#geolocation-statement')
# 					.removeClass theClass
# 					.addClass 'fa fa-question'
# 					.css 'color', 'black'
# 			,5000
#
# 		,(e) ->
# 			$('#geolocation-statement')
# 				.removeClass theClass
# 				#fa-rotate-45機能してない
# 				.addClass 'fa fa-plus-circle fa-rotate-45'
# 				.css 'color', 'red'
# 			console.log '現在地取得エラー:' + e
# 	else
# 		$('#geolocation-statement')
# 			.removeClass theClass
# 			.addClass 'fa fa-exclamation-triangle'
# 			.css 'color', 'yellow'
# 		console.log '位置情報使用不可'
#
#
#
#
# ## toggleの動作の定義
# $('.toggle-next').click () ->
# 	minified = {}
# 	display = $(this).next().css 'display'
# 	if display is 'none'
# 		$(this).children('i')
# 			.removeClass 'fa-angle-double-right'
# 			.addClass 'fa-angle-double-down'
# 		$(this).next().show 'fast'
# 	else
# 		$(this).children('i')
# 			.removeClass 'fa-angle-double-down'
# 			.addClass 'fa-angle-double-right'
# 		$(this).next().hide 'fast'
#
#
#
# $.getJSON './topojson/abstract.json', (json) ->
# 	# selectboxに反映
# 	abstract = json#globalにも格納
# 	for basename, information of json
# 		$('<option>')
# 			.appendTo $ '#handy-overlay'
# 			.val basename
# 			.text "#{information.name} [#{information.size} #{information.unit}]"
#
#
# 	$('#handy-overlay').change () ->
# 		basename = $(this).val()
# 		if basename is '' then return false
# 		#url = 'geojson/' + basename
# 		loadTopojson basename #url + '.topojson'
# 		#中心座標へ移動
# 		Clat = (json[basename].top + json[basename].bottom) / 2
# 		Clon = (json[basename].right + json[basename].left) / 2
# 		geojsonCenter = new google.maps.LatLng Clat, Clon
# 		map.panTo geojsonCenter
#
#
# 	#opacityの変更
# 	$('#opacity-range').on 'input', () ->
# 		opacity = $(this).val()
# 		map.data.setStyle (feature) ->
# 			result = featureStyle (feature.getProperty 'grade'), opacity
# initialize()
