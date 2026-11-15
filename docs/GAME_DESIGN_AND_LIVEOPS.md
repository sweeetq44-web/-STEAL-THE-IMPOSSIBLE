# STEAL THE IMPOSSIBLE — Game Design, Economy & LiveOps Guide

## 1. Core Loop & Server Architecture
- **Server Capacity**: `8` players per server (`GameConfig.MAX_PLAYERS = 8`), each claiming one of the `8` personal bases arranged symmetrically around **The Nexus Hub**.
- **Core Loop**:
  1. Explore the **5 Permanent Biomes** (*Frost Citadel*, *Abyssal Caldera*, *Chronos Ruins*, *Watchers' Sanctum*, *Astral Void*), the **15-Minute Special Rift Dimension**, or team up for the **Co-op Big Heist Vault**.
  2. Grab rare/impossible relics — picking up an item attaches its 3D model, applies tier-scaled weight encumbrance, tracks distance via the **Live Base Waypoint Compass**, and lights up a sky beacon on Rare+ items (unless hidden by a **Shadow Cloak**).
  3. **Race back to your Base Deposit Pad** (or launch via Biome **JumpPads**) while rival players chase and tackle (`E` / Mobile Button / Gamepad `X`) to steal the item out of your hands!
  4. Deposit onto your Base Pad to lock the relic into your persistent Vault & Showcase Pedestals, earning extraction cash + continuous passive income/sec + Net Worth.

## 2. Signature "Impossible" Items & Special Mechanics
| Item | Biome | Special Behavior |
|---|---|---|
| 🧊 **Frozen Sun** | Frost Citadel | Blazing golden star core suspended inside crystalline frost spikes |
| 🐉 **Mini Apocalypse** | Abyssal Caldera | Floating winged dragon relic radiating ember aura |
| ⏳ **Time Eater** | Chronos Ruins | Fractured golden timepiece whose hands tick backwards (`ReverseClockHand`) |
| 👁️ **The Last Eye** | Watchers' Sanctum | Eldritch iris & pupil smoothly tracking nearby players in real time (`TrackingEyeIris`) |
| 🌌 **Galaxy Egg** | Astral Void | Orbiting twin-ring egg; can be flexed on pedestals OR hatched into random Galaxy Creatures (`2.25x`–`3.5x` income bonus!) |

## 3. Rarity & Mutation Probability Tables
### Rarity Table (`RarityConfig.luau`, sum = `100.00%`)
- **Common**: `52.00%` | **Uncommon**: `25.00%` | **Rare**: `13.00%` (Sky Beacon enabled)
- **Epic**: `6.50%` | **Mythic**: `2.60%` | **Impossible**: `0.89%`
- **Secret (`SECRET COLLECTION`)**: **`0.01%`** (`0.0001`) — triggers cross-server `MessagingService` Global Announcement with the finder's name!

### Item Mutation Table (`MutationConfig.luau`)
Every spawned/crate/heist relic rolls a Mutation (scaled by player Luck Elixir + Rebirth Luck):
- **Normal** (`84.75%`, `1.0x`) | **Shiny** (`8.00%`, `1.75x`) | **Frostbitten** (`4.00%`, `2.25x`)
- **Glitched** (`2.00%`, `3.0x`) | **Void-Touched** (`1.00%`, `4.0x`) | **Celestial** (`0.25%`, **`7.5x`**)

## 4. Progression Depth, Base Defense & Social Economy
- **Rebirth / Ascension (`QuestAndCodeConfig.luau`)**:
  - First Rebirth costs `$250,000` (`* 2.6^Rebirths`).
  - Resets Cash, Base Tier, and standard items while **keeping 100% of `0.01%` Secrets, Codex discoveries, Gadgets, Promo Codes, and Robux Cosmetics**.
  - Permanently grants **`+50%` Income/Cash** and **`+10%` Luck** per Rebirth.
- **Biome Mastery**: Discovering every core relic in a biome unlocks **`+20%` permanent Cash Bonus** per mastered biome (up to `+100%` across all 5 biomes).
- **Base Security Shield & High-Stakes 2x Safe (`BaseService.luau`)**:
  - Players get an automatic `60s` Laser Shield upon base claim/extraction (rechargeable on cooldown).
  - Players can opt into **High-Stakes 2x Mode**: passive income doubles (`2x`), routing into the base's **RaidSafe**. When a High-Stakes player's shield drops, rivals can raid **`35%`** of uncollected safe cash (never touching `0.01%` Secrets).
- **Daily Quests, Promo Codes & Black-Market Merchant**:
  - Daily UTC-resetting quests (`quest_extract_5`, `quest_steal_2`, `quest_like_2`, `quest_heist_1`).
  - Active Promo Codes: `IMPOSSIBLE`, `FROZENSUN`, `SECRET001`, `HEISTCREW`, `WORLDENDING`, `TRLAUNCH2026`.
  - Black-Market Merchant buffs: *2x Luck Elixir*, *Featherweight Charm*, *Shadow Beacon Cloak*, *Mystery Crate*.
- **Atomic P2P Safe Trading (`TradeService.luau`)**:
  - Trade Vault items & Cash safely; any offer modification resets both parties' Confirm flags to prevent bait-and-switch scams.

## 5. Retention Schedulers
- **15-Minute Special Zone (`SpecialZoneService`)**: Every `900s`, the Central Plaza Rift Portal opens for `300s`, rotating across *Glitch Matrix*, *Sunken Atlantis*, *Mirror Mirage*, and *Quantum Anomaly* with `2.5x–2.8x` boosted luck.
- **30-Minute Apocalypse (`WorldEventService` — "THE WORLD IS ENDING")**: Every `1800s`, triggers `90s` of map-wide chaos cycling between `MeteorShower`, `GiantMonster` (*Titan of the End*), and `GravityLoss` (`Workspace.Gravity = 42`).
- **Weekly Drops (`WeeklyItems.luau`)**: Update `ACTIVE_WEEK_ID`, `ACTIVE_WEEK_TITLE`, and `Items` table weekly; items automatically merge into `ItemCatalog` spawn pools and the Secret/Codex Index UI.

## 6. Ethical Cosmetic-First Monetization (`CosmeticCatalog.luau`)
Zero pay-to-win stats. All prices are defined in one table for easy A/B testing:
- **Custom Character Skins**: `99 Robux`
- **Custom Base Designs**: `149 Robux`
- **Custom Animations**: `49 Robux`
- **VIP Name Tag**: `199 Robux`
- **Custom Pet Appearances**: `79 Robux`
- **Extra Cosmetic Pack**: `299 Robux`

### Publishing Checklist on Roblox
1. Set Experience **Max Players** to `8` in Roblox Game Settings.
2. Enable **Allow HTTP Requests** and **Enable Studio Access to API Services** (for DataStoreService & OrderedDataStore testing).
3. Create the 6 GamePasses on the Roblox Creator Dashboard and paste their live IDs into `GamePassId` fields inside `src/ReplicatedStorage/Shared/CosmeticCatalog.luau`.
4. (Optional) Add your Creator Roblox UserId(s) to `GameConfig.CREATOR_USER_IDS` for live server `/test` diagnostics.
5. Custom 3D Studio Map Support: `WorldBuilder` automatically creates a playable 3D world if `Workspace.GameWorld` does not exist. To replace geometry with custom Studio meshes/builds, place your map inside `Workspace.GameWorld` and tag parts with `BaseDepositPad`, `BaseSecurityGate`, `FlexPedestal`, `BaseRaidSafe`, `JumpPad`, `PlazaKiosk`, `RiftReturnPad`, and `HeistLockPlate`.
