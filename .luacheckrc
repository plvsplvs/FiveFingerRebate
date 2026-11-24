std = "lua51"
max_line_length = false
read_globals = {
    "CreateFrame", "UIParent", "Minimap", "GameTooltip", "ChatFontNormal", "UISpecialFrames",
    "C_Item", "C_Container", "C_CurrencyInfo", "C_AddOns", "C_Timer", "ItemLocation", "Enum",
    "GetTime", "time", "date", "tinsert", "GetBuildInfo", "GetLocale", "GetRealZoneText",
    "UnitGUID", "UnitName", "UnitIsDeadOrGhost", "issecretvalue", "GetLootSourceInfo",
    "GetLootSlotInfo", "GetLootSlotType", "GetLootSlotLink", "GetNumLootItems", "IsFishingLoot",
    "GOLD_AMOUNT", "SILVER_AMOUNT", "COPPER_AMOUNT", "NUM_BAG_SLOTS", "DEFAULT_CHAT_FRAME",
    "GetMoney", "GetNumBuybackItems", "GetBuybackItemLink", "GetBuybackItemInfo",
    "GetInboxNumItems", "GetInboxHeaderInfo", "GetInboxInvoiceInfo", "hooksecurefunc",
    "HandleModifiedItemClick",
}
globals = {
    "PocketChangeDB", "SlashCmdList", "SLASH_POCKETCHANGE1", "SLASH_POCKETCHANGE2",
    "SLASH_POCKETCHANGEUI1", "SLASH_FIVEFINGERREBATE1", "SLASH_FIVEFINGERREBATE2",
}
files["tests/**"] = { ignore = { "111", "112", "113", "121", "122", "142", "143" } }
