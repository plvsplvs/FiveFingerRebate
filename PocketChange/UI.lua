local _, ns = ...
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
function ns.CreatePanel(name, width, height, title)
    local window = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    window:SetSize(width, height)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetBackdrop(backdrop)
    window:SetBackdropColor(0.035, 0.045, 0.04, 0.98)
    window:SetBackdropBorderColor(0.42, 0.37, 0.20, 1)
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    local emblem = window:CreateTexture(nil, "ARTWORK")
    emblem:SetSize(24, 24)
    emblem:SetPoint("TOPLEFT", 12, -6)
    emblem:SetTexture("Interface\\Icons\\Ability_BackStab")
    window.TitleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    window.TitleText:SetPoint("TOPLEFT", 44, -10)
    window.TitleText:SetText(title)
    window.TitleText:SetTextColor(0.92, 0.76, 0.40)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() window:Hide() end)
    window:Hide()
    tinsert(UISpecialFrames, name)
    return window
end
local panel = ns.CreatePanel("PocketChangePanel", 480, 600, ns.Title)
local summaryBackground = panel:CreateTexture(nil, "BACKGROUND")
summaryBackground:SetPoint("TOPLEFT", 8, -64)
summaryBackground:SetSize(464, 172)
summaryBackground:SetColorTexture(0.075, 0.085, 0.065, 1)

local function label(parent, font, x, y, width)
    local text = parent:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    return text
end
local function makeButton(text, x, y, width, click)
    local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetNormalFontObject("GameFontHighlightSmall")
    button:SetText(text)
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(0.10, 0.12, 0.09, 1)
    button:SetBackdropBorderColor(0.27, 0.32, 0.20, 1)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.80, 0.68, 0.34, 1) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.27, 0.32, 0.20, 1) end)
    button:SetScript("OnClick", click)
    return button
end
local function money(value)
    return (value < 0 and "-" or "") .. C_CurrencyInfo.GetCoinTextureString(math.abs(value))
end
local function duration(seconds)
    return string.format("%dh %02dm", math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
end
local view, selectedRun, sortBy = "session", nil, "name"
local expandedItem
local summary = label(panel, "GameFontHighlight", 16, -68, 448)
summary:SetSpacing(4)
local heading = label(panel, "GameFontNormal", 16, -244, 448)
local status = label(panel, "GameFontHighlightSmall", 16, -536, 448)
status:SetTextColor(0.65, 0.77, 0.48)
local search = CreateFrame("EditBox", "PocketChangeSearch", panel, "InputBoxTemplate")
search:SetSize(296, 24)
search:SetPoint("TOPLEFT", 22, -268)
search:SetAutoFocus(false)
search:SetMaxLetters(100)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
local searchHint = label(panel, "GameFontDisableSmall", 28, -274, 280)
searchHint:SetText("Search items, IDs, or mob names")
local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 16, -304)
scroll:SetPoint("BOTTOMRIGHT", -36, 72)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(424, 1)
scroll:SetScrollChild(content)
local empty = label(content, "GameFontHighlightSmall", 0, 0, 424)
local rows = {}

local function selectView(value)
    view, selectedRun = value, nil
    expandedItem = nil
    scroll:SetVerticalScroll(0)
    search:SetText("")
    search:ClearFocus()
    ns.Refresh()
end
ns.OnReset = function() selectView("session") end
makeButton("Session", 16, -34, 104, function() selectView("session") end)
makeButton("All time", 128, -34, 104, function() selectView("all") end)
makeButton("Recent runs", 240, -34, 112, function() selectView("history") end)
makeButton("Report a bug", 312, -568, 148, function() ns.OpenReport() end)
local sortButton
sortButton = makeButton("Sort: name", 328, -268, 132, function()
    sortBy = sortBy == "name" and "quantity" or sortBy == "quantity" and "value" or "name"
    sortButton:SetText("Sort: " .. sortBy)
    scroll:SetVerticalScroll(0)
    ns.Refresh()
end)
makeButton("New session", 16, -568, 128, function()
    SlashCmdList.POCKETCHANGE("reset")
    selectView("session")
end)
local quietButton
quietButton = makeButton("Chat summaries", 152, -568, 152, function()
    SlashCmdList.POCKETCHANGE("quiet")
    ns.Refresh()
end)

