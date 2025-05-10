local addonName, SLG = ...

-- Create the module
local Frames = {}
SLG:RegisterModule("Frames", Frames)

-- Frame pool
local framePool = {}

-- Constants for text truncation
local STATUS_TEXT_PADDING = 10  -- Padding between name and status text
local MIN_NAME_WIDTH = 50       -- Minimum width for name text

-- Collapsed state tracking for sources
SLG.collapsedSources = SLG.collapsedSources or {}

-- Initialize the module
function Frames:Initialize()
    -- Nothing to initialize yet
end

-- Calculate available width for name text
function Frames:CalculateNameWidth(frame)
    local frameWidth = frame:GetWidth()
    local statusWidth = frame.statusText:GetText() and frame.statusText:GetStringWidth() or 0
    local availableWidth = frameWidth - statusWidth - STATUS_TEXT_PADDING
    
    -- Account for toggle button if present
    if frame.toggleButton and frame.toggleButton:IsShown() then
        availableWidth = availableWidth - 25  -- 25 pixels for toggle button and padding
    end
    
    return math.max(MIN_NAME_WIDTH, availableWidth)
end

-- Update text truncation for a frame
function Frames:UpdateTextTruncation(frame)
    if not frame.nameText then return end
    
    local maxWidth = self:CalculateNameWidth(frame)
    frame.nameText:SetWidth(maxWidth)
    frame.nameText:SetWordWrap(false)
    frame.nameText:SetNonSpaceWrap(false)
end

-- Get a frame from the pool or create a new one
function Frames:GetFrame(isSource)
    -- Try to reuse an existing frame of the correct type
    for _, frame in ipairs(framePool) do
        if not frame:IsShown() and frame.isSource == isSource then
            self:ResetFrame(frame, isSource)
            return frame
        end
    end
    
    -- Create a new frame if none are available
    local frame = self:CreateFrame(isSource)
    table.insert(framePool, frame)
    return frame
end

-- Reset a frame to its default state
function Frames:ResetFrame(frame, isSource)
    frame:Hide()
    frame:SetParent(nil)
    frame:ClearAllPoints()
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    frame.isSource = isSource
    
    frame.nameText:SetText("")
    frame.nameText:SetTextColor(1, 1, 1)
    frame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11)
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:ClearAllPoints()
    frame.nameText:SetWordWrap(false)
    frame.nameText:SetNonSpaceWrap(false)
    
    if isSource then
        if frame.toggleButton then
            frame.toggleButton:Show()
            frame.toggleButton:SetPoint("LEFT", frame, "LEFT", 8, 0)
            frame.toggleButton:SetSize(16, 16)
            frame.nameText:SetPoint("LEFT", frame, "LEFT", 25, 0)
            frame.nameText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
            frame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
            frame.toggleButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
            frame.toggleButton:SetScript("OnClick", function(self)
                local parent = self:GetParent()
                if parent.items and parent.nameText then
                    local sourceName = parent.nameText:GetText()
                    -- Toggle collapsed state
                    SLG.collapsedSources[sourceName] = not SLG.collapsedSources[sourceName]
                    -- Rebuild the item list to reflect new state
                    if SLG.modules.ItemList then
                        SLG.modules.ItemList:UpdateDisplay()
                    end
                end
            end)
        end
        -- Initialize items table for source frames
        frame.items = {}
    else
        if frame.toggleButton then
            frame.toggleButton:Hide()
            frame.toggleButton:SetScript("OnClick", nil)
            frame.toggleButton:SetParent(nil)
            frame.toggleButton:ClearAllPoints()
            frame.toggleButton = nil -- Remove reference so it can't be shown again
        end
        frame.nameText:SetPoint("LEFT", frame, "LEFT", 5, 0)
        frame.nameText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
        -- Clear items table for non-source frames
        frame.items = nil
    end
    
    frame.statusText:SetText("")
    frame.statusText:SetTextColor(1, 1, 1)
    frame.statusText:SetFont("Fonts\\FRIZQT__.TTF", 11)
    frame.statusText:SetJustifyH("RIGHT")
    frame.statusText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    frame.statusText:Show()
    
    frame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
    frame.itemID = nil
    
    -- Update text truncation
    self:UpdateTextTruncation(frame)
end

-- Create a new frame
function Frames:CreateFrame(isSource)
    local frame = CreateFrame("Frame", nil, nil)
    frame:SetHeight(SLG.UI.ITEM_HEIGHT)
    frame:EnableMouse(true)
    frame.isSource = isSource
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
    
    -- Name text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetJustifyH("LEFT")
    frame.nameText:SetWordWrap(false)
    frame.nameText:SetNonSpaceWrap(false)
    
    -- Status text
    frame.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statusText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    frame.statusText:SetJustifyH("RIGHT")
    
    -- Toggle button (for source frames only)
    if isSource then
        frame.toggleButton = CreateFrame("Button", nil, frame)
        frame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        frame.toggleButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
        frame.toggleButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        frame.toggleButton:SetPoint("LEFT", frame, "LEFT", 8, 0)
        frame.toggleButton:SetSize(16, 16)
        
        -- Set up toggle button script
        frame.toggleButton:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            if parent.items and parent.nameText then
                local sourceName = parent.nameText:GetText()
                -- Toggle collapsed state
                SLG.collapsedSources[sourceName] = not SLG.collapsedSources[sourceName]
                -- Rebuild the item list to reflect new state
                if SLG.modules.ItemList then
                    SLG.modules.ItemList:UpdateDisplay()
                end
            end
        end)
        
        -- Initialize items table for source frames
        frame.items = {}
    else
        frame.toggleButton = nil -- Ensure no toggleButton for non-source frames
    end
    
    -- Add OnSizeChanged script to update text truncation
    frame:SetScript("OnSizeChanged", function(self)
        SLG.modules.Frames:UpdateTextTruncation(self)
    end)
    
    return frame
end

-- Create a scroll frame
function Frames:CreateScrollFrame(parent, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetSize(width, height)
    
    -- Create the scroll bar
    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -20, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -20, 16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    scrollBar:SetWidth(SLG.UI.SCROLL_WIDTH)
    
    -- Create the content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(width, height)
    scrollFrame:SetScrollChild(content)
    
    -- Enable mousewheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 30
        if delta < 0 then
            scrollBar:SetValue(math.min(max, current + step))
        else
            scrollBar:SetValue(math.max(min, current - step))
        end
    end)
    
    -- Set up scroll bar script
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    return scrollFrame, scrollBar, content
end

-- Return the module
return Frames 