-- MythicWilds: QuestSystem
-- Tracks quest progress and distributes rewards.

local GameData = require(game.ReplicatedStorage.Shared.GameData)
local QuestSystem = {}

-- Event types that can advance quests
local HANDLERS = {}

-- ── OBJECTIVE CHECKERS ────────────────────────────────────────────────

-- Each handler receives (playerData, questId, objective, eventData)
-- and returns the new progress count (or nil to skip)

HANDLERS["Tame"] = function(playerData, obj, ev)
	if ev.type ~= "Tame" then return nil end
	if obj.beastId and ev.beastId ~= obj.beastId then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["Battle"] = function(playerData, obj, ev)
	if ev.type ~= "Battle" then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["Boss"] = function(playerData, obj, ev)
	if ev.type ~= "Boss" then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["UniqueBoss"] = function(playerData, obj, ev)
	if ev.type ~= "Boss" then return nil end
	-- Track unique bosses in stats
	local bosses = playerData.stats.bosses
	if not bosses[ev.bossId] then
		bosses[ev.bossId] = true
		local count = 0
		for _ in pairs(bosses) do count = count + 1 end
		return count
	end
	return ev.progress  -- no change
end

HANDLERS["Evolve"] = function(playerData, obj, ev)
	if ev.type ~= "Evolve" then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["Trade"] = function(playerData, obj, ev)
	if ev.type ~= "Trade" then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["Collect"] = function(playerData, obj, ev)
	if ev.type ~= "Collect" then return nil end
	if obj.item and ev.item ~= obj.item then return nil end
	return (playerData.inventory[obj.item] or 0)
end

HANDLERS["PlayerLevel"] = function(playerData, obj, ev)
	if ev.type ~= "LevelUp" then return nil end
	return playerData.level
end

HANDLERS["Bloodline"] = function(playerData, obj, ev)
	if ev.type ~= "Tame" then return nil end
	local bl = GameData.Bloodlines[ev.bloodline]
	if not bl then return nil end
	local tier = 1
	for i, name in ipairs(GameData.BloodlineOrder) do
		if name == ev.bloodline then tier = i; break end
	end
	if tier < (obj.minTier or 2) then return nil end
	return (ev.progress or 0) + 1
end

HANDLERS["OwnBloodline"] = function(playerData, obj, ev)
	if ev.type ~= "Tame" then return nil end
	if ev.bloodline ~= obj.bloodline then return nil end
	local count = 0
	for _, b in ipairs(playerData.beasts) do
		if b.bloodline == obj.bloodline then count = count + 1 end
	end
	return count
end

HANDLERS["TameAll"] = function(playerData, obj, ev)
	if ev.type ~= "Tame" then return nil end
	local realm = GameData.Realms[obj.realm]
	if not realm then return nil end
	local tamed = {}
	for _, b in ipairs(playerData.beasts) do tamed[b.beastId] = true end
	local have = 0
	for _, bId in ipairs(realm.beasts) do
		if tamed[bId] then have = have + 1 end
	end
	return have  -- target = #realm.beasts
end

-- ── PUBLIC API ────────────────────────────────────────────────────────

-- Fire a game event to advance relevant quests. Returns list of completed questIds.
function QuestSystem.FireEvent(playerData, eventData)
	local completed = {}
	local active = playerData.quests.active
	local i = 1
	while i <= #active do
		local questId  = active[i]
		local template = GameData.Quests[questId]
		if not template then
			table.remove(active, i)
		else
			local allDone = true
			for j, obj in ipairs(template.obj) do
				local handler = HANDLERS[obj.type]
				if handler then
					local newProg = handler(playerData, obj, eventData)
					if newProg ~= nil then
						-- Store progress on playerData
						playerData.quests.progress = playerData.quests.progress or {}
						playerData.quests.progress[questId] = playerData.quests.progress[questId] or {}
						playerData.quests.progress[questId][j] = newProg
					end
				end

				-- Check if this objective is met
				local prog = (playerData.quests.progress and playerData.quests.progress[questId] and
					playerData.quests.progress[questId][j]) or 0
				local target = obj.count or obj.level or 1
				if obj.type == "TameAll" then
					target = #(GameData.Realms[obj.realm] and GameData.Realms[obj.realm].beasts or {})
				end
				if prog < target then allDone = false end
			end

			if allDone then
				table.remove(active, i)
				table.insert(playerData.quests.completed, questId)
				table.insert(completed, questId)
				-- Grant rewards (caller applies to data)
			else
				i = i + 1
			end
		end
	end
	return completed
end

-- Apply quest rewards to playerData. Returns summary string.
function QuestSystem.GrantRewards(playerData, questId)
	local template = GameData.Quests[questId]
	if not template then return end
	local r = template.rewards
	playerData.coins = (playerData.coins or 0) + (r.coins or 0)
	playerData.xp    = (playerData.xp    or 0) + (r.xp    or 0)
	for itemId, qty in pairs(r.items or {}) do
		playerData.inventory[itemId] = (playerData.inventory[itemId] or 0) + qty
	end
	if r.title then
		playerData.titles.owned = playerData.titles.owned or {}
		table.insert(playerData.titles.owned, r.title)
	end
end

-- Assign a set of daily quests (reset every 24 h)
local DAILY_POOL = { "Tame3EmberDrakes","Defeat10Wild","Collect5Fire","BossSlayer","TradeOnce" }
function QuestSystem.AssignDaily(playerData)
	local active = playerData.quests.active
	for _, qId in ipairs(DAILY_POOL) do
		if not table.find(active, qId) and not table.find(playerData.quests.completed, qId) then
			table.insert(active, qId)
		end
	end
end

return QuestSystem
