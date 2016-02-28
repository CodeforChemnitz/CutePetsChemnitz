# CutePetsChemnitz

Post an random pet from shelter [Chemnitz (OT Röhrsdorf)](http://www.tierfreunde-helfen.de/) on Twitter [@petschemnitz](https://twitter.com/petschemnitz)

## About

Originated as a project of [Team Denver](http://codeforamerica.org/cities/denver/) during the 2014 fellowship at Code for America.
Originally specific to Denver, it's been redeployed by a few cities. Check out [this twitter list](https://twitter.com/drewSaysGoVeg/cutepetseverywhere/members) to see where.


**Links to Bot**

* [Twitter bot](https://twitter.com/petschemnitz)

## Setup & Deployment

### nodejs

[https://nodejs.org/](https://nodejs.org/en/)

### ruby
```
sudo apt-get install ruby ruby-dev rake
sudo gem install bundler
```

### Redis
```
sudo apt-get install redis
```

Configure Redis in `src/server.coffee`

### Repo
```
cd /opt/
git clone https://github.com/CodeforChemnitz/CutePetsChemnitz.git
cd CutePetsChemnitz
```

### API

The API is available via http://127.0.0.1:3000/

#### Install
```
cd API
npm install
npm run-script build
```

#### Run
```
node lib/cron.js
node lib/server.js
```


#### Deploy
Install Service
```
sudo ln -s /opt/CutePetsChemnitz/API/forever_cutepets /etc/init.d
sudo update-rc.d forever_cutepets defaults
sudo service forever_cutepets start
```

Adding a Cronjob:
```
# Scrape shelters every 6 hours
50 */6 * * *   root node /opt/CutePetsChemnitz/API/lib/cron.js
```


### Twitter
1. Create a new [twitter app](https://apps.twitter.com/).
1. On the API key tab for the Twitter app, modify permissions so the app can **Read and Write**.
1. Create an access token. On the API Key tab in Twitter for the app, click **Create my access token**
1. Take note of the values for environment set up below.
*Note:* It's important to change permissions to Read/Write before generating the access token. The access token is keyed for the specific access level and will not be updated when changing permissions.

#### Environmental variables
1. Create a local .env file: `cp template.env .env`
1. Fill in the twitter keys created above.

#### Install
```
bundler install
```

#### Run
```
rake
```

#### Deploy
Adding a Cronjob:
```
# Post a pet every hour
5 9-22/2 * * *  root cd /opt/CutePetsChemnitz && rake
```



## Hat tips

* Kudos to [Darius](https://github.com/dariusk) for his [great guide](http://tinysubversions.com/2013/09/how-to-make-a-twitter-bot/) on how to make a twitter bot.

* And kudo to [Erik](https://github.com/sferik/) for the [twitter gem](https://github.com/sferik/twitter).
