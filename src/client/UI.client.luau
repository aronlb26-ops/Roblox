-- The whole client UI: coins, hotbar, shops, backpack, notifications and weather effects.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.FredokaOne
local C = {
	Panel = Color3.fromRGB(255, 247, 228),
	Ink = Color3.fromRGB(60, 40, 25),
	Outline = Color3.fromRGB(45, 30, 20),
	Green = Color3.fromRGB(90, 200, 90),
	Gold = Color3.fromRGB(255, 200, 50),
	Red = Color3.fromRGB(235, 80, 80),
	Blue = Color3.fromRGB(80, 160, 255),
	Purple = Color3.fromRGB(180, 100, 255),
	Gray = Color3.fromRGB(160, 160, 160),
	White = Color3.new(1, 1, 1),
}

local state = nil
local shopData = { Seeds = {}, Gear = {} }
local restockAt = os.clock() + Config.RestockInterval
local openShopKind = nil
local openShopPrompt = nil
local hotbarKeys = {}
local toggleBackpack -- defined further down

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function make(className: string, props, children)
	local instance = Instance.new(className)
	local parent = props.Parent
	props.Parent = nil
	for k, v in props do
		instance[k] = v
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = parent
	return instance
end

local function corner(radius: number?)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function stroke(thickness: number?, color: Color3?)
	return make("UIStroke", { Thickness = thickness or 3, Color = color or C.Outline, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function gradient(top: Color3, bottom: Color3)
	return make("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = 90 })
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = FONT
	props.TextColor3 = props.TextColor3 or C.White
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	local label = make("TextLabel", props)
	if props.TextColor3 == C.White then
		make("UIStroke", { Thickness = 2, Color = C.Outline, Parent = label })
	end
	return label
end

local function button(props, color: Color3)
	props.BackgroundColor3 = color
	props.AutoButtonColor = true
	props.Font = FONT
	props.TextColor3 = props.TextColor3 or C.White
	props.TextScaled = true
	local btn = make("TextButton", props, { corner(10), stroke(3), gradient(C.White, Color3.fromRGB(200, 200, 200)) })
	make("UIStroke", { Thickness = 2, Color = C.Outline, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = btn })
	make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = btn })
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), { Rotation = math.random(-3, 3) }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
	end)
	return btn
end

local function clearChildren(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function pop(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = gui })
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

--------------------------------------------------------------------------------
-- Base layout
--------------------------------------------------------------------------------

local screen = make("ScreenGui", { Name = "TradgardsUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })

-- Coins
local coinPill = make("Frame", {
	Name = "Coins",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(240, 52),
	BackgroundColor3 = C.Gold,
	Parent = screen,
}, { corner(26), stroke(4), gradient(C.White, Color3.fromRGB(230, 170, 30)) })
local coinLabel = text({ Size = UDim2.fromScale(1, 1), Text = "💰 0", Parent = coinPill })
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = coinPill })

-- Weather banner
local weatherBanner = make("Frame", {
	Name = "Weather",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 68),
	Size = UDim2.fromOffset(300, 38),
	BackgroundColor3 = C.Purple,
	Visible = false,
	Parent = screen,
}, { corner(19), stroke(3), gradient(C.White, Color3.fromRGB(170, 170, 170)) })
local weatherLabel = text({ Size = UDim2.fromScale(1, 1), Text = "", Parent = weatherBanner })
make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), Parent = weatherBanner })
local weatherEndsAt = 0
local weatherName = ""

-- Left menu
local nav = make("Frame", {
	Name = "Nav",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.45, 0),
	Size = UDim2.fromOffset(150, 260),
	BackgroundTransparency = 1,
	Parent = screen,
}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

local navButtons = {
	{ "🏡 Garden", "Garden", C.Green },
	{ "🌱 Seeds", "Seeds", Color3.fromRGB(120, 210, 90) },
	{ "🧰 Gear", "Gear", C.Blue },
	{ "💰 Sell", "Sell", C.Gold },
}
for i, info in navButtons do
	local btn = button({ Name = info[2], LayoutOrder = i, Size = UDim2.new(1, 0, 0, 48), Text = info[1], Parent = nav }, info[3])
	btn.Activated:Connect(function()
		Remotes.Teleport:FireServer(info[2])
	end)
