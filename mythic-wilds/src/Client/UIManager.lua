-- MythicWilds: UIManager
-- Creates and manages all ScreenGui elements.

local TweenService = game:GetService("TweenService")
local UIManager    = {}

local GameData
local playerGui
local State

-- ── THEME ─────────────────────────────────────────────────────────────
local T = {
	bg         = Color3.fromRGB(15,  10,  30),
	panel      = Color3.fromRGB(25,  18,  50),
	accent     = Color3.fromRGB(180, 80,  255),
	accentGold = Color3.fromRGB(255, 200, 50),
	text       = Color3.fromRGB(240, 235, 255),
	textMuted  = Color3.fromRGB(160, 150, 200),
	green      = Color3.fromRGB(80,  220, 120),
	red        = Color3.fromRGB(255, 80,  80),
	orange     = Color3.fromRGB(255, 150, 50),
	white      = Color3.fromRGB(255, 255, 255),
}

local function font(n) return Enum.Font[n] or Enum.Font.Gotham end

-- ── HELPERS ───────────────────────────────────────────────────────────
local function makeGui(name, reset)
	local existing = playerGui:FindFirstChild(name)
	if existing and not reset then return existing end
	if existing then existing:Destroy() end
	local sg = Instance.new("ScreenGui")
	sg.Name            = name
	sg.ResetOnSpawn    = false
	sg.IgnoreGuiInset  = true
	sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	sg.Parent          = playerGui
	return sg
end

local function frame(parent, name, size, pos, bg, alpha)
	local f = Instance.new("Frame")
	f.Name                  = name
	f.Size                  = size
	f.Position              = pos
	f.BackgroundColor3      = bg or T.panel
	f.BackgroundTransparency= alpha or 0
	f.BorderSizePixel       = 0
	f.Parent                = parent
	return f
end

local function label(parent, text, size, pos, col, fs, fn)
	local l = Instance.new("TextLabel")
	l.Text                   = text
	l.Size                   = size
	l.Position               = pos
	l.BackgroundTransparency = 1
	l.TextColor3             = col or T.text
	l.Font                   = font(fn or "Gotham")
	l.TextScaled             = (fs == nil)
	l.TextSize               = fs or 0
	l.Parent                 = parent
	return l
end

local function btn(parent, text, size, pos, col, cb)
	local b = Instance.new("TextButton")
	b.Text                   = text
	b.Size                   = size
	b.Position               = pos
	b.BackgroundColor3       = col or T.accent
	b.TextColor3             = T.white
	b.Font                   = font("GothamBold")
	b.TextScaled             = true
	b.BorderSizePixel        = 0
	b.AutoButtonColor        = true
	b.Parent                 = parent
	if cb then b.MouseButton1Click:Connect(cb) end
	return b
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, col, thick)
	local s = Instance.new("UIStroke")
	s.Color     = col or T.accent
	s.Thickness = thick or 1.5
	s.Parent    = parent
end

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quad), props):Play()
end

local function rarityColor(r)
	return GameData.RarityColors[r] or T.text
end

local function bloodlineColor(bl)
	return (GameData.Bloodlines[bl] and GameData.Bloodlines[bl].glow) or T.text
end

-- ── SCREENS ───────────────────────────────────────────────────────────

-- Shared notice toast (top-centre)
local noticeGui
local function ensureNoticeGui()
	if not noticeGui or not noticeGui.Parent then
		noticeGui = makeGui("MW_Notice")
	end
end

function UIManager.ShowNotice(msg, style)
	ensureNoticeGui()
	local col = style == "green" and T.green or style == "red" and T.red or T.accentGold
	local f = frame(noticeGui, "Toast",
		UDim2.new(0,380,0,50), UDim2.new(0.5,-190,-0.1,0), col, 0)
	corner(f, 10)
	label(f, msg, UDim2.new(1,-20,1,0), UDim2.new(0,10,0,0), T.white, nil, "GothamBold")
	tween(f, { Position=UDim2.new(0.5,-190,0,10) }, 0.3)
	task.delay(3, function()
		tween(f, { Position=UDim2.new(0.5,-190,-0.1,0) }, 0.3)
		task.delay(0.4, function() if f.Parent then f:Destroy() end end)
	end)
end

