# AGENTS.md

## Läs först

- [CLAUDE.md](CLAUDE.md): gemensamma regler för arbetssätt, deploy, loggning, kostnader och Docker. Arbetet sker på en egen gren per session; `main` ändras bara genom en PR från den grenen med squash merge.
- [docs/architecture.md](docs/architecture.md): bindningar, state, utskick och säkerhet.
- [docs/operations.md](docs/operations.md): tester, migreringar och felsökning.
- [docs/kontakter.md](docs/kontakter.md): verktygen för kontaktregistret.

## Regler som alltid gäller

- När du ändrar kod: förenkla och städa det du rör, så länge det inte breddar ändringen eller ändrar beteendet. Ta bort gammal kompatibilitetskod först när det är bekräftat att inget använder den.
- D1 är den enda sanningen. KV, R2, kön och Durable Object har var sin avgränsad roll.
- `CredentialRateLimiter` styr takten per e-postkonto och hanterar ett anrop i taget; ersätt den aldrig med state i KV eller i processen.
- Schemaändringar görs bara som migreringar i `infra/migrations/`.
- Cron varje minut ska vara billig: indexerade frågor med `LIMIT` och inget arbete när kön är tom.
- Kör `cd app && npm run typecheck && npx node@24 --experimental-strip-types --test tests/*.test.ts` före push.
- Behåll maskeringen av frågesträngar och den gemensamma loggprofilen i `CLAUDE.md`.
- Egen installation (Docker): `TURNSTILE_SECRET=off` stänger av bot-kontrollen, och utan systemmejl verifieras nya konton direkt. Imagen startar tom och läser aldrig från någon annans databas.
- Inga personliga värden i koden, bara platshållare (`__NAMN__`) som deklareras i `cloudflare.example.env`. Uppdatera `CHANGELOG.md` och `version.txt` vid varje ny image.
- Inloggningsuppgifter, API-nycklar och krypteringsnycklar hamnar aldrig i Git, loggar eller publik dokumentation.
