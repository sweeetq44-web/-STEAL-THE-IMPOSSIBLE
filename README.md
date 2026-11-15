# 🎮 STEAL THE IMPOSSIBLE (Roblox)

Production-grade **Roblox Luau (`--!strict`)** project for **STEAL THE IMPOSSIBLE** — an 8-player competitive steal-and-extract heist game built around rare mutated relic chases, base shields & high-stakes safe raids, atomic P2P trading, rebirth ascension, squad vault raids, global events, and ethical cosmetic monetization.

---

## ✨ Implemented Features

### Core Gameplay & World Architecture
- **8-Player Competitive Servers & 8 Personal Bases (`BaseService`)**
  - Up to 8 players claim individual bases with **Base Laser Shields**, glowing extraction pads, **Raidable Vault Safes**, passive income/sec, and Tier 1 → Tier 5 expansion (`4` up to `24` display pedestals).
  - **Opt-In High-Stakes 2x Mode**: Toggle **2x Passive Income** inside your base — Safe Cash accumulates in your Vault Safe, and rivals can raid `35%` of uncollected safe cash whenever your Laser Shield drops (while your `0.01%` Secrets stay 100% protected!).
- **Addictive Carry → Chase → Steal → Extract Loop (`CarryStealService` + Live Compass)**
  - Picking up rare loot attaches a 3D carried model, tier-scaled walkspeed encumbrance, a **live Base Waypoint Compass** (`studs` distance HUD), and a towering sky beacon so rivals hunt you down.
  - Chasers tackle/steal (`E`, mobile touch button, or gamepad `X`) with server-authoritative reach validation, cooldowns, steal-immunity protection, and base shield safety.
