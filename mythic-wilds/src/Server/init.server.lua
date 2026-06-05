-- MythicWilds: Server Bootstrap
-- Wires up all systems and remote events.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData       = require(game.ReplicatedStorage.Shared.GameData)
local BeastUtils     = require(game.ReplicatedStorage.Shared.BeastUtils)
local DataManager    = require(script.Parent.DataManager)
local BeastSystem    = require(script.Parent.BeastSystem)
local BattleSystem   = require(script.Parent.BattleSystem)
local TamingSystem   = require(script.Parent.TamingSystem)
local EvolutionSystem= require(script.Parent.EvolutionSystem)
local TradeSystem    = require(script.Parent.TradeSystem)
local QuestSystem    = require(script.Parent.QuestSystem)

-- ── REMOTE EVENTS / FUNCTIONS ─────────────────────────────────────────
local Events   = Instance.new("Folder"); Events.Name = "Events";    Events.Parent = ReplicatedStorage
local Functions= Instance.new("Folder"); Functions.Name="Functions"; Functions.Parent = ReplicatedStorage

local function makeRE(name)  local e=Instance.new("RemoteEvent");   e.Name=name; e.Parent=Events;    return e end
local function makeRF(name)  local e=Instance.new("RemoteFunction"); e.Name=name; e.Parent=Functions; return e end

-- Events (server→client broadcast or client→server fire)
local RE_Init              = makeRE("Init")
local RE_BattleUpdate      = makeRE("BattleUpdate")
local RE_TameResult        = makeRE("TameResult")
local RE_Evolve            = makeRE("Evolve")
local RE_QuestUpdate       = makeRE("QuestUpdate")
local RE_TradeProposal     = makeRE("TradeProposal")
local RE_TradeResult       = makeRE("TradeResult")
local RE_WildBeastSpawned  = makeRE("WildBeastSpawned")
local RE_GlobalAnnouncement= makeRE("GlobalAnnouncement")
local RE_DataUpdate        = makeRE("DataUpdate")
local RE_StarterChosen     = makeRE("StarterChosen")
local RE_DailyReward       = makeRE("DailyReward")

-- Functions (client requests data)
local RF_GetLeaderboard    = makeRF("GetLeaderboard")
local RF_GetBeastDetails   = makeRF("GetBeastDetails")

-- ── WORLD SETUP ───────────────────────────────────────────────────────
local function setupWorld()
	local ws = game.Workspace
	-- Create Realms folder with sub-folders per realm
	local realmsFolder = Instance.new("Folder")
	realmsFolder.Name  = "Realms"
	realmsFolder.Parent= ws

	for _, realmId in ipairs(GameData.RealmOrder) do
		local rf = Instance.new("Folder")
		rf.Name   = realmId
		rf.Parent = realmsFolder

		-- Baseplate per realm (colour-coded)
		local base = Instance.new("Part")
		base.Name     = "Ground"
		base.Anchored = true
		base.Size     = Vector3.new(250, 2, 250)
		local realm   = GameData.Realms[realmId]
		local idx     = table.find(GameData.RealmOrder, realmId) or 1
		base.Position = Vector3.new((idx - 1) * 270, -1, 0)
		base.BrickColor = BrickColor.new(
			realmId == "EmberForest"    and "Bright green"   or
			realmId == "FrostPeaks"     and "Baby blue"      or
			realmId == "ShadowMarsh"    and "Dark purple"    or
			realmId == "SunspireDesert" and "Bright yellow"  or
			realmId == "AbyssOcean"     and "Bright blue"    or
			"Dark indigo"
		)
		base.Parent = rf

		-- Scatter SpawnPads
		for j = 1, 8 do
			local pad = Instance.new("Part")
			pad.Name     = "SpawnPad"
			pad.Anchored = true
			pad.Size     = Vector3.new(4, 0.5, 4)
			pad.Transparency = 0.8
			pad.BrickColor   = BrickColor.new("Bright red")
			pad.Position     = base.Position + Vector3.new(
				math.random(-100, 100), 1, math.random(-100, 100)
			)
			pad.Parent = rf
		end

		-- Portal pad to enter realm
		local portal = Instance.new("Part")
		portal.Name     = "PortalPad_" .. realmId
		portal.Anchored = true
		portal.Size     = Vector3.new(8, 1, 8)
		portal.Position = Vector3.new((idx - 1) * 270 - 120, 1, 0)
		portal.BrickColor = BrickColor.new("Bright violet")
		portal.Material   = Enum.Material.Neon
		portal.Parent     = rf

		-- Realm sign billboard
		local bb = Instance.new("BillboardGui")
		bb.Adornee    = portal
		bb.Size       = UDim2.new(0, 200, 0, 60)
		bb.StudsOffset= Vector3.new(0, 4, 0)
		bb.AlwaysOnTop= true
		bb.Parent     = portal
		local lbl = Instance.new("TextLabel", bb)
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
		lbl.BackgroundTransparency = 0.5
		lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.Font       = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.Text       = realm.label .. "\n[Req. Lv " .. realm.reqLevel .. "]"
	end

	-- Sanctuary hub in centre
	local sanctFolder = Instance.new("Folder"); sanctFolder.Name="Sanctuary"; sanctFolder.Parent=ws
	local hub = Instance.new("Part")
	hub.Name = "HubGround"; hub.Anchored=true
	hub.Size = Vector3.new(200,2,200)
	hub.Position = Vector3.new(-200,-1,0)
	hub.BrickColor = BrickColor.new("Sand green")
	hub.Parent = sanctFolder
