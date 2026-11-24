local addonName, ns = ...
ns = ns or {}
ns.Title = "Five Finger Rebate"
ns.Repository = "https://github.com/plvsplvs/FiveFingerRebate"
local frame = CreateFrame("Frame")
local session
local clockStart
local pending, active, sent
local units = { "target", "mouseover", "focus" }
local junkboxes = {}

ns.GetSession = function() return session end

local function normalize(totals)
    totals = totals or { money = 0, items = {}, pockets = 0 }
    totals.direct = totals.direct or 0
    totals.junkboxMoney = totals.junkboxMoney or 0
    totals.legacyMoney = totals.legacyMoney or math.max(0, totals.money - totals.direct - totals.junkboxMoney)
    totals.vendorSales = totals.vendorSales or 0
    totals.auctionSales = totals.auctionSales or 0
    return totals
end

local function newSession()
    local value = normalize()
    value.started = time()
    value.elapsed = 0
    value.locations = {}
    return value
end

function ns.Elapsed()
    return (session.elapsed or 0) + (clockStart and math.max(0, GetTime() - clockStart) or 0)
end

local function saveClock()
    session.elapsed = ns.Elapsed()
    clockStart = GetTime()
end

function ns.Status(message)
    ns.status = message
    if ns.RefreshStatus then ns.RefreshStatus() end
end

local function say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. ns.Title .. ":|r " .. text)
end

local function moneyText(amount)
    local sign = amount < 0 and "-" or ""
    amount = math.abs(amount)
    return sign .. string.format("%dg %ds %dc", math.floor(amount / 10000), math.floor(amount / 100) % 100, amount % 100)
end

local function readable(value)
    return not issecretvalue or not issecretvalue(value)
end

local function trace(message)
    PocketChangeDB.diagnostics = PocketChangeDB.diagnostics or {}
    local entries = PocketChangeDB.diagnostics
    entries[#entries + 1] = message
    if #entries > 30 then table.remove(entries, 1) end
    if message:find("Skipped", 1, true) then ns.Status(message) end
end

local function scanJunkboxes()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if readable(id) and id == 16882 then
                local guid = C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(bag, slot))
                -- NOTE: Keep GUIDs after bag updates; auto-loot can remove the box first.
                if readable(guid) and guid then junkboxes[guid] = true end
            end
        end
    end
end

local function parseMoney(text)
    if not text then return nil end
    local total, found = 0, false
    for _, coin in ipairs({ { GOLD_AMOUNT, 10000 }, { SILVER_AMOUNT, 100 }, { COPPER_AMOUNT, 1 } }) do
        local pattern = coin[1]:gsub("%%d", "CAPTURE"):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
        pattern = pattern:gsub("CAPTURE", "(%%d+)")
        local amount = text:match(pattern)
        if amount then
            total = total + tonumber(amount) * coin[2]
            found = true
        end
    end
    return found and total or nil
end

local function targetGUID(name)
    for _, unit in ipairs(units) do
        local unitName, guid = UnitName(unit), UnitGUID(unit)
        if readable(name) and readable(unitName) and readable(guid) and guid and (not name or name == "" or unitName == name) then
            local dead = UnitIsDeadOrGhost(unit)
            if readable(dead) and not dead then return guid, unitName end
        end
    end
end

local function sourceMatches(slot, guid)
    local sources = { GetLootSourceInfo(slot) }
    if #sources == 0 then trace("Skipped slot: no loot source"); return false end
    for i = 1, #sources, 2 do
        local source = sources[i]
        if not readable(source) or type(source) ~= "string" then
            trace("Skipped slot: restricted loot source")
            return false
        end
        if guid and source ~= guid then trace("Skipped slot: different source"); return false end
        if not guid and not source:match("^Creature%-") then return false end
    end
    return true
end

local function lootSource(slot)
    if active.junkbox then return "junkbox", "Battered Junkbox" end
    local guid, _, anotherSource = GetLootSourceInfo(slot)
    if anotherSource ~= nil or not readable(guid) or type(guid) ~= "string" then return "unknown", "Source unknown" end
    local npcID = guid:match("^Creature%-[^%-]+%-[^%-]+%-[^%-]+%-[^%-]+%-(%d+)%-")
    if not npcID then return "unknown", "Source unknown" end
    local name = active.sourceName
    if not name then
        for _, unit in ipairs(units) do
            local unitGUID, unitName = UnitGUID(unit), UnitName(unit)
            if readable(unitGUID) and unitGUID == guid and readable(unitName) then name = unitName; break end
        end
    end
    if name and name ~= "" then PocketChangeDB.mobNames[npcID] = name end
    return "npc:" .. npcID, PocketChangeDB.mobNames[npcID] or ("NPC " .. npcID)
end

