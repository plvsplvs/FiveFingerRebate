local widgets, frames, buttons = {}, {}, {}
local methods = {}
for _, name in ipairs({ 'SetSize', 'SetPoint', 'SetWidth', 'SetHeight', 'SetJustifyH', 'SetSpacing', 'SetClampedToScreen', 'SetMovable', 'EnableMouse', 'RegisterForDrag', 'StartMoving', 'StopMovingOrSizing', 'SetAutoFocus', 'SetMaxLetters', 'ClearFocus', 'SetScrollChild', 'SetVerticalScroll', 'SetFrameStrata', 'RegisterForClicks', 'SetHighlightTexture', 'SetOwner', 'AddLine', 'RegisterEvent', 'SetBackdrop', 'SetBackdropColor', 'SetBackdropBorderColor', 'SetTextColor', 'SetNormalFontObject', 'SetAllPoints', 'SetColorTexture', 'SetMultiLine', 'SetFontObject', 'SetFocus', 'HighlightText' }) do methods[name] = function() end end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:SetText(text) self.text = text; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
function methods:GetText() return self.text or '' end
function methods:IsShown() return self.shown ~= false end
function methods:Hide() self.shown = false end
function methods:Show() self:SetShown(true) end
function methods:SetShown(shown)
 local changed = self.shown ~= shown
 self.shown = shown
 if changed and shown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:SetTexture(value) self.texture = value end
function methods:GetStringHeight() local _, lines = (self.text or ''):gsub('\n', '\n'); return (lines + 1) * 14 end
function methods:SetHyperlink(value) self.link = value end
local function widget()
 return setmetatable({ scripts = {} }, { __index = methods })
