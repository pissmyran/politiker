# Arkitektur

## Runtime

Workern `politiker` startar i `app/src/access-index.ts` och konfigureras i `app/wrangler.jsonc`:

| Bindning | Typ | Används till |
| --- | --- | --- |
| `DB` | D1 | Allt state, med migreringarna i `infra/migrations/` |
| `SESSIONS` | KV | Sessioner |
| `ATTACHMENTS` | R2 (`politiker-attachments`) | Bilagor |
| `SEND_QUEUE` | Kö (`politiker-send-jobs`) | Utskick, ett i taget, upp till tio försök och sedan `politiker-send-jobs-dlq` |
| `RATE_LIMITER` | Durable Object (`CredentialRateLimiter`) | Takten per e-postkonto |
| `EMAIL` | Email | Systemmejl från `SYSTEM_FROM_ADDRESS` |
| `ASSETS` | Statiska filer (`app/public/`) | Sidorna; Workern går först för `/`, `/api/*` och `/admin*` |

Hemligheter: `MAIL_CRED_KEY` och `LETTER_DATA_KEY` (krypteringsnycklar), `SYSTEM_SMTP_PASSWORD`, `TURNSTILE_SECRET`, OAuth-klienternas hemligheter och valfritt `RESEND_API_KEY`.

Cron `* * * * *` lägger om väntande utskick i kön. Den gör bara indexerade frågor med `LIMIT` och inget alls när inget väntar.

Loggning: alla loggar (sampling 1, med anropsloggar), spårningar till 1 %, frågesträngar maskeras och Workers Issues är på. Inloggnings- och API-flöden kan bära känsliga parametrar, så maskeringen får aldrig stängas av.

## Koden

- **`app/src/access-index.ts`** är den yttre gränsen och sätter policyn innan applikationen eller de statiska filerna svarar.
- **`app/src/index.ts`** är applikationen: konton, inloggning, API-nycklar, kontakter, brev, bilagor, utskick, köns konsument, feedback och admin.
- **`shared/`** är kod som både Workern och Docker-varianten använder: kryptering, TOTP, SMTP, Microsoft Graph, Resend och indatakontroller.

## Konton och sessioner

Konton och allt som hör till dem ligger i D1, sessionerna i KV. Inloggning sker med lösenord (med valfri TOTP) eller med Google eller Microsoft. Känsliga åtgärder, som att ändra ett sparat e-postkonto, kräver att inloggningen är högst 15 minuter gammal; annars ber sidan dig bekräfta igen.

## Det offentliga registret

`public_contacts` är det gemensamma registret: politiker på alla nivåer, myndigheter, redaktioner, Svenska kyrkan och akademiker. `area_type` skiljer grupperna åt. Akademiker har dessutom lärosäte, enhet, titel, område och källsida. `public_contact_assignments` kopplar kommun- och regionpolitiker till nämnder och styrelser för filtrering på sakområde.

Sökningen är `/api/public-contacts/search`; `/api/politicians/search` finns kvar som alias för äldre klienter.

Registret fylls av verktygen i `kontakter/`; se [Kontaktregistret](kontakter.md).

## Egna kontakter och inledningar

Varje konto kan ha egna kontaktlistor. Återanvändbara inledningar ligger i `letter_intro_presets`; rubriken sparas i klartext och texten krypterad, precis som brevet.

## Utskick

1. Ett utskick sparas i D1 och läggs i kön.
2. Köns konsument hämtar ett jobb i taget och frågar `CredentialRateLimiter` om e-postkontot får skicka nu.
3. Brevet personaliseras i ordningen personlig hälsning, valda inledningar och brevtext (`personalizeLetter`), och skickas från användarens eget konto via SMTP, Google eller Microsoft.

Inledningarna sparas krypterat på utskicket (`send_jobs.intro_text`) när det startar, så att en senare ändring av en mall inte påverkar ett pågående utskick. Brevets innehåll raderas automatiskt efter den tid användaren valt: 5 minuter, 1 dag, 3 dagar eller 7 dagar efter att utskicket är klart.

Kön och DLQ visar bara transportens tillstånd. Utskickets verkliga status finns i D1.

## Takten

`CredentialRateLimiter` är en Durable Object per e-postkonto. Eftersom den hanterar ett anrop i taget kan flera samtidiga Worker-anrop aldrig tillsammans skicka fortare än leverantörens gräns. Den får aldrig ersättas av state i KV eller i processen.

## Säkerhetsgränser

- Internet → den yttre gränsen i `access-index.ts`.
- Session eller API-nyckel → inloggningskontrollen.
- Applikationen → D1, KV och R2.
- Applikationen → kön → takten → e-postleverantören.
- Admin → uttrycklig behörighetskontroll.
- Känsliga API-svar cacheas aldrig.

## Tema och PWA

Det finns tre teman: `legacy` (standard), `forest` (med etiketten från `SITE_FAMILY`) och `blackout`. Valet sparas i `localStorage["<prefix>.theme"]` och cookien `<prefix>_theme`. Temaväljaren ligger längst ner på de publika sidorna. Temat ändrar bara utseendet; PolitikerKontakts egen gul-blå profil och statusfärger finns i alla teman.

Sidan har ett webbmanifest, ikoner i 192 och 512 pixlar och en service worker som alltid hämtar från nätet och aldrig cachear sessioner, data, bilagor eller utskick. Den är bara till för att sidan ska kunna installeras.
