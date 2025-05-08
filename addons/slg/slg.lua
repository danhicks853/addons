local addonName, SLG = ...
SLG.version = GetAddOnMetadata(addonName, "Version")

-- Initialize the addon
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
SLG.addon = addon

-- Get the SynastriaCoreLib
local SCL = LibStub("SynastriaCoreLib-1.0")

-- Initialize SLG tables
SLG.itemFrames = {}
SLG.lootedItems = {} -- Track items that have been looted but not attuned

-- WotLK Raid Configuration
SLG.RaidInfo = {
    ["Icecrown Citadel"] = {
        difficulties = {"10 Normal", "10 Heroic", "25 Normal", "25 Heroic"},
        hasHeroic = true
    },
    ["The Ruby Sanctum"] = {
        difficulties = {"10 Normal", "10 Heroic", "25 Normal", "25 Heroic"},
        hasHeroic = true
    },
    ["The Obsidian Sanctum"] = {
        difficulties = {"10 Normal", "25 Normal"},
        hasHeroic = false
    },
    ["Naxxramas"] = {
        difficulties = {"10 Normal", "25 Normal"},
        hasHeroic = false
    },
    ["The Eye of Eternity"] = {
        difficulties = {"10 Normal", "25 Normal"},
        hasHeroic = false
    },
    ["Ulduar"] = {
        difficulties = {"Normal", "Normal (25)", "Hard Mode", "Hard Mode (25)"},
        hasHeroic = false,
        hardModes = {
            ["Flame Leviathan"] = {"1 Tower", "2 Towers", "3 Towers", "4 Towers"},
            ["XT-002 Deconstructor"] = {"Hard Mode"},
            ["The Iron Council"] = {"Hard Mode"},
            ["Hodir"] = {"Hard Mode"},
            ["Thorim"] = {"Hard Mode"},
            ["Freya"] = {"1 Elder", "2 Elders", "3 Elders"},
            ["Mimiron"] = {"Hard Mode"},
            ["General Vezax"] = {"Hard Mode"},
            ["Yogg-Saron"] = {"1 Keeper", "2 Keepers", "3 Keepers", "No Keepers"},
            ["Algalon the Observer"] = {"Celestial Planetarium Key"}
        }
    },
    ["Trial of the Crusader"] = {
        difficulties = {"Alliance", "Alliance (25)", "Alliance Heroic", "Alliance Heroic (25)", "Horde", "Horde (25)", "Horde Heroic", "Horde Heroic (25)"},
        hasHeroic = true,
        isFactionSpecific = true,
        tributeChest = {
            ["Alliance"] = {"1-24", "25-44", "45-49", "50"},
            ["Horde"] = {"1-24", "25-44", "45-49", "50"}
        }
    },
    ["Onyxia's Lair"] = {
        difficulties = {"10 Normal", "25 Normal"},
        hasHeroic = false
    }
}

-- Default settings
SLG.defaults = {
    profile = {
        autoOpen = false,
        autoOpenOnZoneChange = false,
        minimap = { hide = false },
        displayMode = "not_attuned",
        collectorEnabled = true, -- Enable Collector Module
        collectorExportPath = "SLG_CollectedLoot.lua" -- Default export path
    }
}

-- Options table
local options = {
    name = "Synastria Loot Guide",
    handler = addon,
    type = "group",
    args = {
        autoOpen = {
            type = "toggle",
            name = "Auto-open on Login",
            desc = "Automatically open the window when you log in",
            get = function() return SLGSettings.autoOpen end,
            set = function(_, value) SLGSettings.autoOpen = value end,
            order = 1,
            width = "full"
        },
        autoOpenOnZoneChange = {
            type = "toggle",
            name = "Auto-open on Zone Change",
            desc = "Automatically open the window when you change zones",
            get = function() return SLGSettings.autoOpenOnZoneChange end,
            set = function(_, value) SLGSettings.autoOpenOnZoneChange = value end,
            order = 2,
            width = "full"
        },
        displayMode = {
            type = "select",
            name = "Display Mode",
            desc = "Choose which items to display in the list.",
            values = {
                attuned = "Attuned",
                not_attuned = "Not Attuned",
                eligible = "All Eligible",
                all = "All"
            },
            get = function() return SLGSettings.displayMode end,
            set = function(_, value) SLGSettings.displayMode = value; SLG:UpdateItemList() end,
            order = 3,
            width = "full"
        },
        collectorEnabled = {
            type = "toggle",
            name = "Enable Collector Module",
            desc = "Enable or disable the loot collector module.",
            get = function() return SLGSettings.collectorEnabled end,
            set = function(_, value) SLGSettings.collectorEnabled = value end,
            order = 10,
            width = "full"
        },
        collectorExportPath = {
            type = "input",
            name = "Export File Path",
            desc = "File path to use when exporting collector data (for reference only, export is printed to chat).",
            get = function() return SLGSettings.collectorExportPath end,
            set = function(_, value) SLGSettings.collectorExportPath = value end,
            order = 11,
            width = "full"
        },
        collectorExport = {
            type = "execute",
            name = "Export Collector Data",
            desc = "Export the collected loot data to the chat window (copy from chat).",
            func = function() SLG:ExportCollectorData() end,
            order = 12,
            width = "full"
        },
        collectorExportVendors = {
            type = "execute",
            name = "Export Vendors Only",
            desc = "Export only vendor data (zone > vendor > item ids) to the chat window.",
            func = function()
                if _G.ExportVendorsOnly then
                    _G.ExportVendorsOnly()
                else
                    print("Vendor export function not found.")
                end
            end,
            order = 13,
            width = "full"
        },
        about = {
            type = "description",
            name = "\nSynastria Loot Guide\n5/7/25\nWritten by Faithful Death Knight Dromkal",
            order = 1000,
            fontSize = "medium"
        }
    }
}

