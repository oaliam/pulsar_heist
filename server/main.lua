_missions  = {}
_cooldowns = {}

local _lastNoise = {}

local function GetPlayerPos(src)
    return GetEntityCoords(GetPlayerPed(src))
end

function GetCooldownLeft(src)
    local char = plsr.Fetch:CharacterSource(src)
    if not char then return 0 end
    return math.max(0, (_cooldowns[char:GetData("SID")] or 0) - os.time())
end

function StartCooldown(src)
    local char = plsr.Fetch:CharacterSource(src)
    if char then _cooldowns[char:GetData("SID")] = os.time() + Config.CooldownSeconds end
end

function ClearCooldown(src)
    local char = plsr.Fetch:CharacterSource(src)
    if char then _cooldowns[char:GetData("SID")] = nil end
end

local function BuildGuardTable()
    local t = {}
    for i = 1, #Config.Guards do
        t[i] = { awareness = 0, lastSeen = 0, dead = false }
    end
    return t
end

function DefaultState()
    return {
        active       = false,
        stage        = 0,
        wave         = 1,
        bagsGrabbed  = 0,
        bagsTaken    = { [1] = false, [2] = false },
        usbCollected = false,
        guards       = BuildGuardTable(),
        hackStart    = nil,
        busy         = false,
        lastPdAlert  = 0,
    }
end

function SyncState(src, key, value, subKey)
    TriggerClientEvent("Heist:Client:State:Update", src, key, value, subKey)
end

function SyncFullState(src)
    if not _missions[src] then return end
    local m = _missions[src]
    TriggerClientEvent("Heist:Client:State:Set", src, {
        active       = m.active,
        stage        = m.stage,
        wave         = m.wave,
        bagsGrabbed  = m.bagsGrabbed,
        bagsTaken    = m.bagsTaken,
        usbCollected = m.usbCollected,
    })
end

function AddAwareness(src, index, amount)
    local m = _missions[src]
    if not m or not m.guards[index] or m.guards[index].dead then return end
    local g = m.guards[index]
    g.awareness = math.min(100, g.awareness + amount)
    TriggerClientEvent("Heist:Client:GuardAwareness", src, index, g.awareness)
end

CreateThread(function()
    while true do
        Wait(1000)
        for src, m in pairs(_missions) do
            if m.active then
                for i, g in ipairs(m.guards) do
                    if not g.dead and g.awareness > 0 and g.awareness < Config.Awareness.hostile then
                        g.awareness = math.max(0, g.awareness - Config.Awareness.decay)
                        TriggerClientEvent("Heist:Client:GuardAwareness", src, i, g.awareness)
                    end
                end
            end
        end
    end
end)

function TriggerPDAlert(src)
    local m = _missions[src]
    if m then
        if os.time() - m.lastPdAlert < 60 then return end
        m.lastPdAlert = os.time()
    end

    local coords = Config.Objectives.caseTerminal.coords
    local alert  = Config.PdAlert
    plsr.Callbacks:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
        plsr.EmergencyAlerts:Create(
            alert.code, alert.title, "police_alerts", location,
            alert.description, false, alert.blip, false, false, false
        )
    end)
end

RegisterNetEvent("Heist:Server:GuardSaw", function(index)
    local src = source
    local m   = _missions[src]
    if not m or not m.active then return end
    if type(index) ~= "number" then return end

    local g = m.guards[index]
    if not g or g.dead then return end

    local now = GetGameTimer()
    if (now - g.lastSeen) < Config.Awareness.reportDelay then return end
    g.lastSeen = now

    if #(GetPlayerPos(src) - Config.Guards[index].coords) > (Config.Awareness.seenRange + 8.0) then return end
    AddAwareness(src, index, Config.Awareness.seenGain)
end)

RegisterNetEvent("Heist:Server:GuardHeardShot", function()
    local src = source
    local m   = _missions[src]
    if not m or not m.active then return end

    local now = GetGameTimer()
    if (now - (_lastNoise[src] or 0)) < 900 then return end
    _lastNoise[src] = now

    local playerPos = GetPlayerPos(src)
    for i, guardCfg in ipairs(Config.Guards) do
        if #(playerPos - guardCfg.coords) <= Config.Awareness.noiseRange then
            AddAwareness(src, i, Config.Awareness.gunshotNoise)
        end
    end

    if m.stage >= 2 then TriggerPDAlert(src) end
end)

RegisterNetEvent("Heist:Server:GuardKilled", function(index)
    local src = source
    local m   = _missions[src]
    if not m or not m.active or not m.guards[index] then return end
    m.guards[index].dead = true
    plsr.Logger:Info("Heist", ("Guard %d killed by player %d"):format(index, src), { console = true })
end)

RegisterNetEvent("Heist:Server:UsbPickedUp", function(guardIndex)
    local src = source
    local m   = _missions[src]
    if not m or not m.active then return end
    if m.usbCollected then return end

    if type(guardIndex) ~= "number" or not m.guards[guardIndex] or not m.guards[guardIndex].dead then
        plsr.Logger:Info("Heist", ("Player %d USB claim rejected — guard %s not dead"):format(src, tostring(guardIndex)), { console = true })
        return
    end

    m.usbCollected = true
    SyncState(src, "usbCollected", true)
    plsr.Logger:Info("Heist", ("Player %d picked up USB from guard %d"):format(src, guardIndex), { console = true })
end)

RegisterNetEvent("Heist:Server:Wave1Cleared", function()
    local src = source
    local m   = _missions[src]
    if not m or not m.active or m.wave >= 2 then return end

    for i, cfg in ipairs(Config.Guards) do
        if cfg.wave == 1 and not m.guards[i].dead then return end
    end

    m.wave = 2
    SyncState(src, "wave", 2)
    TriggerClientEvent("Heist:Client:SpawnReinforcements", src)
    TriggerPDAlert(src)
    plsr.Execute:Client(src, "Notification", "Warn", "Backup inbound — law enforcement alerted.", 6000)
end)

RegisterNetEvent("Heist:Server:RequestState", function()
    local src = source
    if not _missions[src] then _missions[src] = DefaultState() end
    SyncFullState(src)
end)

CreateThread(function()
    while not plsr do Wait(100) end
    plsr.Middleware:Add("Characters:Spawning", function(src)
        if not _missions[src] then _missions[src] = DefaultState() end
        SyncFullState(src)
    end)
end)

AddEventHandler("playerDropped", function()
    local src       = source
    _missions[src]  = nil
    _lastNoise[src] = nil
end)

RegisterCommand("resetheist", function(src, args)
    local target = tonumber(args[1]) or src
    _missions[target] = DefaultState()
    ClearCooldown(target)
    SyncFullState(target)
    TriggerClientEvent("Heist:Client:CleanGuards", target)
    print(("[pulsar_heist] reset for player %d"):format(target))
    if src ~= 0 then
        plsr.Execute:Client(src, "Notification", "Info", "Heist reset.", 4000)
    end
end, true)
