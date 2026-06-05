-- MythicWilds: BattleSystem
-- Turn-based battle engine: player party vs. wild beast or boss.

local GameData  = require(game.ReplicatedStorage.Shared.GameData)
local BeastUtils = require(game.ReplicatedStorage.Shared.BeastUtils)

local BattleSystem = {}

-- Active battles: [player.UserId] = battleState
local battles = {}

-- ──────────────────────────────────────────────────────────────────────
-- HELPERS
-- ──────────────────────────────────────────────────────────────────────

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

-- Roll damage for an ability
-- basePower: raw multiplier on ATK (1.0 = normal, 2.0 = heavy, 3.5 = ultimate)
local function rollDamage(attackerStats, defenderStats, attackerElem, defenderElem, basePower, isMagic)
	local stat   = isMagic and attackerStats.mag or attackerStats.atk
	local resist = isMagic and defenderStats.mag  or defenderStats.def
	local elemMult = GameData.ElementMultiplier(attackerElem, defenderElem)
	local variance = 0.9 + math.random() * 0.2  -- ±10%
	local dmg = math.floor(stat * basePower * elemMult * variance - resist * 0.5)
	return math.max(1, dmg), elemMult
end

-- Ability catalogue: {power, isMagic, cooldown (turns)}
local ABILITY_DEFS = {
	-- Basic  (no cooldown)
	basic   = { power=1.0,  magic=false, cd=0 },
	-- Special (1 turn cd)
	special = { power=2.2,  magic=true,  cd=2 },
	-- Ultimate (3 turn cd)
	ult     = { power=4.0,  magic=true,  cd=4 },
}

local function getCooldowns(battleState, owner)
	battleState.cooldowns = battleState.cooldowns or {}
	battleState.cooldowns[owner] = battleState.cooldowns[owner] or { special=0, ult=0 }
	return battleState.cooldowns[owner]
end

local function tickCooldowns(battleState, owner)
	local cd = getCooldowns(battleState, owner)
	cd.special = math.max(0, (cd.special or 0) - 1)
	cd.ult     = math.max(0, (cd.ult     or 0) - 1)
end

-- ──────────────────────────────────────────────────────────────────────
-- BATTLE STATE CONSTRUCTION
-- ──────────────────────────────────────────────────────────────────────

-- combatant: {beastId, bloodline, level, stats, currentHP, element, abilities}
local function makeCombatant(beastObj)
	local template = GameData.Beasts[beastObj.beastId]
	return {
		beastId   = beastObj.beastId,
		label     = template.label,
		bloodline = beastObj.bloodline,
		level     = beastObj.level,
		element   = template.element,
		abilities = template.abilities,
		stats     = BeastUtils.CalcStats(template.base, beastObj.bloodline, beastObj.level),
		currentHP = beastObj.currentHP or BeastUtils.CalcStats(template.base, beastObj.bloodline, beastObj.level).hp,
		maxHP     = BeastUtils.CalcStats(template.base, beastObj.bloodline, beastObj.level).hp,
		beastRef  = beastObj,  -- pointer back to the actual beast object
	}
end

local function makeWildCombatant(wildEntry)
	local template = GameData.Beasts[wildEntry.beastId]
	local stats = BeastUtils.CalcStats(template.base, wildEntry.bloodline, wildEntry.level)
	return {
		beastId   = wildEntry.beastId,
		label     = template.label,
		bloodline = wildEntry.bloodline,
		level     = wildEntry.level,
		element   = template.element,
		abilities = template.abilities,
		stats     = stats,
		currentHP = wildEntry.currentHP or stats.hp,
		maxHP     = stats.hp,
		isWild    = true,
		npcId     = wildEntry.npcId,
	}
end

local function makeBossCombatant(bossId)
	local boss = GameData.Bosses[bossId]
	return {
		beastId   = bossId,
		label     = boss.label,
		bloodline = "Common",
		level     = 1,
		element   = boss.element,
		abilities = { basic=boss.abilities[1], special=boss.abilities[2], ult=boss.abilities[3] },
		stats     = { hp=boss.hp, atk=boss.atk, def=boss.def, spd=20, mag=boss.atk, luck=5 },
		currentHP = boss.hp,
		maxHP     = boss.hp,
		isBoss    = true,
		bossId    = bossId,
	}
end

-- ──────────────────────────────────────────────────────────────────────
-- PUBLIC API
-- ──────────────────────────────────────────────────────────────────────

-- Start a battle vs a wild beast
function BattleSystem.StartWild(player, playerBeast, wildEntry)
	if battles[player.UserId] then return nil, "Already in battle" end
	local state = {
		type       = "wild",
		player     = makeCombatant(playerBeast),
		enemy      = makeWildCombatant(wildEntry),
		turn       = 1,
		log        = {},
		over       = false,
		result     = nil,  -- "win" | "lose" | "flee"
	}
	battles[player.UserId] = state
	return state
end

-- Start a boss fight (multiplayer safe: each player gets own state tracking same boss HP pool)
function BattleSystem.StartBoss(player, playerBeast, bossId)
	if battles[player.UserId] then return nil, "Already in battle" end
	local state = {
		type   = "boss",
		player = makeCombatant(playerBeast),
		enemy  = makeBossCombatant(bossId),
		turn   = 1,
		log    = {},
		over   = false,
		result = nil,
	}
	battles[player.UserId] = state
	return state
end

-- Get active battle for player
function BattleSystem.GetBattle(player)
	return battles[player.UserId]
