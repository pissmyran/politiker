# PolitikerKontakt

PolitikerKontakt gör det enkelt att skriva till politiker och andra förtroendevalda, en eller många på en gång, från ditt eget e-postkonto. Breven skickas från din adress, så svaren kommer direkt till dig. Användare skapar egna konton, kan importera brev från Word eller PDF, och väljer mottagare per nivå, till exempel riksdag, region och kommun.

Imagen startar tom: det finns inga konton och ingen kontaktkatalog. Du behöver inget Cloudflare-konto.

## Kom igång

Imagen ligger på Docker Hub som `docker.io/driftaegis/politiker`. Compose-filen nedan hämtar den därifrån, så du behöver varken klona repot eller bygga något.

1. **Installera Docker.** På Windows och Mac: [Docker Desktop](https://www.docker.com/products/docker-desktop/). På Linux: paketet `docker.io` (Debian/Ubuntu) eller motsvarande. Podman fungerar också.
2. **Skapa en mapp** och en fil i den som heter `docker-compose.yml`. Klistra in innehållet nedan.
3. **Fyll i** `PUBLIC_HOST` (värdnamnet sidan nås på) och `ADMIN_EMAIL` (din e-postadress).
4. **Starta** i den mappen: `docker compose up -d`
5. **Registrera ett konto.** Öppna `http://localhost:8787` och registrera dig med adressen i `ADMIN_EMAIL`. Inom en minut blir kontot administratör.
6. **Koppla din e-post.** Lägg in dina SMTP-uppgifter i kontot, eller logga in med Google eller Microsoft om du har satt upp det. Sedan kan du lägga till mottagare och skicka.

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

## Två sorters e-post

- **Användarnas brev** skickas alltid från användarens eget konto, via SMTP eller via inloggning med Google eller Microsoft. Inloggningsuppgifterna krypteras i databasen.
- **Systemmejl**, alltså verifieringskoder och lösenordsåterställning, skickas från `SYSTEM_FROM_ADDRESS` via `SYSTEM_SMTP_*`. Är systemmejl inte inställt verifieras nya konton direkt, och lösenordsåterställning finns inte. Det räcker för en installation i en liten grupp. För en öppen sida bör du ställa in systemmejl.

## Inställningar

| Variabel | Krävs | Standard | Betydelse |
|---|---|---|---|
| `PUBLIC_HOST` | Ja | `localhost` | Värdnamnet utan `https://`. Används i länkar, e-post, inloggning med Google och Microsoft och tvåfaktorkoder. |
| `ADMIN_EMAIL` | Rekommenderas | – | Kontot med den här adressen blir administratör och markeras som verifierat. |
| `SYSTEM_FROM_ADDRESS` | Nej | `noreply@example.com` | Avsändare för systemmejl. |
| `SYSTEM_SMTP_HOST`, `SYSTEM_SMTP_PORT`, `SYSTEM_SMTP_USER`, `SYSTEM_SMTP_PASSWORD` | Nej | port `587` | SMTP-server för systemmejl. Port 587 (STARTTLS) eller 465 (TLS). |
| `RESEND_API_KEY` | Nej | – | Alternativ till SMTP för systemmejl, via [Resend](https://resend.com). |
| `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET` | Nej | `off` | Cloudflare Turnstile mot bot-registreringar (gratis, kräver ett Cloudflare-konto). `off` stänger av kontrollen. Rekommenderas för en publik sida. |
| `TURNSTILE_HOSTNAMES` | Nej | `PUBLIC_HOST` | Värdnamn som Turnstile-svaret får komma från. |
| `OAUTH_GOOGLE_CLIENT_ID`, `OAUTH_GOOGLE_CLIENT_SECRET` | Nej | – | "Logga in med Google". Redirect-adress: `https://<PUBLIC_HOST>/api/oauth/google/callback`. |
| `OAUTH_MICROSOFT_CLIENT_ID`, `OAUTH_MICROSOFT_CLIENT_SECRET` | Nej | – | "Logga in med Microsoft" och utskick via Outlook. Redirect-adresser: `https://<PUBLIC_HOST>/api/oauth/microsoft/callback` och `https://<PUBLIC_HOST>/api/oauth-mail/microsoft/callback`. |
| `FEEDBACK_NOTIFY_EMAIL` | Nej | – | Adress som får användarnas feedback. |
| `MAIL_CRED_KEY` | Nej | skapas automatiskt | Nyckel som krypterar användarnas e-postuppgifter. Skapas första gången och sparas i `/data/mail-cred-key`. |
| `LETTER_DATA_KEY`, `VISITOR_SALT` | Nej | `MAIL_CRED_KEY` | Separata nycklar för brevinnehåll och besöksstatistik. |
| `PORT` | Nej | `8787` | Porten inne i containern. |

### Inställningar från en fil i stället

Vill du inte ha värden som lösenord i compose-filen lägger du dem som `NAMN=värde`-rader i filen `import.env` i datavolymen (den som monteras på `/data`) och startar om containern. Vid starten sparas värdena i `/data/settings.env`, som bara containern kan läsa, och `import.env` raderas. För att ändra ett värde senare lägger du en ny `import.env` med bara den raden. En rad med `NAMN=` och inget värde tar bort inställningen. Värden som är ifyllda i compose-filen gäller före sparade värden.

## Data, säkerhetskopiering och uppdatering

- Allt ligger i volymen som är monterad på `/data`:
  - databasen (SQLite) med konton, kontakter och utskick,
  - sessioner,
  - bilagor,
  - den automatiskt skapade nyckeln.
- **Säkerhetskopiera:** `docker compose stop`, kopiera volymen och kör `docker compose start`. Följ med `/data/mail-cred-key`, annars går användarnas sparade e-postuppgifter inte att läsa.
- **Uppdatera:** `docker compose pull && docker compose up -d`. Databasmigreringar körs automatiskt vid start.
- **Versioner:** taggarna följer semver. Projektet är i version 0, så `0` följer alla uppdateringar. Vill du bara ha rättningar väljer du `0.11`, och för en exakt version `0.11.0`.

## HTTPS

Containern talar vanlig HTTP på port 8787. Lägg den bakom en omvänd proxy med certifikat, till exempel Caddy, Traefik eller nginx, eller använd en Cloudflare Tunnel. Inloggning med Google och Microsoft kräver HTTPS.

## Teknisk översikt

- **Runtime:** PolitikerKontakt är skrivet som en Cloudflare Worker. I containern körs den i `workerd`, samma runtime som Cloudflare använder, via `wrangler dev --local` (Miniflare). D1 (SQLite), KV, R2, utskickskön och Durable Object-räknaren för inloggningsförsök körs alla lokalt, med tillstånd under `/data`.
- **Schemaläggning:** `wrangler dev` startar inte cron-körningar av sig själv. Därför anropar `docker/scheduler.mjs` den schemalagda körningen varje minut. Den lägger om väntande utskick i kön och gör `ADMIN_EMAIL` till administratör.
- **Utskick:** de går via en kö med ett meddelande i taget och en dead letter-kö. SMTP körs över `cloudflare:sockets`. Utskick per användare och dygn är begränsade.
- **Säkerhet:**
  - Lösenord hashas.
  - Tvåfaktorinloggning (TOTP) och API-nycklar finns.
  - Inloggningsförsök begränsas i en serialiserad Durable Object.
  - Användarnas e-postuppgifter och brevinnehåll krypteras med AES-GCM.
  - Ändrande anrop kräver same-origin, och svaren har strikt CSP.
- **Imagen** bygger på `node:24-trixie-slim` (Node LTS på Debian stable), kör som användaren `node` och har en healthcheck. Den innehåller bara källkod med platshållare; dina värden fylls i när containern startar.
- **Begränsningar:** `wrangler dev` är en utvecklingsserver som kör en process på en maskin. Det räcker för en grupp eller förening, men ger inte Cloudflares skalning. Kontaktkatalogen med politiker ingår inte, utan fylls av administratören eller användarna.
- **Felsökning:** `docker compose logs -f`. Administratören ser utskick, konton och statistik i adminvyn.

## Changelog

**0.12.2**
- `tools/render.mjs` skriver varje ifylld fil i en loop tills alla byte är skrivna, så att en kort skrivning inte kan lämna en avkortad fil.

**0.12.1**
- `tools/render.mjs` läser och skriver varje fil genom samma filbeskrivare, så att filen inte kan bytas ut mellan kontroll och skrivning.

**0.12.0**
- Inställningar kan ges en gång i `/data/import.env` i stället för i compose-filen. De sparas i `/data/settings.env` och importfilen raderas.
- Imagen byggs från projektets eget repo: `docker build -t politiker .`.

**0.11.0**
- Första Docker-imagen, med D1, KV, R2, kön och Durable Object lokalt under `/data`. Migreringarna körs vid start, och kontaktkatalogen är tom.
- `ADMIN_EMAIL`: kontot med den adressen blir administratör.
- Utan systemmejl verifieras nya konton direkt i stället för att registreringen misslyckas.
- `TURNSTILE_SECRET=off` stänger av bot-kontrollen, och en tom nyckel döljer widgeten.
- Nyckeln för e-postuppgifterna skapas automatiskt första gången.

## Licens

MIT.
