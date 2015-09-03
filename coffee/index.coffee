
# googlemapの初期設定
mapElement = document.getElementById 'map-canvas'
initialPosition = new google.maps.LatLng 35.127152, 138.910627
myOptions =
	noClear : true,
	center : initialPosition,
	zoom : 16,
	mapTypeId : google.maps.MapTypeId.ROADMAP
map = new google.maps.Map mapElement, myOptions




d3.json './NPs.json', (data) ->
	styles = data.styles

	d3.json './geojson/NPS_fujihakoneizu.geojson', (data) ->

		styleFeature = (feature) ->

			determineStyle = (feature) ->
				description = feature.getProperty('description')
				for style in styles
					if description.match ///#{style.name}///
						return style
				return 'else'
			style = determineStyle feature

			styleForMap =
				fillColor: style.fill
				strokeColor: '#eeeeee'
				strokeWeight: 1
				fillOpacity: 0.4
			return styleForMap



		map.data.addGeoJson data

		map.data.setStyle styleFeature

		map.data.addListener 'mouseover', (event) ->
			newStyle =
				strokeColor: '#ffffff'
				strokeWeight: 1
				fillOpacity: 0.8
			map.data.overrideStyle event.feature, newStyle

		map.data.addListener 'mouseout', (event) ->
			newStyle =
				strokeColor: '#eeeeee'
				strokeWeight: 1
				fillOpacity: 0.4
			map.data.overrideStyle event.feature, newStyle