function ns.RefreshStatus()
    status:SetText(ns.status or "Ready")
end

local function itemRow(index)
    if rows[index] then return rows[index] end
    local row = CreateFrame("Button", nil, content)
    row:SetSize(424, 40)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * 44)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    local shade = index % 2 == 0 and 0.065 or 0.085
    background:SetColorTexture(shade, shade + 0.01, shade - 0.01, 1)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.22, 0.30, 0.12, 0.28)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("TOPLEFT", 0, -4)
    row.name = label(row, "GameFontHighlightSmall", 40, -2, 380)
    row.detail = label(row, "GameFontDisableSmall", 40, -20, 380)
    row.sources = label(row, "GameFontHighlightSmall", 40, -40, 380)
    row.sources:Hide()
    row:SetScript("OnEnter", function(self)
        if self.link then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.link)
            if self.item then
                GameTooltip:AddLine(string.format("%.1f%% of collected item units", self.item.percent), 1, 0.82, 0)
                GameTooltip:AddLine("Click for mob/source breakdown", 1, 1, 1)
                GameTooltip:AddLine("Observed loot share, not a drop chance", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        if self.run then
            selectedRun, view = self.run, "run"
            scroll:SetVerticalScroll(0)
            ns.Refresh()
        elseif self.link then
            if not HandleModifiedItemClick(self.link) then
                if expandedItem == self.item.id then expandedItem = nil else expandedItem = self.item.id end
                ns.Refresh()
            end
        end
    end)
    rows[index] = row
    return row
end

