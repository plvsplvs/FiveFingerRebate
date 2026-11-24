local addonName, ns = ...
local allowed = {}
for _, message in ipairs({
    "Skipped slot: no loot source", "Skipped slot: restricted loot source",
    "Skipped slot: different source", "Skipped slot: restricted loot details",
    "Battered Junkbox opened", "Skipped loot: cast expired", "Skipped coins: unreadable amount",
    "Skipped cast: restricted cast identifier", "Skipped cast: spell identity restricted",
    "Skipped success: restricted cast identifier", "Pick Pocket sent: target known",
    "Pick Pocket sent: target unavailable", "Pick Pocket succeeded", "Pick Pocket failed or interrupted",
}) do allowed[message] = true end
for _, event in ipairs({ "LOOT_READY", "LOOT_OPENED" }) do
    for _, state in ipairs({ "cast pending", "pocket active", "no recent cast" }) do allowed[event .. ": " .. state] = true end
end

local function encode(value)
    return (value:gsub("([^%w%-_%.~])", function(char) return string.format("%%%02X", string.byte(char)) end))
end
function ns.BuildReport()
    local version, build, _, interface = GetBuildInfo()
    local lines = {
        ns.Title .. " " .. (C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"),
        "Client: " .. tostring(version) .. " (" .. tostring(build) .. ")",
        "Interface: " .. tostring(interface),
        "Locale: " .. GetLocale(),
        "Recent tracking events:",
    }
    local entries = PocketChangeDB and PocketChangeDB.diagnostics or {}
    for i = math.max(1, #entries - 14), #entries do
        local message = entries[i]
        if type(message) == "string" and (allowed[message] or message:match("^Counted coins: %d+$") or message:match("^Counted items: %d+$")) then
            lines[#lines + 1] = message
        end
    end
    if #lines == 5 then lines[#lines + 1] = "No recent tracking diagnostics recorded." end
    local report = table.concat(lines, "\n")
    return report, ns.Repository .. "/issues/new?template=bug_report.yml&diagnostics=" .. encode(report)
end

local window, reportBox, urlBox
local function selectText(self) self:SetFocus(); self:HighlightText() end
function ns.OpenReport()
    if not window then
        window = ns.CreatePanel("PocketChangeReport", 520, 500, "Report a bug")
        local instructions = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        instructions:SetPoint("TOPLEFT", 20, -48)
        instructions:SetWidth(480)
        instructions:SetJustifyH("LEFT")
        instructions:SetText("Copy the link into your browser. Review the prefilled diagnostics, describe the problem, then submit on GitHub. A GitHub account is required.")
        urlBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
        urlBox:SetSize(472, 24)
        urlBox:SetPoint("TOPLEFT", 24, -96)
        urlBox:SetAutoFocus(false)
        urlBox:SetMaxLetters(0)
        urlBox:SetScript("OnMouseUp", selectText)
        urlBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local privacy = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        privacy:SetPoint("TOPLEFT", 20, -132)
        privacy:SetWidth(480)
        privacy:SetJustifyH("LEFT")
        privacy:SetText("Includes client/addon versions, language, and recent event notes. No character/account names, bags, or saved-variable files. Nothing is sent automatically. Copy: Ctrl+C / Cmd+C.")
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -188)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        reportBox = CreateFrame("EditBox", nil, scroll)
        reportBox:SetMultiLine(true)
        reportBox:SetFontObject(ChatFontNormal)
        reportBox:SetWidth(452)
        reportBox:SetHeight(480)
        reportBox:SetAutoFocus(false)
        reportBox:SetMaxLetters(0)
        reportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(reportBox)
    end
    local report, url = ns.BuildReport()
    reportBox:SetText(report)
    urlBox:SetText(url)
    window:Show()
    selectText(urlBox)
end

SLASH_FIVEFINGERREBATE1 = "/ffr"
SLASH_FIVEFINGERREBATE2 = "/fivefingerrebate"
SlashCmdList.FIVEFINGERREBATE = function(input)
    local command = input:lower():match("^%s*(.-)%s*$")
    if command == "report" or command == "bug" then
        ns.OpenReport()
    elseif command == "" then
        SlashCmdList.POCKETCHANGEUI()
    else
        SlashCmdList.POCKETCHANGE(command)
    end
end
