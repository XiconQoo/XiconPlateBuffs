local ADDON_NAME = "XiconPlateBuffs"
local select, tonumber, tostring = select, tonumber, tostring
local XiconPlateBuffsDB_local
local XiconDebuffLib = XiconDebuffLib

local print = function(s)
    local str = s
    if s == nil then str = "" end
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa[".. ADDON_NAME .."]|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- FRAME SETUP FOR REGISTER EVENTS

---------------------------------------------------------------------------------------------

local XiconPlateBuffs = CreateFrame("Frame", "XiconPlateBuffs", UIParent)
XiconPlateBuffs:EnableMouse(false)
XiconPlateBuffs:SetWidth(1)
XiconPlateBuffs:SetHeight(1)
XiconPlateBuffs:SetAlpha(0)

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
    return name
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
        XiconPlateBuffs:CreateOptions()

        XiconDebuffLib:Init(XiconPlateBuffsDB_local)
        print("Loaded")
        print("write /xpb or /xpbconfig for options")
        XiconPlateBuffs:UnregisterEvent("ADDON_LOADED")
    end
end

function events:PLAYER_LOGOUT(...)
    XiconPlateBuffsDB = XiconPlateBuffsDB_local
end


---------------------------------------------------------------------------------------------

-- REGISTER EVENTS

---------------------------------------------------------------------------------------------

XiconPlateBuffs:SetScript("OnEvent", function(self, event, ...)
    events[event](self, ...); -- call one of the functions above
end);
for k, _ in pairs(events) do
    XiconPlateBuffs:RegisterEvent(k); -- Register all events for which handlers have been defined
end

---------------------------------------------------------------------------------------------

-- ON_UPDATE (periodically update nameplates)

---------------------------------------------------------------------------------------------

local updateInterval, lastUpdate = .02, 0
XiconPlateBuffs:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        -- do stuff
        if NAMEPLATES_ON then
            local testMode = false
            if XiconPlateBuffs.testMode then
                testMode = true
            end
            local num = WorldFrame:GetNumChildren()
            for i = 1, num do
                local namePlate = select(i, WorldFrame:GetChildren())
                if namePlate:GetNumRegions() > 2 and namePlate:GetNumChildren() >= 1 then
                    if namePlate:IsVisible() then
                        --namePlate:SetWidth(100)
                        --namePlate:SetHeight(10)
                        local name = getName(namePlate)
                        local dstName = string.gsub(name, "%s+", "")
                        if not namePlate.xiconPlate or namePlate.nameStr and namePlate.nameStr ~= name then
                            namePlate.xiconPlate = 0
                        end
                        namePlate.nameStr = name
                        if testMode then
                            local dstGUID = "0x00001312031"
                            XiconDebuffLib:addDebuff(dstName, dstGUID, 29166, GetSpellInfo(29166)) -- innervate
                            XiconDebuffLib:addDebuff(dstName, dstGUID, 22570, GetSpellInfo(22570)) -- maim
                            XiconDebuffLib:addDebuff(dstName, dstGUID, 14309, GetSpellInfo(14309)) -- freezing trap
                            XiconDebuffLib:addDebuff(dstName, dstGUID, 12826, GetSpellInfo(12826)) -- polymorph
                        end
                        -- check if namePlate is target or mouseover
                        local border, castborder, casticon, highlight, nameText, levelText, levelIcon, raidIcon = namePlate:GetRegions()
                        local target = UnitExists("target") and namePlate:GetAlpha() == 1 or nil
                        local mouseover = UnitExists("mouseover") and highlight:IsShown() or nil
                        if target then
                            XiconDebuffLib:updateNameplate("target", namePlate, dstName)
                        elseif mouseover then
                            XiconDebuffLib:updateNameplate("mouseover", namePlate, dstName)
                        else
                            XiconDebuffLib:assignDebuffs(dstName, namePlate, false)
                        end
                    end
                end
            end
        end
        XiconPlateBuffs.testMode = false
        -- end do stuff
        lastUpdate = 0;
    end
end)

---------------------------------------------------------------------------------------------

-- INTERFACE OPTIONS

