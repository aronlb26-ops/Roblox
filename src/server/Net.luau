-- Creates RemoteEvents/RemoteFunctions and sends the player's state to the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Net = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"

for _, name in { "State", "Notify", "Weather", "Shop", "Equip", "Teleport" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	Net[name] = remote
end

for _, name in { "GetShop", "Buy" } do
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = folder
	Net[name] = remote
end

folder.Parent = ReplicatedStorage

-- Net.Notify is a function; the RemoteEvent itself is reached through notifyRemote.
local notifyRemote = Net.Notify
Net.Notify = nil

-- kind: "info" | "good" | "bad" | "epic"
function Net.Notify(player: Player, text: string, kind: string?)
	notifyRemote:FireClient(player, text, kind or "info")
end

function Net.NotifyAll(text: string, kind: string?)
	notifyRemote:FireAllClients(text, kind or "info")
end

function Net.PushState(player: Player)
	local data = PlayerData.Get(player)
	local session = PlayerData.Session(player)
	if not data or not session then
		return
	end

	-- Group fruits by type + mutation for the backpack.
	local groups = {}
	local order = {}
	local totalValue = 0
	for _, fruit in data.Fruits do
		local groupKey = fruit.S .. "|" .. (fruit.M or "")
		local group = groups[groupKey]
		if not group then
			group = { Seed = fruit.S, Mut = fruit.M, Count = 0, Value = 0 }
			groups[groupKey] = group
			table.insert(order, group)
		end
		local value = Config.FruitValue(fruit)
		group.Count += 1
		group.Value += value
		totalValue += value
	end
	table.sort(order, function(a, b)
		return a.Value > b.Value
	end)

	Net.State:FireClient(player, {
		Coins = data.Coins,
		Seeds = data.Seeds,
		Gear = data.Gear,
		FruitCount = #data.Fruits,
		FruitValue = totalValue,
		MaxFruits = Config.MaxFruits,
		Fruits = order,
		Equipped = session.Equipped,
		Harvested = data.Harvested,
	})

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = data.Coins
		end
		local harvested = leaderstats:FindFirstChild("Harvested")
		if harvested then
			harvested.Value = data.Harvested
		end
	end
end

return Net