end
function methods.CreateFontString(_) local w = widget(); widgets[#widgets+1] = w; return w end
function methods.CreateTexture(_) return widget() end
function CreateFrame(kind, name, parent, template)
 local w = widget()
 w.parent = parent
 if template == 'BasicFrameTemplateWithInset' then w.TitleText = widget() end
 if name then _G[name] = w end
 frames[#frames+1] = w
 if kind == 'Button' then buttons[#buttons+1] = w end
 return w
end
UIParent, Minimap, GameTooltip = widget(), widget(), widget()
UISpecialFrames = {}
tinsert, date = table.insert, os.date
local command
SlashCmdList = { POCKETCHANGE = function(input) command = input end }
function HandleModifiedItemClick(link) command = link end
local data = {
 [123] = { 'Apple', 10, 111 }, [124] = { 'Ruby', 100, 222 }, [16882] = { 'Battered Junkbox', 20, 333 },
}
local requests = 0
C_Item = {
 GetItemInfo = function(link)
  local id = type(link) == 'number' and link or tonumber(link:match('item:(%d+)'))
  local item = data[id]
  if item then return item[1], nil, nil, nil, nil, nil, nil, nil, nil, item[3], item[2] end
 end,
 RequestLoadItemDataByID = function() requests = requests + 1 end,
}
C_CurrencyInfo = { GetCoinTextureString = function(value) assert(value >= 0); return tostring(value) end }
local function totals()
 return { money = 123, pockets = 2, direct = 100, junkboxMoney = 23, vendorSales = 20, auctionSales = 30, legacyMoney = 0, items = {} }
end
PocketChangeDB = totals()
PocketChangeDB.history = {}
local session = totals()
local ns = { Title = 'Five Finger Rebate', Repository = 'https://github.com/plvsplvs/FiveFingerRebate', GetSession = function() return session end, Elapsed = function() return 120 end, status = 'Ready' }
assert(loadfile('PocketChange/Items.lua'))('PocketChange', ns)
assert(loadfile('PocketChange/UI.lua'))('PocketChange', ns)
function GetBuildInfo() return '1.60.1', '71037', 'date', 16001 end
function GetLocale() return 'enUS' end
C_AddOns = { GetAddOnMetadata = function() return '1.5.0-beta.2' end }
ChatFontNormal = 'ChatFontNormal'
assert(loadfile('PocketChange/Reports.lua'))('PocketChange', ns)
local function hasText(fragment)
 for _, text in ipairs(widgets) do if text.text and text.text:find(fragment, 1, true) then return true end end
 return false
end
local function click(text)
 for _, button in ipairs(buttons) do if button.text == text then button.scripts.OnClick(button); return end end
 error('Missing button: ' .. text)
end
assert(PocketChangeMinimapButton.parent == Minimap)
PocketChangeMinimapButton.scripts.OnClick(nil, 'LeftButton')
assert(PocketChangePanel:IsShown() and hasText('Current session · Earned: 173'))
assert(hasText('No items collected yet.') and hasText('5190/hr'))
session.items = {
 ['123'] = { count = 3, link = '|Hitem:123|h[Apple]|h', sources = { ['npc:4'] = { name = 'Bandit', count = 2 } } },
 ['124'] = { count = 1, link = '|Hitem:124|h[Ruby]|h' },
 ['16882'] = { count = 2, link = '|Hitem:16882|h[Battered Junkbox]|h' },
}
ns.Refresh()
local list, value = ns.ItemRows(session, '', 'value')
assert(value == 130 and list[1].id == '124', 'vendor value excludes containers and sorts descending')
assert(ns.ItemRows(session, '', 'quantity')[1].id == '123')
assert(#ns.ItemRows(session, 'APPLE', 'name') == 1)
assert(#ns.ItemRows(session, '124', 'name') == 1)
local filtered = ns.ItemRows(session, 'bandit', 'name')
assert(#filtered == 1 and filtered[1].id == '123', 'mob names are searchable')
assert(filtered[1].percent == 50, 'item percentage uses all item units, not search results')
assert(math.abs(filtered[1].sources[1].percent - 200 / 3) < 0.001, 'source percentage uses this item quantity')
assert(filtered[1].sources[2].count == 1 and filtered[1].sources[2].name == 'Source unknown (older loot)', 'legacy item quantities remain unattributed')
assert(ns.ItemRows({ items = {} }, '', 'name')[1] == nil, 'empty totals need no division')
assert(#ns.ItemRows(session, '[', 'name') == 0, 'search uses literal matching')
PocketChangeSearch:SetText('missing')
assert(hasText('No matching items.'))
PocketChangeSearch:SetText('Ruby')
local row
for _, button in ipairs(buttons) do if button.link == session.items['124'].link and button:IsShown() then row = button end end
assert(row and row.icon.texture == 222)
row.scripts.OnEnter(row)
assert(GameTooltip.link == row.link)
row.scripts.OnClick(row)
assert(command == row.link)
assert(row.sources:IsShown() and row.sources.text:find('Source unknown (older loot): 1x (100.0%)', 1, true), 'click expands source breakdown')
row.scripts.OnClick(row)
assert(not row.sources:IsShown(), 'second click collapses breakdown')
PocketChangeDB.history[1] = totals()
PocketChangeDB.history[1].started = 1700000000
PocketChangeDB.history[1].elapsed = 120
PocketChangeDB.history[1].locations = { Dungeon = true }
click('Recent runs')
assert(hasText('Dungeon') and not PocketChangeSearch:IsShown())
for _, button in ipairs(buttons) do if button.run then button.scripts.OnClick(button); break end end
assert(hasText('Saved run loot') and PocketChangeSearch:IsShown())
click('All time')
assert(hasText('All time · Earned: 173'))
PocketChangeMinimapButton.scripts.OnEnter(PocketChangeMinimapButton)
PocketChangeMinimapButton.scripts.OnLeave()
PocketChangeMinimapButton.scripts.OnClick(nil, 'RightButton')
assert(command == 'quiet')
session.vendorSales = -200
click('Session')
assert(hasText('Earned: -47'))
session.items['999'] = { count = 1, link = '|Hitem:999|h[Unknown]|h' }
local _, _, missing = ns.ItemRows(session, '', 'name')
assert(missing == 1)
ns.ItemRows(session, '', 'name')
assert(requests == 1, 'uncached item requests are not repeated each refresh')
SlashCmdList.POCKETCHANGEUI()
assert(not PocketChangePanel:IsShown())
assert(UISpecialFrames[1] == 'PocketChangePanel')
PocketChangeDB.diagnostics = { 'Pick Pocket succeeded', 'Counted items: 2', 'Account secret-personal-value', 'Counted items: secret-personal-value' }
local report, url = ns.BuildReport()
assert(report:find('1.60.1', 1, true) and report:find('Counted items: 2', 1, true))
assert(not report:find('secret-personal-value', 1, true), 'only safe known event notes are exported')
assert(url:find('https://github.com/plvsplvs/FiveFingerRebate/issues/new?template=bug_report.yml&diagnostics=', 1, true) == 1)
assert(url:find('%%0A') and not url:find('\n', 1, true), 'prefill URL encodes newlines')
SlashCmdList.FIVEFINGERREBATE('report')
assert(PocketChangeReport:IsShown(), 'report command opens the copy window')
SlashCmdList.FIVEFINGERREBATE('')
assert(PocketChangePanel:IsShown(), 'new slash command opens tracker')
print('UI and item-browser checks passed')
