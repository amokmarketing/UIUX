-- MythicWilds: GameData
-- Single source of truth for all game constants, beasts, bloodlines, realms, quests.
-- ModuleScript lives in ReplicatedStorage/Shared

local GameData = {}

-- =====================================================================
-- BLOODLINES
-- =====================================================================
GameData.Bloodlines = {
	Common    = { id="Common",    weight=60,   statMult=1.00, atkMult=1.00, defMult=1.00, tradeValue=1,   glow=Color3.fromRGB(200,200,200), label="Common",    desc="Balanced stats."                             },
	Royal     = { id="Royal",     weight=20,   statMult=1.20, atkMult=1.10, defMult=1.10, tradeValue=5,   glow=Color3.fromRGB(255,215,0),   label="Royal",     desc="Gold markings. Team buff aura."              },
	Ancient   = { id="Ancient",   weight=8,    statMult=1.50, atkMult=1.30, defMult=1.50, tradeValue=15,  glow=Color3.fromRGB(180,140,80),  label="Ancient",   desc="Slow XP but monstrous final stats."          },
	Cursed    = { id="Cursed",    weight=6,    statMult=1.10, atkMult=1.40, defMult=0.75, tradeValue=20,  glow=Color3.fromRGB(160,0,200),   label="Cursed",    desc="Dark power. High damage, low defense."       },
	Celestial = { id="Celestial", weight=3,    statMult=1.30, atkMult=1.20, defMult=1.30, tradeValue=50,  glow=Color3.fromRGB(140,200,255), label="Celestial", desc="Starlight aura. Rare healing ability."       },
	Primal    = { id="Primal",    weight=2,    statMult=1.20, atkMult=1.60, defMult=1.10, tradeValue=40,  glow=Color3.fromRGB(180,30,30),   label="Primal",    desc="Larger form. Devastating physical attacks."  },
	Void      = { id="Void",      weight=0.8,  statMult=1.40, atkMult=1.50, defMult=1.20, tradeValue=100, glow=Color3.fromRGB(80,0,160),    label="Void",      desc="Purple-black tendrils. Dark magic."          },
	Secret    = { id="Secret",    weight=0.2,  statMult=2.00, atkMult=2.00, defMult=2.00, tradeValue=500, glow=Color3.fromRGB(255,255,100), label="???",       desc="Extremely rare. Unique ultimate ability."    },
}
GameData.BloodlineOrder = {"Common","Royal","Ancient","Cursed","Celestial","Primal","Void","Secret"}

function GameData.RollBloodline(luckBonus)
	luckBonus = luckBonus or 0
	local pool = {}
	for _, name in ipairs(GameData.BloodlineOrder) do
		local w = GameData.Bloodlines[name].weight * (1 + luckBonus)
		table.insert(pool, { name=name, w=w })
	end
	local total = 0
	for _, e in ipairs(pool) do total = total + e.w end
	local r = math.random() * total
	local cum = 0
	for _, e in ipairs(pool) do
		cum = cum + e.w
		if r <= cum then return e.name end
	end
	return "Common"
end

-- =====================================================================
-- ELEMENTS & ADVANTAGE TABLE
-- =====================================================================
GameData.Elements = {
	Fire      = { color=Color3.fromRGB(255,90,0),   icon="fire"      },
	Water     = { color=Color3.fromRGB(0,120,255),  icon="water"     },
	Nature    = { color=Color3.fromRGB(0,180,60),   icon="leaf"      },
	Lightning = { color=Color3.fromRGB(255,240,0),  icon="lightning" },
	Earth     = { color=Color3.fromRGB(150,100,50), icon="earth"     },
	Ice       = { color=Color3.fromRGB(180,230,255),icon="ice"       },
	Shadow    = { color=Color3.fromRGB(100,0,180),  icon="shadow"    },
	Celestial = { color=Color3.fromRGB(255,210,60), icon="star"      },
	Void      = { color=Color3.fromRGB(120,0,200),  icon="void"      },
	Spirit    = { color=Color3.fromRGB(255,180,220),icon="spirit"    },
}

-- [attacker] beats [defender]
local ADVANTAGES = {
	Fire      = { Nature=true,  Ice=true    },
	Water     = { Fire=true,    Earth=true  },
	Nature    = { Water=true,   Earth=true  },
	Lightning = { Water=true,   Ice=true    },
	Earth     = { Lightning=true, Fire=true },
	Ice       = { Nature=true               },
	Shadow    = { Spirit=true,  Celestial=true },
	Celestial = { Shadow=true,  Void=true   },
	Void      = { Celestial=true, Spirit=true },
	Spirit    = { Shadow=true               },
}

