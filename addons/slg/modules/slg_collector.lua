-- SLG Collector Module
local addonName, SLG = ...

SLG_CollectedLoot = SLG_CollectedLoot or {}

local function GetCurrentDifficulty()
    local diff = GetInstanceDifficulty and GetInstanceDifficulty() or (select(3, GetInstanceInfo()))
    local diffName = "Unknown"
    if diff == 1 then diffName = "Normal" end
    if diff == 2 then diffName = "Heroic" end
    if diff == 3 then diffName = "Normal (25)" end
    if diff == 4 then diffName = "Heroic (25)" end
    return diffName
end

local function GetCurrentZone()
    return GetRealZoneText() or "Unknown"
end

local function GetBossName()
    -- Try to get boss name from target or encounter
    if UnitExists("boss1") then
        local name = UnitName("boss1")
        if name then return name end
    end
    -- fallback: use last encounter name if available
    if SLG_Collector_LastBoss then return SLG_Collector_LastBoss end
    return "Unknown Boss"
end

local function AddLoot(itemID)
    local zone = GetCurrentZone()
    local boss = GetBossName()
    local diff = GetCurrentDifficulty()
    if not SLG_CollectedLoot[zone] then SLG_CollectedLoot[zone] = {} end
    if not SLG_CollectedLoot[zone][boss] then SLG_CollectedLoot[zone][boss] = {} end
    if not SLG_CollectedLoot[zone][boss][diff] then SLG_CollectedLoot[zone][boss][diff] = {} end
    for _, id in ipairs(SLG_CollectedLoot[zone][boss][diff]) do
        if id == itemID then return end -- already recorded
    end
    table.insert(SLG_CollectedLoot[zone][boss][diff], itemID)
end

local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("CHAT_MSG_LOOT")
f:RegisterEvent("MERCHANT_SHOW")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ENCOUNTER_START" then
        local encounterID, encounterName = ...
        SLG_Collector_LastBoss = encounterName
    elseif event == "ENCOUNTER_END" then
        SLG_Collector_LastBoss = nil
    elseif event == "LOOT_OPENED" then
        for i = 1, GetNumLootItems() do
            local itemLink = GetLootSlotLink(i)
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+):"))
                if itemID then AddLoot(itemID) end
            end
        end
    elseif event == "CHAT_MSG_LOOT" then
        local msg = ...
        local itemLink = msg:match("|Hitem:.-|h")
        if itemLink then
            local itemID = tonumber(itemLink:match("item:(%d+):"))
            if itemID then AddLoot(itemID) end
        end
    elseif event == "MERCHANT_SHOW" then
        local zone = GetCurrentZone()
        local vendor = UnitName("target") or "Vendor"
        if not SLG_CollectedLoot[zone] then SLG_CollectedLoot[zone] = {} end
        if not SLG_CollectedLoot[zone][vendor] then SLG_CollectedLoot[zone][vendor] = {} end
        if not SLG_CollectedLoot[zone][vendor]["Vendor"] then SLG_CollectedLoot[zone][vendor]["Vendor"] = {} end
        local seen = {}
        for _, id in ipairs(SLG_CollectedLoot[zone][vendor]["Vendor"]) do seen[id] = true end
        for i = 1, GetMerchantNumItems() do
            local itemLink = GetMerchantItemLink(i)
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+):"))
                if itemID and not seen[itemID] then
                    table.insert(SLG_CollectedLoot[zone][vendor]["Vendor"], itemID)
                    seen[itemID] = true
                end
            end
        end
    end
end)

SLG_Collector = {}
function SLG_Collector:Init()
    -- nothing needed, frame auto-registers
end

local function TableToLua(tbl, indent)
    indent = indent or 0
    local pad = string.rep(" ", indent)
    local s = "{\n"
    for k, v in pairs(tbl) do
        local key = (type(k) == "string" and string.format("[\"%s\"]", k) or string.format("[%d]", k))
        if type(v) == "table" then
            s = s .. pad .. "  " .. key .. " = " .. TableToLua(v, indent + 2) .. ",\n"
        elseif type(v) == "number" then
            s = s .. pad .. "  " .. key .. " = " .. v .. ",\n"
        elseif type(v) == "string" then
            s = s .. pad .. "  " .. key .. " = \"" .. v .. "\",\n"
        end
    end
    s = s .. pad .. "}"
    return s
end

SLASH_SLGEXPORTLOOT1 = "/slgexportloot"
SlashCmdList["SLGEXPORTLOOT"] = function()
    if not SLG_CollectedLoot then print("No loot data collected yet.") return end
    local out = "SLG_CollectedLoot = " .. TableToLua(SLG_CollectedLoot)
    print("\124cffffd700SLG Collected Loot:\124r\n" .. out)
end

_G.ExportVendorsOnly = function()
    if not SLG_CollectedLoot or not next(SLG_CollectedLoot) then
        print("No vendor data to export.")
        return
    end
    local out = ""
    for zone, vendors in pairs(SLG_CollectedLoot) do
        for vendor, sources in pairs(vendors) do
            if sources["Vendor"] and #sources["Vendor"] > 0 then
                local ids = table.concat(sources["Vendor"], ", ")
                out = out .. zone .. " > " .. vendor .. " > " .. ids .. "\n"
            end
        end
    end
    if out == "" then
        print("No vendor data to export.")
    else
        print("|cffffd700SLG Vendor Export:|r\n" .. out)
    end
end

SLASH_SLGEXPORTVENDORS1 = "/slgexportvendors"
SlashCmdList["SLGEXPORTVENDORS"] = ExportVendorsOnly 