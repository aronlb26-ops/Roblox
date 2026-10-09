-- Fröbutik och redskapsbutik med personligt lager som fylls på med jämna mellanrum.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Net = require(script.Parent.Net)

local Shop = {}

local stocks = {} -- [Player] = { Seeds = {id = n}, Gear = {id = n} }
local nextRestock = os.clock() + Config.RestockInterval
local lastBuy = {} -- [Player] = os.clock()

local function rollStock(items)
	local stock = {}
	for _, item in items do
		if math.random() < item.StockChance then
			stock[item.Id] = math.random(item.Stock[1], item.Stock[2])
		else
			stock[item.Id] = 0
		end
	end
	return stock
end

local function snapshot(player: Player)
	local stock = stocks[player]
	return {
		Seeds = stock and stock.Seeds or {},
		Gear = stock and stock.Gear or {},
		RestockIn = math.max(0, nextRestock - os.clock()),
	}
end

local function restock(player: Player)
	stocks[player] = { Seeds = rollStock(Config.Seeds), Gear = rollStock(Config.Gear) }
	Net.Shop:FireClient(player, snapshot(player))
end

local function announceRare(player: Player)
	local stock = stocks[player]
	for _, seed in Config.Seeds do
		local order = Config.Rarities[seed.Rarity].Order
		if order >= Config.Rarities.Legendary.Order and (stock.Seeds[seed.Id] or 0) > 0 then
			Net.Notify(player, string.format("%s %s %s finns i Fröbutiken!", seed.Emoji, Config.Rarities[seed.Rarity].Name, seed.Name), "epic")
		end
	end
end

local function buy(player: Player, kind: any, id: any)
	if type(kind) ~= "string" or type(id) ~= "string" then
		return false
	end
	local t = os.clock()
	if lastBuy[player] and t - lastBuy[player] < 0.1 then
		return false
	end
	lastBuy[player] = t

	local data = PlayerData.Get(player)
	local stock = stocks[player]
	if not data or not stock then
		return false
	end

	local item, stockTable, inventory
	if kind == "Seed" then
		item, stockTable, inventory = Config.SeedById[id], stock.Seeds, data.Seeds
	elseif kind == "Gear" then
		item, stockTable, inventory = Config.GearById[id], stock.Gear, data.Gear
	end
	if not item then
		return false
	end

	if (stockTable[id] or 0) <= 0 then
		Net.Notify(player, "❌ Slut i lager!", "bad")
		return false
	end
	if data.Coins < item.Price then
		Net.Notify(player, "❌ Du har inte råd! Behöver 💰 " .. Config.FormatNumber(item.Price), "bad")
		return false
	end

	data.Coins -= item.Price
	stockTable[id] -= 1
	inventory[id] = (inventory[id] or 0) + 1
	Net.Notify(player, string.format("🛒 Köpte %s %s", item.Emoji, item.Name), "good")
	Net.PushState(player)
	Net.Shop:FireClient(player, snapshot(player))
	return true
end

function Shop.Init()
	Net.GetShop.OnServerInvoke = function(player)
		return snapshot(player)
	end
	Net.Buy.OnServerInvoke = buy

	task.spawn(function()
		while true do
			task.wait(1)
			if os.clock() >= nextRestock then
				nextRestock = os.clock() + Config.RestockInterval
				for _, player in Players:GetPlayers() do
					if stocks[player] then
						restock(player)
						Net.Notify(player, "🚚 Butikerna har fyllts på!", "good")
						announceRare(player)
					end
				end
			end
		end
	end)
end

function Shop.AddPlayer(player: Player)
	restock(player)
	announceRare(player)
end

function Shop.RemovePlayer(player: Player)
	stocks[player] = nil
	lastBuy[player] = nil
end

-- Säljer allt i ryggsäcken. Anropas från sälj-ståndets ProximityPrompt.
function Shop.SellAll(player: Player)
	local data = PlayerData.Get(player)
	if not data then
		return
	end
	if #data.Fruits == 0 then
		Net.Notify(player, "🎒 Du har inga frukter att sälja. Skörda din trädgård!", "bad")
		return
	end
	local total = 0
	for _, fruit in data.Fruits do
		total += Config.FruitValue(fruit)
	end
	local count = #data.Fruits
	data.Fruits = {}
	data.Coins += total
	data.TotalEarned += total
	Net.Notify(player, string.format("💰 Sålde %d frukter för %s mynt!", count, Config.FormatNumber(total)), "good")
	Net.PushState(player)
end

return Shop
