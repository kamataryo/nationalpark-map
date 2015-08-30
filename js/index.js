var $map, NPs, base, currentPositionMarker, googlemapCanvas, initialPosition, key, kmlOverlayed, moveToCurrentButton, moveToCurrentPosition, myOptions, selectbox, timerId, traceConditionIcon, traceCurrentButton, value,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

googlemapCanvas = null;

currentPositionMarker = null;

timerId = 0;

base = "http://www.biodic.go.jp/trialSystem/LinkEnt/nps/";

NPs = {
  "利尻礼文サロベツ": "NPS_rishirirebunLinkEnt.kml",
  "知床": "NPS_shiretokoLinkEnt.kml",
  "阿寒": "NPS_akanLinkEnt.kml",
  "釧路湿原": "NPS_kushiroLinkEnt.kml",
  "大雪山": "NPS_daisetsuzanLinkEnt.kml",
  "支笏洞爺": "NPS_shikotsutouyaLinkEnt.kml",
  "十和田八幡平": "NPS_towadahatimantaiLinkEnt.kml",
  "三陸復興": "NPS_sanrikufukkouLinkEnt.kml",
  "磐梯朝日": "NPS_bandaiasahiLinkEnt.kml",
  "日光": "NPS_nikkouLinkEnt.kml",
  "尾瀬": "NPS_ozeLinkEnt.kml",
  "秩父多摩甲斐": "NPS_chichibutamaLinkEnt.kml",
  "小笠原": "NPS_ogasawaraLinkEnt.kml",
  "富士箱根伊豆": "NPS_fujihakoneizuLinkEnt.kml",
  "南アルプス": "NPS_southalpsLinkEnt.kml",
  "上信越高原": "NPS_joshinetsuLinkEnt.kml",
  "中部山岳": "NPS_chubusangakuLinkEnt.kml",
  "白山": "NPS_hakusanLinkEnt.kml",
  "伊勢志摩": "NPS_iseshimaLinkEnt.kml",
  "吉野熊野": "NPS_yoshinokumanoLinkEnt.kml",
  "山陰海岸": "NPS_saninkaiganLinkEnt.kml",
  "瀬戸内海": "NPS_setonaikaiLinkEnt.kml",
  "大山隠岐": "NPS_daisenLinkEnt.kml",
  "足摺宇和海": "NPS_ashizuriuwakaiLinkEnt.kml",
  "西海": "NPS_nishikaiLinkEnt.kml",
  "雲仙天草": "NPS_unzenamakusaLinkEnt.kml",
  "阿蘇くじゅう": "NPS_asokujuLinkEnt.kml",
  "霧島錦江湾": "NPS_kirishimakinkowanLinkEnt.kml",
  "屋久島": "NPS_yakushimaLinkEnt.kml",
  "西表石垣": "NPS_iriomoteishigakiLinkEnt.kml",
  "慶良間諸島": "NPS_fkeramashotouLinkEnt.kml"
};

kmlOverlayed = [""];

$map = $('#map');

initialPosition = new google.maps.LatLng(35.127152, 138.910627);

myOptions = {
  noClear: true,
  center: initialPosition,
  zoom: 16,
  mapTypeId: google.maps.MapTypeId.ROADMAP
};

googlemapCanvas = new google.maps.Map($map[0], myOptions);

moveToCurrentPosition = function() {
  var opts;
  if (navigator.geolocation) {
    opts = {
      enableHighAcuracy: true,
      timeout: 3000,
      maximumAge: 200
    };
    return navigator.geolocation.getCurrentPosition(function(position) {
      var currentPosition, newLatLng;
      currentPosition = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      if (currentPositionMarker === null) {
        currentPositionMarker = new google.maps.Marker({
          position: currentPosition,
          map: googlemapCanvas
        });
      } else {
        currentPositionMarker.setPosition(currentPosition);
      }
      newLatLng = currentPosition;
      return sgooglemapCanvas.panTo(newLatLng);
    }, function() {
      return false;
    }, opts);
  } else {
    return false;
  }
};

selectbox = $('#select-np');

for (key in NPs) {
  value = NPs[key];
  selectbox.append($("<option value='" + value + "'>" + key + "</option>"));
}

selectbox.change(function() {
  var filename, kmlLayer, urlTokml;
  filename = $(this).val();
  if (indexOf.call(kmlOverlayed, filename) < 0) {
    urlTokml = base + filename;
    kmlOverlayed.push(filename);
    kmlLayer = new google.maps.KmlLayer(urlTokml);
    return kmlLayer.setMap(map_canvas);
  }
});

moveToCurrentButton = $('#move-to-current');

moveToCurrentButton.click(function() {
  return moveToCurrentPosition();
});

traceCurrentButton = $('#trace-current');

traceConditionIcon = $('#trace-condition');

traceCurrentButton.click(function() {
  var updateCurrentPosition;
  updateCurrentPosition = function() {
    return timerId = setTimeout(function() {
      moveToCurrentPosition();
      return updateCurrentPosition();
    });
  };
  if ($(this).hasClass('on')) {
    clearTimeout(timerId);
    $(this).removeClass('on');
    traceConditionIcon.removeClass('fa-pause');
    return traceConditionIcon.addClass('fa-play');
  } else {
    $(this).addClass('on');
    traceConditionIcon.removeClass('fa-play');
    traceConditionIcon.addClass('fa-pause');
    return updateCurrentPosition();
  }
});
