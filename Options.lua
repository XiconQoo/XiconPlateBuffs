local XPB = LibStub("AceAddon-3.0"):GetAddon("XiconPlateBuffs")

---------------------------------------------------------------------------------------------

-- INTERFACE OPTIONS

---------------------------------------------------------------------------------------------

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
            name = "Unheck All",
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
    local allSpells = initTrackedCrowdControl()
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
            --name = spellName,
            type = "toggle",
            icon = texture,
            arg = debuffs[i].id,
            name = function()
                return format("|T%s:20|t %s", texture, spellName)
            end
        }
    end
    for i=1, #buffs do
        local spellName, _, texture = GetSpellInfo(buffs[i].id)
        spells.buffs.args["buff"..buffs[i].id] = {
            order = i,
            --name = spellName,
            type = "toggle",
            icon = texture,
            arg = buffs[i].id,
            name = function()
                return format("|T%s:20|t %s", texture, spellName)
            end
        }
    end
    return spells
end

function XPB:GetTrackedCC()
    local trackedCC = {}
    local allSpells = initTrackedCrowdControl()
    for k,v in pairs(self.db.profile.trackedCC) do
        if v then
            local spellId = string.match(k, "(%d+)")
            local spellName = GetSpellInfo(spellId)
            trackedCC[spellName] = allSpells[spellName]
        end
    end
    return trackedCC
end

function XPB:CreateOptions()
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
            }
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("XiconPlateBuffs", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XiconPlateBuffs", "XiconPlateBuffs")
end