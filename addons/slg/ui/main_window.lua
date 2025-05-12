local addonName, SLG = ...

-- Create the module
local MainWindow = {}
SLG:RegisterModule("MainWindow", MainWindow)

-- Initialize the module
function MainWindow:Initialize()
    self:CreateMainWindow()
    
    -- Initialize LDB
    self:InitializeLDB()
    
    -- Show window if auto-open is enabled
    if SLGSettings.autoOpen then
        self:Show()
    end
end

-- Create the main window
function MainWindow:CreateMainWindow()
    -- Create the main frame
    local frame = CreateFrame("Frame", "SLGFrame", UIParent)
    frame:SetSize(SLG.UI.MIN_WINDOW_WIDTH, SLG.UI.DEFAULT_WINDOW_HEIGHT)
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
        edgeFile = nil,
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
    titleBg:SetHeight(SLG.UI.TITLE_HEIGHT)
    titleBg:SetTexture(0, 0, 0, 0.5)
    
    -- Create title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 10, -8)
    title:SetText("Synastria Loot Guide")
    
    -- Create zone text
    local zoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneText:SetPoint("BOTTOM", titleBg, "BOTTOM", 0, 6)
    zoneText:SetPoint("LEFT", titleBg, "LEFT", 0, 0)
    zoneText:SetPoint("RIGHT", titleBg, "RIGHT", 0, 0)
    zoneText:SetJustifyH("CENTER")
    zoneText:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create progress text
    local progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOPRIGHT", titleBg, "TOPRIGHT", -40, -18)
    progressText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    progressText:SetTextColor(0, 0.95, 0.3)
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Create resize button
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    
    -- Add resize functionality
    local minWidth = SLG.UI.MIN_WINDOW_WIDTH
    local minHeight = SLG.UI.DEFAULT_WINDOW_HEIGHT
    
    -- Store the original anchor point
    local originalPoint, originalRelativeTo, originalRelativePoint, originalX, originalY = frame:GetPoint()
    
    -- Function to update content layout
    local function UpdateContentLayout()
        if not frame.scrollFrame then return end
        
        -- Update scroll frame size
        local newWidth = frame:GetWidth() - 24
        local newHeight = frame:GetHeight() - titleBg:GetHeight() - 55
        frame.scrollFrame:SetSize(newWidth, newHeight)
        
        -- Update content width to match scroll frame
        frame.content:SetWidth(newWidth)
        
        -- Update all item frames
        for _, child in ipairs({frame.content:GetChildren()}) do
            if child:IsShown() then
                -- Update source frames
                if child.toggleButton and child.toggleButton:IsShown() then
                    child:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, child:GetPoint(2))
                    child:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", 0, child:GetPoint(4))
                -- Update item frames
                else
                    child:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 8, child:GetPoint(2))
                    child:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, child:GetPoint(4))
                end
                
                -- Update text truncation
                if SLG.modules.Frames then
                    SLG.modules.Frames:UpdateTextTruncation(child)
                end
            end
        end
        
        -- Refresh the item list display
        if SLG.modules.ItemList then
            SLG.modules.ItemList:UpdateDisplay()
        end
    end
    
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:SetButtonState("PUSHED", true)
            
            -- Create a temporary frame to handle the resize
            local resizeFrame = CreateFrame("Frame", nil, UIParent)
            resizeFrame:SetScript("OnUpdate", function()
                -- Get the current mouse position relative to the frame
                local scale = frame:GetEffectiveScale()
                local x, y = GetCursorPosition()
                local frameX, frameY = frame:GetLeft() * scale, frame:GetTop() * scale
                
                -- Calculate new dimensions
                local newWidth = math.max(minWidth, (x - frameX) / scale)
                local newHeight = math.max(minHeight, (frameY - y) / scale)
                
                -- Set the new size
                frame:SetSize(newWidth, newHeight)
                
                -- Update content layout
                UpdateContentLayout()
            end)
            
            -- Store the resize frame for cleanup
            self.resizeFrame = resizeFrame
        end
    end)
    
    resizeButton:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:SetButtonState("NORMAL", false)
            if self.resizeFrame then
                self.resizeFrame:SetScript("OnUpdate", nil)
                self.resizeFrame = nil
            end
            -- Final layout update
            UpdateContentLayout()
        end
    end)
    
    -- Create scroll frame
    local scrollFrame, scrollBar, content = SLG.modules.Frames:CreateScrollFrame(
        frame,
        frame:GetWidth() - 24,
        frame:GetHeight() - titleBg:GetHeight() - 55
    )
    scrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, -8)
    
    -- Store references
    self.frame = frame
    self.titleBg = titleBg
    self.zoneText = zoneText
    self.progressText = progressText
    self.scrollFrame = scrollFrame
    self.scrollBar = scrollBar
    self.content = content
    self.resizeButton = resizeButton

    -- Ensure item list updates on resize
    frame:SetScript("OnSizeChanged", function()
        local frameWidth = frame:GetWidth()
        local frameHeight = frame:GetHeight()
        local newScrollWidth = frameWidth - 24
        local newScrollHeight = frameHeight - titleBg:GetHeight() - 55
        scrollFrame:SetWidth(newScrollWidth)
        scrollFrame:SetHeight(newScrollHeight)
        content:SetWidth(newScrollWidth)
        if SLG.modules.ItemList then
            SLG.modules.ItemList:UpdateDisplay()
        end
    end)

    -- Remove OnSizeChanged debug from content
    content:SetScript("OnSizeChanged", nil)
end

-- Initialize LDB
function MainWindow:InitializeLDB()
    local LDB = LibStub("LibDataBroker-1.1")
    
    -- Create the LDB object
    local ldbObj = LDB:NewDataObject("slg", {
        type = "launcher",
        text = "Synastria Loot Guide",
        icon = "Interface\\Icons\\INV_Misc_Bag_27",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:Toggle()
            elseif button == "RightButton" then
                InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
                InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Synastria Loot Guide")
            tooltip:AddLine("|cffffff00Left-click|r to toggle window", 1, 1, 1)
            tooltip:AddLine("|cffffff00Right-click|r for options", 1, 1, 1)
        end,
    })
end

-- Show the window
function MainWindow:Show()
    self.frame:Show()
    if SLG.modules.ItemList then
        SLG.modules.ItemList:UpdateDisplay()
    end
end

-- Hide the window
function MainWindow:Hide()
    self.frame:Hide()
end

-- Toggle the window
function MainWindow:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Return the module
return MainWindow 