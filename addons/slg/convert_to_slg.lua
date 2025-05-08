--[[
Pure Lua AtlasLoot to SLG Converter (Draft 3)
- Loads AtlasLoot data (requires AtlasLoot_Data to be populated)
- Converts to SLG format (zone_items) using BabbleZone and boss names as keys.
- Prints result as a Lua table
]]

-- This script assumes AtlasLoot_Data is already populated in the environment
-- when this script is run. You might need to load it from a file first.

-- Mock a minimal LibStub and Babble environment if running standalone
if not LibStub then
    _G.LibStub = function() return { GetLocale = function() return setmetatable({}, {__index = function(t,k) return k end}) end } end
end
if not AtlasLoot_GetLocaleLibBabble then
    _G.AtlasLoot_GetLocaleLibBabble = function(libName) 
        local babble = setmetatable({}, {__index = function(t,k) return k end}) 
        if _G[libName] then -- If actual Babble table is loaded by data files
            babble = _G[libName]
        end
        return babble
    end
end

-- Initialize BabbleZone for lookups
local BabbleZone = AtlasLoot_GetLocaleLibBabble("LibBabble-Zone-3.0")

local custom_zone_name_map = {
    ["TheShatteredHalls"] = "The Shattered Halls",
    ["UtgardeKeep"] = "Utgarde Keep",
    ["AuchAuchenaiCrypts"] = "Auchenai Crypts",
    ["AuchManaTombs"] = "Mana-Tombs",
    ["AuchSethekkHalls"] = "Sethekk Halls",
    ["CoTHyal"] = "Caverns of Time: Hyjal Summit",
    ["CoTDurnholde"] = "Caverns of Time: Old Hillsbrad Foothills",
    ["CoTStratholme"] = "Caverns of Time: Culling of Stratholme",
    ["HellfireRamparts"] = "Hellfire Ramparts",
    ["HellfireFurnace"] = "The Blood Furnace",
    ["HellfireUnderbog"] = "The Underbog", 
    ["HellfireSteamvault"] = "The Steamvault", 
    ["TempestKeepArcha"] = "Tempest Keep: The Arcatraz",
    ["TempestKeepBoth"] = "Tempest Keep: The Botanica",
    ["TempestKeepMecha"] = "Tempest Keep: The Mechanar",
    ["AhnKahet"] = "Ahn'kahet: The Old Kingdom",
    ["AlteracValley"] = "Alterac Valley",
    ["AuchShadowLabyrinth"] = "Shadow Labyrinth",
    ["AzjolNerub"] = "Azjol-Nerub",
    ["BlackTemple"] = "Black Temple",
    ["BlackfathomDeeps"] = "Blackfathom Deeps",
    ["BlackrockDepths"] = "Blackrock Depths",
    ["BlackrockMountainEnt"] = "Blackrock Mountain Entrance",
    ["BlackrockSpireLower"] = "Blackrock Spire Lower",
    ["BlackrockSpireUpper"] = "Blackrock Spire Upper",
    ["BlackwingLair"] = "Blackwing Lair",
    ["BloodFurnace"] = "Blood Furnace",
    ["CFRSerpentshrineCavern"] = "SerpentShrine Cavern",
    ["CFRTheSlavePens"] = "The Slave Pens",
    ["CFRTheSteamvault"] = "The Steamvault",
    ["CFRTheUnderbog"] = "The Underbog",
    ["CoTBlackMorass"] = "Black Morass",
    ["DireMaulCapitalGardens"] = "DireMaul Capital Gardens",
    ["DireMaulGordokCommons"] = "DireMaul Gordok Commons",
    ["DireMaulWarpwoodQuarter"] = "DireMaul Warpwood Quarter",
    ["Gnomeregan"] = "Gnomeregan",
    ["GruulsLair"] = "Gruul's Lair",
    ["Karazhan"] = "Karazhan",
    ["MagtheridonsLair"] = "Magtheridon's Lair",
    ["Maraudon"] = "Maraudon",
    ["MoltenCore"] = "Molten Core",
    ["Naxxramas"] = "Naxxramas",
    ["RagefireChasm"] = "Ragefire Chasm",
    ["RazorfenDowns"] = "Razorfen Downs",
    ["RazorfenKraul"] = "Razorfen Kraul",
    ["RuinsOfAhnQiraj"] = "Ruins of Ahn'Qiraj",
    ["ScarletMonasteryGraveyard"] = "Scarlet Monastery Graveyard",
    ["ScarletMonasteryLibrary"] = "Scarlet Monastery Library",
    ["ScarletMonasteryArmory"] = "Scarlet Monastery Armory",
    ["ScarletMonasteryCathedral"] = "Scarlet Monastery Cathedral",
    ["Scholomance"] = "Scholomance",
    ["ShadowfangKeep"] = "Shadowfang Keep",
    ["StratholmeMain"] = "Stratholme Main",
    ["StratholmeSide"] = "Stratholme Side",
    ["SunkenTemple"] = "Sunken Temple",
    ["SunwellPlateau"] = "Sunwell Plateau",
    ["TKMagistersTerrace"] = "Magisters Terrace",
    ["TempestKeepEye"] = "Tempest Keep Eye",
    ["TheDragonsEye"] = "The Dragon's Eye",
    ["TheNexus"] = "The Nexus",
    ["TheOcculus"] = "The Occulus",
    ["TheObsidianSanctum"] = "The Obsidian Sanctum",
    ["TheVioletHold"] = "The Violet Hold",
    ["TrialoftheChampion"] = "Trial of the Champion",
    ["TrialoftheCrusader"] = "Trial of the Crusader",
    ["Uldaman"] = "Uldaman",
    ["Ulduar"] = "Ulduar",
    ["UlduarHallsofLightning"] = "Ulduar Hallsof Lightning",
    ["UlduarHallsofStone"] = "Ulduar Hallsof Stone",
    ["UtgardePinnacle"] = "Utgarde Pinnacle",
    ["VaultofArchavon"] = "Vault of Archavon",
    ["WailingCaverns"] = "Wailing Caverns",
    ["ZulAman"] = "Zul'aman",
    ["ZulFarrak"] = "Zul'Farrak",
    ["ZulGurub"] = "Zul'Gurub",
    ["OnyxiasLair"] = "Onyxia's Lair",
    -- Add more mappings as identified
}

