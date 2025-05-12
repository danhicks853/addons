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
    
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ZONE_CHANGED_NEW_AREA" then
            self:OnZoneChange(event, ...)
        end
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
function ZoneManager:GetZoneItems(zoneName, difficulty)
    print("==== CORE DATA DEBUG ====")
    print("SLG.ZoneItems exists:", SLG.ZoneItems ~= nil)
    print("SLG.ZoneInfo exists:", SLG.ZoneInfo ~= nil)
    print("ItemManager available:", SLG.modules.ItemManager ~= nil)
    print("Attunement available:", SLG.modules.Attunement ~= nil)

    local testItem = 50274 -- Example item ID
    local testItemData = SLG.modules.ItemManager:GetItemData(testItem)
    print("Test item lookup (50274):", testItemData and testItemData.name or "FAILED")
    print("========================")

    local zoneData = SLG.ZoneItems[zoneName]
    if not zoneData then
        return nil, { listTotal = 0, listAttuned = 0, zoneEligible = 0, zoneAttuned = 0 }
    end
    
    local stats = {
        listTotal = 0,
        listAttuned = 0,
        zoneEligible = 0,
        zoneAttuned = 0
    }
    
    local sourceGroups = {}
    
    -- Get instance type with safe fallbacks
    local instanceType = "instance"
    if SLG.ZoneInfo and SLG.ZoneInfo[zoneName] then
        instanceType = SLG.ZoneInfo[zoneName].type
    else
        -- Fallback to API detection if ZoneInfo missing
        local _, detectedType = GetInstanceInfo()
        instanceType = detectedType or "instance"
        print("WARNING: Using fallback instance type:", instanceType)
    end
    
    -- Initialize empty ZoneInfo if missing
    if not SLG.ZoneInfo then
        SLG.ZoneInfo = {}
        print("WARNING: Initialized missing SLG.ZoneInfo table")
    end
    
    -- Always use GetInstanceInfo for raids to determine difficulty
    local difficultySetting
    local _, _, difficultyID = GetInstanceInfo()
    print("[SLG] Detected instanceType:", instanceType, "difficultyID:", difficultyID)
    if instanceType == "raid" then
        if difficultyID == 4 then
            difficultySetting = "25ManHeroic"
        elseif difficultyID == 3 then
            difficultySetting = "Heroic"
        elseif difficultyID == 2 then
            difficultySetting = "25Man"
        else -- difficultyID == 1
            difficultySetting = "Normal"
        end
    else -- dungeon
        if difficultyID == 2 then
            -- Check for Mythic dungeon debuff
            if UnitDebuff("player", "Mythic Dungeon") then
                difficultySetting = "Mythic"
            else
                difficultySetting = "Heroic"
            end
        else -- difficultyID == 1
            difficultySetting = "Normal"
        end
    end
    print("[SLG] Using difficultySetting:", difficultySetting)
    
    -- Determine which difficulties to show
    local showDifficulties = {
        ["base"] = false,
        ["25Man"] = false,
        ["Heroic"] = false,
        ["25ManHeroic"] = false
    }
    
    if difficultySetting == "Normal" then
        showDifficulties["base"] = true
    elseif difficultySetting == "25Man" then
        showDifficulties["25Man"] = true
    elseif difficultySetting == "Heroic" then
        showDifficulties["Heroic"] = true
    elseif difficultySetting == "25ManHeroic" then
        showDifficulties["25ManHeroic"] = true
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
    
    -- Modified boss iterator with debug
    local function boss_iter()
        local zoneData = SLG.ZoneItems[zoneName] or {}
        return pairs(zoneData)
    end
    
    local orderedSourceNames = {}
    local zoneData = SLG.ZoneItems[zoneName] or {}
    if zoneData.__order and type(zoneData.__order) == "table" then
        for _, name in ipairs(zoneData.__order) do
            table.insert(orderedSourceNames, name)
        end
        -- Optionally, add any keys not in __order at the end
        for k, _ in pairs(zoneData) do
            if k ~= "__order" then
                local found = false
                for _, v in ipairs(orderedSourceNames) do
                    if v == k then found = true break end
                end
                if not found then table.insert(orderedSourceNames, k) end
            end
        end
    else
        for k, _ in pairs(zoneData) do
            if k ~= "__order" then table.insert(orderedSourceNames, k) end
        end
    end

    for _, sourceName in ipairs(orderedSourceNames) do
        local itemIds = zoneData[sourceName]
        if sourceName ~= "__order" then
            local sourceDiff = sourceName:match("%(([^%)]+)%)")
            local sourceItems = {}
            
            local shouldShow = instanceType == "outdoor" or 
                           (not sourceDiff and showDifficulties["base"]) or
                           (sourceDiff and showDifficulties[sourceDiff])
            
            if shouldShow then
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
                
                -- Add source items to groups
                if #sourceItems > 0 then
                    sourceGroups[sourceName] = sourceItems
                end
            end
        end 
    end 
    
    -- Build final items list in the order of orderedSourceNames
    local allItems = {}
    for _, sourceName in ipairs(orderedSourceNames) do
        local sourceItems = sourceGroups[sourceName]
        if sourceItems and #sourceItems > 0 then
            table.insert(allItems, {
                isHeader = true,
                name = sourceName,
                source = sourceName
            })
            for _, itemData in ipairs(sourceItems) do
                if itemData.id then
                    table.insert(allItems, itemData)
                end
            end
        end
    end
    
    print("Total entries to display:", #allItems, "(", #allItems - #sourceGroups, "actual items)")
    
    -- Update UI
    if SLG.modules.ItemList then
        SLG.modules.ItemList:SetItems(allItems, stats)
    end
    
    return allItems, stats
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