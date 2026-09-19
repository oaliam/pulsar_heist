local function ValidateStage(src, stage)
    local m = _missions[src]
    return m and m.active and (not stage or m.stage == stage)
end

local function ValidateProximity(src, coords, maxDist)
    return #(GetEntityCoords(GetPlayerPed(src)) - coords) <= (maxDist or Config.DefaultInteractRange + 2.0)
end

plsr.Callbacks:RegisterServerCallback("Heist:Server:AcceptJob", function(src, data, cb)
    local char = plsr.Fetch:CharacterSource(src)
    if not char then cb(false, "Not logged in.") return end

    local left = GetCooldownLeft(src)
    if left > 0 then
        local mins = math.ceil(left / 60)
        cb(false, ("On cooldown. ~%d min%s remaining."):format(mins, mins ~= 1 and "s" or ""))
        return
    end

    if _missions[src] and _missions[src].active then
        cb(false, "You already have a job running.")
        return
    end

    local contactPos = vector3(Config.Contact.coords.x, Config.Contact.coords.y, Config.Contact.coords.z)
    if not ValidateProximity(src, contactPos, 8.0) then cb(false, "Too far away.") return end

    local m = DefaultState()
    m.active = true
    m.stage  = 1
    _missions[src] = m
    SyncFullState(src)

    plsr.Logger:Info("Heist", ("%s %s (%s) started the heist."):format(
        char:GetData("First"), char:GetData("Last"), char:GetData("SID")
    ), { console = true, file = true })

    cb(true)
end)

plsr.Callbacks:RegisterServerCallback("Heist:Server:Stage1:HackTerminal", function(src, data, cb)
    if not ValidateStage(src, 1) then cb(false) return end

    local m = _missions[src]

    if not m.usbCollected then
        TriggerClientEvent("Heist:Client:Stage1:Result", src, false, "usb_missing")
        cb(false)
        return
    end

    if not ValidateProximity(src, Config.Objectives.caseTerminal.coords, 5.0) then cb(false) return end

    if m.busy then cb(false) return end
    m.busy      = true
    m.hackStart = GetGameTimer()

    plsr.Callbacks:ClientCallback(src, "Heist:Minigame:HackTerminal", {}, function(success)
        m.busy = false

        local elapsed = (GetGameTimer() - (m.hackStart or 0)) / 1000
        if elapsed < (Config.Minigames.caseTerminal.countdown - 0.5) then
            TriggerClientEvent("Heist:Client:Stage1:Result", src, false, "anticheat")
            return
        end
        m.hackStart = nil

        if success then
            m.stage = 2
            SyncState(src, "stage", 2)
            TriggerClientEvent("Heist:Client:Stage1:Result", src, true)
            TriggerPDAlert(src)
        else
            TriggerClientEvent("Heist:Client:Stage1:Result", src, false)
        end
    end)

    cb(true)
end)

plsr.Callbacks:RegisterServerCallback("Heist:Server:Stage2:GrabBag", function(src, data, cb)
    if not ValidateStage(src, 2) then cb(false) return end

    local bagId = data.bagId
    if bagId ~= 1 and bagId ~= 2 then cb(false) return end

    local m = _missions[src]
    if m.bagsTaken[bagId] then cb(false) return end

    local bagCoords = bagId == 1 and Config.Objectives.moneyBag1.coords or Config.Objectives.moneyBag2.coords
    if not ValidateProximity(src, bagCoords) then cb(false) return end

    if m.busy then cb(false) return end
    m.busy      = true
    m.hackStart = GetGameTimer()

    plsr.Callbacks:ClientCallback(src, "Heist:Minigame:GrabBag", { bagId = bagId }, function(success, cbData)
        m.busy = false

        local elapsed = (GetGameTimer() - (m.hackStart or 0)) / 1000
        if elapsed < (Config.Minigames.moneyBag.countdown - 0.5) then
            TriggerClientEvent("Heist:Client:Stage2:BagResult", src, bagId, false)
            return
        end
        m.hackStart = nil

        if success then
            m.bagsTaken[bagId]  = true
            m.bagsGrabbed      += 1
            SyncState(src, "bagsTaken",   m.bagsTaken)
            SyncState(src, "bagsGrabbed", m.bagsGrabbed)
            TriggerClientEvent("Heist:Client:Stage2:BagResult", src, bagId, true)

            if m.bagsGrabbed >= 2 then
                m.stage = 3
                SyncState(src, "stage", 3)
                plsr.Execute:Client(src, "Notification", "Info", "Both bags secured. Bring them back to the fixer.", 6000)
            else
                plsr.Execute:Client(src, "Notification", "Info", "One bag down. Grab the second.", 6000)
            end
        else
            TriggerClientEvent("Heist:Client:Stage2:BagResult", src, bagId, false)
        end
    end)

    cb(true)
end)

plsr.Callbacks:RegisterServerCallback("Heist:Server:Stage3:DeliverToFixer", function(src, data, cb)
    if not ValidateStage(src, 3) then cb(false) return end

    local contactPos = vector3(Config.Contact.coords.x, Config.Contact.coords.y, Config.Contact.coords.z)
    if not ValidateProximity(src, contactPos, 8.0) then
        cb(false)
        return
    end

    local m      = _missions[src]
    local char   = plsr.Fetch:CharacterSource(src)
    local payout = Config.Rewards.heistBonus + (m.bagsGrabbed * Config.Rewards.cashPerBag)
    if m.bagsGrabbed >= 2 then payout += Config.Rewards.bonusBothBags end

    if char then
        plsr.Wallet:Modify(src, payout)
        plsr.Logger:Info("Heist", ("%s %s (%s) completed. Bags: %d | Payout: $%d"):format(
            char:GetData("First"), char:GetData("Last"), char:GetData("SID"),
            m.bagsGrabbed, payout
        ), {
            console  = true,
            file     = true,
            database = true,
            discord  = { embed = true, type = "info", webhook = GetConvar("discord_log_webhook", "") },
        })
    end

    StartCooldown(src)
    _missions[src]      = DefaultState()
    SyncFullState(src)

    TriggerClientEvent("Heist:Client:Complete",    src, payout)
    TriggerClientEvent("Heist:Client:CleanGuards", src)

    cb(true)
end)

RegisterNetEvent("Heist:Server:Fail", function(reason)
    local src = source
    local m   = _missions[src]
    if not m or not m.active then return end
    _missions[src] = DefaultState()
    SyncFullState(src)
    TriggerClientEvent("Heist:Client:Failed",      src, reason)
    TriggerClientEvent("Heist:Client:CleanGuards", src)
end)
