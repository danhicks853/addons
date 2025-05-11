local addonName, SLG = ...

-- Create the module
local ZoneManager = {}
SLG:RegisterModule("ZoneManager", ZoneManager)

-- Initialize the module
function ZoneManager:Initialize()
    -- Register for zone change events
    self:RegisterEvents()
end

-- Register zone-related events
function ZoneManager:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    
    frame:SetScript("OnEvent", function(_, event, ...)
        self:OnZoneChange(event, ...)
    end)
    
    self.frame = frame
end

-- Handle zone change events
function ZoneManager:OnZoneChange(event)
    -- Update the UI if auto-open is enabled
    if SLGSettings.autoOpenOnZoneChange then
        if SLG.modules.MainWindow then
            SLG.modules.MainWindow:Show()
        end
    end
    
    -- Update the item list
    if SLG.modules.ItemList then
        SLG.modules.ItemList:UpdateDisplay()
    end
end

-- Get items for current zone
function ZoneManager:GetZoneItems(zoneName)
    local zoneData = SLG.ZoneItems[zoneName]
    if not zoneData then
        return nil, { total = 0, attuned = 0 }
    end
    
    local stats = {
        total = 0,
        attuned = 0
    }
    
    local sourceGroups = {}
    -- Get current difficulty info
    local difficulty, instanceType = SLG.modules.DifficultyManager:GetInstanceInfo()
    
    -- Get player's faction
    local playerFaction = UnitFactionGroup("player")
    local factionSuffix = playerFaction == "Alliance" and "_A" or "_H"
    
    -- Get player's class for class-specific item checks
    local playerClass = SLG.modules.ItemManager:GetPlayerClass()
    
    -- Use __order if present for boss ordering
    local bossKeys = zoneData.__order or {}
    local ordered = #bossKeys > 0

    local mode = SLGSettings.displayMode or SLG.DisplayModes.NOT_ATTUNED
    
    local showAll = mode == "all"
    local showEligible = mode == "eligible"
    local showAttuned = mode == "attuned"
    local showNotAttuned = mode == "not_attuned"

    local function boss_iter()
        if ordered then
            local i = 0
            return function()
                i = i + 1
                local k = bossKeys[i]
                if k then return k, zoneData[k] end
            end
        else
            return pairs(zoneData)
        end
    end
    
    for sourceName, itemIds in boss_iter() do
        -- Skip __order key
        if sourceName ~= "__order" then
            -- Check if the source name contains difficulty information
            local sourceDiff = sourceName:match("%(([^%)]+)%)")
            local sourceItems = {}
            
            -- For non-instance zones (like Dalaran), show items based on display mode
            if instanceType == "outdoor" then
                for _, itemId in ipairs(itemIds) do
                    local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                    if itemData then
                        local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                        local canUseGeneral = SLG.modules.ItemManager:CanUseItem(itemData.itemType)
                        local canUseClassWise = SLG.modules.ItemManager:PlayerCanUseItemClassWise(itemId, playerClass)

                        -- Only add items that match the current display mode and class restrictions
                        if showAll and canUseClassWise then
                            stats.total = stats.total + 1
                            if isAttuned then stats.attuned = stats.attuned + 1 end
table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                        elseif showEligible and canUseGeneral and canUseClassWise then
                            stats.total = stats.total + 1
                            if isAttuned then stats.attuned = stats.attuned + 1 end
table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                        elseif showAttuned and canUseGeneral and isAttuned and canUseClassWise then
                            stats.total = stats.total + 1
                            stats.attuned = stats.attuned + 1
table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                        elseif showNotAttuned and canUseGeneral and not isAttuned and canUseClassWise then
                            stats.total = stats.total + 1
table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                        end
                    end
                end
            else
                if sourceDiff then
                    -- Convert source difficulty to match our format
                    local sourceDifficulty = sourceDiff
                    if sourceDiff:match("25ManHeroic") then
                        sourceDifficulty = "Heroic (25)"
                    elseif sourceDiff:match("25Man") then
                        sourceDifficulty = "Normal (25)"
                    elseif sourceDiff:match("Heroic") then
                        sourceDifficulty = "Heroic (10)"
                    end
                    
                    -- Only process items if the source difficulty matches current difficulty
                    if sourceDifficulty == diffKey then
                        for _, itemId in ipairs(itemIds) do
                            local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                            if itemData then
                                local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                                local canUse = SLG.modules.ItemManager:CanUseItem(itemData.itemType)

                                if showAll then
                                    stats.total = stats.total + 1
                                    if isAttuned then stats.attuned = stats.attuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showEligible and canUseGeneral and canUseClassWise then
                                    stats.total = stats.total + 1
                                    if isAttuned then stats.attuned = stats.attuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showAttuned and canUseGeneral and isAttuned and canUseClassWise then
                                    stats.total = stats.total + 1
                                    stats.attuned = stats.attuned + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showNotAttuned and canUseGeneral and not isAttuned and canUseClassWise then
                                    stats.total = stats.total + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                end
                            end
                        end
                    end
                else
                    -- If no difficulty specified in source name, it's a normal mode item
                    if diffKey == "Normal (10)" then
                        for _, itemId in ipairs(itemIds) do
                            local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                            if itemData then
                                local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                                local canUse = SLG.modules.ItemManager:CanUseItem(itemData.itemType)

                                if showAll then
                                    stats.total = stats.total + 1
                                    if isAttuned then stats.attuned = stats.attuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showEligible and canUseGeneral and canUseClassWise then
                                    stats.total = stats.total + 1
                                    if isAttuned then stats.attuned = stats.attuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showAttuned and canUseGeneral and isAttuned and canUseClassWise then
                                    stats.total = stats.total + 1
                                    stats.attuned = stats.attuned + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                elseif showNotAttuned and canUseGeneral and not isAttuned and canUseClassWise then
                                    stats.total = stats.total + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, equipSlot = itemData.equipSlot, source = sourceName })
                                end
                            end
                        end
                    end
                end
            end
            
            if #sourceItems > 0 then
                table.insert(sourceGroups, {
                    source = sourceName,
                    items = sourceItems
                })
            end
        end
    end
    
    return sourceGroups, stats
end

-- Helper function to count total items in zone data
function ZoneManager:CountZoneItems(zoneData)
    local count = 0
    for sourceName, items in pairs(zoneData) do
        if sourceName ~= "__order" and type(items) == "table" then
            count = count + #items
        end
    end
    return count
end

-- Return the module
return ZoneManager 