-- Register options table
LibStub("AceConfig-3.0"):RegisterOptionsTable("SynastriaLootGuide", options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SynastriaLootGuide", "Synastria Loot Guide")

-- At the top, after AceConfig includes:
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

-- Create the LDB object for the minimap icon
local ldbObj = LDB:NewDataObject("SynastriaLootGuide", {
    type = "launcher",
    text = "Synastria Loot Guide",
    icon = "Interface\\Icons\\INV_Misc_Bag_27",
    OnClick = function(_, button)
        if button == "LeftButton" then
            if SLG.frame:IsShown() then
                SLG.frame:Hide()
            else
                SLG.frame:Show()
                SLG:UpdateItemList()
            end
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

-- Function to load settings
function SLG:LoadSettings()
    if not SLGSettings then
        SLGSettings = CopyTable(self.defaults.profile)
    end
end

-- Create the main frame
local frame = CreateFrame("Frame", "SLGFrame", UIParent)
frame:SetSize(400, 600) -- Changed height from 300 to 600
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Register for loot events
frame:RegisterEvent("LOOT_READY")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")

-- Register for BAG_UPDATE event
global_frame = global_frame or frame
if not global_frame:IsEventRegistered("BAG_UPDATE") then
    global_frame:RegisterEvent("BAG_UPDATE")
end

-- Function to handle events
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        SLG:LoadSettings()
        if SLGSettings.autoOpen then
            frame:Show()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        if SLGSettings.autoOpenOnZoneChange then
            frame:Show()
        end
        if frame:IsShown() then
            SLG:UpdateItemList()
        end
    elseif event == "LOOT_READY" then
        -- Check the loot window for items
        local numItems = GetNumLootItems()
        for i = 1, numItems do
            local link = GetLootSlotLink(i)
            if link then
                SLG:HandleLoot(link)
            end
        end
    elseif event == "CHAT_MSG_LOOT" then
        local lootString = ...
        local itemLink = lootString:match("|H(item:%d+:.-)|h")
        if itemLink then
            SLG:HandleLoot("item:" .. itemLink)
        end
    elseif event == "BAG_UPDATE" then
        if frame:IsShown() then
            SLG:UpdateItemList()
        end
    end
end

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:SetScript("OnEvent", OnEvent)

-- Set frame backdrop
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 16, right = 16, top = 16, bottom = 16 } -- Increased margin
})
frame:SetBackdropColor(0, 0, 0, 1)

-- Create title area
local titleBg = frame:CreateTexture(nil, "BACKGROUND")
titleBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
titleBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
titleBg:SetHeight(56)
titleBg:SetTexture(0, 0, 0, 0.5)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", titleBg, "TOPLEFT", 10, -8) -- Changed from TOP to TOPLEFT for better control
title:SetText("Synastria Loot Guide")

-- Create close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
closeButton:SetSize(32, 32)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

local zoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
zoneText:ClearAllPoints()
zoneText:SetPoint("BOTTOM", titleBg, "BOTTOM", 0, 6)
zoneText:SetPoint("LEFT", titleBg, "LEFT", 0, 0)
zoneText:SetPoint("RIGHT", titleBg, "RIGHT", 0, 0)
zoneText:SetJustifyH("CENTER")
zoneText:SetTextColor(0.8, 0.8, 0.8)

local progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
progressText:SetPoint("TOPRIGHT", titleBg, "TOPRIGHT", -40, -18) -- Adjusted vertical position
progressText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
progressText:SetTextColor(0, 0.95, 0.3)

-- Create the scroll frame and related elements
local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
scrollFrame:SetPoint("TOPLEFT", titleBg, "BOTTOMLEFT", 0, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, 12)

-- Create the scroll bar first
local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -20, -16)
scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -20, 16)
scrollBar:SetMinMaxValues(0, 200)
scrollBar:SetValueStep(1)
scrollBar:SetValue(0)
scrollBar:SetWidth(16)
scrollBar:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value)
end)

-- Now enable mousewheel scrolling (after scrollBar is created)
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = scrollBar:GetValue()
    local min, max = scrollBar:GetMinMaxValues()
    local step = 30 -- Scroll 30 pixels at a time for smoother scrolling
    
    if delta < 0 then -- Scrolling down
        scrollBar:SetValue(math.min(max, current + step))
    else -- Scrolling up
        scrollBar:SetValue(math.max(min, current - step))
    end
end)

-- Create the content frame
local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(scrollFrame:GetWidth(), 2000) -- Increased initial height for content
scrollFrame:SetScrollChild(content)

-- Store frames in SLG table
SLG.frame = frame
SLG.scrollFrame = scrollFrame
SLG.scrollContent = content
SLG.scrollBar = scrollBar

-- Function to handle loot events
function SLG:HandleLoot(itemLink)
    if not itemLink then return end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end
    
    -- Mark item as looted
    self.lootedItems[itemID] = true
    
    -- Update UI if the window is shown
    if self.frame:IsShown() then
        self:UpdateItemStatus(itemID)
    end
end

-- Function to update a specific item's status in the UI
function SLG:UpdateItemStatus(itemID)
    for _, frame in pairs(self.itemFrames) do
        if frame.itemID == itemID then
            if SCL.IsAttuned(itemID) then
                -- Item is now attuned, remove it from display
                frame:Hide()
                self.lootedItems[itemID] = nil
                -- Update progress counter
                self:UpdateProgress()
            elseif self.lootedItems[itemID] then
                -- Item is looted but not attuned
                frame.statusText:SetText("Looted!")
                frame.statusText:SetTextColor(1, 1, 0) -- Yellow color
            end
        end
    end
end

-- Function to update progress counter
function SLG:UpdateProgress()
    local currentZone = GetRealZoneText()
    local items = self.ZoneItems[currentZone]
    local stats = {
        total = 0,
        attuned = 0
    }
    
    if items then
        for _, sourceItems in pairs(items) do
            for _, item in ipairs(sourceItems) do
                if self:CanUseItem(item.itemType) then
                    stats.total = stats.total + 1
                    if SCL.IsAttuned(item.id) then
                        stats.attuned = stats.attuned + 1
                    end
                end
            end
        end
    end
    
    progressText:SetText(string.format("%d/%d", stats.attuned, stats.total))
