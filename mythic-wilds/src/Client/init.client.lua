-- MythicWilds: Client Bootstrap
-- Receives server data, drives all client-side UI.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local GameData   = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"))
local UIManager  = require(script.Parent:WaitForChild("UIManager"))

local Events   = ReplicatedStorage:WaitForChild("Events",    15)
local Functions= ReplicatedStorage:WaitForChild("Functions", 15)

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer.PlayerGui

-- ── STATE ─────────────────────────────────────────────────────────────
local State = {
	data        = nil,   -- synced player data from server
	inBattle    = false,
	battleState = nil,
	nearbyNPCs  = {},    -- [npcId] = true (within proximity)
	currentRealm= "Sanctuary",
}

-- ── REMOTE HANDLES ────────────────────────────────────────────────────
local function getRE(name) return Events:WaitForChild(name, 10) end
local function getRF(name) return Functions:WaitForChild(name, 10) end

local RE_Init               = getRE("Init")
local RE_BattleUpdate       = getRE("BattleUpdate")
local RE_TameResult         = getRE("TameResult")
local RE_Evolve             = getRE("Evolve")
local RE_QuestUpdate        = getRE("QuestUpdate")
local RE_TradeProposal      = getRE("TradeProposal")
local RE_TradeResult        = getRE("TradeResult")
local RE_WildBeastSpawned   = getRE("WildBeastSpawned")
local RE_GlobalAnnouncement = getRE("GlobalAnnouncement")
local RE_DataUpdate         = getRE("DataUpdate")
local RE_StarterChosen      = getRE("StarterChosen")
local RE_DailyReward        = getRE("DailyReward")
local RE_BattleAction       = getRE("BattleAction")
local RE_AttemptTame        = getRE("AttemptTame")
local RE_EvolveRequest      = getRE("EvolveRequest")
local RE_TradeRequest       = getRE("TradeRequest")
local RE_TradeAccept        = getRE("TradeAccept")
local RE_TradeCancel        = getRE("TradeCancel")

-- ── INIT ──────────────────────────────────────────────────────────────
RE_Init.OnClientEvent:Connect(function(data)
	State.data = data
	UIManager.Init(State, playerGui, GameData)

	if not data.starterPicked then
		UIManager.ShowStarterSelect(function(beastId)
			RE_StarterChosen:FireServer(beastId)
		end)
	else
		UIManager.ShowHUD(data)
	end
end)

-- ── DATA SYNC ─────────────────────────────────────────────────────────
RE_DataUpdate.OnClientEvent:Connect(function(newData)
	State.data = newData
	UIManager.RefreshHUD(newData)
end)

-- ── DAILY REWARD ──────────────────────────────────────────────────────
RE_DailyReward.OnClientEvent:Connect(function(reward)
	UIManager.ShowDailyReward(reward)
end)

-- ── BATTLE ────────────────────────────────────────────────────────────
RE_BattleUpdate.OnClientEvent:Connect(function(result)
	if result.error then
		UIManager.ShowNotice(result.error, "red")
		return
	end

	if result.started then
		State.inBattle    = true
		State.battleState = result
		UIManager.ShowBattleScreen(result, function(action)
			RE_BattleAction:FireServer(action)
		end, function()  -- flee
			RE_BattleAction:FireServer("flee")
		end)
		return
	end

	if result.levelUp then
		UIManager.ShowLevelUp(result.levels, result.beastId)
		return
	end

	UIManager.UpdateBattleScreen(result)

	if result.outcome == "win" or result.outcome == "lose" or result.outcome == "flee" then
		State.inBattle = false
		task.delay(1.5, function()
			UIManager.CloseBattleScreen(result.outcome)
		end)
	end
end)

-- ── TAMING ────────────────────────────────────────────────────────────
RE_TameResult.OnClientEvent:Connect(function(result)
	if result.success then
		UIManager.ShowTameSuccess(result.beast, result.msg)
	else
		UIManager.ShowNotice(result.msg, "red")
	end
end)

-- ── EVOLUTION ─────────────────────────────────────────────────────────
RE_Evolve.OnClientEvent:Connect(function(result)
	if result.ok then
		UIManager.ShowEvolutionCutscene(result.beast, result.newId)
	else
		UIManager.ShowNotice(result.msg, "red")
	end
end)

-- ── QUEST ─────────────────────────────────────────────────────────────
RE_QuestUpdate.OnClientEvent:Connect(function(update)
	if update.completed then
		local q = GameData.Quests[update.completed]
		if q then
			UIManager.ShowQuestComplete(q, update.rewards)
		end
	end
end)

-- ── TRADE ─────────────────────────────────────────────────────────────
RE_TradeProposal.OnClientEvent:Connect(function(info)
	if info.incoming then
		UIManager.ShowTradeRequest(info, function(accepted, counterOffer)
			if accepted then
				RE_TradeAccept:FireServer(counterOffer)
			else
				RE_TradeCancel:FireServer()
			end
		end)
	elseif info.ack then
		UIManager.ShowNotice(info.ok and "Trade proposal sent!" or info.msg,
			info.ok and "green" or "red")
	end
end)

RE_TradeResult.OnClientEvent:Connect(function(result)
	UIManager.ShowNotice(result.msg, result.ok and "green" or "red")
	UIManager.CloseTradeUI()
end)

-- ── GLOBAL ANNOUNCEMENTS ──────────────────────────────────────────────
RE_GlobalAnnouncement.OnClientEvent:Connect(function(msg)
	UIManager.ShowGlobalAnnouncement(msg)
end)

-- ── WILD BEAST SPAWNED (minimap/nearby UI) ────────────────────────────
RE_WildBeastSpawned.OnClientEvent:Connect(function(npcId, beastId, bloodline, level, realmId)
	UIManager.OnWildBeastSpawned(npcId, beastId, bloodline, level, realmId)
end)

-- ── PROXIMITY BATTLE TRIGGER ──────────────────────────────────────────
-- Detect when player walks near a wild beast model and show "Battle" prompt
local function checkProximity()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local ws = game:GetService("Workspace")
	local realmsFolder = ws:FindFirstChild("Realms")
	if not realmsFolder then return end

	for _, realmF in ipairs(realmsFolder:GetChildren()) do
		for _, model in ipairs(realmF:GetChildren()) do
			if model:IsA("Model") and model.PrimaryPart then
				local dist = (root.Position - model.PrimaryPart.Position).Magnitude
				if dist < 15 then
					-- model.Name is the beastId; find the npcId via tag or name attribute
					local npcId = model:GetAttribute("NpcId")
					if npcId and not State.inBattle then
						UIManager.ShowProximityPrompt(npcId, model.Name, function()
							-- Player pressed interact → start battle
							RE_BattleAction:FireServer(nil, npcId, nil)
						end, function()
							-- Tame button
							UIManager.ShowCrystalSelect(State.data, function(crystalId)
								RE_AttemptTame:FireServer(npcId, crystalId)
							end)
						end)
						return
					end
				end
			end
		end
	end
	UIManager.HideProximityPrompt()
end

-- Poll proximity at 10 Hz
task.spawn(function()
	while true do
		task.wait(0.1)
		pcall(checkProximity)
	end
end)

print("[MythicWilds] Client ready!")