- **Signature "Impossible" Items & Procedural 3D Models (`ItemVisualBuilder`)**
  - 🧊 **Frozen Sun** (Frost Citadel): Blazing solar core locked inside icy crystal spikes.
  - 🐉 **Mini Apocalypse** (Abyssal Caldera): Winged mini dragon radiating fiery embers.
  - ⏳ **Time Eater** (Chronos Ruins): Antique timepiece with reverse-spinning clock hands.
  - 👁️ **The Last Eye** (Watchers' Sanctum): Eldritch iris and pupil that actively turns and stares at nearby players in real time.
  - 🌌 **Galaxy Egg** (Astral Void): Orbiting cosmic rings; flex it on a pedestal OR hatch it into random Galaxy Creatures (*Nebula Fox*, *Starlight Owl*, *Quasar Wyrm*, *Supernova Griffin*, *Void Celestial Leviathan*).
- **Richer 3D Landmarks & Map JumpPads (`WorldBuilder`)**
  - Each biome features custom 3D landmarks (Ice Spires, Magma Crater Pool, Giant Chronos Ring, Giant Tracking Watcher Tower, Floating Astral Island), **JumpPads** launching carriers back toward the Plaza, and Plaza **Merchant / Code / Rebirth** interactive kiosks (`ProximityPrompt`).

### Deep Progression & Social Systems (v2)
- **Item Mutations (`MutationConfig`)**: Every spawn/crate/heist item can roll `Normal` (1.0x), `Shiny` (1.75x), `Frostbitten` (2.25x), `Glitch` (3.0x), `VoidTouched` (4.0x), or `Celestial` (7.5x) with 3D `MutationRing` & aura visuals.
- **Daily Quests, Promo Codes & Black-Market Merchant (`QuestCodeService` + `QuestCodeController`)**
  - Daily UTC-resetting quests (`Extract 5`, `Steal 2`, `Like 2 Bases`, `1 Co-op Heist`).
  - Redeemable Promo Codes (`IMPOSSIBLE`, `FROZENSUN`, `SECRET001`, `HEISTCREW`, `WORLDENDING`, `TRLAUNCH2026`).
  - Black-Market Merchant selling **2x Luck Elixir**, **Featherweight Charm** (zero carry slowdown), **Shadow Cloak** (hides Sky Beacon while sneaking relics home), and **Mystery Crate** (Rare+ up to `0.01%` Secret).
- **Rebirth / Ascension Prestige & Biome Mastery (`DataService`)**
  - Rebirth resets Cash & Base Tier while **preserving all `0.01%` Secrets, Codex discoveries, Cosmetics, and Rebirths**, granting permanent **`+50%` Income** & **`+10%` Luck** per Rebirth.
  - Completing all core items of any Biome awards permanent **`+20%` Mastery Cash Bonus** per mastered biome.
- **Atomic Player-to-Player Safe Trading (`TradeService` + `TradeController`)**
  - Server-validated Vault item + Cash swaps with anti-scam protection (any offer modification resets both players' Confirm locks).

### 3 Global Growth Features + Retention Loops
1. **🌍 THE WORLD IS ENDING (`WorldEventService`)**: Every 30 minutes, triggers `MeteorShower`, `GiantMonster` (*Titan of the End*), or `GravityLoss` (`Workspace.Gravity = 42`).
2. **✨ SECRET COLLECTION (`SecretService`)**: Exact **`0.01%`** secret drops with cross-server `MessagingService` **Global Announcements** displaying the finder's name across every active server + Secret Codex tracker.
3. **🏛️ FLEX YOUR BASE (`BaseService` + `FlexVisitController`)**: Browse all 8 players' bases, check High-Stakes Safe & Shield statuses, teleport to visit galleries, inspect trophies, and like bases.
4. **15-Min Rotating Special Rift**, **Co-op Big Heist Vault**, **Weekly Drops**, **Global Leaderboards**, **Ethical Robux Cosmetics** (`99` / `149` / `49` / `199` / `79` / `299 R$`), and **EN / TR Localization**.

---

## 🚀 Opening & Running in Roblox Studio

### Option A — Instant Open (No Rojo Needed)
1. Double-click **`StealTheImpossible.rbxlx`** in **Roblox Studio**.
2. Press **F5 (Play)** or **Test → Start Local Server (2–8 Players)**.
3. In Studio playtest, use the built-in **STUDIO LIVE TEST** buttons (top-left) or chat commands:
   - `/test meteor` | `/test monster` | `/test gravity`
   - `/test rift` (opens the 15-min Special Rift)
   - `/test secret` (spawns a `0.01%` Secret item right in front of you)
   - `/test celestial` (spawns a `Celestial` 7.5x Frozen Sun right in front of you)
   - `/test cash 100000` | `/test rebirth`

### Option B — Rojo 7 Live Sync Workflow
```bash
rojo serve default.project.json
# or rebuild .rbxlx directly:
python3 tools/build_rbxlx.py
```

### Option C — Publish from Phone (No PC Needed)
See **[`docs/MOBILE_PUBLISH_GUIDE.md`](docs/MOBILE_PUBLISH_GUIDE.md)** to publish `StealTheImpossible.rbxlx` straight from your mobile browser using **GitHub Actions + Roblox Open Cloud** (`.github/workflows/publish-to-roblox.yml`).

---

## 🧪 Automated Luau Verification & Tests

Run the full Luau compiler verification (`47/47` `.luau` files) and end-to-end game logic test suite (`131/131` assertions across Tests 1–22) using the official Luau VM:
```bash
node tests/run_luau_tests.mjs
```

---

## 📁 Project Structure
- `default.project.json` — Rojo 7 place structure
- `StealTheImpossible.rbxlx` — Pre-built Roblox Studio place file (`tools/build_rbxlx.py`)
- `src/ReplicatedFirst/` — Loading screen
- `src/ReplicatedStorage/Shared/` — Configs (`MutationConfig`, `QuestAndCodeConfig`, `RarityConfig`, `ItemCatalog`, `WeeklyItems`, `CosmeticCatalog`, `Localization`, `Remotes`, `Utils`)
- `src/ServerScriptService/Server/Services/` — 17 server-authoritative services & procedural 3D world/item builders (`QuestCodeService`, `TradeService`, `BaseService`, `CarryStealService`, `DataService`, `WorldBuilder`, `ItemVisualBuilder`, etc.)
- `src/StarterPlayer/StarterPlayerScripts/Client/Controllers/` — 15 UI/FX controllers (`HUDController`, `BaseManagerController`, `QuestCodeController`, `TradeController`, `FlexVisitController`, `ShopCosmeticController`, `CodexIndexController`, `SquadHeistController`, `LeaderboardController`, etc.)
- `docs/GAME_DESIGN_AND_LIVEOPS.md` — Deep economy curves, publishing checklist & LiveOps guide
