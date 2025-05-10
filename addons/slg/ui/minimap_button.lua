local addonName, SLG = ...

-- Create the module
local MinimapButton = {}
SLG:RegisterModule("MinimapButton", MinimapButton)

local defaultPosition = 45 -- degrees

-- Helper function to update button position
local function UpdatePosition(button)
    local position = SLGSettings.minimapPos or defaultPosition
    local angle = math.rad(position)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragStart(self)
    self:LockHighlight()
    self.isMouseDown = true
    self:SetScript("OnUpdate", function(self)
        local xpos, ypos = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        xpos, ypos = xpos / scale, ypos / scale
        local minimapCenterX, minimapCenterY = Minimap:GetCenter()
        local position = math.deg(math.atan2(ypos - minimapCenterY, xpos - minimapCenterX)) % 360
        SLGSettings.minimapPos = position
        UpdatePosition(self)
    end)
end

local function OnDragStop(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    self.isMouseDown = false
end

function MinimapButton:Initialize()
    -- Create event frame to wait for PLAYER_LOGIN
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            self:UnregisterEvent("PLAYER_LOGIN")
            MinimapButton:CreateButton()
        end
    end)
end

function MinimapButton:CreateButton()
    if self.button then return self.button end
    
    local button = CreateFrame("Button", "SLGMinimapButton", Minimap)
    button:SetWidth(31)
    button:SetHeight(31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    
    -- Set up textures
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")
    
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetWidth(20)
    background:SetHeight(20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)
    
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(17)
    icon:SetHeight(17)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_27")
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon
    
    -- Set up scripts
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)
    button:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                if SLG.modules.ZoneBrowser then
                    SLG.modules.ZoneBrowser:Toggle()
                end
            else
                if SLG.modules.MainWindow then
                    SLG.modules.MainWindow:Toggle()
                end
            end
        elseif button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
            InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
        end
    end)
    
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Synastria Loot Guide")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left Click: Toggle Main Window")
        GameTooltip:AddLine("Right Click: Open Configuration")
        GameTooltip:AddLine("Shift + Left Click: Toggle Zone Browser")
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Initial position
    UpdatePosition(button)
    
    -- Save reference
    self.button = button
    
    -- Show button unless explicitly hidden in settings
    if not SLGSettings or not SLGSettings.minimap or not SLGSettings.minimap.hide then
        button:Show()
    else
        button:Hide()
    end
    
    return button
end

function MinimapButton:SetIcon(path)
    if self.button and self.button.icon then
        self.button.icon:SetTexture(path)
    end
end

function MinimapButton:Show()
    if self.button then
        self.button:Show()
    end
end

function MinimapButton:Hide()
    if self.button then
        self.button:Hide()
    end
end

function MinimapButton:UpdatePosition()
    if self.button then
        UpdatePosition(self.button)
    end
end

return MinimapButton 