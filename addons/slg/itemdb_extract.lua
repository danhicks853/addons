-- Standalone Lua script to extract all valid items from the item DB
-- Intended for use in a dev environment where GetItemInfo is available

local itemdb = {}  -- Table to hold found items

for itemId = 1, 99999 do
    local name, link, quality, level, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemId)
    if name then
        itemdb[itemId] = {
            name = name,
            link = link,
            quality = quality,
            level = level,
            reqLevel = reqLevel,
            class = class,
            subclass = subclass,
            maxStack = maxStack,
            equipSlot = equipSlot,
            texture = texture,
        }
        -- Optional: Print progress every 1000 items
        if itemId % 1000 == 0 then
            print("Checked itemId:", itemId)
        end
    end
end

-- Serialize the table to a file or string
-- Simple print as Lua table (for copy-paste)
print("itemdb = {")
for id, data in pairs(itemdb) do
    print(string.format("  [%d] = { name = %q, link = %q, quality = %s, level = %s, reqLevel = %s, class = %q, subclass = %q, maxStack = %s, equipSlot = %q, texture = %q },",
        id, data.name, data.link, tostring(data.quality), tostring(data.level), tostring(data.reqLevel),
        data.class or "", data.subclass or "", tostring(data.maxStack), data.equipSlot or "", data.texture or ""))
end
print("}")
