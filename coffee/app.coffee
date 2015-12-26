'use strict'

# application definition
app = angular.module 'nationalpark-map', ['ngMap']

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

                $rootScope.serial = serial
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
                $rootScope.$apply()
        }
]




app.controller 'mainCtrl', [
    '$scope'
    'urlParser'
    ($scope, urlParser) ->
        urlParser.parse()
]

app.controller 'navCtrl', [
    '$scope'
    ($scope) ->
        return
]

app.controller 'mapCtrl', [
    '$scope'
    '$rootScope'
    'NgMap'
    'urlEncoder'
    ($scope, $rootScope, NgMap, urlEncoder) ->
        $scope.zoom = $rootScope.serial.mapPosition.zoom
        $scope.latlng = $rootScope.serial.mapPosition.latitude + ',' + $rootScope.serial.mapPosition.longitude
        NgMap.getMap().then (map) ->
            map.addListener 'idle', () ->
                $rootScope.serial.mapPosition =
                    zoom: map.getZoom()
                    latitude : map.getCenter().lat()
                    longitude: map.getCenter().lng()
                urlEncoder.encode()
]





return


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





# old


map = null#googlemapオブジェクトを格納
geojsonLoaded = {}#マップへの読み込み済みgeojsonを判別する
loadingque = []#geojsonの読み込み状態を管理
abstract = null# geojsonのabstractを読み込む
currentMarker = null #現在地を表示するマーカー
infowindow = null#ポップする情報ウィンドウを1つにするためグローバルに参照を格納する
infomarker = null#同上
timerIDcurrentInactivate = 0 # 現在地表示有効期間を設定するためのtimeout用ID
gradeFill =　#地種区分ごとの色を定義
	"特別保護地区": "#dddd66"
	"海域公園地区": "#2233dd"
	"海中公園地区": "#2233dd"
	"第1種特別地域": "#dd66dd"
	"第2種特別地域": "#dd6666"
	"第3種特別地域": "#66dd66"
	"普通地域": "#66dddd"
	"else": "#666666"


# googlemapの初期設定
googleMapInitialize = (mapId) ->
	options =
		noClear : true
		center : new google.maps.LatLng 35.680795, 139.76721
		zoom : 10
		mapTypeId: google.maps.MapTypeId.TERRAIN
		panControl: false
		zoomControl: false
		mapTypeControl: true
		scaleControl: true
		streetViewControl: true
		overviewMapControl: false
	map = new google.maps.Map Document.getElementById(mapId), options

	# autoloadの実行
	map.addListener 'idle', () ->
		if $('#auto-overlay').is ':checked' then geojsonAutoload()


	#クリックで情報ウインドウを表示
	map.data.addListener 'click', (e) ->
		if infowindow isnt null
			infowindow.close()
			infowindow = null
		if infomarker isnt null
			infomarker.setMap null
			infomarker = null
		infowindow = new google.maps.InfoWindow
			content: "#{e.feature.getProperty 'name'}国立公園<br>#{e.feature.getProperty 'grade'}"
		infomarker = new google.maps.Marker
			position: e.latLng
			map: map
			icon: './img/selected-feature.svg'
		infowindow.addListener 'closeclick', () ->
			infomarker.setMap null
			infomarker = null
		infowindow.open map,infomarker


# geojsonフィーチャーの地種とそれに対するイベントから適応するスタイルを決定する
featureStyle = (grade, opacity) ->
	result =
		strokeColor: '#eeeeee'
		strokeWeight: 1.5
		fillOpacity: 0.40
	if opacity?
		result.fillOpacity = opacity
	if grade?
		result.fillColor = gradeFill[grade]
	return result


#topojson読み込み中の状態表示
uodateLoadingState = (loadStateID, state) ->
	if state is 'start'
		loadingque.push loadStateID
		$('#load-statement').addClass 'fa-spin'
	else if 'finish'
		loadingque.pop loadStateID
		if loadingque.length is 0
			$('#load-statement').removeClass 'fa-spin'


# geojson layerの追加と設定
# topojsonファイルのbasenameをキーにしている
loadTopojson = (basename) ->
	if geojsonLoaded[basename]
		return false
	else
		geojsonLoaded[basename] = true
		$('#handy-overlay').children('option').each (i, elem) ->
			if $(elem).val() is basename
				textOrigin = $(elem).text()
				textModified = textOrigin.replace ']', ', loaded]'
				$(elem).text textModified

	url = 'topojson/' + basename + '.topojson'
	uodateLoadingState url,'start'
	$.getJSON url, (json) ->
		json = topojson.feature json,json.objects[basename] #TopoJSON -> GeoJSON
		map.data.addGeoJson json
		map.data.setStyle (feature) ->
			grade = feature.getProperty('grade')
			return featureStyle grade
		uodateLoadingState url,'finish'