function GameData.ElementMultiplier(atkElem, defElem)
	if ADVANTAGES[atkElem] and ADVANTAGES[atkElem][defElem] then return 1.5 end
	if ADVANTAGES[defElem] and ADVANTAGES[defElem][atkElem] then return 0.7 end
	return 1.0
end

-- =====================================================================
-- MATERIALS
-- =====================================================================
GameData.Materials = {
	FireStone     = { id="FireStone",     label="Fire Stone",      rarity="Common",   value=10  },
	WaterStone    = { id="WaterStone",    label="Water Stone",     rarity="Common",   value=10  },
	NatureStone   = { id="NatureStone",   label="Nature Stone",    rarity="Common",   value=10  },
	ThunderStone  = { id="ThunderStone",  label="Thunder Stone",   rarity="Common",   value=10  },
	EarthStone    = { id="EarthStone",    label="Earth Stone",     rarity="Common",   value=10  },
	IceStone      = { id="IceStone",      label="Ice Stone",       rarity="Uncommon", value=25  },
	ShadowCore    = { id="ShadowCore",    label="Shadow Core",     rarity="Rare",     value=60  },
	CelestialShard= { id="CelestialShard",label="Celestial Shard", rarity="Epic",     value=180 },
	AncientRune   = { id="AncientRune",   label="Ancient Rune",    rarity="Rare",     value=80  },
}

-- =====================================================================
-- TAMING CRYSTALS
-- =====================================================================
GameData.Crystals = {
	BasicCrystal    = { id="BasicCrystal",    label="Basic Crystal",    baseRate=0.40, rarityBonus=0.00, bloodBonus=0.00, bloodUpgrade=0.00, price=50   },
	SilverCrystal   = { id="SilverCrystal",   label="Silver Crystal",   baseRate=0.60, rarityBonus=0.05, bloodBonus=0.02, bloodUpgrade=0.00, price=200  },
	GoldenCrystal   = { id="GoldenCrystal",   label="Golden Crystal",   baseRate=0.75, rarityBonus=0.10, bloodBonus=0.05, bloodUpgrade=0.00, price=500  },
	MythicCrystal   = { id="MythicCrystal",   label="Mythic Crystal",   baseRate=0.90, rarityBonus=0.15, bloodBonus=0.10, bloodUpgrade=0.00, price=2000 },
	BloodlineCrystal= { id="BloodlineCrystal",label="Bloodline Crystal", baseRate=0.80, rarityBonus=0.20, bloodBonus=0.30, bloodUpgrade=0.15, price=5000 },
}

