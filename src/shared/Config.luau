-- BRAINROT BASE RUSH -- shared configuration.
-- Rarity ladder, mutation table, the brainrot roster and every economy number
-- live here so the server, the client HUD and the labels all agree.

local Config = {}

Config.GameName = "BRAINROT BASE RUSH"

-- Economy ---------------------------------------------------------------
Config.StartingCash = 50 -- modal awal, biar telur pertama terasa dekat
Config.EggPrice = 200
Config.PadsPerBase = 8
Config.MaxWild = 12 -- wild brainrots alive on the lane at once
Config.WildRespawnSeconds = 3

-- Rebirth: cost grows x4 each time, income multiplier doubles each time.
Config.RebirthBaseCost = 10000
Config.RebirthCostGrowth = 4

function Config.RebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths))
end

function Config.IncomeMultiplier(rebirths: number): number
	return 2 ^ rebirths -- +100% per rebirth
end

-- Waves -----------------------------------------------------------------
Config.WaveIdleSeconds = 80 -- calm time between tsunamis
Config.WaveWarningSeconds = 10 -- banner + countdown before the sweep
Config.WaveSweepSeconds = 9 -- the wall crossing the map

-- Thief bot ---------------------------------------------------------------
Config.ThiefFirstSeconds = 120
Config.ThiefMinGapSeconds = 150
Config.ThiefMaxGapSeconds = 210
Config.ThiefSpeed = 26

-- Rarities ----------------------------------------------------------------
-- income = Cash per second a pad brainrot of this rarity earns (before
-- mutation and rebirth multipliers). weight = spawn / egg roll weight.
Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "BrainrotGod" }

Config.Rarities = {
	Common = { income = 2, weight = 46, color = Color3.fromRGB(168, 172, 180), label = "Common" },
	Rare = { income = 7, weight = 28, color = Color3.fromRGB(64, 156, 255), label = "Rare" },
	Epic = { income = 22, weight = 15, color = Color3.fromRGB(178, 92, 255), label = "Epic" },
	Legendary = { income = 75, weight = 7, color = Color3.fromRGB(255, 176, 32), label = "Legendary" },
	Mythic = { income = 300, weight = 3, color = Color3.fromRGB(255, 64, 128), label = "Mythic" },
	BrainrotGod = { income = 1500, weight = 1, color = Color3.fromRGB(255, 235, 120), label = "BRAINROT GOD" },
}

-- Mutations ---------------------------------------------------------------
Config.MutationOrder = { "None", "Gold", "Diamond", "Rainbow" }

Config.Mutations = {
	None = { mult = 1, weight = 72, label = "" },
	Gold = { mult = 2, weight = 18, label = "GOLD" },
	Diamond = { mult = 5, weight = 7, label = "DIAMOND" },
	Rainbow = { mult = 10, weight = 3, label = "RAINBOW" },
}

