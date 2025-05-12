local addonName, SLG = ...

-- Create the module
local ItemList = {}
SLG:RegisterModule("ItemList", ItemList)

-- Initialize the module
function ItemList:Initialize()
    self.items = {}
    self.stats = {}
    self.buttons = {}
    
    -- Create main container frame
    self.frame = CreateFrame("Frame", "SLGItemListFrame", UIParent)
    self.frame:SetSize(400, 500)
    
    -- Create scroll frame
    self.scrollFrame = CreateFrame("ScrollFrame", "SLGItemListScrollFrame", self.frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 10, -10)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    -- Create scroll child
    self.scrollChild = CreateFrame("Frame")
    self.scrollChild:SetSize(380, 500)
    self.scrollFrame:SetScrollChild(self.scrollChild)
    
    print("ItemList initialized with scrollFrame")
end

-- Update the item list display
function ItemList:UpdateDisplay()
    local MainWindow = SLG.modules.MainWindow
    if not MainWindow or not MainWindow.frame:IsShown() then return end
    
    -- Check if zone is implemented
    local currentZone = GetRealZoneText()
    if not SLG.ZoneItems[currentZone] then
        print(string.format("|cffff0000%s has not yet been implemented in Synastria Loot Guide|r", currentZone))
        MainWindow.content:SetHeight(0)
        MainWindow.scrollBar:SetMinMaxValues(0, 0)
        return
    end
    
    local SCROLLBAR_WIDTH = 20
    
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
    MainWindow.zoneText:SetText(currentZone)
    
    -- Get current difficulty from settings
    local currentDifficulty = SLGSettings.currentDifficulty or "Normal"
    
    -- Get items for current zone
    local sourceGroups, stats = SLG.modules.ZoneManager:GetZoneItems(currentZone, currentDifficulty)
    
    -- Update progress text
    local mode = SLGSettings.displayMode or SLG.DisplayModes.NOT_ATTUNED
    if mode == "not_attuned" then
        MainWindow.progressText:SetText(stats.zoneAttuned and stats.zoneEligible and string.format("%d/%d", stats.zoneAttuned, stats.zoneEligible) or "-")
    else
        MainWindow.progressText:SetText(stats.listAttuned and stats.listTotal and string.format("%d/%d", stats.listAttuned, stats.listTotal) or "-")
    end
    
    -- Display items
    local totalHeight = 0
    local padding = 1
    local sourceHeight = SLG.UI.SOURCE_HEIGHT
    local itemHeight = SLG.UI.ITEM_HEIGHT
    
    if (stats.listTotal or 0) > 0 and (stats.listAttuned or 0) == (stats.listTotal or 0) then
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

    -- Flat iteration over items and headers
    if not self.items then return end
    local yOffset = 0
    for i, entry in ipairs(self.items) do
        if entry.isHeader then
            -- Create and display a header frame
            local headerFrame = SLG.modules.Frames:GetFrame(true)
            headerFrame:SetParent(MainWindow.content)
            headerFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", 0, -yOffset)
            headerFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", 0, -yOffset)
            headerFrame:SetHeight(sourceHeight)
            headerFrame.bg:SetTexture(0.18, 0.18, 0.22, 0.95)
            headerFrame.nameText:SetText(entry.name)
            headerFrame.nameText:SetTextColor(SLG.Colors.SOURCE.r, SLG.Colors.SOURCE.g, SLG.Colors.SOURCE.b)
            headerFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            headerFrame.statusText:Hide()
            headerFrame:Show()
            yOffset = yOffset + sourceHeight + padding
        elseif entry.id then
            -- Create and display an item frame
            local itemFrame = SLG.modules.Frames:GetFrame(false)
            itemFrame:SetParent(MainWindow.content)
            itemFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", 8, -yOffset)
            itemFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", -10, -yOffset)
            itemFrame:SetHeight(itemHeight)
            -- Zebra shading for item frames
            if i % 2 == 0 then
                itemFrame.bg:SetTexture(0.13, 0.13, 0.13, 0.7)
            else
                itemFrame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
            end
            -- Explicitly set width to fill available space
            local parentWidth = itemFrame:GetParent():GetWidth() or 0
            local leftPad, rightPad = 8, 10
            itemFrame:SetWidth(parentWidth - leftPad - rightPad - SCROLLBAR_WIDTH)
            itemFrame:ClearAllPoints()
            itemFrame:SetPoint("TOPLEFT", MainWindow.content, "TOPLEFT", leftPad, -yOffset)
            itemFrame:SetPoint("TOPRIGHT", MainWindow.content, "TOPRIGHT", -(rightPad + SCROLLBAR_WIDTH), -yOffset)
            -- Set statusText to a fixed width
            local statusTextWidth = 60
            itemFrame.statusText:SetWidth(statusTextWidth)
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
            itemFrame.nameText:SetText(entry.name and entry.name ~= "" and entry.name or ("Item %d"):format(entry.id))
            -- Get status text and color
            local statusText, statusColor = SLG.modules.Attunement:GetStatusText(entry.id, nil)
            itemFrame.statusText:SetText(statusText)
            itemFrame.statusText:SetTextColor(statusColor.r, statusColor.g, statusColor.b)
            itemFrame.itemID = entry.id
            -- Set up tooltip
            itemFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. self.itemID)
                GameTooltip:AddLine("Source: " .. (entry.source or ""), 1, 1, 1)
                GameTooltip:Show()
            end)
            itemFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            itemFrame:Show()
            yOffset = yOffset + SLG.UI.ITEM_HEIGHT + 1
        end
    end
    MainWindow.content:SetHeight(yOffset)
    local maxScroll = math.max(0, yOffset - MainWindow.scrollFrame:GetHeight())
    MainWindow.scrollBar:SetMinMaxValues(0, maxScroll)
