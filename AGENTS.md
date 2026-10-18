# AGENTS.md

## Läs först

- [CLAUDE.md](CLAUDE.md) — gemensamma regler för arbetssätt, deploy, loggning, kostnader och Docker. Arbetet sker lokalt; GitHub är sparpunkten och färdiga delar går in i `main` via en pull request.
- [docs/project-context.md](docs/project-context.md) — canonical runtime/current-state.
- [docs/architecture.md](docs/architecture.md) — Worker-, storage- och queuegränser.
- [docs/operations.md](docs/operations.md) — verifiering och incidentmodell.
- [docs/agents/domain.md](docs/agents/domain.md) — domänkonventionen.

## Invariants

- När kod ändå berörs: förenkla och sanitera det berörda området när det kan göras utan scope-expansion eller beteendeförändring. Ta bort död eller äldre kompatibilitetskod först när användningen är verifierat obefintlig; annars behåll och dokumentera gränsen.
- D1 är canonical application state; KV, R2, Queue och Durable Object har separata avgränsade roller.
- `CredentialRateLimiter` är serialiserad koordinationspunkt för mailcredential-rate limiting; ersätt inte den med oserialiserad process-/KV-state.
- D1-schemaändringar ska vara versionsstyrda migrationer i `infra/migrations/`.
- Cron-körningen varje minut ska förbli billig: indexerade, LIMIT-begränsade frågor och inget arbete när kön är tom.
- Kör `cd app && npm run typecheck && npx node@24 --experimental-strip-types --test tests/*.test.ts` före deploy.
- Bevara query-string-redaction och den gemensamma loggprofilen i `CLAUDE.md`.
- Egen installation (Docker): `TURNSTILE_SECRET=off` stänger av bot-kontrollen, och utan systemmejl verifieras nya konton direkt. Produktionen har både Turnstile och e-post och påverkas inte. Imagen startar tom och läser aldrig från produktionens databas.
- Koden innehåller inga personliga värden, bara platshållare (`__NAMN__`) som deklareras i `cloudflare.example.env` och fylls i av `tools/render.mjs` vid deploy och av `docker/entrypoint.sh` i containern. Se regeln i `CLAUDE.md`. Uppdatera `CHANGELOG.md` och `version.txt` vid varje ny image.
- Lägg aldrig SMTP-/OAuth-credentials, API-nycklar, krypteringsnycklar eller andra secrets i repository, logs eller publik dokumentation.
