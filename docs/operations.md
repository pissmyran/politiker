# Drift

## Kontroller före push

Från `app/`:

```bash
npm ci
npm run validate
```

`validate` kör enhetstesterna, testerna av produktionskontrollen, syntaxkontrollen av skripten i `public/`, de lokala D1-migreringarna, typgenereringen, typkontrollen och `wrangler deploy --dry-run`.

För `kontakter/`: `pip install -r requirements-dev.txt requests pypdf dnspython` och `python -m pytest -q` i den katalogen.

## Lokal utveckling

```bash
cd app
npm run dev
```

## Driftsättning

Produktionen driftsätts från en renderad kopia, antingen från din dator eller med Workers Builds när en PR mergas till `main`; se `README.md`. CI på GitHub kör tester, Docker-bygge och CodeQL. Det finns ingen förhandsmiljö. Kontaktregistret uppdateras separat, inte vid driftsättning.

## Migreringar

Migreringarna ligger i `infra/migrations/`. Workers Builds kör dem inte, så de körs för hand från en renderad kopia:

```bash
node tools/render.mjs <din-fil.env> build
npx wrangler d1 migrations apply DB --remote --cwd build/app
```

1. Schemaändringar görs bara med nya migreringar.
2. En migrering som lägger till körs före deployen av den nya Workern, en som tar bort efter.
3. Kör `npm run validate` först; den provar migreringarna lokalt.

## Kontroll efter driftsättning

```bash
node build/scripts/verify-production.mjs
```

Den kontrollerar att startsidan svarar `200`, och skiljer en blockering i Cloudflares kant (till exempel en utmaning) från ett fel i Workern. Varje kontroll görs upp till fem gånger.

## Felsökning av utskick

Kontrollera i den här ordningen:

1. utskickets state i D1;
2. kön: väntande jobb och nya försök;
3. DLQ;
4. `CredentialRateLimiter` och e-postkontots gräns;
5. felet från e-postleverantören.

Kör aldrig om ett jobb i kön först; utskickets state i D1 och kön måste stämma överens, annars kan ett brev skickas två gånger.

### Fel på ett sparat e-postkonto

1. **Bekräfta inloggningen:** känsliga åtgärder kräver en inloggning som är högst 15 minuter gammal. Sidan ber om lösenord och tvåstegsverifiering, eller skickar ett konto som bara använder Google eller Microsoft dit, utan att du loggas ut.
2. **"Det sparade SMTP-lösenordet kan inte dekrypteras":** det sparade lösenordet går inte att läsa med nuvarande `MAIL_CRED_KEY`. Byt aldrig `MAIL_CRED_KEY` för att felsöka; använd **Uppdatera lösenord**, som provar och krypterar om lösenordet.
3. **Fel `535` från servern:** SMTP-servern avvisade inloggningen. Många leverantörer kräver ett appspecifikt lösenord.
4. **Leverans:** först när kontot loggar in är det dags att titta på utskickets state, kön och mottagarnas svar.

**Uppdatera lösenord** provar det nya lösenordet mot servern innan det sparas, så ett misslyckat försök ändrar inget.

## Bilagor

Kontrollera bindningen, objektnyckeln och kopplingen i D1 innan något raderas eller skrivs om i R2. Använd aldrig bilagornas innehåll för felsökning.

## Inloggning och sessioner

Kontrollera i den här ordningen: route, sessionen i KV, kontot i D1 och sist lösenords-, TOTP- eller OAuth-flödet. Gör aldrig en privat route publik för att lösa ett inloggningsfel.

Lägg aldrig inloggningsuppgifter, nycklar, mejlinnehåll eller privata API-data i loggar.
