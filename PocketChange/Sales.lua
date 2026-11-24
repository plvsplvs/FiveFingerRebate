local _, ns = ...
local frame = CreateFrame("Frame")
local merchant, mailbox, queued = false, false, false
local bagSnapshot, mailSnapshot, wallet, buybacks = {}, {}, 0, {}
local lastInbox = {}
local buybackIntent

local function plain(value)
    return not issecretvalue or not issecretvalue(value)
end
local function initialize()
    PocketChangeDB.stock = PocketChangeDB.stock or {}
    PocketChangeDB.stockLinks = PocketChangeDB.stockLinks or {}
    PocketChangeDB.vendorRefunds = PocketChangeDB.vendorRefunds or {}
end
function ns.TrackItem(id, quantity, link)
    initialize()
    PocketChangeDB.stock[id] = (PocketChangeDB.stock[id] or 0) + quantity
    PocketChangeDB.stockLinks[id] = link
end
local function bagCounts()
    local counts = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and plain(info.itemID) and plain(info.stackCount) then
                local id = tostring(info.itemID)
                counts[id] = (counts[id] or 0) + info.stackCount
            end
        end
    end
    return counts
end
local function readBuybacks()
    local result = {}
    for i = 1, GetNumBuybackItems() do
        local link = GetBuybackItemLink(i)
        local _, _, price, quantity = GetBuybackItemInfo(i)
        local id = link and link:match("item:(%d+)")
        if id and price and quantity then result[i] = { id = id, price = price, quantity = quantity } end
    end
    return result
end
local function credit(id, quantity, amount, field)
    local stock = PocketChangeDB.stock
    local tracked = math.min(quantity, stock[id] or 0)
    if tracked <= 0 then return 0 end
    local value = math.floor(amount * tracked / quantity)
    stock[id] = stock[id] - tracked
    PocketChangeDB[field] = PocketChangeDB[field] + value
    local session = ns.GetSession()
    session[field] = session[field] + value
    if field == "vendorSales" then
        local refunds = PocketChangeDB.vendorRefunds
        refunds[id] = refunds[id] or { quantity = 0, value = 0 }
        refunds[id].quantity = refunds[id].quantity + tracked
        refunds[id].value = refunds[id].value + value
    end
    ns.Status(field == "vendorSales" and "Tracking: vendor proceeds recorded" or "Tracking: auction proceeds collected")
    return tracked
end

