'use strict'
describe 'test of services', () ->
    beforeEach module 'nationalpark-map'

#=========================================================================================
    describe 'test of urlParser service', () ->
        urlParserService = {}
        location = {}
        rootScope = {}
        beforeEach inject (_urlParser_, $location, $rootScope) ->
            urlParserService = _urlParser_
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
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
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
                mapPosition: urlParserService.getDefaultPosition()
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
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
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
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
                mapPosition: urlParserService.getDefaultPosition()
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x/y (lengh=2)
        #    x -> npid
        #    y -> () * rejected
        it 'urlParser interpet 2 elements as npid & default mapPosition', () ->
            elements = ['NPS_yyy', 'value to be ignored']
            serialExpected =
                npid: 'NPS_yyy'
                mapPosition: urlParserService.getDefaultPosition()
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        # x (legth=1)
        #   x -> npid
        it 'urlParser interpet 1 element as npid & default mapPosition', () ->
            elements = ['NPS_zzz']
            serialExpected =
                npid: 'NPS_zzz'
                mapPosition: urlParserService.getDefaultPosition()
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

        it 'urlParser interpet 0 elements as default mapPosition', () ->
            elements = []
            serialExpected =
                npid: ''
                mapPosition: urlParserService.getDefaultPosition()
            localPath = elements.join '/'
            location.path localPath
            rootScope.$apply() # reflect to angular life
            serialized = urlParserService.parse()
            # mapPosition serialization on rootScope success
            expect JSON.stringify serialized
                .toEqual JSON.stringify serialExpected

#=========================================================================================
    describe 'test of urlEncoder service', () ->
        urlEncoderService = {}
        location = {}
        rootScope = {}
        beforeEach inject (_urlEncoder_, $location, $rootScope) ->
            urlEncoderService = _urlEncoder_
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
            urlEncoderService.encode()
            expect location.path()
                .toEqual pathExpected

#=========================================================================================
    describe 'test of abstractLoader service', () ->
        abstractLoaderService ={}
        rootScope = {}
        beforeEach inject (_abstractLoader_, $rootScope) ->
            abstractLoaderService = _abstractLoader_
            rootScope = $rootScope

        it 'ajax request success', () ->
            abstractLoaderService.load()
            rootScope.$on 'abstractLoaded', () ->
                expect rootScope.abstract
                    .not.toBeDefined()

#=========================================================================================
    describe 'test of navCtrl controller', () ->
        urlParserService = {}
        $scope = {}
        rootScope = {}
        beforeEach inject (_urlParser_, _$controller_ , $rootScope) ->
            urlParserService = _urlParser_
            $controller = _$controller_
            rootScope = $rootScope
            navController = $controller 'navCtrl', {$scope: $scope}

        it 'onSelect method change rootScope.selected', () ->
            urlParserService.parse()
            rootScope.$on 'urlParsed', () ->
                $scope.onSelect 'NPS_dummy'
                expect($scope.selected).toEqual 'NPS_dummy'


    #it '必ず失敗させるおまじない', () -> expect(false).toEqual true
