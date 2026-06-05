# Mythic Wilds 🐉

A Roblox beast-catching, training, evolving, battling, and trading game.

## Setup (Rojo)

1. Install [Rojo](https://rojo.space/) plugin in Roblox Studio and the CLI tool.
2. Run `rojo serve default.project.json` in this folder.
3. In Roblox Studio, connect the Rojo plugin to sync all scripts automatically.
4. Press **Play** to test.

## Project Structure

```
src/
├── Shared/          → ReplicatedStorage (shared by server + client)
│   ├── GameData.lua     All game constants: beasts, bloodlines, realms, quests
│   └── BeastUtils.lua   Beast stat calculation, XP, evolution utilities
│
├── Server/          → ServerScriptService
│   ├── init.server.lua  Entry point: wires all systems + RemoteEvents
│   ├── DataManager.lua  DataStore persistence (auto-save every 60s)
│   ├── BeastSystem.lua  Wild beast spawning and realm population
│   ├── TamingSystem.lua Taming crystal mechanics and bloodline upgrades
│   ├── BattleSystem.lua Turn-based battle engine (wild, boss, PvP-ready)
│   ├── EvolutionSystem.lua Evolution validation and execution
│   ├── TradeSystem.lua  Peer-to-peer trade with scam prevention timer
│   └── QuestSystem.lua  Quest event tracking and reward distribution
│
└── Client/          → StarterPlayerScripts
    ├── init.client.lua  RemoteEvent wiring, proximity battle detection
    └── UIManager.lua    All ScreenGui: HUD, starter select, battle screen,
                         taming UI, evolution cutscene, quest popups, trade UI
```

## Core Systems

### Beasts
- **5 starter chains** (Fire/Water/Nature/Lightning/Earth), each with 3 evolution stages
- **20+ wild species** across 6 realms
- **8 bloodlines** (Common → Secret) rolled on every spawn
- Stats scale with level and bloodline multipliers

### Bloodlines
| Bloodline | Weight | Trade Value | Special |
|-----------|--------|-------------|---------|
| Common    | 60%    | 1           | Balanced |
| Royal     | 20%    | 5           | Gold glow, team buff |
| Ancient   | 8%     | 15          | Slow XP, massive final stats |
| Cursed    | 6%     | 20          | +ATK, -DEF, dark glow |
| Celestial | 3%     | 50          | Star aura, healing ability |
| Primal    | 2%     | 40          | Larger size, +60% ATK |
| Void      | 0.8%   | 100         | Purple tendrils, dark magic |
| Secret    | 0.2%   | 500         | Rainbow aura, unique ultimate |

### Realms
| Realm | Req. Level | Beasts |
|-------|-----------|--------|
| Ember Forest | 1 | Ember Drake, Leaf Griffin, Moon Owlbear... |
| Frost Peaks | 10 | Frost Wyvern, Snow Griffin, Spirit Unicorn... |
| Shadow Marsh | 20 | Shadow Cerberus, Venom Hydra, Basilisk... |
| Sunspire Desert | 30 | Solar Phoenix, Sand Manticore, Sun Griffin... |
| Abyss Ocean | 40 | Tidal Serpent, Pearl Alicorn... |
| Celestial Isles | 60 | Celestial Dragon, Void Phoenix, Time Hydra... |

### Taming Crystals
- **Basic** (50 coins) — 40% base rate
- **Silver** (200) — 60%
- **Golden** (500) — 75%
- **Mythic** (2,000) — 90%
- **Bloodline** (5,000) — 80% + 15% bloodline upgrade chance

### Battle System
- Turn-based: Basic / Special (2-turn CD) / Ultimate (4-turn CD) / Flee
- Element advantage: 1.5× damage if super effective, 0.7× if resisted
- AI uses abilities intelligently (ultimate when player is low HP)
- XP and coin rewards on victory; bond XP earned each battle

### Evolution
Requires: level threshold + bond level + coins + realm materials.
Example: Ember Drake → Flame Wyvern at Lv.20, 500 coins, 3× Fire Stone, Bond 5.

### Trading
Safe peer-to-peer trade with proposal → accept/decline flow and 30-second timeout.

### Quests
10+ quests across Tutorial, Taming, Battle, Boss, Evolution, Social, and Bloodline categories.
Completing quests grants coins, XP, crystals, and player titles.

## Monetization Hooks (implement as GamePasses)
- Extra Beast Storage (+50 slots)
- VIP Sanctuary Area
- Faster Training (2×)
- Lucky Taming Boost (+15% luck)
- Double Coins / Double XP
- Auto Battle

## First 60 Seconds Flow
1. Player spawns → starter selection screen (5 beasts to choose from)
2. Receives 3 Basic Crystals
3. Enters Ember Forest → sees wild beasts
4. Walks near beast → proximity prompt appears (Battle / Tame)
5. Wins first battle → XP + coins
6. Quest "First Contact" completes → reward popup
7. Rare bloodline beast spotted → global announcement
8. Encouraged to evolve → evolution requirements shown
