local ADDON_NAME = "XiconPlateBuffs"
local select, tonumber, tostring = select, tonumber, tostring
local XiconPlateBuffsDB_local

--local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
--local COMBATLOG_OBJECT_CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local trackedCC = initTrackedCrowdControl()

local trackedUnitNames = {}

local print = function(s)
    local str = s
    if s == nil then str = "" end
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa[".. ADDON_NAME .."]|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- FRAME SETUP FOR REGISTER EVENTS

---------------------------------------------------------------------------------------------

local xiconPlateBuffs = CreateFrame("Frame", "XiconPlateBuffs", UIParent)
xiconPlateBuffs:EnableMouse(false)
xiconPlateBuffs:SetWidth(1)
xiconPlateBuffs:SetHeight(1)
xiconPlateBuffs:SetAlpha(0)

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
    local _, _, _, _, eman, _, _ = namePlate:GetRegions()
    if namePlate.aloftData then
        name = namePlate.aloftData.name
    elseif sohighPlates then
        name = namePlate.oldname:GetText()
    elseif strmatch(eman:GetText(), "%d") then
        local _, _, _, _, _, nameRegion = namePlate:GetRegions()
        name = nameRegion:GetText()
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

local function removeDebuff(destName, destGUID, spellName)
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
                    --trackedUnitNames[destName..destGUID][i]:SetScript("OnUpdate", nil)
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
    icon:SetAlpha(XiconPlateBuffsDB_local["alpha"])
    icon.texture = icon:CreateTexture(nil, "BORDER")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexture(texture)
    icon.cooldown = icon:CreateFontString(nil, "OVERLAY")
    icon.cooldown:SetAlpha(XiconPlateBuffsDB_local["alpha"])
    icon.cooldown:SetFont("Fonts\\ARIALN.ttf", XiconPlateBuffsDB_local["fontSize"], "OUTLINE")

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
            removeDebuff(destName, destGUID, spellName)
        end
    end

    removeDebuff(destName, destGUID, spellName)
    tinsert(trackedUnitNames[destName..destGUID], icon)
    icon:SetScript("OnUpdate", function()
        iconTimer(icon)
    end)
    --sorting
    if XiconPlateBuffsDB_local["sorting"] == "none" then
        return
    end
    if XiconPlateBuffsDB_local["sorting"] == "ascending" then
        table.sort(trackedUnitNames[destName..destGUID], function(timeleftA,timeleftB) return timeleftA.endtime < timeleftB.endtime end)
    elseif XiconPlateBuffsDB_local["sorting"] == "descending" then
        table.sort(trackedUnitNames[destName..destGUID], function(timeleftA,timeleftB) return timeleftA.endtime > timeleftB.endtime end)
    end
end


local function addIcons(dstName, namePlate)
    local num = #trackedUnitNames[dstName]
    local size, fontSize, width
    if not width then
        width = namePlate:GetWidth()
    end
    if XiconPlateBuffsDB_local["responsive"] and num * XiconPlateBuffsDB_local["iconSize"] + (num * 2 - 2) > width then
        size = (width - (num * 2 - 2)) / num
        if XiconPlateBuffsDB_local["fontSize"] < size/2 then
            fontSize = XiconPlateBuffsDB_local["fontSize"]
        else
            fontSize = size / 2
        end
    else
        fontSize = XiconPlateBuffsDB_local["fontSize"]
        size = XiconPlateBuffsDB_local["iconSize"]
    end
    for i = 1, #trackedUnitNames[dstName] do
        trackedUnitNames[dstName][i]:ClearAllPoints()
        trackedUnitNames[dstName][i]:SetWidth(size)
        trackedUnitNames[dstName][i]:SetHeight(size)
        trackedUnitNames[dstName][i]:SetAlpha(XiconPlateBuffsDB_local["alpha"])
        trackedUnitNames[dstName][i].cooldown:SetAlpha(XiconPlateBuffsDB_local["alpha"])
        trackedUnitNames[dstName][i].cooldown:SetFont("Fonts\\ARIALN.ttf", fontSize, "OUTLINE")
        if i == 1 then
            trackedUnitNames[dstName][i]:SetPoint("TOPLEFT", namePlate, XiconPlateBuffsDB_local["xOffset"], size + XiconPlateBuffsDB_local["yOffset"])
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
                if trackedCC[debuffName] and timeLeft ~= nil then
                    --update buff durations
                    for j = 1, #trackedUnitNames[destName] do
                        if trackedUnitNames[destName][j] and trackedUnitNames[destName][j].name == debuffName then
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
            elseif splitStr[1] == dstName and #v > 0 and namePlate.xiconPlateHooked then
                --update plate to rearrange icons
                name = k
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
        XiconPlateBuffsDB_local = XiconPlateBuffsDB
        if not XiconPlateBuffsDB_local then
            XiconPlateBuffsDB_local = {}
            XiconPlateBuffsDB_local["iconSize"] = 40
            XiconPlateBuffsDB_local["yOffset"] = 15
            XiconPlateBuffsDB_local["xOffset"] = 0
            XiconPlateBuffsDB_local["fontSize"] = 15
            XiconPlateBuffsDB_local["responsive"] = true
            XiconPlateBuffsDB_local["sorting"] = 'ascending'
            XiconPlateBuffsDB_local["alpha"] = 1.0
            XiconPlateBuffsDB = XiconPlateBuffsDB_local
        end
        if not XiconPlateBuffsDB_local["iconSize"] then XiconPlateBuffsDB_local["iconSize"] = 40 end
        if not XiconPlateBuffsDB_local["yOffset"] then XiconPlateBuffsDB_local["yOffset"] = 15 end
        if not XiconPlateBuffsDB_local["xOffset"] then XiconPlateBuffsDB_local["xOffset"] = 0 end
        if not XiconPlateBuffsDB_local["fontSize"] then XiconPlateBuffsDB_local["fontSize"] = 15 end
        if XiconPlateBuffsDB_local["responsive"] == nil then XiconPlateBuffsDB_local["responsive"] = true end
        if not XiconPlateBuffsDB_local["sorting"] then XiconPlateBuffsDB_local["sorting"] = 'ascending' end
        if not XiconPlateBuffsDB_local["alpha"] then XiconPlateBuffsDB_local["alpha"] = 1.0 end
        --local date = date("%m/%d/%y")
        xiconPlateBuffs:CreateOptions()
        print("Loaded")
        print("write /xpb or /xpbconfig for options")
        xiconPlateBuffs:UnregisterEvent("ADDON_LOADED")
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
            removeDebuff(name, dstGUID, spellName)
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

