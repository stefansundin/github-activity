# GitHub Activity RSS Feed

You can use this app freely at [gh-rss.herokuapp.com](https://gh-rss.herokuapp.com/).


## Roll your own

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/stefansundin/github-activity)

You need to create a GitHub access token:
- https://github.com/settings/tokens
  - This token should not be assigned any scopes!

To allow people to authorize for private gists, you need to create a GitHub app:
- https://github.com/settings/developers

## TODO

- [ ] Find modified forks.
- [ ] Render markdown.
- [ ] Follow by user id.
