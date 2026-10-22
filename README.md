# PolitikerKontakt

**Dokumentation:** [vinedrinker.github.io/politiker](https://vinedrinker.github.io/politiker/) – start, dokumentation och Docker på en sida med sök.

PolitikerKontakt låter dig skriva till politiker, myndigheter, redaktioner och forskare från ditt eget e-postkonto. Du väljer mottagare ur ett offentligt register eller dina egna kontaktlistor, skriver brevet och skickar det. Varje mottagare får ett eget mejl från din adress.

Det körs som en Cloudflare Worker med D1, KV, R2, en kö och en Durable Object, eller som en färdig Docker-image. Verktygen i `kontakter/` håller det offentliga registret uppdaterat.

## Tester

Från `app/`:

```bash
npm ci
npm run validate
```

`validate` kör testerna, syntaxkontrollen av skripten i `public/`, de lokala D1-migreringarna, typkontrollen och en torrkörning av driftsättningen. Verktygen i `kontakter/` testas med `python -m pytest -q` i den katalogen.

## Dokumentation

Börja i [översikten](docs/oversikt.md).

- [Arkitektur](docs/architecture.md): bindningar, state, utskick och säkerhet
- [Drift](docs/operations.md): migreringar, driftsättning och felsökning
- [Kontaktregistret](docs/kontakter.md): verktygen som fyller det offentliga registret

## Driftsätta på ett eget Cloudflare-konto

Koden innehåller inga kontouppgifter. Där ett eget värde behövs, som domän, resurs-id eller nycklar, står en platshållare (`__NAMN__`). Alla platshållare finns i `cloudflare.example.env`, med en kommentar om var värdet hämtas. Värdena hamnar bara i Cloudflare, aldrig i repot.

**Alternativ 1: deploy från din egen dator.**

1. Skapa resurserna: D1-databasen (`npx wrangler d1 create <namn> --jurisdiction eu`), KV-namnrymden för sessioner, R2-bucketen `politiker-attachments` och köerna `politiker-send-jobs` och `politiker-send-jobs-dlq`.
2. Kopiera `cloudflare.example.env` till en egen fil utanför repot och fyll i dina värden.
3. Rendera en kopia med dina värden: `node tools/render.mjs <din-fil.env> build`. Verktyget stoppar om ett värde saknas.
4. Lägg in hemligheterna en gång med `npx wrangler secret put <NAMN> --cwd build/app`: `MAIL_CRED_KEY`, `LETTER_DATA_KEY`, `SYSTEM_SMTP_PASSWORD`, `TURNSTILE_SECRET` och, om du använder dem, OAuth-klienternas hemligheter.
5. Kör databasmigreringarna: `npx wrangler d1 migrations apply DB --remote --cwd build/app`.
6. Deploya: `npx wrangler deploy --cwd build/app`, och radera sedan `build/`.

**Alternativ 2: Workers Builds med GitHub-koppling.** Lägg in värdena som *build variables* i Cloudflare (Workers → din Worker → Settings → Build), sätt byggkommandot till `node tools/render.mjs - build && (sh tools/docs-cloudflare.sh build/app/public || echo "docs skipped")` och deploykommandot till `npx wrangler deploy --cwd build/app`. Bygg bara produktionsgrenen. Workers Builds kör inte migreringarna; se [Drift](docs/operations.md).

## Köra med Docker

PolitikerKontakt finns som färdig image, `docker.io/driftaegis/politiker`. Alla inställningar beskrivs i [docker/README.md](docker/README.md). Imagen byggs från repots rot med `docker build -t politiker .`, och ändringarna listas i [CHANGELOG.md](CHANGELOG.md).

## Bidra

Frågor och idéer tas i [Discussions](https://github.com/VineDrinker/.github/discussions), fel och förslag som issues här. Läs [CONTRIBUTING.md](https://github.com/VineDrinker/.github/blob/main/CONTRIBUTING.md) innan du öppnar en pull request. Säkerhetsproblem rapporteras privat via fliken Security.

## Licens

MIT, se [LICENSE](LICENSE).
