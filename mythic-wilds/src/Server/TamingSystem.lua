-- MythicWilds: TamingSystem
-- Handles taming a weakened wild beast using a crystal.

local GameData   = require(game.ReplicatedStorage.Shared.GameData)
local BeastUtils = require(game.ReplicatedStorage.Shared.BeastUtils)

local TamingSystem = {}

-- Rarity capture difficulty modifier
local RARITY_MOD = {
	Common    = 1.00,
	Uncommon  = 0.80,
	Rare      = 0.60,
	Epic      = 0.40,
	Legendary = 0.25,
	Mythic    = 0.12,
	Secret    = 0.05,
}

-- Bloodline difficulty modifier
local BLOOD_MOD = {
	Common    = 1.00,
	Royal     = 0.85,
	Ancient   = 0.80,
	Cursed    = 0.75,
	Celestial = 0.65,
	Primal    = 0.70,
	Void      = 0.50,
	Secret    = 0.25,
}

-- Attempt to tame a wild beast
-- wildEntry: from BeastSystem.GetWild()
-- crystalId: string key from GameData.Crystals
-- playerLuck: player's active beast luck stat (or 0)
-- Returns: success(bool), newBeast(table or nil), message(string)
function TamingSystem.Attempt(wildEntry, crystalId, playerLuck)
	local crystal = GameData.Crystals[crystalId]
	if not crystal then return false, nil, "Unknown crystal." end

	local template = GameData.Beasts[wildEntry.beastId]
	local maxHP = BeastUtils.CalcStats(template.base, wildEntry.bloodline, wildEntry.level).hp

	-- Health factor: lower HP = easier to catch (0.3 at 0 HP, 1.0 at full)
	local hpFactor = 0.3 + 0.7 * (wildEntry.currentHP / maxHP)

	local rarityMod = RARITY_MOD[template.rarity] or 0.5
	local bloodMod  = BLOOD_MOD[wildEntry.bloodline] or 1.0

	-- Luck bonus from player: each 10 luck = +2% catch rate, capped at +20%
	local luckBonus = math.min(0.20, (playerLuck or 0) / 10 * 0.02)

	local chance = crystal.baseRate
		* rarityMod
		* bloodMod
		/ hpFactor
		+ crystal.rarityBonus
		+ crystal.bloodBonus * (1 - bloodMod)
		+ luckBonus

	chance = math.max(0.01, math.min(0.99, chance))

	if math.random() > chance then
		return false, nil, "The beast broke free! (chance was " .. math.floor(chance * 100) .. "%)"
	end

	-- Bloodline upgrade chance (BloodlineCrystal only)
	local finalBloodline = wildEntry.bloodline
	if crystal.bloodUpgrade > 0 and math.random() < crystal.bloodUpgrade then
		-- Upgrade by one tier
		local order = GameData.BloodlineOrder
		for i, name in ipairs(order) do
			if name == finalBloodline and order[i + 1] then
				finalBloodline = order[i + 1]
				break
			end
		end
	end

	local beast = BeastUtils.CreateBeast(wildEntry.beastId, {
		bloodline = finalBloodline,
		level     = wildEntry.level,
	})

	local upgraded = (finalBloodline ~= wildEntry.bloodline)
	local msg = "Tamed " .. template.label ..
		(upgraded and " (Bloodline upgraded to " .. finalBloodline .. "!)" or
		 " [" .. finalBloodline .. "]")
	return true, beast, msg
end

return TamingSystem