end

-- ── PLAYER JOIN ───────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	local data = DataManager.Load(player)

	-- Daily reward
	if not data.dailyClaimed then
		local streak = data.loginStreak
		local bonus  = math.min(streak * 50, 500)
		data.coins   = (data.coins or 0) + 100 + bonus
		data.dailyClaimed = true
		task.delay(2, function()
			if player.Parent then
				RE_DailyReward:FireClient(player, { coins=100+bonus, streak=streak })
			end
		end)
	end

	-- Sync data to client
	task.delay(1, function()
		if player.Parent then
			RE_Init:FireClient(player, data)
			if not data.starterPicked then
				-- Starter selection prompt handled by client
			end
		end
	end)

	-- Quest daily refresh
	QuestSystem.AssignDaily(data)
end)

Players.PlayerRemoving:Connect(function(player)
	DataManager.Save(player)
end)

-- ── STARTER SELECTION ─────────────────────────────────────────────────
RE_StarterChosen.OnServerEvent:Connect(function(player, beastId)
	local data = DataManager.Get(player)
	if not data or data.starterPicked then return end
	if not table.find(GameData.Starters, beastId) then return end

	data.starterPicked = true
	local beast = BeastUtils.CreateBeast(beastId, { level=1 })
	table.insert(data.beasts, BeastUtils.Serialise(beast))
	data.party = { beast.uuid }

	RE_DataUpdate:FireClient(player, data)
end)

-- ── BATTLE ────────────────────────────────────────────────────────────
local RE_BattleAction = makeRE("BattleAction")
RE_BattleAction.OnServerEvent:Connect(function(player, action, npcId, bossId)
	local data     = DataManager.Get(player)
	if not data then return end

	-- Find active beast
	local function getActiveBeast()
		local uuid = data.party[1]
		if not uuid then return nil end
		for _, b in ipairs(data.beasts) do
			if b.uuid == uuid then return BeastUtils.Deserialise(b) end
		end
		return nil
	end

	local battle = BattleSystem.GetBattle(player)

	-- Start a new battle if needed
	if not battle then
		local myBeast = getActiveBeast()
		if not myBeast then
			RE_BattleUpdate:FireClient(player, { error="No active beast in party." })
			return
		end

		if npcId then
			local wild = BeastSystem.GetWild(npcId)
			if not wild then
				RE_BattleUpdate:FireClient(player, { error="Beast not found." })
				return
			end
			if wild.inBattle then
				RE_BattleUpdate:FireClient(player, { error="That beast is already in battle." })
				return
			end
			wild.inBattle = true
			local state, err = BattleSystem.StartWild(player, myBeast, wild)
			if not state then
				RE_BattleUpdate:FireClient(player, { error=err })
				return
			end
			RE_BattleUpdate:FireClient(player, {
				started   = true,
				type      = "wild",
				npcId     = npcId,
				enemy     = { id=wild.beastId, bloodline=wild.bloodline, level=wild.level,
				              hp=state.enemy.currentHP, maxHP=state.enemy.maxHP },
				player    = { id=myBeast.beastId, level=myBeast.level,
				              hp=state.player.currentHP, maxHP=state.player.maxHP },
			})
			return
		end

		if bossId then
			if not GameData.Bosses[bossId] then return end
			local state, err = BattleSystem.StartBoss(player, myBeast, bossId)
			if not state then
				RE_BattleUpdate:FireClient(player, { error=err })
				return
			end
			RE_BattleUpdate:FireClient(player, {
				started  = true,
				type     = "boss",
				bossId   = bossId,
				enemy    = { id=bossId, hp=state.enemy.currentHP, maxHP=state.enemy.maxHP },
				player   = { id=myBeast.beastId, level=myBeast.level,
				             hp=state.player.currentHP, maxHP=state.player.maxHP },
			})
			return
		end
		return
	end

	-- Continue existing battle
	local result, err = BattleSystem.DoAction(player, action or "basic")
	if not result then
		RE_BattleUpdate:FireClient(player, { error=err })
		return
	end

	RE_BattleUpdate:FireClient(player, result)

	if result.outcome == "win" then
		-- XP + coins
		local xp    = result.xpGain   or 0
		local coins = result.coinGain  or 0
		data.coins  = (data.coins or 0) + coins

		-- Apply XP to active beast
		for _, b in ipairs(data.beasts) do
			if b.uuid == data.party[1] then
				local bObj = BeastUtils.Deserialise(b)
				local leveled = BeastUtils.AddXP(bObj, xp)
				BeastUtils.AddBond(bObj, 5)
				local saved = BeastUtils.Serialise(bObj)
				for k,v in pairs(saved) do b[k]=v end

				if #leveled > 0 then
					RE_BattleUpdate:FireClient(player, { levelUp=true, levels=leveled, beastId=bObj.beastId })
				end
				break
			end
		end

		-- Stats tracking
		data.stats.wins = (data.stats.wins or 0) + 1

		-- Mark wild beast as defeated
		local activeBattle = BattleSystem.GetBattle(player)
		if activeBattle and activeBattle.enemy.isWild and activeBattle.enemy.npcId then
			BeastSystem.RemoveWild(activeBattle.enemy.npcId)
		end
		if activeBattle and activeBattle.enemy.isBoss then
			data.stats.bosses[activeBattle.enemy.bossId] = (data.stats.bosses[activeBattle.enemy.bossId] or 0) + 1
		end

		-- Quest events
		local ev = { type="Battle" }
		local completed = QuestSystem.FireEvent(data, ev)
		for _, qId in ipairs(completed) do
			QuestSystem.GrantRewards(data, qId)
			RE_QuestUpdate:FireClient(player, { completed=qId, rewards=GameData.Quests[qId].rewards })
		end

		BattleSystem.EndBattle(player)
		RE_DataUpdate:FireClient(player, data)

	elseif result.outcome == "lose" or result.outcome == "flee" then
		BattleSystem.EndBattle(player)
		RE_DataUpdate:FireClient(player, data)
	end
end)

