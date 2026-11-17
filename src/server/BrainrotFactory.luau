-- Builds every brainrot character procedurally from Parts -- no toolbox
-- models, no external assets. A character is an anchored Model built in
-- model space (origin at the ground) and re-posed from stored local
-- CFrames; the Root part carries the Touched hitbox and the floating
-- name / rarity label.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))

local Factory = {}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = parent
	return p
end

-- Body dimensions per shape: width, height, depth, and the top height where
-- accessories sit.
local SHAPES = {
	boxy = { size = Vector3.new(3, 3.6, 2.2) },
	round = { size = Vector3.new(3.4, 3.4, 3.4), ball = true },
	tall = { size = Vector3.new(2.4, 4.8, 2.4) },
	can = { size = Vector3.new(3.2, 3.8, 3.2), cylinder = true },
}

local function buildAccessory(model, kind, topY, trim)
	if kind == "antenna" then
		part(model, "Antenna", Vector3.new(0.16, 1.4, 0.16), CFrame.new(0, topY + 0.7, 0), trim, Enum.Material.Metal)
		local tip = part(model, "AntennaTip", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, topY + 1.5, 0), trim, Enum.Material.Neon)
		tip.Shape = Enum.PartType.Ball
	elseif kind == "propeller" then
		part(model, "PropStick", Vector3.new(0.16, 0.8, 0.16), CFrame.new(0, topY + 0.4, 0), trim, Enum.Material.Metal)
		local blades = Instance.new("Part")
		blades.Name = "Propeller"
		blades.Size = Vector3.new(3.2, 0.12, 0.5)
		blades.CFrame = CFrame.new(0, topY + 0.85, 0)
		blades.Color = trim
		blades.Material = Enum.Material.SmoothPlastic
		blades.Anchored = true
		blades.CanCollide = false
		blades.CanTouch = false
		blades.CanQuery = false
		blades.Parent = model
		return blades
	elseif kind == "halo" then
		local halo = part(model, "Halo", Vector3.new(2.6, 0.16, 2.6),
			CFrame.new(0, topY + 0.8, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(255, 220, 90), Enum.Material.Neon)
		halo.Shape = Enum.PartType.Cylinder
		halo.Transparency = 0.25
	elseif kind == "horns" then
		for _, side in ipairs({ -1, 1 }) do
			local horn = part(model, "Horn", Vector3.new(0.6, 1, 0.6),
				CFrame.new(side * 1, topY + 0.35, 0) * CFrame.Angles(0, 0, side * -0.5), trim, Enum.Material.SmoothPlastic)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Pyramid
			mesh.Parent = horn
		end
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			part(model, "Wing", Vector3.new(0.18, 1.1, 2.2),
				CFrame.new(side * 1.7, topY - 0.9, -0.4) * CFrame.Angles(0, 0, side * 0.7),
				Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic)
		end
	elseif kind == "crown" then
		part(model, "Crown", Vector3.new(2, 0.55, 2), CFrame.new(0, topY + 0.3, 0),
			Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		for i = -1, 1 do
			local spike = part(model, "CrownSpike", Vector3.new(0.45, 0.8, 0.45),
				CFrame.new(i * 0.7, topY + 0.9, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Pyramid
			mesh.Parent = spike
		end
	end
	return nil
end

-- Create a brainrot record with its model parented to `parent`.
function Factory.Create(def, mutation: string, parent: Instance)
	local shape = SHAPES[def.shape] or SHAPES.boxy
	local size = shape.size
	local halfH = size.Y / 2

	local model = Instance.new("Model")
	model.Name = def.name

	local bodyColor = def.body
	local bodyMaterial = Enum.Material.SmoothPlastic
	if mutation == "Gold" then
		bodyColor = Color3.fromRGB(255, 190, 40)
		bodyMaterial = Enum.Material.Metal
	elseif mutation == "Diamond" then
		bodyColor = Color3.fromRGB(170, 240, 255)
		bodyMaterial = Enum.Material.Glass
	end

	local root = part(model, "Root", size, CFrame.new(0, halfH, 0), bodyColor, bodyMaterial)
	root.CanTouch = true
	if shape.ball then
		root.Shape = Enum.PartType.Ball
	elseif shape.cylinder then
		root.Shape = Enum.PartType.Cylinder
		root.CFrame = CFrame.new(0, halfH, 0) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Face on the +Z front: two eyes and a grin, all small Parts.
	local frontZ = size.Z / 2 + 0.06
	if shape.cylinder or shape.ball then
		frontZ = size.X / 2 + 0.06
	end
	local eyeY = halfH + size.Y * 0.12
	for _, side in ipairs({ -1, 1 }) do
		local eye = part(model, "Eye", Vector3.new(0.34, 0.34, 0.34),
			CFrame.new(side * size.X * 0.2, eyeY, frontZ), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic)
		eye.Shape = Enum.PartType.Ball
	end
	part(model, "Mouth", Vector3.new(size.X * 0.34, 0.16, 0.12),
		CFrame.new(0, eyeY - size.Y * 0.22, frontZ), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic)
	-- Feet, because a brainrot must stand for something.
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Foot", Vector3.new(0.9, 0.35, 1.3),
			CFrame.new(side * size.X * 0.24, 0.18, 0.25), def.trim, Enum.Material.SmoothPlastic)
	end

	local spinPart = buildAccessory(model, def.accessory, size.Y, def.trim)

	if mutation == "Diamond" or mutation == "Rainbow" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = mutation == "Diamond" and Color3.fromRGB(170, 240, 255) or Color3.fromRGB(255, 120, 220)
		sparkles.Parent = root
	end

	-- Floating label: name, then rarity + income.
	local income = Config.BrainrotIncome(def, mutation)
	local rarity = Config.Rarities[def.rarity]
	local mut = Config.Mutations[mutation]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(240, 62)
	gui.StudsOffset = Vector3.new(0, size.Y + 1.7, 0)
	gui.AlwaysOnTop = true
	gui.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = (mut.label ~= "" and (mut.label .. " ") or "") .. def.name
	nameLabel.Parent = gui

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubLabel"
	subLabel.Size = UDim2.new(1, 0, 0.45, 0)
	subLabel.Position = UDim2.new(0, 0, 0.55, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.FredokaOne
	subLabel.TextScaled = true
	subLabel.TextColor3 = rarity.color
	subLabel.TextStrokeTransparency = 0.3
	subLabel.Text = string.format("%s  +%s/s", rarity.label, Config.FormatCash(income))
	subLabel.Parent = gui

	model.PrimaryPart = root
	model.Parent = parent

	-- Placement: every part was built in model space (origin at the ground
	-- under the character, facing +Z). Remember each part's local CFrame so
	-- Place can re-pose the whole model exactly, with no pivot guessing.
	local parts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, { part = descendant, localCFrame = descendant.CFrame })
		end
	end

	local record = {
		def = def,
		mutation = mutation,
		income = income,
		model = model,
		root = root,
		bodyPart = root,
		spinPart = spinPart,
		parts = parts,
		ground = CFrame.new(0, 0, 0),
		state = "Wild",
		owner = nil,
		padIndex = nil,
		wanderTarget = Vector3.new(0, 0, 0),
		wanderWait = 0,
		spin = math.random() * math.pi * 2,
		hue = math.random(),
	}
	-- Pose the model so its ground origin sits at the given CFrame.
	record.place = function(groundCFrame: CFrame)
		record.ground = groundCFrame
		for _, entry in ipairs(parts) do
			entry.part.CFrame = groundCFrame * entry.localCFrame
		end
	end
	if mutation == "Rainbow" then
		State.rainbowModels[record] = true
	end
	return record
end

-- Rotate the propeller (if any) in model space, so the spin survives the
-- next Place instead of snapping back.
function Factory.SpinPropeller(record, angle: number)
	local spinPart = record.spinPart
	if not spinPart then
		return
	end
	for _, entry in ipairs(record.parts) do
		if entry.part == spinPart then
			entry.localCFrame = entry.localCFrame * CFrame.Angles(0, angle, 0)
			spinPart.CFrame = record.ground * entry.localCFrame
			return
		end
	end
end

function Factory.Destroy(record)
	State.rainbowModels[record] = nil
	if record.model then
		record.model:Destroy()
		record.model = nil
	end
end

-- A display / hatch egg in the rarity's color. Returns the model and a
-- Place function with the same ground-origin semantics as a brainrot's.
function Factory.CreateEgg(rarity: string, parent: Instance): (Model, (CFrame) -> ())
	local model = Instance.new("Model")
	model.Name = "BrainrotEgg"
	local color = Config.Rarities[rarity].color
	local egg = part(model, "Egg", Vector3.new(2.2, 2.9, 2.2), CFrame.new(0, 1.45, 0), color, Enum.Material.SmoothPlastic)
	egg.Shape = Enum.PartType.Ball
	local band = part(model, "EggBand", Vector3.new(2.35, 0.5, 2.35),
		CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	band.Shape = Enum.PartType.Cylinder
	model.PrimaryPart = egg
	model.Parent = parent
	local parts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, { part = descendant, localCFrame = descendant.CFrame })
		end
	end
	local function place(groundCFrame: CFrame)
		for _, entry in ipairs(parts) do
			entry.part.CFrame = groundCFrame * entry.localCFrame
		end
	end
	return model, place
end

return Factory