---------------------------------------------------------------------------------------------

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
function XiconPlateBuffs:CreateOptions()
    local panel = XiconPlateBuffs_Options.AddOptionsPanel("XiconPlateBuffs", function() end)
    local i,option_toggles = 1, {}

    local _,subText = panel:MakeTitleTextAndSubText("XiconPlateBuffs Addon", "General settings")

    --- Test button option
    local editBoxButton = panel:MakeButton(
            'name', 'Test',
            'description', 'Test',
            'default', true,
            'func', function() XiconPlateBuffs.testMode = true end)
    local label = editBoxButton:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    label:SetText("Test icons on nearby nameplates")
    label:SetPoint("BOTTOMLEFT", editBoxButton, "TOPLEFT",-3,0)
    editBoxButton:SetPoint("TOPLEFT",subText,"BOTTOMLEFT", 10, -15)
    i = i + 1
    option_toggles[i] = editBoxButton

    --- icon size option
    local iconSizeEditBox = createEditBox("Icon Size",panel,200,25,XiconPlateBuffsDB_local["iconSize"], function(frame)
        if frame:GetText() then
            local size = tonumber(frame:GetText())
            if size and size > 0 then
                XiconPlateBuffsDB_local["iconSize"] = size
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end
        end
    end)
    iconSizeEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -20)
    i = i + 1
    option_toggles[i] = iconSizeEditBox

    --- font size option
    local fontSizeEditBox = createEditBox("Font Size",panel,200,25,XiconPlateBuffsDB_local["fontSize"], function(frame)
        if frame:GetText() then
            local size = tonumber(frame:GetText())
            if size and size > 0 then
                XiconPlateBuffsDB_local["fontSize"] = size
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end
        end
    end)
    fontSizeEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = fontSizeEditBox

    --- y offset option
    local yOffsetEditBox = createEditBox("Vertical Offset",panel,200,25,XiconPlateBuffsDB_local["yOffset"], function(frame)
        if frame:GetText() then
            local offset = tonumber(frame:GetText())
            if offset then
                XiconPlateBuffsDB_local["yOffset"] = offset
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end
        end
    end)
    yOffsetEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = yOffsetEditBox

    --- x offset option
    local xOffsetEditBox = createEditBox("Horizontal Offset",panel,200,25,XiconPlateBuffsDB_local["xOffset"], function(frame)
        if frame:GetText() then
            local offset = tonumber(frame:GetText())
            if offset then
                XiconPlateBuffsDB_local["xOffset"] = offset
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end
        end
    end)
    xOffsetEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = xOffsetEditBox

    --- alpha option
    local alphaEditBox = createEditBox("Alpha (1.0 is 100%, 0.0 is invisible)",panel,200,25,XiconPlateBuffsDB_local["alpha"], function(frame)
        if frame:GetText() then
            local alpha = tonumber(frame:GetText())
            if alpha and alpha <= 1.0 then
                XiconPlateBuffsDB_local["alpha"] = alpha
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end
        end
    end)
    alphaEditBox:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, -10)
    i = i + 1
    option_toggles[i] = alphaEditBox

    --- responsiveness option
    local responsiveToggle = panel:MakeToggle(
            'name', 'Resize Icons Responsively',
            'description', 'Resize Icons responsively',
            'default', true,
            'getFunc', function() return XiconPlateBuffsDB_local["responsive"] end,
            'setFunc', function(value)
                XiconPlateBuffsDB_local["responsive"] = value
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end)
    responsiveToggle:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", -5, 0)
    i = i + 1
    option_toggles[i] = responsiveToggle

    --- sorting option
    local sortingDropdown = panel:MakeDropDown(
            'name', 'Sort Icons',
            'description', 'Specify sorting method',
            'values', {
                'none', "None",
                'ascending', "Ascending",
                'descending', "Descending",
            },
            'default', 'none',
            'getFunc', function() return XiconPlateBuffsDB_local["sorting"] end,
            'setFunc', function(value)
                XiconPlateBuffsDB_local["sorting"] = value
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end)
    sortingDropdown:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", -15, -15)
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
                XiconDebuffLib:UpdateSavedVariables(XiconPlateBuffsDB_local)
            end)
    defaultSettingsButton:SetPoint("TOPLEFT",option_toggles[i],"BOTTOMLEFT", 0, 0)
    i = i + 1
    option_toggles[i] = defaultSettingsButton
end