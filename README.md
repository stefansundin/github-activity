### Configuration

- `GITHUB_TOKEN` is required for access to the GitHub GraphQL API. This is used for non-authenticated access. Generate a token [here](https://github.com/settings/tokens) with no scopes.
- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` is required for authenticated access to private gists. Create an OAuth application [here](https://github.com/settings/developers).
- `ENCRYPTION_KEY` is used to encrypt the token in the URL for authenticated access. The app itself is completely stateless and does not store the tokens so it relies on being passed the token by the user. Run `rake secret` to generate a good key.
