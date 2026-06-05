-- MythicWilds: BeastSystem
-- Spawns wild beasts in realm folders, manages encounter zones.

local GameData = require(game.ReplicatedStorage.Shared.GameData)
local BeastUtils = require(game.ReplicatedStorage.Shared.BeastUtils)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BeastSystem = {}

-- Active wild beast instances: [npcId] = { model, data, realm }
local wildBeasts = {}
local npcCounter = 0

local MAX_PER_REALM = 8
local RESPAWN_DELAY = 30  -- seconds before a new beast spawns after one is tamed/defeated

local RE = ReplicatedStorage:WaitForChild("Events", 10)

local function getRealmFolder(realmId)
	local ws = game:GetService("Workspace")
	return ws:FindFirstChild("Realms") and ws.Realms:FindFirstChild(realmId)
end

-- Pick a weighted-random beast for a given realm
local function rollBeastForRealm(realmId)
	local realm = GameData.Realms[realmId]
	if not realm then return nil end

	local pool = {}
	local total = 0
	for _, beastId in ipairs(realm.beasts) do
		local b = GameData.Beasts[beastId]
		if b and b.spawnW > 0 then
			total = total + b.spawnW
			table.insert(pool, { id=beastId, w=b.spawnW })
		end
	end
	if total == 0 then return nil end

	local r = math.random() * total
	local cum = 0
	for _, entry in ipairs(pool) do
		cum = cum + entry.w
		if r <= cum then return entry.id end
	end
	return pool[1].id
end

