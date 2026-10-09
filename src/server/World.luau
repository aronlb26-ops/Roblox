-- Bygger hela kartan med kod: mark, stigar, trädgårdstomter, butiksstånd och dekorationer.
-- Det gör att spelet fungerar direkt efter en Rojo-synk utan någon .rbxl-fil.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local World = {}

local GRASS = Color3.fromRGB(110, 190, 80)
local PATH = Color3.fromRGB(235, 215, 160)
local WOOD = Color3.fromRGB(150, 100, 60)
local SOIL = Color3.fromRGB(110, 70, 40)

local function make(className: string, props)
	local instance = Instance.new(className)
	local parent = props.Parent
	props.Parent = nil
	for k, v in props do
		instance[k] = v
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
		instance.TopSurface = Enum.SurfaceType.Smooth
		instance.BottomSurface = Enum.SurfaceType.Smooth
	end
	instance.Parent = parent
	return instance
end

local function label(parent: Instance, text: string, size: Vector2, offset: Vector3, color: Color3?)
	local gui = make("BillboardGui", {
		Name = "Label",
		Size = UDim2.fromScale(size.X, size.Y),
		StudsOffset = offset,
		MaxDistance = 150,
		LightInfluence = 0,
		Parent = parent,
	})
	make("TextLabel", {
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.FredokaOne,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(40, 30, 20),
		Parent = gui,
	})
	return gui
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
	Lighting.GlobalShadows = true
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		make("Atmosphere", { Density = 0.25, Offset = 0.1, Color = Color3.fromRGB(200, 225, 255), Decay = Color3.fromRGB(120, 160, 220), Glare = 0.2, Haze = 1, Parent = Lighting })
	end
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		make("BloomEffect", { Intensity = 0.6, Size = 30, Threshold = 1.2, Parent = Lighting })
	end
	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		make("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.05, Parent = Lighting })
	end
end

local function buildTree(parent: Instance, position: Vector3, scale: number)
	local model = make("Model", { Name = "Tree", Parent = parent })
	make("Part", { Name = "Trunk", Size = Vector3.new(1.5, 8, 1.5) * scale, Position = position + Vector3.new(0, 4 * scale, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	make("Part", {
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(8, 8, 8) * scale,
		Position = position + Vector3.new(0, 9 * scale, 0),
		Color = Color3.fromRGB(60, 160, 60):Lerp(Color3.fromRGB(120, 200, 70), math.random()),
		Material = Enum.Material.Grass,
		Parent = model,
	})
end

local function buildStall(parent: Instance, name: string, title: string, color: Color3, cf: CFrame)
	local model = make("Model", { Name = name, Parent = parent })
	make("Part", { Name = "Floor", Size = Vector3.new(16, 0.4, 12), CFrame = cf * CFrame.new(0, 0.2, 0), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = model })
	local counter = make("Part", { Name = "Counter", Size = Vector3.new(14, 3.5, 2), CFrame = cf * CFrame.new(0, 2.15, -4), Color = color, Material = Enum.Material.SmoothPlastic, Parent = model })
	for _, x in { -7.5, 7.5 } do
		for _, z in { -5.5, 5.5 } do
			make("Part", { Name = "Post", Size = Vector3.new(0.8, 10, 0.8), CFrame = cf * CFrame.new(x, 5, z), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
		end
	end
	-- Randigt tak
	for i = 0, 7 do
		make("Part", {
			Name = "Roof",
			Size = Vector3.new(2.1, 0.6, 13),
			CFrame = cf * CFrame.new(-7.35 + i * 2.1, 10.3, 0),
			Color = if i % 2 == 0 then color else Color3.new(1, 1, 1),
			Material = Enum.Material.SmoothPlastic,
			Parent = model,
		})
	end
	label(counter, title, Vector2.new(16, 4), Vector3.new(0, 10, 0))

	-- Enkel butiksägare
	local keeper = make("Model", { Name = "Shopkeeper", Parent = model })
	make("Part", { Name = "Body", Size = Vector3.new(2.5, 3, 1.5), CFrame = cf * CFrame.new(0, 3.5, -1.5), Color = color, Parent = keeper })
	local head = make("Part", { Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = cf * CFrame.new(0, 6, -1.5), Color = Color3.fromRGB(255, 220, 180), Parent = keeper })
	make("Decal", { Texture = "rbxasset://textures/face.png", Face = Enum.NormalId.Front, Parent = head })
	head.CFrame = CFrame.lookAt(head.Position, (cf * CFrame.new(0, 6, -10)).Position)
	make("Part", { Name = "Hat", Size = Vector3.new(2.6, 0.4, 2.6), CFrame = cf * CFrame.new(0, 7.2, -1.5), Color = Color3.fromRGB(240, 210, 120), Material = Enum.Material.Fabric, Parent = keeper })

	local prompt = make("ProximityPrompt", {
		ActionText = "Öppna",
		ObjectText = title,
		HoldDuration = 0,
		MaxActivationDistance = 14,
		RequiresLineOfSight = false,
		Parent = counter,
	})
	return model, prompt, cf * CFrame.new(0, 3, -9) * CFrame.Angles(0, math.pi, 0)
end

local function buildPlot(parent: Instance, index: number, cf: CFrame)
	local half = Config.GridSize * Config.TileSize / 2 + 3
	local model = make("Model", { Name = "Plot" .. index, Parent = parent })
	make("Part", { Name = "Base", Size = Vector3.new(half * 2, 0.4, half * 2), CFrame = cf * CFrame.new(0, 0.2, 0), Color = Color3.fromRGB(95, 165, 70), Material = Enum.Material.Grass, Parent = model })

	-- Staket med öppning mot stigen (framsidan är -Z i tomtens koordinatsystem).
	local fenceProps = { Color = Color3.fromRGB(245, 240, 225), Material = Enum.Material.WoodPlanks, Parent = model, Name = "Fence" }
	local function fence(size: Vector3, offset: Vector3)
		local props = table.clone(fenceProps)
		props.Size = size
		props.CFrame = cf * CFrame.new(offset)
		make("Part", props)
	end
	fence(Vector3.new(half * 2, 2.5, 0.5), Vector3.new(0, 1.25, half))
	fence(Vector3.new(0.5, 2.5, half * 2), Vector3.new(-half, 1.25, 0))
	fence(Vector3.new(0.5, 2.5, half * 2), Vector3.new(half, 1.25, 0))
	local gap = 5
	local segment = half - gap
	fence(Vector3.new(segment, 2.5, 0.5), Vector3.new(-(gap + segment / 2), 1.25, -half))
	fence(Vector3.new(segment, 2.5, 0.5), Vector3.new(gap + segment / 2, 1.25, -half))

	-- Skylt
	make("Part", { Name = "SignPost", Size = Vector3.new(0.6, 6, 0.6), CFrame = cf * CFrame.new(-gap - 1.5, 3, -half - 1), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local board = make("Part", { Name = "SignBoard", Size = Vector3.new(7, 2.5, 0.4), CFrame = cf * CFrame.new(-gap - 1.5, 6, -half - 1), Color = WOOD, Material = Enum.Material.WoodPlanks, Parent = model })
	local sign = label(board, "Ledig tomt", Vector2.new(14, 3), Vector3.new(0, 3, 0), Color3.fromRGB(255, 255, 200))

	-- Odlingsrutor
	local tiles = {}
	local n = Config.GridSize
	local count = 0
	for row = 1, n do
		for col = 1, n do
			count += 1
			local x = (col - (n + 1) / 2) * Config.TileSize
			local z = (row - (n + 1) / 2) * Config.TileSize
			local tile = make("Model", { Name = "Tile" .. count, Parent = model })
			tile:SetAttribute("TileIndex", count)
			local soil = make("Part", {
				Name = "Soil",
				Size = Vector3.new(Config.TileSize - 0.6, 0.6, Config.TileSize - 0.6),
				CFrame = cf * CFrame.new(x, 0.5, z),
				Color = SOIL,
				Material = Enum.Material.Ground,
				Parent = tile,
			})
			tile.PrimaryPart = soil
			local detector = make("ClickDetector", { MaxActivationDistance = 40, Parent = tile })
			tiles[count] = { Model = tile, Soil = soil, Detector = detector }
		end
	end

	return {
		Index = index,
		Model = model,
		CFrame = cf,
		Sign = sign,
		Tiles = tiles,
		Spawn = cf * CFrame.new(0, 3, -half + 3) * CFrame.Angles(0, math.pi, 0),
		Owner = nil,
	}
end

function World.Build()
	setupLighting()

	local old = workspace:FindFirstChild("Baseplate")
	if old then
		old:Destroy()
	end

	local map = make("Folder", { Name = "Map", Parent = workspace })
	make("Part", { Name = "Ground", Size = Vector3.new(500, 2, 500), Position = Vector3.new(0, -1, 0), Color = GRASS, Material = Enum.Material.Grass, Parent = map })
	make("Part", { Name = "Path", Size = Vector3.new(220, 0.2, 34), Position = Vector3.new(0, 0.05, 0), Color = PATH, Material = Enum.Material.Sand, Parent = map })

	make("SpawnLocation", {
		Name = "Spawn",
		Size = Vector3.new(8, 0.4, 8),
		Position = Vector3.new(0, 0.3, 0),
		Color = Color3.fromRGB(255, 220, 120),
		Material = Enum.Material.SmoothPlastic,
		Neutral = true,
		Duration = 0,
		Parent = map,
	})

	-- Tomter: tre på varje sida av stigen, med framsidan mot stigen.
	local plotsFolder = make("Folder", { Name = "Plots", Parent = workspace })
	local plots = {}
	local xs = { -70, 0, 70 }
	for i = 1, Config.PlotCount do
		local side = if i <= 3 then 1 else -1
		local x = xs[((i - 1) % 3) + 1]
		local center = Vector3.new(x, 0, side * 52)
		local cf = CFrame.lookAt(center, center + Vector3.new(0, 0, -side))
		plots[i] = buildPlot(plotsFolder, i, cf)
	end

	-- Butiksstånd längs stigen
	local stalls = make("Folder", { Name = "Stalls", Parent = map })
	local facingNorth = function(x: number)
		local pos = Vector3.new(x, 0, 6)
		return CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
	end
	local _, seedPrompt, seedSpot = buildStall(stalls, "SeedShop", "🌱 Fröbutik", Color3.fromRGB(80, 190, 90), facingNorth(-35))
	seedPrompt:SetAttribute("Shop", "Seeds")
	local _, gearPrompt, gearSpot = buildStall(stalls, "GearShop", "🧰 Redskap", Color3.fromRGB(80, 140, 230), facingNorth(-70))
	gearPrompt:SetAttribute("Shop", "Gear")
	local _, sellPrompt, sellSpot = buildStall(stalls, "SellShop", "💰 Sälj frukt", Color3.fromRGB(240, 170, 40), facingNorth(35))
	sellPrompt.ActionText = "Sälj allt"

	-- Dekorationer runt kanterna
	local deco = make("Folder", { Name = "Decorations", Parent = map })
	local random = Random.new(1337)
	for _ = 1, 60 do
		local x, z
		repeat
			x = random:NextNumber(-240, 240)
			z = random:NextNumber(-240, 240)
		until math.abs(x) > 115 or math.abs(z) > 85
		buildTree(deco, Vector3.new(x, 0, z), random:NextNumber(0.8, 1.6))
	end
	local flowerColors = { Color3.fromRGB(255, 120, 180), Color3.fromRGB(255, 230, 80), Color3.fromRGB(180, 120, 255), Color3.new(1, 1, 1) }
	for _ = 1, 120 do
		local x = random:NextNumber(-110, 110)
		local z = random:NextNumber(-90, 90)
		local insidePlot = false
		for _, plot in plots do
			local p = plot.CFrame.Position
			if math.abs(p.X - x) < 22 and math.abs(p.Z - z) < 22 then
				insidePlot = true
			end
		end
		if not insidePlot and math.abs(z) > 18 then
			make("Part", {
				Name = "Flower",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.8, 0.8, 0.8),
				Position = Vector3.new(x, 0.4, z),
				Color = flowerColors[random:NextInteger(1, #flowerColors)],
				CanCollide = false,
				Parent = deco,
			})
		end
	end

	return {
		Plots = plots,
		SellPrompt = sellPrompt,
		Spots = { Seeds = seedSpot, Gear = gearSpot, Sell = sellSpot },
	}
end

return World
