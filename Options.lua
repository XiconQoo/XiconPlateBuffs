local XPB = LibStub("AceAddon-3.0"):GetAddon("XiconPlateBuffs")

---------------------------------------------------------------------------------------------

-- INTERFACE OPTIONS

---------------------------------------------------------------------------------------------

local customSpell = { id = nil, duration = nil, track = nil }
local errorMessage = ""

local function getCustomSpell(customSpells)
    local spellList = {}
    table.sort(customSpells, function (a, b)
        return GetSpellInfo(a.id) < GetSpellInfo(b.id)
    end)
    local order = 1
    for i=1, #customSpells do
        local spellName,_,texture = GetSpellInfo(customSpells[i].id)
        spellList["customSpell" .. customSpells[i].id] = {
            order = i,
            name = "",
            inline = true,
            type = "group",
            args = {
                desc = {
                    order = 1,
                    name = spellName,
                    type = "toggle",
                    image = texture,
                    width = "1",
                    desc = format("Duration: %ds | Spell School: %s | ID: %d", customSpells[i].duration, customSpells[i].spellSchool, customSpells[i].id),
                    set = function(info, state)
                        XPB.db.profile.trackedCC[customSpells[i].track..customSpells[i].id] = state
                        XPB.modules["XiconDebuffModule"]:OnInitialize()
                    end,
                    get = function(info)
                        return XPB.db.profile.trackedCC[customSpells[i].track..customSpells[i].id]
                    end,
                },
                del = {
                    order = 2,
                    type = "execute",
                    name = "Del",
                    width = "0.35",
                    func = function()
                        local track = customSpells[i].track
                        tremove(customSpells, i)
                        if track == "buff" then
                            XPB.options.args.addCustomSpell.args.customBuffs.args = getCustomSpell(customSpells)
                        else
                            XPB.options.args.addCustomSpell.args.customDebuffs.args = getCustomSpell(customSpells)
                        end
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("XiconPlateBuffs")
                    end,
                },
                edit = {
                    order = 3,
                    type = "execute",
                    name = "Edit",
                    width = "0.35",
                    func = function()
                        XPB.options.args.addCustomSpell.args.spellId.set(nil, tostring(customSpells[i].id))
                        XPB.options.args.addCustomSpell.args.duration.set(nil, tostring(customSpells[i].duration))
                        XPB.options.args.addCustomSpell.args.track.set(nil, tostring(customSpells[i].track))
                        XPB.options.args.addCustomSpell.args.spellSchool.set(nil, tostring(customSpells[i].spellSchool))
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("XiconPlateBuffs")
                    end,
                }
            }
        }
        order = order + 1
    end
    return spellList
end

local function getSpells()
    local spells = {
        ckeckAll = {
            order = 1,
            width = "0.7",
            name = "Check All",
            type = "execute",
            func = function(info)
                for k,v in pairs(XPB.db.profile.trackedCC) do
                    XPB.db.profile.trackedCC[k] = true
                end
            end,
        },
        uncheckAll = {
            order = 2,
            width = "0.7",
            name = "Uncheck All",
            type = "execute",
            func = function(info)
                for k,v in pairs(XPB.db.profile.trackedCC) do
                    XPB.db.profile.trackedCC[k] = false
                end
            end,
        },
        debuffs = {
            order = 3,
            type = "group",
            name = "Debuffs",
            args = {},
        },
        buffs = {
            order = 4,
            type = "group",
            name = "Buffs",
            args = {},
        },
    }
    local allSpells = XPB.trackedCrowdControl
    local buffs, debuffs = {},{}
    for k,v in pairs(allSpells) do
        if v.track == "debuff" then tinsert(debuffs, v) end
        if v.track == "buff" then tinsert(buffs, v) end
    end
    table.sort(buffs, function(a,b)
        local spellA = GetSpellInfo(a.id)
        local spellB = GetSpellInfo(b.id)
        return spellA:upper() < spellB:upper()
    end)
    table.sort(debuffs, function(a,b)
        local spellA = GetSpellInfo(a.id)
        local spellB = GetSpellInfo(b.id)
        return spellA:upper() < spellB:upper()
    end)
    for i=1, #debuffs do
        local spellName, _, texture = GetSpellInfo(debuffs[i].id)
        spells.debuffs.args["debuff"..debuffs[i].id] = {
            order = i,
            name = spellName,
            type = "toggle",
            image = texture,
            width = "2",
            desc = format("Duration: %ds", debuffs[i].duration),
            arg = debuffs[i].id,
        }
    end
    for i=1, #buffs do
        local spellName, _, texture = GetSpellInfo(buffs[i].id)
        spells.buffs.args["buff"..buffs[i].id] = {
            order = i,
            name = spellName,
            type = "toggle",
            image = texture,
            width = "2",
            desc = format("Duration: %ds", buffs[i].duration),
            arg = buffs[i].id,
        }
    end
    return spells