-- Find a spawn pad in the realm folder (Parts named "SpawnPad")
local function getSpawnPosition(realmFolder)
	if not realmFolder then return Vector3.new(0, 5, 0) end
	local pads = {}
	for _, v in ipairs(realmFolder:GetDescendants()) do
		if v:IsA("BasePart") and v.Name == "SpawnPad" then
			table.insert(pads, v)
		end
	end
	if #pads > 0 then
		local pad = pads[math.random(#pads)]
		return pad.Position + Vector3.new(0, 3, 0)
	end
	-- Fallback: random scatter in area
	return realmFolder.PrimaryPart and
		(realmFolder.PrimaryPart.Position + Vector3.new(math.random(-50,50), 3, math.random(-50,50)))
		or Vector3.new(math.random(-50,50), 5, math.random(-50,50))
end

-- Build a simple visual model for the beast (a coloured sphere + name billboard)
local function buildBeastModel(beastId, bloodline, level, position)
	local template = GameData.Beasts[beastId]
	local bl       = GameData.Bloodlines[bloodline]

	local model = Instance.new("Model")
	model.Name  = beastId

	-- Body
	local body = Instance.new("Part")
	body.Name          = "HumanoidRootPart"
	body.Anchored      = false
	body.CanCollide    = true
	body.Shape         = Enum.PartType.Ball
	body.Size          = Vector3.new(3, 3, 3) * (bloodline == "Primal" and 1.3 or 1)
	body.BrickColor    = BrickColor.new(GameData.Elements[template.element] and
		(template.element == "Fire" and "Bright orange" or
		 template.element == "Water" and "Bright blue" or
		 template.element == "Nature" and "Bright green" or
		 template.element == "Lightning" and "Bright yellow" or
		 template.element == "Earth" and "Reddish brown" or
		 template.element == "Ice" and "Light blue" or
		 template.element == "Shadow" and "Dark indigo" or
		 template.element == "Celestial" and "Bright yellow" or
		 template.element == "Void" and "Dark purple" or "White") or "Medium stone grey")
	body.Material      = Enum.Material.SmoothPlastic
	body.Position      = position
	body.Parent        = model

	-- Glow for rare bloodlines
	if bloodline ~= "Common" then
		local light = Instance.new("PointLight")
		light.Color      = bl.glow
		light.Brightness = bloodline == "Secret" and 5 or bloodline == "Void" and 4 or 2
		light.Range      = 12
		light.Parent     = body
	end

	-- Billboard name tag
	local bb = Instance.new("BillboardGui")
	bb.Adornee   = body
	bb.Size      = UDim2.new(0, 160, 0, 50)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent    = body

	local nameLabel = Instance.new("TextLabel", bb)
	nameLabel.Size            = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text            = template.label .. " Lv." .. level
	nameLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
	nameLabel.Font            = Enum.Font.GothamBold
	nameLabel.TextScaled      = true
	nameLabel.TextStrokeTransparency = 0.5

	local bloodLabel = Instance.new("TextLabel", bb)
	bloodLabel.Position  = UDim2.new(0, 0, 0.6, 0)
	bloodLabel.Size      = UDim2.new(1, 0, 0.4, 0)
	bloodLabel.BackgroundTransparency = 1
	bloodLabel.Text      = "[" .. (bl.label or bloodline) .. "]"
	bloodLabel.TextColor3= bl.glow
	bloodLabel.Font      = Enum.Font.Gotham
	bloodLabel.TextScaled= true

	-- Humanoid for health bar
	local hum = Instance.new("Humanoid")
	hum.MaxHealth   = BeastUtils.CalcStats(template.base, bloodline, level).hp
	hum.Health      = hum.MaxHealth
	hum.WalkSpeed   = 8
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = body
	return model
end

-- Spawn one wild beast in a realm
function BeastSystem.SpawnWild(realmId, forcedBeastId)
	local folder = getRealmFolder(realmId)
	local realmData = GameData.Realms[realmId]
	if not realmData then return end

	-- Count current beasts
	local count = 0
	for _, entry in pairs(wildBeasts) do
		if entry.realm == realmId then count = count + 1 end
	end
	if count >= MAX_PER_REALM then return end

	local beastId   = forcedBeastId or rollBeastForRealm(realmId)
	if not beastId then return end

	local level     = math.random(
		math.max(1, realmData.reqLevel),
		realmData.reqLevel + 10
	)
	local bloodline = GameData.RollBloodline(0)
	local position  = getSpawnPosition(folder)

	local model     = buildBeastModel(beastId, bloodline, level, position)
	model.Parent    = folder or game.Workspace

	npcCounter = npcCounter + 1
	local npcId = "wild_" .. npcCounter

	wildBeasts[npcId] = {
		npcId    = npcId,
		model    = model,
		beastId  = beastId,
		bloodline= bloodline,
		level    = level,
		realm    = realmId,
		inBattle = false,
		currentHP= BeastUtils.CalcStats(GameData.Beasts[beastId].base, bloodline, level).hp,
	}

	-- Broadcast new spawn (client updates minimap / nearby UI)
	if RE then
		local ev = RE:FindFirstChild("WildBeastSpawned")
		if ev then ev:FireAllClients(npcId, beastId, bloodline, level, realmId) end
	end

	-- Global announcement for mythic/secret
	local rarity = GameData.Beasts[beastId].rarity
	if rarity == "Mythic" or rarity == "Secret" then
		if RE then
			local ann = RE:FindFirstChild("GlobalAnnouncement")
			if ann then
				ann:FireAllClients(
					"✦ A " .. (bloodline ~= "Common" and "[" .. bloodline .. "] " or "") ..
					GameData.Beasts[beastId].label .. " has appeared in " ..
					realmData.label .. "! ✦"
				)
			end
		end
	end

	return npcId
end

-- Remove a wild beast (tamed, defeated, or despawned)
function BeastSystem.RemoveWild(npcId)
	local entry = wildBeasts[npcId]
	if not entry then return end
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	wildBeasts[npcId] = nil
end

-- Get wild beast data by npcId
function BeastSystem.GetWild(npcId)
	return wildBeasts[npcId]
end

-- Damage a wild beast; returns true if defeated
function BeastSystem.DamageWild(npcId, amount)
	local entry = wildBeasts[npcId]
	if not entry then return true end
	entry.currentHP = math.max(0, entry.currentHP - amount)
	-- Update humanoid
	local hum = entry.model and entry.model:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = entry.currentHP end
	return entry.currentHP <= 0
end

-- Auto-populate realms with beasts on start, then maintain population
function BeastSystem.StartPopulation()
	-- Initial spawn
	for _, realmId in ipairs(GameData.RealmOrder) do
		for _ = 1, MAX_PER_REALM do
			BeastSystem.SpawnWild(realmId)
			task.wait(0.1)
		end
	end

	-- Maintenance loop
	task.spawn(function()
		while true do
			task.wait(RESPAWN_DELAY)
			for _, realmId in ipairs(GameData.RealmOrder) do
				local count = 0
				for _, e in pairs(wildBeasts) do
					if e.realm == realmId then count = count + 1 end
				end
				local toSpawn = MAX_PER_REALM - count
				for _ = 1, toSpawn do
					BeastSystem.SpawnWild(realmId)
					task.wait(0.5)
				end
			end
		end
	end)
end

return BeastSystem
