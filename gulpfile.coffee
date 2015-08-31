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
    root: path.resolve(base)
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



http = require 'http'
request = require 'request'
kmlEntUrl = 'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_rishirirebunLinkEnt.kml'
xml2js = require('xml2js').parseString

geojson = require 'gulp-geojson'
rename = require 'gulp-rename'


# httpでリンクエントリーのkmlをhttp get
# レスポンスを、xml2jsモジュールでjsonに変換
# リンクされているkmzのURLを探す
# kmzのURLから、ファイルをダウンロード
# kmzをUnzip
# 解凍が成功したらkmzを削除
# 得られたkmlを全てgulp-geojsonで.geojsonに変換
# 不要な部分を削除
# opacity調整
gulp.task 'downloadKML', () ->

    # bodyを引数にcallbackされる
    # エラーの時はされない
    getHttpBody = (url, callback) ->
        result = ''
        opts = url: url
        request.get opts, (err, res, body) ->
            if !err and res.statusCode is 200
                console.log 'http get OK for ' + url
                callback.bind body
            else
                result = err: res.statusCode
            return result
        # console.log result

    getHttpBody kmlEntUrl, (body) ->
        console.log body

    # getHttpBody = (url) ->
    #     http.get url, (res) ->
    #         body = ''
    #         res.setEncoding 'utf8'
    #         res.on 'data', (chunk) ->
    #             body += chunk
    #         res.on 'end', (res) ->
    #             return body
    # console.log getHttpBody(kmlEntUrl)

    parseKml = (kml) ->
        xml2js kml, (err, result) ->
            return result


    # kmlbody = getHttpBody url



    # http.get url, (res1) ->
    #     body1 = ''
    #     res1.setEncoding 'utf8'
    #     res1.on 'data', (chunk) ->
    #         body1 += chunk
    #     res1.on 'end', (res1) ->
    #         xml2js body1, (err, result) ->
    #             entityUrl = result.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
    #             http.get entityUrl, (res2) ->
    #                 body2 = ''
    #                 res2.on 'data', (chunk) ->
    #                     body2 += chunk
    #                 res2.on 'end'



gulp.task 'geojson', () ->
    gulp.src base + 'kml/*.kml'
        .pipe geojson()
        .pipe rename extname: '.geojson'
        .pipe gulp.dest base + 'geojson'