-- =====================================================================
-- BEASTS
-- Each beast: base stats, abilities, evolution chain, spawn data
-- =====================================================================
GameData.Beasts = {

	-- ── STARTER CHAIN 1: Fire ────────────────────────────────────────
	EmberDrake = {
		id="EmberDrake", label="Ember Drake", element="Fire", rarity="Common", stage=1,
		base={ hp=80, atk=12, def=8,  spd=10, mag=6,  luck=5  },
		evolvesInto="FlameWyvern", evoLevel=20,
		evoReq={ coins=500,  mats={FireStone=3}, bond=5 },
		abilities={ basic="Ember Scratch", special="Flame Burst",   ult="Dragon Breath"  },
		desc="A young fire drake with a passionate spirit.",
		isStarter=true, realms={"EmberForest"}, spawnW=30,
	},
	FlameWyvern = {
		id="FlameWyvern", label="Flame Wyvern", element="Fire", rarity="Rare", stage=2,
		base={ hp=140, atk=22, def=15, spd=18, mag=12, luck=8  },
		evolvesInto="InfernoDragon", evoLevel=40,
		evoReq={ coins=2000, mats={FireStone=8, AncientRune=2}, bond=15 },
		abilities={ basic="Wing Slash",  special="Inferno Storm",  ult="Wyvern Blaze"   },
		desc="A powerful wyvern wreathed in living flame.",
		isStarter=false, realms={}, spawnW=0,
	},
	InfernoDragon = {
		id="InfernoDragon", label="Inferno Dragon", element="Fire", rarity="Legendary", stage=3,
		base={ hp=250, atk=42, def=28, spd=30, mag=35, luck=15 },
		evolvesInto=nil,
		abilities={ basic="Dragon Claw", special="Magma Wave",    ult="World Burner"   },
		desc="The legendary Inferno Dragon, master of all fire.",
		isStarter=false, realms={}, spawnW=0,
	},

	-- ── STARTER CHAIN 2: Water ───────────────────────────────────────
	AquaSerpent = {
		id="AquaSerpent", label="Aqua Serpent", element="Water", rarity="Common", stage=1,
		base={ hp=90, atk=10, def=10, spd=12, mag=10, luck=5  },
		evolvesInto="TideWyrm", evoLevel=20,
		evoReq={ coins=500,  mats={WaterStone=3}, bond=5 },
		abilities={ basic="Water Whip",  special="Tidal Wave",    ult="Serpent Flood"  },
		desc="A graceful sea serpent with deep ocean magic.",
		isStarter=true, realms={"EmberForest","AbyssOcean"}, spawnW=25,
	},
	TideWyrm = {
		id="TideWyrm", label="Tide Wyrm", element="Water", rarity="Rare", stage=2,
		base={ hp=160, atk=18, def=20, spd=22, mag=18, luck=8  },
		evolvesInto="AbyssLeviathan", evoLevel=40,
		evoReq={ coins=2000, mats={WaterStone=8, CelestialShard=2}, bond=15 },
		abilities={ basic="Tide Slam",   special="Whirlpool",     ult="Wyrm Tsunami"   },
		desc="A powerful wyrm that commands ocean currents.",
		isStarter=false, realms={"AbyssOcean"}, spawnW=10,
	},
	AbyssLeviathan = {
		id="AbyssLeviathan", label="Abyss Leviathan", element="Water", rarity="Legendary", stage=3,
		base={ hp=280, atk=35, def=38, spd=40, mag=40, luck=12 },
		evolvesInto=nil,
		abilities={ basic="Abyss Strike", special="Deep Tempest", ult="Void of the Deep"},
		desc="The ancient ruler of the deepest oceans.",
		isStarter=false, realms={}, spawnW=0,
	},

	-- ── STARTER CHAIN 3: Nature/Air ──────────────────────────────────
	LeafGriffin = {
		id="LeafGriffin", label="Leaf Griffin", element="Nature", rarity="Common", stage=1,
		base={ hp=75, atk=9,  def=9,  spd=14, mag=9,  luck=7  },
		evolvesInto="ForestGriffin", evoLevel=20,
		evoReq={ coins=500,  mats={NatureStone=3}, bond=5 },
		abilities={ basic="Leaf Claw",   special="Wind Gust",     ult="Gale Slash"     },
		desc="A young griffin with leaves woven into its wings.",
		isStarter=true, realms={"EmberForest"}, spawnW=28,
	},
	ForestGriffin = {
		id="ForestGriffin", label="Forest Griffin", element="Nature", rarity="Rare", stage=2,
		base={ hp=130, atk=16, def=16, spd=26, mag=14, luck=10 },
		evolvesInto="ElderSkyGriffin", evoLevel=40,
		evoReq={ coins=2000, mats={NatureStone=8, ThunderStone=3}, bond=15 },
		abilities={ basic="Talon Strike", special="Storm Call",   ult="Tempest Flight" },
		desc="A majestic griffin that soars above ancient forests.",
		isStarter=false, realms={}, spawnW=0,
	},
	ElderSkyGriffin = {
		id="ElderSkyGriffin", label="Elder Sky Griffin", element="Nature", rarity="Legendary", stage=3,
		base={ hp=230, atk=32, def=30, spd=50, mag=28, luck=20 },
		evolvesInto=nil,
		abilities={ basic="Sky Rend",    special="Cyclone Strike", ult="Heaven's Wing"  },
		desc="The ancient guardian of the sky realms.",
		isStarter=false, realms={}, spawnW=0,
	},

	-- ── STARTER CHAIN 4: Lightning/Spirit ────────────────────────────
	SparkKitsune = {
		id="SparkKitsune", label="Spark Kitsune", element="Lightning", rarity="Common", stage=1,
		base={ hp=70, atk=11, def=7,  spd=16, mag=12, luck=9  },
		evolvesInto="VoltKitsune", evoLevel=20,
		evoReq={ coins=500,  mats={ThunderStone=3}, bond=5 },
		abilities={ basic="Thunder Paw", special="Lightning Dash", ult="Spirit Shock"  },
		desc="A mischievous spirit fox with electric tails.",
		isStarter=true, realms={"EmberForest","SunspireDesert"}, spawnW=22,
	},
	VoltKitsune = {
		id="VoltKitsune", label="Volt Kitsune", element="Lightning", rarity="Rare", stage=2,
		base={ hp=120, atk=20, def=12, spd=30, mag=22, luck=12 },
		evolvesInto="ThunderSpiritFox", evoLevel=40,
		evoReq={ coins=2000, mats={ThunderStone=8, ShadowCore=2}, bond=15 },
		abilities={ basic="Volt Bite",   special="Thunder Fox Fire", ult="Storm Spirit" },
		desc="A nimble fox spirit that moves at lightning speed.",
		isStarter=false, realms={}, spawnW=0,
	},
	ThunderSpiritFox = {
		id="ThunderSpiritFox", label="Thunder Spirit Fox", element="Lightning", rarity="Legendary", stage=3,
		base={ hp=210, atk=38, def=22, spd=60, mag=44, luck=25 },
		evolvesInto=nil,
		abilities={ basic="Storm Claw", special="Nine Thunder Tails", ult="Spirit of the Storm" },
		desc="A divine nine-tailed fox of pure thunderous spirit.",
		isStarter=false, realms={}, spawnW=0,
	},

	-- ── STARTER CHAIN 5: Earth ───────────────────────────────────────
	PebbleGolem = {
		id="PebbleGolem", label="Pebble Golem", element="Earth", rarity="Common", stage=1,
		base={ hp=100, atk=10, def=15, spd=6,  mag=5,  luck=4  },
		evolvesInto="RuneGolem", evoLevel=20,
		evoReq={ coins=500,  mats={EarthStone=3}, bond=5 },
		abilities={ basic="Rock Smash",  special="Earthen Shield", ult="Boulder Crash"  },
		desc="A small but sturdy golem of living stone.",
		isStarter=true, realms={"EmberForest","SunspireDesert"}, spawnW=20,
	},
	RuneGolem = {
		id="RuneGolem", label="Rune Golem", element="Earth", rarity="Rare", stage=2,
		base={ hp=200, atk=18, def=30, spd=10, mag=15, luck=6  },
		evolvesInto="AncientTitan", evoLevel=40,
		evoReq={ coins=2000, mats={EarthStone=8, AncientRune=3}, bond=15 },
		abilities={ basic="Rune Strike", special="Granite Wall",  ult="Rune Explosion"  },
		desc="A golem inscribed with ancient magic runes.",
		isStarter=false, realms={"SunspireDesert"}, spawnW=8,
	},
	AncientTitan = {
		id="AncientTitan", label="Ancient Titan", element="Earth", rarity="Legendary", stage=3,
		base={ hp=400, atk=35, def=60, spd=15, mag=25, luck=8  },
		evolvesInto=nil,
		abilities={ basic="Titan Slam",  special="Quake",         ult="World Breaker"   },
		desc="An ancient titan of immeasurable power and endurance.",
		isStarter=false, realms={}, spawnW=0,
	},

	-- ── WILD BEASTS ──────────────────────────────────────────────────
	MoonOwlbear = {
		id="MoonOwlbear", label="Moon Owlbear", element="Spirit", rarity="Uncommon", stage=1,
		base={ hp=85, atk=13, def=11, spd=11, mag=14, luck=8  },
		evolvesInto=nil,
		abilities={ basic="Talon Swipe", special="Moonbeam",      ult="Lunar Howl"      },
		desc="A mystical owlbear that hunts under moonlight.",
		isStarter=false, realms={"EmberForest"}, spawnW=20,
	},
	CrystalStag = {
		id="CrystalStag", label="Crystal Stag", element="Nature", rarity="Rare", stage=1,
		base={ hp=90, atk=11, def=14, spd=20, mag=16, luck=12 },
		evolvesInto=nil,
		abilities={ basic="Crystal Antler", special="Prism Beam", ult="Crystal Tempest" },
		desc="A majestic stag with antlers of pure crystal.",
		isStarter=false, realms={"EmberForest"}, spawnW=8,
	},
	FrostWyvern = {
		id="FrostWyvern", label="Frost Wyvern", element="Ice", rarity="Rare", stage=1,
		base={ hp=120, atk=19, def=14, spd=15, mag=16, luck=7  },
		evolvesInto=nil,
		abilities={ basic="Frost Claw", special="Blizzard Breath", ult="Arctic Storm"   },
		desc="A fearsome wyvern from the frozen peaks.",
		isStarter=false, realms={"FrostPeaks"}, spawnW=25,
	},
	SnowGriffin = {
		id="SnowGriffin", label="Snow Griffin", element="Ice", rarity="Uncommon", stage=1,
		base={ hp=100, atk=14, def=12, spd=18, mag=10, luck=9  },
		evolvesInto=nil,
		abilities={ basic="Ice Talon",   special="Snowstorm",     ult="Frozen Wing"     },
		desc="A graceful griffin with wings of pure snow.",
		isStarter=false, realms={"FrostPeaks"}, spawnW=30,
	},
	IceGolem = {
		id="IceGolem", label="Ice Golem", element="Ice", rarity="Common", stage=1,
		base={ hp=130, atk=12, def=20, spd=5,  mag=8,  luck=4  },
		evolvesInto=nil,
		abilities={ basic="Ice Punch",   special="Frost Wall",    ult="Glacier Slam"    },
		desc="A slow but powerful golem of living ice.",
		isStarter=false, realms={"FrostPeaks"}, spawnW=20,
	},
	SpiritUnicorn = {
		id="SpiritUnicorn", label="Spirit Unicorn", element="Celestial", rarity="Epic", stage=1,
		base={ hp=110, atk=13, def=16, spd=22, mag=25, luck=18 },
		evolvesInto=nil,
		abilities={ basic="Horn Thrust", special="Starlight Beam", ult="Celestial Blessing"},
		desc="A rare unicorn radiating pure celestial energy.",
		isStarter=false, realms={"FrostPeaks"}, spawnW=5,
	},
	ShadowCerberus = {
		id="ShadowCerberus", label="Shadow Cerberus", element="Shadow", rarity="Rare", stage=1,
		base={ hp=140, atk=22, def=13, spd=17, mag=18, luck=7  },
		evolvesInto=nil,
		abilities={ basic="Triple Bite", special="Shadow Howl",   ult="Hellfire Pyre"   },
		desc="A three-headed guardian of shadow realms.",
		isStarter=false, realms={"ShadowMarsh"}, spawnW=20,
	},
	VenomHydra = {
		id="VenomHydra", label="Venom Hydra", element="Shadow", rarity="Epic", stage=1,
		base={ hp=160, atk=18, def=15, spd=12, mag=20, luck=8  },
		evolvesInto=nil,
		abilities={ basic="Venom Bite",  special="Acid Spray",    ult="Hydra Regen"     },
		desc="A multi-headed serpent with lethal venom.",
		isStarter=false, realms={"ShadowMarsh"}, spawnW=12,
	},
	CursedCrow = {
		id="CursedCrow", label="Cursed Crow", element="Shadow", rarity="Common", stage=1,
		base={ hp=65, atk=15, def=8,  spd=20, mag=12, luck=10 },
		evolvesInto=nil,
		abilities={ basic="Claw Scratch", special="Dark Wing",    ult="Curse Flock"     },
		desc="A crow touched by dark magic, quick and deadly.",
		isStarter=false, realms={"ShadowMarsh"}, spawnW=35,
	},
	Basilisk = {
		id="Basilisk", label="Basilisk", element="Shadow", rarity="Epic", stage=1,
		base={ hp=150, atk=20, def=18, spd=10, mag=22, luck=9  },
		evolvesInto=nil,
		abilities={ basic="Stone Gaze",  special="Petrify",       ult="King's Gaze"     },
		desc="A legendary serpent whose gaze can petrify enemies.",
		isStarter=false, realms={"ShadowMarsh"}, spawnW=10,
	},
	SolarPhoenix = {
		id="SolarPhoenix", label="Solar Phoenix", element="Fire", rarity="Epic", stage=1,
		base={ hp=130, atk=24, def=14, spd=28, mag=28, luck=15 },
		evolvesInto=nil,
		abilities={ basic="Solar Talon", special="Rebirth Flame", ult="Solar Eruption"  },
		desc="A phoenix born from the heart of the sun.",
		isStarter=false, realms={"SunspireDesert"}, spawnW=10,
	},
	SandManticore = {
		id="SandManticore", label="Sand Manticore", element="Earth", rarity="Rare", stage=1,
		base={ hp=150, atk=21, def=16, spd=16, mag=11, luck=7  },
		evolvesInto=nil,
		abilities={ basic="Sand Claw",  special="Spine Volley",   ult="Desert Storm"    },
		desc="A fearsome manticore hiding beneath the desert sands.",
		isStarter=false, realms={"SunspireDesert"}, spawnW=20,
	},
	SunGriffin = {
		id="SunGriffin", label="Sun Griffin", element="Celestial", rarity="Epic", stage=1,
		base={ hp=120, atk=20, def=16, spd=24, mag=22, luck=14 },
		evolvesInto=nil,
		abilities={ basic="Golden Talon", special="Solar Beam",   ult="Blazing Dive"    },
		desc="A radiant griffin blessed by solar magic.",
		isStarter=false, realms={"SunspireDesert"}, spawnW=10,
	},
	TidalSerpent = {
		id="TidalSerpent", label="Tidal Serpent", element="Water", rarity="Rare", stage=1,
		base={ hp=130, atk=17, def=16, spd=19, mag=16, luck=8  },
		evolvesInto=nil,
		abilities={ basic="Whip Strike", special="Tidal Pull",    ult="Maelstrom"       },
		desc="A powerful serpent that rides tidal waves.",
		isStarter=false, realms={"AbyssOcean"}, spawnW=22,
	},
	PearlAlicorn = {
		id="PearlAlicorn", label="Pearl Alicorn", element="Celestial", rarity="Legendary", stage=1,
		base={ hp=140, atk=16, def=20, spd=26, mag=32, luck=22 },
		evolvesInto=nil,
		abilities={ basic="Pearl Horn",  special="Ocean Light",   ult="Divine Tide"     },
		desc="A legendary alicorn dwelling in the deepest ocean.",
		isStarter=false, realms={"AbyssOcean"}, spawnW=3,
	},
	CelestialDragon = {
		id="CelestialDragon", label="Celestial Dragon", element="Celestial", rarity="Mythic", stage=1,
		base={ hp=300, atk=50, def=45, spd=40, mag=60, luck=30 },
		evolvesInto=nil,
		abilities={ basic="Celestial Strike", special="Star Shower", ult="Cosmic Breath" },
		desc="A mythic dragon born from the stars themselves.",
		isStarter=false, realms={"CelestialIsles"}, spawnW=3,
	},
	GalaxyAlicorn = {
		id="GalaxyAlicorn", label="Galaxy Alicorn", element="Celestial", rarity="Mythic", stage=1,
		base={ hp=260, atk=40, def=40, spd=55, mag=70, luck=35 },
		evolvesInto=nil,
		abilities={ basic="Galaxy Horn",  special="Nebula Beam",   ult="Universal Harmony" },
		desc="An alicorn that embodies the entire galaxy.",
		isStarter=false, realms={"CelestialIsles"}, spawnW=3,
	},
	VoidPhoenix = {
		id="VoidPhoenix", label="Void Phoenix", element="Void", rarity="Mythic", stage=1,
		base={ hp=240, atk=55, def=30, spd=50, mag=65, luck=20 },
		evolvesInto=nil,
		abilities={ basic="Void Talon",  special="Dark Rebirth",   ult="Reality Tear"   },
		desc="A phoenix that burns with the dark fire of the void.",
		isStarter=false, realms={"CelestialIsles"}, spawnW=2,
	},
	TimeHydra = {
		id="TimeHydra", label="Time Hydra", element="Void", rarity="Secret", stage=1,
		base={ hp=350, atk=60, def=50, spd=45, mag=80, luck=40 },
		evolvesInto=nil,
		abilities={ basic="Time Bite",   special="Temporal Shift", ult="Time Collapse"  },
		desc="A secret hydra that exists across multiple timelines.",
		isStarter=false, realms={"CelestialIsles"}, spawnW=0.5,
	},
}

