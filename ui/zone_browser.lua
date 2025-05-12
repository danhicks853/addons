local addonName, SLG = ...

-- Create the module
local ZoneBrowser = {}
SLG:RegisterModule("ZoneBrowser", ZoneBrowser)

-- Initialize the module
function ZoneBrowser:Initialize()
    -- Create the browser window first
    self:CreateBrowserWindow()
    -- Then initialize LDB
    self:InitializeLDB()
end

-- Initialize LDB
function ZoneBrowser:InitializeLDB()
    local LDB = LibStub("LibDataBroker-1.1")
    
    -- Create the LDB object
    local ldbObj = LDB:NewDataObject("slg_zone_browser", {
        type = "launcher",
        text = "Synastria Loot Guide - Zone Browser",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        OnClick = function(_, button)
            if button == "LeftButton" then
                if SLG.modules.MainWindow then
                    SLG.modules.MainWindow:Toggle()
                end
            elseif button == "RightButton" then
                self:Toggle()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Synastria Loot Guide")
            tooltip:AddLine("|cffffff00Left-click|r to toggle main window", 1, 1, 1)
            tooltip:AddLine("|cffffff00Right-click|r to browse all zones", 1, 1, 1)
        end,
    })
end

-- Create the zone browser window
function ZoneBrowser:CreateBrowserWindow()
    -- Create the main frame
    local frame = CreateFrame("Frame", "SLGZoneFrame", UIParent)
    frame:SetSize(600, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not self.isLocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.isLocked then
            self:StopMovingOrSizing()
        end
    end)
    frame:Hide()
    
    -- Set frame backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 16, right = 16, top = 16, bottom = 16 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    
    -- Create title area
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    titleBg:SetHeight(40)
    titleBg:SetTexture(0, 0, 0, 0.5)
    
    -- Create title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", titleBg, "TOP", 0, -10)
    title:SetText("Browse All Zones")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    -- Hide any help buttons with a '?' texture
    local function HideHelpButtons(parent)
        for i = 1, select("#", parent:GetChildren()) do
            local child = select(i, parent:GetChildren())
            if child and child.GetNormalTexture then
                local tex = child:GetNormalTexture()
                if tex and tex.GetTexture and tex:GetTexture() then
                    local path = tex:GetTexture()
                    if type(path) == "string" and path:find("Help") then
                        child:Hide()
                        child:SetScript("OnClick", nil)
                    end
                end
            end
        end
    end
    HideHelpButtons(frame)
  
    -- Create the left panel for zone list
    local zoneListPanel = CreateFrame("Frame", nil, frame)
    zoneListPanel:SetSize(200, frame:GetHeight() - 70)
    zoneListPanel:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 8, -8)
    
    -- Create scroll frame for zones
    local zoneScrollFrame, zoneScrollBar, zoneContent = SLG.modules.Frames:CreateScrollFrame(
        zoneListPanel,
        zoneListPanel:GetWidth(),
        zoneListPanel:GetHeight()
    )
    zoneScrollFrame:SetPoint("TOPLEFT", zoneListPanel, "TOPLEFT", 0, 0)
    
    -- Create the right panel for items
    local itemPanel = CreateFrame("Frame", nil, frame)
    itemPanel:SetSize(frame:GetWidth() - zoneListPanel:GetWidth() - 40, frame:GetHeight() - 70)
    itemPanel:SetPoint("TOPLEFT", zoneListPanel, "TOPRIGHT", 8, 0)
    
    -- Create title for selected zone
    local selectedZoneText = itemPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedZoneText:SetPoint("TOPLEFT", itemPanel, "TOPLEFT", 10, -5)
    selectedZoneText:SetText("Select a Zone")
    selectedZoneText:SetTextColor(1, 0.82, 0)
    
    -- Create progress text for selected zone
    local selectedZoneProgress = itemPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedZoneProgress:SetPoint("TOPRIGHT", itemPanel, "TOPRIGHT", -10, -5)
    selectedZoneProgress:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    selectedZoneProgress:SetTextColor(0, 0.95, 0.3)
    
    -- Create scroll frame for items
    local itemScrollFrame, itemScrollBar, itemContent = SLG.modules.Frames:CreateScrollFrame(
        itemPanel,
        itemPanel:GetWidth(),
        itemPanel:GetHeight() - 30
    )
    itemScrollFrame:SetPoint("TOPLEFT", itemPanel, "TOPLEFT", 0, -30)
    
    -- Store references
    self.frame = frame
    self.zoneScrollFrame = zoneScrollFrame
    self.zoneContent = zoneContent
    self.zoneScrollBar = zoneScrollBar
    self.itemPanel = itemPanel
    self.itemScrollFrame = itemScrollFrame
    self.itemContent = itemContent
    self.itemScrollBar = itemScrollBar
    self.selectedZoneText = selectedZoneText
    self.selectedZoneProgress = selectedZoneProgress
