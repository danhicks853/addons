local addonName, SLG = ...
SLG.version = GetAddOnMetadata(addonName, "Version")

-- Initialize the addon using AceAddon
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")
SLG.addon = addon

-- Slash command for loot DB test
SLASH_SLGLOOTDB1 = "/slglootdb"
SlashCmdList["SLGLOOTDB"] = function(msg)
    local itemId = tonumber(msg and msg:match("%d+"))
    if not itemId then
        return
    end
    local helpers = SLG.modules["Helpers"]
    if helpers and helpers.TestLootDB then
        helpers:TestLootDB(itemId)
    else
    end
end

-- Slash command for DB Test Window
SLASH_SLGDBTEST1 = "/slgdbtest"
SlashCmdList["SLGDBTEST"] = function()
    local dbtest = SLG.modules["DBTestWindow"]
    if dbtest and dbtest.Toggle then
        dbtest:Toggle()
    else
    end
end

-- Core tables
SLG.modules = {}
SLG.frames = {}
SLG.cache = {}

-- Module registration
function SLG:RegisterModule(name, module)

    self.modules[name] = module
    return module
end

-- Settings initialization
function addon:InitializeSettings()

    if not SLGSettings then

        SLGSettings = CopyTable(SLG.defaults.profile)
    else

        -- Ensure minimap settings exist
        if not SLGSettings.minimap then
            SLGSettings.minimap = CopyTable(SLG.defaults.profile.minimap)
        end
    end
end

-- Initialization function
function addon:OnInitialize()

    -- Load settings
    self:InitializeSettings()
    
    -- Register options

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
    for name, module in pairs(SLG.modules) do
        if module.Initialize then
            module:Initialize()
        end
    end
    
    -- Register slash commands
    self:RegisterChatCommand("slg", function(input)
        self:HandleSlashCommand(input)
    end)
    
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