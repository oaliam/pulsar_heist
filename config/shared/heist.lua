Config = {}

Config.Contact = {
    model      = `cs_nervousron`,
    coords     = vector4(721.606, -930.252, 24.354, 92.3),
    scenario   = "WORLD_HUMAN_LEANING_AGAINST_WALL",
    spawnRange = 80.0,
}

Config.CooldownSeconds      = 30 * 60
Config.DefaultInteractRange = 3.0
Config.PropSpawnRange       = 150.0

Config.Objectives = {
    caseTerminal = {
        coords      = vector3(-95.614, -1008.254, 27.275),
        heading     = 248.7,
        icon        = "laptop",
        zoneLength  = 1.2,
        zoneWidth   = 0.8,
        zoneOptions = { heading = 248.7, minZ = 26.6, maxZ = 29.5 },
    },
    moneyBag1 = {
        coords      = vector3(-117.709, -1038.820, 27.274),
        heading     = 238.4,
        icon        = "sack-dollar",
        zoneLength  = 1.0,
        zoneWidth   = 1.0,
        zoneOptions = { heading = 0.0, minZ = 26.6, maxZ = 29.5 },
    },
    moneyBag2 = {
        coords      = vector3(-95.334, -1038.002, 27.273),
        heading     = 0.0,
        icon        = "sack-dollar",
        zoneLength  = 1.0,
        zoneWidth   = 1.0,
        zoneOptions = { heading = 0.0, minZ = 26.6, maxZ = 29.5 },
    },
}

Config.Props = {
    laptop = {
        model   = `prop_laptop_02_closed`,
        coords  = vector3(-95.614, -1008.254, 27.275),
        heading = 248.7,
    },
    moneyBag1 = {
        model   = `prop_money_bag_01`,
        coords  = vector3(-117.709, -1038.820, 27.274),
        heading = 238.4,
    },
    moneyBag2 = {
        model   = `prop_money_bag_01`,
        coords  = vector3(-95.334, -1038.002, 27.273),
        heading = 0.0,
    },
}
Config.TerminalProp = Config.Props.laptop

Config.BagBone       = 24818
Config.BagAttachOffset = vector3(0.0,  0.28, 0.12)
Config.BagAttachRot    = vector3(5.0, 0.0, 0.0)

Config.LaptopBlip = {
    sprite = 521,
    colour = 5,
    scale  = 0.8,
    label  = "Hack Laptop",
}

Config.FixerBlip = {
    sprite = 280,
    colour = 2,
    scale  = 0.8,
    label  = "Deliver to Fixer",
}

Config.GuardHealth = 150

Config.Guards = {
    { coords = vector3(-111.558, -1047.220, 27.273), heading =  60.0, weapon = `WEAPON_CARBINERIFLE`, wave = 1, wanderRadius = 18.0, scenario = "WORLD_HUMAN_CONST_DRILL"        },
    { coords = vector3(-120.002, -1034.440, 27.273), heading = 180.0, weapon = `WEAPON_PUMPSHOTGUN`,  wave = 1, wanderRadius = 16.0, scenario = "WORLD_HUMAN_SMOKING"              },
    { coords = vector3(-103.880, -1028.114, 27.275), heading = 220.0, weapon = `WEAPON_CARBINERIFLE`, wave = 1, wanderRadius = 15.0, scenario = "WORLD_HUMAN_CLIPBOARD"            },
    { coords = vector3(-93.558,  -1040.334, 27.273), heading = 270.0, weapon = `WEAPON_PUMPSHOTGUN`,  wave = 1, wanderRadius = 14.0, scenario = "WORLD_HUMAN_LEANING_AGAINST_WALL" },
    { coords = vector3(-103.334, -1054.002, 26.920), heading = 340.0, weapon = `WEAPON_CARBINERIFLE`, wave = 1, wanderRadius = 14.0, scenario = "WORLD_HUMAN_GUARD_STAND"          },
    { coords = vector3(-85.002,  -1032.558, 27.273), heading = 200.0, weapon = `WEAPON_PUMPSHOTGUN`,  wave = 1, wanderRadius = 12.0, scenario = "WORLD_HUMAN_SMOKING"              },
    { coords = vector3(-128.440, -1044.002, 27.273), heading =  90.0, weapon = `WEAPON_CARBINERIFLE`, wave = 1, wanderRadius = 16.0, scenario = "WORLD_HUMAN_CLIPBOARD"            },
    { coords = vector3(-98.002,  -1018.334, 27.275), heading = 160.0, weapon = `WEAPON_PUMPSHOTGUN`,  wave = 1, wanderRadius = 13.0, scenario = "WORLD_HUMAN_CONST_DRILL"          },
    { coords = vector3(-88.440,  -1050.558, 26.920), heading = 270.0, weapon = `WEAPON_CARBINERIFLE`, wave = 2, wanderRadius = 22.0 },
    { coords = vector3(-124.334, -1052.002, 26.920), heading =  90.0, weapon = `WEAPON_CARBINERIFLE`, wave = 2, wanderRadius = 22.0 },
    { coords = vector3(-106.002, -1028.558, 27.273), heading = 180.0, weapon = `WEAPON_PUMPSHOTGUN`,  wave = 2, wanderRadius = 18.0 },
    { coords = vector3(-75.558,  -1042.334, 27.273), heading = 250.0, weapon = `WEAPON_CARBINERIFLE`, wave = 2, wanderRadius = 20.0 },
}

Config.GuardModel      = `s_m_y_construct_01`
Config.GuardSpawnRange = 180.0

Config.Awareness = {
    seenRange    = 40.0,
    seenGain     = 6,
    decay        = 2,
    gunshotNoise = 55,
    noiseRange   = 65.0,
    suspicious   = 30,
    alert        = 60,
    hostile      = 85,
    reportDelay  = 400,
}

Config.GuardSpeech = {
    suspicious = { "GENERIC_INSULT_HIGH", "CHAT_STATE", "GENERIC_SHOCKED_MED", "GENERIC_SHOCKED_HIGH", "GENERIC_BYE" },
    alert      = { "GENERIC_FRIGHTENED_HIGH", "GENERIC_SHOCKED_HIGH", "HOLD_ON", "GENERIC_CURSE_MED", "GENERIC_HAILING_HIGH" },
    hostile    = { "GENERIC_CURSE_HIGH", "AGGRESSIVE_1", "GENERIC_HAILING_HIGH", "GENERIC_FRIGHTENED_HIGH", "GENERIC_INSULT_HIGH", "GENERIC_CURSE_MED" },
}

Config.Minigames = {
    caseTerminal = {
        countdown = 5,
        changeMs  = 3000,
        limitMs   = 30000,
        strikes   = 4,
        keys      = 10,
    },
    moneyBag = {
        countdown = 3,
        previewMs = 2500,
        limitMs   = 25000,
        columns   = 4,
        rows      = 4,
        numActive = 6,
        strikes   = 3,
    },
}

Config.Rewards = {
    cashPerBag    = 18000,
    bonusBothBags = 6000,
    heistBonus    = 8000,
}

Config.PdAlert = {
    code        = "10-90",
    title       = "Break-in — Construction Site, Innocence Blvd",
    description = "Shots fired at the construction site near Premium Deluxe Motorsport. Units respond.",
    blip        = { sprite = 161, color = 1 },
}

Config.Blip = {
    sprite    = 316,
    colour    = 1,
    scale     = 0.9,
    label     = "Construction Site",
    showRoute = true,
}
