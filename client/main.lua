_heistState = {
    active       = false,
    stage        = 0,
    wave         = 1,
    bagsGrabbed  = 0,
    bagsTaken    = { [1] = false, [2] = false },
    usbCollected = false,
}

local _siteBlip       = nil
local _laptopBlip     = nil
local _bagBlips       = {}
local _refreshPending = false

function LoadModel(model)
    if HasModelLoaded(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
end

function ResetAwarenessTracker()
    SendNUIMessage({ type = "awareness", value = 0, state = "idle", visible = false })
end

local function SetSiteBlip(active)
    if active and not _siteBlip then
        local loc = Config.Objectives.caseTerminal.coords
        _siteBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(_siteBlip, Config.Blip.sprite)
        SetBlipColour(_siteBlip, Config.Blip.colour)
        SetBlipScale(_siteBlip,  Config.Blip.scale)
        SetBlipAsShortRange(_siteBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(_siteBlip)
        if Config.Blip.showRoute then
            SetBlipRoute(_siteBlip, true)
            SetBlipRouteColour(_siteBlip, Config.Blip.colour)
        end
    elseif not active and _siteBlip then
        RemoveBlip(_siteBlip)
        _siteBlip = nil
    end
end

function ShowLaptopBlip()
    if _laptopBlip then return end
    local loc = Config.Objectives.caseTerminal.coords
    _laptopBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(_laptopBlip, Config.LaptopBlip.sprite)
    SetBlipColour(_laptopBlip, Config.LaptopBlip.colour)
    SetBlipScale(_laptopBlip,  Config.LaptopBlip.scale)
    SetBlipAsShortRange(_laptopBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.LaptopBlip.label)
    EndTextCommandSetBlipName(_laptopBlip)
    SetBlipRoute(_laptopBlip, true)
    SetBlipRouteColour(_laptopBlip, Config.LaptopBlip.colour)
end

function HideLaptopBlip()
    if _laptopBlip then
        RemoveBlip(_laptopBlip)
        _laptopBlip = nil
    end
end

local function ShowBagBlips()
    if #_bagBlips > 0 then return end
    local bags = { Config.Objectives.moneyBag1, Config.Objectives.moneyBag2 }
    for i, bag in ipairs(bags) do
        local b = AddBlipForCoord(bag.coords.x, bag.coords.y, bag.coords.z)
        SetBlipSprite(b, 522)
        SetBlipColour(b, 2)
        SetBlipScale(b, 0.8)
        SetBlipAsShortRange(b, false)
        SetBlipRoute(b, true)
        SetBlipRouteColour(b, 2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(("Cash Bag %d"):format(i))
        EndTextCommandSetBlipName(b)
        _bagBlips[i] = b
    end
end

local function HideBagBlip(bagId)
    if _bagBlips[bagId] then
        RemoveBlip(_bagBlips[bagId])
        _bagBlips[bagId] = nil
    end
end

function HideAllBagBlips()
    for i = 1, 2 do HideBagBlip(i) end
end

local _fixerBlip = nil

function ShowFixerBlip()
    if _fixerBlip then return end
    local c = Config.Contact.coords
    _fixerBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(_fixerBlip, Config.FixerBlip.sprite)
    SetBlipColour(_fixerBlip, Config.FixerBlip.colour)
    SetBlipScale(_fixerBlip,  Config.FixerBlip.scale)
    SetBlipAsShortRange(_fixerBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.FixerBlip.label)
    EndTextCommandSetBlipName(_fixerBlip)
    SetBlipRoute(_fixerBlip, true)
    SetBlipRouteColour(_fixerBlip, Config.FixerBlip.colour)
end

function HideFixerBlip()
    if _fixerBlip then
        RemoveBlip(_fixerBlip)
        _fixerBlip = nil
    end
end

function ScheduleRefresh()
    if _refreshPending then return end
    _refreshPending = true
    CreateThread(function()
        Wait(200)
        plsr.Targeting.Zones:Refresh()
        _refreshPending = false
    end)
end

local function SpawnContactNpc()
    local c = Config.Contact
    plsr.PedInteraction:Add(
        "heist_contact", c.model,
        vector3(c.coords.x, c.coords.y, c.coords.z), c.coords.w,
        c.spawnRange,
        {
            {
                icon      = "comment-dots",
                text      = "Talk",
                event     = "Heist:Client:TalkToContact",
                minDist   = 3.0,
                data      = {},
                isEnabled = function() return not _heistState.active end,
            },
            {
                icon      = "hand-holding-dollar",
                text      = "Hand Over Bags",
                event     = "Heist:Client:Stage3:DeliverToFixer",
                minDist   = 5.0,
                data      = {},
                isEnabled = function() return _heistState.active and _heistState.stage == 3 end,
            },
        },
        "person-walking", c.scenario, true
    )

    CreateThread(function()
        Wait(2500)
        local contactPos = vector3(c.coords.x, c.coords.y, c.coords.z)
        for _, ped in ipairs(GetGamePool("CPed")) do
            if GetEntityModel(ped) == GetHashKey("cs_nervousron") then
                if #(GetEntityCoords(ped) - contactPos) < 6.0 then
                    SetEntityCoordsNoOffset(ped, c.coords.x, c.coords.y, c.coords.z, false, false, false)
                    Wait(100)
                    FreezeEntityPosition(ped, true)
                    break
                end
            end
        end
    end)
end

RegisterNetEvent("Heist:Client:State:Update", function(key, value, subKey)
    if subKey then
        _heistState[key]         = _heistState[key] or {}
        _heistState[key][subKey] = value
    else
        _heistState[key] = value
    end
    if key == "usbCollected" and value == true then
        ShowLaptopBlip()
        plsr.Notification:Success("USB secured. Laptop marked on your map.", 6000)
    end
    if key == "stage" and value == 2 then
        HideLaptopBlip()
        ShowBagBlips()
    end
    if key == "stage" and value == 3 then
        HideAllBagBlips()
        ShowFixerBlip()
    end
    if key == "bagsTaken" and type(value) == "table" then
        for id, taken in pairs(value) do
            if taken then HideBagBlip(tonumber(id)) end
        end
    end
    TriggerEvent("Heist:Client:OnStateChanged")
end)

RegisterNetEvent("Heist:Client:State:Set", function(state)
    _heistState = state
    if state.usbCollected then ShowLaptopBlip() else HideLaptopBlip() end
    if state.stage == 2 then
        ShowBagBlips()
        if state.bagsTaken then
            if state.bagsTaken[1] then HideBagBlip(1) end
            if state.bagsTaken[2] then HideBagBlip(2) end
        end
    elseif state.stage == 3 then
        HideAllBagBlips()
        ShowFixerBlip()
    else
        HideAllBagBlips()
        HideFixerBlip()
    end
    TriggerEvent("Heist:Client:OnStateChanged")
end)

AddEventHandler("Heist:Client:OnStateChanged", function()
    SetSiteBlip(_heistState.active)
    ScheduleRefresh()
end)

CreateThread(function()
    while true do
        Wait(500)
        if not (_heistState.active and _guardsSpawned) then goto continue end
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        for i, g in ipairs(_guards) do
            if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                if #(GetEntityCoords(g.ped) - playerPos) < Config.Awareness.seenRange then
                    if HasEntityClearLosToEntityInFront(g.ped, playerPed) then
                        TriggerServerEvent("Heist:Server:GuardSaw", i)
                    end
                end
            end
        end
        ::continue::
    end
end)

CreateThread(function()
    while true do
        if _heistState.active and _guardsSpawned then
            Wait(0)
            if IsPedShooting(PlayerPedId()) then
                TriggerServerEvent("Heist:Server:GuardHeardShot")
                Wait(800)
            end
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if _heistState.active and not _guardsSpawned then
            local anchor = Config.Objectives.caseTerminal.coords
            if #(GetEntityCoords(PlayerPedId()) - anchor) < Config.GuardSpawnRange then
                TriggerEvent("Heist:Client:SpawnGuardWave", 1)
            end
        end
    end
end)

CreateThread(function()
    local lastValue, lastState, lastVisible = -1, "", nil
    while true do
        Wait(250)
        local value, state, visible = 0, "idle", false
        if _heistState.active and _guardsSpawned then
            visible = true
            for _, g in ipairs(_guards) do
                if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) and g.awareness > value then
                    value, state = g.awareness, g.state
                end
            end
        end
        if value ~= lastValue or state ~= lastState or visible ~= lastVisible then
            lastValue, lastState, lastVisible = value, state, visible
            SendNUIMessage({ type = "awareness", value = value, state = state, visible = visible })
        end
    end
end)

CreateThread(function()
    local _failedAlready = false
    while true do
        Wait(250)
        if _heistState.active and not _failedAlready then
            if IsEntityDead(PlayerPedId()) or plsr.State.flags.isDead then
                _failedAlready = true
                plsr.Minigame:Cancel()
                plsr.Notification.Persistent:Remove("heist_hacking")
                plsr.Notification.Persistent:Remove("heist_grabbing")
                TriggerServerEvent("Heist:Server:Fail", "You died.")
            end
        elseif not _heistState.active then
            _failedAlready = false
        end
    end
end)

CreateThread(function()
    Wait(1000)
    SpawnContactNpc()
    RegisterMinigameCallbacks()
    TriggerServerEvent("Heist:Server:RequestState")
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end
    SetSiteBlip(false)
    HideLaptopBlip()
    HideAllBagBlips()
    HideFixerBlip()
    CleanUpGuards()
    DetachAllBags()
    plsr.Notification.Persistent:Remove("heist_hacking")
    plsr.Notification.Persistent:Remove("heist_grabbing")
    plsr.PedInteraction:Remove("heist_contact")
end)

RegisterCommand("heistcoords", function()
    local p = GetEntityCoords(PlayerPedId())
    local h = GetEntityHeading(PlayerPedId())
    print(("[heistcoords] vector3(%.3f, %.3f, %.3f)  heading %.1f"):format(p.x, p.y, p.z, h))
    plsr.Notification:Info("Coords printed to F8 console.", 4000)
end, false)
