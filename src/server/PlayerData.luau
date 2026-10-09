-- Loads, holds and saves player data through DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerData = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("GardenFeverV1")
end)

local profiles = {} -- [Player] = data
local sessions = {} -- [Player] = { Equipped = string? } (not saved)
local canSave = {} -- [Player] = boolean

local function defaultData()
	return {
		Coins = Config.StartingCoins,
		Seeds = table.clone(Config.StartingSeeds),
		Gear = {},
		Fruits = {},
		Plants = {}, -- ["tileIndex"] = { Seed, Start, Ready, Harvests, Mut }
		TotalEarned = 0,
		Harvested = 0,
	}
end

local function key(player: Player): string
	return "p_" .. player.UserId
end

function PlayerData.Load(player: Player)
	local data = nil
	local loaded = false

	if store then
		for _ = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key(player))
			end)
			if ok then
				data = result
				loaded = true
				break
			end
			warn("[PlayerData] Failed to load", player.Name, result)
			task.wait(1)
		end
	end

	if type(data) ~= "table" then
		data = defaultData()
	else
		for k, v in defaultData() do
			if data[k] == nil then
				data[k] = v
			end
		end
	end

	-- Drop items that no longer exist in the config.
	for id in data.Seeds do
		if not Config.SeedById[id] then
			data.Seeds[id] = nil
		end
	end
	for id in data.Gear do
		if not Config.GearById[id] then
			data.Gear[id] = nil
		end
	end
	for index, plant in data.Plants do
		if not Config.SeedById[plant.Seed] then
			data.Plants[index] = nil
		end
	end

	-- Only save if existing data was actually read, so a DataStore outage never overwrites a save.
	canSave[player] = store ~= nil and loaded
	profiles[player] = data
	sessions[player] = { Equipped = nil }
	return data
end

function PlayerData.Get(player: Player)
	return profiles[player]
end

function PlayerData.Session(player: Player)
	return sessions[player]
end

function PlayerData.Save(player: Player)
	local data = profiles[player]
	if not data or not canSave[player] then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(key(player), data, { player.UserId })
	end)
	if not ok then
		warn("[PlayerData] Failed to save", player.Name, err)
	end
end

function PlayerData.Release(player: Player)
	PlayerData.Save(player)
	profiles[player] = nil
	sessions[player] = nil
	canSave[player] = nil
end

function PlayerData.All()
	return profiles
end

return PlayerData
