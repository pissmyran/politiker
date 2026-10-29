# PolitikerKontakt

*English translation of the Swedish documentation. The Swedish pages are the original.*

PolitikerKontakt makes it easy to write to politicians and other elected representatives, one or many at once, from your own email account. The letters are sent from your address, so replies come straight to you. Users create their own accounts, can import letters from Word or PDF, and choose recipients per level, for example the Riksdag, region and municipality. The app itself is in Swedish.

The image starts empty: there are no accounts and no contact directory. You do not need a Cloudflare account.

## Getting started

The image is on Docker Hub as `docker.io/driftaegis/politiker`. The compose file below pulls it from there, so you neither clone the repo nor build anything.

1. **Install Docker.** On Windows and Mac: [Docker Desktop](https://www.docker.com/products/docker-desktop/). On Linux: the `docker.io` package (Debian/Ubuntu) or equivalent. Podman works too.
2. **Create a folder** with a file in it named `docker-compose.yml`. Paste the content below.
3. **Fill in** `PUBLIC_HOST` (the host name the site is reached at) and `ADMIN_EMAIL` (your email address).
4. **Start** it in that folder: `docker compose up -d`
5. **Register an account.** Open `http://localhost:8787` and register with the address in `ADMIN_EMAIL`. Within a minute the account becomes administrator.
6. **Connect your email.** Add your SMTP details in the account, or sign in with Google or Microsoft if you have set that up. Then you can add recipients and send.

```yaml
services:
  politiker:
    image: docker.io/driftaegis/politiker:0
    restart: unless-stopped
    ports:
      - "8787:8787"
    environment:
      PUBLIC_HOST: "politiker.example.com"
      ADMIN_EMAIL: "you@example.com"
      SYSTEM_FROM_ADDRESS: "noreply@example.com"
      SYSTEM_SMTP_HOST: ""
      SYSTEM_SMTP_PORT: "587"
      SYSTEM_SMTP_USER: ""
      SYSTEM_SMTP_PASSWORD: ""
      TURNSTILE_SITE_KEY: ""
      TURNSTILE_SECRET: "off"
      OAUTH_GOOGLE_CLIENT_ID: ""
      OAUTH_GOOGLE_CLIENT_SECRET: ""
      OAUTH_MICROSOFT_CLIENT_ID: ""
      OAUTH_MICROSOFT_CLIENT_SECRET: ""
    volumes:
      - politiker-data:/data

volumes:
  politiker-data:
```

## Two kinds of email

- **The users' letters** are always sent from the user's own account, through SMTP or through signing in with Google or Microsoft. The credentials are encrypted in the database.
- **System email**, meaning verification codes and password resets, is sent from `SYSTEM_FROM_ADDRESS` through `SYSTEM_SMTP_*`. If system email is not set up, new accounts are verified immediately and password reset is not available. That is enough for an install in a small group. For an open site you should set up system email.

## Settings

| Variable | Required | Default | Meaning |
|---|---|---|---|
| `PUBLIC_HOST` | Yes | `localhost` | The host name without `https://`. Used in links, email, signing in with Google and Microsoft and two-factor codes. |
| `ADMIN_EMAIL` | Recommended | – | The account with this address becomes administrator and is marked as verified. |
| `SYSTEM_FROM_ADDRESS` | No | `noreply@example.com` | Sender for system email. |
| `SYSTEM_SMTP_HOST`, `SYSTEM_SMTP_PORT`, `SYSTEM_SMTP_USER`, `SYSTEM_SMTP_PASSWORD` | No | port `587` | SMTP server for system email. Port 587 (STARTTLS) or 465 (TLS). |
| `RESEND_API_KEY` | No | – | Alternative to SMTP for system email, through [Resend](https://resend.com). |
| `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET` | No | `off` | Cloudflare Turnstile against bot registrations (free, needs a Cloudflare account). `off` turns the check off. Recommended for a public site. |
| `TURNSTILE_HOSTNAMES` | No | `PUBLIC_HOST` | Host names the Turnstile answer may come from. |
| `OAUTH_GOOGLE_CLIENT_ID`, `OAUTH_GOOGLE_CLIENT_SECRET` | No | – | "Sign in with Google". Redirect address: `https://<PUBLIC_HOST>/api/oauth/google/callback`. |
| `OAUTH_MICROSOFT_CLIENT_ID`, `OAUTH_MICROSOFT_CLIENT_SECRET` | No | – | "Sign in with Microsoft" and sending through Outlook. Redirect addresses: `https://<PUBLIC_HOST>/api/oauth/microsoft/callback` and `https://<PUBLIC_HOST>/api/oauth-mail/microsoft/callback`. |
| `FEEDBACK_NOTIFY_EMAIL` | No | – | Address that receives the users' feedback. |
| `MAIL_CRED_KEY` | No | created automatically | Key that encrypts the users' email credentials. Created the first time and saved in `/data/mail-cred-key`. |
| `LETTER_DATA_KEY`, `VISITOR_SALT` | No | `MAIL_CRED_KEY` | Separate keys for letter content and visitor statistics. |
| `PORT` | No | `8787` | The port inside the container. |

### Settings from a file instead

If you do not want values such as passwords in the compose file, put them as `NAME=value` lines in the file `import.env` in the data volume (the one mounted at `/data`) and restart the container. At start the values are saved to `/data/settings.env`, which only the container can read, and `import.env` is deleted. To change a value later, add a new `import.env` with just that line. A line with `NAME=` and no value removes the setting. Values filled in in the compose file take precedence over saved values.

## Data, backup and updates

- Everything lives in the volume mounted at `/data`:
  - the database (SQLite) with accounts, contacts and sends,
  - sessions,
  - attachments,
  - the automatically created key.
- **Back up:** `docker compose stop`, copy the volume and run `docker compose start`. Include `/data/mail-cred-key`, or the users' saved email credentials cannot be read.
- **Update:** `docker compose pull && docker compose up -d`. Database migrations run automatically at start.
- **Versions:** the tags follow semver. The project is at version 0, so `0` follows every update. For fixes only choose `0.11`, and for an exact version `0.11.0`.

## HTTPS

The container speaks plain HTTP on port 8787. Put it behind a reverse proxy with a certificate, for example Caddy, Traefik or nginx, or use a Cloudflare Tunnel. Signing in with Google and Microsoft requires HTTPS.

## Technical overview

- **Runtime:** PolitikerKontakt is written as a Cloudflare Worker. In the container it runs in `workerd`, the same runtime Cloudflare uses, through `wrangler dev --local` (Miniflare). D1 (SQLite), KV, R2, the send queue and the Durable Object counter for sign-in attempts all run locally, with state under `/data`.
- **Scheduling:** `wrangler dev` does not start cron runs by itself. So `docker/scheduler.mjs` calls the scheduled run every minute. It requeues pending sends and makes `ADMIN_EMAIL` administrator.
- **Sending:** sends go through a queue with one message at a time and a dead letter queue. SMTP runs over `cloudflare:sockets`. Sends per user and day are limited.
- **Security:**
  - Passwords are hashed.
  - Two-factor sign-in (TOTP) and API keys are available.
  - Sign-in attempts are limited in a serialized Durable Object.
  - The users' email credentials and letter content are encrypted with AES-GCM.
  - Changing requests require same-origin, and responses have a strict CSP.
- **The image** is based on `node:24-trixie-slim` (Node LTS on Debian stable), runs as the `node` user and has a healthcheck. It only contains source code with placeholders; your values are filled in when the container starts.
- **Limits:** `wrangler dev` is a development server that runs one process on one machine. That is enough for a group or association, but gives no Cloudflare scaling. The contact directory of politicians is not included; the administrator or the users fill it.
- **Troubleshooting:** `docker compose logs -f`. The administrator sees sends, accounts and statistics in the admin view.

## Changelog

**0.12.2**
- `tools/render.mjs` writes each filled-in file in a loop until every byte is written, so a short write cannot leave a truncated file.

**0.12.1**
- `tools/render.mjs` reads and writes each file through the same file descriptor, so the file cannot be swapped between the check and the write.

**0.12.0**
- Settings can be given once in `/data/import.env` instead of in the compose file. They are saved to `/data/settings.env` and the import file is deleted.
- The image is built from the project's own repo: `docker build -t politiker .`.

**0.11.0**
- First Docker image, with D1, KV, R2, the queue and the Durable Object local under `/data`. The migrations run at start, and the contact directory is empty.
- `ADMIN_EMAIL`: the account with that address becomes administrator.
- Without system email, new accounts are verified immediately instead of the registration failing.
- `TURNSTILE_SECRET=off` turns off the bot check, and an empty key hides the widget.
- The key for the email credentials is created automatically the first time.

## License

MIT.
