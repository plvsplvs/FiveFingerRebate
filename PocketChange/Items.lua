local _, ns = ...
local requested = {}

function ns.ItemSources(item)
    local rows, recorded = {}, 0
    for key, source in pairs(item.sources or {}) do
        local npcID = key:match("^npc:(%d+)$")
        local name = npcID and PocketChangeDB.mobNames and PocketChangeDB.mobNames[npcID] or source.name
        rows[#rows + 1] = { name = name or "Source unknown", count = source.count,
            percent = item.count > 0 and source.count * 100 / item.count or 0 }
        recorded = recorded + source.count
    end
    if recorded < item.count then
        rows[#rows + 1] = { name = "Source unknown (older loot)", count = item.count - recorded,
            percent = (item.count - recorded) * 100 / item.count }
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)
    return rows
end

function ns.ItemRows(totals, query, sortBy)
    local rows, estimate, missing = {}, 0, 0
    local totalCount = 0
    for _, item in pairs(totals.items) do totalCount = totalCount + item.count end
    query = (query or ""):lower()
    for id, item in pairs(totals.items) do
        local name, _, _, _, _, _, _, _, _, icon, price = C_Item.GetItemInfo(item.link)
        if not name and not requested[id] then
            requested[id] = true
            C_Item.RequestLoadItemDataByID(tonumber(id))
        end
        name = name or item.link:match("%[(.-)%]") or ("Item " .. id)
        -- NOTE: Box contents are valued separately; never add the container's value too.
        if tonumber(id) == 16882 then price = 0 end
        local value = price and price * item.count
        estimate = estimate + (value or 0)
        if not value then missing = missing + 1 end
        local sources = ns.ItemSources(item)
        local sourceMatch = false
        for _, source in ipairs(sources) do
            if source.name:lower():find(query, 1, true) then sourceMatch = true; break end
        end
        if query == "" or sourceMatch or name:lower():find(query, 1, true) or tostring(id):find(query, 1, true) then
            rows[#rows + 1] = { id = id, name = name, link = item.link, count = item.count,
                icon = icon or 134400, value = value, sources = sources,
                percent = totalCount > 0 and item.count * 100 / totalCount or 0 }
        end
    end
    table.sort(rows, function(a, b)
        if sortBy == "quantity" and a.count ~= b.count then return a.count > b.count end
        if sortBy == "value" and a.value ~= b.value then return (a.value or -1) > (b.value or -1) end
        if a.name ~= b.name then return a.name:lower() < b.name:lower() end
        return tonumber(a.id) < tonumber(b.id)
    end)
    return rows, estimate, missing
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", function(_, _, id, success)
    if success then requested[tostring(id)] = nil end
    if ns.Refresh then ns.Refresh() end
end)
