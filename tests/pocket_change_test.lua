local handler, now, slots, dead = nil, 10, {}, false
local messages = {}
local bags = {}
NUM_BAG_SLOTS = 4
C_Container = {
    GetContainerNumSlots = function(bag) return #(bags[bag] or {}) end,
    GetContainerItemID = function(bag, slot) return bags[bag][slot].id end,
}
ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
C_Item = { GetItemGUID = function(location) return bags[location.bag][location.slot].guid end }
local guid = "Creature-0-1-2-3-4-5"
local link = "|cffaaaaaa|Hitem:123:0|h[Stolen trinket]|h|r"
Enum = { LootSlotType = { Item = 1, Money = 2 } }
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) messages[#messages + 1] = text end }
function CreateFrame()
    return { SetScript = function(_, _, callback) handler = callback end, RegisterEvent = function() end }
end
function GetTime() return now end
function time() return 1700000000 + now end
function GetRealZoneText() return "The Stockade" end
function UnitName() return "Bandit" end
function GetUnitName() return "Bandit" end
function UnitGUID() return guid end
function UnitIsDeadOrGhost() return dead end
function IsFishingLoot() return false end
function GetNumLootItems() return #slots end
function GetLootSlotInfo(i) return nil, slots[i].name, slots[i].quantity end
function GetLootSlotType(i) return slots[i].kind end
function GetLootSlotLink(i) return slots[i].link end
function GetLootSourceInfo(i) return slots[i].source or guid, 1 end
local function event(name, ...) handler(nil, name, ...) end
local function loadAddon()
    assert(loadfile("PocketChange/PocketChange.lua"))("PocketChange")
    event("ADDON_LOADED", "PocketChange")
end
local function cast()
    event("UNIT_SPELLCAST_SENT", "player", "Bandit", "cast", 921)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 921)
end
local function loot()
    slots = {
        { kind = 2, name = "1 Gold\n2 Silver\n3 Copper", quantity = 0 },
        { kind = 1, name = "Stolen trinket", quantity = 2, link = link },
    }
end
local function clear()
    event("LOOT_SLOT_CLEARED", 1)
    event("LOOT_SLOT_CLEARED", 2)
