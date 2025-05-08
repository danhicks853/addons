-- Synastria-LootGrindr: Minimal version
-- /slg opens a frame listing all items in the current zone

local ADDON_NAME = "Synastria-LootGrindr"
local frame = nil
local SynastriaItemDB = LibStub and LibStub("SynastriaItemDB-1.0", true)

-- Utility: get current zone name
local function GetCurrentZone()
	return GetRealZoneText() or "Unknown"
end

-- Utility: get items for the current zone (fallback: all items)
local function GetZoneItems()
	if not SynastriaItemDB or not SynastriaItemDB.items then return {} end
	local zone = GetCurrentZone()
	local results = {}
	for itemID, item in pairs(SynastriaItemDB.items) do
		if type(item) == "table" and (item.zone == zone or item.zoneName == zone) then
			table.insert(results, item)
		end
	end
	-- fallback: if nothing found, show all
	if #results == 0 then
		for itemID, item in pairs(SynastriaItemDB.items) do
			if type(item) == "table" then table.insert(results, item) end
		end
	end
	return results
end

-- Create or show the main frame
local function ShowLootFrame()
	if not frame then
		frame = CreateFrame("Frame", "SynastriaLootGrindrFrame", UIParent)
		frame:SetSize(400, 400)
		frame:SetPoint("CENTER")
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		frame:SetBackdropColor(0,0,0,1)
		-- Simple title
		frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
		frame.title:SetText("Synastria-LootGrindr: Items in Zone")
		frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		frame.scroll:SetPoint("TOPLEFT", 10, -30)
		frame.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
		frame.content = CreateFrame("Frame", nil, frame)
		frame.content:SetSize(360, 360)
		frame.scroll:SetScrollChild(frame.content)
	end
	-- Clear previous content
	for i, child in ipairs({frame.content:GetChildren()}) do child:Hide() end
	-- List items
	local items = GetZoneItems()
	local y = -10
	for i, item in ipairs(items) do
		local text = frame.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("TOPLEFT", 10, y)
		text:SetText((item.name or ("ItemID: "..(item.itemID or "?"))) .. (item.zone and (" | "..item.zone) or ""))
		y = y - 18
	end
	frame:Show()
end

-- Slash command
SLASH_SYNASTRIALOOTGRINDR1 = "/slg"
SlashCmdList["SYNASTRIALOOTGRINDR"] = function()
	ShowLootFrame()
end
