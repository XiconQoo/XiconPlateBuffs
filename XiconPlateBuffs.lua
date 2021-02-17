local ADDON_NAME = "XiconPlateBuffs"
local select, tonumber, tostring = select, tonumber, tostring
local XiconDebuffModule

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
    DEFAULT_CHAT_FRAME:AddMessage("|cffa0f6aa[".. ADDON_NAME .."]|r: " .. str)
end

---------------------------------------------------------------------------------------------

-- CORE

---------------------------------------------------------------------------------------------

local XiconPlateBuffs = CreateFrame("Frame", "XiconPlateBuffs", UIParent)
LibStub("AceAddon-3.0"):NewAddon(XiconPlateBuffs, ADDON_NAME)
XiconPlateBuffs.modules = {}

function XiconPlateBuffs:OnInitialize()
    self.knownNameplates = {}
    self.numKnownNameplates = 0
    self.Aloft = IsAddOnLoaded("Aloft")
    self.SoHighPlates = IsAddOnLoaded("SoHighPlates")
    self.ElvUI = IsAddOnLoaded("ElvUI")
    self.ShaguPlates = IsAddOnLoaded("ShaguPlates-tbc") or IsAddOnLoaded("ShaguPlates")
    XiconPlateBuffs:CreateOptions()
    for _,module in pairs(self.modules) do
        module:OnInitialize()
    end
    XiconDebuffModule = self.modules["XiconDebuffModule"]
    print("Loaded")
    print("write /xpb or /xpbconfig for options")
end

function XiconPlateBuffs:NewModule(name)
    local module = CreateFrame("Frame", name)
    self.modules[name] = module
    return module
end

---------------------------------------------------------------------------------------------

-- TABLE & MATH FUNCTIONS

---------------------------------------------------------------------------------------------

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

function XiconPlateBuffs:GetName(namePlate)
    local name
    if self.Aloft then
        if namePlate.aloftData then
            name = namePlate.aloftData.name
        end
    elseif self.SoHighPlates then
        if namePlate.oldname or namePlate.name then
            name = (namePlate.oldname and namePlate.oldname:GetText()) or (namePlate.name and namePlate.name:GetText())
        end
    else
        if self.ElvUI then
            if namePlate.UnitFrame then
                name = namePlate.UnitFrame.oldName:GetText()
            end
        end
        if not name then
            local _, _, _, _, nameRegion1, nameRegion2 = namePlate:GetRegions()
            if strmatch(nameRegion1:GetText(), "%d") then
                name = nameRegion2:GetText()
            else
                name = nameRegion1:GetText()
            end
        end
    end
    return name
end

---------------------------------------------------------------------------------------------

-- EVENT HANDLERS

---------------------------------------------------------------------------------------------

local events = {} -- store event functions to be assigned to reputation frame

function events:PLAYER_ENTERING_WORLD()
    XiconPlateBuffs.numKnownNameplates = 0
    XiconPlateBuffs.knownNameplates = {}
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

local NameplateFrame = CreateFrame("Frame")
NameplateFrame:SetScript("OnUpdate", function(self, elapsed)
    local num = WorldFrame:GetNumChildren()
    if XiconPlateBuffs.numKnownNameplates < num then
        XiconPlateBuffs.numKnownNameplates = num
        for i = 1, num do
            local namePlate = select(i, WorldFrame:GetChildren())
            if namePlate:GetNumRegions() > 2 and namePlate:GetNumChildren() >= 1 and not XiconPlateBuffs.knownNameplates[namePlate] then
                XiconPlateBuffs.knownNameplates[namePlate] = true
            end
        end
    end
end)

local updateInterval, lastUpdate = .01, 0
XiconPlateBuffs:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        -- do stuff
        for namePlate,_ in pairs(self.knownNameplates) do
            if namePlate:IsVisible() then
                local name = self:GetName(namePlate)
                if name then
                    namePlate.nameStr = name
                    if self.testMode then
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
        self.testMode = false
        -- end do stuff
        lastUpdate = 0;
    end
end)