-- Global announcement banner
function UIManager.ShowGlobalAnnouncement(msg)
	ensureNoticeGui()
	local f = frame(noticeGui, "Ann_"..tostring(tick()),
		UDim2.new(1,-40,0,45), UDim2.new(0,20,0,-60), T.accentGold, 0)
	corner(f, 12)
	stroke(f, T.white, 1)
	label(f, "  ✦  " .. msg .. "  ✦  ", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
		T.bg, nil, "GothamBold")
	tween(f, { Position=UDim2.new(0,20,0,10) }, 0.4)
	task.delay(5, function()
		tween(f, { Position=UDim2.new(0,20,0,-60) }, 0.4)
		task.delay(0.5, function() if f.Parent then f:Destroy() end end)
	end)
end

-- ── HUD ───────────────────────────────────────────────────────────────
local hudGui
function UIManager.ShowHUD(data)
	if hudGui then hudGui:Destroy() end
	hudGui = makeGui("MW_HUD")

	-- Bottom bar
	local bar = frame(hudGui, "BottomBar",
		UDim2.new(1,0,0,70), UDim2.new(0,0,1,-70), T.bg, 0.15)
	stroke(bar, T.accent, 1)

	-- Coins
	label(bar, "Coins: " .. (data.coins or 0),
		UDim2.new(0,150,1,0), UDim2.new(0,10,0,0), T.accentGold, nil, "GothamBold")

	-- Level
	label(bar, "Lv." .. (data.level or 1),
		UDim2.new(0,80,1,0), UDim2.new(0,170,0,0), T.accent, nil, "GothamBold")

	-- Nav buttons
	local navBtns = {
		{ "Beasts",    T.accent     },
		{ "Quests",    T.green      },
		{ "Trade",     T.orange     },
		{ "Evolve",    T.accentGold },
		{ "Leaderboard", T.textMuted },
	}
	for i, nb in ipairs(navBtns) do
		local b = btn(bar, nb[1],
			UDim2.new(0,100,0,44), UDim2.new(1,-(i*110)+60, 0,13), nb[2])
		corner(b, 8)
	end

	-- Active beast quick-view (top-left)
	local activeBeast = UIManager._getActiveBeast(data)
	if activeBeast then
		local card = frame(hudGui, "ActiveBeastCard",
			UDim2.new(0,200,0,80), UDim2.new(0,10,0,10), T.panel, 0.1)
		corner(card, 12)
		stroke(card, bloodlineColor(activeBeast.bloodline), 1.5)
		local tmpl = GameData.Beasts[activeBeast.beastId]
		if tmpl then
			label(card, tmpl.label,
				UDim2.new(1,-10,0,24), UDim2.new(0,5,0,5), T.text, nil, "GothamBold")
			label(card, "[" .. activeBeast.bloodline .. "] Lv." .. activeBeast.level,
				UDim2.new(1,-10,0,20), UDim2.new(0,5,0,28), bloodlineColor(activeBeast.bloodline))
			-- HP bar
			local hpBg = frame(card, "HPBg",
				UDim2.new(1,-10,0,10), UDim2.new(0,5,0,52), Color3.fromRGB(50,0,0))
			corner(hpBg, 4)
			local hp  = activeBeast.stats and activeBeast.stats.hp or 100
			local hpBar = frame(hpBg, "HPFill",
				UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), T.green)
			corner(hpBar, 4)
		end
	end
end

function UIManager.RefreshHUD(data)
	-- Just rebuild for simplicity
	UIManager.ShowHUD(data)
end

function UIManager._getActiveBeast(data)
	if not data or not data.party or #data.party == 0 then return nil end
	local uuid = data.party[1]
	for _, b in ipairs(data.beasts or {}) do
		if b.uuid == uuid then
			local GameDataB = GameData.Beasts[b.beastId]
			if GameDataB then
				local stats = require(game:GetService("ReplicatedStorage").Shared.BeastUtils).CalcStats(
					GameDataB.base, b.bloodline, b.level)
				return { beastId=b.beastId, bloodline=b.bloodline, level=b.level, stats=stats }
			end
		end
	end
	return nil
end