end

-- Function to check for attunement changes
function SLG:CheckAttunementChanges()
    local needsUpdate = false
    
    for itemID in pairs(self.lootedItems) do
        if SCL.IsAttuned(itemID) then
            needsUpdate = true
            break
        end
    end
    
    if needsUpdate and self.frame:IsShown() then
        self:UpdateItemList()
    end
end

-- Helper function to truncate text to a max character count
function SLG:TruncateTextToChars(text, maxChars)
    if #text > maxChars then
        return text:sub(1, maxChars - 3) .. "..."
    else
        return text
    end
end

-- Function to get a new item frame
function SLG:GetItemFrame(isHeader)
    local frame = CreateFrame("Frame", nil, self.scrollContent)
    frame:SetSize(self.scrollFrame:GetWidth() - 20, 20)
    
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0, 0, 0, 0) -- Default transparent, will set color later

    if isHeader then
        -- Create toggle button for headers
        frame.toggleButton = CreateFrame("Button", nil, frame)
        frame.toggleButton:SetSize(16, 16)
        frame.toggleButton:SetPoint("LEFT", frame, "LEFT", 5, 0)
        frame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        frame.toggleButton.isCollapsed = false
        
        frame.toggleButton:SetScript("OnClick", function(self)
            self.isCollapsed = not self.isCollapsed
            if self.isCollapsed then
                self:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
            else
                self:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
            end
            
            -- Immediately hide/show items before recalculating
            if frame.items then
                for _, itemFrame in ipairs(frame.items) do
                    if self.isCollapsed then
                        itemFrame:Hide()
                        itemFrame:ClearAllPoints()
                    else
                        itemFrame:Show()
                    end
                end
            end
            
            -- Recalculate heights and reposition frames
            SLG:RecalculateContentHeight()
        end)
        
        -- Create item name text (moved right to make room for button)
        frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.nameText:SetPoint("LEFT", frame.toggleButton, "RIGHT", 2, 0)
        frame.nameText:SetJustifyH("LEFT")
        frame.nameText:SetWidth(self.scrollFrame:GetWidth() - 100) -- leave more space for status
        frame.nameText:SetWordWrap(false)
    else
        -- Regular item frame
        frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.nameText:SetPoint("LEFT", frame, "LEFT", 2, 0)
        frame.nameText:SetJustifyH("LEFT")
        frame.nameText:SetWidth(self.scrollFrame:GetWidth() - 100)
        frame.nameText:SetWordWrap(false)
    end
    
    -- Create status text
    frame.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statusText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    frame.statusText:SetWidth(80)
    frame.statusText:SetJustifyH("RIGHT")
    
    -- Enable mouse for tooltip
    frame:EnableMouse(true)
    
    return frame
end

-- Function to recalculate content height
function SLG:RecalculateContentHeight()
    local totalHeight = 0
    local padding = 2
    local sourceHeight = 22
    local itemHeight = 22
    
    -- First pass: calculate total height and reposition all frames
    for _, sourceFrame in ipairs(self.itemFrames) do
        if sourceFrame.isHeader then
            -- Position the header
            sourceFrame:ClearAllPoints()
            sourceFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, -totalHeight)
            sourceFrame:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -totalHeight)
            totalHeight = totalHeight + sourceHeight + padding
            
            -- Handle items
            if sourceFrame.items then
                for _, itemFrame in ipairs(sourceFrame.items) do
                    if sourceFrame.toggleButton.isCollapsed then
                        itemFrame:Hide()
                        itemFrame:ClearAllPoints()
                    else
                        itemFrame:ClearAllPoints()
                        itemFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 20, -totalHeight)
                        itemFrame:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -totalHeight)
                        itemFrame:Show()
                        totalHeight = totalHeight + itemHeight + padding
                    end
                end
                if not sourceFrame.toggleButton.isCollapsed then
                    totalHeight = totalHeight + padding -- Extra padding after group
                end
            end
        end
    end
    
    -- Update content height and scroll range
    self.scrollContent:SetHeight(math.max(totalHeight, self.scrollFrame:GetHeight()))
    local maxScroll = math.max(0, totalHeight - self.scrollFrame:GetHeight())
    self.scrollBar:SetMinMaxValues(0, maxScroll)
    
    -- Reset scroll position if we're scrolled too far
    if self.scrollBar:GetValue() > maxScroll then
        self.scrollBar:SetValue(maxScroll)
    end
end

