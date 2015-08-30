#現在の端末の位置に移動させる
moveToCurrentPosition = (gmapobj) ->
	if navigator.geolocation
		## 端末が対応している場合
		opts =
			enableHighAcuracy: true
			timeout: 3000 # 取得のタイムアウト
			maximumAge: 200 # 現在の位置情報をキャッシュする時間

		navigator.geolocation.getCurrentPosition (position) ->
			# 読み取り成功
			newLatLng = new google.maps.LatLng position.coords.latitude, position.coords.longitude
			gmapobj.setCenter newLatLng
		, () ->
			# 読み取りにエラー
			return false
		,opts
	else
		# 端末未対応
		return false




# googlemapの初期設定
$map = $('#map')
initialPosition = new google.maps.LatLng 35.127152, 138.910627
myOptions =
	noClear : true,
	center : initialPosition,
	zoom : 10,
	mapTypeId : google.maps.MapTypeId.ROADMAP
map_canvas = new google.maps.Map $map[0], myOptions# $map[0]でdomに変換


# 国立公園KMLのURLを定義
base = "http://www.biodic.go.jp/trialSystem/LinkEnt/nps/"
NPs =
	# "全国立公園KMLデータ": "NPS_all.kml"
	"利尻礼文サロベツ": "NPS_rishirirebunLinkEnt.kml"
	"知床": "NPS_shiretokoLinkEnt.kml"
	"阿寒": "NPS_akanLinkEnt.kml"
	"釧路湿原": "NPS_kushiroLinkEnt.kml"
	"大雪山": "NPS_daisetsuzanLinkEnt.kml"
	"支笏洞爺": "NPS_shikotsutouyaLinkEnt.kml"
	"十和田八幡平": "NPS_towadahatimantaiLinkEnt.kml"
	"三陸復興": "NPS_sanrikufukkouLinkEnt.kml"
	"磐梯朝日": "NPS_bandaiasahiLinkEnt.kml"
	"日光": "NPS_nikkouLinkEnt.kml"
	"尾瀬": "NPS_ozeLinkEnt.kml"
	"秩父多摩甲斐": "NPS_chichibutamaLinkEnt.kml"
	"小笠原": "NPS_ogasawaraLinkEnt.kml"
	"富士箱根伊豆": "NPS_fujihakoneizuLinkEnt.kml"
	"南アルプス": "NPS_southalpsLinkEnt.kml"
	"上信越高原": "NPS_joshinetsuLinkEnt.kml"
	"中部山岳": "NPS_chubusangakuLinkEnt.kml"
	"白山": "NPS_hakusanLinkEnt.kml"
	"伊勢志摩": "NPS_iseshimaLinkEnt.kml"
	"吉野熊野": "NPS_yoshinokumanoLinkEnt.kml"
	"山陰海岸": "NPS_saninkaiganLinkEnt.kml"
	"瀬戸内海": "NPS_setonaikaiLinkEnt.kml"
	"大山隠岐": "NPS_daisenLinkEnt.kml"
	"足摺宇和海": "NPS_ashizuriuwakaiLinkEnt.kml"
	"西海": "NPS_nishikaiLinkEnt.kml"
	"雲仙天草": "NPS_unzenamakusaLinkEnt.kml"
	"阿蘇くじゅう": "NPS_asokujuLinkEnt.kml"
	"霧島錦江湾": "NPS_kirishimakinkowanLinkEnt.kml"
	"屋久島": "NPS_yakushimaLinkEnt.kml"
	"西表石垣": "NPS_iriomoteishigakiLinkEnt.kml"
	"慶良間諸島": "NPS_fkeramashotouLinkEnt.kml"

# セレクトボックスの初期設定
selectbox = $('#select-np')
for key, value of NPs
	selectbox.append $("<option value='#{value}'>#{key}</option>")

moveToCurrentPosition map_canvas


# kmlの処理（加工とマップへの追加）
selectbox.change () ->
	unless kmlurl is ""
		kmlurl = base + $(this).val()
		kmlLayer = new google.maps.KmlLayer kmlurl
		kmlLayer.setMap map_canvas
