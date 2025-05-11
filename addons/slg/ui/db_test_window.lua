print("SLG Debug: Loading db_test_window.lua")
local addonName, SLG = ...

-- Create the module
local DBTestWindow = {}
print("SLG Debug: Registering DBTestWindow module")
SLG:RegisterModule("DBTestWindow", DBTestWindow)

-- Create the DB Test window
function DBTestWindow:CreateDBTestWindow()
    -- Create the frame
    local frame = CreateFrame("Frame", "SLGDBTestFrame", UIParent)
    frame:SetSize(SLG.UI.MIN_WINDOW_WIDTH, SLG.UI.DEFAULT_WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not self.isLocked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.isLocked then self:StopMovingOrSizing() end
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

    -- Title
    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    titleBg:SetHeight(SLG.UI.TITLE_HEIGHT)
    titleBg:SetTexture(0, 0, 0, 0.5)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 8, -2)
    title:SetText("SLG DB Test")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- Scroll Frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    frame.scrollFrame = scrollFrame
    frame.content = content
    self.frame = frame
    self.content = content
end

-- Show/hide logic
function DBTestWindow:Show()
    if not self.frame then self:CreateDBTestWindow() end
    self.frame:Show()
    self:UpdateDisplay()
end

function DBTestWindow:Hide()
    if self.frame then self.frame:Hide() end
end

function DBTestWindow:Toggle()
    if not self.frame or not self.frame:IsShown() then
        self:Show()
    else
        self:Hide()
    end
end

-- Dynamically get items for current zone from loot DB
function DBTestWindow:GetZoneItemsFromDB()
    -- Check for Loot DB API presence
    if not ItemLocIsLoaded or not ItemLocItemIsInZone then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("Loot DB API not present.")
        self.content:SetHeight(30)
        return
    end
    local dbVersion = ItemLocIsLoaded()
    if not dbVersion then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("Loot DB not loaded.")
        self.content:SetHeight(30)
        return
    end
    -- Determine current zone
    local currentZoneId = nil
    local zoneText = GetRealZoneText and GetRealZoneText() or "(nil)"
    print("SLG Debug: ItemLocGetZoneId:", tostring(ItemLocGetZoneId), "type:", type(ItemLocGetZoneId))
    print("SLG Debug: GetRealZoneText():", tostring(zoneText), "type:", type(zoneText))
    if ItemLocGetZoneId then
        local zoneIdResult = ItemLocGetZoneId(zoneText)
        print("SLG Debug: ItemLocGetZoneId(GetRealZoneText()):", tostring(zoneIdResult), "type:", type(zoneIdResult))
        currentZoneId = zoneIdResult
    end
    if not currentZoneId then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("Could not determine current zone ID.")
        self.content:SetHeight(30)
        return
    end
    -- Get attunement check function
    local isAttuned = function(itemId)
        if SLG and SLG.modules and SLG.modules.Attunement and SLG.modules.Attunement.IsAttuned then
            return SLG.modules.Attunement:IsAttuned(itemId)
        elseif SynastriaCoreLib and SynastriaCoreLib.IsAttuned then
            return SynastriaCoreLib.IsAttuned(itemId)
        end
        return false
    end
    -- Find MAX_ITEMID from SynastriaCoreLib or use a safe default
    local maxItemId = (SynastriaCoreLib and SynastriaCoreLib.MAX_ITEMID) or 100000
    local found = 0
    local y = 0
    local rowHeight = 16
    for itemId = 1, maxItemId do
        if ItemLocItemIsInZone(itemId, currentZoneId) == 1 and not isAttuned(itemId) then
            local name = GetItemInfo(itemId) or ("Item " .. tostring(itemId))
            local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
            text:SetText(string.format("[%d] %s", itemId, name))
            y = y + rowHeight
            found = found + 1
        end
    end
    if found == 0 then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("No unattuned items found in this zone.")
        self.content:SetHeight(30)
        return
    end
    self.content:SetHeight(math.max(y, 30))
end

function DBTestWindow:UpdateDisplay()
    -- Clear previous content
    for _, child in ipairs({self.content:GetChildren()}) do child:Hide() end
    local zone = GetRealZoneText()
    self:GetZoneItemsFromDB(zone)
end

return DBTestWindow
