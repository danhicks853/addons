local addonName, SLG = ...

-- Create the module
local DBTestWindow = {}
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
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
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
function DBTestWindow:GetZoneItemsFromDB(zoneName)
    -- Check Loot DB API
    if not ItemLocIsLoaded or not ItemLocGetSourceCount or not ItemLocGetSourceAt then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("Loot DB API not available.")
        self.content:SetHeight(30)
        return
    end
    local version = ItemLocIsLoaded()
    if not version then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("Loot DB is not loaded.")
        self.content:SetHeight(30)
        return
    end

    -- Get items for the zone
    local ZoneManager = SLG.modules.ZoneManager
    if not ZoneManager then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("ZoneManager not available.")
        self.content:SetHeight(30)
        return
    end
    local items, stats = ZoneManager:GetZoneItems(zoneName)
    if not items or #items == 0 then
        local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        text:SetText("No items found for this zone.")
        self.content:SetHeight(30)
        return
    end

    local y = 0
    local rowHeight = 16
    for i, item in ipairs(items) do
        local itemId = item.id or item.itemId or item[1]
        if itemId then
            local itemData = SLG.modules.ItemManager and SLG.modules.ItemManager:GetItemData(itemId)
            local name = (itemData and itemData.name) or ("Item " .. tostring(itemId))
            local count = ItemLocGetSourceCount(itemId)
            local srcSummary = ""
            if count and count > 0 then
                for j = 1, count do
                    local srcType, objType, objId, chance, dropsPerThousand, objName, zoneName, spawnedCount = ItemLocGetSourceAt(itemId, j)
                    srcSummary = srcSummary .. string.format("%s (%s) | Chance: %.2f%% | Zone: %s  ", tostring(objName), tostring(srcType), tonumber(chance) and chance * 100 or 0, tostring(zoneName))
                end
            else
                srcSummary = "No sources found."
            end
            local text = self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
            text:SetText(string.format("[%d] %s: %s", itemId, name, srcSummary))
            y = y + rowHeight
        end
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
