# PolitikerKontakt

*English translation of the Swedish documentation. The Swedish pages are the original.*

PolitikerKontakt lets you write to politicians, authorities, newsrooms and researchers from your own email account. You pick recipients from a public register or your own contact lists, write the letter and send it. Each recipient gets their own email from your address. The app itself is in Swedish.

It runs as a Cloudflare Worker with D1, KV, R2, a queue and a Durable Object, or as a ready-made Docker image. The tools in `kontakter/` keep the public register up to date.

## Tests

From `app/`:

```bash
npm ci
npm run validate
```

`validate` runs the tests, the syntax check of the scripts in `public/`, the local D1 migrations, the type check and a dry run of the deployment. The tools in `kontakter/` are tested with `python -m pytest -q` in that directory.

## Documentation

Start with the [overview](oversikt.md).

- [Architecture](architecture.md): bindings, state, sending and security
- [Operations](operations.md): migrations, deployment and troubleshooting
- [The contact register](kontakter.md): the tools that fill the public register

## Deploying to your own Cloudflare account

The code contains no account details. Wherever a value of your own is needed, such as a domain, a resource id or keys, there is a placeholder (`__NAME__`). Every placeholder is listed in `cloudflare.example.env`, with a comment on where the value comes from. The values only end up in Cloudflare, never in the repo.

**Option 1: deploy from your own computer.**

1. Create the resources: the D1 database (`npx wrangler d1 create <name> --jurisdiction eu`), the KV namespace for sessions, the R2 bucket `politiker-attachments` and the queues `politiker-send-jobs` and `politiker-send-jobs-dlq`.
2. Copy `cloudflare.example.env` to a file of your own outside the repo and fill in your values.
3. Render a copy with your values: `node tools/render.mjs <your-file.env> build`. The tool stops if a value is missing.
4. Add the secrets once with `npx wrangler secret put <NAME> --cwd build/app`: `MAIL_CRED_KEY`, `LETTER_DATA_KEY`, `SYSTEM_SMTP_PASSWORD`, `TURNSTILE_SECRET` and, if you use them, the OAuth clients' secrets.
5. Run the database migrations: `npx wrangler d1 migrations apply DB --remote --cwd build/app`.
6. Deploy: `npx wrangler deploy --cwd build/app`, then delete `build/`.

**Option 2: Workers Builds with the GitHub connection.** Add the values as *build variables* in Cloudflare (Workers → your Worker → Settings → Build), set the build command to `node tools/render.mjs - build && (sh tools/docs-cloudflare.sh build/app/public || echo "docs skipped")` and the deploy command to `npx wrangler deploy --cwd build/app`. Build only the production branch. Workers Builds does not run the migrations; see [Operations](operations.md).

## Running with Docker

PolitikerKontakt is available as a ready-made image on Docker Hub, `docker.io/driftaegis/politiker`. You do not need to build anything: `docker-compose.yml` names the image like this, and `docker compose up -d` pulls it.

In `docker-compose.yml`:

```yaml
    image: docker.io/driftaegis/politiker:0
```

The tag `0` gives every update within version 0; `X.Y` gives only fixes and `X.Y.Z` exactly one version. Every setting is described on the [Docker](docker.md) page, and the changes are listed in [CHANGELOG.md](../../CHANGELOG.md). To build the image yourself from source: `docker build -t politiker .` in the repo root.

## Contributing

Questions and ideas go to [Discussions](https://github.com/pissmyran/.github/discussions), bugs and suggestions as issues here. Read [CONTRIBUTING.md](https://github.com/pissmyran/.github/blob/main/CONTRIBUTING.md) before opening a pull request. Report security problems privately through the Security tab.

## License

MIT, see [LICENSE](../../LICENSE).
