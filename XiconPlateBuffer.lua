local debug = false
local ADDON_NAME = "XiconPlateBuffer"
local select, tonumber, tostring = select, tonumber, tostring
local XiconPlateBufferDB_local

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local COMBATLOG_OBJECT_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local trackedCC = initTrackedCrowdControl()

local trackedUnitNames = {}

local print = function(s)
    local str = s
    if s == nil then str = "" end
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa".. ADDON_NAME .."|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- FRAME SETUP FOR REGISTER EVENTS

---------------------------------------------------------------------------------------------

-- create core
local xiconPlateBuffer = CreateFrame("Frame", "xiconPlateBuffer", UIParent)
xiconPlateBuffer:EnableMouse(false)
xiconPlateBuffer:SetWidth(1)
xiconPlateBuffer:SetHeight(1)
xiconPlateBuffer:SetAlpha(0)

---------------------------------------------------------------------------------------------

-- TABLE & MATH FUNCTIONS

---------------------------------------------------------------------------------------------

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

local function getName(namePlate)
    local name
    local _, _, _, _, eman, lvl, eman2 = namePlate:GetRegions()
    if namePlate.aloftData then
        name = namePlate.aloftData.name
    elseif strmatch(eman:GetText(), "%d") then
        local _, _, _, _, _, eman = namePlate:GetRegions()
        name = eman:GetText()
    else
        name = eman:GetText()
    end
    name = string.gsub(name, "%s+", "")
    return name
end

local function formatTimer(num, numDecimalPlaces)
    return string.format("%." .. (numDecimalPlaces or 0) .. "f", num)
end

local function round(num, numDecimalPlaces)
    return tonumber(formatTimer(num, numDecimalPlaces))
end

local function split(str, separator)
    local fields = {}

    local sep = separator or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

---------------------------------------------------------------------------------------------

-- TARGETING FUNCTIONS

---------------------------------------------------------------------------------------------

local function IsValidTarget(unit)
    return UnitCanAttack("player", unit) == 1 and not UnitIsDeadOrGhost(unit)
end

local function getUnitTargetedByMe(unitGUID)
    if UnitGUID("target") == unitGUID then return "target" end
    if UnitGUID("focus") == unitGUID then return "focus" end
    if UnitGUID("mouseover") == unitGUID then return "mouseover" end
    return nil
end

---------------------------------------------------------------------------------------------

-- DEBUFF FUNCTIONS

---------------------------------------------------------------------------------------------

local function calcEndTime(timeLeft) return GetTime() + timeLeft end

local function removeDebuff(destName, destGUID, spellID, spellName)
    if trackedUnitNames[destName..destGUID] ~= nil then
        for i = 1, #trackedUnitNames[destName..destGUID] do
            if trackedUnitNames[destName..destGUID][i] then
                if trackedUnitNames[destName..destGUID][i].name == spellName then
                    if trackedUnitNames[destName..destGUID][i]:IsVisible() then
                        local parent = trackedUnitNames[destName..destGUID][i]:GetParent()
                        if parent and parent.xiconPlate then
                            parent.xiconPlate = 0
                        end
                    end
                    trackedUnitNames[destName..destGUID][i]:SetParent(nil)
                    trackedUnitNames[destName..destGUID][i]:Hide()
                    trackedUnitNames[destName..destGUID][i]:SetScript("OnUpdate", nil)
                    tremove(trackedUnitNames[destName..destGUID], i)
                    --count = count - 1
                end
            end
        end
    end
end

