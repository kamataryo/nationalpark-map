'use strict'
describe 'test of services', () ->
    app = module 'nationalpark-map'
    beforeEach app

#=========================================================================================
#=========================================================================================
    describe 'test of urlParser service', () ->
        urlParseService = {}
        location = {}
        rootScope = {}
        beforeEach inject (_urlParser_, $location, $rootScope) ->
            urlParseService = _urlParser_
            location = $location
            rootScope = $rootScope

        # x/y/z/w/u/..(length>3)
        #    x -> npid
        #    y -> zoom
        #    z -> latitude
        #    w -> longitude
        #    u -> () *rejected
        it 'urlParser interpet >3 elements as npid & mapPosition', () ->
            elements = ['NPS_xxx',12, 34.5, 67.8]
            serialExpected =
                npid: 'NPS_xxx'
                mapPosition:
                    zoom:12
                    latitude: 34.5
                    longitude: 67.8
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x/y/z/w/u/..(length>3)
        #    x -> npid
        #    y -> (zoom) *rejected
        #    z -> (latitude) *rejected
        #    w -> (longitude) *rejected
        it 'urlParser interpet >3 elements including invalid value(s) as npid & default mapPosition', () ->
            elements = ['NPS_uuu',6, 'contaminatedInvalidValue', 17.5]
            serialExpected =
                npid: 'NPS_uuu'
                mapPosition: urlParseService.getDefaultPosition()
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x/y/z (length=3)
        #    x -> zoom
        #    y -> latitude
        #    z -> longitude
        it 'urlParser interpet 3 elements as mapPosition', () ->
            elements = [12, 34.5, 67.8]
            serialExpected =
                npid: ''
                mapPosition:
                    zoom:12
                    latitude: 34.5
                    longitude: 67.8
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x/y/z (length=3)
        #    y -> (zoom) *rejected
        #    z -> (latitude) *rejected
        #    w -> (longitude) *rejected
        it 'urlParser interpet 3 elements including invalid value(s) as default mapPosition', () ->
            elements = [17, 14.5, "invalidvalue"]
            serialExpected =
                npid: ''
                mapPosition: urlParseService.getDefaultPosition()
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x/y (lengh=2)
        #    x -> npid
        #    y -> () * rejected
        it 'urlParser interpet 2 elements as npid & default mapPosition', () ->
            elements = ['NPS_yyy', 'value to be ignored']
            serialExpected =
                npid: 'NPS_yyy'
                mapPosition: urlParseService.getDefaultPosition()
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x (legth=1)
        #   x -> npid
        it 'urlParser interpet 1 element as npid & default mapPosition', () ->
            elements = ['NPS_zzz']
            serialExpected =
                npid: 'NPS_zzz'
                mapPosition: urlParseService.getDefaultPosition()
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        it 'urlParser interpet 0 elements as default mapPosition', () ->
            elements = []
            serialExpected =
                npid: ''
                mapPosition: urlParseService.getDefaultPosition()
                pin: ''
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected


        it 'query strings detection success', () ->
            elements = []
            serialExpected =
                npid: ''
                mapPosition: urlParseService.getDefaultPosition()
                pin: '12,34'
            localPath = elements.join '/'
            location.search pin:'12,34'
            serialized = urlParseService.parse()# mapPosition serialization on rootScope
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected


#=========================================================================================
    describe 'test of urlEncoder service', () ->
        urlEncodeService = {}
        location = {}
        rootScope = {}
        beforeEach inject (_urlEncoder_, $location, $rootScope) ->
            urlEncodeService = _urlEncoder_
            location = $location
            rootScope = $rootScope

        it 'URL encode with npid & mapPosition', () ->
            #provide pseudo inner Page Information to rootScope
            rootScope.serial =
                npid: 'NPS_pseudo'
                mapPosition:
                    zoom: 2
                    latitude: 23.45
                    longitude: 67.89
            pathExpected = '/NPS_pseudo/2/23.45/67.89'
            urlEncodeService.encode()
            expect location.path()
                .toEqual pathExpected

#=========================================================================================
    describe 'test of abstractLoader service', () ->
        abstractLoadService ={}
        rootScope = {}
        beforeEach inject (_abstractLoader_, $rootScope) ->
            abstractLoadService = _abstractLoader_
            rootScope = $rootScope

        it 'ajax abstract request success', () ->
            abstractLoadService.load()
            rootScope.$on 'abstractLoaded', () ->
                expect rootScope.abstract
                    .not.toBeDefined()

#=========================================================================================
    describe 'failure case: test of topojsonLoader service', () ->
        topojsonLoadService = {}
        rootScope = {}
        beforeEach inject (_topojsonLoader_, $rootScope) ->
            topojsonLoadService = _topojsonLoader_
            rootScope = $rootScope

        it 'ajax topojson request failes without np selection', () ->
                result = topojsonLoadService.load()
                expect(result).toEqual false

    describe 'success case: test of topojsonLoader service', () ->
        topojsonLoadService = {}
        rootScope = {}
        beforeEach inject (_topojsonLoader_, $rootScope) ->
            topojsonLoadService = _topojsonLoader_
            rootScope = $rootScope
            rootScope.serial = npid:'NPS_rishirirebun'

        it 'ajax topojson request success with np selection', () ->
            result = topojsonLoadService.load()
            rootScope.$on 'topojsonLoaded', () ->
                expect rootScope.geojson
                    .not.toBeDefined()

#=========================================================================================
    describe 'test of navCtrl controller', () ->
        urlParseService = {}
        $scope = {}
        rootScope = {}
        beforeEach inject (_urlParser_, _$controller_ , $rootScope) ->
            urlParseService = _urlParser_
            $controller = _$controller_
            rootScope = $rootScope
            navController = $controller 'navCtrl', {$scope: $scope}

        it 'method onSelect change rootScope.selected', () ->
            urlParseService.parse()
            rootScope.$on 'urlParsed', () ->
                $scope.onSelect 'NPS_dummy'
                expect($scope.selected).toEqual 'NPS_dummy'

    #it '必ず失敗させるおまじない', () -> expect(false).toEqual true
