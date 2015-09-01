gulp       = require 'gulp'
connect    = require 'gulp-connect'
path       = require 'path'
compass    = require 'gulp-compass'
coffee     = require 'gulp-coffee'
plumber    = require 'gulp-plumber'
notify     = require 'gulp-notify'

base = './'

srcs =
  watching : [
    base + '*.html'
    base + 'sass/*.scss'
    base + 'coffee/*.coffee'
  ]
  uploading :　[
    base + '*.html'
    base + 'css/*.css'
    base + 'js/*.js'
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


gulp.task "reload", ["compass", "coffee"] , () ->
  gulp.src srcs["watching"]
    .pipe connect.reload()


gulp.task "default", ["compass","coffee","connect", "watch" ]



# ==========for dev==========




request = require 'request'
xml2js  = require('xml2js').parseString
fs      = require 'fs'
unzip   = require 'gulp-unzip'
geojson = require 'gulp-geojson'
rename  = require 'gulp-rename'

# list of NP
NPs = require './NPs.json'


gulp.task 'download', () ->

    getHttpBody = (url, callback) ->
        request.get url:url, (err, res, body) ->
            if !err and res?
                if res.statusCode is 200
                    callback body
                else
                    console.log "Err: statusCode#{res.statusCode}"
                    console.log "Request for \"#{url}\" failed."
            else
                console.log "Err: unknown error."
                console.log "Please check the internet connection."

    kmlToJson = (kml, callback) ->
        xml2js kml, (err, json) ->
            if !err then callback json

    # 環境省の提供するkmlのネットワークリンク構造に依存
    # this function depends on network-link structure of KMLs hosted by environmental ministry of Japan
    # 実態のあるデータへのurlを返す
    # it returns url to KML data Entity
    env_getKmzEntityLink = (json, callback) ->
        entityUrl = json.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
        callback entityUrl

    downloadBin = (binUrl, pathToFile, callback) ->
        readStream = request.get binUrl
        writeStream = fs.createWriteStream pathToFile
        readStream
            .pipe writeStream
            .on 'close', () ->
                callback pathToFile
            .on 'error', () ->
                console.log "streaming for #{pathToFile}"

    pushToGulpStream = (kmlEntUrl) ->
        getHttpBody kmlEntUrl, (kml) ->
            kmlToJson kml, (json) ->
                env_getKmzEntityLink json, (kmzUrl) ->
                    kmzPath = "./kml/#{path.basename kmzUrl}"
                    console.log "\"#{path.basename kmzUrl}\" has been downloaded."
                    downloadBin kmzUrl, kmzPath, (pathToKmz) ->
                        gulp.src kmzPath
                            .pipe unzip()
                            .pipe geojson()
                            .pipe rename (filepath) ->
                                console.log "\"#{path.basename kmzUrl}\" has been converted to geojson."
                                filepath.basename = path.basename kmzUrl, '.kmz'
                                filepath.extname = '.geojson'
                            .pipe gulp.dest base + 'geojson'

    for name, url of NPs.urllist
        pushToGulpStream NPs.base + url