-- ── STARTER SELECTION ─────────────────────────────────────────────────
local starterGui
function UIManager.ShowStarterSelect(onSelect)
	if starterGui then starterGui:Destroy() end
	starterGui = makeGui("MW_StarterSelect")

	-- Dim overlay
	frame(starterGui, "Overlay", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
		Color3.fromRGB(0,0,0), 0.55)

	local panel = frame(starterGui, "Panel",
		UDim2.new(0,680,0,500), UDim2.new(0.5,-340,0.5,-250), T.bg)
	corner(panel, 18)
	stroke(panel, T.accent, 2)

	label(panel, "Choose Your Starter Beast",
		UDim2.new(1,-20,0,50), UDim2.new(0,10,0,8), T.accentGold, nil, "GothamBold")

	label(panel, "This beast will be your first companion on your journey through the Mythic Wilds.",
		UDim2.new(1,-40,0,30), UDim2.new(0,20,0,55), T.textMuted)

	-- Starter cards
	local cardW  = 110
	local startX = 20
	for i, beastId in ipairs(GameData.Starters) do
		local tmpl = GameData.Beasts[beastId]
		if tmpl then
			local x    = startX + (i-1)*(cardW+10)
			local card = frame(panel, "Card_"..beastId,
				UDim2.new(0,cardW,0,300), UDim2.new(0,x,0,95), T.panel)
			corner(card, 12)
			stroke(card, GameData.Elements[tmpl.element] and GameData.Elements[tmpl.element].color or T.accent, 1.5)

			-- Element colour blob
			local blob = frame(card, "Blob",
				UDim2.new(0,60,0,60), UDim2.new(0.5,-30,0,10),
				GameData.Elements[tmpl.element] and GameData.Elements[tmpl.element].color or T.accent)
			corner(blob, 30)

			label(card, tmpl.label, UDim2.new(1,-4,0,30), UDim2.new(0,2,0,78),
				T.text, nil, "GothamBold")
			label(card, tmpl.element, UDim2.new(1,-4,0,20), UDim2.new(0,2,0,105),
				GameData.Elements[tmpl.element] and GameData.Elements[tmpl.element].color or T.accent)

			-- Stats
			local statNames = {"HP","ATK","DEF","SPD","MAG"}
			local statKeys  = {"hp","atk","def","spd","mag"}
			for j, sk in ipairs(statKeys) do
				label(card, statNames[j]..": "..tmpl.base[sk],
					UDim2.new(1,-8,0,16), UDim2.new(0,4,0,130+(j-1)*20), T.textMuted)
			end

			-- Evo chain
			label(card, "→ " .. (GameData.Beasts[tmpl.evolvesInto or ""] and
				GameData.Beasts[tmpl.evolvesInto].label or "—"),
				UDim2.new(1,-4,0,16), UDim2.new(0,2,0,238), T.accentGold)

			local selBtn = btn(card, "Choose",
				UDim2.new(1,-10,0,32), UDim2.new(0,5,1,-40),
				GameData.Elements[tmpl.element] and GameData.Elements[tmpl.element].color or T.accent,
				function()
					onSelect(beastId)
					starterGui:Destroy()
					UIManager.ShowHUD(State.data)
				end)
			corner(selBtn, 8)
		end
	end
end

-- ── BATTLE SCREEN ─────────────────────────────────────────────────────
local battleGui
local battleCallbacks = {}

