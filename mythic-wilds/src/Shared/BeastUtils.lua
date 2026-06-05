-- MythicWilds: BeastUtils
-- Shared utility functions for beast stat calculations, UUID generation, etc.

local GameData = require(script.Parent.GameData)
local BeastUtils = {}

-- Generate a unique ID for each beast instance
local function newId()
	return tostring(math.random(100000, 999999)) .. tostring(tick()):gsub("%.", "")
end

-- Build a fresh beast object with rolled bloodline and starting stats
function BeastUtils.CreateBeast(beastId, overrides)
	local template = GameData.Beasts[beastId]
	assert(template, "Unknown beast: " .. tostring(beastId))

	local bloodline = (overrides and overrides.bloodline) or GameData.RollBloodline((overrides and overrides.luckBonus) or 0)
	local bl = GameData.Bloodlines[bloodline]

	local beast = {
		uuid      = newId(),
		beastId   = beastId,
		bloodline = bloodline,
		level     = 1,
		xp        = 0,
		bond      = 0,
		nickname  = nil,
		locked    = false,
		favorite  = false,
		-- Effective stats (recalculated on level up / evolution)
		stats = BeastUtils.CalcStats(template.base, bloodline, 1),
		-- Current HP in battle (not persisted between battles)
		currentHP = nil,
	}
	beast.currentHP = beast.stats.hp

	if overrides then
		for k, v in pairs(overrides) do
			if k ~= "luckBonus" and k ~= "bloodline" then
				beast[k] = v
			end
		end
	end

	return beast
end

-- Scale base stats by bloodline multipliers and level
function BeastUtils.CalcStats(base, bloodlineId, level)
	local bl = GameData.Bloodlines[bloodlineId] or GameData.Bloodlines.Common
	local scale = 1 + (level - 1) * 0.08  -- 8% per level

	return {
		hp    = math.floor(base.hp   * bl.statMult * scale),
		atk   = math.floor(base.atk  * bl.atkMult  * scale),
		def   = math.floor(base.def  * bl.defMult  * scale),
		spd   = math.floor(base.spd  * bl.statMult * scale),
		mag   = math.floor(base.mag  * bl.statMult * scale),
		luck  = math.floor(base.luck * bl.statMult * scale),
	}
end

-- Refresh a beast's stats after level/evolution change
function BeastUtils.RefreshStats(beast)
	local template = GameData.Beasts[beast.beastId]
	beast.stats = BeastUtils.CalcStats(template.base, beast.bloodline, beast.level)
end

-- Add XP to beast; handles level-ups. Returns table of level-up events.
function BeastUtils.AddXP(beast, amount)
	local template = GameData.Beasts[beast.beastId]
	-- Ancient bloodline XP penalty
	if beast.bloodline == "Ancient" then amount = math.floor(amount * 0.7) end

	beast.xp = beast.xp + amount
	local leveled = {}
	local cap = 100  -- max level

	while beast.level < cap do
		local needed = GameData.BeastXPForLevel(beast.level + 1)
		if beast.xp >= needed then
			beast.xp = beast.xp - needed
			beast.level = beast.level + 1
			BeastUtils.RefreshStats(beast)
			table.insert(leveled, beast.level)
		else
			break
		end
	end

	return leveled
end

-- Add bond XP (from battles, training, petting)
function BeastUtils.AddBond(beast, amount)
	beast.bond = math.min(100, beast.bond + amount)
end

-- Check if a beast is ready to evolve
function BeastUtils.CanEvolve(beast, inventory)
	local template = GameData.Beasts[beast.beastId]
	if not template.evolvesInto then return false, "This beast has no further evolution." end
	if beast.level < template.evoLevel then
		return false, "Needs level " .. template.evoLevel .. " (currently " .. beast.level .. ")"
	end
	local req = template.evoReq
	if beast.bond < req.bond then
		return false, "Bond too low (" .. beast.bond .. "/" .. req.bond .. ")"
	end
	-- Check materials
	for matId, qty in pairs(req.mats) do
		if (inventory[matId] or 0) < qty then
			return false, "Missing " .. qty - (inventory[matId] or 0) .. "x " .. GameData.Materials[matId].label
		end
	end
	return true, nil
end

-- Perform evolution (mutates beast in-place; caller deducts costs)
function BeastUtils.Evolve(beast)
	local template = GameData.Beasts[beast.beastId]
	assert(template.evolvesInto, "Beast cannot evolve")
	beast.beastId = template.evolvesInto
	beast.xp = 0
	BeastUtils.RefreshStats(beast)
	beast.currentHP = beast.stats.hp
	return beast
end

-- Serialise beast for DataStore (strips non-serialisable values)
function BeastUtils.Serialise(beast)
	return {
		uuid=beast.uuid, beastId=beast.beastId, bloodline=beast.bloodline,
		level=beast.level, xp=beast.xp, bond=beast.bond,
		nickname=beast.nickname, locked=beast.locked, favorite=beast.favorite,
	}
end

-- Deserialise a beast from DataStore
function BeastUtils.Deserialise(data)
	local beast = BeastUtils.CreateBeast(data.beastId, { bloodline=data.bloodline })
	beast.uuid     = data.uuid
	beast.level    = data.level or 1
	beast.xp       = data.xp or 0
	beast.bond     = data.bond or 0
	beast.nickname = data.nickname
	beast.locked   = data.locked or false
	beast.favorite = data.favorite or false
	BeastUtils.RefreshStats(beast)
	beast.currentHP = beast.stats.hp
	return beast
end

return BeastUtils
