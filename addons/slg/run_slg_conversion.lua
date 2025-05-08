-- run_slg_conversion.lua

-- Define AtlasLoot_Data if it's not globally defined by your files
_G.AtlasLoot_Data = _G.AtlasLoot_Data or {}

-- Mock LibStub and Babble for standalone execution
if not _G.LibStub then
    _G.LibStub = function() return { GetLocale = function() return setmetatable({}, {__index = function(t,k) return k end}) end } end
end
if not _G.AtlasLoot_GetLocaleLibBabble then
    _G.AtlasLoot_GetLocaleLibBabble = function() return setmetatable({}, {__index = function(t,k) return k end}) end
end

-- Define LOCALIZED_CLASS_NAMES_MALE if it's not globally defined
_G.LOCALIZED_CLASS_NAMES_MALE = _G.LOCALIZED_CLASS_NAMES_MALE or {
    DEATHKNIGHT = "Death Knight",
    DRUID = "Druid",
    HUNTER = "Hunter",
    MAGE = "Mage",
    PALADIN = "Paladin",
    PRIEST = "Priest",
    ROGUE = "Rogue",
    SHAMAN = "Shaman",
    WARLOCK = "Warlock",
    WARRIOR = "Warrior",
}
    
-- Load your AtlasLoot data files here.
-- The dofile() function executes the Lua file in the current environment.
-- Add all AtlasLoot data files you want to process.
print("-- Loading AtlasLoot data files...")
local data_files = {
    "atlaslootdata/AtlasLoot_MythicBC.lua", -- Relative to this script's location
    "atlaslootdata/AtlasLoot_MythicWotLK.lua",
    "atlaslootdata/burningcrusade.lua",
    "atlaslootdata/classicwow.lua",
    "atlaslootdata/wrathofthelichking.lua",
    -- Add other data files here, e.g., "atlaslootdata/AtlasLoot_Classic.lua"
}

for _, file_path in ipairs(data_files) do
    local success, err = pcall(dofile, file_path)
    if not success then
        print(string.format("Error loading %s: %s", file_path, tostring(err)))
    else
        print(string.format("Successfully loaded %s", file_path))
    end
end

print("-- All data files processed. AtlasLoot_Data should be populated.")
print("-- Running conversion script...")

-- Now run the conversion script
dofile("convert_to_slg.lua")

print("-- Conversion finished.")
