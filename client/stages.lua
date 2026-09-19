local hackAction = {
    controlDisables = {
        disableMovement    = true,
        disableCarMovement = true,
        disableMouse       = false,
        disableCombat      = true,
    },
    animation = {
        animDict = "amb@prop_human_atm@male@idle_a",
        anim     = "idle_b",
        flags    = 49,
    },
}

local grabAction = {
    controlDisables = {
        disableMovement    = true,
        disableCarMovement = true,
        disableMouse       = false,
        disableCombat      = true,
    },
    animation = {
        animDict = "random@shop_robbery",
        anim     = "robbery_action_b",
        flags    = 49,
    },
}

function RegisterMinigameCallbacks()

    plsr.Callbacks:RegisterClientCallback("Heist:Minigame:HackTerminal", function(data, cb)
        local cfg = Config.Minigames.caseTerminal
        plsr.Notification.Persistent:Info("heist_hacking", "Cracking the laptop...")
        plsr.Minigame.Play:Scrambler(
            cfg.countdown, cfg.changeMs, cfg.limitMs, cfg.strikes, cfg.keys,
            { onSuccess = function() cb(true) end, onFail = function() cb(false) end },
            hackAction
        )
    end)

    plsr.Callbacks:RegisterClientCallback("Heist:Minigame:GrabBag", function(data, cb)
        local cfg = Config.Minigames.moneyBag
        plsr.Notification.Persistent:Info("heist_grabbing", "Breaking the lock...")
        plsr.Minigame.Play:Memory(
            cfg.countdown, cfg.previewMs, cfg.limitMs,
            cfg.columns, cfg.rows, cfg.numActive, cfg.strikes,
            { onSuccess = function() cb(true, data) end, onFail = function() cb(false, data) end },
            grabAction
        )
    end)

end

AddEventHandler("Heist:Client:Stage1:HackTerminal", function(entityData, itemData)
    plsr.Callbacks:ServerCallback("Heist:Server:Stage1:HackTerminal", {}, function(allowed)
        if not allowed then
            plsr.Notification:Error("Can't do that right now.", 4000)
        end
    end)
end)

RegisterNetEvent("Heist:Client:Stage1:Result", function(success, reason)
    plsr.Notification.Persistent:Remove("heist_hacking")
    if IsEntityDead(PlayerPedId()) then return end
    if success then
        plsr.Notification:Success("Laptop cracked. Cops notified — grab both bags and get back to the fixer.", 8000)
    elseif reason == "usb_missing" then
        plsr.Notification:Error("You need the USB dongle from a guard.", 6000)
    else
        plsr.Notification:Error("Hack failed — try again.", 5000)
    end
end)

AddEventHandler("Heist:Client:Stage2:GrabBag", function(entityData, itemData)
    plsr.Callbacks:ServerCallback("Heist:Server:Stage2:GrabBag", { bagId = itemData.bagId }, function(allowed)
        if not allowed then plsr.Notification:Error("Can't grab that right now.", 4000) end
    end)
end)

RegisterNetEvent("Heist:Client:Stage2:BagResult", function(bagId, success)
    plsr.Notification.Persistent:Remove("heist_grabbing")
    if IsEntityDead(PlayerPedId()) then return end
    if success then
        AttachBagToBack(bagId)
        plsr.Notification:Success(("Bag %d on your back."):format(bagId), 5000)
    else
        plsr.Notification:Error("Couldn't crack it — try again.", 5000)
    end
end)

AddEventHandler("Heist:Client:Stage3:DeliverToFixer", function(entityData, itemData)
    plsr.Callbacks:ServerCallback("Heist:Server:Stage3:DeliverToFixer", {}, function(allowed)
        if not allowed then
            plsr.Notification:Error("Can't do that right now.", 4000)
        end
    end)
end)

RegisterNetEvent("Heist:Client:Complete", function(payout)
    plsr.Notification.Persistent:Remove("heist_hacking")
    plsr.Notification.Persistent:Remove("heist_grabbing")
    local f = tostring(payout):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    plsr.Notification:Success(("Paid out. +$%s"):format(f), 8000)
    CleanUpGuards()
    HideLaptopBlip()
    HideAllBagBlips()
    HideFixerBlip()
    DetachAllBags()
    ResetAwarenessTracker()
end)

RegisterNetEvent("Heist:Client:Failed", function(reason)
    plsr.Notification.Persistent:Remove("heist_hacking")
    plsr.Notification.Persistent:Remove("heist_grabbing")
    plsr.Notification:Error(("Heist failed: %s"):format(reason or "unknown"), 7000)
    CleanUpGuards()
    HideLaptopBlip()
    HideAllBagBlips()
    HideFixerBlip()
    DetachAllBags()
    ResetAwarenessTracker()
end)

AddEventHandler("Heist:Client:TalkToContact", function(entityData, itemData)
    plsr.Callbacks:ServerCallback("Heist:Server:AcceptJob", {}, function(accepted, reason)
        if accepted then
            plsr.Notification:Info(
                "Construction site, Innocence Blvd near PDM. "..
                "Kill a guard, loot the USB, hack the laptop. "..
                "Grab both cash bags — they go on your back. "..
                "Bring them back here to collect.",
                14000
            )
        else
            plsr.Notification:Error(reason or "Not available right now.", 6000)
        end
    end)
end)
