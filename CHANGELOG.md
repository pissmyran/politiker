# Changelog

Versions follow [semver](https://semver.org). The Docker image is tagged `X.Y.Z`, `X.Y`, `X` and `latest`.

## 0.12.1 – 2026-10-19

- `tools/render.mjs` checks the size of, reads and rewrites each file through one file descriptor, so a file cannot be swapped between the check and the write (CodeQL js/file-system-race).

## 0.12.0 – 2026-10-18

- Settings can be given once in `/data/import.env` instead of in `docker-compose.yml`: they are saved to `/data/settings.env`, readable only by the container, and the import file is deleted. `NAME=` removes a setting; non-empty compose variables still win.
- The project now lives in its own repository, so the image builds from the repo root with `docker build -t politiker .`.

## 0.11.0 – 2026-10-17

- First Docker image: the Worker, its send queue, the per-minute cron and the rate-limit Durable Object run in workerd via `wrangler dev --local`, with D1, KV and R2 under `/data`. Migrations run on start and the contact directory starts empty.
- `ADMIN_EMAIL`: the account registered with that address becomes admin.
- Without system e-mail, new accounts are verified directly instead of failing to send a code.
- `TURNSTILE_SECRET=off` turns the bot check off for installs without Turnstile keys; an empty site key hides the widget.
- The mail-credential encryption key is generated once and kept in `/data` when `MAIL_CRED_KEY` is not set.