-- ── TAMING ────────────────────────────────────────────────────────────
local RE_AttemptTame = makeRE("AttemptTame")
RE_AttemptTame.OnServerEvent:Connect(function(player, npcId, crystalId)
	local data = DataManager.Get(player)
	if not data then return end

	local wild = BeastSystem.GetWild(npcId)
	if not wild then
		RE_TameResult:FireClient(player, { success=false, msg="Beast not found." })
		return
	end

	-- Must have crystal
	if (data.inventory[crystalId] or 0) < 1 then
		RE_TameResult:FireClient(player, { success=false, msg="You don't have that crystal." })
		return
	end

	-- Check capacity (default 30, +50 with gamepass)
	local cap = 30
	if #data.beasts >= cap then
		RE_TameResult:FireClient(player, { success=false, msg="Beast storage full! Buy extra storage." })
		return
	end

	-- Get luck from active beast
	local luck = 0
	for _, b in ipairs(data.beasts) do
		if b.uuid == data.party[1] then
			luck = BeastUtils.Deserialise(b).stats.luck
			break
		end
	end

	local ok, beast, msg = TamingSystem.Attempt(wild, crystalId, luck)

	-- Consume crystal regardless
	data.inventory[crystalId] = data.inventory[crystalId] - 1

	if ok and beast then
		BeastSystem.RemoveWild(npcId)
		local saved = BeastUtils.Serialise(beast)
		table.insert(data.beasts, saved)
		if #data.party == 0 then data.party = { beast.uuid } end

		data.stats.tamed = (data.stats.tamed or 0) + 1

		-- Bloodline tracking
		if beast.bloodline ~= "Common" then
			data.stats.bloodlines[beast.bloodline] = (data.stats.bloodlines[beast.bloodline] or 0) + 1
		end

		-- Global shout for rare bloodlines
		local bl = GameData.Bloodlines[beast.bloodline]
		if bl and bl.tradeValue >= 50 then
			RE_GlobalAnnouncement:FireAllClients(
				"⚡ " .. player.Name .. " tamed a [" .. beast.bloodline .. "] " ..
				GameData.Beasts[beast.beastId].label .. "!"
			)
		end

		-- Quest events
		local evTame = { type="Tame", beastId=beast.beastId, bloodline=beast.bloodline }
		local completed = QuestSystem.FireEvent(data, evTame)
		for _, qId in ipairs(completed) do
			QuestSystem.GrantRewards(data, qId)
			RE_QuestUpdate:FireClient(player, { completed=qId, rewards=GameData.Quests[qId].rewards })
		end

		RE_TameResult:FireClient(player, { success=true, msg=msg, beast=saved })
		RE_DataUpdate:FireClient(player, data)
	else
		RE_TameResult:FireClient(player, { success=false, msg=msg })
		RE_DataUpdate:FireClient(player, data)  -- crystal consumed
	end
end)

