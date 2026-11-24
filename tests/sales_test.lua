local handler, callback, buybackHook
local cash, bags, inbox, buybacks = 1000, {}, {}, {}
NUM_BAG_SLOTS = 0
function CreateFrame()
 return { RegisterEvent = function() end, SetScript = function(_, _, fn) handler = fn end }
end
function hooksecurefunc(name, fn) assert(name == 'BuybackItem'); buybackHook = fn end
C_Timer = { After = function(_, fn) callback = fn end }
function GetMoney() return cash end
C_Container = {
 GetContainerNumSlots = function() return #bags end,
 GetContainerItemInfo = function(_, slot) return bags[slot] end,
}
C_Item = { GetItemInfo = function(value)
 local id = type(value) == 'number' and value or tonumber(value:match('item:(%d+)'))
 if id == 123 then return 'Trinket', nil, nil, nil, nil, nil, nil, nil, nil, 111, 10 end
 if id == 124 then return 'Food', nil, nil, nil, nil, nil, nil, nil, nil, 222, 5 end
end }
function GetNumBuybackItems() return #buybacks end
function GetBuybackItemLink(i) return '|Hitem:' .. buybacks[i].id .. '|h[Trinket]|h' end
function GetBuybackItemInfo(i) local item = buybacks[i]; return 'Trinket', nil, item.price, item.quantity end
function GetInboxNumItems() return #inbox end
function GetInboxHeaderInfo(i) local mail = inbox[i]; return nil, nil, nil, 'Auction successful', mail.money end
function GetInboxInvoiceInfo(i)
 local mail = inbox[i]
 return mail.kind, mail.name, nil, mail.bid or 100, 100, mail.deposit or 0, 5, nil, nil, nil, mail.quantity
end
local function totals() return { vendorSales = 0, auctionSales = 0 } end
PocketChangeDB = totals()
local session = totals()
local status
local ns = { GetSession = function() return session end, Status = function(message) status = message end, Refresh = function() end }
assert(loadfile('PocketChange/Sales.lua'))('PocketChange', ns)
local function event(name) handler(nil, name) end
local function settle()
 if callback then local fn = callback; callback = nil; fn() end
end
local function stock(count) ns.TrackItem('123', count, '|Hitem:123|h[Trinket]|h') end
stock(3)
bags = { { itemID = 123, stackCount = 5 } }
event('MERCHANT_SHOW')
bags, cash = {}, cash + 50
buybacks = { { id = 123, quantity = 5, price = 50 } }
event('PLAYER_MONEY'); event('BAG_UPDATE_DELAYED'); settle()
assert(PocketChangeDB.vendorSales == 30 and session.vendorSales == 30, 'only recorded stolen quantities count')
assert(PocketChangeDB.stock['123'] == 0)
event('MERCHANT_UPDATE'); settle()
assert(PocketChangeDB.vendorSales == 30, 'duplicate vendor events do not recount')
buybackHook(1)
bags, cash = { { itemID = 123, stackCount = 5 } }, cash - 50
buybacks = {}
event('PLAYER_MONEY'); event('BAG_UPDATE_DELAYED'); settle()
assert(PocketChangeDB.vendorSales == 0 and PocketChangeDB.stock['123'] == 3, 'buyback restores provenance and reverses tracked proceeds')
bags, cash = {}, cash + 50
event('PLAYER_MONEY'); event('BAG_UPDATE_DELAYED'); settle()
assert(PocketChangeDB.vendorSales == 30, 'resale after buyback counts once net')
event('MERCHANT_CLOSED')
stock(2)
bags = { { itemID = 123, stackCount = 2 } }
event('MERCHANT_SHOW')
bags = {}
event('BAG_UPDATE_DELAYED'); settle()
assert(PocketChangeDB.vendorSales == 30, 'destroyed or transferred items without payment are not sales')
event('MERCHANT_CLOSED')
inbox = { { kind = 'seller', name = 'Trinket', money = 210, deposit = 10, quantity = 4 } }
event('MAIL_SHOW')
inbox, cash = {}, cash + 210
event('MAIL_INBOX_UPDATE'); event('PLAYER_MONEY'); settle()
assert(PocketChangeDB.auctionSales == 100, 'partial tracked quantity, auction fee already deducted, returned deposit excluded')
assert(PocketChangeDB.stock['123'] == 0)
event('MAIL_INBOX_UPDATE'); settle()
assert(PocketChangeDB.auctionSales == 100, 'duplicate mail events do not recount')
event('MAIL_CLOSED')
stock(4)
inbox = {
 { kind = 'seller', name = 'Trinket', money = 95, quantity = 1 },
 { kind = 'seller', name = 'Trinket', money = 95, quantity = 1 },
 { kind = 'buyer', name = 'Trinket', money = 50, quantity = 1 },
}
event('MAIL_SHOW')
inbox, cash = {}, cash + 240
event('MAIL_INBOX_UPDATE'); event('PLAYER_MONEY'); settle()
assert(PocketChangeDB.auctionSales == 290 and PocketChangeDB.stock['123'] == 2, 'identical sale mails aggregate; non-sale mail ignored')
event('MAIL_CLOSED')
inbox = { { kind = 'seller', name = 'Trinket', money = 95, quantity = 1 } }
event('MAIL_SHOW')
inbox = {}
event('MAIL_INBOX_UPDATE'); settle()
assert(PocketChangeDB.auctionSales == 290, 'mail disappearing without wallet payment is not counted')
assert(status:find('not confirmed', 1, true))
event('MAIL_CLOSED')
inbox = { { kind = 'seller', name = 'Food', money = 50, quantity = 1 } }
event('MAIL_SHOW')
inbox, cash = {}, cash + 50
event('MAIL_INBOX_UPDATE'); event('PLAYER_MONEY'); settle()
assert(PocketChangeDB.auctionSales == 290, 'ordinary auction sales excluded')
event('MAIL_CLOSED')
inbox = { { kind = 'seller', name = 'Trinket', money = 95, quantity = 1 } }
event('MAIL_SHOW')
inbox, cash = {}, cash + 95
event('MAIL_INBOX_UPDATE'); event('PLAYER_MONEY'); event('MAIL_CLOSED'); settle()
assert(PocketChangeDB.auctionSales == 385, 'closing the mailbox before the deferred refresh still records a confirmed payout')
stock(2)
bags = { { itemID = 123, stackCount = 2 } }
event('MERCHANT_SHOW')
bags = {}
event('BAG_UPDATE_DELAYED'); settle()
cash = cash + 20
event('PLAYER_MONEY'); settle()
assert(PocketChangeDB.vendorSales == 50, 'delayed wallet update still confirms vendor sale')
event('MERCHANT_CLOSED')
stock(1)
inbox = { { kind = 'seller', name = 'Trinket', money = 95, quantity = 1 } }
event('MAIL_SHOW')
inbox = {}
event('MAIL_INBOX_UPDATE'); settle()
cash = cash + 95
event('PLAYER_MONEY'); settle()
assert(PocketChangeDB.auctionSales == 480, 'delayed wallet update still confirms auction payout')
event('MAIL_CLOSED')
print('Vendor and auction sale checks passed')
