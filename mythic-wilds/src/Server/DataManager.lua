-- MythicWilds: DataManager
-- Handles all DataStore read/write for player progress.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local GameData = require(game.ReplicatedStorage.Shared.GameData)

local DataManager = {}
local STORE_KEY = "MythicWilds_v1"
local store = DataStoreService:GetDataStore(STORE_KEY)

local cache = {}   -- [userId] = data

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = (type(v) == "table") and deepCopy(v) or v
	end
	return copy
end

function DataManager.Load(player)
	local key = "player_" .. player.UserId
	local ok, data = pcall(function()
		return store:GetAsync(key)
	end)

	if not ok or not data then
		data = deepCopy(GameData.DefaultData)
		data.lastLogin = os.time()
		data.joinDate  = os.time()
	else
		-- Patch in any missing default keys (for older save files)
		for k, v in pairs(GameData.DefaultData) do
			if data[k] == nil then
				data[k] = (type(v) == "table") and deepCopy(v) or v
			end
		end

		-- Daily login streak
		local now = os.time()
		local daysSince = math.floor((now - (data.lastLogin or 0)) / 86400)
		if daysSince >= 1 then
			data.dailyClaimed = false
			data.loginStreak  = (daysSince == 1) and (data.loginStreak + 1) or 1
		end
		data.lastLogin = now
	end

	cache[player.UserId] = data
	return data
end

function DataManager.Save(player)
	local data = cache[player.UserId]
	if not data then return end
	local key = "player_" .. player.UserId
	local ok, err = pcall(function()
		store:SetAsync(key, data)
	end)
	if not ok then
		warn("[DataManager] Save failed for", player.Name, ":", err)
	end
end

function DataManager.Get(player)
	return cache[player.UserId]
end

function DataManager.Set(player, path, value)
	local data = cache[player.UserId]
	if not data then return end
	-- path is a dot-separated key e.g. "coins" or "stats.tamed"
	local parts = path:split(".")
	local tbl = data
	for i = 1, #parts - 1 do
		tbl = tbl[parts[i]]
		if not tbl then return end
	end
	tbl[parts[#parts]] = value
end

-- Periodic auto-save every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			DataManager.Save(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DataManager.Save(player)
	cache[player.UserId] = nil
end)

return DataManager
