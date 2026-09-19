# pulsar_heist

A heist job for the Pulsar Framework.

**The story in one line:** take a job from the fixer, sneak into a construction site, take a USB from a guard, hack a laptop, grab two cash bags, bring them back to the fixer, get paid.

**The main feature:** guards notice you. The more they notice, the angrier they get.

---

## Quick start

1. Put the `pulsar_heist` folder in `resources/[pulsar]/`.
2. Add this to `server.cfg`, **below** the resources listed under "Requirements":
   ```
   ensure pulsar_heist
   ```
3. Restart the server (or type `restart pulsar_heist` in the console).
4. Go to the fixer, third-eye him, choose **Talk**.

```
Fixer: /tp 721.606 -930.252 24.354
```

---

## Requirements

Start these **before** `pulsar_heist`:

| Resource | What it does |
|---|---|
| `pulsar_core` | The framework |
| `pulsar_games` | The two minigames |
| `pulsar_targeting` | The third-eye menu |
| `pulsar_pwnzor` | Anti-cheat check |
| Anything with `plsr.EmergencyAlerts` and `plsr.Wallet` | Police alerts and paying the player |

> **Third-eye** = hold the target key, look at a person or object, pick an option from the menu.

---

## The job (5 steps)

| Step | What you do | Where |
|---|---|---|
| 1 | Talk to the fixer | `/tp 721.606 -930.252 24.354` |
| 2 | Kill a guard, take the USB from the body | `/tp -106.546 -1043.394 27.273` |
| 3 | Hack the laptop | `/tp -95.614 -1008.254 27.275` |
| 4 | Grab both cash bags | Bag 1: `/tp -117.709 -1038.820 27.274`<br>Bag 2: `/tp -95.334 -1038.002 27.273` |
| 5 | Give the bags to the fixer | Back at the fixer |

### Step 1 - Talk to the fixer
Third-eye him → **Talk**. A red blip on your map shows the way to the site.
You can't start if you already have a job or you're on cooldown.

### Step 2 - Get the USB
- Guards appear when you get within 180 m of the laptop.
- Kill any of the 8 starting guards.
- Stand next to the body (2.5 m), third-eye it → **Take USB Dongle**.
- A yellow laptop blip appears on your map.

### Step 3 - Hack the laptop
- Third-eye the laptop on the ground → **Hack Laptop**.
- You need the USB first, otherwise you are told to go get one.
- Minigame: **Scrambler** (match the keys). Fail = try again.

| Setting | Value |
|---|---|
| Keys | 10 |
| Strikes allowed | 4 |
| Time | 30 seconds |
| Keys change every | 3 seconds |

- Success: police get a 10-90 alert, and two green bag blips appear.

### Step 4 - Grab both bags
- Third-eye each bag on the ground → **Pick Up Bag**.
- Minigame: **Memory** (remember the tiles that flashed). Fail = try again.

| Setting | Value |
|---|---|
| Grid | 4 x 4 |
| Tiles to remember | 6 |
| Strikes allowed | 3 |
| Preview time | 2.5 seconds |
| Time | 25 seconds |

- Each bag appears on your back when you win. Its blip disappears.
- When you have both, a green fixer blip appears.

### Step 5 - Deliver
Third-eye the fixer → **Hand Over Bags**. You get paid and the job resets.

### If you die
The job fails and everything is cleaned up. You can start again straight away (a fail does **not** start the cooldown).

---

## Guards and awareness

Every guard has a number from **0 to 100** showing how much they have noticed you. The server keeps this number, so players can't cheat it.

### What makes it go up

| You do this | Awareness goes |
|---|---|
| Stay in a guard's view (within 40 m, facing you) | **+6** each sighting (about twice a second) |
| Fire a gun (guards within 65 m) | **+55** per shot |

**In plain words:** one shot makes guards suspicious, two shots make them hostile.