end
local restockLabel = text({ LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 22), Text = "🚚 --", Parent = nav })

-- Backpack button
local backpackButton = button({
	Name = "Backpack",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.45, 0),
	Size = UDim2.fromOffset(170, 56),
	Text = "🎒 0/200",
	Parent = screen,
}, Color3.fromRGB(200, 140, 80))

-- Hotbar
local hotbar = make("Frame", {
	Name = "Hotbar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.new(0.95, 0, 0, 92),
	BackgroundTransparency = 1,
	Parent = screen,
}, {
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- Notifications
local toasts = make("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -112),
	Size = UDim2.fromOffset(440, 240),
	BackgroundTransparency = 1,
	Parent = screen,
}, {
	make("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

--------------------------------------------------------------------------------
-- Panel template (shop / backpack)
--------------------------------------------------------------------------------

local function makePanel(name: string, title: string, color: Color3)
	local panel = make("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.92, 0.72),
		BackgroundColor3 = C.Panel,
		Visible = false,
		Parent = screen,
	}, { corner(18), stroke(5), make("UISizeConstraint", { MaxSize = Vector2.new(520, 500) }) })

	local header = make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = color, Parent = panel }, { corner(18), stroke(4), gradient(C.White, Color3.fromRGB(190, 190, 190)) })
	local titleLabel = text({ Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -80, 0, 40), Text = title, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
	local close = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(40, 40), Text = "X", Parent = header }, C.Red)
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local subtitle = text({ Name = "Subtitle", Position = UDim2.fromOffset(16, 62), Size = UDim2.new(1, -32, 0, 24), TextColor3 = C.Ink, Text = "", TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })

	local list = make("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(12, 92),
		Size = UDim2.new(1, -24, 1, -104),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Ink,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = panel,
	}, {
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		make("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }),
	})

	return panel, titleLabel, subtitle, list
end

local shopPanel, shopTitle, shopSubtitle, shopList = makePanel("Shop", "🌱 Seed Shop", C.Green)
local packPanel, _, packSubtitle, packList = makePanel("BackpackPanel", "🎒 Backpack", Color3.fromRGB(200, 140, 80))

--------------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------------

local TOAST_COLORS = { info = Color3.fromRGB(70, 70, 90), good = C.Green, bad = C.Red, epic = C.Purple }
local toastOrder = 0

local function toast(message: string, kind: string?)
	toastOrder += 1
	local items = {}
	for _, child in toasts:GetChildren() do
		if child:IsA("Frame") then
			table.insert(items, child)
		end
	end
	if #items >= 5 then
		table.sort(items, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		items[1]:Destroy()
	end

	local frame = make("Frame", {
		LayoutOrder = toastOrder,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = TOAST_COLORS[kind or "info"] or TOAST_COLORS.info,
		Parent = toasts,
	}, { corner(12), stroke(3) })
	local label = text({ Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), Text = message, Parent = frame })
	pop(frame)
	if kind == "epic" then
		make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 200)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 110, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 255)),
			}),
			Parent = frame,
		})
	end

	task.delay(3.5, function()
		if frame.Parent then
			local info = TweenInfo.new(0.4)
			TweenService:Create(frame, info, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, info, { TextTransparency = 1 }):Play()
			task.wait(0.4)
			frame:Destroy()
		end
	end)
end

--------------------------------------------------------------------------------
-- Hotbar
--------------------------------------------------------------------------------

local function setEquipped(id: string?)
	if state and state.Equipped == id then
		id = nil
	end
	Remotes.Equip:FireServer(id)
end

