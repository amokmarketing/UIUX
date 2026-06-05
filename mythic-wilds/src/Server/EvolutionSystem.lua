-- MythicWilds: EvolutionSystem
-- Validates and performs beast evolution.

local GameData   = require(game.ReplicatedStorage.Shared.GameData)
local BeastUtils = require(game.ReplicatedStorage.Shared.BeastUtils)

local EvolutionSystem = {}

-- Returns ok(bool), reason(string), costTable
function EvolutionSystem.Check(beast, inventory, coins)
	local template = GameData.Beasts[beast.beastId]
	if not template then return false, "Invalid beast." end
	if not template.evolvesInto then return false, "This beast cannot evolve further." end

	local req = template.evoReq
	if not req then return false, "No evolution requirements defined." end

	if beast.level < template.evoLevel then
		return false, "Requires level " .. template.evoLevel .. " (you have " .. beast.level .. ")."
	end

	if beast.bond < req.bond then
		return false, "Bond too low: need " .. req.bond .. ", have " .. beast.bond .. "."
	end

	if coins < req.coins then
		return false, "Not enough coins: need " .. req.coins .. ", have " .. coins .. "."
	end

	for matId, qty in pairs(req.mats) do
		local have = inventory[matId] or 0
		if have < qty then
			local matLabel = (GameData.Materials[matId] and GameData.Materials[matId].label) or matId
			return false, "Missing material: " .. matLabel .. " (" .. have .. "/" .. qty .. ")."
		end
	end

	return true, nil, req
end

-- Performs evolution; mutates beast, deducts costs.
-- Returns evolvedBeast, newId, costs deducted
function EvolutionSystem.Evolve(beast, playerData)
	local template = GameData.Beasts[beast.beastId]
	local req = template.evoReq

	-- Deduct coin
	playerData.coins = playerData.coins - req.coins

	-- Deduct materials
	for matId, qty in pairs(req.mats) do
		playerData.inventory[matId] = (playerData.inventory[matId] or 0) - qty
	end

	-- Evolve the beast
	local oldId = beast.beastId
	BeastUtils.Evolve(beast)

	-- Track stats
	playerData.stats.evolutions = (playerData.stats.evolutions or 0) + 1

	return beast, oldId
end

return EvolutionSystem