local function addDebuff(destName, destGUID, spellID, spellName)
    if trackedUnitNames[destName..destGUID] == nil then
        trackedUnitNames[destName..destGUID] = {}
    end
    local _, _, texture = GetSpellInfo(spellID)
    local duration = trackedCC[spellName].duration
    local icon = CreateFrame("frame", nil, nil)
    --if spellID == 42292 or spellID == 59752 then texture = "Interface\\Icons\\inv_jewelry_trinketpvp_02" end
    icon.texture = icon:CreateTexture(nil, "BORDER")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexture(texture)
    icon.cooldown = icon:CreateFontString(nil, "OVERLAY")--CreateFrame("Cooldown", nil, icon)
    icon.cooldown:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")

    icon.cooldown:SetTextColor(0.7, 1, 0)
    icon.cooldown:SetAllPoints(icon)
    icon.duration = duration
    icon.endtime = calcEndTime(duration)
    icon.name = spellName
    icon.destGUID = destGUID

    local iconTimer = function(iconFrame)
        --if not Icicledb.fontSize then Icicledb.fontSize = ceil(Icicledb.iconsizer - Icicledb.iconsizer  / 2) end
        local itimer = ceil(iconFrame.endtime - GetTime()) -- cooldown duration
        local milliTimer = round(iconFrame.endtime - GetTime(), 1)
        iconFrame.timeLeft = milliTimer
        if itimer >= 60 then
            iconFrame.cooldown:SetText(itimer)
            if itimer < 60 and itimer >= 90 then
                iconFrame.cooldown:SetText("2m")
            else
                iconFrame.cooldown:SetText(ceil(itimer / 60) .. "m") -- X minutes
            end
        elseif itimer < 60 and itimer >= 11 then
            --if it's less than 60s
            iconFrame.cooldown:SetText(itimer)
        elseif itimer <= 10 and itimer >= 5 then
            iconFrame.cooldown:SetTextColor(1, 0.7, 0)
            iconFrame.cooldown:SetText(itimer)
        elseif itimer <= 4 and itimer >= 3 then
            iconFrame.cooldown:SetTextColor(1, 0, 0)
            iconFrame.cooldown:SetText(itimer)
        elseif milliTimer <= 3 and milliTimer > 0 then
            iconFrame.cooldown:SetTextColor(1, 0, 0)
            iconFrame.cooldown:SetText(formatTimer(milliTimer, 1))
        else -- fallback in case SPELL_AURA_REMOVED is not fired
            removeDebuff(destName, destGUID, spellID, spellName)
        end
    end

    removeDebuff(destName, destGUID, spellID, spellName)
    tinsert(trackedUnitNames[destName..destGUID], icon)
    icon:SetScript("OnUpdate", function()
        iconTimer(icon)
    end)
end


local function addIcons(dstName, namePlate)
    --TODO configurable
    local num = #trackedUnitNames[dstName]
    local size, width
    if not width then
        width = namePlate:GetWidth()
    end
    if num * 20 + (num * 2 - 2) > width then
        size = (width - (num * 2 - 2)) / num
    else
        size = 50
    end
    for i = 1, #trackedUnitNames[dstName] do
        trackedUnitNames[dstName][i]:ClearAllPoints()
        trackedUnitNames[dstName][i]:SetWidth(size)
        trackedUnitNames[dstName][i]:SetHeight(size)
        trackedUnitNames[dstName][i].cooldown:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE") --
        if i == 1 then
            trackedUnitNames[dstName][i]:SetPoint("TOPLEFT", namePlate, 31, size + -4)
        else
            trackedUnitNames[dstName][i]:SetPoint("TOPLEFT", trackedUnitNames[dstName][i - 1], size + 2, 0)
        end
    end
end

local function hideIcons(dstName, namePlate)
    namePlate.xiconPlate = 0
    namePlate.xiconPlateHooked = false
    if trackedUnitNames[dstName] then
        for i = 1, #trackedUnitNames[dstName] do
            trackedUnitNames[dstName][i]:SetParent(nil)
            trackedUnitNames[dstName][i]:Hide()
        end
    end
    namePlate:SetScript("OnHide", nil)
end

local function updateIconsOnUnit(unit)
    if IsValidTarget(unit) then
        local destName = string.gsub(UnitName(unit), "%s+", "") .. UnitGUID(unit)
        if trackedUnitNames[destName] ~= nil then
            for i = 1, 40 do
                local debuffName,rank,icon,count,dtype,duration,timeLeft,isMine = UnitDebuff(unit, i)
                if not debuffName then break end
                if trackedCC[debuffName] then
                    --update buff durations
                    for j = 1, #trackedUnitNames[destName] do
                        if trackedUnitNames[destName][j] and trackedUnitNames[destName][j].name == debuffName and timeLeft ~= nil then
                            trackedUnitNames[destName][j].endtime = calcEndTime(timeLeft)
                            --break
                        end
                    end
                end
            end
        end
    end
end

local function updateIconsOnUnitGUID(unitGUID)
    local unit = getUnitTargetedByMe(unitGUID)
    if unit then
        updateIconsOnUnit(unit)
    end
end

