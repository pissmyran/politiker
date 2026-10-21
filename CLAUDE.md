# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The public source of politiker: a service for writing to politicians from your own e-mail account, plus its self-hosted Docker image. It is one of four sibling repos (dumpen, jobb, klarsprak, politiker); shared community files, issue forms and the GitHub settings for all of them live in the account's `.github` repo. The code is generic: it contains no account ids, domains, e-mail addresses, keys or other personal values — only `__NAME__` placeholders. Real values live outside the repo and are filled in at deploy (`tools/render.mjs`) or by the user in `docker-compose.yml`. Read `AGENTS.md`, `README.md` and `docs/` before larger changes.

| Dir | Entry | Handlers | Bindings |
|---|---|---|---|
| `.` | `app/src/access-index.ts` | fetch, queue, scheduled `* * * * *` | D1, KV, R2, Queue, Durable Object, send_email, Assets |

## The one rule: no personal values

Never write a real id, domain, e-mail address, key, name, donation link or payment detail into code, config, tests, docs or commit messages. Use a placeholder declared in `cloudflare.example.env` (code and config) or `example.com`-style values (docs and tests). Personal assets such as images go in an overlay directory outside the repo. The repo is public.

## Placeholders and deploy

- Every `__NAME__` used in the code must be declared in `cloudflare.example.env`, with an example value and a comment saying where the real value comes from.
- `node tools/render.mjs <values.env | -> <out-dir> [overlay-dir]` copies the repo, fills in every declared placeholder (failing if a value is missing), copies the overlay on top, drops routes with an empty pattern and links `node_modules`. With `-` the values come from environment variables.
- Production is deployed by Workers Builds (Cloudflare's GitHub connection) when a PR is merged to `main`, with the values as Cloudflare build variables: build command `node tools/render.mjs - build`, deploy command `npx wrangler deploy --cwd build/app`. Only `main` builds; pushing to `dev` deploys nothing.
- A self-hosted deploy from a private values file works the same way: render, then `npx wrangler deploy --cwd build/app`, and throw the rendered copy away. Secrets go in with `npx wrangler secret put`, never in the repo.
- Deploy the new Worker before applying a migration that drops tables or columns.
- Tests run on the unrendered source, so they see the placeholders.
- Values that encrypt stored data (jobb's `CONFIG_NAMESPACE`) must never change for an existing database.

## Commands

```bash
cd app && npm ci && npm run typecheck && npx node@24 --experimental-strip-types --test tests/*.test.ts
cd kontakter && pip install -r requirements-dev.txt requests pypdf dnspython && python -m pytest -q
```

Formatting: Prettier with `.prettierrc.json` (printWidth 100). Run `npx prettier --write <paths>` after editing; CI runs `prettier --check .`. Tests that read source files must not depend on formatting; prefer importing and calling real code over matching source text.

## Architecture

- **politiker**: letters to politicians from the user's own e-mail account. Accounts, OAuth (Google/Microsoft), TOTP and API keys in D1, sessions in KV. Sends go through a queue (batch 1, DLQ) using user SMTP/OAuth credentials; Durable Object `CredentialRateLimiter` rate-limits logins. The per-minute cron only re-queues pending sends with indexed, LIMIT-bounded queries. For self-hosting, `TURNSTILE_SECRET=off` skips the bot check and accounts are verified directly when no system e-mail is configured. `kontakter/` holds the contact-data tooling; its output never goes in the repo.

## Cost and logging

Target the Workers Free plan: 10 ms CPU per invocation. No full inventory or rescan on each cron run, request or added item; work incrementally and cache derived data at write time.

Logging, as in the sibling repos: logs at sampling 1 with invocation logs, traces at 0.01, query strings redacted, Workers Issues on. Keep volume down in the code: log errors and warnings, plus at most a line or two per run. Handled errors reach Issues only through `console.error`.

## Documentation site

`README.md`, `docker/README.md` and `docs/` are also the documentation site on GitHub Pages, built with Zensical (`zensical.toml`, pinned in `requirements-docs.txt`) and published from `main` by `.github/workflows/pages.yml`. Build it locally with `node tools/docs-site.mjs && zensical build` (output in `site/`). `tools/docs-site.mjs` makes the README the start page and points links to files outside the site at GitHub. Keep the README's `**Dokumentation:**` line at the top, and add every new page under `docs/` to `nav` in `zensical.toml`.

## Docker image

- `Dockerfile` (build from the repo root: `docker build -t politiker .`), `docker-compose.yml`, `CHANGELOG.md` and `docker/` (`README.md` is the Docker Hub page, `entrypoint.sh`, `import-settings.sh`, the container wrangler config).
- The Worker runs in workerd through `wrangler dev --local` with all state under `/data`. The entrypoint renders the source with `tools/render.mjs` from the container environment with zero-setup defaults, and generates missing encryption keys once into `/data`. Images start empty and never read from anyone's Cloudflare resources.
- Settings come from `docker-compose.yml`, or once from `/data/import.env`: `import-settings.sh` merges it into `/data/settings.env` and deletes it. Non-empty compose variables win.
- Keep `docker/README.md` in step with `docker-compose.yml` and `CHANGELOG.md`. Versions are semver. To release, bump `version.txt` on `dev` by semver (major for breaking changes, minor for new features, patch for fixes) and add a `## X.Y.Z – YYYY-MM-DD` entry to CHANGELOG.md. When that reaches `main`, `.github/workflows/release.yml` creates the tag and the GitHub release and calls `docker.yml`, which pushes `X.Y.Z`, `X.Y`, `X` and `latest` to Docker Hub. A merge without a version bump releases nothing. If the Docker job fails, "Re-run failed jobs" on the release run retries it; if the release step stopped after the tag was created, run `docker.yml` by hand (workflow_dispatch on the tag).

## Branches and review

The repo is public on GitHub (`VineDrinker/politiker`).

- All work happens on `dev`. `main` changes only through a pull request from `dev`, merged with a squash merge (the only method allowed). Nobody pushes directly to `main`.
- Before starting new work, bring `dev` up to date: `git pull --no-rebase origin main`, then push `dev`. A squash merge leaves `main` with a commit `dev` does not have, so this is a merge unless `dev` can fast-forward; `dev` can never be force-pushed or deleted.
- Before pushing to `dev`, run the tests once per finished change set.
- Open the PR with `gh pr create --base main --head dev --assignee VineDrinker` and turn on auto-merge with `gh pr merge <number> --auto --squash`. GitHub merges it by itself once the rules on `main` are met: the tests and `Docker-bild` green and no CodeQL errors or high-severity security alerts, no approval needed; the branch need not be up to date.
- When CI, Docker or Release fails, `.github/workflows/larm.yml` opens an issue labelled `ci-failure` assigned to the owner (or comments on the open one) and closes it when the workflow passes again. Nobody needs to watch GitHub.
- Review findings are input, not a to-do list: a fault gets a fix, a finding that shows the design went wrong gets a rethink or a rewrite, noise is dismissed with a reason. Never use CI or review rounds as a debugging loop.
- Renovate keeps dependencies on their LTS, stable or latest versions (shared config in the account's `.github` repo) and merges its own PRs with squash once the checks pass; Dependabot only raises security alerts. Tool versions are never pinned separately in CI or Dockerfiles when the manifest already names them. Workflows use only GitHub's own actions, pinned by commit SHA, with a read-only token, and never `pull_request_target`. Nothing may be enabled that can cost money.