### What makes it go down
Out of sight = **-2 per second**. It stops working once a guard is hostile.

### What guards do

| Awareness | State | Icon | Behaviour |
|---|---|---|---|
| 0 - 29 | Idle | none | Carries on working |
| 30 - 59 | Suspicious | yellow **?** | Turns to look at you, shouts |
| 60 - 84 | Alert | orange **!** | Aims at you, shouts |
| 85 - 100 | Hostile | red **!!** | Attacks you |

**Hostile guards stay hostile.**

### What you see on screen
- The icon above a guard's head (within 40 m).
- A bar in the bottom-left showing the highest awareness of any guard.
- Guards shout lines when their state changes.

### Waves

| Wave | Guards | When they appear |
|---|---|---|
| 1 | 8 workers (drilling, smoking, clipboard, standing watch) | When you get near the site |
| 2 | 4 backup guards | When **all** wave-1 guards are dead |

When wave 2 arrives, the police are alerted too.

<details>
<summary>All 12 guard positions</summary>

**Wave 1**

| # | Position | Weapon | Doing |
|---|---|---|---|
| 1 | `-111.558, -1047.220, 27.273` | Carbine | Drilling |
| 2 | `-120.002, -1034.440, 27.273` | Shotgun | Smoking |
| 3 | `-103.880, -1028.114, 27.275` | Carbine | Clipboard |
| 4 | `-93.558, -1040.334, 27.273` | Shotgun | Leaning on wall |
| 5 | `-103.334, -1054.002, 26.920` | Carbine | Standing guard |
| 6 | `-85.002, -1032.558, 27.273` | Shotgun | Smoking |
| 7 | `-128.440, -1044.002, 27.273` | Carbine | Clipboard |
| 8 | `-98.002, -1018.334, 27.275` | Shotgun | Drilling |

**Wave 2**

| # | Position | Weapon |
|---|---|---|
| 9 | `-88.440, -1050.558, 26.920` | Carbine |
| 10 | `-124.334, -1052.002, 26.920` | Carbine |
| 11 | `-106.002, -1028.558, 27.273` | Shotgun |
| 12 | `-75.558, -1042.334, 27.273` | Carbine |

</details>

---

## Police, money and cooldown

**Police get a 10-90 alert when:**
1. You hack the laptop successfully.
2. All wave-1 guards are dead.
3. You fire a gun after the hack.

Max one alert per minute per player.

**Payout**

| What | Amount |
|---|---|
| Finishing the job | $8,000 |
| Each bag | $18,000 |
| Both bags bonus | $6,000 |
| **Maximum** | **$50,000** |

**Cooldown:** 30 minutes per character, starting when you get paid.

---

## Distances

| What | Distance |
|---|---|
| Guards appear | 180 m from the laptop |
| Laptop and bags appear | 150 m from the laptop |
| Guards see you | 40 m |
| Guards hear gunshots | 65 m |
| Third-eye on objects | 3 m |
| Take USB | 2.5 m |
| Hand over to fixer | 8 m |

---

## Commands

| Command | What it does | Who |
|---|---|---|
| `/heistcoords` | Prints your position to the F8 console | Anyone |
| `/resetheist` | Resets your heist and cooldown | Admin |
| `/resetheist <id>` | Same, for another player | Admin |

---

## Changing settings

All settings are in `config/shared/heist.lua`. After a change, run `restart pulsar_heist`.

| I want to... | Change this |
|---|---|
| Move the fixer | `Config.Contact.coords` (use `/heistcoords` to get the numbers) |
| Move the laptop or bags | `Config.Objectives` **and** `Config.Props` |
| Add or remove guards | `Config.Guards` (`wave = 1` or `wave = 2`) |
| Tougher guards | `Config.GuardHealth` |
| Guards see further | `Config.Awareness.seenRange` |
| Awareness rises faster | `Config.Awareness.seenGain` or `gunshotNoise` |
| Guards calm down faster | `Config.Awareness.decay` |
| Easier laptop hack | `Config.Minigames.caseTerminal` (fewer `keys`, more `strikes`) |
| Easier bag lock | `Config.Minigames.moneyBag` (lower `numActive`) |
| Change the pay | `Config.Rewards` |
| Change the cooldown | `Config.CooldownSeconds` (in seconds) |
| Guard shouts | `Config.GuardSpeech` |

