local MODULE_NAME = "XiconDebuffModule"
local trackedUnitNames = {}
local framePool = {}
local trackedCC
local XPB = LibStub("AceAddon-3.0"):GetAddon("XiconPlateBuffs")
local select, tonumber, ceil = select, tonumber, ceil

local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_REACTION_NEUTRAL = COMBATLOG_OBJECT_REACTION_NEUTRAL

local print = function(s)
    local str = s
    if s == nil then str = "nil" end
    if type(str) == "boolean" then
        if str then
            str = "true"
        else
            str = "false"
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa[".. MODULE_NAME .."]|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- REGISTER MODULE

---------------------------------------------------------------------------------------------

local XiconDebuffModule = XPB:NewModule(MODULE_NAME)

function XiconDebuffModule:OnInitialize()
    trackedCC = XPB:GetTrackedCC()
end

---------------------------------------------------------------------------------------------

-- TABLE & MATH FUNCTIONS

---------------------------------------------------------------------------------------------

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

local function formatTimer(num, numDecimalPlaces)
    return string.format("%." .. (numDecimalPlaces or 0) .. "f", num)
end

local function round(num, numDecimalPlaces)
    return tonumber(formatTimer(num, numDecimalPlaces))
end

local function splitName(str)
    local name = string.match(str , "(.+)0x.+")
    local guid = string.match(str , ".+(0x.+)")
    return {name, guid}
end

local function sortIcons(destName, destGUID, trackType)
    if XPB.db.profile[trackType].sorting == "none" then
        return
    elseif XPB.db.profile[trackType].sorting == "ascending" then
        table.sort(trackedUnitNames[destName..destGUID][trackType], function(iconA,iconB) return iconA.endtime < iconB.endtime end)
    elseif XPB.db.profile[trackType].sorting == "descending" then
        table.sort(trackedUnitNames[destName..destGUID][trackType], function(iconA,iconB) return iconA.endtime > iconB.endtime end)
    end
end

---------------------------------------------------------------------------------------------

-- TARGETING FUNCTIONS

---------------------------------------------------------------------------------------------

local function isValidTarget(unit)
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

