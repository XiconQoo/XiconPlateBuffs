local XiconPlateBuffs = LibStub("AceAddon-3.0"):GetAddon("XiconPlateBuffs")

XiconPlateBuffs.trackedCrowdControl = {

    ["interrupts"] = {
        [GetSpellInfo(19675)] = {duration = 4, id = 19675, track = "debuff", texture = select(3, GetSpellInfo(19675))}, -- Feral Charge Effect (Druid)
        [GetSpellInfo(2139)] = {duration = 8, id = 2139, track = "debuff", texture = select(3, GetSpellInfo(2139))}, -- Counterspell (Mage)
        [GetSpellInfo(1766)] = {duration = 5, id = 1766, track = "debuff", texture = select(3, GetSpellInfo(1766))}, -- Kick (Rogue)
        [GetSpellInfo(6552)] = {duration = 4, id = 6552, track = "debuff", texture = select(3, GetSpellInfo(6552))}, -- Pummel (Warrior)
        [GetSpellInfo(72)] = {duration = 6, id = 72, track = "debuff", texture = select(3, GetSpellInfo(72))}, -- Shield Bash (Warrior)
        [GetSpellInfo(8042)] = {duration = 2, id = 8042, track = "debuff", texture = select(3, GetSpellInfo(8042))}, -- Earth Shock (Shaman)
        [GetSpellInfo(19244)] = {duration = 5, id = 1, track = "debuff", texture = select(3, GetSpellInfo(19244))}, -- Spell Lock (Warlock
        [GetSpellInfo(32747)] = {duration = 3, id = 32747, track = "debuff", texture = select(3, GetSpellInfo(32747))}, -- Deadly Throw Interrupt
    },
    ["shortinterrupts"] = {
        --Shaman
        [GetSpellInfo(331)] = true, --Healing Wave
        [GetSpellInfo(8004)] = true, -- Lesser Healing Wave
        [GetSpellInfo(10622)] = true, -- Chain Heal
        [GetSpellInfo(20609)] = true, -- Ancestral Spirit
        --Paladin
        [GetSpellInfo(635)] = true, --Holy Light
        [GetSpellInfo(19750)] = true, -- Flash of Light
        [GetSpellInfo(10322)] = true, -- Redemption
        [GetSpellInfo(24274)] = true, -- Hammer of Wrath
        [GetSpellInfo(2878)] = true, -- Turn Undead
        [GetSpellInfo(27139)] = true, -- Holy Wrath
        [GetSpellInfo(10326)] = true, -- Turn Evil
    },

    -- Cyclone
    [GetSpellInfo(33786)] = {
        track = "debuff",
        duration = 6,
        priority = 40,
        spellSchool = "immune",
        id = 33786,
    },
    -- Hibernate
    [GetSpellInfo(18658)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        spellSchool = "magic",
        id = 18658,
    },
    -- Entangling Roots
    [GetSpellInfo(26989)] = {
        track = "debuff",
        duration = 10,
        priority = 30,
        onDamage = true,
        spellSchool = "magic",
        root = true,
        id = 26989,
    },
    -- Feral Charge
    [GetSpellInfo(16979)] = {
        track = "debuff",
        duration = 4,
        priority = 30,
        spellSchool = "physical",
        root = true,
        id = 16979,
    },
    -- Bash
    [GetSpellInfo(8983)] = {
        track = "debuff",
        duration = 4,
        priority = 30,
        spellSchool = "physical",
        id = 8983,
    },
    -- Pounce
    [GetSpellInfo(27006)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        spellSchool = "physical",
        id = 27006,
    },
    -- Maim
    [GetSpellInfo(22570)] = {
        track = "debuff",
        duration = 6,
        priority = 40,
        incapacite = true,
        spellSchool = "physical",
        id = 22570,
    },


    ---

    -- Innervate
    [GetSpellInfo(29166)] = {
        track = "buff",
        duration = 20,
        priority = 10,
        spellSchool = "magic",
        id = 29166,
    },


    -- Freezing Trap Effect
    [GetSpellInfo(14309)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        spellSchool = "magic",
        id = 14309,
    },
    -- Wyvern Sting
    [GetSpellInfo(19386)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        spellSchool = "poison",
        sleep = true,
        id = 19386,
    },
    -- Scatter Shot
    [GetSpellInfo(19503)] = {
        track = "debuff",
        duration = 4,
        priority = 40,
        onDamage = true,
        spellSchool = "physical",
        id = 19503,
    },
    -- Silencing Shot
    [GetSpellInfo(34490)] = {
        track = "debuff",
        duration = 3,
        priority = 15,
        spellSchool = "magic",
        id = 34490,
    },
    -- Intimidation
    [GetSpellInfo(19577)] = {
        track = "debuff",
        duration = 2,
        priority = 40,
        spellSchool = "physical",
        id = 19577,
    },
    --Scare Beast 14327
    [GetSpellInfo(14327)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        spellSchool = "magic",
        id = 14327,
    },
    -- Improved Wing Clip 19229
    [GetSpellInfo(19229)] = {
        track = "debuff",
        duration = 5,
        priority = 20,
        spellSchool = "physical",
        id = 19229,
    },
    -- The Beast Within
    [GetSpellInfo(34692)] = {
        track = "buff",
        duration = 18,
        priority = 20,
        spellSchool = "physical",
        id = 34692,
    },


    -- Polymorph
    [GetSpellInfo(12826)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        spellSchool = "magic",
        id = 12826,
    },
    -- Dragon's Breath
    [GetSpellInfo(31661)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        onDamage = true,
        spellSchool = "magic",
        id = 31661,
    },
    -- Frost Nova
    [GetSpellInfo(27088)] = {
        track = "debuff",
        duration = 8,
        priority = 30,
        onDamage = true,
        spellSchool = "magic",
        root = true,
        id = 27088,
    },
    -- Frostbite
    [GetSpellInfo(12494)] = {
        track = "debuff",
        duration = 5,
        priority = 30,
        onDamage = true,
        spellSchool = "magic",
        root = true,
        id = 12494,
    },
    -- Freeze (Water Elemental)
    [GetSpellInfo(33395)] = {
        track = "debuff",
        duration = 8,
        priority = 30,
        onDamage = true,
        spellSchool = "magic",
        root = true,
        id = 33395,
    },
    -- Counterspell - Silence
    [GetSpellInfo(18469)] = {
        track = "debuff",
        duration = 4,
        priority = 15,
        spellSchool = "magic",
        id = 18469,
    },

    -- Ice Block
    [GetSpellInfo(45438)] = {
        track = "buff",
        duration = 10,
        priority = 20,
        spellSchool = "immune",
        id = 45438,
    },


    -- Hammer of Justice
    [GetSpellInfo(10308)] = {
        track = "debuff",
        duration = 6,
        priority = 40,
        spellSchool = "magic",
        id = 10308,
    },
    -- Repentance
    [GetSpellInfo(20066)] = {
        track = "debuff",
        duration = 6,
        priority = 40,
        onDamage = true,
        spellSchool = "magic",
        incapacite = true,
        id = 20066,
    },

    -- Blessing of Protection
    [GetSpellInfo(10278)] = {
        track = "buff",
        duration = 10,
        priority = 10,
        spellSchool = "magic",
        id = 10278,
    },
    -- Blessing of Freedom
    [GetSpellInfo(1044)] = {
        track = "buff",
        duration = 14,
        priority = 10,
        spellSchool = "magic",
        id = 1044,
    },
    -- Divine Shield
    [GetSpellInfo(642)] = {
        track = "buff",
        duration = 12,
        priority = 20,
        spellSchool = "immune",
        id = 642,
    },

    -- Psychic Scream
    [GetSpellInfo(8122)] = {
        track = "debuff",
        duration = 8,
        priority = 40,
        onDamage = true,
        fear = true,
        spellSchool = "magic",
        id = 8122,
    },
    --Blackout Stun 15269
    [GetSpellInfo(15269)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        spellSchool = "physical",
        id = 15269,
    },
    -- Chastise
    [GetSpellInfo(44047)] = {
        track = "debuff",
        duration = 8,
        priority = 30,
        root = true,
        spellSchool = "immune",
        id = 44047,
    },
    -- Mind Control
    [GetSpellInfo(605)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        magic = true,
        spellSchool = "immune",
        id = 605,
    },
    -- Silence
    [GetSpellInfo(15487)] = {
        track = "debuff",
        duration = 5,
        priority = 15,
        spellSchool = "magic",
        id = 15487,
    },

    -- Pain Suppression
    [GetSpellInfo(33206)] = {
        track = "buff",
        duration = 8,
        priority = 10,
        spellSchool = "magic",
        id = 33206,
    },

    -- Sap
    [GetSpellInfo(6770)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        incapacite = true,
        spellSchool = "physical",
        id = 6770,
    },
    -- Blind
    [GetSpellInfo(2094)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        spellSchool = "physical",
        id = 2094,
    },
    -- Cheap Shot
    [GetSpellInfo(1833)] = {
        track = "debuff",
        duration = 4,
        priority = 40,
        spellSchool = "physical",
        id = 1833,
    },
    -- Kidney Shot
    [GetSpellInfo(8643)] = {
        track = "debuff",
        duration = 6,
        priority = 40,
        spellSchool = "physical",
        id = 8643,
    },
    -- Gouge
    [GetSpellInfo(1776)] = {
        track = "debuff",
        duration = 4,
        priority = 40,
        onDamage = true,
        incapacite = true,
        spellSchool = "physical",
        id = 1776,
    },
    -- Kick - Silence
    [GetSpellInfo(18425)] = {
        track = "debuff",
        duration = 2,
        priority = 15,
        spellSchool = "physical",
        id = 18425,
    },
    -- Garrote - Silence
    [GetSpellInfo(1330)] = {
        track = "debuff",
        duration = 3,
        priority = 15,
        spellSchool = "physical",
        id = 1330,
    },

    -- Cloak of Shadows
    [GetSpellInfo(31224)] = {
        track = "buff",
        duration = 5,
        priority = 20,
        spellSchool = "physical",
        id = 31224,
    },

    -- Fear
    [GetSpellInfo(5782)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        fear = true,
        spellSchool = "magic",
        id = 5782,
    },
    -- Death Coil
    [GetSpellInfo(27223)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        spellSchool = "magic",
        id = 27223,
    },
    -- Shadowfury
    [GetSpellInfo(30283)] = {
        track = "debuff",
        duration = 2,
        priority = 40,
        spellSchool = "magic",
        id = 30283,
    },
    -- Seduction (Succubus)
    [GetSpellInfo(6358)] = {
        track = "debuff",
        duration = 10,
        priority = 40,
        onDamage = true,
        fear = true,
        spellSchool = "magic",
        id = 6358,
    },
    -- Howl of Terror
    [GetSpellInfo(5484)] = {
        track = "debuff",
        duration = 8,
        priority = 40,
        onDamage = true,
        fear = true,
        spellSchool = "magic",
        id = 5484,
    },
    -- Spell Lock (Felhunter)
    [GetSpellInfo(24259)] = {
        track = "debuff",
        duration = 3,
        priority = 15,
        spellSchool = "magic",
        id = 24259,
    },
    --[[
    -- Unstable Affliction
    [GetSpellInfo(31117)] = {
        track = "debuff",
        duration = 5,
        priority = 15,
        magic = true,
        id = 31117,
    },
    --]]


    -- Intimidating Shout
    [GetSpellInfo(5246)] = {
        track = "debuff",
        duration = 8,
        priority = 15,
        onDamage = true,
        fear = true,
        spellSchool = "physical",
        id = 5246,
    },
    -- Concussion Blow
    [GetSpellInfo(12809)] = {
        track = "debuff",
        duration = 5,
        priority = 40,
        spellSchool = "physical",
        id = 12809,
    },
    -- Intercept Stun
    [GetSpellInfo(25274)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        spellSchool = "physical",
        texture = select(3, GetSpellInfo(20252)),
        id = 25274,
    },
    --Charge Stun
    [GetSpellInfo(7922)] = {
        track = "debuff",
        duration = 1,
        priority = 40,
        spellSchool = "physical",
        texture = select(3, GetSpellInfo(100)),
        id = 7922,
    },
    --Improved Hamstring 23694
    [GetSpellInfo(23694)] = {
        track = "debuff",
        duration = 5,
        priority = 40,
        spellSchool = "physical",
        id = 23694,
    },
    -- Spell Reflection
    [GetSpellInfo(23920)] = {
        track = "buff",
        duration = 5,
        priority = 10,
        spellSchool = "physical",
        id = 23920,
    },

    -- Shield Wall
    [GetSpellInfo(871)] = {
        track = "buff",
        duration = 10,
        priority = 10,
        spellSchool = "physical",
        id = 871,
    },

    -- Mace Stun Effect
    [GetSpellInfo(5530)] = {
        track = "debuff",
        duration = 3,
        priority = 40,
        spellSchool = "physical",
        texture = select(3, GetSpellInfo(12284)),
        id = 5530,
    },
    -- Storm Herald Stun effect
    [GetSpellInfo(34510)] = {
        track = "debuff",
        duration = 4,
        priority = 40,
        spellSchool = "physical",
        id = 34510,
    },
    -- War Stomp
    [GetSpellInfo(20549)] = {
        track = "debuff",
        duration = 2,
        priority = 40,
        spellSchool = "physical",
        id = 20549,
    },
    -- Arcane Torrent
    [GetSpellInfo(28730)] = {
        track = "debuff",
        duration = 2,
        priority = 15,
        spellSchool = "magic",
        id = 28730,
    },
}