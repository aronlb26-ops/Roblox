# 🌱 Trädgårdsfeber

Ett trendigt odlingsspel för Roblox i stil med *Grow a Garden*. Plantera frön, vänta på att de växer, skörda frukterna och sälj dem för mynt. Använd mynten till sällsyntare frön, och håll utkik efter väder som ger dina plantor värdefulla mutationer.

## Funktioner

- **Egen trädgård:** varje spelare får en tomt med 5×5 odlingsrutor och sitt namn på skylten (max 6 spelare per server).
- **10 frön i 6 sällsynthetsnivåer:** från 🥕 Morot (Vanlig) till 🌵 Kosmisk Kaktus (Mytisk). Vissa plantor ♻️ växer om efter skörd.
- **Butiker som fylls på:** fröbutiken och redskapsbutiken får nytt, slumpat lager var 5:e minut. Legendariska och mytiska frön annonseras när de finns i lager.
- **Väderhändelser:** 🌧️ Regn, ❄️ Snöstorm, ⛈️ Åskväder (med blixtar), 🌅 Gyllene timmen och 🌈 Regnbågsnatt. De har egna ljus- och partikeleffekter.
- **Mutationer:** Blöt (x2), Frusen (x10), Guld (x20), Regnbåge (x50, skiftar färg) och Elektrisk (x100).
- **🦣 ENORMA frukter:** 1 % chans att en frukt blir 2,5–4 gånger större och mer värd.
- **Redskap:** 💧 Vattenkanna (snabbare växande) och ✨ Guldgödsel (gör en planta till Guld).
- **Ryggsäck** med plats för 200 frukter, grupperade efter sort och mutation.
- **Sparning** via DataStore. Plantorna fortsätter växa även när du är offline.
- **Topplista** med Mynt och Skördat.
- Gränssnittet är på svenska och fungerar på både dator och mobil.

## Så spelar man

1. Välj ett frö i verktygsfältet längst ner (eller tryck **1–9**).
2. Klicka på en tom jordruta i din trädgård för att plantera.
3. Klicka på plantan när den är ✅ redo, så hamnar frukten i ryggsäcken (**B**).
4. Gå till 💰-ståndet och sälj allt.
5. Köp bättre frön i 🌱 Fröbutiken och 🧰 Redskap.

Knapparna till vänster teleporterar dig mellan trädgården och stånden. Använd 🪏 Spaden för att gräva upp en planta.

## Kom igång

Projektet använder [Rojo](https://rojo.space). Kartan byggs helt med kod, så du behöver ingen `.rbxl`-fil.

```bash
# Installera verktygen (rojo + selene) med Rokit
rokit install

# Starta live-synk och anslut från Rojo-pluginet i Roblox Studio
rojo serve

# …eller bygg en placefil direkt
rojo build -o Tradgardsfeber.rbxl
```

Öppna en tom Baseplate i Studio, anslut via Rojo-pluginet och tryck **Play**.

> **Sparning i Studio:** slå på *Game Settings → Security → Enable Studio Access to API Services* för att testa DataStore. Utan det fungerar spelet ändå, men inget sparas.
>
> **Serverstorlek:** sätt max antal spelare till **6** när du publicerar (en trädgård per spelare).

## Struktur

```
src/
├── shared/Config.luau          Frön, redskap, mutationer, väder och all balans
├── server/
│   ├── Main.server.luau        Startpunkt: kopplar ihop alla system
│   ├── World.luau              Bygger kartan: mark, tomter, stånd, träd
│   ├── Garden.luau             Plantering, växande, skörd, mutationer
│   ├── Shop.luau               Butikslager, köp och försäljning
│   ├── Weather.luau            Väderhändelser och ljus
│   ├── PlayerData.luau         DataStore-laddning och sparning
│   └── Net.luau                Remotes och tillståndssynk till klienten
└── client/UI.client.luau       Hela gränssnittet och vädereffekterna
```

Vill du balansera spelet ändrar du `src/shared/Config.luau`: priser, växttider, butikschanser och mutationschanser finns där.