function UIManager.ShowBattleScreen(result, onAction, onFlee)
	if battleGui then battleGui:Destroy() end
	battleGui = makeGui("MW_Battle")
	battleCallbacks = { onAction=onAction, onFlee=onFlee }

	local enemy = result.enemy
	local player= result.player
	local eData = GameData.Beasts[enemy.id] or { label=enemy.id, element="Fire" }
	local pData = GameData.Beasts[player.id] or { label=player.id, element="Fire" }

	-- Background overlay
	local overlay = frame(battleGui,"BG",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),
		Color3.fromRGB(5,2,15))
	corner(overlay,0)

	-- Title
	label(overlay, "⚔ BATTLE!", UDim2.new(0,200,0,36),
		UDim2.new(0.5,-100,0,10), T.accentGold, nil, "GothamBold")

	-- Enemy card (top right)
	local enemyCard = frame(overlay,"EnemyCard",
		UDim2.new(0,220,0,130), UDim2.new(1,-235,0,55), T.panel, 0.1)
	corner(enemyCard,12)
	local eRarCol = rarityColor(eData.rarity or "Common")
	stroke(enemyCard, eRarCol, 1.5)
	label(enemyCard, eData.label, UDim2.new(1,-10,0,28), UDim2.new(0,5,0,5), T.text, nil,"GothamBold")
	label(enemyCard, "[" .. (enemy.bloodline or "Common") .. "] Lv." .. (enemy.level or 1),
		UDim2.new(1,-10,0,20), UDim2.new(0,5,0,30), bloodlineColor(enemy.bloodline or "Common"))
	-- Enemy HP bar
	local ehpBg = frame(enemyCard,"HPBg",UDim2.new(1,-10,0,14),UDim2.new(0,5,0,58),
		Color3.fromRGB(50,0,0))
	corner(ehpBg,5)
	local ehpFill = frame(ehpBg,"Fill",UDim2.new(enemy.hp/enemy.maxHP,0,1,0),
		UDim2.new(0,0,0,0), T.red)
	corner(ehpFill,5)
	ehpFill.Name = "EnemyHPFill"
	label(enemyCard, "HP: "..enemy.hp.."/"..enemy.maxHP,
		UDim2.new(1,-10,0,18), UDim2.new(0,5,0,76), T.textMuted)
	enemyCard.Name = "EnemyCard"

	-- Player card (top left)
	local pCard = frame(overlay,"PlayerCard",
		UDim2.new(0,220,0,130), UDim2.new(0,15,0,55), T.panel, 0.1)
	corner(pCard,12)
	stroke(pCard, T.accent, 1.5)
	label(pCard, pData.label, UDim2.new(1,-10,0,28), UDim2.new(0,5,0,5), T.text, nil,"GothamBold")
	label(pCard, "Lv." .. (player.level or 1),
		UDim2.new(1,-10,0,20), UDim2.new(0,5,0,30), T.accent)
	local phpBg = frame(pCard,"HPBg",UDim2.new(1,-10,0,14),UDim2.new(0,5,0,58),
		Color3.fromRGB(0,50,0))
	corner(phpBg,5)
	local phpFill = frame(phpBg,"Fill",UDim2.new(player.hp/player.maxHP,0,1,0),
		UDim2.new(0,0,0,0), T.green)
	corner(phpFill,5)
	phpFill.Name = "PlayerHPFill"
	label(pCard, "HP: "..player.hp.."/"..player.maxHP,
		UDim2.new(1,-10,0,18), UDim2.new(0,5,0,76), T.textMuted)
	pCard.Name = "PlayerCard"

	-- Battle log (middle)
	local logFrame = frame(overlay,"Log",
		UDim2.new(0.6,0,0,160), UDim2.new(0.2,0,0,200), T.bg, 0.2)
	corner(logFrame,10)
	stroke(logFrame,T.accent,1)
	local logLabel = label(logFrame,"Battle started!",
		UDim2.new(1,-10,1,-10), UDim2.new(0,5,0,5), T.textMuted)
	logLabel.TextWrapped= true
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextYAlignment = Enum.TextYAlignment.Top
	logLabel.Name = "LogLabel"

	-- Action buttons (bottom)
	local actions = {
		{ id="basic",   label="Basic",   col=T.green  },
		{ id="special", label="Special", col=T.orange },
		{ id="ult",     label="Ultimate",col=T.accent },
		{ id="flee",    label="Flee",    col=T.red    },
	}
	for i, a in ipairs(actions) do
		local b = btn(overlay, a.label,
			UDim2.new(0,130,0,48), UDim2.new(0.5,(i-3)*140+10,1,-70), a.col,
			function()
				if a.id == "flee" then
					onFlee()
				else
					onAction(a.id)
				end
			end)
		corner(b,10)
		b.Name = "Btn_"..a.id
	end
end

