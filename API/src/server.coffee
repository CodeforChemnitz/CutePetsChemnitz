cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
redis = require 'redis'
bluebird = require 'bluebird'
_ = require 'lodash'

app = express()

bluebird.promisifyAll(redis.RedisClient.prototype)

cache = redis.createClient('/var/run/redis/redis.sock') # Configure Redis

cache.on 'error', (err) ->
  console.error err

# get a pet that was not posted yet
get_notPostedPet = ->
  new Promise (f, r) ->
    cache.getAsync 'posted_pets'
      .then (postedPets) ->
        postedPets = JSON.parse postedPets
        if postedPets is null
          postedPets = []
        cache.getAsync ('tiere')
          .then (pets) ->
            pets = JSON.parse pets
            notPostedPets = []
            for pet in pets
              if pet.id not in postedPets
                notPostedPets.push pet
              if notPostedPets.length is 0
                notPostedPets = pets
                postedPets = []
            random = Math.ceil Math.random()*notPostedPets.length-1
            notPostedPet = notPostedPets[random]
            postedPets.push notPostedPet.id
            cache.set 'posted_pets', JSON.stringify(postedPets)
            f notPostedPet
          .catch (err) ->
            r err
      .catch (err) ->
        r err

#console.log get_notPostedPet()

# Return all pets
app.get '/', (req, res) ->
  cache.getAsync ('tiere')
    .then (pets) ->
      res.json JSON.parse(pets)
    .catch (err) ->
      console.error err
      res.status(500).json(err)

# Return a random pet
app.get '/random', (req, res) ->
  get_notPostedPet()
    .then (pet) ->
      res.json pet
    .catch (err) ->
      console.error err
      res.status(500).json(err)

server = app.listen 3000, 'localhost', ->
  host = server.address().address
  host = if host.match /:/ then "[#{host}]" else host
  port = server.address().port
  console.log 'Listening at http://%s:%s', host, port
