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
        listTotal = 0,
        listAttuned = 0,
        zoneEligible = 0,
        zoneAttuned = 0
    }
    
    local sourceGroups = {}
    local boss_iter = function()
        local order = zoneData.__order
        return pairs(zoneData)
    end
    
    local difficulty, instanceType = SLG.modules.DifficultyManager:GetInstanceInfo()
    local diffKey 
    if instanceType ~= "outdoor" then 
        if difficulty == 1 then
            diffKey = "Normal (10)"
        elseif difficulty == 2 then
            diffKey = "Normal (25)"
        elseif difficulty == 3 then
            diffKey = "Heroic (10)"
        elseif difficulty == 4 then
            diffKey = "Heroic (25)"
        else
            diffKey = "Normal (10)" 
        end
    else
        diffKey = nil 
    end
    
    local playerFaction = UnitFactionGroup("player")
    
    local mode = SLGSettings.displayMode or SLG.DisplayModes.NOT_ATTUNED
    
    local showAll = mode == "all"
    local showEligible = mode == "eligible"
    local showAttuned = mode == "attuned"
    local showNotAttuned = mode == "not_attuned"
    
    local function shouldCountItem(canUse, isAttuned)
        if showAll then return true end
        if showEligible then return canUse end
        if showAttuned then return canUse and isAttuned end
        if showNotAttuned then return canUse and not isAttuned end
        return false
    end
    
    for sourceName, itemIds in boss_iter() do
        if sourceName ~= "__order" then
            local sourceDiff = sourceName:match("%(([^%)]+)%)")
            local sourceItems = {}
            
            if instanceType == "outdoor" then
                if itemIds and type(itemIds) == "table" then
                    for _, itemId in ipairs(itemIds) do
                        local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                        if itemData then
                            local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                            local canUse = SLG.modules.ItemManager:CanUseItem(itemData)
                            if canUse then
                                stats.zoneEligible = stats.zoneEligible + 1
                                if isAttuned then
                                    stats.zoneAttuned = stats.zoneAttuned + 1
                                end
                            end
                            if showAll then
                                stats.listTotal = stats.listTotal + 1
                                if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                            else
                                if shouldCountItem(canUse, isAttuned) then
                                    stats.listTotal = stats.listTotal + 1
                                    if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                end
                            end
                        end
                    end
                end
            else 
                if sourceDiff then
                    local sourceDifficulty = sourceDiff
                    if sourceDiff:match("25ManHeroic") then
                        sourceDifficulty = "Heroic (25)"
                    elseif sourceDiff:match("25Man") then
                        sourceDifficulty = "Normal (25)"
                    elseif sourceDiff:match("Heroic") then 
                        sourceDifficulty = "Heroic (10)"
                    end
                    
                    sourceDifficulty = sourceDifficulty:gsub("_[AH]$", "")
                    local currentDiffKey = diffKey:gsub("_[AH]$", "")
                    
                    if sourceDifficulty == currentDiffKey then
                        for _, itemId in ipairs(itemIds) do
                            local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                            if itemData then
                                local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                                local canUse = SLG.modules.ItemManager:CanUseItem(itemData)
                                if canUse then
                                    stats.zoneEligible = stats.zoneEligible + 1
                                    if isAttuned then
                                        stats.zoneAttuned = stats.zoneAttuned + 1
                                    end
                                end
                                if showAll then
                                    stats.listTotal = stats.listTotal + 1
                                    if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                else
                                    if shouldCountItem(canUse, isAttuned) then
                                        stats.listTotal = stats.listTotal + 1
                                        if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                        table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                    end
                                end
                            end
                        end
                    end
                else 
                    if diffKey == "Normal (10)" and itemIds then
                        for _, itemId in ipairs(itemIds) do
                            local itemData = SLG.modules.ItemManager:GetItemData(itemId)
                            if itemData then
                                local isAttuned = SLG.modules.Attunement:IsAttuned(itemId)
                                local canUse = SLG.modules.ItemManager:CanUseItem(itemData)
                                if canUse then
                                    stats.zoneEligible = stats.zoneEligible + 1
                                    if isAttuned then
                                        stats.zoneAttuned = stats.zoneAttuned + 1
                                    end
                                end
                                if showAll then
                                    stats.listTotal = stats.listTotal + 1
                                    if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                else
                                    if shouldCountItem(canUse, isAttuned) then
                                        stats.listTotal = stats.listTotal + 1
                                        if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                        table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                    end
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