-- Function to update the item list
function SLG:UpdateItemList()
    -- Clear existing frames
    for _, frame in pairs(self.itemFrames) do
        frame:Hide()
    end
    wipe(self.itemFrames)
    
    -- Get items for current zone
    local currentZone = GetRealZoneText()
    
    -- Get items and stats using GetZoneItems
    local sourceGroups, stats = self:GetZoneItems(currentZone)
    
    -- Update zone and progress text
    zoneText:SetText(currentZone .. self:GetDifficultyText())
    progressText:SetText(string.format("%d/%d", stats.attuned, stats.total))
    
    -- If all items are attuned, show a message
    if stats.total > 0 and stats.attuned == stats.total then
        local messageFrame = self:GetItemFrame()
        messageFrame:SetPoint("TOP", self.scrollContent, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        messageFrame.nameText:SetText("All items attuned!")
        messageFrame.nameText:SetTextColor(0, 1, 0)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        
        table.insert(self.itemFrames, messageFrame)
        
        -- Set content height
        self.scrollContent:SetHeight(60)
        -- Update scroll bar range
        local maxScroll = math.max(0, 60 - self.scrollFrame:GetHeight())
        self.scrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    -- If no items found or no source groups
    if not sourceGroups or #sourceGroups == 0 then
        local messageFrame = self:GetItemFrame()
        messageFrame:SetPoint("TOP", self.scrollContent, "TOP", 0, -20)
        messageFrame:SetHeight(40)
        
        local noItemsText = "No attunable items found in this zone"
        local difficulty, instanceType = self:GetInstanceInfo()
        if instanceType == "dungeon" then
            noItemsText = string.format("No attunable items found for %s mode", difficulty)
        elseif instanceType == "raid" then
            noItemsText = string.format("No attunable items found for %s %s", difficulty, instanceType)
        end
        
        messageFrame.nameText:SetText(noItemsText)
        messageFrame.nameText:SetTextColor(0.8, 0.8, 0.8)
        messageFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        messageFrame.nameText:SetJustifyH("CENTER")
        messageFrame.nameText:SetPoint("CENTER")
        messageFrame.statusText:Hide()
        
        table.insert(self.itemFrames, messageFrame)
        
        -- Set content height
        self.scrollContent:SetHeight(60)
        -- Update scroll bar range
        local maxScroll = math.max(0, 60 - self.scrollFrame:GetHeight())
        self.scrollBar:SetMinMaxValues(0, maxScroll)
        return
    end
    
    -- Update content height
    local totalHeight = 0
    local padding = 2
    local sourceHeight = 22
    local itemHeight = 22
    
    -- Create frames for each source and its items
    for _, sourceGroup in ipairs(sourceGroups) do
        -- Create source header
        local sourceFrame = self:GetItemFrame(true) -- true for header
        sourceFrame.isHeader = true
        sourceFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, -totalHeight)
        sourceFrame:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -totalHeight)
        sourceFrame:SetHeight(sourceHeight)
        
        -- Set source text
        sourceFrame.nameText:SetText(sourceGroup.source)
        sourceFrame.nameText:SetTextColor(1, 0.8, 0) -- Gold color for source headers
        sourceFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        sourceFrame.statusText:Hide()
        
        -- Initialize items array for the header
        sourceFrame.items = {}
        
        -- Set initial button state
        sourceFrame.toggleButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        
        -- Add source frame to list
        table.insert(self.itemFrames, sourceFrame)
        totalHeight = totalHeight + sourceHeight + padding
        
        -- Create frames for items under this source
        for idx, item in ipairs(sourceGroup.items) do
            local itemFrame = self:GetItemFrame(false)
            itemFrame:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 8, -totalHeight)
            itemFrame:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", -10, -totalHeight)
            itemFrame:SetHeight(itemHeight)

            -- Zebra striping
            if idx % 2 == 0 then
                itemFrame.bg:SetTexture(0.13, 0.13, 0.13, 0.7)
            else
                itemFrame.bg:SetTexture(0.09, 0.09, 0.09, 0.7)
            end

            -- Set item text
            itemFrame.nameText:SetText(item.name)
            itemFrame.nameText:SetTextColor(1, 1, 1) -- White color for items
            itemFrame.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11)
            
            -- Set status text based on looted state
            if SLGSettings.displayMode == "attuned" then
                if SCL.IsAttuned(item.id) then
                    itemFrame.statusText:SetText("Attuned!")
                    itemFrame.statusText:SetTextColor(0, 1, 0) -- Green color
                else
                    itemFrame.statusText:SetText(item.itemType)
                    itemFrame.statusText:SetTextColor(0.7, 0.7, 0.7) -- Gray color
                end
            elseif SLGSettings.displayMode == "not_attuned" then
                if self:IsItemEquipped(item.id) then
                    local itemLink = self:GetEquippedItemLink(item.id)
                    local pct = 0
                    if itemLink and GetItemLinkAttuneProgress then
                        pct = tonumber(GetItemLinkAttuneProgress(itemLink)) or 0
                    end
                    itemFrame.nameText:SetTextColor(0.2, 0.6, 1) -- Blue
                    itemFrame.statusText:SetText(string.format("Attuning: %d%%", pct))
                    itemFrame.statusText:SetTextColor(0.2, 0.6, 1)
                elseif self:IsItemInInventory(item.id) then
                    local itemLink = self:GetInventoryItemLink(item.id)
                    local pct = 0
                    if itemLink and GetItemLinkAttuneProgress then
                        pct = tonumber(GetItemLinkAttuneProgress(itemLink)) or 0
                    end
                    itemFrame.nameText:SetTextColor(0, 1, 0) -- Green
                    itemFrame.statusText:SetText(string.format("Looted! (%d%%)", pct))
                    itemFrame.statusText:SetTextColor(0, 1, 0)
                else
                    itemFrame.nameText:SetTextColor(1, 1, 1)
                    itemFrame.statusText:SetText(item.itemType)
                    itemFrame.statusText:SetTextColor(0.7, 0.7, 0.7)
                end
            elseif SLGSettings.displayMode == "eligible" then
                if SCL.IsAttuned(item.id) then
                    itemFrame.statusText:SetText("Attuned!")
                    itemFrame.statusText:SetTextColor(0, 1, 0) -- Green color
                else
                    itemFrame.statusText:SetText("Eligible")
                    itemFrame.statusText:SetTextColor(0.2, 0.6, 1) -- Blue color
                end
            elseif SLGSettings.displayMode == "all" then
                itemFrame.statusText:SetText(item.itemType)
                itemFrame.statusText:SetTextColor(1, 1, 1) -- White color for all items
            end
            
            -- Store itemID for later reference
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
            
            -- Add item frame to list and to source's items
            table.insert(self.itemFrames, itemFrame)
            table.insert(sourceFrame.items, itemFrame)
            totalHeight = totalHeight + itemHeight + padding
        end
        
        -- Add extra padding after each source group
        totalHeight = totalHeight + padding * 2
    end
    
    -- Update content height and scroll range
    self.scrollContent:SetHeight(totalHeight)
    -- Update scroll bar range
    local maxScroll = math.max(0, totalHeight - self.scrollFrame:GetHeight())
    self.scrollBar:SetMinMaxValues(0, maxScroll)
end

