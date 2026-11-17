-- THREAT 1 -- the TSUNAMI WAVE. Every cycle: a calm countdown, a 10 second
-- warning, then a giant translucent wall of water sweeps the map from
-- south to north. A player caught outside their own base while carrying a
-- brainrot loses it: the brainrot washes back to the wild lane.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))

local WaveController = {}

local function buildWall(): Part
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(420, 64, 10)
	wall.Color = Color3.fromRGB(50, 150, 255)
	wall.Transparency = 0.35
	wall.Material = Enum.Material.Glass
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanTouch = false
	wall.CanQuery = false
	wall.CFrame = CFrame.new(0, 28, -250)
	wall.Parent = Workspace
	local foam = Instance.new("Part")
	foam.Name = "Foam"
	foam.Size = Vector3.new(420, 7, 11)
	foam.Color = Color3.fromRGB(240, 250, 255)
	foam.Transparency = 0.2
	foam.Material = Enum.Material.SmoothPlastic
	foam.Anchored = true
	foam.CanCollide = false
	foam.CanTouch = false
	foam.CanQuery = false
	foam.CFrame = CFrame.new(0, 58, -250)
	foam.Parent = wall -- rides along by being repositioned with the wall below
	return wall
end

-- hooks: { setWave(phase, secondsLeft), washCarried(player), notifyAll(text) }
function WaveController.Start(hooks)
	task.spawn(function()
		while true do
			-- Calm.
			State.wave.phase = "idle"
			for t = Config.WaveIdleSeconds, 1, -1 do
				State.wave.timeLeft = t
				hooks.setWave("idle", t)
				task.wait(1)
			end
			-- Warning.
			State.wave.phase = "warning"
			hooks.notifyAll("TSUNAMI DATANG! Bawa brainrotmu pulang ke base!")
			for t = Config.WaveWarningSeconds, 1, -1 do
				State.wave.timeLeft = t
				hooks.setWave("warning", t)
				task.wait(1)
			end
			-- Sweep.
			State.wave.phase = "sweep"
			State.wave.timeLeft = 0
			State.wave.washedThisSweep = {}
			hooks.setWave("sweep", 0)
			local wall = buildWall()
			State.wave.wall = wall
			local foam = wall:FindFirstChild("Foam")
			local startZ, endZ = -250, 250
			local elapsed = 0
			while elapsed < Config.WaveSweepSeconds do
				local dt = task.wait(0.1)
				elapsed += dt
				local z = startZ + (endZ - startZ) * math.min(elapsed / Config.WaveSweepSeconds, 1)
				wall.CFrame = CFrame.new(0, 28, z)
				if foam then
					foam.CFrame = CFrame.new(0, 58, z)
				end
				for player, data in pairs(State.players) do
					if data.carried and not State.wave.washedThisSweep[player] then
						if not State.IsInBase(player, data.baseIndex) then
							State.wave.washedThisSweep[player] = true
							hooks.washCarried(player)
						end
					end
				end
			end
			wall:Destroy()
			State.wave.wall = nil
		end
	end)
end

return WaveController
