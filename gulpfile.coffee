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

# ==========for developing==========




# ==========data download==========

#request  = require 'request'

xml2js   = require('xml2js').parseString
#fs       = require 'fs'

intercept = require 'gulp-intercept'
#replace  = require 'gulp-replace'
#xeditor  = require 'gulp-xml-editor'
#xmlEdit = require 'gulp-edit-xml'
xml2json = require 'gulp-xml2json'
jeditor  = require 'gulp-json-editor'
download = require 'gulp-download'
unzip    = require 'gulp-unzip'
convert  = require 'gulp-convert'
geojson  = require 'gulp-geojson'
beautify = require 'gulp-jsbeautifier'
rename   = require 'gulp-rename'
#_        = require 'underscore'
# list of NP
NPs = require './NPs.json'


gulp.task 'download', () ->

    searchKmzUrl = (kml, callback) ->
        xml2js kml, (err, json) ->
            if !err
                entityUrl = json.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
                callback entityUrl


    pushToGulpStream = (kmlEntUrl) ->
        download kmlEntUrl
            .pipe rename extname:'.xml'
            .pipe xml2json()
            # this depends on network-link structure of KMLs hosted by environmental ministry of Japan
            .pipe jeditor (json) ->
                kmzUrl = json.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
            #.pipe intercept (file) ->
                #searchKmzUrl file.contents, (kmzUrl) ->
                basename = path.basename kmzUrl, '.kmz'
                download kmzUrl
                    .pipe unzip()
                    .pipe rename extname:'.xml'
                    .pipe xml2json()
                    # gulp-geojsonがdescription属性下のCDATAを吐き出してくれないので、
                    # 一旦gulp-xml2jsonで変換して実態参照を含んだjsonに変換
                    # このjsonから自分でパースしてもよい
                    .pipe rename extname:'.json'
                    .pipe convert {from:'json', to:'xml'}

                    .pipe rename extname:'.kml'
                    .pipe geojson()

                    .pipe rename extname:'.json'
                    .pipe beautify()

                    .pipe rename {basename:basename, extname:'.geojson'}
                    .pipe gulp.dest base + 'geojson'


    #for name, url of NPs.entries
    #    pushToGulpStream NPs.base + url
    pushToGulpStream NPs.base + NPs.entries['小笠原']
