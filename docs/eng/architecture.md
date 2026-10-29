# Architecture

## Runtime

The Worker `politiker` starts in `app/src/access-index.ts` and is configured in `app/wrangler.jsonc`:

| Binding | Type | Used for |
| --- | --- | --- |
| `DB` | D1 | All state, with the migrations in `infra/migrations/` |
| `SESSIONS` | KV | Sessions |
| `ATTACHMENTS` | R2 (`politiker-attachments`) | Attachments |
| `SEND_QUEUE` | Queue (`politiker-send-jobs`) | Sends, one at a time, up to ten attempts and then `politiker-send-jobs-dlq` |
| `RATE_LIMITER` | Durable Object (`CredentialRateLimiter`) | The pace per email account |
| `EMAIL` | Email | System email from `SYSTEM_FROM_ADDRESS` |
| `ASSETS` | Static files (`app/public/`) | The pages; the Worker goes first for `/`, `/api/*` and `/admin*` |

Secrets: `MAIL_CRED_KEY` and `LETTER_DATA_KEY` (encryption keys), `SYSTEM_SMTP_PASSWORD`, `TURNSTILE_SECRET`, the OAuth clients' secrets and optionally `RESEND_API_KEY`.

Cron `* * * * *` requeues pending sends. It only runs indexed queries with `LIMIT` and does nothing at all when nothing is pending.

Logging: every log (sampling 1, with invocation logs), traces at 1 %, query strings masked and Workers Issues on. Sign-in and API flows can carry sensitive parameters, so the masking must never be turned off.

## The code

- **`app/src/access-index.ts`** is the outer boundary and sets the policy before the application or the static files answer.
- **`app/src/index.ts`** is the application: accounts, sign-in, API keys, contacts, letters, attachments, sends, the queue consumer, feedback and admin.
- **`shared/`** is code used by both the Worker and the Docker variant: encryption, TOTP, SMTP, Microsoft Graph, Resend and input checks.

## Accounts and sessions

Accounts and everything that belongs to them live in D1, the sessions in KV. Sign-in is with a password (with optional TOTP) or with Google or Microsoft. Sensitive actions, such as changing a saved email account, require that the sign-in is at most 15 minutes old; otherwise the page asks you to confirm again.

## The public register

`public_contacts` is the shared register: politicians at every level, authorities, newsrooms, the Church of Sweden and academics. `area_type` tells the groups apart. Academics also have a university, unit, title, field and source page. `public_contact_assignments` links municipal and regional politicians to committees and boards for filtering by policy area.

The search is `/api/public-contacts/search`; `/api/politicians/search` remains as an alias for older clients.

The register is filled by the tools in `kontakter/`; see [The contact register](kontakter.md).

## Your own contacts and introductions

Each account can have its own contact lists. Reusable introductions live in `letter_intro_presets`; the heading is saved in plain text and the text encrypted, just like the letter.

## Sending

1. A send is saved in D1 and put in the queue.
2. The queue consumer takes one job at a time and asks `CredentialRateLimiter` whether the email account may send now.
3. The letter is personalized in the order personal greeting, chosen introductions and letter text (`personalizeLetter`), and sent from the user's own account through SMTP, Google or Microsoft.

The introductions are saved encrypted on the send (`send_jobs.intro_text`) when it starts, so a later change to a template does not affect a send in progress. The letter's content is deleted automatically after the time the user chose: 5 minutes, 1 day, 3 days or 7 days after the send is finished.

The queue and the DLQ only show the transport's state. The send's real status lives in D1.

## The pace

`CredentialRateLimiter` is one Durable Object per email account. Since it handles one request at a time, several concurrent Worker requests can never together send faster than the provider's limit. It must never be replaced by state in KV or in the process.

## Security boundaries

- Internet → the outer boundary in `access-index.ts`.
- Session or API key → the sign-in check.
- The application → D1, KV and R2.
- The application → the queue → the pace → the email provider.
- Admin → an explicit permission check.
- Sensitive API responses are never cached.

## Theme and PWA

There are three themes: `legacy` (default), `forest` (with the label from `SITE_FAMILY`) and `blackout`. The choice is saved in `localStorage["<prefix>.theme"]` and the cookie `<prefix>_theme`. The theme picker is at the bottom of the public pages. The theme only changes the look; PolitikerKontakt's own yellow-and-blue profile and status colors exist in every theme.

The site has a web manifest, icons at 192 and 512 pixels and a service worker that always fetches from the network and never caches sessions, data, attachments or sends. It only exists so the site can be installed.
