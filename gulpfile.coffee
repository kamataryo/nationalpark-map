gulp       = require 'gulp'
connect    = require 'gulp-connect'
path       = require 'path'
compass    = require 'gulp-compass'
coffee     = require 'gulp-coffee'
plumber    = require 'gulp-plumber'
notify     = require 'gulp-notify'
sketch     = require 'gulp-sketch'

base = './'

srcs =
  watching : [
    base + '*.html'
    base + 'sass/*.scss'
    base + 'coffee/*.coffee'
    base + 'sketch/*.sketch'
  ]
  uploading :　[
    base + '*.html'
    base + 'css/*.css'
    base + 'js/*.js'
    base + 'img/*.svg'
  ]

host = 'localhost'
port = 8001



# create server
gulp.task "connect", () ->
  options =
    root: path.resolve base
    livereload: true
    port: port
    host: host
  connect.server options



gulp.task "watch", () ->
  gulp.watch srcs["watching"], ["compass", "coffee", "reload"]


gulp.task "compass", () ->
  options =
    config_file: base + 'config.rb'
    css: base + 'css/'
    sass: base + 'sass/'
    image: base + 'img/'

  gulp.src base + 'sass/*.scss'
    .pipe plumber(errorHandler: notify.onError '<%= error.message %>')
    .pipe compass options
    .pipe gulp.dest base + 'css/'


gulp.task "coffee", () ->
  gulp.src base + 'coffee/*.coffee'
    .pipe plumber(errorHandler: notify.onError '<%= error.message %>')
    .pipe coffee(bare: true).on 'error', (err) ->
      console.log err.stack
    .pipe gulp.dest base + 'js/'


gulp.task 'sketch', () ->
  gulp.src base + 'sketch/svg/*.sketch'
    .pipe sketch
      export: 'artboards'
      formats: 'svg'
    .pipe gulp.dest base + 'img/'

    gulp.src base + 'sketch/png/*.sketch'
      .pipe sketch
        export: 'artboards'
        formats: 'png'
      .pipe gulp.dest base + 'img/'


gulp.task "reload", ["compass", "coffee", "sketch"] , () ->
  gulp.src srcs["watching"]
    .pipe connect.reload()


gulp.task "default", ["compass","coffee","sketch","connect", "watch" ]

# ==========upper for developing==========




# ==========lower for data Initialization==========

request  = require 'request'

xml2js   = require('xml2js').parseString
fs       = require 'fs'
_ = require 'underscore'
xml2json = require 'gulp-xml2json'
jeditor  = require 'gulp-json-editor'
download = require 'gulp-download'
unzip    = require 'gulp-unzip'
convert  = require 'gulp-convert'
geojson  = require 'gulp-geojson'
beautify = require 'gulp-jsbeautifier'
rename   = require 'gulp-rename'
concat  = require 'gulp-concat-json'
intercept = require 'gulp-intercept'
exec = require 'gulp-exec'
# list of National Park
settingsUrl = './settings.json'
settings = require settingsUrl


#settings.jsonにエントリーポイントを記載した全ての国立公園kmlのURLから、
#gejsonを生成し、地種区分属性を付与する
gulp.task 'download', () ->
    for filename, npname of settings.entries
        url = settings.base + filename
        #url = 'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_ozeLinkEnt.kml'
        download url
            .pipe rename  extname:'.xml'
            .pipe xml2json()
            .pipe jeditor (json) ->
                kmzUrl = json.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
                basename = path.basename kmzUrl, '.kmz'
                download kmzUrl
                    .pipe unzip()
                    .pipe rename extname:'.xml'
                    .pipe xml2json()
                    # gulp-geojsonがdescription属性下のCDATAを吐き出してくれないので、
                    # 一旦gulp-xml2jsonで変換して実態参照を含んだjsonに変換
                    # このJSONから自分でパースしてもよいが
                    .pipe convert {from:'json', to:'xml'}
                    .pipe rename extname:'.kml'
                    .pipe geojson()
                    .pipe rename extname:'.json'
                    .pipe jeditor (json) ->
                        for feature, i in json.features
                            #地種属性を付与
                            description = feature.properties.description
                            for style in settings.styles
                                if description.match ///#{style.name}///
                                    feature.properties.grade = style.name
                                    break;
                                else
                                    feature.properties.grade = '地種不明'
                            json.features[i] = feature
                        return json
                    .pipe beautify()
                    .pipe rename {basename:basename, extname:'.geojson'}
                    .pipe gulp.dest base + '.geojson/'