-- Starters list (for starter selection screen)
GameData.Starters = {"EmberDrake","AquaSerpent","LeafGriffin","SparkKitsune","PebbleGolem"}

-- =====================================================================
-- REALMS
-- =====================================================================
GameData.Realms = {
	EmberForest = {
		id="EmberForest",   label="Ember Forest",    reqLevel=1,
		desc="A magical forest glowing with fireflies and ancient trees.",
		beasts={"EmberDrake","AquaSerpent","LeafGriffin","SparkKitsune","PebbleGolem","MoonOwlbear","CrystalStag"},
		boss="InfernoTreant", mats={"FireStone","NatureStone"},
		portalColor=Color3.fromRGB(255,100,0), sky=Color3.fromRGB(255,180,100),
	},
	FrostPeaks = {
		id="FrostPeaks",    label="Frost Peaks",     reqLevel=10,
		desc="Snowy mountains, ice caves, and frozen lakes.",
		beasts={"FrostWyvern","SnowGriffin","IceGolem","SpiritUnicorn"},
		boss="GlacierWyvern", mats={"IceStone","ThunderStone"},
		portalColor=Color3.fromRGB(100,200,255), sky=Color3.fromRGB(200,220,255),
	},
	ShadowMarsh = {
		id="ShadowMarsh",   label="Shadow Marsh",    reqLevel=20,
		desc="A dark swamp filled with purple fog and cursed ruins.",
		beasts={"ShadowCerberus","VenomHydra","CursedCrow","Basilisk"},
		boss="CursedHydra", mats={"ShadowCore","AncientRune"},
		portalColor=Color3.fromRGB(150,0,200), sky=Color3.fromRGB(50,0,80),
	},
	SunspireDesert = {
		id="SunspireDesert",label="Sunspire Desert",  reqLevel=30,
		desc="A golden desert with ancient temples and solar magic.",
		beasts={"SolarPhoenix","SandManticore","RuneGolem","SunGriffin","SparkKitsune"},
		boss="SolarManticore", mats={"FireStone","EarthStone","AncientRune"},
		portalColor=Color3.fromRGB(255,200,0), sky=Color3.fromRGB(255,220,100),
	},
	AbyssOcean = {
		id="AbyssOcean",    label="Abyss Ocean",     reqLevel=40,
		desc="Underwater ruins with glowing coral and deep-sea monsters.",
		beasts={"AquaSerpent","TideWyrm","TidalSerpent","PearlAlicorn"},
		boss="DeepseaLeviathan", mats={"WaterStone","CelestialShard"},
		portalColor=Color3.fromRGB(0,150,255), sky=Color3.fromRGB(0,50,100),
	},
	CelestialIsles = {
		id="CelestialIsles",label="Celestial Isles",  reqLevel=60,
		desc="Floating islands in the sky filled with cosmic energy.",
		beasts={"CelestialDragon","GalaxyAlicorn","VoidPhoenix","TimeHydra"},
		boss="VoidCelestialDragon", mats={"CelestialShard","ShadowCore","AncientRune"},
		portalColor=Color3.fromRGB(200,100,255), sky=Color3.fromRGB(100,50,200),
	},
}
GameData.RealmOrder = {"EmberForest","FrostPeaks","ShadowMarsh","SunspireDesert","AbyssOcean","CelestialIsles"}

