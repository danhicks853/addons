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
        listTotal = 0,    -- Items in the currently displayed/filtered list
        listAttuned = 0,  -- Attuned items in the currently displayed/filtered list
        zoneEligible = 0, -- Total usable items in the whole zone
        zoneAttuned = 0   -- Total usable AND attuned items in the whole zone
    }
    
    local sourceGroups = {}
    -- Get current difficulty info
    local difficulty, instanceType = SLG.modules.DifficultyManager:GetInstanceInfo()
    local diffKey -- Declare diffKey
    if instanceType ~= "outdoor" then -- Only set diffKey for instances
        if difficulty == 1 then
            diffKey = "Normal (10)"
        elseif difficulty == 2 then
            diffKey = "Normal (25)"
        elseif difficulty == 3 then
            diffKey = "Heroic (10)"
        elseif difficulty == 4 then
            diffKey = "Heroic (25)"
        else
            -- Fallback for unknown instance difficulties, ensure it's not nil
            diffKey = "Normal (10)" 
        end
    else
        diffKey = nil -- Explicitly nil for outdoor
    end
    
    -- Get player's faction
    local playerFaction = UnitFactionGroup("player")
    -- local factionSuffix = playerFaction == "Alliance" and "_A" or "_H" -- Not currently used
    
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
            local sourceDiff = sourceName:match("%(([^%)]+)%)") -- Check if the source name contains difficulty information
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
                            elseif showEligible and canUse then
                                stats.listTotal = stats.listTotal + 1
                                if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                            elseif showAttuned and canUse and isAttuned then
                                stats.listTotal = stats.listTotal + 1
                                stats.listAttuned = stats.listAttuned + 1
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                            elseif showNotAttuned and canUse and not isAttuned then
                                stats.listTotal = stats.listTotal + 1
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                            end
                        end
                    end
                end
            else -- Logic for instances (non-outdoor)
                if sourceDiff then
                    local sourceDifficulty = sourceDiff
                    if sourceDiff:match("25ManHeroic") then
                        sourceDifficulty = "Heroic (25)"
                    elseif sourceDiff:match("25Man") then
                        sourceDifficulty = "Normal (25)"
                    elseif sourceDiff:match("Heroic") then 
                        sourceDifficulty = "Heroic (10)"
                    end
                    
                    if sourceDifficulty == diffKey then
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
                                elseif showEligible and canUse then
                                    stats.listTotal = stats.listTotal + 1
                                    if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                elseif showAttuned and canUse and isAttuned then
                                    stats.listTotal = stats.listTotal + 1
                                    stats.listAttuned = stats.listAttuned + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                elseif showNotAttuned and canUse and not isAttuned then
                                    stats.listTotal = stats.listTotal + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                end
                            end
                        end
                    end
                else -- No sourceDiff, this implies it's from a source like "Boss Name" without (Difficulty)
                     -- Apply only if current instance difficulty is Normal (10), as per original implicit logic
                    if diffKey == "Normal (10)" then
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
                                elseif showEligible and canUse then
                                    stats.listTotal = stats.listTotal + 1
                                    if isAttuned then stats.listAttuned = stats.listAttuned + 1 end
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                elseif showAttuned and canUse and isAttuned then
                                    stats.listTotal = stats.listTotal + 1
                                    stats.listAttuned = stats.listAttuned + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                elseif showNotAttuned and canUse and not isAttuned then
                                    stats.listTotal = stats.listTotal + 1
                                    table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName })
                                end
                            end
                        end
                    end
                end
            end -- Closes 'if instanceType == "outdoor" / else'
            
            -- print("SLG_DEBUG: GetZoneItems - Processed sourceName: " .. tostring(sourceName) .. ". #sourceItems = " .. tostring(#sourceItems) .. ", current #sourceGroups = " .. tostring(#sourceGroups))
            if #sourceItems > 0 then
                table.insert(sourceGroups, {
                    source = sourceName,
                    items = sourceItems
                })
                -- print("SLG_DEBUG: GetZoneItems - Added to sourceGroups. #sourceGroups = " .. tostring(#sourceGroups)) -- Optional Debug
            end
        end -- Closes 'if sourceName ~= "__order"'
    end -- Closes 'for sourceName, itemIds in boss_iter()'
    
    -- print("SLG_DEBUG: GetZoneItems FINAL - Returning. #sourceGroups = " .. tostring(#sourceGroups) .. ", total items processed = " .. tostring(stats.total) .. ", total attuned = " .. tostring(stats.attuned))
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