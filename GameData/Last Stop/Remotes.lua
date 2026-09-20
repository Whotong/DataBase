-- Last Stop [Beta] game data — captured 2026-09-20 (PlaceId 122776220269735, GameId 10759337137)
-- Knit game: 133 remotes under ReplicatedStorage.ClientSource.Mutual.Packages.Knit.Services.*,
-- 49 Knit services, 53 client controllers. Decompile-verified 2026-09-20.
-- Prefer the game's own Knit services/components over raw remotes where one exists.
-- STATIC SNAPSHOT: game updates can stale this.

return {
	-- Primary integration: require("ReplicatedStorage.ClientSource.Mutual.Packages.Knit")
	-- Verified call chain (ItemController + LootController decompile):
	--   local Knit = require(RS.ClientSource.Mutual.Packages.Knit)
	--   Knit.GetService("ItemService"):EquipItem(itemInstance)
	-- FocusItem = LootController:GetFocusItem() = world Instance (userdata) from
	-- ITEM_CONTAINER. Both QuickEquip and Item_Interact paths call EquipItem
	-- with the single instance arg. Knit serializes Instance params natively.
	ItemService = {
		EQUIP_ITEM = "ItemService: EquipItem", -- arg: world item Instance (verified)
		TOGGLE_EQUIP = "ItemService: ToggleEquip", -- seen in RF map, args unverified
		DROP_ITEM = "ItemService: DropItem", -- seen in RF map, args unverified
		EAT = "ItemService: Eat", -- seen in RF map, args unverified
		STORE_ITEM = "ItemService: StoreItem", -- component path, args unverified
		UNSTORE_ITEM = "ItemService: UnstoreItem", -- component path, args unverified
	},
	-- Component methods (Knit.Components.*), called on component objects:
	--   Character:StoreItem(instance), HoldingSack:StoreItem(instance),
	--   Util.SafeCall(holding, "UnstoreItem"), Knit.Components.Item:FromInstance(inst),
	--   Knit.Components.Item:FromId(id), Knit.Components.Player:FromInstance(player)
	Components = {
		ITEM = "Knit.Components.Item", -- FromInstance(inst)/FromId(id)
		PLAYER = "Knit.Components.Player", -- FromInstance(player)
	},
	-- Read-only controller API (ItemController decompile, no remote fires):
	-- GetItemByName, GetItemsByType, GetItemByInstance, GetItemInstanceById,
	-- GetItemReplica/TryGetItemReplica, IsItemEquipable, IsItemStorable,
	-- IsFuelObject, GetHoldingItem/Fuel/Weapon/Backpack/Sack, GetSellableItems,
	-- GetQuickEquipAction, CanUnstoreFromBackpack/Sack, IsSackStorable
	Controllers = {
		ITEM = "Game.Controllers.ItemController", -- richest: 14KB, Equip/Store/Grab
		LOOT = "Game.Controllers.LootController", -- 11KB, interact->EquipItem path
		QUEST = "Game.Controllers.QuestController", -- 674b stub, delegates to service
		VEHICLE = "VehicleController", -- bus driving (unexamined)
	},
	InventoryService = {
		GET_ITEMS_BY_NAME = "InventoryService: GetItemsByName",
		GET_ITEMS_BY_TYPE = "InventoryService: GetItemsByType",
		HAS_SPACE = "InventoryService: HasInventorySpace",
		SWAP_BACKPACK = "InventoryService: SwapBackpackItems",
		TOGGLE_ARMOR = "InventoryService: ToggleArmor",
		TOGGLE_CARD = "InventoryService: ToggleCardSlot",
	},
	VaultService = {
		-- No VaultController among loaded modules; vault flow likely via
		-- ItemController store path + OpenVaultPrompt. All args <unverified>.
		PURCHASE_SLOT = "VaultService: PurchaseSlot",
		SELL_OFFER = "VaultService: SellOfferItem",
		STORE = "VaultService: StoreItem",
		SWAP = "VaultService: SwapItems",
		UNSTORE = "VaultService: UnstoreItem",
	},
	CraftService = {
		-- No CraftController among loaded modules. All args <unverified>.
		CRAFT = "CraftService: Craft",
		CLOSE_STATION = "CraftService: CloseStation",
		UNLOCK_RECIPE = "CraftService: UnlockRecipe",
		MARK_SEEN = "CraftService: MarkRecipesSeen",
	},
	ReviveService = {
		-- All args <unverified>.
		HEAL = "ReviveService: Heal",
		HEAL_ENTITY = "ReviveService: HealEntity",
		REVIVE_SELF = "ReviveService: ReviveSelf",
		REVIVE_OTHER = "ReviveService: ReviveOtherPlayer",
	},
	QuestService = {
		-- All args <unverified>.
		CLAIM = "QuestService: ClaimQuest",
		CANCEL = "QuestService: CancelQuest",
	},
	BadgesService = {
		CLAIM_REWARD = "BadgesService: ClaimReward", -- args <unverified>
		EQUIP = "BadgesService: EquipBadge",
		UNEQUIP = "BadgesService: UnequipBadge",
	},
	GameService = {
		RESET_TO_BUS = "GameService: ResetToBus", -- args <unverified>
		RETURN_LOBBY = "GameService: ReturnLobby", -- args <unverified>
		PLAY_AGAIN = "GameService: PlayAgain", -- args <unverified>
		GO_LOBBY = "GameService: GoLobby", -- args <unverified>
	},
}