-- ── EVOLUTION ─────────────────────────────────────────────────────────
local RE_EvolveRequest = makeRE("EvolveRequest")
RE_EvolveRequest.OnServerEvent:Connect(function(player, beastUUID)
	local data = DataManager.Get(player)
	if not data then return end

	local bIdx, bSave
	for i, b in ipairs(data.beasts) do
		if b.uuid == beastUUID then bIdx=i; bSave=b; break end
	end
	if not bSave then RE_Evolve:FireClient(player,{ok=false,msg="Beast not found."}); return end

	local beast = BeastUtils.Deserialise(bSave)
	local ok, err = EvolutionSystem.Check(beast, data.inventory, data.coins)
	if not ok then RE_Evolve:FireClient(player,{ok=false,msg=err}); return end

	EvolutionSystem.Evolve(beast, data)
	local newSave = BeastUtils.Serialise(beast)
	for k,v in pairs(newSave) do bSave[k]=v end

	-- Quest event
	local completed = QuestSystem.FireEvent(data, { type="Evolve" })
	for _, qId in ipairs(completed) do
		QuestSystem.GrantRewards(data, qId)
		RE_QuestUpdate:FireClient(player, { completed=qId, rewards=GameData.Quests[qId].rewards })
	end

	RE_Evolve:FireClient(player, { ok=true, beast=newSave, newId=beast.beastId })
	RE_DataUpdate:FireClient(player, data)

	RE_GlobalAnnouncement:FireAllClients(
		"★ " .. player.Name .. "'s " .. (GameData.Beasts[newSave.beastId] and GameData.Beasts[newSave.beastId].label or newSave.beastId) ..
		" evolved into " .. (GameData.Beasts[beast.beastId] and GameData.Beasts[beast.beastId].label or beast.beastId) .. "!"
	)
end)

-- ── TRADE ─────────────────────────────────────────────────────────────
local RE_TradeRequest = makeRE("TradeRequest")
local RE_TradeAccept  = makeRE("TradeAccept")
local RE_TradeCancel  = makeRE("TradeCancel")

RE_TradeRequest.OnServerEvent:Connect(function(player, targetName, offer)
	local data = DataManager.Get(player)
	if not data then return end
	local ok, msg = TradeSystem.Propose(player, targetName, offer, data)
	RE_TradeProposal:FireClient(player, { ack=true, ok=ok, msg=msg })
	if ok then
		local target = game.Players:FindFirstChild(targetName)
		if target then
			RE_TradeProposal:FireClient(target, {
				incoming   = true,
				from       = player.Name,
				offer      = offer,
			})
		end
	end
end)

RE_TradeAccept.OnServerEvent:Connect(function(player, counterOffer)
	local data = DataManager.Get(player)
	if not data then return end

	local proposal = TradeSystem.GetIncoming(player)
	if not proposal then
		RE_TradeResult:FireClient(player, { ok=false, msg="No pending trade." })
		return
	end

	local initiator = game.Players:GetPlayerByUserId(proposal.initiatorId)
	if not initiator then
		RE_TradeResult:FireClient(player, { ok=false, msg="Initiator disconnected." })
		return
	end

	local initiatorData = DataManager.Get(initiator)
	local ok, msg = TradeSystem.Accept(player, counterOffer, data, initiatorData)
	RE_TradeResult:FireClient(player,     { ok=ok, msg=msg })
	RE_TradeResult:FireClient(initiator,  { ok=ok, msg=ok and "Trade completed!" or msg })

	if ok then
		-- Quest
		for _, p in ipairs({ player, initiator }) do
			local pd = DataManager.Get(p)
			local completed = QuestSystem.FireEvent(pd, { type="Trade" })
			for _, qId in ipairs(completed) do
				QuestSystem.GrantRewards(pd, qId)
				RE_QuestUpdate:FireClient(p, { completed=qId, rewards=GameData.Quests[qId].rewards })
			end
			RE_DataUpdate:FireClient(p, pd)
		end
	end
end)

RE_TradeCancel.OnServerEvent:Connect(function(player)
	TradeSystem.Cancel(player)
end)

-- ── LEADERBOARD ───────────────────────────────────────────────────────
RF_GetLeaderboard.OnServerInvoke = function(player)
	local board = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local d = DataManager.Get(p)
		if d then
			table.insert(board, {
				name  = p.Name,
				level = d.level,
				tamed = d.stats.tamed or 0,
				wins  = d.stats.wins  or 0,
				title = d.titles.active,
			})
		end
	end
	table.sort(board, function(a,b) return a.level > b.level end)
	return board
end

-- ── START WORLD ───────────────────────────────────────────────────────
setupWorld()
BeastSystem.StartPopulation()

print("[MythicWilds] Server ready!")
