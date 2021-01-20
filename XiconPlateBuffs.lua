local ADDON_NAME = "XiconPlateBuffs"
local select, tonumber, tostring = select, tonumber, tostring
local XiconDebuffModule = GetXiconDebuffModule()

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
LibStub("AceAddon-3.0"):NewAddon(XiconPlateBuffs, ADDON_NAME)

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
    local _, _, _, _, nameRegion1, _, nameRegion2 = namePlate:GetRegions()
    if namePlate.aloftData then
        name = namePlate.aloftData.name
    elseif ElvUI then
        name = namePlate.UnitFrame.oldName:GetText()
    elseif sohighPlates then
        --name = namePlate.name:GetText()
        name = namePlate.oldname:GetText()
    elseif strmatch(nameRegion1:GetText(), "%d") then
        name = nameRegion2:GetText()
    else
        name = nameRegion1:GetText()
    end
    return name
end

---------------------------------------------------------------------------------------------

-- EVENT HANDLERS

---------------------------------------------------------------------------------------------

local events = {} -- store event functions to be assigned to reputation frame

function events:ADDON_LOADED(...)
    if select(1, ...) == ADDON_NAME then
        local trackedCC = initTrackedCrowdControl()
        local defaultTrackedCC = {}
        for k,v in pairs(trackedCC) do
            defaultTrackedCC[v.track..v.id] = true
        end
        local defaults = {
            profile = {
                debuff = {
                    iconSize = 40,
                    fontSize = 15,
                    responsive = true,
                    responsiveMax = 120,
                    font = "Fonts\\FRIZQT__.ttf",
                    yOffset = 5,
                    xOffset = -10,
                    alpha = 1.0,
                    sorting = "ascending",
                    anchor = { self = "BOTTOMLEFT", nameplate = "TOPLEFT" },
                    growDirection = { self = "LEFT", icon = "RIGHT" },
                },
                buff = {
                    iconSize = 40,
                    fontSize = 15,
                    responsive = true,
                    responsiveMax = 120,
                    font = "Fonts\\FRIZQT__.ttf",
                    yOffset = 0,
                    xOffset = 0,
                    alpha = 1.0,
                    sorting = "ascending",
                    anchor = { self = "BOTTOMLEFT", nameplate = "TOPLEFT" },
                    growDirection = { self = "LEFT", icon = "RIGHT" },
                },
                attachBuffsToDebuffs = true,
                trackedCC = defaultTrackedCC
            }
        }
        XiconPlateBuffs.db = LibStub("AceDB-3.0"):New("XiconPlateBuffsDB", defaults)
        XiconDebuffModule:Init()
        XiconPlateBuffs:CreateOptions()
        print("Loaded")
        print("write /xpb or /xpbconfig for options")
        XiconPlateBuffs:UnregisterEvent("ADDON_LOADED")
    end
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

local updateInterval, lastUpdate = .01, 0
XiconPlateBuffs:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        -- do stuff
        if NAMEPLATES_ON or XiconPlateBuffs.testMode then
            local num = WorldFrame:GetNumChildren()
            for i = 1, num do
                local namePlate = select(i, WorldFrame:GetChildren())
                if namePlate:GetNumRegions() > 2 and namePlate:GetNumChildren() >= 1 then
                    if namePlate:IsVisible() then
                        local name = getName(namePlate)
                        namePlate.nameStr = name
                        if XiconPlateBuffs.testMode then
                            local dstGUID = "0x00001312031"
                            XiconDebuffModule:addDebuff(string.gsub(name, "%s+", ""), dstGUID, 29166, 15) -- innervate
                            XiconDebuffModule:addDebuff(string.gsub(name, "%s+", ""), dstGUID, 22570, 5) -- maim
                            XiconDebuffModule:addDebuff(string.gsub(name, "%s+", ""), dstGUID, 14309, 8) -- freezing trap
                            XiconDebuffModule:addDebuff(string.gsub(name, "%s+", ""), dstGUID, 12826, 5) -- polymorph
                        end
                        -- check if namePlate is target or mouseover
                        local border, castborder, casticon, highlight, nameText, levelText, levelIcon, raidIcon = namePlate:GetRegions()
                        local target = UnitExists("target") and namePlate:GetAlpha() == 1 or nil
                        local mouseover = UnitExists("mouseover") and highlight:IsShown() or nil
                        if target then
                            XiconDebuffModule:updateNameplate("target", namePlate, name)
                        elseif mouseover then
                            XiconDebuffModule:updateNameplate("mouseover", namePlate, name)
                        else
                            XiconDebuffModule:assignDebuffs(name, namePlate, false)
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