-- Utility: serialize Lua table to string (for output)
local function serialize(tbl, indent_level)
    indent_level = indent_level or 0
    local indent_str = string.rep("  ", indent_level)
    local s = ""

    -- Check if it's a simple array (all numeric keys from 1 to #tbl)
    local is_simple_array = true
    local count = 0
    for k, _ in pairs(tbl) do
        count = count + 1
        if type(k) ~= "number" or k < 1 or k > #tbl or math.floor(k) ~= k then
            is_simple_array = false
            break
        end
    end
    if count ~= #tbl then -- Handles cases where #tbl might be 0 but there are non-numeric keys
        is_simple_array = false
    end
    if #tbl == 0 and count > 0 then -- e.g. { ["a"] = 1 } #tbl is 0
        is_simple_array = false
    end


    if is_simple_array and #tbl > 0 then
        s = "{ "
        for i = 1, #tbl do
            local v = tbl[i]
            if type(v) == "table" then
                s = s .. serialize(v, indent_level + 1) -- Should not happen for item lists
            elseif type(v) == "string" then
                s = s .. string.format("%q", v)
            else
                s = s .. tostring(v)
            end
            if i < #tbl then
                s = s .. ", "
            end
        end
        s = s .. " }"
    else -- It's a dictionary-like table or an empty table to be formatted with newlines
        s = s .. "{\n"
        local entries = {}
        for k, v in pairs(tbl) do
            local key_repr
            if type(k) == "string" then
                key_repr = string.format("%s  [%q]", indent_str, k)
            else -- numbers or other types
                key_repr = string.format("%s  [%s]", indent_str, k)
            end
            table.insert(entries, {key_repr = key_repr, value = v, original_key = k})
        end

        -- Sort by original key for consistent output (optional, but good for diffs)
        table.sort(entries, function(a,b) 
            if type(a.original_key) == type(b.original_key) then
                return a.original_key < b.original_key
            else
                return type(a.original_key) < type(b.original_key)
            end
        end)

        for _, entry in ipairs(entries) do
            s = s .. entry.key_repr .. " = "
            if type(entry.value) == "table" then
                s = s .. serialize(entry.value, indent_level + 1)
            elseif type(entry.value) == "string" then
                s = s .. string.format("%q", entry.value)
            else
                s = s .. tostring(entry.value)
            end
            s = s .. ",\n"
        end
        s = s .. string.rep("  ", math.max(0, indent_level - 1)) .. "}"
    end
    return s
end

-- Conversion logic: AtlasLoot -> SLG
local zone_items = {}

