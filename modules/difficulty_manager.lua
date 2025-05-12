local addonName, SLG = ...

-- Create the module
local DifficultyManager = {}
SLG:RegisterModule("DifficultyManager", DifficultyManager)

-- Initialize the module
function DifficultyManager:Initialize()
    -- Nothing to initialize yet
end

-- Get current instance info
function DifficultyManager:GetInstanceInfo()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return SLG.Difficulties.NORMAL, SLG.InstanceTypes.OUTDOOR
    end

    local difficultyID = GetInstanceDifficulty()
    local currentZone = GetRealZoneText()
    local raidInfo = SLG.RaidInfo[currentZone]

    -- Check for Mythic Dungeon buff
    local hasMythicBuff = false
    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if name and name:find("Mythic") then
            hasMythicBuff = true
            break
        end
    end

    if instanceType == "party" then
        -- For dungeons, check for mythic buff first
        if hasMythicBuff or difficultyID == 23 then -- 23 is the difficulty ID for mythic dungeons
            return SLG.Difficulties.MYTHIC, SLG.InstanceTypes.DUNGEON
        elseif difficultyID == 2 then
            return SLG.Difficulties.HEROIC, SLG.InstanceTypes.DUNGEON
        else
            return SLG.Difficulties.NORMAL, SLG.InstanceTypes.DUNGEON
        end
    elseif instanceType == "raid" then
        if raidInfo then
            if difficultyID == 1 then
                return SLG.Difficulties.NORMAL, SLG.InstanceTypes.RAID .. "10"
            elseif difficultyID == 2 then
                return SLG.Difficulties.NORMAL, SLG.InstanceTypes.RAID .. "25"
            elseif difficultyID == 3 then
                return SLG.Difficulties.HEROIC, SLG.InstanceTypes.RAID .. "10"
            elseif difficultyID == 4 then
                return SLG.Difficulties.HEROIC, SLG.InstanceTypes.RAID .. "25"
            else
                return "legacy", SLG.InstanceTypes.RAID
            end
        else
            return "legacy", SLG.InstanceTypes.RAID
        end
    end

    return SLG.Difficulties.NORMAL, "unknown"
end

-- Get raid hard mode info
function DifficultyManager:GetRaidHardModeInfo(boss)
    local currentZone = GetRealZoneText()
    local raidInfo = SLG.RaidInfo[currentZone]
    
    if raidInfo and raidInfo.hardModes and raidInfo.hardModes[boss] then
        return raidInfo.hardModes[boss]
    end
    
    return nil
end

-- Get appropriate difficulty based on player faction
function DifficultyManager:GetFactionDifficulties(raidInfo)
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

-- Get difficulty text for display
function DifficultyManager:GetDifficultyText()
    local difficulty, instanceType = self:GetInstanceInfo()
    local currentZone = GetRealZoneText()
    local raidInfo = SLG.RaidInfo[currentZone]
    
    if instanceType == SLG.InstanceTypes.DUNGEON then
        if difficulty == SLG.Difficulties.MYTHIC then
            return " (Mythic)"
        elseif difficulty == SLG.Difficulties.HEROIC then
            return " (Heroic)"
        else
            return " (Normal)"
        end
    elseif instanceType:match("raid%d+") then
        if raidInfo then
            local size = instanceType:match("%d+")
            if raidInfo.hasHeroic then
                return string.format(" (%s %s %s)", size, difficulty:gsub("^%l", string.upper), "Player")
            else
                return string.format(" (%s %s)", size, "Player")
            end
        elseif instanceType == SLG.InstanceTypes.RAID then
            return " (Legacy)"
        end
    end
    
    return ""
end

-- Get a list of potential difficulty keys to try
function DifficultyManager:GetDifficultyKeys(difficulty, instanceType, raidInfo)
    local keysToTry = {}
    local size = instanceType:match("raid(%d+)") or instanceType:match("dungeon(%d+)") -- Match raid or dungeon size
    local isHeroic = difficulty == SLG.Difficulties.HEROIC
    local isMythic = difficulty == SLG.Difficulties.MYTHIC

    -- For dungeons, we want to be very specific about which difficulty we show
    if instanceType == SLG.InstanceTypes.DUNGEON then
        if isMythic then
            table.insert(keysToTry, "Mythic")
            table.insert(keysToTry, "(Mythic)")
        elseif isHeroic then
            table.insert(keysToTry, "Heroic")
            table.insert(keysToTry, "(Heroic)")
        else
            -- For normal dungeons, only show normal items
            table.insert(keysToTry, "Normal")
            -- Also include items with no difficulty specified
            table.insert(keysToTry, "")
        end
        return keysToTry
    end

    -- For raids with sizes
    if size then
        if isHeroic then
            table.insert(keysToTry, size .. "ManHeroic") -- e.g., 25ManHeroic
            table.insert(keysToTry, "Heroic (" .. size .. ")") -- e.g, Heroic (25)
            table.insert(keysToTry, size .. "Heroic") -- e.g., 25Heroic
        else
            table.insert(keysToTry, size .. "Man") -- e.g., 25Man
            table.insert(keysToTry, "Normal (" .. size .. ")") -- e.g, Normal (25)
            table.insert(keysToTry, size .. "Normal") -- e.g., 25Normal
            -- Also include items with no difficulty specified
            table.insert(keysToTry, "")
        end
    else
        -- For non-sized instances
        if isHeroic then
            table.insert(keysToTry, "Heroic")
            table.insert(keysToTry, "(Heroic)")
        else
            table.insert(keysToTry, "Normal")
            table.insert(keysToTry, "")
        end
    end

    return keysToTry
end

-- Check if a source name matches the current difficulty
function DifficultyManager:SourceMatchesDifficulty(sourceName, difficulty)
    -- Extract the difficulty from the source name
    local sourceDiff = sourceName:match("%(([^%)]+)%)")
    
    -- Convert difficulty to lowercase for case-insensitive comparison
    difficulty = difficulty:lower()
    sourceName = sourceName:lower()
    
    -- Check for various difficulty formats
    if sourceName:find("%(mythic%)") or sourceName:find("mythic") then
        return difficulty == SLG.Difficulties.MYTHIC
    elseif sourceName:find("%(25manheroic%)") or sourceName:find("25manheroic") or 
           sourceName:find("%(heroic%)") or sourceName:find("heroic") then
        return difficulty == SLG.Difficulties.HEROIC
    elseif sourceName:find("%(25man%)") or sourceName:find("25man") then
        return difficulty == SLG.Difficulties.NORMAL -- 25-man normal
    else
        -- If no difficulty specified in source name, it's a normal mode item
        return difficulty == SLG.Difficulties.NORMAL
    end
end

-- Return the module
return DifficultyManager 