end

-- Update the zone list
function ZoneBrowser:UpdateZoneList()
    -- Clear existing content
    for _, child in ipairs({self.zoneContent:GetChildren()}) do
        child:Hide()
    end
    
    local totalHeight = 0
    local padding = 2
    local buttonHeight = 18
    local headerHeight = 25
    local indent = 15
    
    -- Create category headers and zone buttons
    for _, category in ipairs({"CLASSIC", "TBC", "WOTLK"}) do
        local categoryInfo = SLG.ZoneCategories[category]
        if categoryInfo then
            -- Create category header
            local header = CreateFrame("Button", nil, self.zoneContent)
            header:SetSize(self.zoneScrollFrame:GetWidth() - 20, headerHeight)
            header:SetPoint("TOPLEFT", self.zoneContent, "TOPLEFT", 0, -totalHeight)
            
            -- Create header background
            local headerBg = header:CreateTexture(nil, "BACKGROUND")
            headerBg:SetAllPoints()
            headerBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            headerBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
            
            -- Create header text
            local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            headerText:SetPoint("LEFT", header, "LEFT", 5, 0)
            headerText:SetText(categoryInfo.name)
            headerText:SetTextColor(1, 0.82, 0)
            
            totalHeight = totalHeight + headerHeight + padding
            
            -- Create buttons for each zone in this category
            for _, zoneName in ipairs(categoryInfo.zones) do
                if SLG.ZoneItems[zoneName] then  -- Only create button if zone has items
                    local button = CreateFrame("Button", nil, self.zoneContent)
                    button:SetSize(self.zoneScrollFrame:GetWidth() - 20 - indent, buttonHeight)
                    button:SetPoint("TOPLEFT", self.zoneContent, "TOPLEFT", indent, -totalHeight)
                    
                    -- Create highlight texture
                    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
                    highlightTexture:SetAllPoints()
                    highlightTexture:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    highlightTexture:SetBlendMode("ADD")
                    
                    -- Create zone text
                    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    text:SetPoint("LEFT", button, "LEFT", 5, 0)
                    text:SetPoint("RIGHT", button, "RIGHT", -5, 0)
                    text:SetJustifyH("LEFT")
                    text:SetText(zoneName)
                    
                    button:SetScript("OnClick", function()
                        -- Update the browser window to show items for this zone
                        self:ShowZoneItems(zoneName)
                        -- Highlight the selected zone
                        self:HighlightSelectedZone(button)
                    end)
                    
                    totalHeight = totalHeight + buttonHeight + padding
                end
            end
            
            -- Add extra padding after each category
            totalHeight = totalHeight + padding * 2
        end
    end
    
    -- Update content height and scroll range
    self.zoneContent:SetHeight(math.max(totalHeight, self.zoneScrollFrame:GetHeight()))
    local maxScroll = math.max(0, totalHeight - self.zoneScrollFrame:GetHeight())
    self.zoneScrollBar:SetMinMaxValues(0, maxScroll)
end