function UIManager.UpdateBattleScreen(result)
	if not battleGui then return end
	local overlay = battleGui:FindFirstChild("BG")
	if not overlay then return end

	-- Update HP bars
	local function updateHP(cardName, fillName, current, max)
		local card = overlay:FindFirstChild(cardName)
		if not card then return end
		local hpBg = card:FindFirstChild("HPBg")
		if not hpBg then return end
		local fill = hpBg:FindFirstChild("Fill")
		if not fill then return end
		local ratio = math.max(0, math.min(1, current/max))
		tween(fill, { Size=UDim2.new(ratio,0,1,0) }, 0.3)
	end

	if result.playerHP ~= nil then
		updateHP("PlayerCard", "PlayerHPFill", result.playerHP, result.playerMaxHP or 100)
	end
	if result.enemyHP ~= nil then
		updateHP("EnemyCard", "EnemyHPFill", result.enemyHP, result.enemyMaxHP or 100)
	end

	-- Battle log
	if result.log then
		local logLabel = overlay:FindFirstChild("Log") and overlay.Log:FindFirstChild("LogLabel")
		if logLabel then
			logLabel.Text = table.concat(result.log, "\n")
		end
	end

	-- Cooldown visuals
	local function setCdBtn(id, cd)
		local b = overlay:FindFirstChild("Btn_"..id)
		if b then
			b.Text = (GameData.Quests and id or id) -- keep label
			if cd and cd > 0 then
				b.BackgroundTransparency = 0.6
				b.Text = id:gsub("^%l",string.upper) .. " (" .. cd .. ")"
			else
				b.BackgroundTransparency = 0
			end
		end
	end
	setCdBtn("special", result.cdSpecial)
	setCdBtn("ult",     result.cdUlt)
end

function UIManager.CloseBattleScreen(outcome)
	if not battleGui then return end
	local msg = outcome == "win"  and "Victory!" or
	            outcome == "lose" and "Defeated..." or "Fled safely."
	local col = outcome == "win"  and T.green or
	            outcome == "lose" and T.red or T.textMuted
	UIManager.ShowNotice(msg, outcome == "win" and "green" or outcome == "lose" and "red" or nil)
	task.delay(0.5, function()
		if battleGui then battleGui:Destroy(); battleGui = nil end
	end)
end

-- ── TAMING ────────────────────────────────────────────────────────────
local crystalGui
function UIManager.ShowCrystalSelect(data, onSelect)
	if crystalGui then crystalGui:Destroy() end
	crystalGui = makeGui("MW_Crystal")

	local panel = frame(crystalGui,"Panel",
		UDim2.new(0,400,0,320),UDim2.new(0.5,-200,0.5,-160), T.bg)
	corner(panel,16)
	stroke(panel,T.accent,2)
	label(panel,"Select Taming Crystal",UDim2.new(1,-20,0,36),UDim2.new(0,10,0,8),
		T.accentGold,nil,"GothamBold")

	local y = 54
	for crystalId, crystal in pairs(GameData.Crystals) do
		local have = data.inventory[crystalId] or 0
		if have > 0 then
			local b = btn(panel, crystal.label .. "  ×" .. have,
				UDim2.new(1,-20,0,40), UDim2.new(0,10,0,y), T.panel,
				function()
					crystalGui:Destroy(); crystalGui=nil
					onSelect(crystalId)
				end)
			corner(b,8)
			stroke(b,T.accent,1)
			b.TextColor3 = T.text
			label(panel, math.floor((crystal.baseRate)*100).."%",
				UDim2.new(0,50,0,40), UDim2.new(1,-60,0,y), T.green)
			y = y + 48
		end
	end

	if y == 54 then
		label(panel,"No crystals in inventory!",UDim2.new(1,-20,0,40),
			UDim2.new(0,10,0,y), T.red)
	end

	btn(panel,"Cancel",UDim2.new(0,100,0,36),UDim2.new(0.5,-50,1,-46),T.red,function()
		crystalGui:Destroy(); crystalGui=nil
	end)
end

-- ── TAME SUCCESS ──────────────────────────────────────────────────────
function UIManager.ShowTameSuccess(savedBeast, msg)
	local tmpl = GameData.Beasts[savedBeast.beastId]
	if not tmpl then return end
	local bl   = GameData.Bloodlines[savedBeast.bloodline] or GameData.Bloodlines.Common

	local tameGui = makeGui("MW_TameSuccess_"..savedBeast.uuid, true)
	local panel = frame(tameGui,"Panel",
		UDim2.new(0,360,0,240),UDim2.new(0.5,-180,0.5,-120), T.bg)
	corner(panel,18)
	stroke(panel, bl.glow, 2.5)

	label(panel,"Beast Tamed!",UDim2.new(1,-20,0,40),UDim2.new(0,10,0,8),
		T.green,nil,"GothamBold")
	label(panel, tmpl.label, UDim2.new(1,-20,0,36),UDim2.new(0,10,0,48),
		T.text, nil, "GothamBold")
	label(panel,"["..bl.label.."] Lv."..savedBeast.level,
		UDim2.new(1,-20,0,26),UDim2.new(0,10,0,82), bl.glow)

	local rarCol = rarityColor(tmpl.rarity)
	label(panel, tmpl.rarity, UDim2.new(0,100,0,24),UDim2.new(0,10,0,110), rarCol)
	label(panel, tmpl.element, UDim2.new(0,100,0,24),UDim2.new(0.5,0,0,110),
		GameData.Elements[tmpl.element] and GameData.Elements[tmpl.element].color or T.text)

	btn(panel,"Awesome!",UDim2.new(0,140,0,40),UDim2.new(0.5,-70,1,-50),T.green,function()
		tameGui:Destroy()
	end)

	task.delay(5, function() if tameGui.Parent then tameGui:Destroy() end end)
