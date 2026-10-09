-- Shared configuration for Garden Fever.
-- All balance values (prices, grow times, chances) live here so the game can be tuned in one place.

local Config = {}

Config.GameName = "Garden Fever"

Config.StartingCoins = 20
Config.StartingSeeds = { Carrot = 3 }
Config.MaxFruits = 200 -- backpack capacity

Config.PlotCount = 6 -- = max players per server
Config.GridSize = 5 -- 5x5 tiles per garden
Config.TileSize = 6

Config.RestockInterval = 300 -- seconds between shop restocks
Config.WeatherMinGap = 120
Config.WeatherMaxGap = 240
Config.WeatherTick = 10 -- how often weather tries to mutate plants
Config.AutoSaveInterval = 90

Config.RegrowFactor = 0.6 -- regrowing plants regrow in 60% of the time
Config.HugeChance = 0.01 -- chance for a HUGE fruit
Config.WateringCanBoost = 0.25 -- the watering can skips 25% of the grow time

Config.Rarities = {
	Common = { Name = "Common", Color = Color3.fromRGB(200, 200, 200), Order = 1 },
	Uncommon = { Name = "Uncommon", Color = Color3.fromRGB(95, 215, 95), Order = 2 },
	Rare = { Name = "Rare", Color = Color3.fromRGB(80, 150, 255), Order = 3 },
	Epic = { Name = "Epic", Color = Color3.fromRGB(180, 90, 255), Order = 4 },
	Legendary = { Name = "Legendary", Color = Color3.fromRGB(255, 195, 40), Order = 5 },
	Mythic = { Name = "Mythic", Color = Color3.fromRGB(255, 70, 130), Order = 6 },
}

-- Stock = {min, max} amount in stock when the seed shows up in the shop.
Config.Seeds = {
	{ Id = "Carrot", Name = "Carrot", Emoji = "🥕", Rarity = "Common", Price = 10, SellValue = 20, GrowTime = 20, Regrow = false, StockChance = 1, Stock = { 8, 20 }, Color = Color3.fromRGB(255, 140, 30), Size = 1.2, Height = 1.5 },
	{ Id = "Strawberry", Name = "Strawberry", Emoji = "🍓", Rarity = "Common", Price = 50, SellValue = 15, GrowTime = 30, Regrow = true, StockChance = 1, Stock = { 3, 10 }, Color = Color3.fromRGB(235, 40, 60), Size = 1.0, Height = 1.8 },
	{ Id = "Blueberry", Name = "Blueberry", Emoji = "🫐", Rarity = "Uncommon", Price = 400, SellValue = 45, GrowTime = 45, Regrow = true, StockChance = 0.8, Stock = { 2, 6 }, Color = Color3.fromRGB(60, 80, 220), Size = 0.9, Height = 2.2 },
	{ Id = "Tomato", Name = "Tomato", Emoji = "🍅", Rarity = "Uncommon", Price = 800, SellValue = 80, GrowTime = 60, Regrow = true, StockChance = 0.7, Stock = { 1, 5 }, Color = Color3.fromRGB(220, 30, 30), Size = 1.4, Height = 3 },
	{ Id = "Watermelon", Name = "Watermelon", Emoji = "🍉", Rarity = "Rare", Price = 2500, SellValue = 4200, GrowTime = 180, Regrow = false, StockChance = 0.5, Stock = { 1, 4 }, Color = Color3.fromRGB(40, 150, 50), Size = 2.8, Height = 1.2 },
	{ Id = "Pumpkin", Name = "Pumpkin", Emoji = "🎃", Rarity = "Rare", Price = 3500, SellValue = 6000, GrowTime = 240, Regrow = false, StockChance = 0.45, Stock = { 1, 3 }, Color = Color3.fromRGB(240, 120, 20), Size = 3, Height = 1.2 },
	{ Id = "Mango", Name = "Mango", Emoji = "🥭", Rarity = "Epic", Price = 15000, SellValue = 900, GrowTime = 120, Regrow = true, StockChance = 0.3, Stock = { 1, 3 }, Color = Color3.fromRGB(255, 180, 40), Size = 1.6, Height = 4 },
	{ Id = "Dragonfruit", Name = "Dragon Fruit", Emoji = "🐉", Rarity = "Legendary", Price = 50000, SellValue = 2600, GrowTime = 180, Regrow = true, StockChance = 0.15, Stock = { 1, 2 }, Color = Color3.fromRGB(255, 50, 160), Size = 1.8, Height = 4 },
	{ Id = "Starfruit", Name = "Starfruit", Emoji = "⭐", Rarity = "Legendary", Price = 120000, SellValue = 6500, GrowTime = 240, Regrow = true, StockChance = 0.07, Stock = { 1, 1 }, Color = Color3.fromRGB(255, 240, 80), Size = 1.8, Height = 4.5 },
	{ Id = "CosmicCactus", Name = "Cosmic Cactus", Emoji = "🌵", Rarity = "Mythic", Price = 1000000, SellValue = 45000, GrowTime = 300, Regrow = true, StockChance = 0.02, Stock = { 1, 1 }, Color = Color3.fromRGB(120, 60, 255), Size = 2.2, Height = 5 },
}