-- Show items for a specific zone
function ZoneBrowser:ShowZoneItems(zoneName)
    -- Update the selected zone text
    self.selectedZoneText:SetText(zoneName)
    
    -- Get items for the selected zone - force showAll mode
    local originalMode = SLGSettings.displayMode
    SLGSettings.displayMode = "all"
    local sourceGroups, stats = SLG.modules.ZoneManager:GetZoneItems(zoneName, nil, true)
    SLGSettings.displayMode = originalMode
    
    -- Update progress text
    self.selectedZoneProgress:SetText(string.format("%d/%d", stats.listAttuned, stats.listTotal))
    
    -- Clear existing items
    for _, child in ipairs({self.itemContent:GetChildren()}) do
        child:Hide()
    end
    
    -- Display items
    local totalHeight = 0
    local padding = 1
    local sourceHeight = SLG.UI.SOURCE_HEIGHT
    local itemHeight = SLG.UI.ITEM_HEIGHT
    
    if stats.listTotal > 0 and stats.listAttuned == stats.listTotal then
        local messageFrame = SLG.modules.Frames:GetFrame()
        messageFrame:SetParent(self.itemContent)
        messageFrame:SetPoint("TOP", self.itemContent, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        messageFrame.nameText:SetText("All items attuned!")
        messageFrame.nameText:SetTextColor(SLG.Colors.ATTUNED.r, SLG.Colors.ATTUNED.g, SLG.Colors.ATTUNED.b)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        messageFrame:Show()
        
        self.itemContent:SetHeight(60)
        local maxScroll = math.max(0, 60 - self.itemScrollFrame:GetHeight())
        self.itemScrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    if not sourceGroups or #sourceGroups == 0 then
        local messageFrame = SLG.modules.Frames:GetFrame()
        messageFrame:SetParent(self.itemContent)
        messageFrame:SetPoint("TOP", self.itemContent, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        messageFrame.nameText:SetText("No attunable items found in this zone")
        messageFrame.nameText:SetTextColor(0.8, 0.8, 0.8)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        messageFrame:Show()
        
        self.itemContent:SetHeight(60)
        local maxScroll = math.max(0, 60 - self.itemScrollFrame:GetHeight())
        self.itemScrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    -- Create frames for each source and its items
    for _, sourceGroup in ipairs(sourceGroups) do
        -- Create source header
        local sourceFrame = SLG.modules.Frames:GetFrame(true)
        sourceFrame:SetParent(self.itemContent)
        sourceFrame:SetPoint("TOPLEFT", self.itemContent, "TOPLEFT", 0, -totalHeight)
        sourceFrame:SetPoint("TOPRIGHT", self.itemContent, "TOPRIGHT", 0, -totalHeight)
        sourceFrame:SetHeight(sourceHeight)
        
        sourceFrame.nameText:SetText(sourceGroup.source)
        sourceFrame.nameText:SetTextColor(SLG.Colors.SOURCE.r, SLG.Colors.SOURCE.g, SLG.Colors.SOURCE.b)
        sourceFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        sourceFrame.statusText:Hide()
        
        -- Ensure items table is initialized
        if not sourceFrame.items then
            sourceFrame.items = {}
        end
        -- Set toggle button to minus if present
        if sourceFrame.toggleButton then
            sourceFrame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        end
        sourceFrame:Show()
        
        totalHeight = totalHeight + sourceHeight + padding
        
        -- Create frames for items
        if sourceGroup and sourceGroup.items and type(sourceGroup.items) == "table" then
            for idx, item in ipairs(sourceGroup.items) do
                local itemFrame = SLG.modules.Frames:GetFrame(false)
                itemFrame:SetParent(self.itemContent)
                itemFrame:SetPoint("TOPLEFT", self.itemContent, "TOPLEFT", 8, -totalHeight)
                itemFrame:SetPoint("TOPRIGHT", self.itemContent, "TOPRIGHT", -28, -totalHeight)
                itemFrame:SetHeight(itemHeight)
                itemFrame:EnableMouse(true)
                
                if idx % 2 == 0 then
                    itemFrame.bg:SetTexture(0.13, 0.13, 0.13, 0.7)
                else
                    itemFrame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
                end
                
                itemFrame.nameText:SetText(item.name and item.name ~= "" and item.name or ("Item %d"):format(item.id))
                
                -- Get status text and color
                local statusText, statusColor = SLG.modules.Attunement:GetStatusText(item.id, nil) -- Pass nil to omit itemType from status
                itemFrame.statusText:SetText(statusText)
                itemFrame.statusText:SetTextColor(statusColor.r, statusColor.g, statusColor.b)
                
                itemFrame.itemID = item.id
                
                -- Set up tooltip
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
    self.itemContent:SetHeight(totalHeight)
    local maxScroll = math.max(0, totalHeight - self.itemScrollFrame:GetHeight())
    self.itemScrollBar:SetMinMaxValues(0, maxScroll)
end

-- Highlight the selected zone
function ZoneBrowser:HighlightSelectedZone(selectedButton)
    -- Remove highlight from all buttons
    for _, child in ipairs({self.zoneContent:GetChildren()}) do
        if child:GetObjectType() == "Button" then
            child:UnlockHighlight()
        end
    end
    -- Highlight the selected button
    selectedButton:LockHighlight()
end

-- Show the window
function ZoneBrowser:Show()
    if not self.frame then
        self:CreateBrowserWindow()
    end
    self.frame:Show()
    self:UpdateZoneList()
end

-- Hide the window
function ZoneBrowser:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle the window
function ZoneBrowser:Toggle()
    if not self.frame then
        self:Show()
    elseif self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Return the module
return ZoneBrowser 