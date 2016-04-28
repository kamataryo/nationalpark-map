(function() {
  'use strict';
  var app;

  app = angular.module('nationalpark-map', ['ngMap', 'ngMdIcons', 'ngTouch']);

  app.service('urlParser', [
    '$location', '$rootScope', function($location, $rootScope) {
      var defaultPosition;
      defaultPosition = {
        zoom: 10,
        latitude: 35.680795,
        longitude: 139.76721
      };
      return {
        getDefaultPosition: function() {
          return defaultPosition;
        },
        parse: function() {
          var _latitude, _longitude, _zoom, elements, latitude, longitude, npid, pin, queries, zoom;
          elements = $location.path().split('/').filter(function(e) {
            return e !== '';
          });
          queries = $location.search();
          npid = '';
          zoom = defaultPosition.zoom;
          latitude = defaultPosition.latitude;
          longitude = defaultPosition.longitude;
          pin = '';
          if (elements.length > 3) {
            npid = elements[0];
            _zoom = parseInt(elements[1], 10);
            _latitude = parseFloat(elements[2]);
            _longitude = parseFloat(elements[3]);
          } else if (elements.length === 3) {
            _zoom = parseInt(elements[0], 10);
            _latitude = parseFloat(elements[1]);
            _longitude = parseFloat(elements[2]);
          } else if (elements.length === 2) {
            npid = elements[0];
          } else if (elements.length === 1) {
            npid = elements[0];
          }
          if (!(isNaN(_zoom) || isNaN(_latitude) || isNaN(_longitude))) {
            zoom = Math.min(_zoom, 18);
            latitude = _latitude;
            longitude = _longitude;
          }
          pin = queries.pin != null ? queries.pin : '';
          return $rootScope.serial = {
            npid: npid,
            mapPosition: {
              zoom: zoom,
              latitude: latitude,
              longitude: longitude
            },
            pin: pin
          };
        }
      };
    }
  ]);

  app.service('urlEncoder', [
    '$location', '$rootScope', function($location, $rootScope) {
      return {
        encode: function() {
          var path;
          path = [$rootScope.serial.npid, $rootScope.serial.mapPosition.zoom, $rootScope.serial.mapPosition.latitude, $rootScope.serial.mapPosition.longitude].join('/');
          $location.path(path);
          if ($rootScope.serial.pin === '') {
            return $location.search({
              pin: null
            });
          } else {
            return $location.search({
              pin: $rootScope.serial.pin
            });
          }
        }
      };
    }
  ]);

  app.service('abstractLoader', [
    '$http', '$rootScope', function($http, $rootScope) {
      var query;
      query = {
        url: './topojson/abstract.json',
        method: 'GET'
      };
      return {
        load: function() {
          return $http(query).success(function(data) {
            $rootScope.abstract = data;
            return $rootScope.$emit('abstractLoaded');
          });
        }
      };
    }
  ]);

  app.service('topojsonLoader', [
    '$http', '$rootScope', function($http, $rootScope) {
      return {
        load: function() {
          var query;
          if (!$rootScope.serial) {
            return false;
          }
          if (!$rootScope.serial.npid) {
            return false;
          }
          query = {
            url: "./topojson/" + $rootScope.serial.npid + ".topojson",
            method: 'GET'
          };
          return $http(query).success(function(json) {
            return $rootScope.geojson = topojson.feature(json, json.objects[$rootScope.serial.npid]);
          });
        }
      };
    }
  ]);

  app.service('mapFocuser', [
    'NgMap', function(NgMap) {
      return {
        focus: function(lat, lng) {
          return NgMap.getMap().then(function(map) {
            return map.panTo(new google.maps.LatLng(lat, lng));
          });
        }
      };
    }
  ]);

  app.service('geoLocator', [
    '$rootScope', 'NgMap', function($rootScope, NgMap) {
      var geolocatorOptions, watchState;
      geolocatorOptions = {
        enableHighAccuracy: true,
        timeout: 8000,
        maximumAge: 1000
      };
      watchState = {
        id: null,
        count: 0,
        lastUpdated: 0,
        map: null,
        marker: null
      };
      return {
        start: function(tracking) {
          if (navigator.geolocation) {
            return watchState.id = navigator.geolocation.watchPosition(function(pos) {
              var now;
              watchState.count++;
              now = Math.floor(new Date() / 1000);
              if (watchState.lastUpdated + 3 > now) {
                return false;
              } else if ($rootScope.dragging) {
                return false;
              } else {
                watchState.lastUpdate = now;
                $rootScope.current = pos.coords.latitude + ',' + pos.coords.longitude;
                $rootScope.$emit('currentMoved');
                if (tracking === true) {
                  return NgMap.getMap().then(function(map) {
                    return map.panTo(new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude));
                  });
                }
              }
            }, function(error) {
              var msg;
              msg = {
                0: 'unknown error',
                1: 'access permission denied',
                2: 'due to device or environment',
                3: 'timeout'
              };
              console.log("error " + error.code + ":" + msg[error.code]);
              if (error.code === 1) {
                return $rootScope.$emit('geolocationFailed');
              }
            }, geolocatorOptions);
          } else {
            console.log('your device donot offer geolocation.');
            return $rootScope.$emit('geolocationFailed');
          }
        },
        stop: function() {
          if (navigator.geolocation) {
            navigator.geolocation.clearWatch(watchState.id);
            return $rootScope.$emit('geolocationStopped');
          }
        }
      };
    }
  ]);

  app.controller('mainCtrl', [
    '$scope', '$rootScope', 'urlParser', 'abstractLoader', 'geoLocator', function($scope, $rootScope, urlParser, abstractLoader, geoLocator) {
      $rootScope.fillStyles = {
        '特別保護地区': '#dddd66',
        '海域公園地区': '#2233dd',
        '海中公園地区': '#2233dd',
        '第1種特別地域': '#dd66dd',
        '第2種特別地域': '#dd6666',
        '第3種特別地域': '#66dd66',
        '特別地域': '#343265',
        '普通地域': '#66dddd',
        'else': '#666666'
      };
      $scope.fiiStyles = $rootScope.fillStyles;
      urlParser.parse();
      abstractLoader.load();
      $scope.navOpen = true;
      $scope.toggleNav = function() {
        return $scope.navOpen = !$scope.navOpen;
      };
      $scope.locatingButtonIcon = 'gps_fixed';
      $scope.toggleLocator = function() {
        if ($scope.locatingButtonIcon === 'gps_fixed') {
          geoLocator.start(true);
          return $scope.locatingButtonIcon = 'gps_off';
        } else {
          $scope.locatingButtonIcon = 'gps_fixed';
          return geoLocator.stop();
        }
      };
      $scope.$on('geolocationFailed', function() {
        return $rootScope.locatingButtonIcon = 'gps_fixed';
      });
      $scope.pinButtonIcon = $rootScope.serial.pin === '' ? 'location_on' : 'location_off';
      $scope.togglePin = function() {
        if ($scope.pinButtonIcon === 'location_on') {
          $scope.$broadcast('force:pinSet');
          return $scope.pinButtonIcon = 'location_off';
        } else {
          $scope.$broadcast('force:pinRemove');
          return $scope.pinButtonIcon = 'location_on';
        }
      };
      $scope.$on('pinSet', function() {
        return $scope.pinButtonIcon = 'location_off';
      });
      return $scope.$on('pinRemove', function() {
        return $scope.pinButtonIcon = 'location_on';
      });
    }
  ]);

  app.controller('navCtrl', [
    '$scope', '$rootScope', 'topojsonLoader', 'urlEncoder', 'mapFocuser', function($scope, $rootScope, topolsonLoader, urlEncoder, mapFocuser) {
      var getStyleId, reflectStyles;
      $rootScope.$on('abstractLoaded', function() {
        $scope.npAbstract = $rootScope.abstract;
        if ($rootScope.serial) {
          return $scope.onSelect($rootScope.serial.npid, false);
        }
      });
      $scope.description = '国立公園の区域を閲覧し、位置情報を共有するためのサービスです。';
      $scope.keywords = '国立公園,地図,マップ,規制,区域';
      $scope.ogurl = "http://kamataryo.github.io/nationalpark-map/";
      $scope.onSelect = function(npid, focus) {
        var bottom, left, right, top;
        if ($scope.selected) {
          if (npid === $scope.selected) {
            return;
          }
        }
        $scope.selected = npid;
        $rootScope.serial.npid = npid;
        $scope.description = $scope.npAbstract[npid].name + '国立公園の区域を閲覧し、位置情報を共有するためのサービスです。';
        $scope.keywords = $scope.npAbstract[npid].name + '国立公園,地図,マップ,規制,区域';
        $scope.ogurl = "http://kamataryo.github.io/nationalpark-map/\#/" + npid;
        if (focus) {
          top = $scope.npAbstract[npid].top;
          bottom = $scope.npAbstract[npid].bottom;
          left = $scope.npAbstract[npid].left;
          right = $scope.npAbstract[npid].right;
          mapFocuser.focus((top + bottom) / 2, (right + left) / 2);
        }
        topolsonLoader.load();
        return urlEncoder.encode();
      };
      reflectStyles = function() {
        $rootScope.lineColor = $scope.lineColor;
        $rootScope.lineWidth = $scope.lineWidth;
        return $rootScope.opacity = $scope.opacity;
      };
      getStyleId = function() {
        return '' + $scope.lineColor + $scope.lineWidth + $scope.opacity;
      };
      $scope.getRGBA = function(color, a) {
        return "rgba(" + color + "," + a;
      };
      reflectStyles();
      return $rootScope.$watch(getStyleId, reflectStyles);
    }
  ]);

  app.controller('mapCtrl', [
    '$scope', '$rootScope', 'NgMap', 'urlEncoder', function($scope, $rootScope, NgMap, urlEncoder) {
      $scope.zoom = $rootScope.serial.mapPosition.zoom;
      $scope.latlng = $rootScope.serial.mapPosition.latitude + ',' + $rootScope.serial.mapPosition.longitude;
      $scope.pin = '100000,100000';
      $scope.current = '100000,100000';
      return NgMap.getMap().then(function(map) {
        var i, len, ref, results, style;
        $scope.mapStyler = function(feature) {
          var grade;
          grade = feature.getProperty('grade');
          return {
            strokeColor: $rootScope.lineColor,
            strokeWeight: $rootScope.lineWidth,
            fillOpacity: $rootScope.opacity,
            fillColor: grade != null ? $rootScope.fillStyles[grade] : $scope.styles['else']
          };
        };
        if ($rootScope.serial.pin !== '') {
          $scope.pin = $rootScope.serial.pin;
        }
        $scope.$on('force:pinSet', function() {
          $scope.pin = $rootScope.serial.mapPosition.latitude + ',' + $rootScope.serial.mapPosition.longitude;
          $rootScope.serial.pin = $scope.pin;
          return urlEncoder.encode();
        });
        $scope.$on('force:pinRemove', function() {
          $scope.pin = '1000000,1000000';
          $rootScope.serial.pin = '';
          return urlEncoder.encode();
        });
        $scope.pinSetCallback = function(event) {
          $scope.pin = [event.latLng.lat(), event.latLng.lng()].join(',');
          $rootScope.serial.pin = $scope.pin;
          urlEncoder.encode();
          $scope.$emit('pinSet');
          return $scope.$apply();
        };
        $scope.addData = function() {
          map.data.forEach(function(feature) {
            return map.data.remove(feature);
          });
          map.data.addGeoJson($rootScope.geojson);
          map.data.setStyle($scope.mapStyler);
          return map.data.addListener('click', $scope.pinSetCallback);
        };
        $rootScope.$watch(function() {
          return $rootScope.geojson;
        }, $scope.addData);
        map.addListener('click', $scope.pinSetCallback);
        map.addListener('idle', function() {
          $rootScope.serial.mapPosition = {
            zoom: map.getZoom(),
            latitude: map.getCenter().lat(),
            longitude: map.getCenter().lng()
          };
          urlEncoder.encode();
          return $rootScope.$apply();
        });
        map.addListener('dragstart', function() {
          return $rootScope.dragging = true;
        });
        map.addListener('dragend', function() {
          return $rootScope.dragging = false;
        });
        $rootScope.$on('currentMoved', function() {
          return $scope.current = $rootScope.current;
        });
        $rootScope.$on('geolocationStopped', function() {
          return $scope.current = '100000,100000';
        });
        ref = ['opacity', 'lineColor', 'lineWidth'];
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          style = ref[i];
          results.push($rootScope.$watch(style, function() {
            return map.data.setStyle($scope.mapStyler);
          }));
        }
        return results;
      });
    }
  ]);

}).call(this);