end

function XPB:GetTrackedCC()
    local trackedCC = {}
    local allSpells = self.trackedCrowdControl
    local customDebuffs = self.db.profile.customDebuffs
    local customBuffs = self.db.profile.customBuffs
    for k,v in pairs(self.db.profile.trackedCC) do
        if v then
            local spellId = string.match(k, "(%d+)")
            local spellName = GetSpellInfo(spellId)
            trackedCC[spellName] = allSpells[spellName]
        end
    end
    for i=1, #customDebuffs do
        if (XPB.db.profile.trackedCC[customDebuffs[i].track..customDebuffs[i].id]) then
            trackedCC[GetSpellInfo(customDebuffs[i].id)] = customDebuffs[i]
        end
    end
    for i=1, #customBuffs do
        if (XPB.db.profile.trackedCC[customBuffs[i].track..customBuffs[i].id]) then
            trackedCC[GetSpellInfo(customBuffs[i].id)] = customBuffs[i]
        end
    end
    return trackedCC
end

local DebuffTypeColor = { };
DebuffTypeColor["none"]     = { r = 0.80, g = 0, b = 0 , a = 1};
DebuffTypeColor["magic"]    = { r = 0.20, g = 0.60, b = 1.00, a = 1};
DebuffTypeColor["curse"]    = { r = 0.60, g = 0.00, b = 1.00, a = 1 };
DebuffTypeColor["disease"]  = { r = 0.60, g = 0.40, b = 0, a = 1 };
DebuffTypeColor["poison"]   = { r = 0.00, g = 0.60, b = 0, a = 1 };
DebuffTypeColor["immune"]   = { r = 1.00, g = 0.02, b = 0.99, a = 1 };
DebuffTypeColor[""] = DebuffTypeColor["none"];

