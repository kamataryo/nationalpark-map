'use strict'
describe 'test of services', () ->
    urlParserService = {}
    location = {}
    rootScope = {}

    beforeEach module 'nationalpark-map'

    beforeEach inject (_urlParser_, $location, $rootScope) ->
        urlParserService = _urlParser_
        location = $location
        rootScope = $rootScope
    it 'url parse success in case of fullmatch', () ->
        npid = 'NPS_xxx'
        zoom = 8
        lat = 34.54
        lng = 123.2
        localPath = "#{npid}/#{zoom}/#{lat}/#{lng}" # test case
        location.path localPath
        rootScope.$apply() # reflect to angular life cycle
        urlParserService.parse()

        # location change success
        expect location.absUrl()
            .toEqual "http://server/#/#{localPath}"
        # serialize of map position to rootScope success
        expect JSON.stringify rootScope.serial
            .toEqual JSON.stringify {
                npid: npid
                mapPosition:
                    zoom: zoom
                    latitude: lat
                    longitude: lng
            }
