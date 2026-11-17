-- BRAINROT BASE RUSH -- server bootstrap and economy.
-- Server-authoritative: catching, carrying, pads, income, the egg shop,
-- rebirths, the tsunami and the thief bot all live here or in the modules
-- beside this script. Clients only draw the HUD and ask.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script:WaitForChild("State"))
local Factory = require(script:WaitForChild("BrainrotFactory"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local WaveController = require(script:WaitForChild("WaveController"))
local ThiefBot = require(script:WaitForChild("ThiefBot"))

-- Remotes -------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage
local remoteEvents = {}
for _, name in ipairs({ "BuyEgg", "RequestRebirth", "Notify", "WaveState" }) do
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotes
	remoteEvents[name] = ev
end

local function notify(player: Player, text: string)
	remoteEvents.Notify:FireClient(player, text)
end

local function notifyAll(text: string)
	remoteEvents.Notify:FireAllClients(text)
end

-- Brainrot records ------------------------------------------------------------
local brainrotFolder = Instance.new("Folder")
brainrotFolder.Name = "Brainrots"
brainrotFolder.Parent = Workspace

local function randomLanePoint(): Vector3
	return Vector3.new(math.random(-15, 15), 0, math.random(-185, 185))
end

local function removeFromWild(record)
	for i, other in ipairs(State.wild) do
		if other == record then
			table.remove(State.wild, i)
			return
		end
	end
end

local function destroyRecord(record)
	removeFromWild(record)
	State.allBrainrots[record] = nil
	Factory.Destroy(record)
end

local function washToWild(record)
	record.state = "Wild"
	record.owner = nil
	record.padIndex = nil
	local pos = randomLanePoint()
	record.place(CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	record.wanderTarget = randomLanePoint()
	record.wanderWait = 0
	table.insert(State.wild, record)
end

local function tryCatch(player: Player, record)
	local data = State.players[player]
	if not data or data.hatching then
		return
	end
	if record.state ~= "Wild" and not (record.state == "Dropped" and record.owner == player) then
		return
	end
	if data.carried then
		notify(player, "Tanganmu penuh! Simpan dulu ke pad kosong di base-mu.")
		return
	end
	if record.state == "Wild" then
		removeFromWild(record)
	end
	record.state = "Carried"
	record.owner = player
	data.carried = record
	player:SetAttribute("Carrying", record.def.name)
	notify(player, string.format("Kamu menangkap %s! Bawa ke pad kosong di base-mu.", record.def.name))
end

local function registerRecord(record)
	State.allBrainrots[record] = true
	record.root.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			tryCatch(player, record)
		end
	end)
end

local function spawnWild()
	local rarity = Config.RollRarity()
	local def = Config.RandomCharacterOfRarity(rarity)
	local record = Factory.Create(def, Config.RollMutation(), brainrotFolder)
	record.state = "Wild"
	local pos = randomLanePoint()
	record.place(CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	record.wanderTarget = randomLanePoint()
	table.insert(State.wild, record)
	registerRecord(record)
end

-- Pads ------------------------------------------------------------------------
local function resetPadVisual(baseIndex: number, padIndex: number)
	local pad = State.bases[baseIndex].pads[padIndex]
	pad.Color = Color3.fromRGB(245, 245, 245)
	pad.Material = Enum.Material.SmoothPlastic
end

local function deposit(player: Player, baseIndex: number, padIndex: number)
	local data = State.players[player]
	local record = data.carried
	if not record then
		return
	end
	data.carried = nil
	player:SetAttribute("Carrying", "")
	record.state = "Pad"
	record.padIndex = padIndex
	data.pads[padIndex] = record
	local pad = State.bases[baseIndex].pads[padIndex]
	record.place(CFrame.new(pad.Position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, record.spin, 0))
	pad.Color = Color3.fromRGB(120, 255, 140)
	pad.Material = Enum.Material.Neon
	notify(player, string.format("%s disimpan di pad %d: +%s Cash/detik!", record.def.name, padIndex,
		Config.FormatCash(record.income * Config.IncomeMultiplier(data.rebirths))))
end

-- Economy ---------------------------------------------------------------------
local function syncCash(player: Player, data)
	if data.cashValue then
		data.cashValue.Value = math.floor(data.cash)
	end
end

local function computeIncome(data): number
	local sum = 0
	for _, record in pairs(data.pads) do
		if record then
			sum += record.income
		end
	end
	return sum * Config.IncomeMultiplier(data.rebirths)
end

local shopRefs = nil

local function buyEgg(player: Player)
	local data = State.players[player]
	if not data or data.hatching then
		return
	end
	if data.carried then
		notify(player, "Tanganmu penuh! Simpan dulu brainrotmu ke base.")
		return
	end
	if data.cash < Config.EggPrice then
		notify(player, string.format("Cash kurang! Telur harganya %s Cash.", Config.FormatCash(Config.EggPrice)))
		return
	end
	data.cash -= Config.EggPrice
	syncCash(player, data)
	data.hatching = true
	local rarity = Config.RollRarity()
	local mutation = Config.RollMutation()
	local def = Config.RandomCharacterOfRarity(rarity)
	task.spawn(function()
		local egg, placeEgg = Factory.CreateEgg(rarity, Workspace)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local basePos = hrp and (hrp.Position + hrp.CFrame.LookVector * 5) or (shopRefs and shopRefs.shopPosition) or Vector3.new(30, 0, 8)
		placeEgg(CFrame.new(Vector3.new(basePos.X, 0, basePos.Z)))
		for i = 1, 8 do
			if not State.players[player] then
				egg:Destroy()
				return
			end
			placeEgg(CFrame.new(Vector3.new(basePos.X, 0, basePos.Z)) * CFrame.Angles(0, 0, math.rad(i % 2 == 0 and 7 or -7)))
			task.wait(0.09)
		end
		egg:Destroy()
		if not State.players[player] then
			return
		end
		data.hatching = false
		if data.carried then
			-- Caught something mid-hatch (should not happen): refund the egg.
			data.cash += Config.EggPrice
			syncCash(player, data)
			notify(player, "Telurnya batal menetas - Cash dikembalikan.")
			return
		end
		local record = Factory.Create(def, mutation, brainrotFolder)
		record.state = "Carried"
		record.owner = player
		data.carried = record
		registerRecord(record)
		player:SetAttribute("Carrying", record.def.name)
		local rarityInfo = Config.Rarities[rarity]
		notify(player, string.format("Telur menetas: %s (%s)! Bawa pulang ke base!", def.name, rarityInfo.label))
	end)
end

local function doRebirth(player: Player)
	local data = State.players[player]
	if not data then
		return
	end
	local cost = Config.RebirthCost(data.rebirths)
	if data.cash < cost then
		notify(player, string.format("Rebirth butuh %s Cash. Cash-mu baru %s.", Config.FormatCash(cost), Config.FormatCash(data.cash)))
		return
	end
	for padIndex, record in pairs(data.pads) do
		if record then
			destroyRecord(record)
			resetPadVisual(data.baseIndex, padIndex)
		end
	end
	data.pads = {}
	if data.carried then
		local carried = data.carried
		data.carried = nil
		player:SetAttribute("Carrying", "")
		washToWild(carried)
	end
	data.cash = 0
	data.rebirths += 1
	if data.rebirthValue then
		data.rebirthValue.Value = data.rebirths
	end
	syncCash(player, data)
	notifyAll(string.format("%s REBIRTH! Penghasilan permanennya sekarang x%d!", player.DisplayName, Config.IncomeMultiplier(data.rebirths)))
end

-- Persistence (session-only fallback when DataStore is unavailable) -----------
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("BrainrotBaseRush_v1")
	end)
	if ok then
		store = result
	end
end

local function loadData(player: Player)
	if not store then
		return nil
	end
	local ok, saved = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if ok and type(saved) == "table" then
		return saved
	end
	return nil
end

local function saveData(player: Player, data)
	if not store then
		return
	end
	local pads = {}
	for i = 1, Config.PadsPerBase do
		local record = data.pads[i]
		if record then
			pads[tostring(i)] = { def = record.def.name, mutation = record.mutation }
		end
	end
	pcall(function()
		store:SetAsync("player_" .. player.UserId, {
			cash = math.floor(data.cash),
			rebirths = data.rebirths,
			pads = pads,
		})
	end)
end

-- Players -----------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	local data = {
		cash = Config.StartingCash,
		rebirths = 0,
		pads = {},
		carried = nil,
		hatching = false,
		baseIndex = 1,
	}
	for i = 1, 4 do
		if not State.bases[i].owner then
			State.bases[i].owner = player
			data.baseIndex = i
			break
		end
	end
	State.players[player] = data
	player:SetAttribute("Carrying", "")
	player:SetAttribute("IncomePerSec", 0)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = math.floor(data.cash)
	cashValue.Parent = stats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = stats
	stats.Parent = player
	data.cashValue = cashValue
	data.rebirthValue = rebirthValue

	local base = State.bases[data.baseIndex]
	if base and base.signLabel then
		base.signLabel.Text = string.format("BASE %d - %s", data.baseIndex, player.DisplayName)
	end

	local saved = loadData(player)
	if saved then
		data.cash = saved.cash or data.cash
		data.rebirths = saved.rebirths or 0
		rebirthValue.Value = data.rebirths
		syncCash(player, data)
		if type(saved.pads) == "table" then
			for key, entry in pairs(saved.pads) do
				local padIndex = tonumber(key)
				local def = entry and Config.RosterByName[entry.def]
				if padIndex and def and padIndex >= 1 and padIndex <= Config.PadsPerBase then
					local record = Factory.Create(def, entry.mutation or "None", brainrotFolder)
					record.state = "Pad"
					record.owner = player
					record.padIndex = padIndex
					data.pads[padIndex] = record
					local pad = State.bases[data.baseIndex].pads[padIndex]
					record.place(CFrame.new(pad.Position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, record.spin, 0))
					pad.Color = Color3.fromRGB(120, 255, 140)
					pad.Material = Enum.Material.Neon
					registerRecord(record)
				end
			end
		end
	end

	local function onCharacter(character: Model)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		local b = State.bases[data.baseIndex]
		if hrp and b then
			local spawnPos = b.center + Vector3.new(0, 4, b.center.Z > 0 and -20 or 20)
			hrp.CFrame = CFrame.new(spawnPos, b.center)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	remoteEvents.WaveState:FireClient(player, State.wave.phase, State.wave.timeLeft)
end

local function onPlayerRemoving(player: Player)
	local data = State.players[player]
	if not data then
		return
	end
	saveData(player, data)
	for _, record in pairs(data.pads) do
		if record then
			destroyRecord(record)
		end
	end
	if data.carried then
		destroyRecord(data.carried)
	end
	local base = State.bases[data.baseIndex]
	if base then
		if base.owner == player then
			base.owner = nil
		end
		if base.signLabel then
			base.signLabel.Text = "BASE " .. data.baseIndex
		end
	end
	State.players[player] = nil
end

-- Boot ---------------------------------------------------------------------------
shopRefs = WorldBuilder.Build()

for baseIndex, base in pairs(State.bases) do
	for padIndex, pad in ipairs(base.pads) do
		local bi, pi = baseIndex, padIndex
		pad.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local data = State.players[player]
			if not data or data.baseIndex ~= bi then
				return
			end
			if data.carried and not data.pads[pi] then
				deposit(player, bi, pi)
			end
		end)
	end
	if base.rebirthPrompt then
		base.rebirthPrompt.Triggered:Connect(function(player)
			if State.bases[baseIndex].owner == player then
				doRebirth(player)
			else
				notify(player, "Kristal ini punya base orang lain!")
			end
		end)
	end
end

if shopRefs and shopRefs.shopPrompt then
	shopRefs.shopPrompt.Triggered:Connect(function(player)
		buyEgg(player)
	end)
end

remoteEvents.BuyEgg.OnServerEvent:Connect(function(player)
	buyEgg(player)
end)
remoteEvents.RequestRebirth.OnServerEvent:Connect(function(player)
	doRebirth(player)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(onPlayerRemoving)
game:BindToClose(function()
	for player, data in pairs(State.players) do
		saveData(player, data)
	end
end)

-- Wild population ------------------------------------------------------------------
task.spawn(function()
	while true do
		if #State.wild < Config.MaxWild then
			spawnWild()
		end
		task.wait(Config.WildRespawnSeconds)
	end
end)

-- Income ------------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, data in pairs(State.players) do
			local income = computeIncome(data)
			if income > 0 then
				data.cash += income
				syncCash(player, data)
			end
			player:SetAttribute("IncomePerSec", income)
		end
	end
end)

-- Animation / movement tick --------------------------------------------------------------
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	-- Wild brainrots wander the lane.
	for _, record in ipairs(State.wild) do
		if record.model and record.root then
			local pos = record.ground.Position
			local target = record.wanderTarget
			local delta = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
			if delta.Magnitude < 2 then
				record.wanderWait -= dt
				if record.wanderWait <= 0 then
					record.wanderTarget = randomLanePoint()
					record.wanderWait = math.random(1, 4)
				end
			else
				local step = delta.Unit * math.min(delta.Magnitude, 6 * dt)
				local newPos = pos + step
				local bob = math.abs(math.sin(elapsed * 3 + record.spin)) * 0.35
				local look = Vector3.new(newPos.X + delta.X, bob, newPos.Z + delta.Z)
				record.place(CFrame.lookAt(Vector3.new(newPos.X, bob, newPos.Z), look))
			end
			Factory.SpinPropeller(record, dt * 9)
		end
	end
	-- Carried brainrots ride above their player's head.
	for player, data in pairs(State.players) do
		local record = data.carried
		if record and record.model then
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local bob = math.sin(elapsed * 4) * 0.25
				record.place(hrp.CFrame * CFrame.new(0, 4.4 + bob, 0))
				Factory.SpinPropeller(record, dt * 9)
			end
		end
	end
	-- Rainbow mutations cycle their colors.
	for record in pairs(State.rainbowModels) do
		if record.bodyPart then
			record.hue = (record.hue + dt * 0.12) % 1
			record.bodyPart.Color = Color3.fromHSV(record.hue, 0.55, 1)
		end
	end
end)

