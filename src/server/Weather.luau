-- Random weather events that change the lighting and give plants a chance to mutate.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local Garden = require(script.Parent.Garden)

local Weather = {}

local current = nil
local endsAt = 0

local LOOKS = {
	Clear = { ClockTime = 14, Brightness = 2.2, OutdoorAmbient = Color3.fromRGB(150, 150, 150), Density = 0.25, AtmosphereColor = Color3.fromRGB(200, 225, 255) },
	Rain = { ClockTime = 14, Brightness = 1, OutdoorAmbient = Color3.fromRGB(110, 115, 130), Density = 0.45, AtmosphereColor = Color3.fromRGB(150, 160, 180) },
	Snow = { ClockTime = 14, Brightness = 1.6, OutdoorAmbient = Color3.fromRGB(170, 190, 220), Density = 0.5, AtmosphereColor = Color3.fromRGB(230, 240, 255) },
	Thunder = { ClockTime = 17, Brightness = 0.6, OutdoorAmbient = Color3.fromRGB(70, 70, 100), Density = 0.55, AtmosphereColor = Color3.fromRGB(90, 90, 120) },
	GoldenHour = { ClockTime = 17.7, Brightness = 2.5, OutdoorAmbient = Color3.fromRGB(200, 150, 90), Density = 0.35, AtmosphereColor = Color3.fromRGB(255, 200, 120) },
	RainbowNight = { ClockTime = 0, Brightness = 1, OutdoorAmbient = Color3.fromRGB(150, 110, 200), Density = 0.3, AtmosphereColor = Color3.fromRGB(200, 150, 255) },
}

local function applyLook(id: string)
	local look = LOOKS[id] or LOOKS.Clear
	local info = TweenInfo.new(4, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, { ClockTime = look.ClockTime, Brightness = look.Brightness, OutdoorAmbient = look.OutdoorAmbient }):Play()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, { Density = look.Density, Color = look.AtmosphereColor }):Play()
	end
end

local function pickWeather()
	local total = 0
	for _, weather in Config.Weathers do
		total += weather.Weight
	end
	local roll = math.random() * total
	for _, weather in Config.Weathers do
		roll -= weather.Weight
		if roll <= 0 then
			return weather
		end
	end
	return Config.Weathers[1]
end

function Weather.Init()
	task.spawn(function()
		while true do
			task.wait(math.random(Config.WeatherMinGap, Config.WeatherMaxGap))

			local weather = pickWeather()
			current = weather
			endsAt = os.clock() + weather.Duration
			applyLook(weather.Id)
			Net.Weather:FireAllClients(weather.Id, weather.Duration)
			Net.NotifyAll(string.format("%s %s has started!", weather.Emoji, weather.Name), "epic")

			while os.clock() < endsAt do
				task.wait(Config.WeatherTick)
				Garden.WeatherTick(weather)
			end

			current = nil
			applyLook("Clear")
			Net.Weather:FireAllClients(nil, 0)
		end
	end)
end

-- Send the ongoing weather to a player who just joined.
function Weather.SendCurrent(player: Player)
	if current then
		Net.Weather:FireClient(player, current.Id, math.max(0, endsAt - os.clock()))
	end
end

return Weather
