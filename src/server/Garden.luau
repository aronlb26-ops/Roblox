-- Garden logic: plot assignment, planting, growth, mutations and harvesting.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Net = require(script.Parent.Net)

local Garden = {}

local plots = {}
local plotOf = {} -- [Player] = plot

local STEM_COLOR = Color3.fromRGB(70, 160, 60)

local function now(): number
	return os.time()
end

local function rollBaseMutation(): string?
	if math.random() < Config.BaseMutationChance.Rainbow then
		return "Rainbow"
	elseif math.random() < Config.BaseMutationChance.Gold then
		return "Gold"
	end
	return nil
end

local function newPart(name: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true -- needed so the ClickDetector hits the plant
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

local function clearVisual(tile)
	local visual = tile.Model:FindFirstChild("Plant")
	if visual then
		visual:Destroy()
	end
end

local function progressOf(record, t: number): number
	local total = record.Ready - record.Start
	if total <= 0 then
		return 1
	end
	return math.clamp((t - record.Start) / total, 0, 1)
end

local function updateVisual(tile, record, t: number)
	local visual = tile.Model:FindFirstChild("Plant")
	local seed = Config.SeedById[record.Seed]
	if not visual or not seed then
		return
	end

	local p = progressOf(record, t)
	local stemP = if (record.Harvests or 0) > 0 then 1 else p
	local ready = p >= 1
	local soil = tile.Soil
	local base = soil.Position + Vector3.new(0, soil.Size.Y / 2, 0)

	local stem = visual.Stem
	local height = 0.4 + seed.Height * stemP
	stem.Size = Vector3.new(height, 0.35, 0.35) -- the cylinder's axis is X
	stem.CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))

	local leafSize = 0.3 + 1.4 * stemP
	visual.LeafA.Size = Vector3.new(leafSize, 0.12, leafSize * 0.5)
	visual.LeafA.CFrame = CFrame.new(base + Vector3.new(leafSize / 2, height * 0.45, 0)) * CFrame.Angles(0, 0, math.rad(20))
	visual.LeafB.Size = visual.LeafA.Size
	visual.LeafB.CFrame = CFrame.new(base + Vector3.new(-leafSize / 2, height * 0.6, 0)) * CFrame.Angles(0, 0, math.rad(-20))

	local fruit = visual.Fruit
	local d = seed.Size * (0.2 + 0.8 * p)
	fruit.Size = Vector3.new(d, d, d)
	fruit.CFrame = CFrame.new(base + Vector3.new(0, height + d / 2 - 0.15, 0))

	local mutation = record.Mut and Config.Mutations[record.Mut]
	if mutation then
		fruit.Color = mutation.Color
		fruit.Material = mutation.Material
	else
		fruit.Color = seed.Color
		fruit.Material = if ready then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
	if record.Mut == "Rainbow" then
		CollectionService:AddTag(fruit, "RainbowFruit")
	else
		CollectionService:RemoveTag(fruit, "RainbowFruit")
	end

	visual.Fruit.Sparkles.Enabled = ready or mutation ~= nil

	local gui = visual.Fruit.Info
	local title = seed.Emoji .. " " .. seed.Name
	if mutation then
		title = string.format("[%s] %s", mutation.Name, title)
	end
	gui.Title.Text = title
	gui.Title.TextColor3 = if mutation then mutation.Color else Color3.new(1, 1, 1)
	if ready then
		gui.Status.Text = "✅ Ready to harvest!"
		gui.Status.TextColor3 = Color3.fromRGB(140, 255, 120)
	else
		gui.Status.Text = "⏳ " .. Config.FormatTime(record.Ready - t)
		gui.Status.TextColor3 = Color3.fromRGB(255, 240, 180)
	end
end

