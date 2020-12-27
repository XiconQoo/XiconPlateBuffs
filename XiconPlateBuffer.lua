local debug = false
local ADDON_NAME = "XiconPlateBuffer"
local select, tonumber, tostring = select, tonumber, tostring
local XiconPlateBufferDB_local

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local COMBATLOG_OBJECT_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local trackedCC = initTrackedCrowdControl()

local trackedNames = {}

local print = function(s)
    local str = s
    if s == nil then str = "" end
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa".. ADDON_NAME .."|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- FRAME SETUP FOR REGISTER EVENTS

---------------------------------------------------------------------------------------------

-- create core
local plateBuffer = CreateFrame("Frame", "plateBuffer", UIParent)
plateBuffer:EnableMouse(false)
plateBuffer:SetWidth(1)
plateBuffer:SetHeight(1)
plateBuffer:SetAlpha(0)

local plateFrame = CreateFrame("Frame")

---------------------------------------------------------------------------------------------

-- TABLE FUNCTIONS

---------------------------------------------------------------------------------------------

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

local getname = function(f)
    local name
    local _, _, _, _, eman, lvl, eman2 = f:GetRegions()
    if f.aloftData then
        name = f.aloftData.name
    elseif strmatch(eman:GetText(), "%d") then
        local _, _, _, _, _, eman = f:GetRegions()
        name = eman:GetText()
    else
        name = eman:GetText()
    end
    return name
end

---------------------------------------------------------------------------------------------

-- DEBUFF FUNCTIONS

---------------------------------------------------------------------------------------------

local function addDebuff(destName, destGUID, spellID, spellName)
    if trackedNames[destName] == nil then
        trackedNames[destName] = {}
    end
    local _, _, texture = GetSpellInfo(spellID)
    local duration = trackedCC[spellName].duration
    local icon = CreateFrame("frame", nil, UIParent)
    --if spellID == 42292 or spellID == 59752 then texture = "Interface\\Icons\\inv_jewelry_trinketpvp_02" end
    icon.texture = icon:CreateTexture(nil, "BORDER")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexture(texture)
    icon.cooldown = icon:CreateFontString(nil, "OVERLAY")--CreateFrame("Cooldown", nil, icon)
    icon.cooldown:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")

    icon.cooldown:SetTextColor(0.7, 1, 0)
    icon.cooldown:SetAllPoints(icon)
    icon.endtime = GetTime() + duration
    icon.name = spellName

    local icontimer = function(icon)
        --if not Icicledb.fontSize then Icicledb.fontSize = ceil(Icicledb.iconsizer - Icicledb.iconsizer  / 2) end
        local itimer = ceil(icon.endtime - GetTime()) -- cooldown duration
        if itimer >= 60 then
            icon.cooldown:SetText(itimer)
            if itimer < 60 and itimer >= 90 then
                icon.cooldown:SetText("2m")
            else
                icon.cooldown:SetText(ceil(itimer / 60) .. "m") -- X minutes
            end
        elseif itimer < 60 and itimer >= 11 then
            --if it's less than 60s
            icon.cooldown:SetText(itimer)
        elseif itimer <= 10 and itimer >= 4 then
            icon.cooldown:SetTextColor(1, 0.7, 0)
            icon.cooldown:SetText(itimer)
        elseif itimer <= 3 and itimer >= 1 then
            icon.cooldown:SetTextColor(1, 0, 0)
            icon.cooldown:SetText(itimer)
        elseif itimer <= 0 then
            icon:Hide()
            icon:SetParent(nil)
        else
            icon.cooldown:SetText(" ")
            icon:SetScript("OnUpdate", nil)
        end
    end

    for i = 1, #trackedNames[destName] do
        if trackedNames[destName][i] then
            if trackedNames[destName][i].name == spellName then
                if trackedNames[destName][i]:IsVisible() then
                    local f = trackedNames[destName][i]:GetParent()
                    if f.xiconplate then
                        f.xiconplate = 0
                    end
                end
                trackedNames[destName][i]:Hide()
                trackedNames[destName][i]:SetParent(nil)
                tremove(trackedNames[destName], i)
                --count = count - 1
            end
        end
    end

    tinsert(trackedNames[destName], icon)
    icon:SetScript("OnUpdate", function()
        icontimer(icon)
    end)
end

local function removeDebuff(destName, destGUID, spellID, spellName)
    if trackedNames[destName] == nil then
        return
    end
    for i = 1, #trackedNames[destName] do
        if trackedNames[destName][i] then
            if trackedNames[destName][i].name == spellName then
                trackedNames[destName][i]:Hide()
                trackedNames[destName][i]:SetParent(nil)
                tremove(trackedNames[destName], i)
                break
                --count = count - 1
            end
        end
    end
end