local function snapshot(slot)
    if active.cleared[slot] or not sourceMatches(slot, active.guid) then return end
    local _, name, quantity = GetLootSlotInfo(slot)
    local kind, link = GetLootSlotType(slot), GetLootSlotLink(slot)
    if not readable(name) or not readable(quantity) or not readable(link) then trace("Skipped slot: restricted loot details"); return end
    if kind == Enum.LootSlotType.Money then
        active.slots[slot] = { money = parseMoney(name) }
    elseif kind == Enum.LootSlotType.Item and link and quantity and quantity > 0 then
        local id = link:match("item:(%d+)")
        if id then
            local source, sourceName = lootSource(slot)
            active.slots[slot] = { id = id, link = link, count = quantity, source = source, sourceName = sourceName }
        end
    end
end

local function openLoot(fromItem)
    if IsFishingLoot() then pending, active = nil, nil; return end
    if not active or not active.junkbox then
        for slot = 1, GetNumLootItems() do
            local source = GetLootSourceInfo(slot)
            if readable(source) and source and junkboxes[source] then
                active = { guid = source, junkbox = true, confirmed = true,
                    slots = {}, cleared = {}, waiting = {}, money = 0, count = 0 }
                pending = nil
                trace("Battered Junkbox opened")
                break
            end
        end
    end
    if fromItem and not (active and active.junkbox) then pending, active = nil, nil; return end
    if active and active.closed then return end
    if not active then
        if not pending or GetTime() - pending.time > 2 then
            if pending then trace("Skipped loot: cast expired") end
            pending = nil
            return
        end
        for _, unit in ipairs(units) do
            local guid = UnitGUID(unit)
            local dead = UnitIsDeadOrGhost(unit)
            if pending.guid and readable(guid) and guid == pending.guid and readable(dead) and dead then
                pending = nil
                return
            end
        end
        active = { guid = pending.guid, sourceName = pending.sourceName, cast = pending.cast, time = pending.time,
            confirmed = pending.confirmed, slots = {}, cleared = {}, waiting = {}, money = 0, count = 0 }
        pending = nil
    end
    for slot = 1, GetNumLootItems() do snapshot(slot) end
end

local function collect(slot)
    if not active or active.cleared[slot] then return end
    if not active.confirmed then active.waiting[slot] = true; return end
    local loot = active.slots[slot]
    active.cleared[slot] = true
    if not loot then return end
    if not loot.money and not loot.id then
        trace("Skipped coins: unreadable amount")
        say("Could not read the coin amount; this coin slot was not counted.")
        return
    end
    for _, totals in ipairs({ PocketChangeDB, session }) do
        local newPocket = totals == session and active.sessionCounted ~= session or totals == PocketChangeDB and not active.counted
        if newPocket and not active.junkbox then totals.pockets = totals.pockets + 1 end
        if loot.money then
            totals.money = totals.money + loot.money
            local source = active.junkbox and "junkboxMoney" or "direct"
            totals[source] = totals[source] + loot.money
        else
            local item = totals.items[loot.id] or { link = loot.link, count = 0 }
            item.count = item.count + loot.count
            item.sources = item.sources or {}
            local source = item.sources[loot.source] or { count = 0, name = loot.sourceName }
            source.count = source.count + loot.count
            source.name = loot.sourceName
            item.sources[loot.source] = source
            totals.items[loot.id] = item
        end
    end
    active.counted = true
    active.sessionCounted = session
    if loot.id and ns.TrackItem then ns.TrackItem(loot.id, loot.count, loot.link) end
    local zone = GetRealZoneText()
    if readable(zone) and zone and zone ~= "" then session.locations[zone] = true end
    ns.Status(active.junkbox and "Tracking: junkbox loot counted" or "Tracking: pickpocket loot counted")
    trace(loot.money and ("Counted coins: " .. loot.money) or ("Counted items: " .. loot.count))
    active.money = active.money + (loot.money or 0)
    active.count = active.count + (loot.count or 0)
    if ns.Refresh then ns.Refresh() end
end

