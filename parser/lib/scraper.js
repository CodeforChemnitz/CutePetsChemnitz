// Generated by CoffeeScript 1.9.3
(function() {
  var base_url, cheerio, get_detailUrls, get_details, request, splitpos, url;

  cheerio = require('cheerio');

  request = require('request');

  url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not";

  splitpos = url.lastIndexOf('/');

  base_url = url.slice(0, splitpos + 1);

  get_details = function(url, callback) {
    return request(url, function(err, response, body) {
      var $, details, name;
      $ = cheerio.load(body);
      name = $('.shady').find('h1').text();
      $('.shady').find('h1').remove();
      details = {
        pic: base_url + $('.shady').find('img').attr('src'),
        name: name,
        url: url,
        desc: $('.shady').text()
      };
      return callback(details);
    });
  };

  get_detailUrls = function(callback) {
    return request(url, function(err, response, body) {
      var $, urls;
      if (err) {
        console.error(err);
        return;
      }
      urls = [];
      $ = cheerio.load(body);
      $('.teaser-subline').each(function() {
        var detail_url, elem;
        elem = $(this);
        detail_url = base_url + elem.find('.teaser-image').find('a').attr('href');
        urls.push(detail_url);
      });
      return callback(urls);
    });
  };

  get_detailUrls(function(urls) {
    var i, len, results;
    results = [];
    for (i = 0, len = urls.length; i < len; i++) {
      url = urls[i];
      results.push(get_details(url, function(details) {
        return console.log(details);
      }));
    }
    return results;
  });


  /*
        tier =
          name: elem.find('h3').text()
          url: detail_url
          pic: base_url + get_details detail_url
          desc: elem.children().last().text()
        tiere.push tier
   */

}).call(this);

//# sourceMappingURL=scraper.js.map