-- Function to get instance difficulty info
function SLG:GetInstanceInfo()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return "normal", "outdoor" -- Not in an instance
    end

    local difficultyID = GetInstanceDifficulty()
    local currentZone = GetRealZoneText()
    local raidInfo = self.RaidInfo[currentZone]

    -- Custom server mapping:
    -- 1: 10 Normal
    -- 2: 25 Normal
    -- 3: 10 Heroic
    -- 4: 25 Heroic

    if instanceType == "party" then
        if difficultyID == 2 then
            return "heroic", "dungeon"
        else
            return "normal", "dungeon"
        end
    elseif instanceType == "raid" then
        if raidInfo then
            if difficultyID == 1 then
                return "normal", "raid10"
            elseif difficultyID == 2 then
                return "normal", "raid25"
            elseif difficultyID == 3 then
                return "heroic", "raid10"
            elseif difficultyID == 4 then
                return "heroic", "raid25"
            else
                return "legacy", "raid"
            end
        else
            return "legacy", "raid"
        end
    end

    return "normal", "unknown"
end

-- Function to get raid hard mode info
function SLG:GetRaidHardModeInfo(boss)
    local currentZone = GetRealZoneText()
    local raidInfo = self.RaidInfo[currentZone]
    
    if raidInfo and raidInfo.hardModes and raidInfo.hardModes[boss] then
        return raidInfo.hardModes[boss]
    end
    
    return nil
end

-- Function to check if player can use the item
function SLG:CanUseItem(itemType)
    local _, class = UnitClass("player")
    
    -- Primary armor types for each class
    local primaryArmor = {
        ["WARRIOR"] = "Plate",
        ["PALADIN"] = "Plate",
        ["HUNTER"] = "Mail",
        ["ROGUE"] = "Leather",
        ["PRIEST"] = "Cloth",
        ["DEATHKNIGHT"] = "Plate",
        ["SHAMAN"] = "Mail",
        ["MAGE"] = "Cloth",
        ["WARLOCK"] = "Cloth",
        ["DRUID"] = "Leather"
    }
    
    -- Weapon types each class can use
    local weaponTypes = {
        ["WARRIOR"] = {"1H Sword", "2H Sword", "1H Axe", "2H Axe", "1H Mace", "2H Mace", "Dagger", "Fist Weapon", "Polearm", "Staff", "Shield"},
        ["PALADIN"] = {"1H Sword", "2H Sword", "1H Mace", "2H Mace", "Shield"},
        ["HUNTER"] = {"Bow", "Crossbow", "Gun", "1H Sword", "2H Sword", "1H Axe", "2H Axe", "Polearm", "Staff", "Fist Weapon"},
        ["ROGUE"] = {"1H Sword", "1H Axe", "1H Mace", "Dagger", "Fist Weapon"},
        ["PRIEST"] = {"1H Mace", "Dagger", "Staff", "Wand"},
        ["DEATHKNIGHT"] = {"1H Sword", "2H Sword", "1H Axe", "2H Axe", "1H Mace", "2H Mace", "Polearm"},
        ["SHAMAN"] = {"1H Axe", "2H Axe", "1H Mace", "2H Mace", "Dagger", "Fist Weapon", "Staff", "Shield"},
        ["MAGE"] = {"1H Sword", "Dagger", "Staff", "Wand"},
        ["WARLOCK"] = {"1H Sword", "Dagger", "Staff", "Wand"},
        ["DRUID"] = {"1H Mace", "2H Mace", "Dagger", "Fist Weapon", "Polearm", "Staff"}
    }
    
    -- Check if it's an armor type
    if itemType == "Cloth" or itemType == "Leather" or itemType == "Mail" or itemType == "Plate" then
        return itemType == primaryArmor[class]
    end
    
    -- Check if it's a weapon type
    if weaponTypes[class] then
        for _, type in ipairs(weaponTypes[class]) do
            if type == itemType then
                return true
            end
        end
    end
    
    -- Check if it's jewelry or other (anyone can use)
    if itemType == "Neck" or itemType == "Ring" or itemType == "Trinket" or itemType == "Cloak" then
        return true
    end
    
    return false
end

-- Helper function to get item data
function SLG:GetItemData(itemId)
    if not itemId then return nil end
    
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
    if not name then
        -- Item data not in cache, request it
        GameTooltip:SetHyperlink("item:" .. itemId)
        GameTooltip:Hide()
        -- Try getting the data again
        name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
        if not name then
            -- Still no data, return nil and let the caller handle it
            return nil
        end
    end
    
    -- Determine item type based on class and subclass
    local itemType = "Misc"
    if class == "Armor" then
        if subclass == "Cloth" or subclass == "Leather" or subclass == "Mail" or subclass == "Plate" then
            itemType = subclass
        elseif subclass == "Cloaks" then
            itemType = "Cloak"
        elseif subclass == "Shields" then
            itemType = "Shield"
        elseif subclass == "Neck" then
            itemType = "Neck"
        elseif subclass == "Finger" then
            itemType = "Ring"
        elseif subclass == "Trinket" then
            itemType = "Trinket"
        end
        -- Fix: If it's a cloak by equipSlot, override itemType
        if equipSlot == "INVTYPE_CLOAK" then
            itemType = "Cloak"
        end
    elseif class == "Weapon" then
        -- Map weapon subclasses to our internal types
        local weaponMap = {
            ["One-Handed Swords"] = "1H Sword",
            ["Two-Handed Swords"] = "2H Sword",
            ["One-Handed Axes"] = "1H Axe",
            ["Two-Handed Axes"] = "2H Axe",
            ["One-Handed Maces"] = "1H Mace",
            ["Two-Handed Maces"] = "2H Mace",
            ["Daggers"] = "Dagger",
            ["Fist Weapons"] = "Fist Weapon",
            ["Polearms"] = "Polearm",
            ["Staves"] = "Staff",
            ["Bows"] = "Bow",
            ["Crossbows"] = "Crossbow",
            ["Guns"] = "Gun",
            ["Wands"] = "Wand",
            ["Thrown"] = "Thrown"
        }
        itemType = weaponMap[subclass] or subclass
    elseif class == "Miscellaneous" then
        -- Handle accessories in Miscellaneous class
        if subclass == "Rings" or subclass == "Ring" or subclass == "Finger" then
            itemType = "Ring"
        elseif subclass == "Neck" or subclass == "Necklace" then
            itemType = "Neck"
        elseif subclass == "Trinket" then
            itemType = "Trinket"
        elseif subclass == "Cloak" or subclass == "Back" then
            itemType = "Cloak"
        end
    end
    
    -- Also check equipSlot for accessories if not already set
    if itemType == "Misc" then
        if equipSlot == "INVTYPE_NECK" then
            itemType = "Neck"
        elseif equipSlot == "INVTYPE_FINGER" then
            itemType = "Ring"
        elseif equipSlot == "INVTYPE_TRINKET" then
            itemType = "Trinket"
        elseif equipSlot == "INVTYPE_CLOAK" then
            itemType = "Cloak"
        end
    end
    
    return {
        id = itemId,
        name = name,
        link = link,
        quality = quality,
        itemType = itemType,
        texture = texture
    }