local function buildVisual(tile, record)
	clearVisual(tile)
	local visual = Instance.new("Model")
	visual.Name = "Plant"

	local stem = newPart("Stem", visual)
	stem.Shape = Enum.PartType.Cylinder
	stem.Color = STEM_COLOR
	for _, name in { "LeafA", "LeafB" } do
		local leaf = newPart(name, visual)
		leaf.Color = STEM_COLOR:Lerp(Color3.fromRGB(150, 220, 90), 0.4)
		leaf.Material = Enum.Material.Grass
	end
	local fruit = newPart("Fruit", visual)
	fruit.Shape = Enum.PartType.Ball

	local sparkles = Instance.new("Sparkles")
	sparkles.Name = "Sparkles"
	sparkles.Enabled = false
	sparkles.Parent = fruit

	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromScale(6, 1.6)
	gui.StudsOffset = Vector3.new(0, 2, 0)
	gui.MaxDistance = 45
	gui.LightInfluence = 0
	gui.Parent = fruit
	for i, name in { "Title", "Status" } do
		local text = Instance.new("TextLabel")
		text.Name = name
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 0.5)
		text.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextStrokeTransparency = 0
		text.Parent = gui
	end

	visual.Parent = tile.Model
	updateVisual(tile, record, now())
end

local function renderPlot(plot, player: Player)
	local data = PlayerData.Get(player)
	for index, tile in plot.Tiles do
		local record = data and data.Plants[tostring(index)]
		if record then
			buildVisual(tile, record)
		else
			clearVisual(tile)
		end
	end
end

