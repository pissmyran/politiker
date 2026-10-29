# Overview

```text
Browser
    |
    v
app/src/access-index.ts    outer boundary: routing and security headers
    |
    v
app/src/index.ts ──> D1         accounts, letters, sends, the contact register
    |            ──> KV         sessions
    |            ──> R2         attachments
    |            ──> Email      system email
    v
Queue (SEND_QUEUE) ──> CredentialRateLimiter ──> your email (SMTP, Google, Microsoft)
    |
    └──> DLQ
```

Cron runs every minute and requeues pending sends.

| Topic | Page |
| --- | --- |
| Bindings, state, sending, security and theme | [Architecture](architecture.md) |
| Tests, migrations, deployment and troubleshooting | [Operations](operations.md) |
| The tools that fill the public contact register | [The contact register](kontakter.md) |

## Who owns which data

- **D1** is the single source of truth: accounts, letters, sends, your own contacts and the public register `public_contacts`.
- **KV** only holds sessions.
- **R2** only holds the attachments' bytes; metadata lives in D1.
- **The queue and the DLQ** are transport. They never replace the sends' state in D1.
- **The Durable Object** `CredentialRateLimiter` controls the pace per email account.
- **The static files** are presentation.

## Before you change anything

- **Sign-in, sessions or the API:** read [Architecture](architecture.md) and run the tests.
- **The D1 schema:** write a new migration in `infra/migrations/` and read [Operations](operations.md).
- **Sending, the queue or the pace:** read [Architecture](architecture.md) and the troubleshooting in [Operations](operations.md).
- **The contact register:** read [The contact register](kontakter.md).
