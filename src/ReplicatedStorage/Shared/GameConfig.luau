--!strict
-- Core Server & Gameplay Constants for STEAL THE IMPOSSIBLE

local GameConfig = {
    GAME_TITLE = "STEAL THE IMPOSSIBLE",
    GAME_VERSION = "1.0.0",

    -- Server Capacity (8 players, 8 bases)
    MAX_PLAYERS = 8,

    -- Base & World Geometry
    NORMAL_GRAVITY = 196.2,
    ZERO_G_GRAVITY = 42.0,
    PLAZA_RADIUS = 72,
    BASE_RING_RADIUS = 148,
    BIOME_RING_RADIUS = 325,
    VAULT_POSITION = Vector3.new(0, 6, -340),
    RIFT_ARENA_POSITION = Vector3.new(0, 115, 0),

    -- Core Carry & Steal Tuning
    DEFAULT_WALKSPEED = 18,
    DEFAULT_JUMP_POWER = 52,
    STEAL_REACH_STUDS = 10.5,
    TACKLE_COOLDOWN = 3.2,
    TACKLE_LUNGE_SPEED = 58,
    STEAL_IMMUNITY_DURATION = 1.6, -- prevents instant ping-pong back-steal
    STUN_DURATION_ON_STOLEN = 0.85,
    WORLD_DROP_DESPAWN_SECONDS = 50,
    PICKUP_COOLDOWN = 0.75,
    MAX_WORLD_ITEMS_PER_BIOME = 6,
    MAX_RIFT_ITEMS = 8,
    SPAWN_TICK_SECONDS = 4.5,

    -- Retention Schedulers (in seconds)
    SPECIAL_ZONE_INTERVAL_SECONDS = 15 * 60, -- Every 15 minutes
    SPECIAL_ZONE_DURATION_SECONDS = 5 * 60, -- Active for 5 minutes
    WORLD_ENDING_INTERVAL_SECONDS = 30 * 60, -- Every 30 minutes
    WORLD_ENDING_DURATION_SECONDS = 90, -- 90 seconds of pure apocalypse

    -- Economy & Progression
    STARTING_CASH = 250,
    PASSIVE_INCOME_INTERVAL = 1.0,
    STEAL_THIEF_CASH_BONUS = 0.15, -- 15% of item base value on steal
    BASE_LIKE_REWARD_CASH = 75,
    MAX_VAULT_INVENTORY = 120,

    -- Co-op Big Heist Settings
    HEIST_MIN_PLAYERS = 2,
    HEIST_MAX_PLAYERS = 4,
    HEIST_COOLDOWN_SECONDS = 180,
    HEIST_ESCAPE_BONUS_MULTIPLIER = 1.6,

    -- Persistence & Leaderboards
    DATASTORE_NAME = "StealTheImpossible_Prod_v1",
    ORDERED_WEALTH_DS = "STI_Leaderboard_NetWorth_v1",
    ORDERED_STEALS_DS = "STI_Leaderboard_Steals_v1",
    ORDERED_SECRETS_DS = "STI_Leaderboard_Secrets_v1",
    MESSAGING_SECRET_TOPIC = "STI_GlobalSecretFound_v1",
    AUTOSAVE_INTERVAL_SECONDS = 90,
    LEADERBOARD_REFRESH_SECONDS = 60,

    -- Studio / Admin Test Access (Add Creator Roblox UserIds here)
    CREATOR_USER_IDS = {} :: { number },
}

return table.freeze(GameConfig)