-- =====================================================================
-- BOSSES
-- =====================================================================
GameData.Bosses = {
	InfernoTreant = {
		id="InfernoTreant",   label="Inferno Treant",       realm="EmberForest",
		element="Fire", hp=1000, atk=25, def=20,
		abilities={"Root Slam","Ember Rain","Forest Inferno"},
		rewards={ coins={200,500},  mats={"FireStone","NatureStone"}, beastChance=0.05, beasts={"SolarPhoenix","CrystalStag"} },
		respawn=600,
	},
	GlacierWyvern = {
		id="GlacierWyvern",   label="Glacier Wyvern",       realm="FrostPeaks",
		element="Ice", hp=2000, atk=40, def=35,
		abilities={"Ice Breath","Blizzard","Glacier Charge"},
		rewards={ coins={400,800},  mats={"IceStone","ThunderStone"},beastChance=0.05, beasts={"SpiritUnicorn"} },
		respawn=600,
	},
	CursedHydra = {
		id="CursedHydra",     label="Cursed Hydra",         realm="ShadowMarsh",
		element="Shadow", hp=3500, atk=55, def=30,
		abilities={"Venom Torrent","Head Regenerate","Curse Aura"},
		rewards={ coins={700,1200}, mats={"ShadowCore","AncientRune"}, beastChance=0.05, beasts={"Basilisk"} },
		respawn=600,
	},
	SolarManticore = {
		id="SolarManticore",  label="Solar Manticore",      realm="SunspireDesert",
		element="Fire", hp=5000, atk=70, def=45,
		abilities={"Solar Spine Volley","Desert Blaze","Solar Roar"},
		rewards={ coins={1000,2000},mats={"FireStone","EarthStone","AncientRune"}, beastChance=0.05, beasts={"SolarPhoenix","SunGriffin"} },
		respawn=600,
	},
	DeepseaLeviathan = {
		id="DeepseaLeviathan",label="Deepsea Leviathan",    realm="AbyssOcean",
		element="Water", hp=8000, atk=90, def=60,
		abilities={"Deep Surge","Abyss Vortex","Leviathan Roar"},
		rewards={ coins={2000,4000},mats={"WaterStone","CelestialShard"}, beastChance=0.05, beasts={"PearlAlicorn","AbyssLeviathan"} },
		respawn=600,
	},
	VoidCelestialDragon = {
		id="VoidCelestialDragon",label="Void Celestial Dragon",realm="CelestialIsles",
		element="Void", hp=15000, atk=130, def=100,
		abilities={"Reality Shatter","Void Breath","Cosmic Collapse"},
		rewards={ coins={5000,10000},mats={"CelestialShard","ShadowCore","AncientRune"}, beastChance=0.10, beasts={"TimeHydra","VoidPhoenix","CelestialDragon"} },
		respawn=1800,
	},
}

