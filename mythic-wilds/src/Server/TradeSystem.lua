-- MythicWilds: TradeSystem
-- Peer-to-peer trade request / confirm / cancel flow.

local Players = game:GetService("Players")
local GameData = require(game.ReplicatedStorage.Shared.GameData)

local TradeSystem = {}

-- Pending trade proposals: [initiatorId] = { target, offer{beastUUID, mats, coins}, timer }
local pending = {}
-- Active trades in confirmation window: [userId] = tradeSession
local active  = {}

local CONFIRM_TIMEOUT = 30  -- seconds to accept
local TRADE_TIMEOUT   = 60  -- seconds for both parties to confirm

-- Utility: find a beast in player data by UUID
local function findBeast(playerData, uuid)
	for i, b in ipairs(playerData.beasts) do
		if b.uuid == uuid then return i, b end
	end
	return nil, nil
end

local function validateOffer(offer, playerData)
	if not offer then return false, "No offer." end
	if (offer.coins or 0) > (playerData.coins or 0) then
		return false, "Not enough coins."
	end
	if offer.beastUUID then
		local i, b = findBeast(playerData, offer.beastUUID)
		if not i then return false, "Beast not found in your collection." end
		if b.locked  then return false, "Beast is locked." end
	end
	for matId, qty in pairs(offer.mats or {}) do
		if (playerData.inventory[matId] or 0) < qty then
			return false, "Not enough " .. matId .. "."
		end
	end
	return true, nil
end

-- ── PUBLIC API ────────────────────────────────────────────────────────

-- Initiate a trade request to another player
-- offer: { beastUUID?, mats={}, coins=0 }
function TradeSystem.Propose(initiator, targetName, offer, initiatorData)
	if pending[initiator.UserId] then
		return false, "You already have a pending trade proposal."
	end
	local target = Players:FindFirstChild(targetName)
	if not target then return false, "Player not found." end
	if target == initiator then return false, "Cannot trade with yourself." end

	local ok, err = validateOffer(offer, initiatorData)
	if not ok then return false, err end

	pending[initiator.UserId] = {
		initiatorId = initiator.UserId,
		targetId    = target.UserId,
		offer       = offer,
		expires     = os.time() + CONFIRM_TIMEOUT,
	}

	-- Auto-cancel after timeout
	task.delay(CONFIRM_TIMEOUT, function()
		if pending[initiator.UserId] then
			pending[initiator.UserId] = nil
		end
	end)

	return true, "Trade proposal sent to " .. targetName .. "."
end

-- Target accepts; provide their counter-offer
function TradeSystem.Accept(target, counterOffer, targetData, initiatorData)
	-- Find proposal for this target
	local proposal
	for _, p in pairs(pending) do
		if p.targetId == target.UserId and p.expires > os.time() then
			proposal = p
			break
		end
	end
	if not proposal then return false, "No pending trade request for you." end

	local ok, err = validateOffer(counterOffer, targetData)
	if not ok then return false, err end

	-- Execute the trade
	local initiator = Players:GetPlayerByUserId(proposal.initiatorId)
	if not initiator then
		pending[proposal.initiatorId] = nil
		return false, "Initiator disconnected."
	end

	-- Swap beasts
	local function transferBeast(fromData, toData, uuid)
		if not uuid then return end
		local i, beast = findBeast(fromData, uuid)
		if i then
			table.remove(fromData.beasts, i)
			table.insert(toData.beasts, beast)
		end
	end

	-- Initiator → Target
	transferBeast(initiatorData, targetData, proposal.offer.beastUUID)
	targetData.coins  = (targetData.coins  or 0) + (proposal.offer.coins or 0)
	initiatorData.coins = (initiatorData.coins or 0) - (proposal.offer.coins or 0)
	for matId, qty in pairs(proposal.offer.mats or {}) do
		targetData.inventory[matId]    = (targetData.inventory[matId]    or 0) + qty
		initiatorData.inventory[matId] = (initiatorData.inventory[matId] or 0) - qty
	end

	-- Target → Initiator
	transferBeast(targetData, initiatorData, counterOffer.beastUUID)
	initiatorData.coins = (initiatorData.coins or 0) + (counterOffer.coins or 0)
	targetData.coins    = (targetData.coins    or 0) - (counterOffer.coins or 0)
	for matId, qty in pairs(counterOffer.mats or {}) do
		initiatorData.inventory[matId] = (initiatorData.inventory[matId] or 0) + qty
		targetData.inventory[matId]    = (targetData.inventory[matId]    or 0) - qty
	end

	-- Update trade stats
	initiatorData.stats.trades = (initiatorData.stats.trades or 0) + 1
	targetData.stats.trades    = (targetData.stats.trades    or 0) + 1

	pending[proposal.initiatorId] = nil
	return true, "Trade completed successfully!"
end

-- Either party cancels
function TradeSystem.Cancel(player)
	-- Cancel as initiator
	if pending[player.UserId] then
		pending[player.UserId] = nil
		return true, "Trade proposal cancelled."
	end
	-- Cancel as target
	for key, p in pairs(pending) do
		if p.targetId == player.UserId then
			pending[key] = nil
			return true, "Trade declined."
		end
	end
	return false, "No pending trade to cancel."
end

-- Get pending proposal aimed at a player (for UI prompt)
function TradeSystem.GetIncoming(player)
	for _, p in pairs(pending) do
		if p.targetId == player.UserId and p.expires > os.time() then
			return p
		end
	end
	return nil
end

return TradeSystem