end

function ItemList:SetItems(items, stats)
    print("==== ITEM LIST SET ====")
    print("Received items:", #items)
    
    self.items = items
    self.stats = stats
    
    -- Verify and initialize UI if needed
    if not self.frame or not self.scrollFrame then
        print("Initializing UI components")
        self:Initialize()
    end
    
    -- Show frame if hidden
    if not self.frame:IsShown() then
        print("Showing ItemList frame")
        self.frame:Show()
    end
    
    self:UpdateList()
end

function ItemList:UpdateList()
    -- Verify UI components exist
    if not self.scrollFrame then
        print("ERROR: scrollFrame missing - reinitializing")
        self:Initialize()
        if not self.scrollFrame then
            print("CRITICAL: Failed to initialize scrollFrame")
            return
        end
    end
    
    print("==== UI DEBUG ====")
    print("Frame exists:", self.frame and true or false)
    print("scrollFrame exists:", self.scrollFrame and true or false)
    
    -- Clear existing items
    for i = 1, #self.buttons do
        if self.buttons[i] then
            self.buttons[i]:Hide()
        end
    end
    
    if #self.items == 0 then
        print("WARNING: Empty items list passed to UI")
        return
    end
    
    -- Create/update buttons using existing method
    for i, item in ipairs(self.items) do
        if not self.buttons[i] then
            self.buttons[i] = self:CreateButton()  -- Using original CreateButton method
            if not self.buttons[i] then
                print("ERROR: Failed to create button for item", i)
                break
            end
        end
        
        self.buttons[i]:Update(item)
        self.buttons[i]:Show()
    end
    
    print("Updated", #self.items, "items in UI")
    print("================")
end

function ItemList:CreateButton()
    if not self.scrollChild then
        print("ERROR: scrollChild missing in CreateButton")
        return nil
    end
    
    local button = CreateFrame("Button", nil, self.scrollChild)
    button:SetSize(380, 40)
    
    -- Item icon
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(32, 32)
    button.icon:SetPoint("LEFT", 5, 0)
    
    -- Item name
    button.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.name:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
    button.name:SetJustifyH("LEFT")
    
    -- Update function
    function button:Update(item)
        if not item or not item.id then return end
        
        local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(item.id)
        self.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
        self.name:SetText(item.name or "Unknown Item")
        
        self:SetScript("OnEnter", function() 
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(item.id)
            GameTooltip:Show() 
        end)
        
        self:SetScript("OnLeave", function() 
            GameTooltip:Hide() 
        end)
    end
    
    print("Created new item button")
    return button
end

-- Add to module definition
ItemList.CreateButton = ItemList.CreateButton

-- Return the module
return ItemList 