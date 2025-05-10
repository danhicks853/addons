local addonName, SLG = ...

-- Create the module
local ItemManager = {}
SLG:RegisterModule("ItemManager", ItemManager)

-- Local cache for item data
local itemCache = {}

-- Initialize the module
function ItemManager:Initialize()
    self:ClearCache()
end

-- Clear the item cache
function ItemManager:ClearCache()
    wipe(itemCache)
end

-- Get item data with caching
function ItemManager:GetItemData(itemId)
    if not itemId then return nil end
    
    -- Check cache first
    if itemCache[itemId] then
        return itemCache[itemId]
    end
    
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
    if not name then
        -- Item data not in cache, request it
        GameTooltip:SetHyperlink("item:" .. itemId)
        GameTooltip:Hide()
        name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
        if not name then
            return { id = itemId, name = ("Item %d"):format(itemId), itemType = "", texture = "" }
        end
    end
    
    -- Determine item type
    local itemType = self:DetermineItemType(class, subclass, equipSlot)
    
    -- Cache the result
    local itemData = {
        id = itemId,
        name = name,
        link = link,
        quality = quality,
        itemType = itemType,
        texture = texture
    }
    itemCache[itemId] = itemData
    
    return itemData
end

-- Determine item type based on class and subclass
function ItemManager:DetermineItemType(class, subclass, equipSlot)
    if class == "Armor" then
        if subclass == "Cloth" then return SLG.ItemTypes.ARMOR.CLOTH
        elseif subclass == "Leather" then return SLG.ItemTypes.ARMOR.LEATHER
        elseif subclass == "Mail" then return SLG.ItemTypes.ARMOR.MAIL
        elseif subclass == "Plate" then return SLG.ItemTypes.ARMOR.PLATE
        elseif subclass == "Shields" then return SLG.ItemTypes.WEAPON.SHIELD
        elseif subclass == "Cloaks" or equipSlot == "INVTYPE_CLOAK" then return SLG.ItemTypes.ACCESSORY.CLOAK
        elseif subclass == "Neck" or equipSlot == "INVTYPE_NECK" then return SLG.ItemTypes.ACCESSORY.NECK
        elseif subclass == "Finger" or equipSlot == "INVTYPE_FINGER" then return SLG.ItemTypes.ACCESSORY.RING
        elseif subclass == "Trinket" or equipSlot == "INVTYPE_TRINKET" then return SLG.ItemTypes.ACCESSORY.TRINKET
        end
    elseif class == "Weapon" then
        local weaponMap = {
            ["One-Handed Swords"] = SLG.ItemTypes.WEAPON.ONEHAND_SWORD,
            ["Two-Handed Swords"] = SLG.ItemTypes.WEAPON.TWOHAND_SWORD,
            ["One-Handed Axes"] = SLG.ItemTypes.WEAPON.ONEHAND_AXE,
            ["Two-Handed Axes"] = SLG.ItemTypes.WEAPON.TWOHAND_AXE,
            ["One-Handed Maces"] = SLG.ItemTypes.WEAPON.ONEHAND_MACE,
            ["Two-Handed Maces"] = SLG.ItemTypes.WEAPON.TWOHAND_MACE,
            ["Daggers"] = SLG.ItemTypes.WEAPON.DAGGER,
            ["Fist Weapons"] = SLG.ItemTypes.WEAPON.FIST,
            ["Polearms"] = SLG.ItemTypes.WEAPON.POLEARM,
            ["Staves"] = SLG.ItemTypes.WEAPON.STAFF,
            ["Bows"] = SLG.ItemTypes.WEAPON.BOW,
            ["Crossbows"] = SLG.ItemTypes.WEAPON.CROSSBOW,
            ["Guns"] = SLG.ItemTypes.WEAPON.GUN,
            ["Wands"] = SLG.ItemTypes.WEAPON.WAND
        }
        return weaponMap[subclass] or subclass
    end
    
    return "Misc"
end