local function hotbarSlot(order: number, id: string, emoji: string, name: string, count: number?, rarityColor: Color3?)
	local equipped = state and state.Equipped == id
	local slot = make("TextButton", {
		Name = id,
		LayoutOrder = order,
		Size = UDim2.fromOffset(78, if equipped then 88 else 78),
		BackgroundColor3 = if equipped then Color3.fromRGB(255, 240, 160) else C.Panel,
		AutoButtonColor = true,
		Text = "",
		Parent = hotbar,
	}, { corner(14), stroke(if equipped then 5 else 3, if equipped then C.Gold else C.Outline) })
	text({ Size = UDim2.new(1, 0, 0.55, 0), Position = UDim2.fromScale(0, 0.05), Text = emoji, Parent = slot })
	text({ Size = UDim2.new(1, -6, 0.22, 0), Position = UDim2.new(0, 3, 0.6, 0), Text = name, TextColor3 = rarityColor or C.Ink, Parent = slot })
	if count then
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 2), Size = UDim2.fromOffset(34, 18), Text = "x" .. count, TextXAlignment = Enum.TextXAlignment.Right, Parent = slot })
	end
	if order <= 9 then
		text({ Position = UDim2.fromOffset(5, 2), Size = UDim2.fromOffset(14, 16), Text = tostring(order), TextColor3 = C.Gray, Parent = slot })
		hotbarKeys[order] = id
	end
	slot.Activated:Connect(function()
		setEquipped(id)
	end)
end

local function renderHotbar()
	clearChildren(hotbar)
	table.clear(hotbarKeys)
	if not state then
		return
	end
	local order = 0
	order += 1
	hotbarSlot(order, "Shovel", "🪏", "Shovel", nil, nil)
	for _, seed in Config.Seeds do
		local count = state.Seeds[seed.Id]
		if count and count > 0 then
			order += 1
			hotbarSlot(order, "Seed:" .. seed.Id, seed.Emoji, seed.Name, count, Config.Rarities[seed.Rarity].Color:Lerp(C.Ink, 0.35))
		end
	end
	for _, gear in Config.Gear do
		local count = state.Gear[gear.Id]
		if count and count > 0 then
			order += 1
			hotbarSlot(order, "Gear:" .. gear.Id, gear.Emoji, gear.Name, count, C.Blue)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local keys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
	for i, keyCode in keys do
		if input.KeyCode == keyCode and hotbarKeys[i] then
			setEquipped(hotbarKeys[i])
			return
		end
	end
	if input.KeyCode == Enum.KeyCode.B then
		toggleBackpack()
	end
end)

--------------------------------------------------------------------------------
-- Shop
--------------------------------------------------------------------------------

