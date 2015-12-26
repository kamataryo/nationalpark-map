gulp    = require 'gulp'
connect = require 'gulp-connect'
path    = require 'path'
compass = require 'gulp-compass'
coffee  = require 'gulp-coffee'
rename  = require 'gulp-rename'
plumber = require 'gulp-plumber'
sketch  = require 'gulp-sketch'
KarmaServer  = require('karma').Server;



base = './'
srcs =
  watching : [
    base + '*.html'
    base + 'sass/*.scss'
    base + 'coffee/**/*.coffee'
    base + 'sketch/**/*.sketch'
  ]
  uploading :　[
    base + '*.html'
    base + 'css/*.css'
    base + 'js/*.js'
    base + 'img/*.svg'
  ]
host = 'localhost'
port = 8001


gulp.task 'compass', () ->
  options =
    config_file: base + 'config.rb'
    css: base + 'css/'
    sass: base + 'sass/'
    image: base + 'img/'

  gulp.src base + 'sass/*.scss'
    .pipe plumber()
    .pipe compass options
    .on 'error', (err) ->
        console.log err
    .pipe gulp.dest base + 'css/'


gulp.task 'coffee', () ->
  gulp.src [base + 'coffee/**/*.coffee', '!' + base + 'coffee/spec/karma.conf.coffee']
    .pipe plumber()
    .pipe coffee(bare: false)
    .on 'error', (err) ->
        console.log err.stack
    .pipe gulp.dest base + 'js/'

gulp.task 'sketch', () ->
  gulp.src base + 'sketch/svg/*.sketch'
    .pipe sketch
      export: 'artboards'
      formats: 'svg'
    .pipe gulp.dest base + 'img/'


# !!!!use karma directory!!!!
gulp.task 'karma',['coffee'], (done) ->
    # files = [
    #     './js/lib/angular/angular.js'
    #     './js/lib/angular-mocks/angular-mocks.js'
    #     './js/lib/ngmap/build/scripts/ng-map.js'
    #     './js/*.js'
    #     './js/spec/*.js'
    # ]
    new KarmaServer {
        configFile: __dirname + '/coffee/spec/karma.conf.coffee'
        singleRun: true
    }, done
        .start()

# create server
gulp.task 'connect', () ->
  options =
    root: path.resolve base
    livereload: true
    port: port
    host: host
  connect.server options

gulp.task 'reload', ['compass', 'coffee'] , () ->
  gulp.src srcs['watching']
    .pipe connect.reload()

gulp.task 'watch', () ->
  gulp.watch srcs['watching'], ['compass', 'coffee','karma', 'reload']


gulp.task 'default', ['coffee','compass' ] # exclude sketch
gulp.task 'dev', ['sketch', 'compass','coffee','karma','connect', 'watch' ]



# ==========upper for developing==========




# ==========lower for data Initialization==========

download  = require 'gulp-download'
xml2json  = require 'gulp-xml2json'
jeditor   = require 'gulp-json-editor'
unzip     = require 'gulp-unzip'
convert   = require 'gulp-convert'
geojson   = require 'gulp-geojson'
gulpif    = require 'gulp-if'
exec      = require 'gulp-exec'
beautify  = require 'gulp-jsbeautifier'

intercept = require 'gulp-intercept'
_ = require 'underscore'
concat  = require 'gulp-concat-json'

# list of National Park
entries =
  '利尻礼文サロベツ':'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_rishirirebunLinkEnt.kml',
  '知床'          :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_shiretokoLinkEnt.kml',
  '阿寒'          :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_akanLinkEnt.kml',
  '釧路湿原'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_kushiroLinkEnt.kml',
  '大雪山'        :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_daisetsuzanLinkEnt.kml',
  '支笏洞爺'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_shikotsutouyaLinkEnt.kml',
  '十和田八幡平'    :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_towadahatimantaiLinkEnt.kml',
  '三陸復興'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_sanrikufukkouLinkEnt.kml',
  '磐梯朝日'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_bandaiasahiLinkEnt.kml',
  '日光'          :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_nikkouLinkEnt.kml',
  '尾瀬'          :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_ozeLinkEnt.kml',
  '秩父多摩甲斐'   :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_chichibutamaLinkEnt.kml',
  '小笠原'        :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_ogasawaraLinkEnt.kml',
  '富士箱根伊豆'   :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_fujihakoneizuLinkEnt.kml',
  '南アルプス'     :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_southalpsLinkEnt.kml',
  '上信越高原'     :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_joshinetsuLinkEnt.kml',
  '中部山岳'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_chubusangakuLinkEnt.kml',
  '白山'          :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_hakusanLinkEnt.kml',
  '伊勢志摩'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_iseshimaLinkEnt.kml',
  '吉野熊野'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_yoshinokumanoLinkEnt.kml',
  '山陰海岸'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_saninkaiganLinkEnt.kml',
  '瀬戸内海'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_setonaikaiLinkEnt.kml',
  '大山隠岐'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_daisenLinkEnt.kml',
  '足摺宇和海'    :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_ashizuriuwakaiLinkEnt.kml',
  '西海'         :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_nishikaiLinkEnt.kml',
  '雲仙天草'      :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_unzenamakusaLinkEnt.kml',
  '阿蘇くじゅう'   :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_asokujuLinkEnt.kml',
  '霧島錦江湾'    :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_kirishimakinkowanLinkEnt.kml',
  '屋久島'       :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_yakushimaLinkEnt.kml',
  '西表石垣'     :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_iriomoteishigakiLinkEnt.kml',
  '慶良間諸島'   :'http://www.biodic.go.jp/trialSystem/LinkEnt/nps/NPS_keramashotouLinkEnt.kml'
styles =
    '特別保護地区' : '#dd6'
    '海域公園地区' : '#23d'
    '海中公園地区' : '#23d'
    '第1種特別地域': '#d6d'
    '第2種特別地域': '#d66'
    '第3種特別地域': '#6d6'
    '普通地域'    : '#6dd'

gulp.task 'download', () ->
  for npname, url of entries
    download url
      .pipe rename  extname:'.xml'
      .pipe xml2json()
      .pipe jeditor (json) ->
        #get urls of networklinked KMLs
        kmzUrl = json.kml.Document[0].Folder[0].NetworkLink[0].Link[0].href[0]
        basename = path.basename kmzUrl, '.kmz'
        download kmzUrl
          .pipe unzip()
          .pipe rename extname:'.xml'
          # conserve CDATA--
          .pipe xml2json()
          .pipe convert {from:'json', to:'xml'}
          .pipe rename extname:'.kml'
          # --conserve CDATA
          .pipe geojson()
          .pipe rename extname:'.json'
          .pipe jeditor (json) ->
            for feature, i in json.features
              # 地種属性を付与
              description = feature.properties.description
              for grade, fillColor in styles
                feature.properties.grade = '地種不明'
                feature.properties.gradeFill = '#666'
                if description.match ///#{style.name}///
                  feature.properties.grade = grade
                  feature.properties.gradeFill = fillColor
                  break;
          .pipe rename {basename:basename, extname:'.geojson'}
          .pipe gulpif (file) ->
              return file.name is 'NPS_keramashotou.geojson'
          , jeditor (json) ->
              for feature in json.features
                  feature.properties.name = '慶良間諸島'
              return json
          .pipe exec 'topojson -p name -p grade -p gradeFill -p description -o <%= file.path %>.topojson <%= file.path %>'
          .pipe exec.reporter stdout:true
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
