-- Shared server state for BRAINROT BASE RUSH.
-- One table every server module reads and writes: who owns which base, what
-- sits on every pad, what is wild, what is being carried, and the wave clock.

local State = {}

-- players[Player] = {
--   baseIndex = number, cash = number, rebirths = number,
--   carried = brainrot|nil, pads = { [1..8] = brainrot|nil },
-- }
State.players = {}

-- bases[i] = { center = Vector3, platform = Part, pads = { Part },
--              signLabel = TextLabel|nil, owner = Player|nil }
State.bases = {}

-- A brainrot record: {
--   def = roster entry, mutation = string, income = number,
--   model = Model, root = Part, label = TextLabel,
--   state = "Wild"|"Carried"|"Pad"|"Stolen"|"Dropped",
--   owner = Player|nil, padIndex = number|nil,
--   wanderTarget = Vector3, wanderWait = number, spin = number,
-- }
State.wild = {} -- array of brainrot records in state "Wild"
State.allBrainrots = {} -- set of every live record (record -> true)
State.rainbowModels = {} -- records whose colors cycle (mutation Rainbow)

State.wave = {
	phase = "idle", -- idle | warning | sweep
	timeLeft = 0, -- seconds left in the current phase
	wall = nil, -- the wave Part while sweeping
	washedThisSweep = {}, -- players already washed by the current sweep
}

State.thief = {
	active = false,
	model = nil,
	target = nil, -- player being robbed
	record = nil, -- brainrot being stolen (state "Stolen")
	phase = "idle", -- idle | toBase | flee | escape
	escapePoint = nil,
	nextAt = 0, -- os.clock() time of the next attempt
}

function State.IsInBase(player, baseIndex: number): boolean
	local base = State.bases[baseIndex]
	if not base then
		return false
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local p = hrp.Position
	local c = base.center
	return math.abs(p.X - c.X) <= 30 and math.abs(p.Z - c.Z) <= 30
end

return State