end

-- Helper function to get item info
function SLG:GetItemInfo(itemId)
    if not itemId then return nil end
    
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
    if not name then
        -- Item data not in cache, request it
        GameTooltip:SetHyperlink("item:" .. itemId)
        GameTooltip:Hide()
        -- Try getting the data again
        name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
    end
    
    return name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture
end

-- Function to verify and update item data
function SLG:VerifyItemData(item)
    local itemInfo = self:GetItemInfo(item.id)
    if not itemInfo then
        -- Item not in cache yet, keep existing data
        return item
    end
    
    -- Update item data with client information
    item.name = itemInfo.name
    item.itemType = itemInfo.itemType ~= "" and itemInfo.itemType or item.itemType
    
    return item
end

-- Helper function to get a list of potential difficulty keys to try
function SLG:GetZoneItemDifficultyKeys(difficulty, instanceType, raidInfo)
    local keysToTry = {}
    local size = instanceType:match("raid(%d+)") or instanceType:match("dungeon(%d+)") -- Match raid or dungeon size
    local isHeroic = difficulty == "heroic"

    if size then -- For sized instances (10/25 man raids, or future sized dungeons)
        if isHeroic then
            table.insert(keysToTry, size .. "ManHeroic") -- e.g., 25ManHeroic
            table.insert(keysToTry, "Heroic (" .. size .. ")") -- e.g, Heroic (25)
            table.insert(keysToTry, size .. "Heroic") -- e.g., 25Heroic (less common but possible)
        else
            table.insert(keysToTry, size .. "Man") -- e.g., 25Man
            table.insert(keysToTry, "Normal (" .. size .. ")") -- e.g, Normal (25)
            table.insert(keysToTry, size .. "Normal") -- e.g., 25Normal
        end
    end

    -- General keys (for dungeons or non-sized difficulties in zone_items.lua)
    if isHeroic then
        table.insert(keysToTry, "Heroic")
    else
        table.insert(keysToTry, "Normal")
    end
    
    -- Add the direct difficulty string as a last resort (e.g. "heroic")
    -- table.insert(keysToTry, difficulty) 

    return keysToTry
end

-- Function to filter items based on instance difficulty
function SLG:FilterItemsByDifficulty(items)
    local difficulty, instanceType = self:GetInstanceInfo()
    local currentZone = GetRealZoneText()
    local raidInfo = self.RaidInfo[currentZone]
    local filteredItems = {}
    local stats = {
        total = 0,
        attuned = 0
    }
    
    -- If we're not in an instance, show all items
    if instanceType == "outdoor" then
        return items, stats
    end
    
    for sourceName, sourceItems in pairs(items) do
        local filteredSourceItems = {}
        local hardModes = nil
        
        -- Check for Ulduar hard modes
        if raidInfo and raidInfo.hardModes then
            for bossName, _ in pairs(raidInfo.hardModes) do
                if sourceName:find(bossName) then
                    hardModes = self:GetRaidHardModeInfo(bossName)
                    break
                end
            end
        end
        
        -- Handle new-style difficulty structure (like ICC or custom boss difficulties)
        if type(sourceItems) == "table" and next(sourceItems) ~= nil then
            local itemsForCurrentDifficulty = nil
            local matchedDiffKey = nil
            local potentialKeys = self:GetZoneItemDifficultyKeys(difficulty, instanceType, raidInfo)

            for _, key in ipairs(potentialKeys) do
                if sourceItems[key] and type(sourceItems[key]) == "table" then
                    itemsForCurrentDifficulty = sourceItems[key]
                    matchedDiffKey = key
                    break
                end
            end
            
            if itemsForCurrentDifficulty then
                for _, itemId in ipairs(itemsForCurrentDifficulty) do
                    local itemData = self:GetItemData(itemId)
                    if itemData then
                        if self:CanUseItem(itemData.itemType) then
                            stats.total = stats.total + 1
                            local displaySourceText = sourceName .. " (" .. matchedDiffKey .. ")"
                            if SLGSettings.displayMode == "attuned" then
                                if SCL.IsAttuned(itemId) then
                                    stats.attuned = stats.attuned + 1
                                    table.insert(filteredSourceItems, {
                                        id = itemId,
                                        name = itemData.name,
                                        itemType = itemData.itemType,
                                        source = displaySourceText
                                    })
                                end
                            elseif SLGSettings.displayMode == "not_attuned" then
                                if SCL.IsAttuned(itemId) then
                                    stats.attuned = stats.attuned + 1
                                else
                                    table.insert(filteredSourceItems, {
                                        id = itemId,
                                        name = itemData.name,
                                        itemType = itemData.itemType,
                                        source = displaySourceText
                                    })
                                end
                            elseif SLGSettings.displayMode == "eligible" then
                                -- For eligible, we consider it "attuned" for counting purposes if they can use it
                                stats.attuned = stats.attuned + 1 
                                table.insert(filteredSourceItems, {
                                    id = itemId,
                                    name = itemData.name,
                                    itemType = itemData.itemType,
                                    source = displaySourceText
                                })
                            elseif SLGSettings.displayMode == "all" then
                                table.insert(filteredSourceItems, {
                                    id = itemId,
                                    name = itemData.name,
                                    itemType = itemData.itemType,
                                    source = displaySourceText
                                })
                            end
                        end
                    end
                end
            end
        else
            -- Handle old-style difficulty in source name
            for _, item in ipairs(sourceItems) do
                -- Verify and update item data
                item = self:VerifyItemData(item)
                
                local isHeroic = string.find(item.source, "(Heroic)") ~= nil
                local shouldInclude = false
                
                if instanceType == "dungeon" then
                    if difficulty == "heroic" and isHeroic then
                        shouldInclude = true
                    elseif difficulty == "normal" and not isHeroic then
                        shouldInclude = true
                    end
                elseif instanceType:match("raid%d+") then
                    if raidInfo then
                        local size = instanceType:match("%d+")
                        local sourceSize = item.source:match("(%d+)")
                        
                        -- Check if the item matches the current raid size
                        if sourceSize and sourceSize == size then
                            -- For raids with heroic mode
                            if raidInfo.hasHeroic then
                                if (difficulty == "heroic" and isHeroic) or
                                   (difficulty == "normal" and not isHeroic) then
                                    shouldInclude = true
                                end
                            else
                                shouldInclude = true
                                
                                -- Special handling for Ulduar hard modes
                                if hardModes then
                                    -- TODO: Implement hard mode detection logic
                                    -- For now, show all items
                                    shouldInclude = true
                                end
                            end
                        end
                    else
                        shouldInclude = true
                    end
                else
                    shouldInclude = true
                end
                
                if shouldInclude then
                    if self:CanUseItem(item.itemType) then
                        stats.total = stats.total + 1
                        if SLGSettings.displayMode == "attuned" then
                            if SCL.IsAttuned(item.id) then
                                stats.attuned = stats.attuned + 1
                                table.insert(filteredSourceItems, {
                                    id = item.id,
                                    name = item.name,
                                    itemType = item.itemType,
                                    source = item.source
                                })
                            end
                        elseif SLGSettings.displayMode == "not_attuned" then
                            if SCL.IsAttuned(item.id) then
                                stats.attuned = stats.attuned + 1
                            else
                                table.insert(filteredSourceItems, item)
                            end
                        elseif SLGSettings.displayMode == "eligible" then
                            stats.attuned = stats.attuned + 1
                            table.insert(filteredSourceItems, item)
                        elseif SLGSettings.displayMode == "all" then
                            table.insert(filteredSourceItems, item)
                        end
                    end
                end
            end
        end
        
        if #filteredSourceItems > 0 then
            filteredItems[sourceName] = filteredSourceItems
        end
    end
    
    return filteredItems, stats
