local _laptop    = nil
local _bagProps  = {}
local _bagOnBack = {}

local function RegisterLaptopTarget()
    if not _laptop or not DoesEntityExist(_laptop) then return end
    plsr.Targeting:AddEntity(_laptop, "laptop", {{
        icon      = "laptop",
        text      = "Hack Laptop",
        event     = "Heist:Client:Stage1:HackTerminal",
        minDist   = Config.DefaultInteractRange,
        data      = {},
        isEnabled = function() return _heistState.active and _heistState.stage == 1 end,
    }}, Config.DefaultInteractRange, false)
end

local function SpawnLaptop()
    if _laptop and DoesEntityExist(_laptop) then return end
    local cfg = Config.Props.laptop
    LoadModel(cfg.model)
    _laptop = CreateObject(cfg.model, cfg.coords.x, cfg.coords.y, cfg.coords.z + 0.5, false, false, false)
    SetEntityHeading(_laptop, cfg.heading)
    SetEntityCollision(_laptop, true, true)
    SetModelAsNoLongerNeeded(cfg.model)
    CreateThread(function()
        Wait(500)
        if _laptop and DoesEntityExist(_laptop) then
            PlaceObjectOnGroundProperly(_laptop)
            Wait(100)
            FreezeEntityPosition(_laptop, true)
            RegisterLaptopTarget()
        end
    end)
end

local function DeleteLaptop()
    if _laptop and DoesEntityExist(_laptop) then
        plsr.Targeting:RemoveEntity(_laptop)
        DeleteEntity(_laptop)
    end
    _laptop = nil
end

local function RegisterBagTarget(bagId)
    local prop = _bagProps[bagId]
    if not prop or not DoesEntityExist(prop) then return end
    plsr.Targeting:AddEntity(prop, "sack-dollar", {{
        icon      = "sack-dollar",
        text      = "Pick Up Bag",
        event     = "Heist:Client:Stage2:GrabBag",
        minDist   = Config.DefaultInteractRange,
        data      = { bagId = bagId },
        isEnabled = function()
            return _heistState.active and _heistState.stage == 2
                and not (_heistState.bagsTaken and _heistState.bagsTaken[bagId])
        end,
    }}, Config.DefaultInteractRange, false)
end

local function SpawnBagProp(bagId)
    if _bagProps[bagId] and DoesEntityExist(_bagProps[bagId]) then return end
    local cfg = Config.Props["moneyBag" .. bagId]
    LoadModel(cfg.model)
    local prop = CreateObject(cfg.model, cfg.coords.x, cfg.coords.y, cfg.coords.z + 0.5, false, false, false)
    SetEntityHeading(prop, cfg.heading)
    SetEntityCollision(prop, true, true)
    SetModelAsNoLongerNeeded(cfg.model)
    _bagProps[bagId] = prop
    CreateThread(function()
        Wait(500)
        if DoesEntityExist(prop) then
            PlaceObjectOnGroundProperly(prop)
            Wait(100)
            FreezeEntityPosition(prop, true)
            RegisterBagTarget(bagId)
        end
    end)
end

function AttachBagToBack(bagId)
    if _bagProps[bagId] and DoesEntityExist(_bagProps[bagId]) then
        plsr.Targeting:RemoveEntity(_bagProps[bagId])
        DeleteEntity(_bagProps[bagId])
        _bagProps[bagId] = nil
    end

    local cfg = Config.Props["moneyBag" .. bagId]
    LoadModel(cfg.model)
    local carried = CreateObject(cfg.model, 0.0, 0.0, 0.0, true, true, false)
    SetModelAsNoLongerNeeded(cfg.model)

    local playerPed = PlayerPedId()
    local xOffset = (bagId == 2) and 0.12 or -0.12
    AttachEntityToEntity(
        carried, playerPed,
        Config.BagBone,
        Config.BagAttachOffset.x + xOffset,
        Config.BagAttachOffset.y,
        Config.BagAttachOffset.z,
        Config.BagAttachRot.x,
        Config.BagAttachRot.y,
        Config.BagAttachRot.z,
        false, false, false, false, 2, true
    )
    _bagOnBack[bagId] = carried
end

function DetachAllBags()
    for i = 1, 2 do
        if _bagOnBack[i] and DoesEntityExist(_bagOnBack[i]) then
            DetachEntity(_bagOnBack[i], true, false)
            DeleteEntity(_bagOnBack[i])
            _bagOnBack[i] = nil
        end
        if _bagProps[i] and DoesEntityExist(_bagProps[i]) then
            plsr.Targeting:RemoveEntity(_bagProps[i])
            DeleteEntity(_bagProps[i])
            _bagProps[i] = nil
        end
    end
end

local function SpawnProps()
    SpawnLaptop()
    for bagId = 1, 2 do
        local taken = _heistState.bagsTaken and _heistState.bagsTaken[bagId]
        if not taken then SpawnBagProp(bagId) end
    end
end

CreateThread(function()
    local range = Config.PropSpawnRange or 150.0
    while true do
        Wait(2000)
        if _heistState and _heistState.active then
            local dist = #(GetEntityCoords(PlayerPedId()) - Config.Props.laptop.coords)
            if dist < range then SpawnProps() end
        end
    end
end)

local function DeleteAllProps()
    DeleteLaptop()
    DetachAllBags()
end

RegisterNetEvent("Heist:Client:State:Set", function(s)
    if not s.active then DeleteAllProps() end
end)

RegisterNetEvent("Heist:Client:State:Update", function(k, v)
    if k == "active" and not v then DeleteAllProps() end
end)

RegisterNetEvent("Heist:Client:Complete", function() DeleteAllProps() end)
RegisterNetEvent("Heist:Client:Failed",   function() DeleteAllProps() end)

AddEventHandler("onResourceStop", function(n)
    if n == GetCurrentResourceName() then DeleteAllProps() end
end)
