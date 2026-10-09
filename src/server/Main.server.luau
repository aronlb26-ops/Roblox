-- Server entry point: builds the world and wires up every system.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Net = require(script.Parent.Net)
local World = require(script.Parent.World)
local Garden = require(script.Parent.Garden)
local Shop = require(script.Parent.Shop)
local Weather = require(script.Parent.Weather)

local world = World.Build()
Garden.Init(world.Plots)
Shop.Init()
Weather.Init()

world.SellPrompt.Triggered:Connect(function(player)
	Shop.SellAll(player)
end)

local function teleport(player: Player, cf: CFrame?)
	local character = player.Character
	if cf and character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(cf)
	end
end

Net.Teleport.OnServerEvent:Connect(function(player, destination)
	if destination == "Garden" then
		local plot = Garden.PlotOf(player)
		teleport(player, plot and plot.Spawn)
	elseif type(destination) == "string" then
		teleport(player, world.Spots[destination])
	end
end)

Net.Equip.OnServerEvent:Connect(function(player, id)
	local data = PlayerData.Get(player)
	local session = PlayerData.Session(player)
	if not data or not session then
		return
	end
	local valid = id == nil or id == "Shovel"
	if type(id) == "string" then
		local seedId = string.match(id, "^Seed:(.+)$")
		local gearId = string.match(id, "^Gear:(.+)$")
		if (seedId and (data.Seeds[seedId] or 0) > 0) or (gearId and (data.Gear[gearId] or 0) > 0) then
			valid = true
		end
	end
	if valid then
		session.Equipped = id
	end
	Net.PushState(player)
end)

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	local harvested = Instance.new("IntValue")
	harvested.Name = "Harvested"
	harvested.Parent = leaderstats
	leaderstats.Parent = player

	PlayerData.Load(player)
	if not player.Parent then
		PlayerData.Release(player)
		return
	end

	local plot = Garden.Assign(player)
	if not plot then
		player:Kick("This server is full - every garden is taken. Please try again!")
		return
	end

	local function onCharacter(character: Model)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		character:PivotTo(plot.Spawn)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	Shop.AddPlayer(player)
	Net.PushState(player)
	Weather.SendCurrent(player)
	Net.Notify(player, "🌱 Welcome to " .. Config.GameName .. "! Plant your seeds and get rich!", "good")
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	Garden.Release(player)
	Shop.RemovePlayer(player)
	PlayerData.Release(player)
end)

-- Autosave
task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		for player in PlayerData.All() do
			task.spawn(PlayerData.Save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in PlayerData.All() do
		pending += 1
		task.spawn(function()
			PlayerData.Save(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
