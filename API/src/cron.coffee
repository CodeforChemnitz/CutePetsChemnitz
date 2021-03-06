cheerio = require 'cheerio'
request = require 'request'
redis = require 'redis'
bluebird = require 'bluebird'
_ = require 'lodash'

bluebird.promisifyAll(redis.RedisClient.prototype)

cache = redis.createClient('/var/run/redis/redis.sock')

cache.on 'error', (err) ->
  d = new Date()
  console.error '%s - %s', d.toISOString(), err


tierfreunde_url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
tierfreunde_splitpos = tierfreunde_url.lastIndexOf '/'
tierfreunde_base_url = tierfreunde_url.slice 0, tierfreunde_splitpos+1

tierschutz_url = "http://www.tierschutz-chemnitz.de/vm_hunde.php"
tierschutz_splitpos = tierschutz_url.lastIndexOf '/'
tierschutz_base_url = tierschutz_url.slice 0, tierschutz_splitpos+1

get_tierfreunde = (url)->
  new Promise (f, r) ->
    request url, (err, response, body) ->
      if err
        r err
      try
        d = new Date()
        console.info '%s - %s: %s', d.toISOString(), "Scraping", url
        $ = cheerio.load body
        content = $('#content')
        name = content.find('h1').text()
        img = content.find('img').attr('src')
        pic = tierfreunde_base_url + img
        id = img.split '.', 1
        id = id[0].split '/'
        content.find('h1').remove()
        content.find('a').remove()
        details =
          id: id[-1..][0]
          pic: encodeURI pic
          name: name
          link: url
          desc: content
            .text().replace(/\n/g, '')
            .replace(/\r/g, '')
            .replace(/\t/g, '')
            .trim()
        f details
      catch err
        console.error err
        f {}

get_tierfreundeUrls = (url) ->
  new Promise (f, r) ->
    request url, (err, response, body) ->
      if err
        r err
      urls = []
      d = new Date()
      console.info '%s - %s: %s', d.toISOString(), "Seaching Urls", url
      $ = cheerio.load body
      $('.teaser-subline').each ->
        elem = $(this)
        detail_url = tierfreunde_base_url + elem.find('.teaser-image').find('a').attr('href')
        urls.push detail_url
      f urls

get_tierschutz = (url) ->
  new Promise (f, r) ->
    request url, (err, response, body) ->
      if err
        r err
      try
        d = new Date()
        console.info '%s - %s: %s', d.toISOString(), "Scraping", url
        $ = cheerio.load body
        content = $('table')
        name = content.find('.Stil2').text().replace /"/g, ''
        img = content.find('img').attr('src')
        pic = tierschutz_base_url + 'vermittlung/' + img
        id = img.split '.', 1
        id = id[0].split '/'
        content.find('.Stil2').remove()
        content.find('p').first().remove()
        content.find('p').last().remove()
        content.find('p').each ->
          elem = $(this)
          elem.remove() if elem.text().trim().split(/\s+/).length < 10
          elem.remove() if /^-/.test elem.text().trim()
        details =
          id: id[-1..][0]
          pic: encodeURI pic
          name: name
          link: url
          desc: content.find('.Stil1')
            .text().replace(/\n/g, '')
            .replace(/\r/g, '')
            .replace(/\t/g, '')
            .trim()
        f details
      catch err
        console.error err
        f {}

get_tierschutzUrls = (url) ->
  new Promise (f, r) ->
    request url, (err, response, body) ->
      if err
        r err
      urls = []
      d = new Date()
      console.info '%s - %s: %s', d.toISOString(), "Seaching Urls", url
      $ = cheerio.load body
      $('td', '#center').each ->
        elem = $(this)
        if elem.attr 'colspan' is undefined
          href = elem.find('a').attr('href')
          if href isnt undefined and /^vermittlung/.test href
            detail_url = tierschutz_base_url + href
            urls.push detail_url
      f urls

get_tierfreundedata = ->
  new Promise (f, r) ->
    get_tierfreundeUrls tierfreunde_url
      .then (urls) ->
        p = []
        for url in urls
          p.push get_tierfreunde url
        Promise.all p
      .then (values) ->
        f values
      .catch (err) ->
        r err

get_tierschutzdata = ->
  new Promise (f, r) ->
    get_tierschutzUrls tierschutz_url
      .then (urls) ->
        p = []
        for url in urls
          p.push get_tierschutz url
        Promise.all p
      .then (values) ->
        f values
      .catch (err) ->
        r err

get_data = ->
  Promise.all [get_tierschutzdata(), get_tierfreundedata()]
    .then (list_of_values) ->
      values = _.filter list_of_values, (o) -> return !(_.isEmpty(o))
      data = JSON.stringify(_.union.apply(null, values))
      cache.setAsync 'tiere', data
        .then ->
          d = new Date()
          console.info '%s - %s', d.toISOString(), "Set new DataSet"
          cache.quit()
    .catch (err) ->
      d = new Date()
      console.error '%s - %s', d.toISOString(), err
    
get_data()