local function report(totals, label, includeItems)
    local count = 0
    for _, item in pairs(totals.items) do count = count + item.count end
    say(string.format("%s: %s, %d items, %d looted pockets.", label, moneyText(totals.money), count, totals.pockets))
    say("Direct: " .. moneyText(totals.direct) .. "; junkboxes: " .. moneyText(totals.junkboxMoney)
        .. "; vendor sales: " .. moneyText(totals.vendorSales) .. "; auction sales: " .. moneyText(totals.auctionSales))
    if totals.legacyMoney > 0 then say("Older unsplit coins: " .. moneyText(totals.legacyMoney)) end
    if includeItems then
        local ids = {}
        for id in pairs(totals.items) do ids[#ids + 1] = id end
        table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
        for _, id in ipairs(ids) do
            local item = totals.items[id]
            say(string.format("%dx %s", item.count, item.link))
        end
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        PocketChangeDB = normalize(PocketChangeDB)
        PocketChangeDB.history = PocketChangeDB.history or {}
        PocketChangeDB.mobNames = PocketChangeDB.mobNames or {}
        PocketChangeDB.session = PocketChangeDB.session or newSession()
        session = normalize(PocketChangeDB.session)
        session.locations = session.locations or {}
        clockStart = GetTime()
        ns.Status("Ready: waiting for Pick Pocket or a junkbox")
        say("Loaded. /ffr opens the tracker; /ffr report prepares a bug report.")
    elseif not PocketChangeDB then
        return
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unit, name, cast, spell = ...
        if unit == "player" and readable(spell) and spell == 921 then
            if not readable(cast) then trace("Skipped cast: restricted cast identifier"); return end
            local guid, sourceName = targetGUID(name)
            if not sourceName and readable(name) and name and name ~= "" then sourceName = name end
            sent = { cast = cast, guid = guid, sourceName = sourceName, time = GetTime() }
            pending, active = sent, nil
            trace(sent.guid and "Pick Pocket sent: target known" or "Pick Pocket sent: target unavailable")
            ns.Status("Tracking: waiting for pocket loot")
        elseif unit == "player" and not readable(spell) then
            trace("Skipped cast: spell identity restricted")
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, cast, spell = ...
        if unit == "player" and readable(spell) and spell == 921 then
            if not readable(cast) then trace("Skipped success: restricted cast identifier"); return end
            local guid, sourceName = targetGUID()
            if sent and sent.cast == cast then guid, sourceName = sent.guid, sent.sourceName end
            trace("Pick Pocket succeeded")
            if active and active.cast == cast and GetTime() - active.time <= 2 then
                active.confirmed = true
                for slot in pairs(active.waiting) do collect(slot) end
                if active.closed then active = nil end
                pending = nil
            else
                pending = { guid = guid, sourceName = sourceName, cast = cast, time = GetTime(), confirmed = true }
            end
            sent = nil
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, _, spell = ...
        if unit == "player" and readable(spell) and spell == 921 then
            pending, sent, active = nil, nil, nil
            trace("Pick Pocket failed or interrupted")
        end
    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        local _, fromItem = ...
        trace(event .. (pending and ": cast pending" or active and ": pocket active" or ": no recent cast"))
        openLoot(fromItem)
    elseif event == "LOOT_SLOT_CHANGED" then
        if active then snapshot(...) end
    elseif event == "LOOT_SLOT_CLEARED" then
        collect(...)
    elseif event == "LOOT_CLOSED" then
        if active and active.counted and not PocketChangeDB.quiet then
            say(string.format("+%s, %d items. Session: %s.", moneyText(active.money), active.count, moneyText(session.money)))
        end
        if active and not active.confirmed then
            active.closed = true
        else
            active = nil
        end
        pending = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        active, pending, sent = nil, nil, nil
        scanJunkboxes()
    elseif event == "BAG_UPDATE_DELAYED" then
        scanJunkboxes()
    elseif event == "PLAYER_LOGOUT" then
        saveClock()
    end
end)

for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "BAG_UPDATE_DELAYED", "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "LOOT_READY", "LOOT_OPENED", "LOOT_SLOT_CHANGED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED" }) do
    frame:RegisterEvent(event)
end

SLASH_POCKETCHANGE1 = "/pc"
SLASH_POCKETCHANGE2 = "/pocketchange"
SlashCmdList.POCKETCHANGE = function(input)
    local command = input:lower():match("^%s*(.-)%s*$")
    if command == "" then
        report(session, "Session", false)
        report(PocketChangeDB, "All time", false)
    elseif command == "items" then
        report(PocketChangeDB, "All time", true)
    elseif command == "session" then
        report(session, "Session", true)
    elseif command == "quiet" then
        PocketChangeDB.quiet = not PocketChangeDB.quiet
        say(PocketChangeDB.quiet and "Loot summaries off." or "Loot summaries on.")
    elseif command == "debug" then
        for _, message in ipairs(PocketChangeDB.diagnostics or {}) do say(message) end
        say("End of recent tracking diagnostics.")
    elseif command == "reset" then
        saveClock()
        session.finished = time()
        table.insert(PocketChangeDB.history, 1, session)
        if #PocketChangeDB.history > 20 then table.remove(PocketChangeDB.history) end
        session = newSession()
        PocketChangeDB.session = session
        clockStart = GetTime()
        say("Session reset. All-time totals kept.")
        if ns.OnReset then ns.OnReset() elseif ns.Refresh then ns.Refresh() end
    elseif command == "reset all confirm" then
        local quiet = PocketChangeDB.quiet
        PocketChangeDB = normalize()
        PocketChangeDB.quiet, PocketChangeDB.history = quiet, {}
        PocketChangeDB.mobNames = {}
        session = newSession()
        PocketChangeDB.session = session
        clockStart = GetTime()
        say("All totals reset.")
        if ns.OnReset then ns.OnReset() elseif ns.Refresh then ns.Refresh() end
    else
        say("/pc — totals; /pc items — stolen items; /pc session — session items; /pc quiet — toggle loot summaries; /pc reset — new session.")
        say("To erase all saved totals: /pc reset all confirm")
        say("/pc debug — recent tracking diagnostics")
    end
end