local function reconcileVendor()
    local current, cash = bagCounts(), GetMoney()
    local gain = cash - wallet
    if gain == 0 then
        for id, count in pairs(bagSnapshot) do
            -- NOTE: Bag updates can arrive before the server's money update.
            if count > (current[id] or 0) then return end
        end
    end
    if gain > 0 then
        local candidates, expected = {}, 0
        for id, count in pairs(bagSnapshot) do
            local removed = count - (current[id] or 0)
            if removed > 0 then
                local price = select(11, C_Item.GetItemInfo(tonumber(id)))
                if price and price > 0 then
                    candidates[#candidates + 1] = { id = id, count = removed, value = removed * price }
                    expected = expected + removed * price
                elseif price == nil and (PocketChangeDB.stock[id] or 0) > 0 then
                    ns.Status("Sale not attributed: vendor price unavailable")
                end
            end
        end
        if expected > 0 and expected <= gain then
            for _, sale in ipairs(candidates) do credit(sale.id, sale.count, sale.value, "vendorSales") end
        elseif expected > gain then
            ns.Status("Sale not attributed: bag changes and coins did not match")
        end
    elseif gain < 0 and buybackIntent then
        local item = buybackIntent
        local refunds = PocketChangeDB.vendorRefunds[item.id]
        if refunds and cash - wallet <= -item.price and (current[item.id] or 0) - (bagSnapshot[item.id] or 0) >= item.quantity then
            local quantity = math.min(item.quantity, refunds.quantity)
            local value = math.min(refunds.value, math.floor(item.price * quantity / item.quantity))
            refunds.quantity, refunds.value = refunds.quantity - quantity, refunds.value - value
            PocketChangeDB.vendorSales = PocketChangeDB.vendorSales - value
            ns.GetSession().vendorSales = ns.GetSession().vendorSales - value
            PocketChangeDB.stock[item.id] = (PocketChangeDB.stock[item.id] or 0) + quantity
            ns.Status("Tracking: vendor buyback deducted")
        end
    end
    buybackIntent = nil
    bagSnapshot, wallet, buybacks = current, cash, readBuybacks()
end

local function saleMail()
    local result = {}
    for i = 1, GetInboxNumItems() do
        local _, _, _, subject, money = GetInboxHeaderInfo(i)
        local kind, name, _, bid, buyout, deposit, cut, _, _, _, quantity = GetInboxInvoiceInfo(i)
        if kind == "seller" and money and money > 0 and name and quantity and quantity > 0 then
            local key = table.concat({ name, subject or "", bid or 0, buyout or 0, deposit or 0, cut or 0, quantity, money }, "\031")
            local entry = result[key] or { name = name, quantity = quantity, money = money,
                proceeds = math.max(0, money - (deposit or 0)), copies = 0 }
            entry.copies = entry.copies + 1
            result[key] = entry
        end
    end
    return result
end
local function idForName(name)
    local match
    for id, link in pairs(PocketChangeDB.stockLinks) do
        local itemName = C_Item.GetItemInfo(link) or link:match("%[(.-)%]")
        if itemName == name and (PocketChangeDB.stock[id] or 0) > 0 then
            if match then return nil end
            match = id
        end
    end
    return match
end
local function reconcileMail(snapshot)
    local current, cash = snapshot or saleMail(), GetMoney()
    local removed, expected = {}, 0
    for key, entry in pairs(mailSnapshot) do
        local count = entry.copies - (current[key] and current[key].copies or 0)
        if count > 0 then
            removed[#removed + 1] = { entry = entry, count = count }
            expected = expected + entry.money * count
        end
    end
    if expected > 0 and cash - wallet >= expected then
        for _, record in ipairs(removed) do
            local entry = record.entry
            local id = idForName(entry.name)
            if id then
                credit(id, entry.quantity * record.count, entry.proceeds * record.count, "auctionSales")
            else
                ns.Status("Auction collected: no matching tracked stolen quantity")
            end
        end
    elseif expected > 0 then
        ns.Status("Auction not attributed: payout was not confirmed")
        return
    end
    mailSnapshot, wallet = current, cash
end
local function schedule()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function()
        queued = false
        if not PocketChangeDB then return end
        if merchant then reconcileVendor() end
        if mailbox then reconcileMail() end
        if ns.Refresh then ns.Refresh() end
    end)
end

frame:SetScript("OnEvent", function(_, event)
    if not PocketChangeDB or not ns.GetSession() then return end
    initialize()
    if event == "MERCHANT_SHOW" then
        merchant = true
        bagSnapshot, wallet, buybacks = bagCounts(), GetMoney(), readBuybacks()
    elseif event == "MERCHANT_CLOSED" then
        reconcileVendor()
        merchant = false
    elseif event == "MAIL_SHOW" then
        mailbox = true
        mailSnapshot, wallet = saleMail(), GetMoney()
        lastInbox = mailSnapshot
    elseif event == "MAIL_CLOSED" then
        -- NOTE: Inbox APIs may already be empty at MAIL_CLOSED; never infer payouts here.
        if mailbox then reconcileMail(lastInbox) end
        mailbox = false
    elseif event == "MAIL_INBOX_UPDATE" and mailbox then
        lastInbox = saleMail()
        schedule()
    elseif merchant or mailbox then
        schedule()
    end
end)
for _, event in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "MAIL_SHOW", "MAIL_CLOSED", "MAIL_INBOX_UPDATE" }) do frame:RegisterEvent(event) end
hooksecurefunc("BuybackItem", function(index)
    if merchant then buybackIntent = buybacks[index]; schedule() end
end)
