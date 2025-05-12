SLASH_SLGDEBUGITEM1 = "/slgdebugitem"
SlashCmdList["SLGDEBUGITEM"] = function(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        
        return
    end
    
    -- Wrath Classic compatible async loading
    local name = GetItemInfo(itemId)
    if name then
        SLG_DebugShowItemData(itemId)
    else
        
        local waitFrame = CreateFrame("Frame")
        waitFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        waitFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "GET_ITEM_INFO_RECEIVED" and ... == itemId then
                SLG_DebugShowItemData(itemId)
                self:UnregisterAllEvents()
            end
        end)
    end
end

function SLG_DebugShowItemData(itemId)
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, 
          equipSlot, texture, vendorPrice, classID, subclassID = GetItemInfo(itemId)
    
    if not name then
        
        return
    end
    
    -- Wrath Classic compatible bind type detection
    local bindType = select(14, GetItemInfo(itemId))  -- Returns bindType (1-4)
    
    -- Handle nil values
    classID = classID or "N/A"
    subclassID = subclassID or "N/A"
    bindType = bindType or "N/A"
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    -- Scan tooltip for class requirements
    local tooltipScanner = CreateFrame("GameTooltip", "SLG_DebugTooltip", nil, "GameTooltipTemplate")
    tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltipScanner:SetHyperlink(link)
    
    local classRequirements = {}
    for i=2, tooltipScanner:NumLines() do
        local line = _G["SLG_DebugTooltipTextLeft"..i]
        local text = line:GetText() or ""
        
        if text:find("Classes: ") then
            for class in text:gmatch("([^,]+)") do
                class = class:gsub("Classes: ", ""):trim()
                if class ~= "" then
                    table.insert(classRequirements, class)
                end
            end
        end
    end
    tooltipScanner:Hide()
    
    
end

SLASH_CHECKVENDORCLASS1 = "/checkvendorclass"
SlashCmdList["CHECKVENDORCLASS"] = function()
    if not MerchantFrame:IsShown() then
        
        return
    end

    local _, class = UnitClass("player")
    local faction = UnitFactionGroup("player")
    local hiddenItems = {}

    -- Enable debug mode temporarily
    local prevDebug = SLG_DEBUG
    SLG_DEBUG = true

    for i=1,GetMerchantNumItems() do
        local itemLink = GetMerchantItemLink(i)
        if itemLink then
            local itemId = GetItemInfoFromHyperlink(itemLink)
            local itemData = ItemManager:GetItemData(itemId)
            
            if itemData then
                local filters = {}
                
                -- Class check
                if itemData.classes and not tContains(itemData.classes, class:upper()) then
                    table.insert(filters, "class")
                end
                
                -- Faction check
                if itemData.faction and itemData.faction ~= faction then
                    table.insert(filters, "faction")
                end
                
                -- Attunement check
                if itemData.attunement and not Attunement:IsAttunedForItem(itemId) then
                    table.insert(filters, "attunement")
                end
                
                -- Level requirement check
                local playerLevel = UnitLevel("player")
                if itemData.minLevel and playerLevel < itemData.minLevel then
                    table.insert(filters, "level")
                end
                
                if #filters > 0 then
                    table.insert(hiddenItems, {
                        id = itemId,
                        name = GetItemInfo(itemId),
                        filters = filters
                    })
                end
            else
                
            end
        end
    end

    SLG_DEBUG = prevDebug

    if #hiddenItems > 0 then
        
        for _, item in ipairs(hiddenItems) do
            
        end
    end
end