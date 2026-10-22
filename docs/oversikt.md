# Översikt

```text
Webbläsare
    |
    v
app/src/access-index.ts    yttre gräns: routing och säkerhetshuvuden
    |
    v
app/src/index.ts ──> D1         konton, brev, utskick, kontaktregistret
    |            ──> KV         sessioner
    |            ──> R2         bilagor
    |            ──> Email      systemmejl
    v
Kö (SEND_QUEUE) ──> CredentialRateLimiter ──> din e-post (SMTP, Google, Microsoft)
    |
    └──> DLQ
```

Cron kör varje minut och lägger om väntande utskick i kön.

| Ämne | Sida |
| --- | --- |
| Bindningar, state, utskick, säkerhet och tema | [Arkitektur](architecture.md) |
| Tester, migreringar, driftsättning och felsökning | [Drift](operations.md) |
| Verktygen som fyller det offentliga kontaktregistret | [Kontaktregistret](kontakter.md) |

## Vem äger vilken data

- **D1** är den enda sanningen: konton, brev, utskick, egna kontakter och det offentliga registret `public_contacts`.
- **KV** innehåller bara sessioner.
- **R2** innehåller bara bilagornas bytes; metadata ligger i D1.
- **Kön och DLQ** är transport. De ersätter aldrig utskickens state i D1.
- **Durable Object** `CredentialRateLimiter` styr takten per e-postkonto.
- **De statiska filerna** är presentation.

## Innan du ändrar något

- **Inloggning, sessioner eller API:** läs [Arkitektur](architecture.md) och kör testerna.
- **D1-schemat:** skriv en ny migrering i `infra/migrations/` och läs [Drift](operations.md).
- **Utskick, kön eller takten:** läs [Arkitektur](architecture.md) och felsökningen i [Drift](operations.md).
- **Kontaktregistret:** läs [Kontaktregistret](kontakter.md).