end

-- Function to get difficulty text for display
function SLG:GetDifficultyText()
    local difficulty, instanceType = self:GetInstanceInfo()
    local currentZone = GetRealZoneText()
    local raidInfo = self.RaidInfo[currentZone]
    
    if instanceType == "dungeon" then
        return difficulty == "heroic" and " (Heroic)" or " (Normal)"
    elseif instanceType:match("raid%d+") then
        if raidInfo then
            local size = instanceType:match("%d+")
            if raidInfo.hasHeroic then
                return string.format(" (%s %s %s)", size, difficulty:gsub("^%l", string.upper), "Player")
            else
                return string.format(" (%s %s)", size, "Player")
            end
        elseif instanceType == "raid" then
            return " (Legacy)"
        end
    end
    
    return ""
end

-- Helper function to get table keys
function SLG:GetTableKeys(tbl)
    local keys = {}
    if type(tbl) == "table" then
        for k, _ in pairs(tbl) do
            table.insert(keys, k)
        end
    end
    return keys
end

-- Register slash commands
function addon:OnInitialize()
    -- Load settings
    SLG:LoadSettings()
    
    -- Register minimap icon
    if LDBIcon and ldbObj then
        LDBIcon:Register("SynastriaLootGuide", ldbObj, SLGSettings.minimap or SLG.defaults.profile.minimap)
    end
    
    -- Register slash command
    self:RegisterChatCommand("slg", function(input)
        input = input:trim():lower()
        
        if input == "config" or input == "options" then
            InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
            InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide") -- Called twice to overcome a Blizzard bug
        else
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
                SLG:UpdateItemList()
            end
        end
    end)
    
    print("|cFF33FF99SLG|r: Synastria Loot Guide loaded. Use /slg to toggle window, /slg config for options.")
end

