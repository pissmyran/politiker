# Kontaktregistret

Verktygen i `kontakter/` fyller D1-tabellen `public_contacts` med offentliga kontaktuppgifter. De körs utanför Cloudflare, på en egen dator eller server, eftersom en del källor kräver en riktig webbläsare och verifieringen av adresser behöver utgående port 25.

## Källor

Repot innehåller inga kontaktlistor och inga listor över var kontakterna finns. Dina källfiler ligger i en egen katalog utanför repot som `CONTACT_SOURCES_DIR` pekar ut; format och påhittade exempel finns i `kontakter/sources.example/`.

Bara adresser som organisationen själv publicerar för just det syftet tas med. Det enda undantaget är en kommun som själv skriver att adresserna följer mönstret `fornamn.efternamn@domän` (källtypen `namnmonster`); då byggs adresserna från namnen på kommunens egen sida. För akademiker måste adressen höra till samma lärosäte som källsidan.

## Inställningar

| Variabel | Betydelse |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Kontot som D1-databasen ligger i. |
| `CLOUDFLARE_API_TOKEN` | Token med D1-behörigheten *Edit*. |
| `D1_DATABASE_UUID` | Databasens id (alias: `D1_DATABASE_ID`). |
| `CONTACT_SOURCES_DIR` | Katalogen med dina källfiler. |

Skripten som använder D1:s HTTP-API läser variablerna ur miljön. `sanitize_d1.py` och `backfill_assignments.py` kör `wrangler d1 execute --remote` och använder det token wrangler har.

## Verktygen

| Skript | Gör |
| --- | --- |
| `scraper.py` | Läser kommuner och regioner (Netpublicator, Troman och sidor med `mailto`-länkar) i en container med webbläsare. |
| `sync_to_d1.py` | Synkar resultatet från `scraper.py` till D1. |
| `backfill_assignments.py` | Kopplar kommun- och regionpolitiker till nämnder och styrelser. |
| `fetch_riksdagen_members.py` | Riksdagens ledamöter från riksdagens öppna API. |
| `fetch_eu_meps.py` | Sveriges ledamöter i Europaparlamentet från parlamentets öppna API. |
| `sync_regeringen.py` | Departementens registratorsadresser. |
| `fetch_kyrka.py` | Svenska kyrkans förtroendevalda från sidorna i `kyrka.json`. |
| `fetch_media.py` | Redaktionernas kontaktvägar. |
| `fetch_academics.py` | Akademiska yrkeskontakter. `--dry-run` visar urvalet utan att skriva till D1. |
| `sync_party_from_val.py` | Fyller i parti för kommun- och regionpolitiker från Valmyndighetens öppna data. |
| `sanitize_d1.py` | Normaliserar och rensar registret utan att hämta något nytt. `--apply` skriver ändringarna. |
| `verify/verify_emails.py` | Kontrollerar adresserna mot mottagarnas e-postservrar utan att skicka något. |

## Kvartalskörningen

`kontakter/scraper/quarterly_refresh.sh` kör alla verktygen i rätt ordning och sist `sanitize_d1.py --apply`. Den är tänkt att schemaläggas var tredje månad. Om schemaläggaren använder en fil med variablerna sätter den `POLITIKER_ENV_FILE` till den filen; skriptet stoppar om `CONTACT_SOURCES_DIR` saknas.

## Tester

```bash
cd kontakter
pip install -r requirements-dev.txt requests pypdf dnspython
python -m pytest -q
```