-- Roster ------------------------------------------------------------------
-- Every character is built procedurally from Parts by BrainrotFactory:
-- shape picks the body, accessory is worn on the head, colors dress it.
-- Names are original Indonesian-flavoured absurdity, none borrowed.
Config.Roster = {
	{ name = "Bambang Blender", rarity = "Common", shape = "can", accessory = "propeller",
		body = Color3.fromRGB(200, 205, 210), trim = Color3.fromRGB(90, 95, 105) },
	{ name = "Siti Spatula", rarity = "Common", shape = "tall", accessory = "antenna",
		body = Color3.fromRGB(240, 170, 90), trim = Color3.fromRGB(140, 90, 40) },
	{ name = "Udin Odong-Odong", rarity = "Common", shape = "boxy", accessory = "horns",
		body = Color3.fromRGB(120, 200, 120), trim = Color3.fromRGB(60, 120, 60) },
	{ name = "Dedi Dinding", rarity = "Common", shape = "boxy", accessory = "none",
		body = Color3.fromRGB(178, 160, 140), trim = Color3.fromRGB(110, 95, 75) },

	{ name = "Budi Bantal Terbang", rarity = "Rare", shape = "round", accessory = "wings",
		body = Color3.fromRGB(245, 245, 250), trim = Color3.fromRGB(64, 156, 255) },
	{ name = "Nenek Wifi", rarity = "Rare", shape = "tall", accessory = "antenna",
		body = Color3.fromRGB(190, 130, 220), trim = Color3.fromRGB(255, 220, 90) },
	{ name = "Tono Toples", rarity = "Rare", shape = "can", accessory = "halo",
		body = Color3.fromRGB(150, 220, 230), trim = Color3.fromRGB(70, 140, 160) },
	{ name = "Sari Sandal Jepit", rarity = "Rare", shape = "boxy", accessory = "propeller",
		body = Color3.fromRGB(255, 140, 160), trim = Color3.fromRGB(70, 170, 90) },

	{ name = "Ratu Rice Cooker", rarity = "Epic", shape = "can", accessory = "crown",
		body = Color3.fromRGB(250, 250, 245), trim = Color3.fromRGB(178, 92, 255) },
	{ name = "Pak Haji Helicopter", rarity = "Epic", shape = "round", accessory = "propeller",
		body = Color3.fromRGB(240, 240, 235), trim = Color3.fromRGB(60, 160, 90) },
	{ name = "Joko Jendela", rarity = "Epic", shape = "boxy", accessory = "antenna",
		body = Color3.fromRGB(120, 180, 240), trim = Color3.fromRGB(240, 240, 250) },
	{ name = "Rina Radio Rusak", rarity = "Epic", shape = "tall", accessory = "antenna",
		body = Color3.fromRGB(230, 90, 90), trim = Color3.fromRGB(60, 60, 70) },

	{ name = "Sultan Solder", rarity = "Legendary", shape = "tall", accessory = "crown",
		body = Color3.fromRGB(255, 200, 60), trim = Color3.fromRGB(150, 60, 200) },
	{ name = "Dewi Dispenser", rarity = "Legendary", shape = "can", accessory = "halo",
		body = Color3.fromRGB(120, 220, 255), trim = Color3.fromRGB(255, 120, 160) },
	{ name = "Kapten Kompor", rarity = "Legendary", shape = "boxy", accessory = "horns",
		body = Color3.fromRGB(90, 100, 120), trim = Color3.fromRGB(255, 120, 40) },

	{ name = "Maharaja Mie Instan", rarity = "Mythic", shape = "round", accessory = "crown",
		body = Color3.fromRGB(255, 210, 80), trim = Color3.fromRGB(255, 64, 128) },
	{ name = "Putri Panci Presto", rarity = "Mythic", shape = "can", accessory = "wings",
		body = Color3.fromRGB(230, 235, 245), trim = Color3.fromRGB(255, 64, 128) },

	{ name = "Kaisar Kulkas Dua Pintu", rarity = "BrainrotGod", shape = "boxy", accessory = "halo",
		body = Color3.fromRGB(250, 250, 255), trim = Color3.fromRGB(255, 215, 60) },
	{ name = "Sesepuh Sambal Terasi", rarity = "BrainrotGod", shape = "round", accessory = "crown",
		body = Color3.fromRGB(255, 90, 60), trim = Color3.fromRGB(255, 235, 120) },
}

-- Lookups -----------------------------------------------------------------
Config.RosterByName = {}
for _, def in ipairs(Config.Roster) do
	Config.RosterByName[def.name] = def
end

local function rollWeighted(order, table_, key)
	local total = 0
	for _, name in ipairs(order) do
		total += table_[name].weight
	end
	local roll = math.random() * total
	for _, name in ipairs(order) do
		roll -= table_[name].weight
		if roll <= 0 then
			return name
		end
	end
	return order[1]
end

function Config.RollRarity(): string
	return rollWeighted(Config.RarityOrder, Config.Rarities)
end

function Config.RollMutation(): string
	return rollWeighted(Config.MutationOrder, Config.Mutations)
end

-- Pick a random roster character of the given rarity.
function Config.RandomCharacterOfRarity(rarity: string)
	local pool = {}
	for _, def in ipairs(Config.Roster) do
		if def.rarity == rarity then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Cash a brainrot earns per second, before the rebirth multiplier.
function Config.BrainrotIncome(def, mutation: string): number
	local rarity = Config.Rarities[def.rarity]
	local mut = Config.Mutations[mutation] or Config.Mutations.None
	return rarity.income * mut.mult
end

-- 1234567 -> "1,234,567"
function Config.FormatCash(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

return Config