#慶良間のgeojsonに国立公園名が入ってないので処理
gulp.task 'kerama', () ->
    gulp.src '.geojson/NPS_keramashotou.geojson'
        .pipe jeditor (json) ->
            for feature in json.features
                feature.properties.name = '慶良間諸島'
            return json
        .pipe gulp.dest '.geojson/'


#geojsonフォルダに入っている全ての国立公園geojsonファイルから、
#その分布範囲などを記載したabstractを生成する
gulp.task 'abstract_of_geo', () ->
    gulp.src base + '.geojson/*.geojson'
        .pipe intercept (file) ->
            identifier = path.basename file.path, '.geojson'
            json = JSON.parse file.contents,toString()
            latitudes = []
            longitudes = []
            name = json.features[0].properties.name
            for feature in json.features
                if feature.geometry.coordinates?
                    for coordinate in feature.geometry.coordinates[0]
                        latitudes.push coordinate[0]
                        longitudes.push coordinate[1]

            information = {}
            information[identifier] =
                name: name
                top: _.max longitudes
                right: _.max latitudes
                bottom: _.min longitudes
                left: _.min latitudes

            file.contents = new Buffer JSON.stringify information
            return file
        .pipe concat 'abstract.ofGeo.json'
        .pipe jeditor (json) ->
            #flattenする
            result = {}
            for obj in json
                key = _.keys(obj)[0]
                result[key] = obj[key]
            return result
        .pipe beautify()
        .pipe gulp.dest base + '.geojson/'


#topojsonに変換
gulp.task 'topojson_export', () ->
    gulp.src '.geojson/*.geojson'
        .pipe exec 'topojson -p name -p grade -p description -o <%= file.path %>.topojson <%= file.path %>'
        .pipe exec.reporter stdout:true

#topojsonの名前を変える
gulp.task 'topojson_rename', () ->
    gulp.src '.geojson/*.geojson.topojson'
        .pipe rename extname:'.json'
        .pipe beautify()
        .pipe rename extname: '' # trim .topojson
        .pipe rename extname: '' # trim .geojson
        .pipe rename extname: '.topojson'
        .pipe gulp.dest 'topojson/'


#topogeojsonフォルダに入っている全ての国立公園topojsonファイルから、
#そのサイズを記載したabstractを生成する
gulp.task 'abstract_of_topo', () ->
    gulp.src base + 'topojson/*.topojson'
        .pipe intercept (file) ->
            identifier = path.basename file.path, '.topojson'
            size = Math.round( file.contents.length / 1024 )
            if size > 1000
                size = Math.round(10 * size / 1024) / 10
                unit = 'MB'
            else
                unit = 'kB'
            information = {}
            information[identifier] =
                size: size
                unit: unit
            file.contents = new Buffer JSON.stringify information
            return file
        .pipe concat 'abstract.ofTopo.json'
        .pipe jeditor (json) ->
            #flattenする
            result = {}
            for obj in json
                key = _.keys(obj)[0]
                result[key] = obj[key]
            return result
        .pipe beautify()
        .pipe gulp.dest base + '.geojson/'

#最後に結合
gulp.task 'abstract_concat', () ->
    gulp.src base + '.geojson/abstract.*.json'
        .pipe concat 'abstract.json'
        .pipe beautify()
        .pipe jeditor (json) ->
            for key, value of json[0]
                json[0][key]['size'] = json[1][key]['size']
                json[0][key]['unit'] = json[1][key]['unit']
            return json[0]
        .pipe gulp.dest base + 'topojson/'