end

-- ── EVOLUTION ─────────────────────────────────────────────────────────
function UIManager.ShowEvolutionCutscene(savedBeast, newBeastId)
	local newTmpl = GameData.Beasts[newBeastId]
	if not newTmpl then return end

	local evoGui = makeGui("MW_Evo_"..tostring(tick()), true)
	local overlay= frame(evoGui,"OV",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),
		T.accent,0)
	tween(overlay,{BackgroundTransparency=0.1},0.5)

	label(overlay,"★ EVOLUTION! ★",UDim2.new(0,500,0,60),
		UDim2.new(0.5,-250,0.3,0),T.accentGold,nil,"GothamBold")
	label(overlay, newTmpl.label,UDim2.new(0,400,0,50),
		UDim2.new(0.5,-200,0.45,0),T.white,nil,"GothamBold")
	label(overlay,newTmpl.desc,UDim2.new(0,400,0,36),
		UDim2.new(0.5,-200,0.55,0),T.text)

	btn(overlay,"Incredible!",UDim2.new(0,180,0,48),
		UDim2.new(0.5,-90,0.7,0),T.green,function() evoGui:Destroy() end)

	task.delay(8, function() if evoGui.Parent then evoGui:Destroy() end end)
end

-- ── LEVEL UP ──────────────────────────────────────────────────────────
function UIManager.ShowLevelUp(levels, beastId)
	local tmpl = GameData.Beasts[beastId]
	UIManager.ShowNotice("Level up! " .. (tmpl and tmpl.label or beastId) ..
		" is now Lv." .. levels[#levels], "green")
end

-- ── QUEST COMPLETE ────────────────────────────────────────────────────
function UIManager.ShowQuestComplete(questTemplate, rewards)
	local qGui = makeGui("MW_Quest_"..questTemplate.id, true)
	local panel = frame(qGui,"Panel",
		UDim2.new(0,340,0,200),UDim2.new(0.5,-170,0.5,-100), T.bg)
	corner(panel,16)
	stroke(panel,T.green,2)

	label(panel,"Quest Complete!",UDim2.new(1,-20,0,36),UDim2.new(0,10,0,8),
		T.green,nil,"GothamBold")
	label(panel,questTemplate.label,UDim2.new(1,-20,0,28),UDim2.new(0,10,0,44),
		T.accentGold,nil,"GothamBold")

	local rewStr = ""
	if rewards.coins then rewStr = rewStr .. "+" .. rewards.coins .. " Coins  " end
	if rewards.xp    then rewStr = rewStr .. "+" .. rewards.xp    .. " XP  "   end
	label(panel,rewStr,UDim2.new(1,-20,0,24),UDim2.new(0,10,0,78),T.text)

	btn(panel,"Claim",UDim2.new(0,120,0,38),UDim2.new(0.5,-60,1,-50),T.green,function()
		qGui:Destroy()
	end)

	task.delay(8, function() if qGui.Parent then qGui:Destroy() end end)
end

-- ── DAILY REWARD ──────────────────────────────────────────────────────
function UIManager.ShowDailyReward(reward)
	local drGui = makeGui("MW_Daily",true)
	local panel = frame(drGui,"Panel",
		UDim2.new(0,340,0,220),UDim2.new(0.5,-170,0.5,-110), T.bg)
	corner(panel,16)
	stroke(panel,T.accentGold,2)

	label(panel,"Daily Reward!",UDim2.new(1,-20,0,40),UDim2.new(0,10,0,8),
		T.accentGold,nil,"GothamBold")
	label(panel,"Login Streak: " .. reward.streak .. " days",
		UDim2.new(1,-20,0,28),UDim2.new(0,10,0,50),T.text)
	label(panel,"+" .. reward.coins .. " Coins",
		UDim2.new(1,-20,0,32),UDim2.new(0,10,0,84),T.green,nil,"GothamBold")

	btn(panel,"Collect!",UDim2.new(0,140,0,40),UDim2.new(0.5,-70,1,-52),T.accentGold,
		function() drGui:Destroy() end)
end

-- ── TRADE UI ──────────────────────────────────────────────────────────
local tradeGui
function UIManager.ShowTradeRequest(info, onRespond)
	if tradeGui then tradeGui:Destroy() end
	tradeGui = makeGui("MW_Trade")

	local panel = frame(tradeGui,"Panel",
		UDim2.new(0,420,0,300),UDim2.new(0.5,-210,0.5,-150),T.bg)
	corner(panel,16)
	stroke(panel,T.orange,2)

	label(panel,"Trade Request from " .. info.from,
		UDim2.new(1,-20,0,36),UDim2.new(0,10,0,8),T.orange,nil,"GothamBold")

	local offer = info.offer
	local offerStr = "Offering: "
	if offer.beastUUID then offerStr = offerStr .. "Beast  " end
	if offer.coins and offer.coins > 0 then offerStr = offerStr .. offer.coins .. " Coins  " end
	label(panel,offerStr,UDim2.new(1,-20,0,28),UDim2.new(0,10,0,52),T.text)

	label(panel,"Tap Accept to counter-offer nothing, or Decline to refuse.",
		UDim2.new(1,-20,0,40),UDim2.new(0,10,0,88),T.textMuted)

	-- Accept (no counter for MVP)
	btn(panel,"Accept",UDim2.new(0,140,0,42),UDim2.new(0,20,1,-60),T.green,function()
		onRespond(true, { coins=0, mats={} })
	end)
	btn(panel,"Decline",UDim2.new(0,140,0,42),UDim2.new(1,-160,1,-60),T.red,function()
		onRespond(false, nil)
	end)
end

function UIManager.CloseTradeUI()
	if tradeGui then tradeGui:Destroy(); tradeGui=nil end
end

-- ── PROXIMITY PROMPT ──────────────────────────────────────────────────
local proximityGui
local lastNpcId
function UIManager.ShowProximityPrompt(npcId, beastId, onBattle, onTame)
	if lastNpcId == npcId then return end
	lastNpcId = npcId
	if proximityGui then proximityGui:Destroy() end
	proximityGui = makeGui("MW_Proximity")

	local tmpl = GameData.Beasts[beastId]
	local name = tmpl and tmpl.label or beastId
	local panel= frame(proximityGui,"Panel",
		UDim2.new(0,200,0,90),UDim2.new(0.5,-100,1,-120),T.bg,0.1)
	corner(panel,12)
	stroke(panel,T.accent,1.5)

	label(panel,name,UDim2.new(1,-10,0,24),UDim2.new(0,5,0,4),T.text,nil,"GothamBold")

	btn(panel,"⚔ Battle",UDim2.new(0,80,0,30),UDim2.new(0,5,0,32),T.orange,onBattle)
	btn(panel,"◎ Tame",  UDim2.new(0,80,0,30),UDim2.new(1,-85,0,32),T.accent, onTame)
end

function UIManager.HideProximityPrompt()
	if proximityGui then
		proximityGui:Destroy()
		proximityGui=nil
		lastNpcId=nil
	end
end

-- ── WILD BEAST SPAWNED (Notification) ────────────────────────────────
function UIManager.OnWildBeastSpawned(npcId, beastId, bloodline, level, realmId)
	local tmpl  = GameData.Beasts[beastId]
	if not tmpl then return end
	local rarity= tmpl.rarity
	-- Only notify for Rare+
	if GameData.RarityIndex(rarity) >= 3 then
		local bl    = GameData.Bloodlines[bloodline] or GameData.Bloodlines.Common
		local realm = GameData.Realms[realmId]
		UIManager.ShowNotice(
			rarity .. " " .. tmpl.label .. " [" .. bl.label .. "] appeared in " ..
			(realm and realm.label or realmId) .. "!", "green")
	end
end

-- ── INIT ──────────────────────────────────────────────────────────────
function UIManager.Init(s, gui, gd)
	State     = s
	playerGui = gui
	GameData  = gd
end

return UIManager
