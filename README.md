# GitHub Activity RSS Feed

You can use this app freely at [gh-rss.herokuapp.com](https://gh-rss.herokuapp.com/), or deploy it yourself if you want to.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/stefansundin/github-activity)

You have to [verify](https://heroku.com/verify) your Heroku account to add the free redis addon.

After deploying, you probably want to [create a GitHub application](https://github.com/settings/applications/new) to increase your ratelimit. Then set the two ENV keys `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`. If you don't authenticate, you have 60 requests per hour, which should be enough if you are the only user.

Data is cached in redis. You should configure `maxmemory-policy` to be `volatile-lru` to prevent it from running out of memory. You can store the access token in ENV instead of redis if you want. After authenticating, run:

```
heroku run print_access_token
heroku config:set ACCESS_TOKEN=token_you_just_got
```
