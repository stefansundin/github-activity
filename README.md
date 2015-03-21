# GitHub Activity RSS Feed [![Code Climate](https://codeclimate.com/github/stefansundin/github-activity/badges/gpa.svg)](https://codeclimate.com/github/stefansundin/github-activity)

You can use this app freely at [gh-rss.herokuapp.com](https://gh-rss.herokuapp.com/).


## Roll your own

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/stefansundin/github-activity)

Data is cached in redis. You have to [verify](https://heroku.com/verify) your Heroku account to add the free redis addon. You don't need a credit card if you create an account directly on [redislabs.com](https://redislabs.com).

You should configure `maxmemory-policy` to be `volatile-lru` to prevent your redis instance from running out of memory.

You probably want to authenticate with GitHub to get more than 60 requests per hour. Use [this script](https://gist.github.com/stefansundin/85b9969ab8664b97b7cf) to obtain a GitHub access token.


## TODO

- [ ] Find modified forks.
- [ ] Render markdown.
- [ ] Follow by user id.
