local addonName, SLG = ...

-- Create the module
local Helpers = {}
SLG:RegisterModule("Helpers", Helpers)

-- Table functions
function Helpers:TableCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = self:TableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Helpers:TableMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) == "table" then
                self:TableMerge(t1[k], v)
            else
                t1[k] = self:TableCopy(v)
            end
        else
            t1[k] = v
        end
    end
    return t1
end

function Helpers:TableKeys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

-- String functions
function Helpers:TruncateString(str, length)
    if #str > length then
        return str:sub(1, length - 3) .. "..."
    end
    return str
end

function Helpers:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

function Helpers:ColorText(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

-- Color functions
function Helpers:RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function Helpers:HexToRGB(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
           tonumber("0x" .. hex:sub(3, 4)) / 255,
           tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Frame functions
function Helpers:GetScreenSize()
    return UIParent:GetWidth(), UIParent:GetHeight()
end

function Helpers:ClampToScreen(frame)
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local screenWidth, screenHeight = self:GetScreenSize()
    local point, parent, relativePoint, x, y = frame:GetPoint()
    
    x = math.max(0, math.min(x, screenWidth - width))
    y = math.max(0, math.min(y, screenHeight - height))
    
    frame:ClearAllPoints()
    frame:SetPoint(point, parent, relativePoint, x, y)
end

-- Debug functions
function Helpers:Debug(...)
    if SLGSettings.debug then
        print("|cFF33FF99SLG Debug:|r", ...)
    end
end

function Helpers:Dump(o, depth)
    if not SLGSettings.debug then return end
    
    depth = depth or 0
    local indent = string.rep("  ", depth)
    
    if type(o) == "table" then
        local s = "{\n"
        for k, v in pairs(o) do
            if type(k) ~= "number" then k = '"' .. k .. '"' end
            s = s .. indent .. "[" .. k .. "] = " .. self:Dump(v, depth + 1) .. ",\n"
        end
        return s .. indent .. "}"
    else
        return tostring(o)
    end
end

-- Return the module
return Helpers 