-- Check if player can use item type
function ItemManager:CanUseItem(itemType)
    local _, playerClass = UnitClass("player")
    
    -- Primary armor types for each class
    local primaryArmor = {
        ["WARRIOR"] = SLG.ItemTypes.ARMOR.PLATE,
        ["PALADIN"] = SLG.ItemTypes.ARMOR.PLATE,
        ["HUNTER"] = SLG.ItemTypes.ARMOR.MAIL,
        ["ROGUE"] = SLG.ItemTypes.ARMOR.LEATHER,
        ["PRIEST"] = SLG.ItemTypes.ARMOR.CLOTH,
        ["DEATHKNIGHT"] = SLG.ItemTypes.ARMOR.PLATE,
        ["SHAMAN"] = SLG.ItemTypes.ARMOR.MAIL,
        ["MAGE"] = SLG.ItemTypes.ARMOR.CLOTH,
        ["WARLOCK"] = SLG.ItemTypes.ARMOR.CLOTH,
        ["DRUID"] = SLG.ItemTypes.ARMOR.LEATHER
    }
    
    -- Weapon types each class can use
    local weaponTypes = {
        ["WARRIOR"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.TWOHAND_SWORD,
                       SLG.ItemTypes.WEAPON.ONEHAND_AXE, SLG.ItemTypes.WEAPON.TWOHAND_AXE,
                       SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                       SLG.ItemTypes.WEAPON.DAGGER, SLG.ItemTypes.WEAPON.FIST,
                       SLG.ItemTypes.WEAPON.POLEARM, SLG.ItemTypes.WEAPON.STAFF,
                       SLG.ItemTypes.WEAPON.SHIELD},
        ["PALADIN"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.TWOHAND_SWORD,
                       SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                       SLG.ItemTypes.WEAPON.SHIELD},
        ["HUNTER"] = {SLG.ItemTypes.WEAPON.BOW, SLG.ItemTypes.WEAPON.CROSSBOW,
                      SLG.ItemTypes.WEAPON.GUN, SLG.ItemTypes.WEAPON.ONEHAND_SWORD,
                      SLG.ItemTypes.WEAPON.TWOHAND_SWORD, SLG.ItemTypes.WEAPON.ONEHAND_AXE,
                      SLG.ItemTypes.WEAPON.TWOHAND_AXE, SLG.ItemTypes.WEAPON.POLEARM,
                      SLG.ItemTypes.WEAPON.STAFF, SLG.ItemTypes.WEAPON.FIST},
        ["ROGUE"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.ONEHAND_AXE,
                     SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.DAGGER,
                     SLG.ItemTypes.WEAPON.FIST},
        ["PRIEST"] = {SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.DAGGER,
                      SLG.ItemTypes.WEAPON.STAFF, SLG.ItemTypes.WEAPON.WAND},
        ["DEATHKNIGHT"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.TWOHAND_SWORD,
                          SLG.ItemTypes.WEAPON.ONEHAND_AXE, SLG.ItemTypes.WEAPON.TWOHAND_AXE,
                          SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                          SLG.ItemTypes.WEAPON.POLEARM},
        ["SHAMAN"] = {SLG.ItemTypes.WEAPON.ONEHAND_AXE, SLG.ItemTypes.WEAPON.TWOHAND_AXE,
                      SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                      SLG.ItemTypes.WEAPON.DAGGER, SLG.ItemTypes.WEAPON.FIST,
                      SLG.ItemTypes.WEAPON.STAFF, SLG.ItemTypes.WEAPON.SHIELD},
        ["MAGE"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.DAGGER,
                    SLG.ItemTypes.WEAPON.STAFF, SLG.ItemTypes.WEAPON.WAND},
        ["WARLOCK"] = {SLG.ItemTypes.WEAPON.ONEHAND_SWORD, SLG.ItemTypes.WEAPON.DAGGER,
                       SLG.ItemTypes.WEAPON.STAFF, SLG.ItemTypes.WEAPON.WAND},
        ["DRUID"] = {SLG.ItemTypes.WEAPON.ONEHAND_MACE, SLG.ItemTypes.WEAPON.TWOHAND_MACE,
                     SLG.ItemTypes.WEAPON.DAGGER, SLG.ItemTypes.WEAPON.FIST,
                     SLG.ItemTypes.WEAPON.POLEARM, SLG.ItemTypes.WEAPON.STAFF}
    }
    
    -- Check armor type
    if itemType == SLG.ItemTypes.ARMOR.CLOTH or
       itemType == SLG.ItemTypes.ARMOR.LEATHER or
       itemType == SLG.ItemTypes.ARMOR.MAIL or
       itemType == SLG.ItemTypes.ARMOR.PLATE then
        return itemType == primaryArmor[playerClass]
    end
    
    -- Check weapon type
    if weaponTypes[playerClass] then
        for _, type in ipairs(weaponTypes[playerClass]) do
            if type == itemType then
                return true
            end
        end
    end
    
    -- Check accessories (anyone can use)
    if itemType == SLG.ItemTypes.ACCESSORY.NECK or
       itemType == SLG.ItemTypes.ACCESSORY.RING or
       itemType == SLG.ItemTypes.ACCESSORY.TRINKET or
       itemType == SLG.ItemTypes.ACCESSORY.CLOAK then
        return true
    end
    
    return false
end

-- Check if item is in player's inventory
function ItemManager:IsItemInInventory(itemId)
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

-- Check if item is equipped
function ItemManager:IsItemEquipped(itemId)
    for slot = 1, 19 do
        local id = GetInventoryItemID("player", slot)
        if id == itemId then
            return true
        end
    end
    return false
end

-- Get equipped item link
function ItemManager:GetEquippedItemLink(itemId)
    for slot = 1, 19 do
        local id = GetInventoryItemID("player", slot)
        if id == itemId then
            return GetInventoryItemLink("player", slot)
        end
    end
    return nil
end

-- Get inventory item link
function ItemManager:GetInventoryItemLink(itemId)
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

-- Return the module
return ItemManager 