-- Function to get zone items
function SLG:GetZoneItems(zoneName)
    local zoneData = self.ZoneItems[zoneName]
    local stats = {
        total = 0,
        attuned = 0
    }
    
    if not zoneData then 
        return nil, stats 
    end
    
    local sourceGroups = {}
    -- Determine current difficulty key
    local difficulty, instanceType = self:GetInstanceInfo()
    local diffKey = nil
    if instanceType:match("raid%d+") then
        local size = instanceType:match("%d+")
        if difficulty == "heroic" then
            diffKey = "Heroic (" .. size .. ")"
        else
            diffKey = "Normal (" .. size .. ")"
        end
    else
        diffKey = difficulty:gsub("^%l", string.upper)
    end
    
    -- Use __order if present for boss ordering
    local bossKeys = zoneData.__order or {}
    local ordered = #bossKeys > 0

    local mode = SLGSettings.displayMode or "not_attuned"
    local showAll = mode == "all"
    local showEligible = mode == "eligible"
    local showAttuned = mode == "attuned"
    local showNotAttuned = mode == "not_attuned"

    local function boss_iter()
        if ordered then
            local i = 0
            return function()
                i = i + 1
                local k = bossKeys[i]
                if k then return k, zoneData[k] end
            end
        else
            return pairs(zoneData)
        end
    end
    
    for sourceName, itemIds in boss_iter() do
        -- Skip __order key
        if sourceName ~= "__order" then
            -- If itemIds is a table of difficulties (e.g., ICC/Ulduar style)
            if type(itemIds) == "table" and (itemIds["Normal"] or itemIds["Normal (25)"] or itemIds["Heroic"] or itemIds["Heroic (25)"]) then
                local keys = {}
                for k, _ in pairs(itemIds) do table.insert(keys, k) end
                -- Only process the sub-table matching diffKey
                if itemIds[diffKey] then
                    local sourceItems = {}
                    for _, itemId in ipairs(itemIds[diffKey]) do
                        local itemData = self:GetItemData(itemId)
                        if itemData then
                            local isAttuned = SCL.IsAttuned(itemId)
                            local canUse = self:CanUseItem(itemData.itemType)

                            if showAll then
                                stats.total = stats.total + 1
                                if isAttuned then stats.attuned = stats.attuned + 1 end
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                            elseif showEligible and canUse then
                                stats.total = stats.total + 1
                                if isAttuned then stats.attuned = stats.attuned + 1 end
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                            elseif showAttuned and canUse and isAttuned then
                                stats.total = stats.total + 1
                                stats.attuned = stats.attuned + 1
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                            elseif showNotAttuned and canUse and not isAttuned then
                                stats.total = stats.total + 1
                                table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                            end
                        end
                    end
                    if #sourceItems > 0 then
                        table.insert(sourceGroups, {
                            source = sourceName .. " (" .. diffKey .. ")",
                            items = sourceItems
                        })
                    end
                end
            else
                -- Flat list (dungeon style)
                local sourceItems = {}
                for _, itemId in ipairs(itemIds) do
                    local itemData = self:GetItemData(itemId)
                    if itemData then
                        local isAttuned = SCL.IsAttuned(itemId)
                        local canUse = self:CanUseItem(itemData.itemType)

                        if showAll then
                            stats.total = stats.total + 1
                            if isAttuned then stats.attuned = stats.attuned + 1 end
                            table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                        elseif showEligible and canUse then
                            stats.total = stats.total + 1
                            if isAttuned then stats.attuned = stats.attuned + 1 end
                            table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                        elseif showAttuned and canUse and isAttuned then
                            stats.total = stats.total + 1
                            stats.attuned = stats.attuned + 1
                            table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                        elseif showNotAttuned and canUse and not isAttuned then
                            stats.total = stats.total + 1
                            table.insert(sourceItems, { id = itemId, name = itemData.name, itemType = itemData.itemType, source = sourceName .. " (" .. diffKey .. ")" })
                        end
                    end
                end
                if #sourceItems > 0 then
                    table.insert(sourceGroups, {
                        source = sourceName,
                        items = sourceItems
                    })
                end
            end
        end
    end
    
    return sourceGroups, stats
end

-- Function to get appropriate difficulty based on player faction
function SLG:GetFactionDifficulties(raidInfo)
    if not raidInfo.isFactionSpecific then
        return raidInfo.difficulties
    end
    
    local faction = UnitFactionGroup("player")
    local difficulties = {}
    for _, diff in ipairs(raidInfo.difficulties) do
        if diff:find(faction) then
            table.insert(difficulties, diff)
        end
    end
    return difficulties
end

-- Make the main window resizable
frame:SetResizable(true)
frame:SetMinResize(320, 240)
frame:SetMaxResize(800, 1000)

-- Add a resize handle
local resizeHandle = CreateFrame("Button", nil, frame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() SLG:UpdateItemList() end)

-- Update scrollFrame/content sizing on resize
local function OnFrameResize(self, width, height)
    scrollFrame:SetWidth(width - 36) -- 24 for scrollbar, 12 for padding
    SLG.scrollContent:SetWidth(scrollFrame:GetWidth())
    SLG:UpdateItemList()
end
frame:SetScript("OnSizeChanged", OnFrameResize)

-- Truncate zone name at the top if too long, and show tooltip
function SLG:TruncateZoneName(text, maxChars)
    if #text > maxChars then
        return text:sub(1, maxChars - 3) .. "...", true
    else
        return text, false
    end
end

-- Helper to check if item is in player's inventory
function SLG:IsItemInInventory(itemId)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if id == itemId then
                return true
            end
        end
    end
    return false
end

-- Helper to check if item is equipped
function SLG:IsItemEquipped(itemId)
    for slot = 1, 19 do -- 1-19 are equip slots
        local id = GetInventoryItemID("player", slot)
        if id == itemId then
            return true
        end
    end
    return false
end

-- Helper to get equipped item link by itemId
function SLG:GetEquippedItemLink(itemId)
    for slot = 1, 19 do
        local id = GetInventoryItemID("player", slot)
        if id == itemId then
            return GetInventoryItemLink("player", slot)
        end
    end
    return nil
end

-- Helper to get inventory item link by itemId
function SLG:GetInventoryItemLink(itemId)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if id == itemId then
                return GetContainerItemLink(bag, slot)
            end
        end
    end
    return nil
end

-- Stub for attunement progress (replace with real SCL function if available)
if not SCL.GetAttuneProgress then
    function SCL.GetAttuneProgress(itemId)
        return 0 -- Always 0% unless implemented
    end
end

function SLG:ExportCollectorData()
    if not SLG_CollectedLoot or not next(SLG_CollectedLoot) then
        print("No collector data to export.")
        return
    end
    local function TableToLua(tbl, indent)
        indent = indent or 0
        local pad = string.rep(" ", indent)
        local s = "{\n"
        for k, v in pairs(tbl) do
            local key = (type(k) == "string" and string.format("[\"%s\"]", k) or string.format("[%d]", k))
            if type(v) == "table" then
                s = s .. pad .. "  " .. key .. " = " .. TableToLua(v, indent + 2) .. ",\n"
            elseif type(v) == "number" then
                s = s .. pad .. "  " .. key .. " = " .. v .. ",\n"
            elseif type(v) == "string" then
                s = s .. pad .. "  " .. key .. " = \"" .. v .. "\",\n"
            end
        end
        s = s .. pad .. "}"
        return s
    end
    local out = "SLG_CollectedLoot = " .. TableToLua(SLG_CollectedLoot)
    print("|cffffd700SLG Collected Loot Export:|r\n" .. out)
end 