---

## How it works

**One rule: the client asks, the server decides.**

- **Client** = runs on the player's computer (guards, icons, minigames).
- **Server** = runs on the game server (who is allowed to do what, who gets paid).

### Files

```
pulsar_heist/
├── fxmanifest.lua
├── config/shared/heist.lua   Settings
├── client/
│   ├── main.lua              Blips, fixer, background checks, awareness bar
│   ├── guards.lua            Guards, their behaviour, icons, USB looting
│   ├── props.lua             Laptop and cash bags
│   └── stages.lua            Minigames, messages, cleanup
├── server/
│   ├── main.lua              Mission state, awareness numbers, cooldown
│   └── callbacks.lua         Rules for each step, payout
└── html/awareness.html       The awareness bar
```

### How a step works
```
Player acts  ->  server checks the rules  ->  minigame runs  ->  server checks the result  ->  next step
```

### How awareness works
```
Your game: "a guard can see me" / "I fired"   ->  Server adds awareness
Server sends the new number back              ->  Your game changes how the guard acts
```

### What the server checks (anti-cheat)
- You can only do a step if you are on that step.
- Every action checks how close you are.
- The USB needs a guard who is really dead.
- Wave 2 needs every wave-1 guard really dead.
- Minigames that finish too fast are rejected.
- Only one minigame at a time.
- Pay is worked out on the server.

### Pulsar features used

| Feature | Used for |
|---|---|
| `plsr.Targeting:AddEntity` | Third-eye on laptop and bags |
| `plsr.Targeting:AddPed` | Take USB from dead guards |
| `plsr.PedInteraction:Add` | The fixer |
| `plsr.Minigame.Play:Scrambler` / `:Memory` | The two minigames |
| `plsr.Minigame:Cancel` | Close the minigame if you die |
| `plsr.Callbacks` | Talking between client and server |
| `plsr.Wallet:Modify` | Paying the player |
| `plsr.Logger:Info` | Logs |
| `plsr.EmergencyAlerts:Create` | Police alerts |
| `plsr.Notification` | Messages on screen |
| `plsr.Middleware:Add` | Re-sync state when a character spawns |

---

## Testing checklist

Run `/resetheist` between tests.

- [ ] Fixer stands on the ground and **Talk** works
- [ ] Guards appear near the site
- [ ] A **?** then **!** appears when you walk into view
- [ ] One shot = suspicious, two shots = hostile
- [ ] The awareness bar shows and changes colour
- [ ] Killing a guard gives **Take USB Dongle** on the body
- [ ] Hacking without the USB is refused
- [ ] Hack works, and success sends a police alert
- [ ] Both bags end up on your back and their blips disappear
- [ ] Killing all wave-1 guards spawns wave 2
- [ ] **Hand Over Bags** pays $50,000
- [ ] Dying cleans everything up
- [ ] Restarting the job right after a success is blocked by the cooldown

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing happens | A requirement isn't running yet. Put `ensure pulsar_heist` **below** them. |
| No awareness bar | Check `html/awareness.html` exists and `fxmanifest.lua` still has `ui_page` and `files`. |
| Laptop or bags missing | They appear within 150 m of the laptop. Get closer. |
| Fixer floating | Stand on the ground, run `/heistcoords`, paste the exact Z into `Config.Contact.coords`. |
| "On cooldown" while testing | `/resetheist` |
| Stuck job | `/resetheist`, then talk to the fixer again |
| Red text in F8 | The message tells you the file and line number |