end

-- Execute a player action: "basic" | "special" | "ult" | "flee"
-- Returns result table consumed by server handler / broadcast to client
function BattleSystem.DoAction(player, action)
	local state = battles[player.UserId]
	if not state or state.over then return nil, "No active battle" end

	local pCombatant = state.player
	local eCombatant = state.enemy
	local cd = getCooldowns(state, "player")
	local log = {}

	-- ── FLEE ──────────────────────────────────────────────────────────
	if action == "flee" then
		-- 50% base flee chance
		if math.random() < 0.5 then
			state.over   = true
			state.result = "flee"
			return { outcome="flee", log={"You fled from battle!"} }
		else
			table.insert(log, "You failed to flee!")
			-- Enemy still attacks
			local eDmg = rollDamage(eCombatant.stats, pCombatant.stats, eCombatant.element, pCombatant.element, 1.0, false)
			pCombatant.currentHP = math.max(0, pCombatant.currentHP - eDmg)
			table.insert(log, eCombatant.label .. " hit for " .. eDmg .. " dmg!")
			if pCombatant.currentHP <= 0 then
				state.over   = true
				state.result = "lose"
				table.insert(log, "Your beast fainted!")
			end
			return { outcome="continue", log=log, playerHP=pCombatant.currentHP, enemyHP=eCombatant.currentHP }
		end
	end

	-- ── VALIDATE COOLDOWNS ────────────────────────────────────────────
	if action == "special" and cd.special > 0 then
		return nil, "Special ability on cooldown (" .. cd.special .. " turns)"
	end
	if action == "ult" and cd.ult > 0 then
		return nil, "Ultimate ability on cooldown (" .. cd.ult .. " turns)"
	end

	-- ── PLAYER ATTACKS ────────────────────────────────────────────────
	local abilDef  = ABILITY_DEFS[action] or ABILITY_DEFS.basic
	local abilName = pCombatant.abilities[action] or "Attack"
	local pDmg, pMult = rollDamage(
		pCombatant.stats, eCombatant.stats,
		pCombatant.element, eCombatant.element,
		abilDef.power, abilDef.magic
	)
	eCombatant.currentHP = math.max(0, eCombatant.currentHP - pDmg)

	local effectMsg = pMult > 1.2 and " (Super Effective!)" or pMult < 0.8 and " (Not Very Effective)" or ""
	table.insert(log, pCombatant.label .. " used " .. abilName .. " → " .. pDmg .. " dmg!" .. effectMsg)

	-- Set cooldown
	if action == "special" then cd.special = abilDef.cd end
	if action == "ult"     then cd.ult     = abilDef.cd end

	-- ── CHECK ENEMY DEFEAT ────────────────────────────────────────────
	if eCombatant.currentHP <= 0 then
		state.over   = true
		state.result = "win"
		table.insert(log, eCombatant.label .. " was defeated!")
		return {
			outcome  = "win",
			log      = log,
			playerHP = pCombatant.currentHP,
			enemyHP  = 0,
			xpGain   = BattleSystem.CalcXP(eCombatant),
			coinGain = BattleSystem.CalcCoins(eCombatant),
		}
	end

	-- ── ENEMY ATTACKS ─────────────────────────────────────────────────
	-- Simple AI: randomly pick basic/special (never ultimate until low HP)
	local eAction = "basic"
	local eCd = getCooldowns(state, "enemy")
	if pCombatant.currentHP / pCombatant.maxHP < 0.3 and eCd.ult == 0 then
		eAction = "ult"; eCd.ult = ABILITY_DEFS.ult.cd
	elseif math.random() < 0.3 and eCd.special == 0 then
		eAction = "special"; eCd.special = ABILITY_DEFS.special.cd
	end

	local eAbilDef = ABILITY_DEFS[eAction]
	local eAbilName= eCombatant.abilities[eAction] or "Attack"
	local eDmg = rollDamage(
		eCombatant.stats, pCombatant.stats,
		eCombatant.element, pCombatant.element,
		eAbilDef.power, eAbilDef.magic
	)
	pCombatant.currentHP = math.max(0, pCombatant.currentHP - eDmg)
	table.insert(log, eCombatant.label .. " used " .. eAbilName .. " → " .. eDmg .. " dmg!")

	-- Tick cooldowns
	tickCooldowns(state, "player")
	tickCooldowns(state, "enemy")

	state.turn = state.turn + 1

	if pCombatant.currentHP <= 0 then
		state.over   = true
		state.result = "lose"
		table.insert(log, "Your beast fainted!")
		return {
			outcome  = "lose",
			log      = log,
			playerHP = 0,
			enemyHP  = eCombatant.currentHP,
		}
	end

	return {
		outcome   = "continue",
		log       = log,
		playerHP  = pCombatant.currentHP,
		enemyHP   = eCombatant.currentHP,
		playerMaxHP = pCombatant.maxHP,
		enemyMaxHP  = eCombatant.maxHP,
		turn      = state.turn,
		cdSpecial = cd.special,
		cdUlt     = cd.ult,
	}
end

function BattleSystem.EndBattle(player)
	battles[player.UserId] = nil
end

function BattleSystem.CalcXP(enemy)
	local base = enemy.level * 10
	if enemy.isBoss then base = base * 5 end
	return base
end

function BattleSystem.CalcCoins(enemy)
	local base = enemy.level * 5
	if enemy.isBoss then base = base * 10 end
	return base + math.random(0, base)
end

return BattleSystem
