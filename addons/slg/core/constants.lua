local addonName, SLG = ...

-- Default settings
SLG.defaults = {
    profile = {
        autoOpen = false,
        autoOpenOnZoneChange = false,
        minimap = { hide = false },
        displayMode = "not_attuned",
        collectorEnabled = true,
        collectorExportPath = "SLG_CollectedLoot.lua"
    }
}

-- Raid configuration
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
        difficulties = {"Alliance", "Alliance (25)", "Alliance Heroic", "Alliance Heroic (25)", 
                       "Horde", "Horde (25)", "Horde Heroic", "Horde Heroic (25)"},
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

-- Display modes
SLG.DisplayModes = {
    ATTUNED = "attuned",
    NOT_ATTUNED = "not_attuned",
    ELIGIBLE = "eligible",
    ALL = "all"
}

-- Instance types
SLG.InstanceTypes = {
    DUNGEON = "dungeon",
    RAID = "raid",
    OUTDOOR = "outdoor"
}

-- Difficulty levels
SLG.Difficulties = {
    NORMAL = "normal",
    HEROIC = "heroic",
    MYTHIC = "mythic"
}

-- Item types
SLG.ItemTypes = {
    ARMOR = {
        CLOTH = "Cloth",
        LEATHER = "Leather",
        MAIL = "Mail",
        PLATE = "Plate"
    },
    WEAPON = {
        ONEHAND_SWORD = "1H Sword",
        TWOHAND_SWORD = "2H Sword",
        ONEHAND_AXE = "1H Axe",
        TWOHAND_AXE = "2H Axe",
        ONEHAND_MACE = "1H Mace",
        TWOHAND_MACE = "2H Mace",
        DAGGER = "Dagger",
        FIST = "Fist Weapon",
        POLEARM = "Polearm",
        STAFF = "Staff",
        BOW = "Bow",
        CROSSBOW = "Crossbow",
        GUN = "Gun",
        WAND = "Wand",
        SHIELD = "Shield"
    },
    ACCESSORY = {
        NECK = "Neck",
        RING = "Ring",
        TRINKET = "Trinket",
        CLOAK = "Cloak"
    }
}

-- UI constants
SLG.UI = {
    FRAME_PADDING = 1,
    ITEM_HEIGHT = 18,
    SOURCE_HEIGHT = 18,
    TITLE_HEIGHT = 56,
    SCROLL_WIDTH = 16,
    MIN_WINDOW_WIDTH = 300,
    DEFAULT_WINDOW_HEIGHT = 400
}

-- Colors
SLG.Colors = {
    TITLE = { r = 1, g = 1, b = 1 },
    ATTUNED = { r = 0, g = 1, b = 0 },
    NOT_ATTUNED = { r = 1, g = 1, b = 1 },
    ATTUNING = { r = 0.2, g = 0.6, b = 1 },
    SOURCE = { r = 1, g = 0.8, b = 0 },
    ADDON = "|cFF33FF99",
    ERROR = "|cFFFF0000",
    SUCCESS = "|cFF00FF00"
}

-- Zone categories
SLG.ZoneCategories = {
    CLASSIC = {
        name = "Classic",
        zones = {
            "Blackfathom Deeps",
            "Blackrock Depths",
            "Lower Blackrock Spire",
            "Upper Blackrock Spire",
            "Blackwing Lair",
            "Molten Core",
            "Onyxia's Lair",
            "Zul'Gurub",
            "Ruins of Ahn'Qiraj",
            "Temple of Ahn'Qiraj"
        }
    },
    TBC = {
        name = "Burning Crusade",
        zones = {
            "Auchenai Crypts",
            "Black Morass",
            "Blood Furnace",
            "Botanica",
            "Mechanar",
            "Arcatraz",
            "Mana-Tombs",
            "Old Hillsbrad Foothills",
            "Sethekk Halls",
            "Shadow Labyrinth",
            "Shattered Halls",
            "Slave Pens",
            "Steamvault",
            "Underbog",
            "Magtheridon's Lair",
            "Gruul's Lair",
            "Serpentshrine Cavern",
            "Tempest Keep",
            "Black Temple",
            "Mount Hyjal",
            "Zul'Aman",
            "Sunwell Plateau"
        }
    },
    WOTLK = {
        name = "Wrath of the Lich King",
        zones = {
            "Utgarde Keep",
            "The Nexus",
            "Azjol-Nerub",
            "Ahn'kahet: The Old Kingdom",
            "Drak'Tharon Keep",
            "The Violet Hold",
            "Gundrak",
            "Halls of Stone",
            "Halls of Lightning",
            "The Oculus",
            "Culling of Stratholme",
            "Utgarde Pinnacle",
            "Trial of the Champion",
            "Forge of Souls",
            "Pit of Saron",
            "Halls of Reflection",
            "Naxxramas",
            "Obsidian Sanctum",
            "Eye of Eternity",
            "Vault of Archavon",
            "Ulduar",
            "Trial of the Crusader",
            "Onyxia's Lair",
            "Icecrown Citadel",
            "Ruby Sanctum"
        }
    },
    CITIES = {
        name = "Cities & Special",
        zones = {
            "Dalaran",
            "Shattrath City",
            "Stormwind City",
            "Ironforge",
            "Darnassus",
            "Exodar",
            "Orgrimmar",
            "Thunder Bluff",
            "Undercity",
            "Silvermoon City"
        }
    }
} 