if not AtlasLoot_Data or type(AtlasLoot_Data) ~= "table" then
    error("AtlasLoot_Data is not loaded or is not a table. Ensure your AtlasLoot data file is loaded before running this script.")
end

for lootSourceKey, lootSourceData in pairs(AtlasLoot_Data) do
    if type(lootSourceData) == "table" and lootSourceData.info and (lootSourceData.info.instance or lootSourceData.info.zone) and lootSourceData.info.name then
        
        local instanceName = lootSourceData.info.instance -- Used for boss difficulty suffix logic later

        local key_for_babble_lookup
        if lootSourceData.info.zone and lootSourceData.info.zone ~= "" then
            key_for_babble_lookup = lootSourceData.info.zone
        elseif instanceName and instanceName ~= "" then
            local stripped_instance_name = instanceName
            if string.sub(stripped_instance_name, 1, 6) == "Mythic" then
                stripped_instance_name = string.sub(stripped_instance_name, 7)
            end
            -- Now, also check for HC prefix on the potentially already Mythic-stripped name
            if string.sub(stripped_instance_name, 1, 2) == "HC" then
                stripped_instance_name = string.sub(stripped_instance_name, 3)
            end
            
            if stripped_instance_name == "" then -- If stripping resulted in empty, use original
                key_for_babble_lookup = instanceName 
            else
                key_for_babble_lookup = stripped_instance_name
            end
        else
            -- This case implies neither info.zone nor info.instance was valid,
            -- which should be caught by the outer 'if' condition.
            -- If somehow reached, use a very distinct placeholder.
            key_for_babble_lookup = "!!UNRESOLVED_ZONE_FROM_" .. lootSourceKey 
        end

        -- Perform BabbleZone lookup first.
        local babble_lookup_result = BabbleZone[key_for_babble_lookup]

        -- If BabbleZone lookup fails (returns nil) or returns an empty string, use key_for_babble_lookup as the intermediate.
        local intermediate_zone_name
        if not babble_lookup_result or babble_lookup_result == "" then
            intermediate_zone_name = key_for_babble_lookup
        else
            intermediate_zone_name = babble_lookup_result
        end

        -- Now, try the custom map with the intermediate_zone_name.
        -- This allows custom_zone_name_map to override even a successful BabbleZone lookup if needed,
        -- or to provide a pretty name if BabbleZone just returned the key_for_babble_lookup.
        local final_zone_key = custom_zone_name_map[intermediate_zone_name] or intermediate_zone_name

        -- Ensure final_zone_key is not accidentally the boolean true/false from a bad map lookup or empty.
        if type(final_zone_key) ~= "string" or final_zone_key == "" then
            print(string.format("WARNING: final_zone_key became non-string or empty ('%s') after custom_zone_name_map lookup. Original babble_lookup_result: '%s', key_for_babble_lookup: '%s'. Reverting to key_for_babble_lookup.", tostring(final_zone_key), tostring(babble_lookup_result), key_for_babble_lookup))
            final_zone_key = key_for_babble_lookup
            -- As a very last resort if key_for_babble_lookup was also bad (e.g. empty from bad stripping)
            if not final_zone_key or final_zone_key == "" then
                 final_zone_key = "!!ERROR_UNRESOLVED_ZONE_FOR_" .. lootSourceKey
                 print("CRITICAL ERROR: final_zone_key and key_for_babble_lookup are both unusable for " .. lootSourceKey)
            end
        end
        
        -- Debug prints removed
        
        local localizedZoneName = final_zone_key -- This variable is used later to key zone_items table non-stripped instanceName
        if not final_zone_key or final_zone_key == "" then
            final_zone_key = instanceName -- As a last resort
            print("CRITICAL FALLBACK: final_zone_key was empty, using raw instanceName: " .. instanceName .. " for lootSourceKey: " .. lootSourceKey)
        end

        if type(final_zone_key) ~= "string" then
            print(string.format("WARNING: final_zone_key became non-string (%s) for key_for_babble_lookup '%s', localizedZoneName '%s'. Reverting to localizedZoneName.", tostring(final_zone_key), key_for_babble_lookup, localizedZoneName))
            final_zone_key = localizedZoneName
        end

        if not final_zone_key or final_zone_key == "" then -- Check again after potential reversion
            print("CRITICAL ERROR: final_zone_key is empty for " .. lootSourceKey .. ". Babble lookup key was: " .. key_for_babble_lookup .. ", localized name was: " .. localizedZoneName)
            final_zone_key = key_for_babble_lookup -- Prevent erroring out, but log it
        end
        
        -- Debug prints removed
        
        local localizedZoneName = final_zone_key -- This variable is used later to key zone_items table -- Fallback to key if no BabbleZone entry

        local rawBossName = lootSourceData.info.name -- This is already localized by AtlasLoot data files
        local isMythicSource = false
        local cleanedBossName = rawBossName

        if string.sub(rawBossName, -1) == "+" then
            isMythicSource = true
            cleanedBossName = string.sub(rawBossName, 1, -2) -- Remove the trailing '+'
        end

        for difficultyKey, difficulty_table in pairs(lootSourceData) do
            if type(difficulty_table) == "table" and difficultyKey ~= "info" and difficultyKey ~= "module" then
                local bossNameToDisplay = cleanedBossName -- Start with the cleaned name
                local difficultyName = tostring(difficultyKey)

                if isMythicSource then
                    -- This data comes from a Mythic source file (name ended with "+")
                    -- The difficultyKey inside these files is usually "Normal", but we want "(Mythic)"
                    if not string.find(cleanedBossName, "%(Mythic%)", 1, true) then
                        bossNameToDisplay = cleanedBossName .. " (Mythic)"
                    end
                else
                    -- Original logic for Non-Mythic sources (Normal, Heroic, N10, H25 etc.)
                    if string.match(difficultyName, "Heroic") then
                        -- If base name already has (Heroic), like "Boss (Heroic)" from data, don't double append
                        if not string.find(cleanedBossName, "%(Heroic%)", 1, true) then
                             -- Prefer a simple "(Heroic)" for clarity unless it's a specific size like Heroic10/25
                            if difficultyName == "Heroic" then
                                bossNameToDisplay = cleanedBossName .. " (Heroic)"
                            else -- e.g. Heroic10, Heroic25 - append full difficultyName
                                bossNameToDisplay = cleanedBossName .. " (" .. difficultyName .. ")"
                            end
                        end
                    elseif difficultyName ~= "Normal" and difficultyName ~= "LFR" and difficultyName ~= "Timewalking" and difficultyName ~= "Mythic" and difficultyName ~= "MythicKeystone" then
                        -- Handles things like Normal10, Normal25 (non-Heroic, non-Normal base difficulties)
                        -- Ensure we don't append if difficultyName is already in cleanedBossName
                        if not string.find(cleanedBossName, "%(" .. difficultyName .. "%)", 1, true) then
                             bossNameToDisplay = cleanedBossName .. " (" .. difficultyName .. ")"
                        end
                    end
                end
                
                -- Final check to prevent double appends if AtlasLoot info.name ALREADY had a specific difficulty string
                -- This is more of a safeguard. The primary logic is above.
                -- Example: if AtlasLoot info.name was "Boss (10 Player)" and difficultyKey was "Normal10"
                -- The above logic might produce "Boss (10 Player) (Normal10)". This aims to simplify.
                -- However, the current AtlasLoot data doesn't seem to do this often.
                -- The cleanedBossName and specific handling for isMythicSource / Heroic should be more robust.

                -- The most important part is that `bossNameToDisplay` should be correct by now.


                local current_boss_items = {}
                if type(difficulty_table) == "table" then
                    for _, itemListingTable in pairs(difficulty_table) do
                        if type(itemListingTable) == "table" then
                            for _, itemData in pairs(itemListingTable) do
                                if type(itemData) == "table" and itemData[2] and type(itemData[2]) == "number" then
                                    table.insert(current_boss_items, itemData[2])
                                end
                            end
                        end
                    end
                end
                
                if #current_boss_items > 0 then
                    if not zone_items[localizedZoneName] then
                        zone_items[localizedZoneName] = {}
                    end
                    -- Use bossNameToDisplay which now includes (Heroic) or (Mythic) if applicable
                    zone_items[localizedZoneName][bossNameToDisplay] = current_boss_items
                end
            end
        end
    else
        -- print("Skipping key: " .. tostring(lootSourceKey) .. " due to missing info (instance/zone or name).")
    end
end

-- Output the converted table
local outputFile = io.open("zone_items_output.lua", "w")
if outputFile then
    outputFile:write("SLG.ZoneItems = ")

    outputFile:write(serialize(zone_items))
    outputFile:write("\n") -- Added newline for better formatting
    outputFile:close()
    print("Output successfully written to zone_items_output.lua")
else
    print("Error: Could not open zone_items_output.lua for writing!")
end
