p3 = d3
	.select 'body'
	.selectAll 'p'


dataset = [12, 24, 32]
p3
 .data dataset
 .text (d, i) ->
	 return "#{i + 1}番目は#{d}"
# googlemapの初期設定
# $map = $('#map')
# initialPosition = new google.maps.LatLng 35.127152, 138.910627
# myOptions =
# 	noClear : true,
# 	center : initialPosition,
# 	zoom : 16,
# 	mapTypeId : google.maps.MapTypeId.ROADMAP
# googlemapCanvas = new google.maps.Map $map[0], myOptions# $map[0]でdomに変換
