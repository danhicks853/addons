local AtlasLoot = LibStub("AceAddon-3.0"):GetAddon("AtlasLoot")
local AL = LibStub("AceLocale-3.0"):GetLocale("AtlasLoot")
local SynastriaCoreLib = LibStub('SynastriaCoreLib-1.0')
local BabbleZone = AtlasLoot_GetLocaleLibBabble("LibBabble-Zone-3.0")

local SLG = {}
AtlasLoot.SLG = SLG

-- Create the main frame (classic 3.3.5 style)
local frame = CreateFrame("Frame", "AtlasLootSLGFrame", UIParent)
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
frame:SetBackdropColor(0,0,0,1)

-- Create the scroll frame (no template)
local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 12)

-- Create the content frame
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(scrollFrame:GetWidth(), 1000) -- Initial height, will be adjusted
scrollFrame:SetScrollChild(content)

-- Create the title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("AtlasLoot Attunement")

-- Categories for different item sources
local categories = {
    "Boss Drops",
    "Vendor Items",
    "Zone Drops",
    "Quest Rewards",
    "Crafting"
}

-- Function to get current zone name
local function GetCurrentZoneName()
    local zoneName = GetZoneText()
    return zoneName
end

-- Function to check if an item is attunable but not attuned
local function IsItemAttunableNotAttuned(itemId)
    if not itemId or type(itemId) ~= "number" then return false end
    return SynastriaCoreLib.IsItemValid(itemId) and SynastriaCoreLib.GetAttuneProgress(itemId) < 100
end

-- Function to get items from a loot table
local function GetItemsFromLootTable(tableName, lootTableType)
    local items = {}
    if not AtlasLoot_Data[tableName] or not AtlasLoot_Data[tableName][lootTableType] then
        return items
    end
    
    for _, page in ipairs(AtlasLoot_Data[tableName][lootTableType]) do
        for _, item in ipairs(page) do
            if item[2] and type(item[2]) == "number" then
                table.insert(items, {
                    id = item[2],
                    name = item[4],
                    source = "Boss Drops" -- Default to boss drops
                })
            end
        end
    end
    return items
end

-- Function to get all items in current zone
local function GetItemsInCurrentZone()
    local currentZone = GetCurrentZoneName()
    local itemsByCategory = {}
    
    -- Initialize categories
    for _, category in ipairs(categories) do
        itemsByCategory[category] = {}
    end
    
    -- Search through all loot tables
    for tableName, tableData in pairs(AtlasLoot_Data) do
        -- Check if this table belongs to current zone
        local zoneInfo = AtlasLoot_LootTableRegister["Instances"][tableName]
        if zoneInfo and zoneInfo["Info"] and zoneInfo["Info"][1] == currentZone then
            -- Get items from all loot table types
            for _, lootTableType in ipairs(AtlasLoot.lootTableTypes) do
                local items = GetItemsFromLootTable(tableName, lootTableType)
                for _, item in ipairs(items) do
                    if IsItemAttunableNotAttuned(item.id) then
                        table.insert(itemsByCategory[item.source], item)
                    end
                end
            end
        end
    end
    
    return itemsByCategory
end

-- Function to populate the frame with items
local function PopulateFrame()
    -- Clear existing content
    for i = 1, content:GetNumChildren() do
        local child = select(i, content:GetChildren())
        if child then
            child:Hide()
        end
    end
    
    local itemsByCategory = GetItemsInCurrentZone()
    local yOffset = 0
    
    -- Create item buttons
    for _, category in ipairs(categories) do
        if #itemsByCategory[category] > 0 then
            -- Create category header
            local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -yOffset)
            header:SetText(category)
            yOffset = yOffset + 20
            
            -- Create item buttons
            for _, item in ipairs(itemsByCategory[category]) do
                local itemButton = CreateFrame("Button", nil, content, "ItemButtonTemplate")
                itemButton:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -yOffset)
                itemButton:SetSize(32, 32)
                
                -- Set item info
                local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(item.id)
                if name then
                    itemButton:SetAttribute("type1", "item")
                    itemButton:SetAttribute("item", link)
                    _G[itemButton:GetName().."IconTexture"]:SetTexture(texture)
                    
                    -- Add item name
                    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    nameText:SetPoint("LEFT", itemButton, "RIGHT", 5, 0)
                    nameText:SetText(name)
                    
                    -- Add attunement indicator
                    local attuneIcon = itemButton:CreateTexture(nil, "OVERLAY")
                    attuneIcon:SetPoint("BOTTOMLEFT", 2, 2)
                    attuneIcon:SetSize(12, 12)
                    attuneIcon:SetTexture("Interface\\AddOns\\AtlasLoot\\Images\\AttuneIconWhite")
                    attuneIcon:SetVertexColor(0.96, 0.63, 0.02) -- Orange color for not fully attuned
                end
                
                yOffset = yOffset + 40
            end
        end
    end
    
    -- Adjust content height
    content:SetHeight(yOffset + 20)
end

-- Function to show the frame
function SLG:ShowFrame()
    frame:Show()
    PopulateFrame()
end

-- Test function to verify module is working
function SLG:Test()
    print("AtlasLoot Attunement module loaded successfully!")
    print("Current zone: " .. GetCurrentZoneName())
    local itemsByCategory = GetItemsInCurrentZone()
    local totalItems = 0
    for category, items in pairs(itemsByCategory) do
        print(category .. ": " .. #items .. " items")
        totalItems = totalItems + #items
    end
    print("Total attunable items in zone: " .. totalItems)
end

-- Initialize the module
function SLG:OnInitialize()
    -- Register the slash command
    SLASH_SLG1 = "/slg"
    SlashCmdList["SLG"] = function()
        self:ShowFrame()
    end

    -- Register test command
    SLASH_SLGTEST1 = "/slgtest"
    SlashCmdList["SLGTEST"] = function()
        self:Test()
    end
end

-- No RegisterModule call needed for this AtlasLoot version 