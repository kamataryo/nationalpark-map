# Online National Park Map-国立公園オンラインマップ

[![Build Status Images](https://travis-ci.org/KamataRyo/nationalpark-map.svg)](https://travis-ci.org/KamataRyo/nationalpark-map)
[![codecov.io](https://codecov.io/github/KamataRyo/nationalpark-map/coverage.svg?branch=master)](https://codecov.io/github/KamataRyo/nationalpark-map?branch=master)

## Abstract-概要

National park map in Japan (restriction area)

日本の国立公園（規制区域）の区域図です。

## How does it work?-どんなものか？

![screen shot](screenshot.png)

The developmental restricted areas are overlaid on Google Maps.

開発規制区域がGoogle Maps上に表示されます。

## Goal of this service

- Provide a platform to share geolocational information of Japanese National Park.

## Goal of development

- Auto-transformation of national from official KML to TopoJSON with gulp.
- (done) Overlay national park poligon on Webmap service.
- Support geolocation.
- Test of 100% coverage.


## License-ライセンス
MIT. see [LICENSE.md](LICENSE.md)

## Attention-注意事項
TopoJSONs are under another License.

TopoJSONファイルは他のライセンス下にあると考えています。

See [topojson/LICENSE.md](topojson/LICENSE.md).