-- =====================================================================
-- QUESTS
-- =====================================================================
GameData.Quests = {
	FirstTame        = { id="FirstTame",        cat="Tutorial",    label="First Contact",      desc="Tame your first wild beast.",                                 obj={{type="Tame",count=1}},                              rewards={coins=100,  xp=50,  items={BasicCrystal=2}}       },
	Tame3EmberDrakes = { id="Tame3EmberDrakes", cat="Taming",      label="Drake Hunter",       desc="Tame 3 Ember Drakes.",                                        obj={{type="Tame",beastId="EmberDrake",count=3}},         rewards={coins=300,  xp=150, items={FireStone=3}}           },
	Defeat10Wild     = { id="Defeat10Wild",      cat="Battle",      label="Wild Fighter",       desc="Defeat 10 wild beasts in battle.",                            obj={{type="Battle",count=10}},                           rewards={coins=500,  xp=200, items={SilverCrystal=1}}       },
	EvolveStarter    = { id="EvolveStarter",     cat="Evolution",   label="Evolution!",         desc="Evolve your starter beast for the first time.",               obj={{type="Evolve",count=1}},                            rewards={coins=1000, xp=500, items={GoldenCrystal=1}}       },
	Collect5Fire     = { id="Collect5Fire",      cat="Collection",  label="Fire Collector",     desc="Collect 5 Fire Stones.",                                      obj={{type="Collect",item="FireStone",count=5}},          rewards={coins=200,  xp=100}                                },
	BossSlayer       = { id="BossSlayer",        cat="Boss",        label="Boss Slayer",        desc="Defeat any realm boss.",                                      obj={{type="Boss",count=1}},                              rewards={coins=2000, xp=1000,items={MythicCrystal=1}}       },
	TradeOnce        = { id="TradeOnce",         cat="Social",      label="First Trade",        desc="Successfully complete a trade with another player.",          obj={{type="Trade",count=1}},                             rewards={coins=500,  xp=250}                                },
	BloodlineHunter  = { id="BloodlineHunter",   cat="Bloodline",   label="Bloodline Hunter",   desc="Discover a beast with a Royal bloodline or rarer.",           obj={{type="Bloodline",minTier=2,count=1}},               rewards={coins=1000, xp=500, items={BloodlineCrystal=1}}    },
	ForestComplete   = { id="ForestComplete",    cat="Collection",  label="Forest Explorer",    desc="Tame every unique beast species in Ember Forest.",             obj={{type="TameAll",realm="EmberForest"}},               rewards={coins=2000, xp=800, title="ForestExplorer"}        },
	ReachLevel20     = { id="ReachLevel20",      cat="Progression", label="Rising Tamer",       desc="Reach player level 20.",                                      obj={{type="PlayerLevel",level=20}},                      rewards={coins=1000, xp=0,   items={SilverCrystal=3}}        },
	CollectSecret    = { id="CollectSecret",     cat="Bloodline",   label="Secret Bloodline",   desc="Own a beast with a Secret bloodline.",                        obj={{type="OwnBloodline",bloodline="Secret",count=1}},   rewards={coins=10000,xp=5000,title="MythicCollector"}       },
	Defeat5Bosses    = { id="Defeat5Bosses",     cat="Boss",        label="Realm Conqueror",    desc="Defeat 5 different realm bosses.",                            obj={{type="UniqueBoss",count=5}},                        rewards={coins=5000, xp=2000,title="BossSlayer"}            },
}

