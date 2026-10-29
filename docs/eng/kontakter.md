# The contact register

The tools in `kontakter/` fill the D1 table `public_contacts` with public contact details. They run outside Cloudflare, on a computer or server of your own, because some sources need a real browser and verifying addresses needs outgoing port 25.

## Sources

The repo contains no contact lists and no lists of where the contacts are. Your source files live in a directory of your own outside the repo that `CONTACT_SOURCES_DIR` points to; the format and made-up examples are in `kontakter/sources.example/`.

Only addresses that the organization itself publishes for exactly that purpose are included. The only exception is a municipality that itself states that addresses follow the pattern `firstname.lastname@domain` (the source type `namnmonster`); the addresses are then built from the names on the municipality's own page. For academics, the address must belong to the same university as the source page.

## Settings

| Variable | Meaning |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | The account the D1 database lives in. |
| `CLOUDFLARE_API_TOKEN` | Token with the D1 permission *Edit*. |
| `D1_DATABASE_UUID` | The database's id (alias: `D1_DATABASE_ID`). |
| `CONTACT_SOURCES_DIR` | The directory with your source files. |

The scripts that use D1's HTTP API read the variables from the environment. `sanitize_d1.py` and `backfill_assignments.py` run `wrangler d1 execute --remote` and use the token wrangler has.

## The tools

| Script | Does |
| --- | --- |
| `scraper.py` | Reads municipalities and regions (Netpublicator, Troman and pages with `mailto` links) in a container with a browser. |
| `sync_to_d1.py` | Syncs the result from `scraper.py` to D1. |
| `backfill_assignments.py` | Links municipal and regional politicians to committees and boards. |
| `fetch_riksdagen_members.py` | The members of the Riksdag (Swedish parliament) from the Riksdag's open API. |
| `fetch_eu_meps.py` | Sweden's members of the European Parliament from the Parliament's open API. |
| `sync_regeringen.py` | The ministries' registry addresses. |
| `fetch_kyrka.py` | The Church of Sweden's elected representatives from the pages in `kyrka.json`. |
| `fetch_media.py` | The newsrooms' contact channels. |
| `fetch_academics.py` | Academic professional contacts. `--dry-run` shows the selection without writing to D1. |
| `sync_party_from_val.py` | Fills in the party for municipal and regional politicians from the Election Authority's open data. |
| `sanitize_d1.py` | Normalizes and cleans the register without fetching anything new. `--apply` writes the changes. |
| `verify/verify_emails.py` | Checks the addresses against the recipients' mail servers without sending anything. |

## The quarterly run

`kontakter/scraper/quarterly_refresh.sh` runs every tool in the right order and last `sanitize_d1.py --apply`. It is meant to be scheduled every three months. If the scheduler uses a file with the variables, it sets `POLITIKER_ENV_FILE` to that file; the script stops if `CONTACT_SOURCES_DIR` is missing.

## Tests

```bash
cd kontakter
pip install -r requirements-dev.txt requests pypdf dnspython
python -m pytest -q
```
