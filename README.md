# 🌱 Garden Fever

A trendy *Grow a Garden*-style farming game for Roblox. Plant seeds, wait for them to grow, harvest the fruit and sell it for coins. Spend the coins on rarer seeds, and watch the weather for events that give your plants valuable mutations.

## Features

- **Your own garden:** every player gets a plot with 5×5 soil tiles and their name on the sign (max 6 players per server).
- **10 seeds across 6 rarities:** from 🥕 Carrot (Common) to 🌵 Cosmic Cactus (Mythic). Some plants ♻️ regrow after harvesting.
- **Restocking shops:** the Seed Shop and Gear Shop get new random stock every 5 minutes. Legendary and Mythic seeds are announced when they're in stock.
- **Weather events:** 🌧️ Rain, ❄️ Snowstorm, ⛈️ Thunderstorm (with lightning flashes), 🌅 Golden Hour and 🌈 Rainbow Night. Each has its own lighting and particle effects.
- **Mutations:** Wet (x2), Frozen (x10), Gold (x20), Rainbow (x50, cycles colors) and Shocked (x100).
- **🦣 HUGE fruit:** 1% chance for a fruit to be 2.5–4× bigger and worth more.
- **Gear:** 💧 Watering Can (faster growth) and ✨ Gold Fertilizer (turns a plant Gold).
- **Backpack** that holds 200 fruits, grouped by type and mutation.
- **Saving** through DataStore. Plants keep growing while you're offline.
- **Leaderboard** with Coins and Harvested.
- The UI works on both desktop and mobile.

## How to play

1. Pick a seed in the hotbar at the bottom (or press **1–9**).
2. Click an empty soil tile in your garden to plant it.
3. Click the plant when it's ✅ ready, and the fruit goes into your backpack (**B**).
4. Walk to the 💰 stall and sell everything.
5. Buy better seeds at the 🌱 Seed Shop and 🧰 Gear Shop.

The buttons on the left teleport you between your garden and the stalls. Use the 🪏 Shovel to dig up a plant.

## How to test the game

The project is plain source code synced into Roblox Studio with [Rojo](https://rojo.space). The whole map is built by code, so you don't need a `.rbxl` place file.

### 1. Install the tools (one time)

1. Install **[Roblox Studio](https://create.roblox.com)**.
2. Install **Rojo**. Pick one option:
   - **VS Code (easiest):** install the *Rojo* extension in VS Code. It installs Rojo and the Studio plugin for you.
   - **Command line:** install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder. That installs the Rojo version pinned in `rokit.toml`.
3. Install the **Rojo plugin in Studio**: run `rojo plugin install`, or search for "Rojo" on the Creator Store.

### 2. Run the game

1. Clone this repo and open a terminal in the folder.
2. Start the sync server:
   ```bash
   rojo serve
   ```
3. Open Roblox Studio and create a new **Baseplate** place.
4. Open the **Rojo** plugin (Plugins tab) and click **Connect**.
5. Press **Play** (F5). You spawn in your own garden with 20 coins and 3 carrot seeds.

Code changes you save are synced into Studio live while `rojo serve` is running.

**Without live sync:** run `rojo build -o GardenFever.rbxl` and open the generated file in Studio.

### 3. Test multiplayer

In Studio, go to the **Test** tab, set **Clients and Servers** to 2–3 players and click **Start**. Each player gets their own garden.

### 4. Test saving

Saving needs *Game Settings → Security → Enable Studio Access to API Services* (the place must be published first). Without it the game still works, but nothing is saved between sessions.

### Testing tips

Edit `src/shared/Config.luau` to make events happen faster while you test, for example:

```lua
Config.StartingCoins = 1000000 -- buy anything right away
Config.RestockInterval = 20    -- restock every 20 seconds
Config.WeatherMinGap = 10      -- weather starts quickly
Config.WeatherMaxGap = 20
```

Remember to change them back before you publish.

### Publishing

Publish from Studio with *File → Publish to Roblox*, then set the **max players to 6** under *Game Settings → Places* (one garden per player).

## Project structure

```
src/
├── shared/Config.luau          Seeds, gear, mutations, weather and all balance values
├── server/
│   ├── Main.server.luau        Entry point: wires up every system
│   ├── World.luau              Builds the map: ground, plots, stalls, trees
│   ├── Garden.luau             Planting, growth, harvesting, mutations
│   ├── Shop.luau               Shop stock, buying and selling
│   ├── Weather.luau            Weather events and lighting
│   ├── PlayerData.luau         DataStore loading and saving
│   └── Net.luau                Remotes and state sync to the client
└── client/UI.client.luau       The whole UI and the weather effects
```

All balance values (prices, grow times, shop chances, mutation chances) live in `src/shared/Config.luau`.
