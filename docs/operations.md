# Drift

## Lokal/full verifiering

Från `app/`:

```bash
npm ci
npm run validate
```

`validate` omfattar:

- enhetstester,
- produktionsverifieringstester,
- syntaxkontroller för frontend-JavaScript,
- lokala D1-migrationer,
- Wrangler type generation,
- TypeScript typecheck,
- Wrangler dry-run.

## Lokal utveckling

```bash
cd app
npm run dev
```

Använd lokal runtime för request- och API-förändringar innan produktion berörs.

## D1-migrationer

Migrationerna ligger i `infra/migrations/`.

Produktionsmigration:

```bash
cd app
npm run migrate:production
```

Före migration:

1. verifiera att migrationen är versionsstyrd;
2. verifiera att aktuell Worker-kod är kompatibel med både före- och efterstate där deploymentordningen kräver det;
3. kör lokal migration genom `npm run validate`.

För migration `0003_generalize_public_contacts.sql` var ordningen **migration först, därefter Worker-deploy**. Den skapade legacy-vyer för `politicians` och `politician_assignments` samt en begränsad compatibility-trigger för cutover. Current Worker och kontaktverktyg använder nu canonical `public_contacts` / `public_contact_assignments`. Migration `0005_drop_public_contact_legacy_views.sql` tar därför bort endast de tre temporära D1-objekten. Verifiera före production migration att current Worker-versionen är deployad och efter migration att canonical tabellerna finns kvar samt att legacyobjekten saknas.

## Queue/DLQ-felsökning

Vid leveransproblem, kontrollera i ordning:

1. persistent send-job-state i D1;
2. queue backlog/retries;
3. dead-letter queue;
4. `CredentialRateLimiter` och credentialgräns;
5. provider/mail-fel.

Manuell återkörning ska inte vara första åtgärd eftersom persistent state och queue-state måste vara konsistenta.

### SMTP-credential och autentiseringsfel

Felsök ett lagrat SMTP-konto i den här ordningen:

1. **Fresh session:** känsliga credential-operationer kräver en autentisering som är högst 15 minuter gammal. UI:t öppnar automatiskt **Bekräfta att det är du** och förnyar den befintliga webbsessionen efter lösenord/2FA-verifiering; användaren ska inte behöva logga ut. OAuth-only-konton skickas genom sitt länkade externa inloggningssätt utan föregående logout. SMTP-anropet startar först efter lyckad återautentisering.
2. **Dekryptering:** `Det sparade SMTP-lösenordet kan inte dekrypteras` betyder att den lagrade credentialen inte kan läsas med aktuell `MAIL_CRED_KEY`. Rotera inte `MAIL_CRED_KEY` som felsökningsåtgärd; använd **Uppdatera lösenord** för att testa och kryptera credentialen på nytt.
3. **SMTP-auth:** ett explicit providerfel som `535` betyder att SMTP-servern avvisade credentialen. För iCloud används `smtp.mail.me.com:587` med STARTTLS och ett appspecifikt lösenord.
4. **Leverans:** först när credentialen autentiserar ska D1 send-job-state, Queue/DLQ och mottagarspecifika SMTP-svar felsökas.

**Uppdatera lösenord** autentiserar det inmatade värdet mot den befintliga SMTP-host/user/from-konfigurationen innan `encrypted_password` och `verified_at` skrivs. Ett misslyckat test ändrar alltså inte den lagrade credentialen.

## R2/bilagor

Verifiera binding, objektkey och metadatarelation innan objekt raderas eller skrivs om. Objektinnehåll ska inte användas som generell debugdump.

## Auth/sessionproblem

Kontrollera:

1. request/accessroute;
2. sessionstate i KV;
3. motsvarande account/auth-state i D1;
4. relevant OAuth/TOTP/password-flöde.

Lös inte authfel genom att göra privata routes publika.

## Deployment

Produktion driftsätts från en renderad kopia med dina egna värden, se avsnittet om Cloudflare i `README.md`. I den renderade `app/`-katalogen:

1. `npm run validate`
2. `npm run migrate:production`
3. `npm run deploy`
4. `npm run verify:production`

CI på GitHub kör tester, Docker-bygge och CodeQL vid varje push till `main`. Det finns ingen förhandsmiljö. Kontaktdata, inklusive akademiker, uppdateras separat av kvartalskörningen i `kontakter/`, inte vid driftsättning.

## Observability

Persistent logs/traces använder sampling och query-string-redaction. Lägg inte credentials, tokens, mailinnehåll eller privata API-payloads i loggar.

## Underhållsscripts

Scripts under `kontakter/scraper/` är operativa verktyg, inte alternativa sources of truth. Verifiera target/config före D1-relaterade operationer och dokumentera nya underhållsflöden här.

Repot innehåller inga kontaktlistor och inga källkataloger. Skriptens källor (kommuner och regioner, redaktioner, akademiska kontakter, kyrkans sidor) ligger i JSON-filer i en egen katalog utanför repot som `CONTACT_SOURCES_DIR` pekar ut; format och exempel finns i `kontakter/sources.example/`. `quarterly_refresh.sh` stoppar om variabeln saknas.

`quarterly_refresh.sh` uppdaterar även akademiska yrkeskontakter via `fetch_academics.py`. Endast e-postadresser som lärosätena själva publicerar används, adressen måste höra till samma lärosäte som källsidan, och officiell `source_url` sparas per post. `--dry-run` visar urvalet utan D1-skrivningar.