end
loadAddon()
loot()
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == 0, "ordinary loot excluded")
cast()
event("LOOT_READY")
event("LOOT_OPENED")
clear()
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == 10203 and PocketChangeDB.items["123"].count == 2 and PocketChangeDB.pockets == 1, "duplicate events counted once")
assert(PocketChangeDB.items["123"].sources["npc:4"].count == 2 and PocketChangeDB.items["123"].sources["npc:4"].name == "Bandit", "mob identity and quantity recorded once")
assert(PocketChangeDB.session.items["123"].sources["npc:4"].count == 2, "session source counts recorded separately")
cast()
event("LOOT_READY")
event("LOOT_SLOT_CLEARED", 1)
event("LOOT_CLOSED")
assert(PocketChangeDB.items["123"].count == 2, "uncollected items excluded")
local money = PocketChangeDB.money
cast()
now = now + 3
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == money, "expired cast excluded")
cast()
event("UNIT_SPELLCAST_FAILED", "player", "cast", 921)
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == money, "failed cast excluded")
cast()
dead = true
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
dead = false
assert(PocketChangeDB.money == money, "corpse loot excluded")
cast()
slots[1].source, slots[2].source = "another-creature", "another-creature"
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == money, "unrelated source excluded")
loot()
cast()
event("LOOT_OPENED", true, true)
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == money, "opened containers excluded")
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silber", "%d Kupfer"
slots[1].name = "4 Silber\n7 Kupfer"
cast()
event("LOOT_READY")
event("LOOT_SLOT_CLEARED", 1)
event("LOOT_CLOSED")
assert(PocketChangeDB.money == money + 407, "localized money parsed")
local previousSession = PocketChangeDB.session
now = now + 60
event("PLAYER_LOGOUT")
local savedElapsed = PocketChangeDB.session.elapsed
now = now + 3600
loadAddon()
assert(PocketChangeDB.money == money + 407, "reload preserves saved totals")
SlashCmdList.POCKETCHANGE("session")
assert(PocketChangeDB.session == previousSession and PocketChangeDB.session.money == money + 407, "reload preserves session")
assert(PocketChangeDB.session.elapsed == savedElapsed, "offline time is excluded")
SlashCmdList.POCKETCHANGE("items")
assert(messages[#messages]:find("2x " .. link, 1, true), "item report contains counted items")
SlashCmdList.POCKETCHANGE("reset")
assert(PocketChangeDB.money == money + 407, "session reset preserves saved totals")
assert(PocketChangeDB.history[1] == previousSession and PocketChangeDB.session.money == 0, "new session archives previous run")
assert(previousSession.locations["The Stockade"], "run records loot locations")
SlashCmdList.POCKETCHANGE("reset all")
assert(PocketChangeDB.money == money + 407, "all-time reset requires explicit command")
SlashCmdList.POCKETCHANGE("reset all confirm")
assert(PocketChangeDB.money == 0 and next(PocketChangeDB.items) == nil, "confirmed reset clears totals")
loot()
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
event("UNIT_SPELLCAST_SENT", "player", "Bandit", "early", 921)
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
event("UNIT_SPELLCAST_SUCCEEDED", "player", "early", 921)
assert(PocketChangeDB.money == 10203 and PocketChangeDB.items["123"].count == 2,
    "auto-loot arriving before cast success must be counted")
local hidden = {}
function issecretvalue(value) return value == hidden end
function UnitGUID() return hidden end
function UnitName() return hidden end
function UnitIsDeadOrGhost() return hidden end
cast()
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == 20406 and PocketChangeDB.items["123"].count == 4,
    "dungeon loot tracks when unit identity and dead state are restricted")
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == 20406, "ordinary dungeon loot excluded")
event("UNIT_SPELLCAST_SENT", "player", "Bandit", "failed", 921)
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
event("UNIT_SPELLCAST_FAILED", "player", "failed", 921)
assert(PocketChangeDB.money == 20406, "buffered loot discarded for failed casts")
cast()
slots[1].source, slots[2].source = "Item-123", "Item-123"
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == 20406, "container sources rejected with hidden target")
SlashCmdList.POCKETCHANGE("debug")
assert(#PocketChangeDB.diagnostics <= 30, "diagnostics stay bounded")
local beforeMoney, beforeItems, beforePockets = PocketChangeDB.money, PocketChangeDB.items["123"].count, PocketChangeDB.pockets
bags[0] = { { id = 16882, guid = "Item-junkbox" }, { id = 12345, guid = "Item-other" } }
event("PLAYER_ENTERING_WORLD")
loot()
slots[1].source, slots[2].source = "Item-junkbox", "Item-junkbox"
bags[0] = {}
event("BAG_UPDATE_DELAYED")
event("LOOT_READY")
event("LOOT_OPENED", true, true)
clear()
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == beforeMoney + 10203, "junkbox coins counted once despite early bag removal")
assert(PocketChangeDB.items["123"].count == beforeItems + 2, "junkbox items included")
assert(PocketChangeDB.pockets == beforePockets, "opening a junkbox does not add another pocket")
assert(PocketChangeDB.junkboxMoney == 10203 and PocketChangeDB.direct == beforeMoney, "coin sources remain separate")
slots[1].source, slots[2].source = "Item-other", "Item-other"
event("LOOT_READY")
event("LOOT_OPENED", true, true)
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.money == beforeMoney + 10203, "other bag containers excluded")
bags[0] = { { id = 16882, guid = "Item-second-junkbox" } }
event("BAG_UPDATE_DELAYED")
slots[1].source, slots[2].source = "Item-second-junkbox", "Item-second-junkbox"
event("LOOT_OPENED", false, true)
event("LOOT_SLOT_CLEARED", 1)
event("LOOT_CLOSED")
assert(PocketChangeDB.items["123"].count == beforeItems + 2, "uncollected junkbox items excluded")
event("LOOT_OPENED", false, true)
event("LOOT_SLOT_CLEARED", 2)
event("LOOT_CLOSED")
assert(PocketChangeDB.items["123"].count == beforeItems + 4, "remaining junkbox items count on reopening")
assert(PocketChangeDB.items["123"].sources.junkbox.count == 4, "junkbox contents have their own source")
assert(PocketChangeDB.items["123"].sources["npc:4"].count == beforeItems, "junkbox contents are not assigned to mobs")
loot()
slots[1].source, slots[2].source = "Creature-0-1-2-3-999-5", "Creature-0-1-2-3-999-5"
event("UNIT_SPELLCAST_SENT", "player", hidden, "anonymous", 921)
event("UNIT_SPELLCAST_SUCCEEDED", "player", "anonymous", 921)
event("LOOT_READY")
clear()
event("LOOT_CLOSED")
assert(PocketChangeDB.items["123"].sources["npc:999"].name == "NPC 999", "restricted mob names fall back to readable NPC ID")
event("PLAYER_LOGOUT")
loadAddon()
assert(PocketChangeDB.session.items["123"].sources["npc:999"].count == 2, "source counts survive reload")
PocketChangeDB = { money = 1234, pockets = 7, items = { ["123"] = { count = 3, link = link } } }
loadAddon()
assert(PocketChangeDB.legacyMoney == 1234 and PocketChangeDB.direct == 0 and PocketChangeDB.junkboxMoney == 0, "old earnings are not assigned invented sources")
assert(PocketChangeDB.items["123"].count == 3 and PocketChangeDB.pockets == 7, "migration preserves old items and pockets")
for _ = 1, 25 do SlashCmdList.POCKETCHANGE("reset") end
assert(#PocketChangeDB.history == 20, "run history stays bounded")
print("Pocket Change tracking and migration checks passed")