#現在の座標位置をもとに、表示範囲内のgeojsonを全て読み込む
geojsonAutoload = () ->
	if !abstract then return false

	margin = -0.2#margin = -20%
	top = map.getBounds().getNorthEast().lat()
	right = map.getBounds().getNorthEast().lng()
	bottom = map.getBounds().getSouthWest().lat()
	left = map.getBounds().getSouthWest().lng()
	top += (1 + margin) * (top - bottom)
	right += (1 + margin) * (right - left)
	bottom -= (1 + margin) * (top - bottom)
	left -= (1 + margin) * (right - left)

	for basename, information of abstract
		c1 = information.top > bottom
		c2 = information.bottom < top
		c3 = information.right > left
		c4 = information.left < right
		if c1 and c2 and c3 and c4
			loadTopojson basename


#自動読み込みのオンオフ
$('#auto-overlay').change () ->
	state = $(this).is ':checked'
	if state is true then geojsonAutoload()


#現在地にpanする
$('#move-to-current').click () ->
	theClass = $('#geolocation-statement').attr 'class'
	result = false
	if navigator.geolocation
		navigator.geolocation.getCurrentPosition (pos) ->
			theCurrent = new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
			$('#geolocation-statement')
				.removeClass theClass
				.addClass 'fa fa-check-circle'
				.css 'color', 'green'
			map.panTo theCurrent
			#現在地にマーカーを追加
			if !currentMarker
			#marker追加
				currentMarker = new google.maps.Marker
					position: theCurrent
					map: map
					icon: './img/marker-current.svg'
			else
				currentMarker.setPosition theCurrent
				currentMarker.setIcon './img/marker-current.svg'
				clearTimeout timerIDcurrentInactivate
			#timeoutをセットし、5秒くらいでdeactiate
			timerIDcurrentInactivate = setTimeout () ->
				currentMarker.setIcon './img/marker-inactive.svg'
				$('#geolocation-statement')
					.removeClass theClass
					.addClass 'fa fa-question'
					.css 'color', 'black'
			,5000

		,(e) ->
			$('#geolocation-statement')
				.removeClass theClass
				#fa-rotate-45機能してない
				.addClass 'fa fa-plus-circle fa-rotate-45'
				.css 'color', 'red'
			console.log '現在地取得エラー:' + e
	else
		$('#geolocation-statement')
			.removeClass theClass
			.addClass 'fa fa-exclamation-triangle'
			.css 'color', 'yellow'
		console.log '位置情報使用不可'


# toggle機能の定義
##toggleアイコンをprepend
##初期状態でtoggleにするにはstyle=display:none
$('.toggle-next').each (i, elem) ->
	$(elem).prepend '<i class="fa"></i>'
	$i = $(elem).children 'i'
	display = $(elem).next().css 'display'
	if display is 'none'
		$i.addClass 'fa-angle-double-right'
	else
		$i.addClass 'fa-angle-double-down'


## toggleの動作の定義
$('.toggle-next').click () ->
	minified = {}
	display = $(this).next().css 'display'
	if display is 'none'
		$(this).children('i')
			.removeClass 'fa-angle-double-right'
			.addClass 'fa-angle-double-down'
		$(this).next().show 'fast'
	else
		$(this).children('i')
			.removeClass 'fa-angle-double-down'
			.addClass 'fa-angle-double-right'
		$(this).next().hide 'fast'



$.getJSON './topojson/abstract.json', (json) ->
	# selectboxに反映
	abstract = json#globalにも格納
	for basename, information of json
		$('<option>')
			.appendTo $ '#handy-overlay'
			.val basename
			.text "#{information.name} [#{information.size} #{information.unit}]"


	$('#handy-overlay').change () ->
		basename = $(this).val()
		if basename is '' then return false
		#url = 'geojson/' + basename
		loadTopojson basename #url + '.topojson'
		#中心座標へ移動
		Clat = (json[basename].top + json[basename].bottom) / 2
		Clon = (json[basename].right + json[basename].left) / 2
		geojsonCenter = new google.maps.LatLng Clat, Clon
		map.panTo geojsonCenter


	#opacityの変更
	$('#opacity-range').on 'input', () ->
		opacity = $(this).val()
		map.data.setStyle (feature) ->
			result = featureStyle (feature.getProperty 'grade'), opacity
initialize()