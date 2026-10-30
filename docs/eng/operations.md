# Operations

## Checks before pushing

From `app/`:

```bash
npm ci
npm run validate
```

`validate` runs the unit tests, the tests of the production check, the syntax check of the scripts in `public/`, the local D1 migrations, type generation, the type check and `wrangler deploy --dry-run`.

For `kontakter/`: `pip install -r requirements-dev.txt requests pypdf dnspython` and `python -m pytest -q` in that directory.

## Local development

```bash
cd app
npm run dev
```

## Deployment

Production is deployed from a rendered copy, either from your computer or with Workers Builds when a PR is merged to `main`; see the [home page](index.md). CI on GitHub runs tests, the Docker build and CodeQL. There is no preview environment. The contact register is updated separately, not at deployment.

## Migrations

The migrations live in `infra/migrations/`. Workers Builds does not run them, so they are run by hand from a rendered copy:

```bash
node tools/render.mjs <your-file.env> build
npx wrangler d1 migrations apply DB --remote --cwd build/app
```

1. Schema changes are only made with new migrations.
2. A migration that adds runs before the new Worker is deployed, one that removes runs after.
3. Run `npm run validate` first; it tries the migrations locally.

## Check after deployment

```bash
node build/scripts/verify-production.mjs
```

It checks that the home page answers `200`, and tells a block at Cloudflare's edge (for example a challenge) apart from an error in the Worker. Each check is tried up to five times.

## Troubleshooting sends

Check in this order:

1. the send's state in D1;
2. the queue: pending jobs and retries;
3. the DLQ;
4. `CredentialRateLimiter` and the email account's limit;
5. the error from the email provider.

Never rerun a job in the queue first; the send's state in D1 and the queue must agree, or a letter can be sent twice.

### Errors on a saved email account

1. **Confirm the sign-in:** sensitive actions require a sign-in at most 15 minutes old. The page asks for the password and two-step verification, or sends an account that only uses Google or Microsoft there, without signing you out.
2. **"Det sparade SMTP-lösenordet kan inte dekrypteras"** (the saved SMTP password cannot be decrypted): the saved password cannot be read with the current `MAIL_CRED_KEY`. Never change `MAIL_CRED_KEY` to troubleshoot; use **Uppdatera lösenord** (update password), which tests and re-encrypts the password.
3. **Error `535` from the server:** the SMTP server rejected the sign-in. Many providers require an app-specific password.
4. **Delivery:** only once the account signs in is it time to look at the send's state, the queue and the recipients' replies.

**Uppdatera lösenord** tests the new password against the server before saving it, so a failed attempt changes nothing.

## Attachments

Check the binding, the object key and the link in D1 before anything is deleted or rewritten in R2. Never use the attachments' content for troubleshooting.

## Sign-in and sessions

Check in this order: the route, the session in KV, the account in D1 and last the password, TOTP or OAuth flow. Never make a private route public to solve a sign-in error.

Never put credentials, keys, email content or private API data in logs.

## Repository review configuration

`.coderabbit.yaml` uses `inheritance: true` to inherit
`pissmyran/coderabbit/.coderabbit.yaml`. Only repository-specific review guidance
is local. It also covers attachments and document imports, browser behavior and
accessibility, app tests, queue recovery, migrations, lockfiles and the mirror
under `docs/eng`.

Under [CodeRabbit's inheritance rules](https://docs.coderabbit.ai/configuration/configuration-inheritance),
unique central list entries remain, while a local entry with the same `path`
replaces the central entry. Overlapping but different path patterns both remain.
Scanners, review scope, advisory checks, disabled automatic approvals and disabled
credit-consuming features remain centrally controlled.

When changing the configuration, validate YAML syntax and duplicate keys, check
against the [current schema](https://coderabbit.ai/integrations/schema.v2.json), and
check that every path pattern covers its intended tracked files. Compare with
the central configuration so unique security guidance survives the merge.
