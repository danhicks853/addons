SLASH_SLGDEBUGITEM1 = "/slgdebugitem"
SlashCmdList["SLGDEBUGITEM"] = function(itemId)
    itemId = tonumber(itemId)
    if not itemId then
        print("|cFFFF0000Invalid item ID|r")
        return
    end
    
    -- Wrath Classic compatible async loading
    local name = GetItemInfo(itemId)
    if name then
        SLG_DebugShowItemData(itemId)
    else
        print("|cFFFFFF00Requesting item data from server...|r")
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
        print("|cFFFF0000Failed to load data for item", itemId,"|r")
        return
    end
    
    -- Wrath Classic compatible bind type detection
    local bindType = select(14, GetItemInfo(itemId))  -- Returns bindType (1-4)
    
    -- Handle nil values
    classID = classID or "N/A"
    subclassID = subclassID or "N/A"
    bindType = bindType or "N/A"
    
    print("|cFF00FF00Raw Client Data for Item", itemId,"|r")
    print("Name:", name)
    print("Link:", link)
    print("Quality:", quality, _G["ITEM_QUALITY"..quality.."_DESC"])
    print("Item Level:", iLevel)
    print("Required Level:", reqLevel)
    print("Class:", class, "(ID:", classID..")")
    print("Subclass:", subclass, "(ID:", subclassID..")")
    print("Equip Slot:", _G[equipSlot] or equipSlot)
    print("Bind Type:", bindType, "(", (bindType ~= "N/A" and _G["ITEM_BIND_"..bindType]) or "Unknown", ")")
    print("Texture:", texture)
    print("Vendor Price:", vendorPrice)
    
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
    
    print("|cFF00FF00Class Requirements:|r", #classRequirements > 0 and table.concat(classRequirements, ", ") or "None")
end

SLASH_CHECKVENDORCLASS1 = "/checkvendorclass"
SlashCmdList["CHECKVENDORCLASS"] = function()
    if not MerchantFrame:IsShown() then
        print("Open vendor window first!")
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
                print("No data found for item:", itemLink)
            end
        end
    end

    SLG_DEBUG = prevDebug

    if #hiddenItems > 0 then
        print(format("Hidden items at vendor (%s/%s):", class, faction))
        for _, item in ipairs(hiddenItems) do
            print(format("  %s (ID: %d) - Filters: %s",
                item.name, item.id, table.concat(item.filters, ", ")))
        end
    else
        print("No hidden items found at this vendor")
    end
end