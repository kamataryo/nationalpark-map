# googlemapの初期設定
	$map = $ '#map-canvas'
	options =
		noClear : true
		center : new google.maps.LatLng 35.127152, 138.910627
		zoom : 16
		panControl: false
		zoomControl: false
		mapTypeControl: true
		scaleControl: true
		streetViewControl: true
		overviewMapControl: false
	map = new google.maps.Map $map[0], options
	

	featureStyle = (state) ->
		result =
			strokeColor: '#eeeeee'
			strokeWeight: 3
			fillOpacity: 2.4

		if state='mouseover'
			result.fillColor = style.fill
			result.fillOpacity = 0.4
		else if 'mouseover'
			strokeColor: '#ffffff'
			strokeWeight: 3.75
			fillOpacity: 2.8



	# 国立公園settingsの読み込み
	$.getJSON './settings.json', (settings) ->
	# 国立公園データの読み込み
		loadNationalPark = (url) ->
			$.getJSON url, (json) ->
				map.data.addGeoJson json
				map.data.setStyle (feature) ->
					determineStyle = (feature) ->
						description = feature.getProperty('description')
						for style in settings.styles
							if description.match ///#{style.name}///
								return style
						return 'else'
					style = determineStyle feature

			styleForMap =
				fillColor: style.fill
				strokeColor: '#eeeeee'
				strokeWeight: 3
				fillOpacity: 2.4
			return styleForMap
		map.data.addListener 'mouseover', (event) ->
			newStyle =
				strokeColor: '#ffffff'
				strokeWeight: 3.75
				fillOpacity: 2.8
			map.data.overrideStyle event.feature, newStyle
		map.data.addListener 'mouseout', (event) ->
			newStyle =
				strokeColor: '#eeeeee'
				strokeWeight: 3
				fillOpacity: 2.4
			map.data.overrideStyle event.feature, newStyle
	urltmp = './geojson/NPS_fujihakoneizu.geojson'
	loadNationalPark urltmp
	console.log settings


	#コントロール類の動作を定義
	$('#move-to-current').click () ->
		return true