function events:PLAYER_ENTERING_WORLD(...) -- TODO add option to enable/disable in open world/instance/etc
    trackedUnitNames = {} -- wipe all data
    --[[
    local instance = select(2, IsInInstance()
    if (instance == "arena") then
        self:JoinedArena()
    elseif (instance ~= "arena" and self.lastInstance == "arena") then
        self:HideFrame()
    end
    self.lastInstance = instance--]]
end

function events:PLAYER_LOGOUT(...)
    XiconPlateBuffsDB = XiconPlateBuffsDB_local
end


---------------------------------------------------------------------------------------------

-- REGISTER EVENTS

---------------------------------------------------------------------------------------------

xiconPlateBuffs:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, _ in pairs(events) do
    xiconPlateBuffs:RegisterEvent(k); -- Register all events for which handlers have been defined
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
xiconPlateBuffs:SetScript("OnUpdate", function(_, elapsed)
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

-- INTERFACE OPTIONS

---------------------------------------------------------------------------------------------

local function XiconPlateBuffs_Test(text)
    if text and text ~= "" then
        local dstName,dstGUID = string.gsub(text, "%s+", ""), "0x00001312031"
        addDebuff(dstName, dstGUID, 29166, GetSpellInfo(29166)) -- innervate
        addDebuff(dstName, dstGUID, 22570, GetSpellInfo(22570)) -- maim
        addDebuff(dstName, dstGUID, 14309, GetSpellInfo(14309)) -- freezing trap
        addDebuff(dstName, dstGUID, 12826, GetSpellInfo(12826)) -- polymorph
    end
end

local function onEscapePressed(frame)
    frame:SetText(frame.oldValue)
    frame:ClearFocus()
end

local function onEnterPressed(frame)
    frame.oldValue = frame:GetText()
    frame:ClearFocus()
end

local function setEditBoxValue(frame, value)
    frame:SetText(tostring(value))
    frame:SetCursorPosition(0)
    frame:ClearFocus()
    frame.setFunc(frame)
end

local function onEnter(frame)
    frame.oldValue = frame:GetText()
end

local function onLeave(frame)
    frame:SetText(frame.oldValue)
end

local function createEditBox(name, parent, width, height, value, setFunc)
    local editbox = CreateFrame("EditBox",parent:GetName()..name,parent,"InputBoxTemplate")
    editbox:SetText(value)
    editbox:SetCursorPosition(0)
    editbox:SetHeight(height)
    editbox:SetWidth(width)
    editbox:SetAutoFocus(false)
    editbox:SetScript("OnEditFocusGained", onEnter)
    editbox:SetScript("OnEditFocusLost", onLeave)
    editbox:SetScript("OnEnterPressed", onEnterPressed)
    editbox:SetScript("OnEscapePressed", onEscapePressed)
    editbox:HookScript("OnEnterPressed", setFunc)
    editbox.setFunc = setFunc

    local label = editbox:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    label:SetText(name)
    label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT",-3,0)
    return editbox
end

local XiconPlateBuffs_Options = LibStub("LibSimpleOptions-1.0")
LibStub("LibSimpleOptions-1.0").AddSlashCommand("XiconPlateBuffs", "/xpb", "/xpbconfig")
function xiconPlateBuffs:CreateOptions()
    local panel = XiconPlateBuffs_Options.AddOptionsPanel("XiconPlateBuffs", function() end)
    local i,option_toggles = 1, {}

    local _,subText = panel:MakeTitleTextAndSubText("XiconPlateBuffs Addon", "General settings")

    --- Test input option
    local editTestBox = createEditBox("Mob/Unit exact name (be near the mob)",panel,200,25, "Dampscale Basilisk", function() end)
    editTestBox:SetPoint("TOPLEFT",subText,"BOTTOMLEFT", 10, -15)
    option_toggles[i] = editTestBox

    --- Test button option
    local editBoxButton = panel:MakeButton(
            'name', 'Test',
            'description', 'Test',
            'default', true,
            'func', function() XiconPlateBuffs_Test(editTestBox:GetText()) end)
    editBoxButton:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, 0)
    i = i + 1
    option_toggles[i] = editBoxButton

    --- icon size option
    local iconSizeEditBox = createEditBox("Icon Size",panel,200,25,XiconPlateBuffsDB_local["iconSize"], function(frame)
        if frame:GetText() and tonumber(frame:GetText()) then
            XiconPlateBuffsDB_local["iconSize"] = tonumber(frame:GetText())
        end
    end)
    iconSizeEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -20)
    i = i + 1
    option_toggles[i] = iconSizeEditBox

    --- font size option
    local fontSizeEditBox = createEditBox("Font Size",panel,200,25,XiconPlateBuffsDB_local["fontSize"], function(frame)
        if frame:GetText() and tonumber(frame:GetText()) then
            XiconPlateBuffsDB_local["fontSize"] = tonumber(frame:GetText())
        end
    end)
    fontSizeEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = fontSizeEditBox

    --- y offset option
    local yOffsetEditBox = createEditBox("Vertical Offset",panel,200,25,XiconPlateBuffsDB_local["yOffset"], function(frame)
        if frame:GetText() and tonumber(frame:GetText()) then
            XiconPlateBuffsDB_local["yOffset"] = tonumber(frame:GetText())
        end
    end)
    yOffsetEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = yOffsetEditBox

    --- x offset option
    local xOffsetEditBox = createEditBox("Horizontal Offset",panel,200,25,XiconPlateBuffsDB_local["xOffset"], function(frame)
        if frame:GetText() and tonumber(frame:GetText()) then
            XiconPlateBuffsDB_local["xOffset"] = tonumber(frame:GetText())
        end
    end)
    xOffsetEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = xOffsetEditBox

    --- alpha option
    local alphaEditBox = createEditBox("Alpha (1.0 is 100%, 0.0 is invisible)",panel,200,25,XiconPlateBuffsDB_local["alpha"], function(frame)
        if frame:GetText() and tonumber(frame:GetText()) then
            XiconPlateBuffsDB_local["alpha"] = tonumber(frame:GetText())
        end
    end)
    alphaEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = alphaEditBox

    --- responsiveness option
    local responsiveToggle = panel:MakeToggle(
            'name', 'Resize Icons responsively',
            'description', 'Resize Icons responsively',
            'default', true,
            'getFunc', function() return XiconPlateBuffsDB_local["responsive"] or true end,
            'setFunc', function(value) XiconPlateBuffsDB_local["responsive"] = value end)
    responsiveToggle:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", -5, 0)
    i = i + 1
    option_toggles[i] = responsiveToggle

    --- sorting option
    local sortingDropdown = panel:MakeDropDown(
            'name', 'Sorting',
            'description', 'Specify sorting method',
            'values', {
                'none', "None",
                'ascending', "Ascending",
                'descending', "Descending",
            },
            'default', 'none',
            'getFunc', function() return XiconPlateBuffsDB_local["sorting"] or "none" end,
            'setFunc', function(value) XiconPlateBuffsDB_local["sorting"] = value end)
    sortingDropdown:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", -15, -10)
    i = i + 1
    option_toggles[i] = sortingDropdown

    --- default settings button
    local defaultSettingsButton = panel:MakeButton(
            'name', 'Default Settings',
            'description', 'Default Settings',
            'default', true,
            'func', function()
                setEditBoxValue(iconSizeEditBox, 40)
                setEditBoxValue(fontSizeEditBox,15)
                setEditBoxValue(yOffsetEditBox, 15)
                setEditBoxValue(xOffsetEditBox,0)
                setEditBoxValue(alphaEditBox, 1.0)
                responsiveToggle.SetValue(responsiveToggle, true)
                sortingDropdown.SetValue(sortingDropdown, 'ascending')
            end)
    defaultSettingsButton:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, 0)
    i = i + 1
    option_toggles[i] = defaultSettingsButton
end