local width
local function addicons(name, f, spellID)
    --name returns ___, f returns table value
    local num = #trackedNames[name] --number = db number
    local size
    if not width then
        width = f:GetWidth()
    end
    if num * 20 + (num * 2 - 2) > width then
        size = (width - (num * 2 - 2)) / num
    else
        size = 50
    end
    for i = 1, #trackedNames[name] do
        trackedNames[name][i]:ClearAllPoints()
        trackedNames[name][i]:SetWidth(size)
        trackedNames[name][i]:SetHeight(size)
        trackedNames[name][i].cooldown:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE") --
        if i == 1 then
            trackedNames[name][i]:SetPoint("TOPLEFT", f, 31, size + -4)
        else
            trackedNames[name][i]:SetPoint("TOPLEFT", trackedNames[name][i - 1], size + 2, 0)
        end
    end
end

local function hideicons(name, f)
    f.xiconplate = 0
    for i = 1, #trackedNames[name] do
        trackedNames[name][i]:Hide()
        trackedNames[name][i]:SetParent(nil)
    end
    f:SetScript("OnHide", nil)
end

---------------------------------------------------------------------------------------------

-- EVENT HANDLERS

---------------------------------------------------------------------------------------------

local events = {} -- store event functions to be assigned to reputation frame

function events:ADDON_LOADED(...)
    if select(1, ...) == ADDON_NAME then
        print("LOADED - \"/xtc\" toggles the display frame. \"/xtc enable/disable\" enables or disables the addon")
        XiconPlateBufferDB_local = XiconPlateBufferDB
        if not XiconPlateBufferDB_local then
            XiconPlateBufferDB_local = {}
            XiconPlateBufferDB = XiconPlateBufferDB_local
        end

        local date = date("%m/%d/%y")
        plateBuffer:UnregisterEvent("ADDON_LOADED")
    end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, auraType, stackCount = select(1, ...)
    local isEnemy = bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_NEUTRAL) == COMBATLOG_OBJECT_REACTION_NEUTRAL
    local playerGUID = UnitGUID("player")
    if playerGUID == srcGUID then
        --print(eventType .. " - " .. spellName)
    end
    if trackedCC[spellName] then
        --print(eventType .. " - " .. spellName)
    end
    if isEnemy and eventType == "SPELL_AURA_APPLIED" and trackedCC[spellName] then
        print(eventType .. " - " .. spellName .. " - addDebuff")
        addDebuff(dstName, dstGUID, spellID, spellName)
    end
    if isEnemy and (eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPEL") and trackedCC[spellName] then
        print(eventType .. " - " .. spellName .. " - " .. dstName .. " - removeDebuff")
        removeDebuff(dstName, dstGUID, spellID, spellName)
    end
    if isEnemy and playerGUID == srcGUID and trackedCC[spellName] then
        if eventType == "SPELL_CAST_SUCCESS" and spellSchool == 1 then -- melee hits only
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_AURA_APPLIED" then
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_AURA_REFRESH" then
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_MISSED" then
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_AURA_BROKEN_SPELL" then
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_AURA_BROKEN" then
            print(eventType .. " - " .. spellName)
        elseif eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPEL" then
            print(eventType .. " - " .. spellName)
        end
    end--_AURA_BROKEN_SPELL _AURA_BROKEN
end

function events:PLAYER_LOGOUT(...)
    XiconPlateBufferDB = XiconPlateBufferDB_local
end


---------------------------------------------------------------------------------------------

-- REGISTER EVENTS

---------------------------------------------------------------------------------------------

plateBuffer:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, _ in pairs(events) do
    plateBuffer:RegisterEvent(k); -- Register all events for which handlers have been defined
end

---------------------------------------------------------------------------------------------

-- ON_UPDATE

---------------------------------------------------------------------------------------------

local updateInterval, lastUpdate, dateUpdate = 0.02,0
plateBuffer:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        -- do stuff
        local num = WorldFrame:GetNumChildren()
        for i = 1, num do
            local f = select(i, WorldFrame:GetChildren())
            if not f.xiconplate then
                f.xiconplate = 0
            end
            if f:GetNumRegions() > 2 and f:GetNumChildren() >= 1 then
                if f:IsVisible() then
                    local name = getname(f)
                    if trackedNames[name] ~= nil then
                        if f.xiconplate ~= #trackedNames[name] then
                            f.xiconplate = #trackedNames[name]
                            print("f.xiconplate = " .. f.xiconplate .. " - #trackedNames[name] = " .. #trackedNames[name] .. " - name = " .. name)
                            for j = 1, #trackedNames[name] do
                                trackedNames[name][j]:SetParent(f)
                                trackedNames[name][j]:Show()
                            end
                            addicons(name, f)
                            f:SetScript("OnHide", function()
                                hideicons(name, f)
                            end)
                        end
                    end
                end
            end
        end
        -- end do stuff
        lastUpdate = 0;
    end
end)

---------------------------------------------------------------------------------------------

-- SLASH COMMAND

---------------------------------------------------------------------------------------------

SLASH_XICONPLATEBUFFER1 = "/xpb";

local enable, disable, trinket1, trinket2= "enable", "disable", "1", "2"

local function XICONPLATEBUFFERfunc(msg)
    if msg == "" then

    else
        local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
        print("cmd = \"" .. cmd .. "\"")
        if cmd == "" and not XiconPlateBufferDB_local["enabled"] then

        end
    end
end

SlashCmdList["XICONPLATEBUFFER"] = XICONPLATEBUFFERfunc;