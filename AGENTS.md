# AGENTS.md – politiker

Brev till politiker från användarens egen e-post, plus en Docker-bild för egen drift.

Läs de gemensamma reglerna i början av varje session: [GOVERNANCE.md](https://raw.githubusercontent.com/pissmyran/.github/main/GOVERNANCE.md) och [SERVICES.md](https://raw.githubusercontent.com/pissmyran/.github/main/SERVICES.md).

## Läs vid behov

- [docs/architecture.md](docs/architecture.md): bindningar, state, utskick och säkerhet.
- [docs/operations.md](docs/operations.md): tester, migreringar och felsökning.
- [docs/kontakter.md](docs/kontakter.md): verktygen för kontaktregistret.

## Kommandon

Appen, före varje push (Node-versionen i `.node-version` krävs av `--experimental-strip-types`):

```bash
cd app && npm ci && npm run typecheck && npx --yes node@"$(cat ../.node-version)" --experimental-strip-types --test tests/*.test.ts
```

Appen, full kontroll med lokal migrering och torrkörd driftsättning, vid ändrad konfiguration eller migrering:

```bash
cd app && npx --yes -p node@"$(cat ../.node-version)" -- npm run validate
```

Kontaktverktygen:

```bash
cd kontakter && pip install -r requirements-dev.txt requests pypdf dnspython && python -m pytest -q
```

## Regler

- **Ingång:** `app/src/access-index.ts`. Hanterare: fetch, queue, scheduled `* * * * *`. Bindningar: D1, KV, R2, Queue, Durable Object, send_email, Assets. Driftsätt med `--cwd build/app`.
- **När du ändrar kod:** förenkla och städa det du rör, så länge det inte breddar ändringen eller ändrar beteendet. Ta bort gammal kompatibilitetskod först när det är bekräftat att inget använder den.
- **D1 är enda sanningen.** Konton, OAuth (Google/Microsoft), TOTP och API-nycklar ligger i D1, sessioner i KV. KV, R2, kön och Durable Object har var sin avgränsad roll.
- **Utskick** går genom en kö (batch 1, DLQ) med användarens SMTP- eller OAuth-uppgifter. `CredentialRateLimiter` (Durable Object) begränsar inloggningsförsök, missbruk, utskick och SMTP-tester per mejlkonto (`credentialId` i `send-queue.ts` och `mail-credentials.ts`), hanterar ett anrop i taget och ersätts aldrig med state i KV eller i processen.
- **Schemaändringar** görs bara som migreringar i `infra/migrations/`.
- **Cron varje minut** ska vara billig: köar bara om väntande utskick, med indexerade frågor med `LIMIT`, och gör inget när kön är tom.
- **Egen drift:** `TURNSTILE_SECRET=off` stänger av bot-kontrollen, och utan systemmejl verifieras konton direkt. Det är avsiktliga lägen, inte säkerhetsfel.
- **`kontakter/`** innehåller verktygen för kontaktdata. Deras utdata hamnar aldrig i repot.
- **Dokumentationen** publiceras också under `/docs` av appens egen Worker: Workers Builds kör `node tools/render.mjs - build && (sh tools/docs-cloudflare.sh build/app/public || echo "docs skipped")`, som lägger till en `/docs/*`-regel i `_headers` vars CSP tillåter sajtens inline-skript med hash.
- **Release:** versionen finns i `version.txt`.
- **Extra noggrant:** inloggning och OAuth, utskickskön, krypterade uppgifter, kontaktverktygen och migreringar.

## Repository review guidance

`.coderabbit.yaml` inherits from `pissmyran/coderabbit/.coderabbit.yaml` with
`inheritance: true`. Keep local guidance specific to this repository: it covers
attachments and document imports, browser behavior and accessibility, app tests,
queue recovery, migrations, dependency lockfiles and the `docs/eng` mirror, in
addition to the existing security review areas. See [operations](docs/eng/operations.md#repository-review-configuration)
for inheritance and validation details.
