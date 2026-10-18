# Källfiler för kontaktinsamlingen

Koden innehåller inga kontaktlistor och inga listor över var kontakterna finns. Det lägger du själv i en egen katalog utanför repot, och pekar ut den med miljövariabeln `CONTACT_SOURCES_DIR`:

```bash
cp -r kontakter/sources.example ~/mina-kallor
export CONTACT_SOURCES_DIR=~/mina-kallor
```

Filerna här är exempel med påhittade adresser på reserverade exempeldomäner. Byt ut dem mot riktiga, offentliga källor.

| Fil | Används av | Innehåll |
|---|---|---|
| `regioner.json` | `scraper.py`, `backfill_assignments.py` | En post per kommun eller region: namn, vilken publiceringsplattform sidan använder (`typ`) och var sidan finns. Fälten för varje typ syns i exemplet. |
| `media.json` | `fetch_media.py` | Redaktionernas fasta funktionsadresser (`contacts`), personalsidor där namn och befattning står före adressen (`staff_pages`), sidor med publicerade yrkesadresser (`public_email_pages`) och politiksektioner där artikelförfattarnas adresser hämtas (`section_authors`). |
| `academics.json` | `fetch_academics.py` | Akademiska yrkeskontakter med lärosäte, institution, titel, område (`political-science`, `public-administration`, `public-law`) och källsidan där adressen publiceras. Adressen måste höra till samma lärosäte som källsidan. |
| `kyrka.json` | `fetch_kyrka.py` | Basadress och de sidor med förtroendevalda som läses, med vilket område varje sida hör till. |

Ta bara med adresser som organisationen själv publicerar för just det syftet. Gissa aldrig adresser från namn.