function ns.Refresh()
    if not panel:IsShown() or not PocketChangeDB then return end
    ns.RefreshStatus()
    quietButton:SetText(PocketChangeDB.quiet and "Chat: off" or "Chat: on")
    search:SetShown(view ~= "history")
    sortButton:SetShown(view ~= "history")
    searchHint:SetShown(view ~= "history" and (search:GetText() or "") == "")
    if view == "history" then
        summary:SetText("Recent runs\nThe last 20 sessions you finished with New session.\nClick a run to inspect its loot and earnings.\nDuration counts logged-in time, including idle time.")
        heading:SetText("Saved runs")
        local runs = PocketChangeDB.history
        empty:SetText(#runs == 0 and "No saved runs yet. Finish a session to save it here." or "")
        for i, run in ipairs(runs) do
            local row = itemRow(i)
            row.link, row.run = nil, run
            row.item = nil
            row.sources:Hide()
            row:SetSize(424, 40)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * 44)
            row.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_11")
            local locations = {}
            for zone in pairs(run.locations or {}) do locations[#locations + 1] = zone end
            table.sort(locations)
            row.name:SetText(date("%d %b %H:%M", run.started) .. " · " .. (#locations > 0 and table.concat(locations, ", ") or "No loot location"))
            row.detail:SetText(duration(run.elapsed or 0) .. " · " .. run.pockets .. " pockets · "
                .. money(run.money + run.vendorSales + run.auctionSales))
            row:Show()
        end
        for i = #runs + 1, #rows do rows[i]:Hide() end
        content:SetHeight(math.max(1, #runs * 44))
        return
    end
    local totals = view == "all" and PocketChangeDB or view == "run" and selectedRun or ns.GetSession()
    local list, estimate, missing = ns.ItemRows(totals, search:GetText(), sortBy)
    local earned = totals.money + totals.vendorSales + totals.auctionSales
    local lines = {
        (view == "all" and "All time" or view == "run" and date("Run · %d %b %H:%M", totals.started) or "Current session") .. " · Earned: " .. money(earned),
        "Pocket coins: " .. money(totals.direct) .. "   Junkbox coins: " .. money(totals.junkboxMoney),
        "Vendor sales: " .. money(totals.vendorSales) .. "   AH collected: " .. money(totals.auctionSales),
        "Looted coins combined: " .. money(totals.money) .. "   Pockets: " .. totals.pockets,
        "Loot vendor estimate: " .. money(estimate) .. (missing > 0 and " (some prices unavailable)" or ""),
        "Estimate is historical item value, not added to earnings.",
    }
    if totals.legacyMoney > 0 then lines[#lines + 1] = "Older coins, source unknown: " .. money(totals.legacyMoney) end
    if view ~= "all" then
        local elapsed = view == "run" and (totals.elapsed or 0) or ns.Elapsed()
        local rate = elapsed >= 60 and money(math.floor(earned * 3600 / elapsed)) .. "/hr" or "Rate available after 1 minute"
        lines[#lines + 1] = "Online: " .. duration(elapsed) .. " · " .. rate
    end
    summary:SetText(table.concat(lines, "\n"))
    heading:SetText(view == "all" and "All-time loot" or view == "run" and "Saved run loot" or "Session loot")
    empty:SetText(#list == 0 and ((search:GetText() or "") ~= "" and "No matching items." or "No items collected yet.") or "")
    local offset = 0
    for i, item in ipairs(list) do
        local row = itemRow(i)
        row.run, row.link = nil, item.link
        row.item = item
        row:SetPoint("TOPLEFT", 0, -offset)
        row.icon:SetTexture(item.icon)
        row.name:SetText(item.count .. "x " .. item.link)
        row.detail:SetText(string.format("%.1f%% of loot · Vendor: ", item.percent) .. (item.value and money(item.value) or "price unavailable"))
        local height = 40
        row.sources:SetShown(expandedItem == item.id)
        if expandedItem == item.id then
            local breakdown = { "Sources · share of this item:" }
            for _, source in ipairs(item.sources) do
                breakdown[#breakdown + 1] = string.format("%s: %dx (%.1f%%)", source.name, source.count, source.percent)
            end
            row.sources:SetText(table.concat(breakdown, "\n"))
            height = height + row.sources:GetStringHeight() + 8
        end
        row:SetSize(424, height)
        offset = offset + height + 4
        row:Show()
    end
    for i = #list + 1, #rows do rows[i]:Hide() end
    content:SetHeight(math.max(1, offset))
end
search:SetScript("OnTextChanged", function()
    scroll:SetVerticalScroll(0)
    ns.Refresh()
end)
panel:SetScript("OnShow", ns.Refresh)
local elapsedUpdate = 0
panel:SetScript("OnUpdate", function(_, elapsed)
    elapsedUpdate = elapsedUpdate + elapsed
    if elapsedUpdate >= 1 then elapsedUpdate = 0; ns.Refresh() end
end)
local button = CreateFrame("Button", "PocketChangeMinimapButton", Minimap)
button:SetSize(31, 31)
button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -12, -12)
button:SetFrameStrata("MEDIUM")
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_11")
local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
        SlashCmdList.POCKETCHANGE("quiet")
    elseif mouseButton == "LeftButton" then
        panel:SetShown(not panel:IsShown())
    end
end)
button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.Title)
    if PocketChangeDB then GameTooltip:AddLine("Total stolen: " .. money(PocketChangeDB.money), 1, 1, 1) end
    GameTooltip:AddLine("Left-click: open tracker", 1, 1, 1)
    GameTooltip:AddLine("Right-click: toggle chat summaries", 1, 1, 1)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

SLASH_POCKETCHANGEUI1 = "/pcui"
SlashCmdList.POCKETCHANGEUI = function() panel:SetShown(not panel:IsShown()) end
