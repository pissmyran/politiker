# Politiker

**Dokumentation:** [vinedrinker.github.io/politiker](https://vinedrinker.github.io/politiker/) – start, dokumentation och Docker på en sida med sök.

Politiker är en Cloudflare-baserad webbapplikation för konton, kontakt-/mottagardata, brev och utskick. Repositoryt innehåller både applikationsruntime och verktyg för att underhålla dess data.

## Snabb verifiering

Från `app/`:

```bash
npm ci
npm run validate
```

`validate` kör tester, produktionsverifieringstester, JavaScript-kontroller, lokala D1-migrationer, Wrangler types, TypeScript typecheck och Worker dry-run.

## Dokumentation

Börja i **[dokumentationsöversikten](docs/oversikt.md)**.

- [Projektkontext](docs/project-context.md) — runtime, state och subsystem
- [Arkitektur](docs/architecture.md) — request-, auth-, lagrings- och utskicksflöden
- [Drift](docs/operations.md) — verifiering, migrationer, queue/DLQ och deployment

README hålls medvetet kort. Detaljerad teknisk dokumentation ligger under `docs/`.

## Runtime i korthet

Applikationen använder D1, KV, Queue + DLQ, Durable Object, R2, Cloudflare Email och schemalagd Worker-körning. Dessa lager har olika ansvar och ska inte behandlas som utbytbara state stores.

## Operator-wizard

Provider-/credentialförutsättningar verifieras utan att exportera eller skriva secretvärden:

```bash
bash scripts/setup-provider-credentials.sh
```

Wizarden är human-only och skapar eller roterar inga credentials.

## Driftsätta på ett eget Cloudflare-konto

Koden innehåller inga kontouppgifter. Där ett eget värde behövs, som domän, resurs-id eller nycklar, står en platshållare (`__NAMN__`). Alla platshållare finns i `cloudflare.example.env`, med en kommentar om var värdet hämtas. Värdena hamnar bara i Cloudflare, aldrig i repot.

**Alternativ 1: deploy från din egen dator (standard).**

1. Kopiera `cloudflare.example.env` till en egen fil utanför repot och fyll i dina värden.
2. Rendera en kopia med dina värden: `node tools/render.mjs <din-fil.env> build [overlay-katalog]`. Verktyget stoppar om ett värde saknas. Filer i overlay-katalogen kopieras ovanpå, till exempel egna bilder.
3. Lägg in hemligheter en gång, antingen var för sig med `npx wrangler secret put <NAMN>` eller alla på en gång från en JSON-fil med `npx wrangler secret bulk <fil.json>`. Radera filen efteråt.
4. Kör databasmigreringarna (se `docs/`) och deploya: `npx wrangler deploy --cwd build/app`.
5. Radera `build/`. Cloudflare har nu värdena. Vill du ändra något fyller du i filen igen och upprepar steg 2 och 4.

**Alternativ 2: Workers Builds med GitHub-koppling.** Lägg in värdena som *build variables* i Cloudflare (Workers → din Worker → Settings → Build), sätt byggkommandot till `node tools/render.mjs - build` och deploykommandot till `npx wrangler deploy --cwd build/app`. Bygg bara produktionsgrenen (stäng av bygg för andra grenar), så skapas inga förhandsversioner. Hemligheter läggs in som i alternativ 1.

## Köra med Docker

Kopiera `docker-compose.yml`, fyll i värdena och kör `docker compose up -d`. Alla inställningar beskrivs i [docker/README.md](docker/README.md). Vill du inte ha värdena i compose-filen kan du lägga dem som `NAMN=värde`-rader i `import.env` i datakatalogen och starta om. Containern sparar dem i `settings.env`, som bara containern kan läsa, och raderar importfilen. Imagen byggs från repots rot med `docker build -t politiker .`.

## Bidra

Frågor och idéer tas i [Discussions](https://github.com/VineDrinker/.github/discussions), fel och förslag som issues här. Läs [CONTRIBUTING.md](https://github.com/VineDrinker/.github/blob/main/CONTRIBUTING.md) innan du öppnar en pull request. Säkerhetsproblem rapporteras privat via fliken Security.