local function hideOrRemoveIconFromList(list, index, remove)
    list[index]:Hide()
    list[index]:SetAlpha(0)
    list[index]:SetParent(UIParent)
    if (remove) then
        list[index]:SetScript("OnUpdate", nil)
        --trackedUnitNames[destName..destGUID][i].cooldowncircle:SetCooldown(0,0)
        framePool[#framePool + 1] = tremove(list, index)
    else
        list[index]:ClearAllPoints()
        list[index]:Show()
    end
end


local function removeDebuff(destName, destGUID, spellID)
    if trackedUnitNames[destName..destGUID] then
        for i = 1, #trackedUnitNames[destName..destGUID].buff do
            if trackedUnitNames[destName..destGUID].buff[i] then
                if trackedUnitNames[destName..destGUID].buff[i].spellName == select(1, GetSpellInfo(spellID)) then
                    hideOrRemoveIconFromList(trackedUnitNames[destName..destGUID].buff, i, true)
                    break
                end
            end
        end
        for i = 1, #trackedUnitNames[destName..destGUID].debuff do
            if trackedUnitNames[destName..destGUID].debuff[i] then
                if trackedUnitNames[destName..destGUID].debuff[i].spellName == select(1, GetSpellInfo(spellID)) then
                    hideOrRemoveIconFromList(trackedUnitNames[destName..destGUID].debuff, i, true)
                    break
                end
            end
        end
        if #trackedUnitNames[destName..destGUID].buff == 0 and #trackedUnitNames[destName..destGUID].debuff == 0 then
            if trackedUnitNames[destName..destGUID].parent then
                trackedUnitNames[destName..destGUID].parent.xiconPlateActive = nil
                trackedUnitNames[destName..destGUID].parent.guessedGUID = nil
            end
            trackedUnitNames[destName..destGUID] = nil
        end
    end
end

function XiconDebuffModule:addOrRefreshDebuff(destName, destGUID, spellID, timeLeft)
    destName = string.gsub(destName, "%s+", "")
    local spellName = GetSpellInfo(spellID)
    local found
    if trackedUnitNames[destName..destGUID] then
        for i = 1, #trackedUnitNames[destName..destGUID].buff do
            if trackedUnitNames[destName..destGUID].buff[i] and trackedUnitNames[destName..destGUID].buff[i].spellName == spellName then
                --trackedUnitNames[destName..destGUID][i].cooldowncircle:SetCooldown(GetTime(), timeLeft or trackedCC[spellName].duration)
                if timeLeft then
                    trackedUnitNames[destName..destGUID].buff[i].endtime = calcEndTime(timeLeft)
                else
                    trackedUnitNames[destName..destGUID].buff[i].endtime = GetTime() + trackedCC[trackedUnitNames[destName..destGUID].buff[i].spellName].duration
                end
                --sorting
                sortIcons(destName, destGUID, "buff")
                found = true
                break
            end
        end
        if not found then
            for i = 1, #trackedUnitNames[destName..destGUID].debuff do
                if trackedUnitNames[destName..destGUID].debuff[i] and trackedUnitNames[destName..destGUID].debuff[i].spellName == spellName then
                    --trackedUnitNames[destName..destGUID][i].cooldowncircle:SetCooldown(GetTime(), timeLeft or trackedCC[spellName].duration)
                    if timeLeft then
                        trackedUnitNames[destName..destGUID].debuff[i].endtime = calcEndTime(timeLeft)
                    else
                        trackedUnitNames[destName..destGUID].debuff[i].endtime = GetTime() + trackedCC[trackedUnitNames[destName..destGUID].debuff[i].spellName].duration
                    end
                    --sorting
                    sortIcons(destName, destGUID, "debuff")
                    found = true
                    break
                end
            end
        end
    end
    if not found then
        --print("not found .. spellID = " .. spellID)
        XiconDebuffModule:addDebuff(destName, destGUID, spellID, timeLeft)
    end
end

function XiconDebuffModule:addDebuff(destName, destGUID, spellID, timeLeft)
    if trackedUnitNames[destName..destGUID] == nil then
        trackedUnitNames[destName..destGUID] = { debuff = {}, buff ={}}
    end
    local spellName, _, texture = GetSpellInfo(spellID)
    local duration = trackedCC[spellName] ~= nil and trackedCC[spellName].duration or 10
    local icon
    if #framePool > 0 then
        icon = tremove(framePool, 1)
    else
        icon = CreateFrame("frame", nil, nil)
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetAllPoints(icon)
        icon.border = icon:CreateTexture(nil, "BORDER")
        icon.border:SetAllPoints(icon)
        icon.cooldown = icon:CreateFontString(nil, "OVERLAY")
        icon.cooldown:SetAllPoints(icon)
        icon.cooldown:SetFont(XPB.db.profile[trackedCC[GetSpellInfo(spellID)].track].font, XPB.db.profile[trackedCC[GetSpellInfo(spellID)].track].fontSize, "OUTLINE")
    end

    icon:SetParent(UIParent)
    icon:SetAlpha(0)
    icon.texture:SetTexture(texture)
    local color
    if trackedCC[GetSpellInfo(spellID)].spellSchool == "magic" then
        color = XPB.db.profile.iconBorderColorMagic
    elseif trackedCC[GetSpellInfo(spellID)].spellSchool == "poison" then
        color = XPB.db.profile.iconBorderColorPoison
    elseif trackedCC[GetSpellInfo(spellID)].spellSchool == "curse" then
        color = XPB.db.profile.iconBorderColorCurse
    elseif trackedCC[GetSpellInfo(spellID)].spellSchool == "physical" then
        color = XPB.db.profile.iconBorderColorPhysical
    elseif trackedCC[GetSpellInfo(spellID)].spellSchool == "immune" then
        color = XPB.db.profile.iconBorderColorImmune
    else
        color = {r = 0, g = 0, b = 0, a = 1}
    end
    if (trackedCC[GetSpellInfo(spellID)].track == "debuff") then
        icon.border:SetTexture(XPB.db.profile.debuff.iconBorder)
    else
        icon.border:SetTexture(XPB.db.profile.buff.iconBorder)
    end
    icon.border:SetVertexColor(color.r, color.g, color.b, color.a)


    --icon.cooldowncircle = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    --icon.cooldowncircle.noCooldownCount = true -- disable OmniCC
    --icon.cooldowncircle:SetAllPoints()
    --icon.cooldowncircle:SetCooldown(GetTime(), timeLeft or duration)

    icon.endtime = calcEndTime(timeLeft or duration)
    icon.spellName = spellName
    icon.spellID = trackedCC[GetSpellInfo(spellID)].id
    icon.destGUID = destGUID
    icon.destName = destName
    icon.trackType = trackedCC[GetSpellInfo(spellID)].track

    local iconTimer = function(iconFrame, elapsed)
        local itimer = ceil(iconFrame.endtime - GetTime()) -- cooldown duration
        local milliTimer = round(iconFrame.endtime - GetTime(), 1)
        iconFrame.timeLeft = milliTimer
        if itimer >= 60 then
            iconFrame.cooldown:SetText(itimer)
            icon.cooldown:SetTextColor(0.7, 1, 0)
            if itimer < 60 and itimer >= 90 then
                iconFrame.cooldown:SetText("2m")
            else
                iconFrame.cooldown:SetText(ceil(itimer / 60) .. "m") -- X minutes
            end
        elseif itimer < 60 and itimer >= 11 then
            --if it's less than 60s
            iconFrame.cooldown:SetText(itimer)
            icon.cooldown:SetTextColor(0.7, 1, 0)
        elseif itimer <= 10 and itimer >= 5 then
            iconFrame.cooldown:SetTextColor(1, 0.7, 0)
            iconFrame.cooldown:SetText(itimer)
        elseif itimer <= 4 and itimer >= 3 then
            iconFrame.cooldown:SetTextColor(1, 0, 0)
            iconFrame.cooldown:SetText(itimer)
        elseif milliTimer <= 3 and milliTimer > 0 then
            iconFrame.cooldown:SetTextColor(1, 0, 0)
            iconFrame.cooldown:SetText(formatTimer(milliTimer, 1))
        elseif milliTimer <= 0 and milliTimer > -0.05 then -- 50ms ping max wait for SPELL_AURA_REMOVED event
            iconFrame.cooldown:SetText("")
        else -- fallback in case SPELL_AURA_REMOVED is not fired
            removeDebuff(iconFrame.destName, iconFrame.destGUID, iconFrame.spellID)
        end
    end

    tinsert(trackedUnitNames[destName..destGUID][icon.trackType], icon)
    icon:SetScript("OnUpdate", iconTimer)
    icon:Show()
    --sorting
    sortIcons(destName, destGUID, icon.trackType)
end

local function calcResponsive(responsive, responsiveMax, iconSize, fontSize, numBuffs)
    local sizeBuff, fontSizeBuff
    if responsive and numBuffs > 0 and numBuffs * iconSize + (numBuffs * 2 - 2) > responsiveMax then
        sizeBuff = (responsiveMax - (numBuffs * 2 - 2)) / numBuffs
        if fontSize < sizeBuff/2 then
            fontSizeBuff = fontSize
        else
            fontSizeBuff = sizeBuff / 2
        end
    else
        fontSizeBuff = fontSize
        sizeBuff = iconSize
    end
    return sizeBuff, fontSizeBuff
end

local function addIcons(dstName, namePlate, force)
    local numBuffs, numDebuffs = #trackedUnitNames[dstName].buff, #trackedUnitNames[dstName].debuff
    local sizeBuff, fontSizeBuff = calcResponsive(XPB.db.profile.buff["responsive"], XPB.db.profile.buff["responsiveMax"], XPB.db.profile.buff["iconSize"], XPB.db.profile.buff.fontSize, numBuffs)
    local sizeDebuff, fontSizeDebuff = calcResponsive(XPB.db.profile.debuff["responsive"], XPB.db.profile.debuff["responsiveMax"], XPB.db.profile.debuff["iconSize"], XPB.db.profile.debuff["fontSize"], numDebuffs)

    for i = 1, #trackedUnitNames[dstName].debuff do
        trackedUnitNames[dstName].debuff[i]:SetParent(namePlate)
        trackedUnitNames[dstName].debuff[i]:SetFrameStrata(force and "LOW" or "BACKGROUND")
        trackedUnitNames[dstName].debuff[i]:ClearAllPoints()
        trackedUnitNames[dstName].debuff[i]:SetWidth(sizeDebuff)
        trackedUnitNames[dstName].debuff[i]:SetHeight(sizeDebuff)
        trackedUnitNames[dstName].debuff[i]:SetAlpha(XPB.db.profile.debuff.alpha)
        trackedUnitNames[dstName].debuff[i].cooldown:SetAlpha(XPB.db.profile.debuff.alpha)
        trackedUnitNames[dstName].debuff[i].cooldown:SetFont(XPB.db.profile.debuff.font, fontSizeDebuff, "OUTLINE")
        if i == 1 then
            trackedUnitNames[dstName].debuff[i]:SetPoint(XPB.db.profile.debuff.anchor.self,
                    namePlate, XPB.db.profile.debuff.anchor.nameplate,
                    XPB.db.profile.debuff.xOffset,
                    XPB.db.profile.debuff.yOffset)
        else
            trackedUnitNames[dstName].debuff[i]:SetPoint(XPB.db.profile.debuff.growDirection.self,
                    trackedUnitNames[dstName].debuff[i - 1], XPB.db.profile.debuff.growDirection.icon,
                    0, 0)
        end
        trackedUnitNames[dstName].debuff[i]:Show()
    end

    for i = 1, #trackedUnitNames[dstName].buff do
        trackedUnitNames[dstName].buff[i]:SetParent(namePlate)
        trackedUnitNames[dstName].buff[i]:SetFrameStrata(force and "LOW" or "BACKGROUND")
        trackedUnitNames[dstName].buff[i]:ClearAllPoints()
        trackedUnitNames[dstName].buff[i]:SetWidth(sizeBuff)
        trackedUnitNames[dstName].buff[i]:SetHeight(sizeBuff)
        trackedUnitNames[dstName].buff[i]:SetAlpha(XPB.db.profile.buff.alpha)
        trackedUnitNames[dstName].buff[i].cooldown:SetAlpha(XPB.db.profile.buff.alpha)
        trackedUnitNames[dstName].buff[i].cooldown:SetFont(XPB.db.profile.buff.font, fontSizeBuff, "OUTLINE")
        if i == 1 then
            if XPB.db.profile.attachBuffsToDebuffs then
                if #trackedUnitNames[dstName].debuff > 0 then
                    trackedUnitNames[dstName].buff[i]:SetPoint(XPB.db.profile.buff.anchor.self,
                            trackedUnitNames[dstName].debuff[1], XPB.db.profile.buff.anchor.nameplate,
                            XPB.db.profile.buff.xOffset,
                            XPB.db.profile.buff.yOffset)
                else
                    trackedUnitNames[dstName].buff[i]:SetPoint(XPB.db.profile.debuff.anchor.self,
                            namePlate, XPB.db.profile.debuff.anchor.nameplate,
                            XPB.db.profile.debuff.xOffset,
                            XPB.db.profile.debuff.yOffset)
                end
            else
                trackedUnitNames[dstName].buff[i]:SetPoint(XPB.db.profile.buff.anchor.self,
                        namePlate, XPB.db.profile.buff.anchor.nameplate,
                        XPB.db.profile.buff.xOffset,
                        XPB.db.profile.buff.yOffset)
            end
        else
            trackedUnitNames[dstName].buff[i]:SetPoint(XPB.db.profile.buff.growDirection.self, trackedUnitNames[dstName].buff[i - 1], XPB.db.profile.buff.growDirection.icon, 0, 0)
        end
        trackedUnitNames[dstName].buff[i]:Show()
    end
end

local function hideIcons(namePlate, dstName)
    if namePlate then -- OnHide or just remove icons
        if not dstName and namePlate.XiconGUID then -- OnHide
            namePlate.XiconGUID = nil
            namePlate.guessedGUID = nil
        end
        namePlate.xiconPlateActive = nil
        local kids = { namePlate:GetChildren() };
        for _, child in ipairs(kids) do
            if child.destGUID then
                for i = 1, #trackedUnitNames[child.destName .. child.destGUID].buff do
                    hideOrRemoveIconFromList(trackedUnitNames[child.destName .. child.destGUID].buff, i, false)
                end
                for i = 1, #trackedUnitNames[child.destName .. child.destGUID].debuff do
                    hideOrRemoveIconFromList(trackedUnitNames[child.destName .. child.destGUID].debuff, i, false)
                end
                if trackedUnitNames[child.destName .. child.destGUID].parent then
                    trackedUnitNames[child.destName .. child.destGUID].parent.xiconPlateActive = nil
                end
                trackedUnitNames[child.destName .. child.destGUID].parent = nil
                break
            end
        end
    elseif not namePlate and dstName then -- UNIT_DIED
        if trackedUnitNames[dstName] then
            local i = #trackedUnitNames[dstName].buff
            while i > 0 do
                hideOrRemoveIconFromList(trackedUnitNames[dstName].buff, i, true)
                i = i - 1
            end
            i = #trackedUnitNames[dstName].debuff
            while i > 0 do
                hideOrRemoveIconFromList(trackedUnitNames[dstName].debuff, i, true)
                i = i - 1
            end
            if #trackedUnitNames[dstName].buff == 0 and #trackedUnitNames[dstName].debuff == 0 then
                trackedUnitNames[dstName] = nil
            end
        end
    end
end

local function updateDebuffsOnUnit(unit, event)
    if isValidTarget(unit) then
        local unitName = string.gsub(UnitName(unit), "%s+", "")
        local unitGUID = UnitGUID(unit)
        --if trackedUnitNames[unitName..unitGUID] then
        --    hideIcons(nil, unitName..unitGUID)
        --end
        local debuffs = {}
        for i = 1, 40 do
            local spellName,rank,icon,count,dtype,duration,timeLeft,isMine = UnitDebuff(unit, i)
            if not spellName then break end
            if trackedCC[spellName] and (timeLeft or event == "UNIT_AURA") then
                debuffs[spellName] = true
                --update buff durations
                XiconDebuffModule:addOrRefreshDebuff(unitName, unitGUID, trackedCC[spellName].id, timeLeft or trackedCC[spellName].duration, true)
                if timeLeft > 0.5 then
                    XiconDebuffModule:SendMessage(string.format("SPELL_AURA_REFRESH:%s,%s,%s,%s,%s,%s,%s", trackedCC[spellName].id, spellName, unitName, unitGUID, duration, timeLeft, "enemy"))
                end
            end
        end
        --safe delete debuff if not exists
        --[[if trackedUnitNames[unitName..unitGUID] then
            for i = 1, #trackedUnitNames[unitName..unitGUID].debuff do
                if trackedUnitNames[unitName..unitGUID].debuff[i] and not debuffs[trackedUnitNames[unitName..unitGUID].debuff[i].spellName] then
                    print("Remove debuff " .. trackedUnitNames[unitName..unitGUID].debuff[i].spellName)
                    removeDebuff(unitName, unitGUID, trackedCC[trackedUnitNames[unitName..unitGUID].debuff[i].spellName].id)
                end
            end
        end--]]
        local buffs = {}
        for i = 1, 40 do
            local spellName, _, _, _, duration, timeLeft,isMine,isStealable,shouldConsolidate,spellId = UnitBuff(unit, i)
            if not spellName then break end
            if trackedCC[spellName] and (timeLeft or event == "UNIT_AURA") then
                buffs[spellName] = true
                --update buff durations
                XiconDebuffModule:addOrRefreshDebuff(unitName, unitGUID, trackedCC[spellName].id, timeLeft or trackedCC[spellName].duration, true)
                if timeLeft > 0.5 then
                    XiconDebuffModule:SendMessage(string.format("SPELL_AURA_REFRESH:%s,%s,%s,%s,%s,%s,%s", trackedCC[spellName].id, spellName, unitName, unitGUID, duration, timeLeft, "enemy"))
                end
            end
        end
        --safe delete buff if not exists
        --[[if trackedUnitNames[unitName..unitGUID] then
            for i = 1, #trackedUnitNames[unitName..unitGUID].buff do
                if trackedUnitNames[unitName..unitGUID].buff[i] and not buffs[trackedUnitNames[unitName..unitGUID].buff[i].name] then
                    removeDebuff(unitName, unitGUID, trackedUnitNames[unitName..unitGUID].buff[i].id)
                end
            end
        end--]]
    end
end

local function updateDebuffsOnUnitGUID(unitGUID)
    local unit = getUnitTargetedByMe(unitGUID)
    if unit then
        updateDebuffsOnUnit(unit)
    end
end

local function updateDebuffsOnNameplate(name, namePlate, force)
    if trackedUnitNames[name] then
        addIcons(name, namePlate, force)
        if not namePlate:GetScript("OnHide") then
            namePlate:SetScript("OnHide", hideIcons)
            namePlate.xiconPlateHooked = true
        elseif not namePlate.xiconPlateHooked then
            namePlate:HookScript("OnHide", hideIcons)
            namePlate.xiconPlateHooked = true
        end
        if trackedUnitNames[name].parent then
            trackedUnitNames[name].parent.xiconPlateActive = nil
        end
        trackedUnitNames[name].parent = namePlate
        namePlate.xiconPlateActive = true
    end
end

function XiconDebuffModule:assignDebuffs(dstName, namePlate, force)
    dstName = string.gsub(dstName, "%s+", "")
    local name
    if force and namePlate.XiconGUID then -- we know the nameplates guid here
        name = dstName .. namePlate.XiconGUID() -- record to look for
        if trackedUnitNames[name] == nil then -- force wipe debuffs if no record, else record will show on this nameplate
            hideIcons(namePlate, dstName)
        end
    else
        -- find unit with unknown guid, same name and hidden active debuffs in trackedUnitNames
        for k,v in pairs(trackedUnitNames) do
            local splitStr = splitName(k)
            if namePlate.XiconGUID and splitStr[2] == namePlate.XiconGUID() then -- we definitely know this nameplate (hovered / targeted before... OnHide will clear namePlate.XiconGUID
                if namePlate.xiconPlateActive then
                    local kids = { namePlate:GetChildren() };
                    for _, child in ipairs(kids) do
                        if child.destGUID and child.destGUID ~= splitStr[2] then
                            hideIcons(namePlate, dstName)
                            break
                        elseif child.destGUID then
                            break
                        end
                    end
                end
                name = k
                break
            elseif not namePlate.xiconPlateActive and not trackedUnitNames[k].parent and not namePlate.XiconGUID and splitStr[1] == dstName then
                -- wild guess in pve, accurate in pvp
                namePlate.guessedGUID = function() return splitStr[2] end
                name = k
                break
            elseif namePlate.xiconPlateActive and trackedUnitNames[k].parent == namePlate and not namePlate.XiconGUID and splitStr[1] == dstName then
                -- still wild guess but active, we update here nonetheless, accurate in pvp
                name = k
                break
            elseif namePlate.xiconPlateActive and not namePlate.guessedGUID then
                hideIcons(namePlate, k)
            end
        end
    end
    if name then
        -- nameplate with either force or guess was found
        updateDebuffsOnNameplate(name, namePlate, force)
    end
end

function XiconDebuffModule:updateNameplate(unit, plate, unitName)
    local guid = UnitGUID(unit)
    local plateGUID = plate.XiconGUID
    if guid and not plateGUID then
        plate.XiconGUID = function() return guid end
    elseif guid and plateGUID and guid ~= plateGUID() then
        plate.XiconGUID = function() return guid end
    end
    --updateDebuffsOnUnit(unit)
    XiconDebuffModule:assignDebuffs(unitName, plate, true)
end

function XiconDebuffModule:SendMessage(msg)
    SendAddonMessage("XICON1", msg, "RAID")
end

---------------------------------------------------------------------------------------------

-- EVENT HANDLERS

---------------------------------------------------------------------------------------------

local events = {}

function events:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, auraType, stackCount = select(1, ...)
    local dstIsEnemy = bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_NEUTRAL) == COMBATLOG_OBJECT_REACTION_NEUTRAL or bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
    local srcIsEnemy = bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_NEUTRAL) == COMBATLOG_OBJECT_REACTION_NEUTRAL or bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
    local name
    if eventType == "SPELL_SUMMON" then
        local isGroundingTotem = tonumber(strsub(dstGUID,9,12), 16) == 5925 -- read unit id in dstGUID between 9th and 12th (hex to number)
        if isGroundingTotem then
            --print("Grounding Totem with guid " .. dstGUID .. " casted by " .. srcName)
        end
    end
    --print(eventType .. " - " .. (dstName and dstName.." dst" or srcName and srcName.." src"))
    if dstIsEnemy and (trackedCC[spellName]) then
        --print(eventType .. " - " ..spellName)
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
            --print(eventType .. " - " .. spellName .. " - " .. spellID)
            name = string.gsub(dstName, "%s+", "")
            XiconDebuffModule:addOrRefreshDebuff(name, dstGUID, spellID)
            XiconDebuffModule:SendMessage(string.format(eventType .. ":%s,%s,%s,%s,%s,%s,%s", spellID, spellName, name, dstGUID, "nil", "nil", "enemy"))
            updateDebuffsOnUnitGUID(dstGUID)
        end
    end
    if (srcIsEnemy or dstIsEnemy) and trackedCC[spellName] then
        if (eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPEL") then
            --print(eventType .. " - " .. spellName .. " - " .. dstName .. (dstIsEnemy and " - dst" or srcIsEnemy and " - src"))
            name = string.gsub(dstName, "%s+", "")
            removeDebuff(name, dstGUID, spellID)
            XiconDebuffModule:SendMessage(string.format(eventType .. ":%s,%s,%s,%s,%s,%s,%s", spellID, spellName, name, dstGUID, "nil", "nil", "enemy"))
        end
    end
    if dstIsEnemy and eventType == "UNIT_DIED" then
        name = string.gsub(dstName or srcName, "%s+", "")
        if trackedUnitNames[name..dstGUID] then
            hideIcons(nil, name..dstGUID)
            trackedUnitNames[name..dstGUID] = nil
            XiconDebuffModule:SendMessage(string.format(eventType .. ":%s,%s,%s,%s,%s,%s,%s", "nil", "nil", name, dstGUID, "nil", "nil", "enemy"))
        end
    end
end

function events:PLAYER_FOCUS_CHANGED()
    updateDebuffsOnUnit("focus")
end

function events:PLAYER_TARGET_CHANGED()
    updateDebuffsOnUnit("target")
end

function events:UPDATE_MOUSEOVER_UNIT()
    updateDebuffsOnUnit("mouseover")
end

function events:UNIT_AURA(unitId)
    updateDebuffsOnUnit(unitId, "UNIT_AURA")
end

-- Catch syncs
function events:CHAT_MSG_ADDON(prefix, msg, type, author)
    if( (prefix == "PCCT2" or prefix == "XICON1") and author ~= UnitName("player")  ) then
        local eventType, data = string.match(msg, "(.+)%:(.+)")
        local spellID, spellName, destName, destGUID, duration, timeLeft, playerType = string.split(",", data)
        duration = tonumber(duration)
        timeLeft = tonumber(timeLeft)
        spellID = tonumber(spellID)
        --print(eventType .. " - " .. msg)
        if( eventType == "SPELL_AURA_APPLIED" ) then
            --print(eventType .. " - " .. author .. " - " .. data)
            XiconDebuffModule:addOrRefreshDebuff(destName, destGUID, spellID, timeLeft)
        elseif( eventType == "SPELL_AURA_REFRESH" ) then
            --print(eventType .. " - " .. author .. " - " .. data)
            XiconDebuffModule:addOrRefreshDebuff(destName, destGUID, spellID, timeLeft)
        elseif( eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_DISPEL" ) then
            --print(eventType .. " - " .. author .. " - " .. data)
            removeDebuff(destName, destGUID, spellID)
        elseif eventType == "UNIT_DIED" then
            --print(eventType .. " - " .. author .. " - " .. data)
            if trackedUnitNames[destName..destGUID] then
                hideIcons(nil, destName..destGUID)
                trackedUnitNames[destName..destGUID] = nil
            end
        end
    end
end

function events:PLAYER_ENTERING_WORLD(...) -- TODO add option to enable/disable in open world/instance/etc
    for k,v in pairs(trackedUnitNames) do
        local i = #trackedUnitNames[k].buff
        while i > 0 do
            hideOrRemoveIconFromList(trackedUnitNames[k].buff, i, true)
            i = i - 1
        end
        i = #trackedUnitNames[k].debuff
        while i > 0 do
            hideOrRemoveIconFromList(trackedUnitNames[k].debuff, i, true)
            i = i - 1
        end
        if #trackedUnitNames[k].buff == 0 and #trackedUnitNames[k].debuff == 0 then
            trackedUnitNames[k] = nil
        end
    end
    trackedUnitNames = {} -- wipe all data
    --framePool = {}
end

---------------------------------------------------------------------------------------------

-- REGISTER EVENTS

---------------------------------------------------------------------------------------------

XiconDebuffModule:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, _ in pairs(events) do
    XiconDebuffModule:RegisterEvent(k); -- Register all events for which handlers have been defined
end