-- =====================================================================
-- TITLES
-- =====================================================================
GameData.Titles = {
	DragonTamer    = { id="DragonTamer",    label="Dragon Tamer"    },
	VoidHunter     = { id="VoidHunter",     label="Void Hunter"     },
	CelestialMaster= { id="CelestialMaster",label="Celestial Master"},
	BossSlayer     = { id="BossSlayer",     label="Boss Slayer"     },
	BloodlineHunter= { id="BloodlineHunter",label="Bloodline Hunter"},
	ForestExplorer = { id="ForestExplorer", label="Forest Explorer" },
	LegendaryTrader= { id="LegendaryTrader",label="Legendary Trader"},
	MythicCollector= { id="MythicCollector",label="Mythic Collector"},
}

-- =====================================================================
-- RARITY METADATA
-- =====================================================================
GameData.RarityOrder = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"}
GameData.RarityColors = {
	Common   = Color3.fromRGB(180,180,180),
	Uncommon = Color3.fromRGB(0,200,50),
	Rare     = Color3.fromRGB(60,120,255),
	Epic     = Color3.fromRGB(160,0,255),
	Legendary= Color3.fromRGB(255,165,0),
	Mythic   = Color3.fromRGB(255,0,100),
	Secret   = Color3.fromRGB(255,255,80),
}
function GameData.RarityIndex(r)
	for i,v in ipairs(GameData.RarityOrder) do if v==r then return i end end
	return 1
end

-- =====================================================================
-- XP CURVES
-- =====================================================================
function GameData.BeastXPForLevel(level)
	return math.floor(100 * (level ^ 1.5))
end
function GameData.PlayerXPForLevel(level)
	return math.floor(200 * (level ^ 1.6))
end

-- =====================================================================
-- DEFAULT PLAYER DATA TEMPLATE
-- =====================================================================
GameData.DefaultData = {
	level=1, xp=0, coins=100,
	beasts={},           -- array of beast save objects
	party={},            -- up to 3 beast UUIDs
	inventory={ BasicCrystal=3 },
	quests={ active={"FirstTame","BloodlineHunter"}, completed={} },
	realms={ unlocked={"EmberForest"} },
	starterPicked=false,
	titles={ owned={}, active=nil },
	stats={ tamed=0, wins=0, losses=0, bosses={}, trades=0, evolutions=0, bloodlines={} },
	settings={ music=0.5, sfx=0.8 },
	loginStreak=0, lastLogin=0, dailyClaimed=false,
}

return GameData
