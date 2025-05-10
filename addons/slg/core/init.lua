local addonName, SLG = ...
print("SLG Debug: Starting initialization...")
SLG.version = GetAddOnMetadata(addonName, "Version")

-- Initialize the addon using AceAddon
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
print("SLG Debug: Created AceAddon instance")
SLG.addon = addon

-- Slash command for loot DB test
SLASH_SLGLOOTDB1 = "/slglootdb"
SlashCmdList["SLGLOOTDB"] = function(msg)
    local itemId = tonumber(msg and msg:match("%d+"))
    if not itemId then
        print("Usage: /slglootdb <itemId>")
        return
    end
    local helpers = SLG.modules["Helpers"]
    if helpers and helpers.TestLootDB then
        helpers:TestLootDB(itemId)
    else
        print("Helpers module or TestLootDB not found.")
    end
end

-- Slash command for DB Test Window
SLASH_SLGDBTEST1 = "/slgdbtest"
SlashCmdList["SLGDBTEST"] = function()
    local dbtest = SLG.modules["DBTestWindow"]
    if dbtest and dbtest.Toggle then
        dbtest:Toggle()
    else
        print("DBTestWindow module not found.")
    end
end

-- Core tables
SLG.modules = {}
SLG.frames = {}
SLG.cache = {}

-- Module registration
function SLG:RegisterModule(name, module)
    print("SLG Debug: Registering module:", name)
    self.modules[name] = module
    return module
end

-- Settings initialization
function addon:InitializeSettings()
    print("SLG Debug: Initializing settings...")
    if not SLGSettings then
        print("SLG Debug: Creating new settings from defaults")
        SLGSettings = CopyTable(SLG.defaults.profile)
    else
        print("SLG Debug: Using existing settings")
        -- Ensure minimap settings exist
        if not SLGSettings.minimap then
            SLGSettings.minimap = CopyTable(SLG.defaults.profile.minimap)
        end
    end
end

-- Initialization function
function addon:OnInitialize()
    print("SLG Debug: OnInitialize called")
    -- Load settings
    self:InitializeSettings()
    
    -- Register options
    print("SLG Debug: Registering options...")
    local options = {
        name = "Synastria Loot Guide",
        handler = self,
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
                set = function(_, value) 
                    SLGSettings.displayMode = value
                    if SLG.modules.ItemList then
                        SLG.modules.ItemList:UpdateDisplay()
                    end
                end,
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
            collectorEnabledDesc = {
                type = "description",
                name = "Currently this functionality has been disabled in the code. The collector module allows me to scrape item info from vendors, loot events, and inventory. This is a Dev feature.",
                order = 10.1,
                fontSize = "medium"
            },
            collectorExport = {
                type = "execute",
                name = "Export Collector Data",
                desc = "Export the collected loot data to the chat window (copy from chat).",
                func = function() 
                    if SLG.modules.Collector then
                        SLG.modules.Collector:ExportData()
                    end
                end,
                order = 12,
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
    
    -- Register the options table first
    local AceConfig = LibStub("AceConfig-3.0")
    AceConfig:RegisterOptionsTable("slg", options)
    
    -- Then add to Blizzard options
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigDialog:AddToBlizOptions("slg", "Synastria Loot Guide")
    
    -- Initialize modules
    print("SLG Debug: Initializing modules...")
    for name, module in pairs(SLG.modules) do
        if module.Initialize then
            print("SLG Debug: Initializing module:", name)
            module:Initialize()
        end
    end
    
    -- Register slash commands
    print("SLG Debug: Registering slash commands...")
    self:RegisterChatCommand("slg", function(input)
        self:HandleSlashCommand(input)
    end)
    
    -- Print loaded message
    print("|cFF33FF99SLG|r loaded. Type /slg")
end

-- Slash command handler
function addon:HandleSlashCommand(input)
    input = input:trim():lower()
    
    if input == "config" or input == "options" then
        InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide")
        InterfaceOptionsFrame_OpenToCategory("Synastria Loot Guide") -- Called twice to overcome a Blizzard bug
    else
        if SLG.modules.MainWindow then
            SLG.modules.MainWindow:Toggle()
        end
    end
end 