local function assignDebuffs(dstName, namePlate, force)
    local name
    if force and namePlate.xiconGUID then
        name = dstName .. namePlate.xiconGUID
        if trackedUnitNames[name] == nil and namePlate.xiconPlateHooked then
            local kids = { namePlate:GetChildren() };
            for _, child in ipairs(kids) do
                if child.destGUID then
                    hideIcons(dstName .. child.destGUID, namePlate) -- destGUID
                    return
                end
            end
        end
    else -- find unit with unkown guid, same name and hidden active debuffs in trackedUnitNames
        for k,v in pairs(trackedUnitNames) do
            local splitStr = split(k, "0x")
            if splitStr[1] == dstName and #v > 0 and v[1]:GetParent() == nil then
                name = k
                break
            end
            --[[if string.match(k, dstName) and #v > 0 and v[1]:GetParent() == nil then
                name = k
                break
            end--]]
        end
    end
    if name == nil then
        return
    else
        dstName = name
    end
    if trackedUnitNames[dstName] then
        namePlate.xiconPlate = #trackedUnitNames[dstName]
        for j = 1, #trackedUnitNames[dstName] do
            trackedUnitNames[dstName][j]:SetParent(namePlate)
            trackedUnitNames[dstName][j]:Show()
        end
        addIcons(dstName, namePlate)
        if namePlate:GetScript("OnHide") and not namePlate.xiconPlateHooked then
            namePlate.xiconPlateHooked = true
            namePlate:HookScript("OnHide", function()
                hideIcons(dstName, namePlate)
            end)
        else
            namePlate.xiconPlateHooked = true
            namePlate:SetScript("OnHide", function()
                hideIcons(dstName, namePlate)
            end)
        end
    end
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
        xiconPlateBuffer:UnregisterEvent("ADDON_LOADED")
    end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, auraType, stackCount = select(1, ...)
    local isEnemy = bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_NEUTRAL) == COMBATLOG_OBJECT_REACTION_NEUTRAL or bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
    if isEnemy and trackedCC[spellName] then
        local name = string.gsub(dstName, "%s+", "")
        if (eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH") then
            --print(eventType .. " - " .. spellName .. " - addDebuff")
            addDebuff(name, dstGUID, spellID, spellName)
            updateIconsOnUnitGUID(dstGUID)
        elseif (eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPEL") then
            --print(eventType .. " - " .. spellName .. " - " .. dstName .. " - removeDebuff")
            removeDebuff(name, dstGUID, spellID, spellName)
        elseif eventType == "UNIT_DIED" then
            trackedUnitNames[dstName..dstGUID] = nil
        end
    end
end

function events:PLAYER_FOCUS_CHANGED()
    updateIconsOnUnit("focus")
end

function events:PLAYER_TARGET_CHANGED()
    updateIconsOnUnit("target")
end

function events:UPDATE_MOUSEOVER_UNIT()
    updateIconsOnUnit("mouseover")
end

function events:PLAYER_ENTERING_WORLD(...)
    local instance = select(2, IsInInstance())
    trackedUnitNames = {}
    --[[if (instance == "arena") then
        self:JoinedArena()
    elseif (instance ~= "arena" and self.lastInstance == "arena") then
        self:HideFrame()
    end
    self.lastInstance = instance--]]
end

function events:PLAYER_LOGOUT(...)
    XiconPlateBufferDB = XiconPlateBufferDB_local
end


---------------------------------------------------------------------------------------------

-- REGISTER EVENTS

---------------------------------------------------------------------------------------------

xiconPlateBuffer:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, _ in pairs(events) do
    xiconPlateBuffer:RegisterEvent(k); -- Register all events for which handlers have been defined
end

---------------------------------------------------------------------------------------------

-- ON_UPDATE (periodically update nameplates)

---------------------------------------------------------------------------------------------

local function updateNameplate(unit, plate, unitName)
    local guid = UnitGUID(unit)
    if not plate.xiconGUID then
        plate.xiconGUID = guid
    elseif plate.xiconGUID ~= guid then
        plate.xiconGUID = guid
    end
    updateIconsOnUnit(unit)
    assignDebuffs(unitName, plate, true)
end

local updateInterval, lastUpdate = .02, 0
xiconPlateBuffer:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        -- do stuff
        if NAMEPLATES_ON then
            local num = WorldFrame:GetNumChildren()
            for i = 1, num do
                local namePlate = select(i, WorldFrame:GetChildren())
                if namePlate:GetNumRegions() > 2 and namePlate:GetNumChildren() >= 1 then
                    if namePlate:IsVisible() then
                        if not namePlate.xiconPlate then
                            namePlate.xiconPlate = 0
                        end
                        local name = getName(namePlate)

                        -- check if namePlate is target or mouseover
                        local border, castborder, casticon, highlight, nameText, levelText, levelIcon, raidIcon = namePlate:GetRegions()
                        local target = UnitExists("target") and namePlate:GetAlpha() == 1 or nil
                        local mouseover = UnitExists("mouseover") and highlight:IsShown() or nil
                        if target then
                            updateNameplate("target", namePlate, name)
                        elseif mouseover then
                            updateNameplate("mouseover", namePlate, name)
                        else
                            assignDebuffs(name, namePlate, false)
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