-- Threats -----------------------------------------------------------------------------------
WaveController.Start({
	setWave = function(phase, secondsLeft)
		remoteEvents.WaveState:FireAllClients(phase, secondsLeft)
	end,
	washCarried = function(player)
		local data = State.players[player]
		if data and data.carried then
			local record = data.carried
			data.carried = nil
			player:SetAttribute("Carrying", "")
			washToWild(record)
			notify(player, string.format("%s hanyut terbawa tsunami dan kembali ke jalanan!", record.def.name))
		end
	end,
	notifyAll = notifyAll,
})

ThiefBot.Start({
	notifyAll = notifyAll,
	notifyPlayer = notify,
	stealFromPad = function(record)
		local owner = record.owner
		local data = owner and State.players[owner]
		if data and record.padIndex then
			data.pads[record.padIndex] = nil
			resetPadVisual(data.baseIndex, record.padIndex)
		end
		record.padIndex = nil
		record.state = "Stolen"
	end,
	dropStolen = function(record, position)
		record.state = "Dropped"
		record.place(CFrame.new(Vector3.new(position.X, 0, position.Z)) * CFrame.Angles(0, record.spin, 0))
	end,
	loseStolen = function(record)
		destroyRecord(record)
	end,
})

print(Config.GameName .. " server started.")