local function renderShop()
	if not openShopKind then
		return
	end
	clearChildren(shopList)
	local isSeeds = openShopKind == "Seeds"
	local items = if isSeeds then Config.Seeds else Config.Gear
	local stock = (if isSeeds then shopData.Seeds else shopData.Gear) or {}
	local coins = state and state.Coins or 0

	for i, item in items do
		local rarity = Config.Rarities[item.Rarity]
		local inStock = stock[item.Id] or 0
		local row = make("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 72),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = shopList,
		}, { corner(12), stroke(3, rarity.Color:Lerp(C.Outline, 0.3)) })

		text({ Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(56, 56), Text = item.Emoji, Parent = row })
		text({ Position = UDim2.fromOffset(70, 6), Size = UDim2.new(1, -200, 0, 26), Text = item.Name, TextColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })

		local detail
		if isSeeds then
			detail = string.format("%s • %s • %s", rarity.Name, Config.FormatTime(item.GrowTime), if item.Regrow then "Regrows ♻️" else "Single harvest")
		else
			detail = item.Description
		end
		text({ Position = UDim2.fromOffset(70, 32), Size = UDim2.new(1, -200, 0, 18), Text = detail, TextColor3 = rarity.Color:Lerp(C.Ink, 0.4), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		text({
			Position = UDim2.fromOffset(70, 50),
			Size = UDim2.new(1, -200, 0, 16),
			Text = if inStock > 0 then string.format("x%d in stock", inStock) else "OUT OF STOCK",
			TextColor3 = if inStock > 0 then Color3.fromRGB(60, 150, 60) else C.Red,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		local affordable = coins >= item.Price
		local canBuy = inStock > 0 and affordable
		local buy = button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(116, 48),
			Text = "💰 " .. Config.FormatNumber(item.Price),
			Parent = row,
		}, if canBuy then C.Green elseif inStock > 0 then C.Red else C.Gray)
		buy.Activated:Connect(function()
			Remotes.Buy:InvokeServer(if isSeeds then "Seed" else "Gear", item.Id)
		end)
	end
end

local function openShop(kind: string, prompt: ProximityPrompt?)
	openShopKind = kind
	openShopPrompt = prompt
	packPanel.Visible = false
	shopTitle.Text = if kind == "Seeds" then "🌱 Seed Shop" else "🧰 Gear Shop"
	shopPanel.Header.BackgroundColor3 = if kind == "Seeds" then C.Green else C.Blue
	shopPanel.Visible = true
	pop(shopPanel)
	renderShop()
end

shopPanel:GetPropertyChangedSignal("Visible"):Connect(function()
	if not shopPanel.Visible then
		openShopKind = nil
		openShopPrompt = nil
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local kind = prompt:GetAttribute("Shop")
	if kind then
		openShop(kind, prompt)
	end
end)

Remotes.Shop.OnClientEvent:Connect(function(data)
	shopData = data
	restockAt = os.clock() + data.RestockIn
	renderShop()
end)

--------------------------------------------------------------------------------
-- Backpack
--------------------------------------------------------------------------------

local function renderBackpack()
	if not state then
		return
	end
	backpackButton.Text = string.format("🎒 %d/%d", state.FruitCount, state.MaxFruits)
	if not packPanel.Visible then
		return
	end
	packSubtitle.Text = string.format("Total value: 💰 %s  •  Sell at the 💰 stall!", Config.FormatNumber(state.FruitValue))
	clearChildren(packList)
	if #state.Fruits == 0 then
		text({ Size = UDim2.new(1, 0, 0, 40), Text = "Empty! Harvest ripe plants in your garden 🌱", TextColor3 = C.Ink, Parent = packList })
		return
	end
	for i, group in state.Fruits do
		local seed = Config.SeedById[group.Seed]
		local mutation = group.Mut and Config.Mutations[group.Mut]
		if seed then
			local row = make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = Color3.new(1, 1, 1), Parent = packList }, { corner(10), stroke(3, if mutation then mutation.Color:Lerp(C.Outline, 0.3) else C.Outline) })
			text({ Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(40, 40), Text = seed.Emoji, Parent = row })
			text({
				Position = UDim2.fromOffset(52, 8),
				Size = UDim2.new(0.6, -52, 0, 32),
				Text = string.format("%s%s x%d", if mutation then "[" .. mutation.Name .. "] " else "", seed.Name, group.Count),
				TextColor3 = if mutation then mutation.Color:Lerp(C.Ink, 0.35) else C.Ink,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.new(0.38, 0, 0, 32), Text = "💰 " .. Config.FormatNumber(group.Value), TextColor3 = Color3.fromRGB(190, 140, 20), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
		end
	end
end

function toggleBackpack()
	packPanel.Visible = not packPanel.Visible
	if packPanel.Visible then
		shopPanel.Visible = false
		pop(packPanel)
		renderBackpack()
	end
end

backpackButton.Activated:Connect(toggleBackpack)

--------------------------------------------------------------------------------
-- State from the server
--------------------------------------------------------------------------------

local displayedCoins = 0

Remotes.State.OnClientEvent:Connect(function(newState)
	local oldCoins = state and state.Coins
	state = newState

	if oldCoins and newState.Coins ~= oldCoins then
		local value = Instance.new("NumberValue")
		value.Value = displayedCoins
		value.Changed:Connect(function(v)
			displayedCoins = v
			coinLabel.Text = "💰 " .. Config.FormatNumber(v)
		end)
		local tween = TweenService:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Value = newState.Coins })
		tween.Completed:Connect(function()
			value:Destroy()
		end)
		tween:Play()
		pop(coinPill)
	else
		displayedCoins = newState.Coins
		coinLabel.Text = "💰 " .. Config.FormatNumber(newState.Coins)
	end

	renderHotbar()
	renderBackpack()
	renderShop()
end)

Remotes.Notify.OnClientEvent:Connect(toast)

--------------------------------------------------------------------------------
-- Weather
--------------------------------------------------------------------------------

local camera = workspace.CurrentCamera
local fxPart = make("Part", {
	Name = "WeatherFx",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.new(120, 1, 120),
	Parent = workspace,
})
local emitter = make("ParticleEmitter", {
	Enabled = false,
	EmissionDirection = Enum.NormalId.Bottom,
	LightInfluence = 0,
	Parent = fxPart,
})
local flash = make("ColorCorrectionEffect", { Brightness = 0, Parent = camera })
local currentWeather = nil