local function equippedId(player: Player, prefix: string): string?
	local session = PlayerData.Session(player)
	local equipped = session and session.Equipped
	if type(equipped) == "string" and string.sub(equipped, 1, #prefix) == prefix then
		return string.sub(equipped, #prefix + 1)
	end
	return nil
end

local function unequipIfEmpty(player: Player, data)
	local session = PlayerData.Session(player)
	if not session or not session.Equipped then
		return
	end
	local seedId = equippedId(player, "Seed:")
	local gearId = equippedId(player, "Gear:")
	if (seedId and (data.Seeds[seedId] or 0) <= 0) or (gearId and (data.Gear[gearId] or 0) <= 0) then
		session.Equipped = nil
	end
end

local function harvest(player: Player, data, tile, key: string, record)
	local seed = Config.SeedById[record.Seed]
	if #data.Fruits >= Config.MaxFruits then
		Net.Notify(player, "🎒 Your backpack is full! Sell your fruit first.", "bad")
		return
	end

	local weight = 0.8 + math.random() * 0.8
	local huge = math.random() < Config.HugeChance
	if huge then
		weight = 2.5 + math.random() * 1.5
	end
	local fruit = { S = seed.Id, W = math.floor(weight * 100) / 100, M = record.Mut }
	table.insert(data.Fruits, fruit)
	data.Harvested += 1

	local value = Config.FruitValue(fruit)
	local mutation = fruit.M and Config.Mutations[fruit.M]
	local text = string.format("+1 %s %s%s (💰 %s)", seed.Emoji, if mutation then mutation.Name .. " " else "", seed.Name, Config.FormatNumber(value))
	if huge then
		Net.Notify(player, "🦣 HUGE HARVEST! " .. text, "epic")
	else
		Net.Notify(player, text, if mutation then "epic" else "good")
	end

	if seed.Regrow then
		local t = now()
		record.Start = t
		record.Ready = t + math.floor(seed.GrowTime * Config.RegrowFactor)
		record.Harvests = (record.Harvests or 0) + 1
		record.Mut = rollBaseMutation()
		updateVisual(tile, record, t)
	else
		data.Plants[key] = nil
		clearVisual(tile)
	end
	Net.PushState(player)
end

local function onTileClicked(player: Player, plot, index: number)
	if plot.Owner ~= player then
		Net.Notify(player, "🚫 This is not your garden!", "bad")
		return
	end
	local data = PlayerData.Get(player)
	local session = PlayerData.Session(player)
	if not data or not session then
		return
	end

	local tile = plot.Tiles[index]
	local key = tostring(index)
	local record = data.Plants[key]
	local t = now()

	if record then
		local seed = Config.SeedById[record.Seed]
		if session.Equipped == "Shovel" then
			data.Plants[key] = nil
			clearVisual(tile)
			Net.Notify(player, "🪏 Dug up " .. seed.Name, "info")
			return
		end

		local gearId = equippedId(player, "Gear:")
		if gearId == "GoldFertilizer" and (data.Gear.GoldFertilizer or 0) > 0 then
			if Config.MutationMult(record.Mut) >= Config.Mutations.Gold.Mult then
				Net.Notify(player, "This plant is already worth at least as much as Gold!", "bad")
				return
			end
			data.Gear.GoldFertilizer -= 1
			record.Mut = "Gold"
			updateVisual(tile, record, t)
			Net.Notify(player, "✨ " .. seed.Name .. " turned GOLD!", "epic")
			unequipIfEmpty(player, data)
			Net.PushState(player)
			return
		end

		if progressOf(record, t) >= 1 then
			harvest(player, data, tile, key, record)
			return
		end

		if gearId == "WateringCan" and (data.Gear.WateringCan or 0) > 0 then
			data.Gear.WateringCan -= 1
			local skip = math.max(1, math.floor(seed.GrowTime * Config.WateringCanBoost))
			record.Ready = math.max(t, record.Ready - skip)
			updateVisual(tile, record, t)
			Net.Notify(player, "💧 Watered " .. seed.Name .. " (-" .. Config.FormatTime(skip) .. ")", "good")
			unequipIfEmpty(player, data)
			Net.PushState(player)
			return
		end

		Net.Notify(player, string.format("⏳ %s will be ready in %s", seed.Name, Config.FormatTime(record.Ready - t)), "info")
		return
	end

	local seedId = equippedId(player, "Seed:")
	if not seedId then
		Net.Notify(player, "🌱 Pick a seed in the hotbar to plant!", "info")
		return
	end
	local seed = Config.SeedById[seedId]
	if not seed or (data.Seeds[seedId] or 0) <= 0 then
		Net.Notify(player, "You have no more of those seeds.", "bad")
		return
	end

	data.Seeds[seedId] -= 1
	if data.Seeds[seedId] <= 0 then
		data.Seeds[seedId] = nil
	end
	record = { Seed = seedId, Start = t, Ready = t + seed.GrowTime, Harvests = 0, Mut = rollBaseMutation() }
	data.Plants[key] = record
	buildVisual(tile, record)
	unequipIfEmpty(player, data)
	Net.PushState(player)
end

function Garden.Init(worldPlots)
	plots = worldPlots
	for _, plot in plots do
		for index, tile in plot.Tiles do
			tile.Detector.MouseClick:Connect(function(player)
				onTileClicked(player, plot, index)
			end)
		end
	end

	-- Update growth and countdowns once per second.
	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			for _, plot in plots do
				local owner = plot.Owner
				local data = owner and PlayerData.Get(owner)
				if data then
					for index, tile in plot.Tiles do
						local record = data.Plants[tostring(index)]
						if record then
							updateVisual(tile, record, t)
						end
					end
				end
			end
		end
	end)
end

function Garden.Assign(player: Player)
	for _, plot in plots do
		if not plot.Owner then
			plot.Owner = player
			plotOf[player] = plot
			plot.Sign.Text.Text = player.DisplayName .. "'s Garden"
			renderPlot(plot, player)
			return plot
		end
	end
	return nil
end

function Garden.Release(player: Player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	for _, tile in plot.Tiles do
		clearVisual(tile)
	end
	plot.Owner = nil
	plot.Sign.Text.Text = "Ledig tomt"
	plotOf[player] = nil
end

function Garden.PlotOf(player: Player)
	return plotOf[player]
end

-- Called by the weather: every plant gets a chance at a (better) mutation.
function Garden.WeatherTick(weather)
	local t = now()
	for _, plot in plots do
		local owner = plot.Owner
		local data = owner and PlayerData.Get(owner)
		if data then
			for index, tile in plot.Tiles do
				local record = data.Plants[tostring(index)]
				if record then
					for mutationId, chance in weather.Chances do
						if Config.MutationMult(mutationId) > Config.MutationMult(record.Mut) and math.random() < chance then
							record.Mut = mutationId
							updateVisual(tile, record, t)
							local seed = Config.SeedById[record.Seed]
							Net.Notify(owner, string.format("%s Your %s became %s!", weather.Emoji, seed.Name, Config.Mutations[mutationId].Name), "epic")
						end
					end
				end
			end
		end
	end
end

return Garden
