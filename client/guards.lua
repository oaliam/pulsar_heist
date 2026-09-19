_guards        = {}
_guardsSpawned = false
_allWave1Dead  = false

local _ICON_STATES = {
    suspicious = { symbol = "?",  r = 255, g = 215, b = 0   },
    alert      = { symbol = "!",  r = 255, g = 130, b = 0   },
    hostile    = { symbol = "!!", r = 220, g = 40,  b = 40  },
}

local function DrawAwarenessIcon(x, y, z, state)
    local ico = _ICON_STATES[state]
    if not ico then return end

    SetDrawOrigin(x, y, z + 1.32, 0)

    SetTextFont(4)
    SetTextScale(0.0, 0.38)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(ico.r, ico.g, ico.b, 255)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(ico.symbol)
    EndTextCommandDisplayText(0.0, 0.0)

    ClearDrawOrigin()
end

local function SpeakLine(ped, lines)
    if not lines or #lines == 0 then return end
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    local line = lines[math.random(#lines)]
    PlayAmbientSpeech1(ped, line, "SPEECH_PARAMS_FORCE_SHOUTED", 0)
end

local function SpawnGuardPed(guardCfg, index)
    LoadModel(Config.GuardModel)

    local ped = CreatePed(
        4, Config.GuardModel,
        guardCfg.coords.x, guardCfg.coords.y, guardCfg.coords.z - 1.0,
        guardCfg.heading, false, true
    )

    if guardCfg.weapon then
        GiveWeaponToPed(ped, guardCfg.weapon, 250, false, true)
    end

    SetPedArmour(ped, Config.GuardHealth)
    SetEntityHealth(ped, 200)

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5,  true)
    SetPedCombatRange(ped, 2)

    local r = guardCfg.wanderRadius or 12.0
    if guardCfg.scenario then
        TaskStartScenarioInPlace(ped, guardCfg.scenario, 0, true)
    else
        TaskWanderInArea(ped, guardCfg.coords.x, guardCfg.coords.y, guardCfg.coords.z, r, 1.0, 0.0)
    end

    _guards[index] = {
        ped          = ped,
        state        = "idle",
        awareness    = 0,
        wave         = guardCfg.wave,
        spawnCoords  = guardCfg.coords,
        wanderRadius = r,
        usbLooted    = false,
        usbZoneAdded = false,
    }
end

AddEventHandler("Heist:Client:SpawnGuardWave", function(wave)
    for i, guardCfg in ipairs(Config.Guards) do
        if guardCfg.wave == wave then
            if not _guards[i] or not DoesEntityExist(_guards[i].ped) then
                SpawnGuardPed(guardCfg, i)
            end
        end
    end
    _guardsSpawned = true

    if wave == 1 then
        plsr.Notification:Warn("Armed guards on site. Kill one and loot the USB.", 6000)
    elseif wave == 2 then
        plsr.Notification:Error("Backup inbound!", 5000)
    end
end)

RegisterNetEvent("Heist:Client:SpawnReinforcements", function()
    TriggerEvent("Heist:Client:SpawnGuardWave", 2)
end)

local function ApplyGuardState(index, newState, oldState)
    local g = _guards[index]
    if not g or not DoesEntityExist(g.ped) or IsEntityDead(g.ped) then return end

    local playerPed = PlayerPedId()
    local cfg       = Config.Guards[index]

    if newState == "idle" then
        if cfg and cfg.scenario then
            TaskStartScenarioInPlace(g.ped, cfg.scenario, 0, true)
        else
            TaskWanderInArea(g.ped, g.spawnCoords.x, g.spawnCoords.y, g.spawnCoords.z, g.wanderRadius, 1.0, 0.0)
        end

    elseif newState == "suspicious" then
        TaskTurnPedToFaceEntity(g.ped, playerPed, 2000)
        if oldState == "idle" then
            SpeakLine(g.ped, Config.GuardSpeech.suspicious)
        end

    elseif newState == "alert" then
        if cfg and cfg.weapon then
            TaskAimGunAtEntity(g.ped, playerPed, -1, false)
        else
            TaskTurnPedToFaceEntity(g.ped, playerPed, -1)
        end
        SpeakLine(g.ped, Config.GuardSpeech.alert)

    elseif newState == "hostile" then
        TaskCombatPed(g.ped, playerPed, 0, 16)
        SpeakLine(g.ped, Config.GuardSpeech.hostile)
    end

    g.state = newState
end

RegisterNetEvent("Heist:Client:GuardAwareness", function(index, value)
    local g = _guards[index]
    if not g then return end

    g.awareness = value
    if g.state == "hostile" then return end

    local newState = "idle"
    if     value >= Config.Awareness.hostile    then newState = "hostile"
    elseif value >= Config.Awareness.alert      then newState = "alert"
    elseif value >= Config.Awareness.suspicious then newState = "suspicious"
    end

    if newState ~= g.state then
        ApplyGuardState(index, newState, g.state)
    end
end)

local function AddUsbPedTarget(guardIndex, deadPed)
    if not DoesEntityExist(deadPed) then return end
    local g = _guards[guardIndex]
    if not g or g.usbZoneAdded then return end

    plsr.Targeting:AddPed(
        deadPed,
        "usb-drive",
        {{
            icon      = "usb-drive",
            text      = "Take USB Dongle",
            event     = "Heist:Client:LootUsb",
            minDist   = 2.5,
            data      = { guardIndex = guardIndex, ped = deadPed },
            isEnabled = function()
                local gg = _guards[guardIndex]
                return gg ~= nil and not gg.usbLooted and _heistState.active and not _heistState.usbCollected
            end,
        }},
        3.0
    )
    g.usbZoneAdded = true
end

AddEventHandler("Heist:Client:LootUsb", function(entityData, itemData)
    local g = _guards[itemData.guardIndex]
    if not g or g.usbLooted then return end

    g.usbLooted = true

    plsr.Notification:Success("USB dongle taken. Find the laptop.", 5000)

    plsr.Targeting:RemovePed(itemData.ped)

    TriggerServerEvent("Heist:Server:UsbPickedUp", itemData.guardIndex)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if not _guardsSpawned then goto continue end

        local wave1Total = 0
        local wave1Dead  = 0

        for i, g in ipairs(_guards) do
            if g.wave == 1 then
                wave1Total += 1
                if not DoesEntityExist(g.ped) or IsEntityDead(g.ped) then
                    wave1Dead += 1

                    if g.state ~= "dead" then
                        g.state = "dead"
                        TriggerServerEvent("Heist:Server:GuardKilled", i)

                        if not g.usbLooted and not g.usbZoneAdded and not _heistState.usbCollected then
                            if DoesEntityExist(g.ped) then
                                AddUsbPedTarget(i, g.ped)
                            end
                        end
                    end
                end
            end
        end

        if wave1Total > 0 and wave1Dead >= wave1Total and not _allWave1Dead then
            _allWave1Dead = true
            TriggerServerEvent("Heist:Server:Wave1Cleared")
        end

        ::continue::
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if not _guardsSpawned then Wait(500) goto continue end

        local playerPos = GetEntityCoords(PlayerPedId())

        for _, g in ipairs(_guards) do
            if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                if g.state == "suspicious" or g.state == "alert" or g.state == "hostile" then
                    local c = GetEntityCoords(g.ped)
                    if #(c - playerPos) < 40.0 then
                        DrawAwarenessIcon(c.x, c.y, c.z, g.state)
                    end
                end
            end
        end

        ::continue::
    end
end)

function CleanUpGuards()
    for i, g in ipairs(_guards) do
        if g.usbZoneAdded and not g.usbLooted and DoesEntityExist(g.ped) then
            plsr.Targeting:RemovePed(g.ped)
        end
        if DoesEntityExist(g.ped) then DeleteEntity(g.ped) end
    end
    _guards        = {}
    _guardsSpawned = false
    _allWave1Dead  = false
end

RegisterNetEvent("Heist:Client:CleanGuards", function()
    CleanUpGuards()
end)