function XPB:CreateOptions()
    local trackedCC = XPB.trackedCrowdControl
    local defaultTrackedCC = {}
    for k,v in pairs(trackedCC) do
        defaultTrackedCC[v.track..v.id] = true
    end
    local defaults = {
        profile = {
            iconBorderColorCurse = DebuffTypeColor["curse"],
            iconBorderColorMagic = DebuffTypeColor["magic"],
            iconBorderColorPoison = DebuffTypeColor["poison"],
            iconBorderColorPhysical = DebuffTypeColor["none"],
            iconBorderColorImmune = DebuffTypeColor["immune"],
            iconBorderColorInterrupt = DebuffTypeColor["none"],
            debuff = {
                iconSize = 40,
                iconBorder = "Interface\\AddOns\\XiconPlateBuffs\\media\\Border_rounded_blp",
                iconBorderColor = {r = 1, g = 0, b = 0, a = 1},
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
                iconBorder = "Interface\\AddOns\\XiconPlateBuffs\\media\\Border_rounded_blp",
                iconBorderColor = {r = 0, g = 0, b = 0, a = 1},
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
            customBuffs = {},
            customDebuffs = {},
            attachBuffsToDebuffs = true,
            trackedCC = defaultTrackedCC
        }
    }
    self.db = LibStub("AceDB-3.0"):New("XiconPlateBuffsDB", defaults)

    self.options = {
        name = "XiconPlateBuffs",
        descStyle = "inline",
        type = "group",
        plugins = {
            profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) },
        },
        childGroups = "tab",
        args = {
            style = {
                name = "Style",
                type = "group",
                order = 10,
                childGroups = "tab",
                args = {
                    attachBuffsToDebuffs = {
                        name = "Attach Buffs to Debuffs",
                        type = "toggle",
                        set = function(info, value) self.db.profile.attachBuffsToDebuffs = value end,
                        get = function(info) return self.db.profile.attachBuffsToDebuffs end,
                    },
                    testButton = {
                        name = "Test",
                        type = "execute",
                        width = "half",
                        func = function() self.testMode = true end
                    },
                    debuff = {
                        name = "Debuffs",
                        type = "group",
                        order = 11,
                        get = function(info)
                            local option = info[#info]
                            return self.db.profile.debuff[option]
                        end,
                        set = function(info, state)
                            local option = info[#info]
                            self.db.profile.debuff[option] = state
                        end,
                        args = {
                            iconSize = {
                                order = 1,
                                min = 1,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Icon Size",
                                width = "full",
                            },
                            fontSize = {
                                order = 2,
                                min = 1,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Font Size",
                            },
                            font = {
                                order = 3,
                                type = "select",
                                name = "Cooldown Font",
                                values = { ["Fonts\\ARIALN.ttf"] = "Arial",
                                           ["Fonts\\FRIZQT__.ttf"] = "Fritz Quadrata",
                                           ["Fonts\\MORPHEUS.ttf"] = "Morpheus",
                                           ["Fonts\\skurri.ttf"] = "Skurri"
                                },
                                width = "0.7"
                            },
                            responsive = {
                                order = 4,
                                name = "Responsive Scaling",
                                type = "toggle"
                            },
                            responsiveMax = {
                                hidden = function() return not self.db.profile.debuff.responsive end,
                                order = 5,
                                min = self.db.profile.debuff.iconSize,
                                max = 1000,
                                step = 1,
                                type = "range",
                                name = "Max Responsive Width/Height",
                                width = "full",
                            },
                            xOffset = {
                                order = 6,
                                min = -100,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Horizontal Offset",
                                width = "0.85",
                            },
                            yOffset = {
                                order = 7,
                                min = -100,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Vertical Offset",
                                width = "0.85",
                            },
                            alpha = {
                                order = 8,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                type = "range",
                                name = "Alpha",
                                isPercent = true,
                                width = "full",
                            },
                            sorting = {
                                order = 9,
                                type = "select",
                                name = "Sorting",
                                values = { ["none"] = "None", ["ascending"] = "Ascending", ["descending"] = "Descending"},
                            },
                            anchor = {
                                order = 10,
                                type = "select",
                                name = "Anchor",
                                values = { ["TOPLEFT"] = "TOPLEFT", ["TOPRIGHT"] = "TOPRIGHT", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["BOTTOMLEFT"] = "BOTTOMLEFT", ["BOTTOMRIGHT"] = "BOTTOMRIGHT" },
                                get = function(info)
                                    return self.db.profile.debuff.anchor.nameplate
                                end,
                                set = function(info, state)
                                    if state == "TOPLEFT" then
                                        self.db.profile.debuff.anchor.self = "BOTTOMLEFT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    elseif state == "TOPRIGHT" then
                                        self.db.profile.debuff.anchor.self = "BOTTOMRIGHT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    elseif state == "LEFT" then
                                        self.db.profile.debuff.anchor.self = "RIGHT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    elseif state == "RIGHT" then
                                        self.db.profile.debuff.anchor.self = "LEFT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    elseif state == "BOTTOMLEFT" then
                                        self.db.profile.debuff.anchor.self = "TOPLEFT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    elseif state == "BOTTOMRIGHT" then
                                        self.db.profile.debuff.anchor.self = "TOPRIGHT"
                                        self.db.profile.debuff.anchor.nameplate = state
                                    end
                                end
                            },
                            growDirection = {
                                order = 11,
                                type = "select",
                                name = "Grow Direction",
                                values = { ["TOP"] = "TOP", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["BOTTOM"] = "BOTTOM"},
                                get = function(info)
                                    return self.db.profile.debuff.growDirection.icon
                                end,
                                set = function(info, state)
                                    if state == "TOP" then
                                        self.db.profile.debuff.growDirection.self = "BOTTOM"
                                        self.db.profile.debuff.growDirection.icon = state
                                    elseif state == "BOTTOM" then
                                        self.db.profile.debuff.growDirection.self = "TOP"
                                        self.db.profile.debuff.growDirection.icon = state
                                    elseif state == "LEFT" then
                                        self.db.profile.debuff.growDirection.self = "RIGHT"
                                        self.db.profile.debuff.growDirection.icon = state
                                    elseif state == "RIGHT" then
                                        self.db.profile.debuff.growDirection.self = "LEFT"
                                        self.db.profile.debuff.growDirection.icon = state
                                    end
                                end
                            }
                        },
                    },
                    buff = {
                        name = "Buffs",
                        type = "group",
                        order = 12,
                        get = function(info)
                            local option = info[#info]
                            return self.db.profile.buff[option]
                        end,
                        set = function(info, state)
                            local option = info[#info]
                            self.db.profile.buff[option] = state
                        end,
                        args = {
                            iconSize = {
                                order = 1,
                                min = 1,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Icon Size",
                                width = "full",
                            },
                            fontSize = {
                                order = 2,
                                min = 1,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Font Size",
                            },
                            font = {
                                order = 3,
                                type = "select",
                                name = "Cooldown Font",
                                values = { ["Fonts\\ARIALN.ttf"] = "Arial",
                                           ["Fonts\\FRIZQT__.ttf"] = "Fritz Quadrata",
                                           ["Fonts\\MORPHEUS.ttf"] = "Morpheus",
                                           ["Fonts\\skurri.ttf"] = "Skurri"
                                },
                                width = "0.7"
                            },
                            responsive = {
                                order = 4,
                                name = "Responsive Scaling",
                                type = "toggle",
                            },
                            responsiveMax = {
                                hidden = function() return not self.db.profile.buff.responsive end,
                                order = 5,
                                min = self.db.profile.buff.iconSize,
                                max = 1000,
                                step = 1,
                                type = "range",
                                name = "Max Responsive Width/Height",
                                width = "full",
                            },
                            xOffset = {
                                order = 6,
                                min = -100,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Horizontal Offset",
                                width = "0.85",
                            },
                            yOffset = {
                                order = 7,
                                min = -100,
                                max = 100,
                                step = 1,
                                type = "range",
                                name = "Vertical Offset",
                                width = "0.85",
                            },
                            alpha = {
                                order = 8,
                                min = 0,
                                max = 1,
                                step = 0.01,
                                type = "range",
                                name = "Alpha",
                                isPercent = true,
                                width = "full",
                            },
                            sorting = {
                                order = 9,
                                type = "select",
                                name = "Sorting",
                                values = { ["none"] = "None", ["ascending"] = "Ascending", ["descending"] = "Descending"},
                            },
                            anchor = {
                                --hidden = function() return self.db.attachBuffsToDebuffs end,
                                order = 10,
                                type = "select",
                                name = "Anchor",
                                values = { ["TOPLEFT"] = "TOPLEFT", ["TOPRIGHT"] = "TOPRIGHT", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["BOTTOMLEFT"] = "BOTTOMLEFT", ["BOTTOMRIGHT"] = "BOTTOMRIGHT" },
                                get = function(info)
                                    return self.db.profile.buff.anchor.nameplate
                                end,
                                set = function(info, state)
                                    if state == "TOPLEFT" then
                                        self.db.profile.buff.anchor.self = "BOTTOMLEFT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    elseif state == "TOPRIGHT" then
                                        self.db.profile.buff.anchor.self = "BOTTOMRIGHT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    elseif state == "LEFT" then
                                        self.db.profile.buff.anchor.self = "RIGHT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    elseif state == "RIGHT" then
                                        self.db.profile.buff.anchor.self = "LEFT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    elseif state == "BOTTOMLEFT" then
                                        self.db.profile.buff.anchor.self = "TOPLEFT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    elseif state == "BOTTOMRIGHT" then
                                        self.db.profile.buff.anchor.self = "TOPRIGHT"
                                        self.db.profile.buff.anchor.nameplate = state
                                    end
                                end
                            },
                            growDirection = {
                                --hidden = function() return self.db.attachBuffsToDebuffs end,
                                order = 11,
                                type = "select",
                                name = "Grow Direction",
                                values = { TOP = "TOP", LEFT = "LEFT", RIGHT = "RIGHT", BOTTOM = "BOTTOM"},
                                get = function(info)
                                    return self.db.profile.buff.growDirection.icon
                                end,
                                set = function(info, state)
                                    if state == "TOP" then
                                        self.db.profile.buff.growDirection.self = "BOTTOM"
                                        self.db.profile.buff.growDirection.icon = state
                                    elseif state == "BOTTOM" then
                                        self.db.profile.buff.growDirection.self = "TOP"
                                        self.db.profile.buff.growDirection.icon = state
                                    elseif state == "LEFT" then
                                        self.db.profile.buff.growDirection.self = "RIGHT"
                                        self.db.profile.buff.growDirection.icon = state
                                    elseif state == "RIGHT" then
                                        self.db.profile.buff.growDirection.self = "LEFT"
                                        self.db.profile.buff.growDirection.icon = state
                                    end
                                end
                            }
                        },
                    },
                },
            },
            spellList = {
                name = "Spell List",
                type = "group",
                order = 11,
                childGroups = "tab",
                args = getSpells(),
                set = function(info, state)
                    local option = info[#info]
                    self.db.profile.trackedCC[option] = state
                end,
                get = function(info)
                    local option = info[#info]
                    return self.db.profile.trackedCC[option]
                end,
            },
            addCustomSpell = {
                name = "Custom Spell",
                type = "group",
                childGroups = "tab",
                order = 12,
                args = {
                    errorMessage = {
                        --hidden = function(info) return not customSpell.id end,
                        type = "description",
                        image = "",
                        imageWidth = 20,
                        imageHeight = 20,
                        name = "",
                        width = "full",
                        fontSize = "large",
                        order = 1
                    },
                    spellId = {
                        name = "SpellID",
                        type = "input",
                        order = 2,
                        width = "0.5",
                        pattern = "%d+",
                        validate = function(info, value)
                            local spellName,_,texture = GetSpellInfo(value)
                            if not spellName then
                                customSpell.id = nil
                                self.options.args.addCustomSpell.args.errorMessage.name = "No spell info found for SpellID =  " .. value
                                self.options.args.addCustomSpell.args.errorMessage.image = "Interface\\Icons\\INV_Misc_QuestionMark",
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("XiconPlateBuffs")
                                return errorMessage
                            else
                                --self.options.args.addCustomSpell.args.errorMessage.desc =  format("|T%s:20|t %s", texture, spellName)
                                self.options.args.addCustomSpell.args.errorMessage.name = spellName
                                self.options.args.addCustomSpell.args.errorMessage.image = texture
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("XiconPlateBuffs")
                                return true
                            end
                        end,
                        get = function(info) return customSpell.id end,
                        set = function(info, value) customSpell.id = value end,
                    },
                    duration = {
                        name = "Duration",
                        hidden = function(info) return not customSpell.id end,
                        type = "input",
                        order = 3,
                        width = "0.5",
                        pattern = "%d+",
                        get = function(info) return customSpell.duration end,
                        set = function(info, value) customSpell.duration = value end,
                    },
                    track = {
                        name = "Track Type",
                        hidden = function(info) return not customSpell.id end,
                        type = "select",
                        width = "0.7",
                        order = 5,
                        values = {["debuff"] = "Debuff", ["buff"] = "Buff"},
                        get = function(info) return customSpell.track end,
                        set = function(info, value) customSpell.track = value end
                    },
                    spellSchool = {
                        name = "Spell School",
                        hidden = function(info) return not customSpell.id end,
                        type = "select",
                        width = "0.7",
                        order = 6,
                        values = {["magic"] = "Magic", ["physical"] = "Physical", ["poison"] = "Poison", ["curse"] = "Curse", ["immune"] = "Immune"},
                        get = function(info) return customSpell.spellSchool end,
                        set = function(info, value) customSpell.spellSchool = value end
                    },
                    add = {
                        name = "Add",
                        hidden = function(info) return not customSpell.id end,
                        disabled = function(info) return not customSpell.id
                                or not customSpell.duration
                                or not customSpell.track
                                or not customSpell.spellSchool end,
                        type = "execute",
                        width = "0.5",
                        order = 4,
                        func = function(info)
                            local function insert(table)
                                local exists
                                local spell = {id = tonumber(customSpell.id), duration = tonumber(customSpell.duration), spellSchool = customSpell.spellSchool, track = customSpell.track}
                                for i = 1, #table do
                                    if table[i].id == spell.id then
                                        exists = i
                                        break
                                    end
                                end
                                if exists then
                                    table[exists] = spell
                                else
                                    tinsert(table, spell)
                                end
                            end
                            if customSpell.track == "buff" then
                                insert(self.db.profile.customBuffs)
                                self.options.args.addCustomSpell.args.customBuffs.args = getCustomSpell(self.db.profile.customBuffs)
                            else
                                insert(self.db.profile.customDebuffs)
                                self.options.args.addCustomSpell.args.customDebuffs.args = getCustomSpell(self.db.profile.customDebuffs)
                            end
                            XPB.db.profile.trackedCC[customSpell.track..customSpell.id] = true
                            XPB.modules["XiconDebuffModule"]:OnInitialize()
                            customSpell = { id = nil, duration = nil, track = nil }
                            self.options.args.addCustomSpell.args.errorMessage.name = ""
                            self.options.args.addCustomSpell.args.errorMessage.image = ""
                            self.modules["XiconDebuffModule"]:OnInitialize()
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("XiconPlateBuffs")
                        end,
                    },
                    customDebuffs = {
                        order = 7,
                        name = "Custom Debuffs",
                        type = "group",
                        childGroups = "simple",
                        args = getCustomSpell(self.db.profile.customDebuffs)
                    },
                    customBuffs = {
                        order = 8,
                        name = "Custom Buffs",
                        type = "group",
                        childGroups = "simple",
                        args = getCustomSpell(self.db.profile.customBuffs)
                    },
                }
            }
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("XiconPlateBuffs", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XiconPlateBuffs", "XiconPlateBuffs")
end