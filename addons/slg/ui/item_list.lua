local addonName, SLG = ...


-- Create the module
local ItemList = {}
SLG:RegisterModule("ItemList", ItemList)

-- Initialize the module
function ItemList:Initialize()
    -- Nothing to initialize yet
end

-- Update the item list display
function ItemList:UpdateDisplay()

    local MainWindow = SLG.modules.MainWindow
    if not MainWindow or not MainWindow.frame:IsShown() then return end
    
    local currentZone = GetRealZoneText()

    
    -- Force content frame width to match scroll frame
    if MainWindow.scrollFrame and MainWindow.content then
        local sw = MainWindow.scrollFrame:GetWidth()
        MainWindow.content:SetWidth(sw)
    end
    
    -- Clear existing content
    for _, child in ipairs({MainWindow.content:GetChildren()}) do
        child:Hide()
    end
    
    -- Update zone text
    local currentZone = GetRealZoneText()
    MainWindow.zoneText:SetText(currentZone)
    
    -- Get items for current zone
    local sourceGroups, stats = SLG.modules.ZoneManager:GetZoneItems(currentZone)

    
    -- Update progress text
    MainWindow.progressText:SetText(string.format("%d/%d", stats.attuned, stats.total))
    
    -- Display items
    local totalHeight = 0
    local padding = 1
    local sourceHeight = SLG.UI.SOURCE_HEIGHT
    local itemHeight = SLG.UI.ITEM_HEIGHT
    
    if stats.total > 0 and stats.attuned == stats.total then
        local messageFrame = SLG.modules.Frames:GetFrame()
        messageFrame:SetParent(MainWindow.content)
        messageFrame:SetPoint("TOP", MainWindow.content, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        messageFrame.nameText:SetText("All items attuned!")
        messageFrame.nameText:SetTextColor(SLG.Colors.ATTUNED.r, SLG.Colors.ATTUNED.g, SLG.Colors.ATTUNED.b)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        messageFrame:Show()
        
        MainWindow.content:SetHeight(60)
        local maxScroll = math.max(0, 60 - MainWindow.scrollFrame:GetHeight())
        MainWindow.scrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    if not sourceGroups or #sourceGroups == 0 then
        local messageFrame = SLG.modules.Frames:GetFrame()
        messageFrame:SetParent(MainWindow.content)
        messageFrame:SetPoint("TOP", MainWindow.content, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        messageFrame.nameText:SetText("No attunable items found in this zone")
        messageFrame.nameText:SetTextColor(0.8, 0.8, 0.8)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        messageFrame:Show()
        
        MainWindow.content:SetHeight(60)
        local maxScroll = math.max(0, 60 - MainWindow.scrollFrame:GetHeight())
        MainWindow.scrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    -- Create frames for each source and its items
    for _, sourceGroup in ipairs(sourceGroups) do
        -- Create source header
        local sourceFrame = SLG.modules.Frames:GetFrame(true)
        sourceFrame:SetParent(MainWindow.content)
        sourceFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", 0, -totalHeight)
        sourceFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", 0, -totalHeight)
        sourceFrame:SetHeight(sourceHeight)
        
        -- Category shading for source frame
        sourceFrame.bg:SetTexture(0.18, 0.18, 0.22, 0.95) -- subtle dark blue-gray
        
        sourceFrame.nameText:SetText(sourceGroup.source)
        sourceFrame.nameText:SetTextColor(SLG.Colors.SOURCE.r, SLG.Colors.SOURCE.g, SLG.Colors.SOURCE.b)
        sourceFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        sourceFrame.statusText:Hide()

        -- Make the sourceFrame clickable
        sourceFrame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                local npcName = sourceGroup.source
                -- Extract base NPC name if difficulty is present (e.g., "Boss Name (Heroic)")
                npcName = npcName:match("([^%(]+)") or npcName
                npcName = npcName:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
                SendChatMessage(".findnpc " .. npcName)
            end
        end)
        
        -- Ensure items table is initialized
        if not sourceFrame.items then
            sourceFrame.items = {}
        end
        -- Set toggle button state based on collapsedSources
        if sourceFrame.toggleButton then
            if SLG.collapsedSources and SLG.collapsedSources[sourceGroup.source] then
                sourceFrame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
                sourceFrame.toggleButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
            else
                sourceFrame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
                sourceFrame.toggleButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
            end
        end
        sourceFrame:Show()
        
        totalHeight = totalHeight + sourceHeight + padding
        
        -- Only show items if not collapsed
        if not (SLG.collapsedSources and SLG.collapsedSources[sourceGroup.source]) then
            -- Create frames for items
            for idx, item in ipairs(sourceGroup.items) do
                local itemFrame = SLG.modules.Frames:GetFrame(false)
                itemFrame:SetParent(MainWindow.content)
                itemFrame.itemID = item.id
                itemFrame:EnableMouse(true)
                itemFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", 8, -totalHeight)
                itemFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", -10, -totalHeight)
                itemFrame:SetHeight(itemHeight)
                
                -- Zebra shading for item frames
                if idx % 2 == 0 then
                    itemFrame.bg:SetTexture(0.13, 0.13, 0.13, 0.7)
                else
                    itemFrame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
                end
                
                -- Explicitly set width to fill available space
                local parentWidth = itemFrame:GetParent():GetWidth() or 0
                local leftPad, rightPad = 8, 10
                itemFrame:SetWidth(parentWidth - leftPad - rightPad)
                itemFrame:ClearAllPoints()
                itemFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", leftPad, -totalHeight)
                itemFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", -rightPad, -totalHeight)

                -- Set statusText to a fixed width
                local statusTextWidth = 100 -- Increased width
                itemFrame.statusText:SetWidth(statusTextWidth)
                itemFrame.statusText:SetWordWrap(false) -- Disable word wrap
                itemFrame.statusText:SetNonSpaceWrap(false) -- Disable non-space wrap
                itemFrame.statusText:ClearAllPoints()
                itemFrame.statusText:SetPoint("RIGHT", itemFrame, "RIGHT", -5, 0)
                itemFrame.statusText:SetJustifyH("RIGHT")

                -- Set nameText to fill remaining space
                local namePadding = 10
                local nameWidth = math.max(50, itemFrame:GetWidth() - statusTextWidth - namePadding)
                itemFrame.nameText:SetWidth(nameWidth)
                itemFrame.nameText:ClearAllPoints()
                itemFrame.nameText:SetPoint("LEFT", itemFrame, "LEFT", 5, 0)
                itemFrame.nameText:SetPoint("RIGHT", itemFrame.statusText, "LEFT", -5, 0)
                itemFrame.nameText:SetJustifyH("LEFT")
                itemFrame.nameText:SetWordWrap(false)
                itemFrame.nameText:SetNonSpaceWrap(false)
                

                
                -- Set nameText to item name
                itemFrame.nameText:SetText(item.name and item.name ~= "" and item.name or ("Item %d"):format(item.id))

                -- Get attunement status
                local itemData = SLG.modules.ItemManager:GetItemData(item.id)
                local itemType = itemData and itemData.itemType or "" -- Default to empty string if no data
                local statusText, statusColor = SLG.modules.Attunement:GetStatusText(item.id, itemType)

                if statusText == itemType then -- Only add slot info if not attuned/looted
                    local typeText = itemType
                    local slotText = ""

                    -- Define item types that should not have slot text appended
                    local noSlotTextTypes = {
                        SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.TWOHAND_SWORD,
                        SLG.ItemTypes.WEAPON.ONEHAND_AXE, SLG.ItemTypes.WEAPON.TWOHAND_AXE,
                        SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                        SLG.ItemTypes.WEAPON.DAGGER, SLG.ItemTypes.WEAPON.FIST,
                        SLG.ItemTypes.WEAPON.POLEARM, SLG.ItemTypes.WEAPON.STAFF,
                        SLG.ItemTypes.WEAPON.BOW, SLG.ItemTypes.WEAPON.CROSSBOW,
                        SLG.ItemTypes.WEAPON.GUN, SLG.ItemTypes.WEAPON.WAND,
                        SLG.ItemTypes.WEAPON.SHIELD, -- Shields are listed under WEAPON in constants
                        SLG.ItemTypes.ACCESSORY.NECK,
                        SLG.ItemTypes.ACCESSORY.TRINKET,
                        SLG.ItemTypes.ACCESSORY.CLOAK
                        -- Rings are often "Finger 1", "Finger 2", so they might still need slot info.
                        -- Let's exclude rings from this list for now.
                    }

                    local shouldAddSlotText = true
                    for _, noSlotType in ipairs(noSlotTextTypes) do
                        if itemType == noSlotType then
                            shouldAddSlotText = false
                            break
                        end
                    end

                    if shouldAddSlotText and item.equipSlot and item.equipSlot ~= "" then
                        local slotNames = {
                            INVTYPE_HEAD = "Head",
                            INVTYPE_NECK = "Neck",
                            INVTYPE_SHOULDER = "Shoulder",
                            INVTYPE_BODY = "Shirt",
                            INVTYPE_CHEST = "Chest",
                            INVTYPE_ROBE = "Chest",
                            INVTYPE_WAIST = "Waist",
                            INVTYPE_LEGS = "Legs",
                            INVTYPE_FEET = "Feet",
                            INVTYPE_WRIST = "Wrist",
                            INVTYPE_HAND = "Hands",
                            INVTYPE_FINGER = "Finger", -- Kept for rings
                            INVTYPE_TRINKET = "Trinket",
                            INVTYPE_CLOAK = "Back",
                            INVTYPE_TABARD = "Tabard",
                            INVTYPE_HOLDABLE = "Off-hand",
                            INVTYPE_SHIELD = "Shield",
                            INVTYPE_RANGED = "Ranged",
                            INVTYPE_RANGEDRIGHT = "Ranged",
                            INVTYPE_WEAPONMAINHAND = "Main Hand",
                            INVTYPE_WEAPONOFFHAND = "Off Hand",
                            INVTYPE_2HWEAPON = "Two-Hand",
                            INVTYPE_WEAPON = "One-Hand",
                            INVTYPE_THROWN = "Thrown",
                            INVTYPE_RELIC = "Relic",
                        }
                        local slotName = slotNames[item.equipSlot]
                        if slotName then
                            slotText = slotName
                        end
                    end

                    if slotText ~= "" then
                        itemFrame.statusText:SetText(string.format("%s %s", typeText, slotText))
                    else
                        itemFrame.statusText:SetText(typeText)
                    end
                else
                    itemFrame.statusText:SetText(statusText)
                    if statusColor then
                        itemFrame.statusText:SetTextColor(statusColor.r, statusColor.g, statusColor.b)
                    else
                        itemFrame.statusText:SetTextColor(SLG.Colors.NOT_ATTUNED.r, SLG.Colors.NOT_ATTUNED.g, SLG.Colors.NOT_ATTUNED.b)
                    end
                end
                
                itemFrame:SetScript("OnEnter", function(self)

                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. self.itemID)
                    GameTooltip:AddLine("Source: " .. sourceGroup.source, 1, 1, 1)
                    GameTooltip:Show()
                end)
                itemFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                
                -- Ensure items table exists before inserting
                if not sourceFrame.items then
                    sourceFrame.items = {}
                end
                table.insert(sourceFrame.items, itemFrame)
                itemFrame:Show()
                totalHeight = totalHeight + itemHeight + padding
            end
        end
        totalHeight = totalHeight + padding * 2
    end
    
    -- Update content height and scroll range
    MainWindow.content:SetHeight(totalHeight)
    local maxScroll = math.max(0, totalHeight - MainWindow.scrollFrame:GetHeight())
    MainWindow.scrollBar:SetMinMaxValues(0, maxScroll)
end

-- Return the module
return ItemList 