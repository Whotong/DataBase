-- Steal an Egg game data — captured 2026-08-25 (PlaceId 107778070777162, GameId 10563114921)
-- Canonical NETWORK_MAP endpoints, decompiled from
-- ReplicatedStorage.Library.Globals.Constants._Index.NETWORK_MAP.Endpoints.*
-- Prefer the client Cmds modules (Library.Client.*) over raw remotes where one exists.
-- STATIC SNAPSHOT: game updates can stale this.

return {
	-- Primary integration: require("ReplicatedStorage.Library.Client.EggCmds")
	-- (RequestCarryAreaEgg/RequestAreaEggSnapshot/RequestHatchEgg/... wrap these)
	Eggs = {
		REQUEST_EGG_RECORD = "Eggs: RequestEggRecord",
		REQUEST_RUNTIME_SNAPSHOT = "Eggs: RequestRuntimeSnapshot",
		REQUEST_EQUIP_TOOL = "Eggs: RequestEquipTool",
		REQUEST_UNEQUIP_TOOL = "Eggs: RequestUnequipTool",
		REQUEST_PLACE_EGG = "Eggs: RequestPlaceEgg",
		REQUEST_SKIP_GROWTH = "Eggs: RequestSkipGrowth",
		REQUEST_HATCH_EGG = "Eggs: RequestHatchEgg",
		REQUEST_COMPLETE_HATCH_EGG = "Eggs: RequestCompleteHatchEgg",
		REQUEST_AREA_EGG_SNAPSHOT = "Eggs: RequestAreaEggSnapshot",
		REQUEST_AREA_EGG_RARE_SPAWN_PRESENTATIONS = "Eggs: RequestAreaEggRareSpawnPresentations",
		REQUEST_AREA_EGG_CARRY = "Eggs: RequestAreaEggCarry",
		REQUEST_AREA_EGG_DROP = "Eggs: RequestAreaEggDrop",
		RUNTIME_OWNER_UPDATED = "Eggs: RuntimeOwnerUpdated",
		RUNTIME_OWNER_CLEARED = "Eggs: RuntimeOwnerCleared",
		AREA_EGG_UPDATED = "Eggs: AreaEggUpdated",
		AREA_EGG_REMOVED = "Eggs: AreaEggRemoved",
		AREA_EGG_BATCH_UPDATED = "Eggs: AreaEggBatchUpdated",
		AREA_EGG_CARRY_STATE = "Eggs: AreaEggCarryState",
		AREA_EGG_CLAIM_FEEDBACK = "Eggs: AreaEggClaimFeedback",
		AREA_EGG_RESET_START_COUNTDOWN = "Eggs: AreaEggResetStartCountdown",
		AREA_EGG_RARE_SPAWNS_REVEALED = "Eggs: AreaEggRareSpawnsRevealed",
	},
	ActiveAssets = {
		REQUEST_RUNTIME_SNAPSHOT = "ActiveAssets: RequestRuntimeSnapshot",
		REQUEST_EQUIP = "ActiveAssets: RequestEquip",
		REQUEST_UNEQUIP = "ActiveAssets: RequestUnequip",
		REQUEST_EQUIP_LIMIT = "ActiveAssets: RequestEquipLimit",
		MONEY_UPDATED_EVENT = "ActiveAssets: MoneyUpdated",
		ITEM_UPDATED_EVENT = "ActiveAssets: ItemUpdated",
		MONEY_COLLECTED_EVENT = "ActiveAssets: MoneyCollected",
		REQUEST_SELL = "ActiveAssets: RequestSell",
		REQUEST_STEAL_TARGET = "ActiveAssets: RequestStealTarget", -- PRODUCT-GATED (DNA steal)
		STEAL_TARGET_EVENT = "ActiveAssets: StealTargetEvent",
		REQUEST_DNA_STEAL_ANIMATION_COMPLETE = "ActiveAssets: RequestDnaStealAnimationComplete",
	},
	AssetInventory = {
		SET_FAVORITE = "AssetInventory: SetFavorite",
		SELL_ASSET = "AssetInventory: SellAsset",
		SELL_ALL_ASSETS = "AssetInventory: SellAllAssets",
	},
	Backpack = {
		EQUIP_BEST = "Backpack: EquipBest",
		GET_EQUIP_BEST_STATUS = "Backpack: GetEquipBestStatus",
		GET_AUTO_SELL_STATE = "Backpack: GetAutoSellState",
		SET_AUTO_SELL_STATE = "Backpack: SetAutoSellState", -- arg: serialized auto-sell config map
		PROMPT_FULL_INVENTORY_SELL = "Backpack: PromptFullInventorySell",
	},
	Plots = {
		STATE_UPDATE_EVENT = "Plots: StateUpdate",
		REQUEST_STATE = "Plots: RequestState",
		ENABLE_BASE_HIGHLIGHT = "Plots: EnableBaseHighlight",
		DISABLE_BASE_HIGHLIGHT = "Plots: DisableBaseHighlight",
		REQUEST_PROXIMITY_PURCHASE = "Plots: RequestProximityPurchase",
		REQUEST_BASE_UPGRADE = "Plots: RequestBaseUpgrade", -- prefer BaseUpgradeClient.RequestCashUpgrade()
		ON_BASE_UPGRADED = "Plots: OnBaseUpgraded",
		REQUEST_LOBBY_TELEPORT = "Plots: RequestLobbyTeleport",
	},
	Treadmills = {
		REQUEST_EQUIP_STATIC = "Treadmills: RequestEquipStatic",
		REQUEST_UPGRADE = "Treadmills: RequestUpgrade", -- consumer args unverified
		REQUEST_UNEQUIP = "Treadmills: RequestUnequip",
		SPEED_GAIN_EVENT = "Treadmills: SpeedGain",
		REQUEST_GET_SLOW_TOGGLE_STATE = "Treadmills: RequestGetSlowToggleState",
		REQUEST_SET_SLOW_TOGGLE_ENABLED = "Treadmills: RequestSetSlowToggleEnabled",
	},
	Guards = {
		FOREST_DEPOSIT = "Guards: ForestDeposit",
		FOREST_HIT = "Guards: ForestHit",
		ENABLED_CHANGED = "Guards: EnabledChanged",
		REQUEST_ENABLED = "Guards: RequestEnabled",
		SPEED_HIT_OFFER = "Guards: SpeedHitOffer",
		SPEED_HIT_WARNING = "Guards: SpeedHitWarning",
		WAKE_UP = "Guards: WakeUp",
	},
	Index = {
		REQUEST_CLAIM = "Index: RequestClaim", -- arg: category string
		REQUEST_CLAIM_ALL = "Index: RequestClaimAll", -- no args
		REQUEST_CLAIM_LIMITED_EGG_REWARD = "Index: RequestClaimLimitedEggReward", -- no args
		REQUEST_EQUIP_AREA_BAT = "Index: RequestEquipAreaBat", -- arg: boolean
	},
	Bat = { ACTIVATE = "Bat:Activate" },
	ToolInput = { ACTIVATE = "ToolInput:Activate" },
	GroupReward = { CLAIM_REWARD = "GroupReward: ClaimReward" },
	FreeGifts = { REQUEST_CLAIM = "FreeGifts: RequestClaim", ON_REDEEMED = "FreeGifts: OnGiftRedeemed" },
	OfflineAssets = {
		GET_SUMMARY = "OfflineAssets: GetSummary",
		REQUEST_REDEEM = "OfflineAssets: Redeem",
		IS_STATE_PENDING = "OfflineAssets: IsStatePending",
		CLAIMED_EVENT = "OfflineAssets: Claimed",
	},
	Sakura = {
		REQUEST_INSERT_EGG = "Sakura: InsertEgg",
		REQUEST_REMOVE_EGG = "Sakura: RemoveEgg",
		REQUEST_DEPOSIT = "Sakura: Deposit",
		REQUEST_MUTATE = "Sakura: Mutate",
		REQUEST_RETURN_CRANE = "Sakura: ReturnCrane",
		REQUEST_COLLECT_CRYSTAL = "Sakura: CollectCrystal",
		REQUEST_HIT_TREE = "Sakura: HitTree",
		CRYSTALS_COLLECTED = "Sakura: CrystalsCollected",
	},
	FuseMachine = {
		INSERT_MOB = "FuseMachine: InsertMob",
		REMOVE_MOB = "FuseMachine: RemoveMob",
		START_FUSE = "FuseMachine: StartFuse",
		COMPLETE_REVEAL = "FuseMachine: CompleteReveal",
	},
	Trading = {
		REQUEST = "Server: Trading: Request",
		REJECT = "Server: Trading: Reject",
		DECLINE = "Server: Trading: Decline",
		SET_READY = "Server: Trading: Set Ready",
		SET_ITEM = "Server: Trading: Set Item",
		SET_CONFIRMED = "Server: Trading: Set Confirmed",
	},
	ClientCharacter = {
		SYNC = "ClientCharacter: Sync",
		UPDATE = "ClientCharacter: Update",
		READY = "ClientCharacter: Ready",
		CORRECTION_STARTED = "ClientCharacter: CorrectionStarted",
		REQUEST_CHARACTER_RESET = "ClientCharacter: RequestCharacterReset",
		CHECK_INVENTORY = "ClientCharacter: CheckInventory",
	},
	Analytics = {
		REPORT_AFK_STATE = "Analytics:ReportAfkState",
		REPORT_AFK_TELEPORT = "Analytics:ReportAfkTeleport",
		REQUEST_AFK_TELEPORT_FLUSH = "Analytics:RequestAfkTeleportFlush",
	},
	RuntimeSync = {
		HEARTBEAT = "RuntimeSync: Pulse",
		REPORT = "RuntimeSync: Status",
		CHALLENGE = "RuntimeSync: Sync",
	},
	Settings = { REQUEST_UPDATE = "Settings: Request Update", SETTING_CHANGED = "Setting Changed" },
	ServerLuck = { GET_STATE = "ServerLuck:GetState" },
	Experiments = { GET = "Experiments:Get", UPDATE = "Experiments:Update" },
	GearShop = { GET_SHOP = "GearShop:GetShop", REQUEST_PURCHASE = "GearShop:RequestPurchase", TOGGLE_AUTO_BUY = "GearShop:TOGGLE_AUTO_BUY" },
	GearInventory = { REQUEST_ADD = "GearInventory: RequestAdd", ADDED_EVENT = "GearInventory: Added", REMOVED_EVENT = "GearInventory: Removed" },
	Trails = {
		REQUEST_PURCHASE = "Trails: RequestPurchase",
		REQUEST_SELECT = "Trails: RequestSelect",
		REQUEST_UNEQUIP = "Trails: RequestUnequip",
		REQUEST_ACTIVE_SNAPSHOT = "Trails: RequestActiveSnapshot",
	},
	Rebirth = { REQUEST_REBIRTH = "Rebirth: RequestRebirth", REQUEST_REBIRTH_COMMIT = "Rebirth: RequestRebirthCommit" },
	Products = { REQUEST_PROMPT_PURCHASE = "Products: Request Prompt Purchase" },
	Notifications = { SHOW = "Notifications_Show" },
}