Config.Gear = {
	{ Id = "WateringCan", Name = "Watering Can", Emoji = "💧", Rarity = "Common", Price = 500, StockChance = 1, Stock = { 2, 6 }, Description = "Click a growing plant to make it grow faster." },
	{ Id = "GoldFertilizer", Name = "Gold Fertilizer", Emoji = "✨", Rarity = "Legendary", Price = 25000, StockChance = 0.25, Stock = { 1, 1 }, Description = "Turns a plant Gold (x20 value)." },
}

Config.Mutations = {
	Wet = { Name = "Wet", Mult = 2, Color = Color3.fromRGB(90, 170, 255), Material = Enum.Material.Glass },
	Frozen = { Name = "Frozen", Mult = 10, Color = Color3.fromRGB(170, 230, 255), Material = Enum.Material.Ice },
	Gold = { Name = "Gold", Mult = 20, Color = Color3.fromRGB(255, 200, 30), Material = Enum.Material.Neon },
	Rainbow = { Name = "Rainbow", Mult = 50, Color = Color3.fromRGB(255, 0, 0), Material = Enum.Material.Neon },
	Shocked = { Name = "Shocked", Mult = 100, Color = Color3.fromRGB(255, 255, 120), Material = Enum.Material.Neon },
}

-- Chance when a plant is planted or regrows.
Config.BaseMutationChance = { Gold = 0.01, Rainbow = 0.002 }

-- Chances = chance per weather tick (every WeatherTick seconds) for each plant.
Config.Weathers = {
	{ Id = "Rain", Name = "Rain", Emoji = "🌧️", Duration = 60, Weight = 40, Chances = { Wet = 0.08 } },
	{ Id = "Snow", Name = "Snowstorm", Emoji = "❄️", Duration = 60, Weight = 25, Chances = { Frozen = 0.04 } },
	{ Id = "Thunder", Name = "Thunderstorm", Emoji = "⛈️", Duration = 45, Weight = 15, Chances = { Wet = 0.06, Shocked = 0.012 } },
	{ Id = "GoldenHour", Name = "Golden Hour", Emoji = "🌅", Duration = 60, Weight = 12, Chances = { Gold = 0.03 } },
	{ Id = "RainbowNight", Name = "Rainbow Night", Emoji = "🌈", Duration = 45, Weight = 8, Chances = { Rainbow = 0.015 } },
}

-- Lookup tables
Config.SeedById = {}
for i, seed in Config.Seeds do
	seed.Order = i
	Config.SeedById[seed.Id] = seed
end

Config.GearById = {}
for i, gear in Config.Gear do
	gear.Order = i
	Config.GearById[gear.Id] = gear
end

Config.WeatherById = {}
for _, weather in Config.Weathers do
	Config.WeatherById[weather.Id] = weather
end

function Config.MutationMult(mutationId: string?): number
	local mutation = mutationId and Config.Mutations[mutationId]
	return if mutation then mutation.Mult else 1
end

function Config.FruitValue(fruit): number
	local seed = Config.SeedById[fruit.S]
	if not seed then
		return 0
	end
	return math.floor(seed.SellValue * fruit.W * Config.MutationMult(fruit.M))
end

local suffixes = { "", "K", "M", "B", "T", "Qa" }

function Config.FormatNumber(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local index = 1
	local value = n
	while value >= 1000 and index < #suffixes do
		value /= 1000
		index += 1
	end
	local text = if value >= 100 then string.format("%d", value) else string.format("%.1f", value)
	text = string.gsub(text, "%.0$", "")
	return text .. suffixes[index]
end

function Config.FormatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local m = seconds // 60
	local s = seconds % 60
	if m >= 60 then
		return string.format("%dh %02dm", m // 60, m % 60)
	elseif m > 0 then
		return string.format("%d:%02d", m, s)
	end
	return string.format("%ds", s)
end

return Config