local PARTICLES = {
	Rain = { Rate = 600, Lifetime = NumberRange.new(1.2), Speed = NumberRange.new(70), Size = NumberSequence.new(0.12), Color = ColorSequence.new(Color3.fromRGB(170, 200, 255)), Transparency = NumberSequence.new(0.3), Squash = NumberSequence.new(-3) },
	Thunder = { Rate = 900, Lifetime = NumberRange.new(1), Speed = NumberRange.new(90), Size = NumberSequence.new(0.14), Color = ColorSequence.new(Color3.fromRGB(150, 170, 220)), Transparency = NumberSequence.new(0.3), Squash = NumberSequence.new(-3) },
	Snow = { Rate = 300, Lifetime = NumberRange.new(6), Speed = NumberRange.new(8), Size = NumberSequence.new(0.35), Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0), Squash = NumberSequence.new(0) },
	GoldenHour = { Rate = 80, Lifetime = NumberRange.new(5), Speed = NumberRange.new(4), Size = NumberSequence.new(0.4), Color = ColorSequence.new(Color3.fromRGB(255, 210, 80)), Transparency = NumberSequence.new(0.2), Squash = NumberSequence.new(0) },
	RainbowNight = {
		Rate = 150,
		Lifetime = NumberRange.new(5),
		Speed = NumberRange.new(5),
		Size = NumberSequence.new(0.45),
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
		}),
		Transparency = NumberSequence.new(0),
		Squash = NumberSequence.new(0),
	},
}

Remotes.Weather.OnClientEvent:Connect(function(id, duration)
	local weather = id and Config.WeatherById[id]
	currentWeather = id
	if weather then
		weatherName = weather.Emoji .. " " .. weather.Name
		weatherEndsAt = os.clock() + duration
		weatherBanner.Visible = true
		pop(weatherBanner)
		local look = PARTICLES[id]
		if look then
			for k, v in look do
				emitter[k] = v
			end
			emitter.Enabled = true
		end
	else
		weatherBanner.Visible = false
		emitter.Enabled = false
	end
end)

-- Lightning during thunderstorms
task.spawn(function()
	while true do
		task.wait(math.random(3, 8))
		if currentWeather == "Thunder" then
			flash.Brightness = 0.6
			TweenService:Create(flash, TweenInfo.new(0.5), { Brightness = 0 }):Play()
		end
	end
end)

--------------------------------------------------------------------------------
-- Continuous updates
--------------------------------------------------------------------------------

local lastTick = 0
RunService.Heartbeat:Connect(function()
	local t = os.clock()

	-- Rainbow fruits cycle color locally.
	for _, fruit in CollectionService:GetTagged("RainbowFruit") do
		if fruit:IsA("BasePart") then
			local offset = (fruit.Position.X + fruit.Position.Z) * 0.02
			fruit.Color = Color3.fromHSV((t * 0.4 + offset) % 1, 0.85, 1)
		end
	end

	fxPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))

	if t - lastTick < 0.25 then
		return
	end
	lastTick = t

	local restockText = Config.FormatTime(restockAt - t)
	restockLabel.Text = "🚚 Restock " .. restockText
	if shopPanel.Visible then
		shopSubtitle.Text = "🚚 New stock in " .. restockText
	end
	if weatherBanner.Visible then
		weatherLabel.Text = string.format("%s • %s", weatherName, Config.FormatTime(weatherEndsAt - t))
	end

	-- Close the shop if the player walks away.
	if openShopPrompt and openShopPrompt.Parent then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local parentPart = openShopPrompt.Parent
		if root and parentPart:IsA("BasePart") and (root.Position - parentPart.Position).Magnitude > 25 then
			shopPanel.Visible = false
		end
	end
end)

-- Fetch the shop stock right away on start.
task.spawn(function()
	local ok, data = pcall(function()
		return Remotes.GetShop:InvokeServer()
	end)
	if ok and data then
		shopData = data
		restockAt = os.clock() + data.RestockIn
		renderShop()
	end
end)
