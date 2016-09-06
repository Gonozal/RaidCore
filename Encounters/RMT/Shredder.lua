----------------------------------------------------------------------------------------------------
-- Shredder/Swabbie Ski'Li encounter script
--
-- Copyright (C) 2016 Joshua Shaffer
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Shredder", 104, 548, 549)
local Log = Apollo.GetPackage("Log-1.0").tPackage
if not mod then return end

mod:RegisterTrigMob("ANY", { "Swabbie Ski'Li" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Swabbie Ski'Li"] = "Swabbie Ski'Li",
    ["Regor the Rancid"] = "Regor the Rancid",
	["Risen Redmoon Cadet"] = "Risen Redmoon Cadet",
	["Risen Redmoon Plunderer"] = "Risen Redmoon Plunderer",
    ["Noxious Nabber"] = "Noxious Nabber",
    ["Putrid Pouncer"] = "Putrid Pouncer",
    ["Risen Redmoon Grunt"] = "Risen Redmoon Grunt",
    ["Bilious Brute"] = "Bilious Brute",
    ["Sawblade"] = "Sawblade",
    ["Saw"] = "Saw",
    ["Tether Anchor"] = "Tether Anchor",
    ["Circle Telegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)", --Bubble AoE?
    -- Datachron messages.
    ["WARNING: THE SHREDDER IS STARTING!"] = "WARNING: THE SHREDDER IS STARTING!",
    -- NPC Say
    ["Into the shredder with ye!"] = "Into the shredder with ye!", --Shredder is active!
    ["Ye've jammed me shredder"] = "Ye've jammed me shredder, ye have! Blast ye filthy bilge slanks!",
    ["The shredder'll take care o' ye"] = "The shredder'll take care o' ye once and fer all!", --Wipe incoming
    -- Cast.
    ["Risen Repellent"] = "Risen Repellent",
    ["Scrubber Bubbles"] = "Scrubber Bubbles",
    ["Clean Sweep"] = "Clean Sweep", --Resets swabbie to starting position after shredder jams
    ["Swabbie Swoop"] = "Swabbie Swoop", --Swabbie's ovement ability at start of fight
    ["Necrotic Lash"] = "Necrotic Lash", --Cast by Noxious Nabber (grab and disorient), interruptable
    ["Deathwail"] = "Deathwail", --Miniboss knockdown, interruptable
    ["Gravedigger"] = "Gravedigger", --Miniboss cast?
    ["Bilerush"] = "Bilerush",
    -- Bar and messages.
    ["%s 10 BILE STACKS!"] = "%s 10 BILE STACKS!",
    ["Swabbie Speed: %.2f"] = "Swabbie Speed: %.2f",
    ["%d BILE STACKS!"] = "%d BILE STACKS!",
    ["Bilerush"] = "Bilerush",
    
})

mod:RegisterDefaultSetting("MarkSpawnLocations")
mod:RegisterDefaultSetting("SpawnWarningSound")
mod:RegisterDefaultSetting("DrawSawbladeSafeLines")
mod:RegisterDefaultSetting("DrawLargeSawLines")
mod:RegisterDefaultSetting("PrintSwabbieSpeed")
mod:RegisterDefaultSetting("SoundLashInterrupt")
mod:RegisterDefaultSetting("SoundMinibossInterrupt")
mod:RegisterDefaultSetting("DrawScrubberBubbleCircles")
mod:RegisterDefaultSetting("Announce10BileStacks", false)
mod:RegisterDefaultSetting("SoundOozeStacksWarning")

--Wave 1 A: Risen Redmoon Grunt x1, Risen Redmoon Cadet x2, Putrid Pouncer x1
--Wave 1 B: Risen Redmoon Grunt x2, Risen Redmoon Cadet x2, Risen Redmoon Plunderer x1
--Wave 2 A: Risen Redmoon Plunderer x3, Noxious Nabber x1
--Wave 2 B: Risen Redmoon Plunderer x3, Noxious Nabber x1
--Wave 3 A: Risen Redmoon Grunt x2, Risen Redmoon Cadet x2, Risen Redmoon Plunderer x1
--Wave 3 B: Risen Redmoon Grunt x1, Risen Redmoon Cadet x2, Putrid Pouncer x1
--Mini 1: Regor the Rancid
--Wave 4 A: Risen Redmoon Grunt x2, Risen Redmoon Cadet x2, Risen Redmoon Plunderer x1
--Wave 4 B: Bilious Brute x1
--Wave 5 A: Putrid Pouncer x2, Risen Redmoon Grunt x1, Risen Redmoon Cadet x2
--Wave 5 B: Noxious Nabber x1, Risen Redmoon Plunderer x3
--Wave 6 A: Noxious Nabber x1, Risen Redmoon Plunderer x3
--Wave 6 B: Risen Redmoon Grunt x2, Risen Redmoon Cadet x2, Risen Redmoon Plunderer x1
--Mini 2: Regor the Rancid
--Wave 7 A: Noxious Nabber x1, Risen Redmoon Plunderer x3
--Wave 7 B: Bilious Brute x1
--Wave 8 A: Bilious Brute x1
--Wave 8 B: Putrid Pouncer x1, Risen Redmoon Grunt x1, Risen Redmoon Cadet x2

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF__SCRUBBER_BUBBLES = 77715 --Debuff while launched into the air
local DEBUFF__NECROTIC_OOZE = 84317 --Disorient
local DEBUFF__JUNK_TRAP = 86752 --Tether debuff
local DEBUFF__OOZING_BILE = 84321 --5% less damage done, 5% increase damage taken. Get stacks by hitting billious brute
local BUFF__DETERMINED_STRIDE = 85567 --Swabbie is immune to CC (during walk back)
local BUFF__RISEN_REPELLENT = 85488 --Swabbie will cast AoE knockback if he gets too close to risen
local BUFF__RISEN = 77841 --Add can't die (needs knocked up into shredder)

local SPAWN_TRIGGER_DISTANCE = 12 --How close Swabbie has to get to trigger a spawn warning
local SPEED_CHECK_TIME = 3

local DECK_Y_LOC = 598
local SPAWN_1_TRIGGER = Vector3.New(-20, DECK_Y_LOC, -827)
local SPAWN_1_LOCATION_A = Vector3.New(-20, DECK_Y_LOC, -882)
local SPAWN_1_LOCATION_B = Vector3.New(-20, DECK_Y_LOC, -959)
local SPAWN_2_TRIGGER = Vector3.New(-20, DECK_Y_LOC, -883)
local SPAWN_2_LOCATION_A = Vector3.New(-20, DECK_Y_LOC, -807)
local SPAWN_2_LOCATION_B = Vector3.New(-20, DECK_Y_LOC, -958)
local SPAWN_3_TRIGGER = Vector3.New(-20, DECK_Y_LOC, -917)
local SPAWN_3_LOCATION_A = Vector3.New(-20, DECK_Y_LOC, -809)
local SPAWN_3_LOCATION_B = Vector3.New(-20, DECK_Y_LOC, -882)
local MINI_SPAWN_TIGGER = Vector3.New(-20.5, DECK_Y_LOC, -973)
local MINI_SPAWN_LOCATION = Vector3.New(-20.5, DECK_Y_LOC, -807)

local ENTRANCELINE_A = Vector3.New(-1, DECK_Y_LOC, -830)
local ENTRANCELINE_B = Vector3.New(-40, DECK_Y_LOC, -830)
local SHREDDERLINE_A = Vector3.New(-1, DECK_Y_LOC, -980)
local SHREDDERLINE_B = Vector3.New(-41, DECK_Y_LOC, -980)

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local bWave1Spawned, bWave2Spawned, bWave3Spawned, bMini1Spawned, bWave4Spawned, bWave5Spawned, bWave6Spawned, bMini2Spawned, bWave7Spawned, bWave8Spawned
local bWave1Warning, bWave2Warning, bWave3Warning, bMini1Warning, bWave4Warning, bWave5Warning, bWave6Warning, bMini2Warning, bWave7Warning, bWave8Warning
local bWalkingPhase, bWipeWarning
local tPositionCheckTimer
local nSwabbieSkiLiId
local bShouted10Stacks

local lastPos, speedCheckTimer

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
	bWave1Spawned = false
    bWave2Spawned = false
    bWave3Spawned = false
    bWave4Spawned = false
    bWave5Spawned = false
    bWave6Spawned = false
    bWave7Spawned = false
    bWave8Spawned = false
    
    bWave1Warning = false
    bWave2Warning = false
    bWave3Warning = false
    bWave4Warning = false
    bWave5Warning = false
    bWave6Warning = false
    bWave7Warning = false
    bWave8Warning = false
    
    bMini1Spawned = false
    bMini1Warning = false
    bMini2Spawned = false
    bMini2Warning = false
    
    bWalkingPhase = false
    bWipeWarning = false
    
    bShouted10Stacks = false
    
    tPositionCheckTimer = ApolloTimer.Create(.2, true, "OnPositionCheckTimer", mod)
    if mod:GetSetting("PrintSwabbieSpeed") then
        speedCheckTimer = ApolloTimer.Create(SPEED_CHECK_TIME, true, "SpeedCheckTimer", mod)
    end
    
    if mod:GetSetting("DrawSawbladeSafeLines") then
        core:AddLineBetweenUnits("ShredderSawLine", SHREDDERLINE_A, SHREDDERLINE_B, 5, "xkcdBrightPurple")
        core:AddLineBetweenUnits("EntranceSawLine", ENTRANCELINE_A, ENTRANCELINE_B, 5, "xkcdBrightPurple")
    end
end

function mod:OnBossDisable()
    if tPositionCheckTimer then
        tPositionCheckTimer:Stop()
        tPositionCheckTimer = nil
    end
    if speedCheckTimer then
        speedCheckTimer:Stop()
        speedCheckTimer = nil
    end
    core:RemoveLineBetweenUnits("ShredderSawLine")
    core:RemoveLineBetweenUnits("EntranceSawLine")
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:SpeedCheckTimer()
    local swabbie = GameLib.GetUnitById(nSwabbieSkiLiId)
    local currentPos = Vector3.New(swabbie:GetPosition())
    if lastPos then
        if not bWalkingPhase then
            local speed = (currentPos - lastPos):Length() / SPEED_CHECK_TIME
            if speed > .1 and speed < 10 then
                --ChatSystemLib.Command("/p " .. string.format(self.L["Swabbie Speed: %.2f"], speed))
                core:Print(string.format(self.L["Swabbie Speed: %.2f"], speed))
            end
        end
    end
    lastPos = currentPos
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Noxious Nabber"] == sName then
        if self.L["Necrotic Lash"] == sCastName then
            local uUnit = GameLib.GetUnitById(nId)
            local player = GameLib.GetPlayerUnit()
            local playerPos = Vector3.New(player:GetPosition())
            if mod:DistanceBetween(uUnit, playerPos) < 30 then
                mod:AddMsg("LASH", "Interrupt Lash!", 5, mod:GetSetting("SoundLashInterrupt") and "Destruction")
            end
        end
    elseif self.L["Regor the Rancid"] == sName then
        if self.L["Deathwail"] == sCastName or
            self.L["Gravedigger"] == sCastName then
            mod:AddMsg("MINIINTERRUPT", "Interrupt!", 5, mod:GetSetting("SoundMinibossInterrupt") and "Destruction")
        end
    end
end

function mod:OnUnitCreated(nId, unit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Swabbie Ski'Li"] then
        core:AddUnit(unit)
        core:WatchUnit(unit)
        nSwabbieSkiLiId = nId
    elseif sName == self.L["Noxious Nabber"] then
        mod:PrintUnitPos(nId)
        core:WatchUnit(unit)
        if not bWave2Spawned then
            bWave2Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        elseif bWave4Spawned and not bWave5Spawned then
            bWave5Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        elseif bWave5Spawned and not bWave6Spawned then
            bWave6Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        end
    elseif sName == self.L["Risen Redmoon Plunderer"] then
        mod:PrintUnitPos(nId)
        if not bWave1Spawned then
            bWave1Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        end
    elseif sName == self.L["Putrid Pouncer"] then
        mod:PrintUnitPos(nId)
    elseif sName == self.L["Risen Redmoon Grunt"] then
        mod:PrintUnitPos(nId)
    elseif sName == self.L["Risen Redmoon Cadet"] then
        mod:PrintUnitPos(nId)
        if bWave2Spawned and not bWave3Spawned then
            bWave3Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        end
    elseif sName == self.L["Bilious Brute"] then
        mod:PrintUnitPos(nId)
        core:WatchUnit(unit)
        if not bWave4Spawned then
            bWave4Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        elseif bMini2Spawned and not bWave7Spawned then
            bWave7Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        elseif bWave7Spawned and not bWave8Spawned then
            bWave8Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("SPAWNA")
            core:RemovePicture("SPAWNB")
        end
    elseif sName == self.L["Regor the Rancid"] then
        core:AddUnit(unit)
        mod:PrintUnitPos(nId)
        core:WatchUnit(unit)
        if not bMini1Spawned then
            bMini1Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("MINISPAWN")
        elseif not bMini2Spawned then
            bMini2Spawned = true
            mod:PrintUnitPos(nSwabbieSkiLiId)
            core:RemovePicture("MINISPAWN")
        end
    elseif sName == self.L["Sawblade"] then
        if mod:GetSetting("DrawLargeSawLines") then
            core:AddPixie(nId, 2, unit, nil, "xkcdBrightPurple", 15, 60, 0)
        end
    elseif sName == self.L["Circle Telegraph"] then
        if mod:GetSetting("DrawScrubberBubbleCircles") then
            core:AddPolygon(nId, nId, 6.7, 0, 7, "xkcdBloodOrange", 20)
        end
    end
end

function mod:OnUnitDestroyed(nId, unit, sName)
    if sName == self.L["Sawblade"] then
        core:DropPixie(nId)
    elseif sName == self.L["Circle Telegraph"] then
        core:RemovePolygon(nId)
    end
end

function mod:OnNPCSay(sMessage)
    if sMessage == self.L["Into the shredder with ye!"] then
        mod:AddTimerBar("SHREDDER", "Shredder Active", 60, nil)
    elseif sMessage == self.L["Ye've jammed me shredder"] then
        
    elseif sMessage == self.L["The shredder'll take care o' ye"] then
        mod:PrintUnitPos(nSwabbieSkiLiId)
    end
end

function mod:OnDatachron(sMessage)
    if sMessage == self.L["WARNING: THE SHREDDER IS STARTING!"] then
        mod:WaveAlert(MINI_SPAWN_LOCATION, nil, "Miniboss Incoming")
    end
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)    
    if BUFF__DETERMINED_STRIDE == nSpellId then
        bWalkingPhase = true
    end
end

function mod:OnBuffUpdate(nId, nSpellId, nStack, fTimeRemaining)    
    if BUFF__DETERMINED_STRIDE == nSpellId then
        bWalkingPhase = true
    end
end

function mod:OnBuffRemove(nId, nSpellId, nStack, fTimeRemaining)    
    if DEBUFF__OOZING_BILE == nSpellId then
        local tPlayer = GameLib.GetPlayerUnit()
        local tUnit = GameLib.GetUnitById(nId)
        if tPlayer == tUnit then
            if nStack >= 8 then
                mod:AddMsg("OOZE", string.format(self.L["%d BILE STACKS!"], nStack), 5, nStack == 8 and mod:GetSetting("SoundOozeStacksWarning") and "Beware")
            end
        end
        
        if nStack == 10 and not bShouted10Stacks and mod:GetSetting("Announce10BileStacks") then
            ChatSystemLib.Command("/p" .. string.format(self.L["%s 10 BILE STACKS!"], tUnit:GetName()))
            bShouted10Stacks = true
        end
    end
end

function mod:OnPositionCheckTimer()
    local uSwabbieSkiLi = GameLib.GetUnitById(nSwabbieSkiLiId)
    if not bWalkingPhase and uSwabbieSkiLi then
        if not bWave1Spawned and not bWave1Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_1_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave1Warning = true
                mod:WaveAlert(SPAWN_1_LOCATION_A, SPAWN_1_LOCATION_B, "Wave 1 Incoming")
            end
        elseif bWave1Spawned and not bWave2Spawned and not bWave2Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_2_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave2Warning = true
                mod:WaveAlert(SPAWN_2_LOCATION_A, SPAWN_2_LOCATION_B, "Wave 2 Incoming")
            end
        elseif bWave2Spawned and not bWave3Spawned and not bWave3Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_3_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave3Warning = true
                mod:WaveAlert(SPAWN_3_LOCATION_A, SPAWN_3_LOCATION_B, "Wave 3 Incoming")
            end
        -- elseif bWave3Spawned and not bMini1Warning then
            -- if mod:DistanceBetween(uSwabbieSkiLi, MINI_SPAWN_TIGGER) < SPAWN_TRIGGER_DISTANCE then
                -- bMini1Warning = true
                -- mod:WaveAlert(MINI_SPAWN_LOCATION, nil, "Miniboss Incoming")
                -- core:AddPicture("MINISPAWN", MINI_SPAWN_LOCATION, "Crosshair", 40, nil, nil, nil, "red")
                -- mod:AddMsg("WAVE", "Miniboss Incoming", 5, "Info")
            -- end
        elseif bMini1Spawned and not bWave4Spawned and not bWave4Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_1_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave4Warning = true
                mod:WaveAlert(SPAWN_1_LOCATION_A, SPAWN_1_LOCATION_B, "Wave 4 Incoming")
            end
        elseif bWave4Spawned and not bWave5Spawned and not bWave5Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_2_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave5Warning = true
                mod:WaveAlert(SPAWN_2_LOCATION_A, SPAWN_2_LOCATION_B, "Wave 5 Incoming")
            end
        elseif bWave5Spawned and not bWave6Spawned and not bWave6Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_3_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave6Warning = true
                mod:WaveAlert(SPAWN_3_LOCATION_A, SPAWN_3_LOCATION_B, "Wave 6 Incoming")
            end
        -- elseif bWave6Spawned and not bMini2Warning then
            -- if mod:DistanceBetween(uSwabbieSkiLi, MINI_SPAWN_TIGGER) < SPAWN_TRIGGER_DISTANCE then
                -- bMini2Warning = true
                -- core:AddPicture("MINISPAWN", MINI_SPAWN_LOCATION, "Crosshair", 40, nil, nil, nil, "red")
                -- mod:AddMsg("WAVE", "Miniboss Incoming", 5, "Info")
            -- end
        elseif bMini2Spawned and not bWave7Spawned and not bWave7Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_1_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave7Warning = true
                mod:WaveAlert(SPAWN_1_LOCATION_A, SPAWN_1_LOCATION_B, "Wave 7 Incoming")
            end
        elseif bWave7Spawned and not bWave8Spawned and not bWave8Warning then
            if mod:DistanceBetween(uSwabbieSkiLi, SPAWN_2_TRIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWave8Warning = true
                mod:WaveAlert(SPAWN_2_LOCATION_A, SPAWN_2_LOCATION_B, "Wave 8 Incoming")
            end
        elseif bWave8Spawned and not bWipeWarning then
            if mod:DistanceBetween(uSwabbieSkiLi, MINI_SPAWN_TIGGER) < SPAWN_TRIGGER_DISTANCE then
                bWipeWarning = true
                mod:AddMsg("WAVE", "WIPE INCOMING", 5, "Burn")
            end
        end
    end
end

function mod:WaveAlert(vLocationA, vLocationB, sMessage)
    if mod:GetSetting("MarkSpawnLocations") then
        core:AddPicture("SPAWNA", vLocationA, "Crosshair", 40, nil, nil, nil, "red")
        if vLocationB then
            core:AddPicture("SPAWNB", vLocationB, "Crosshair", 40, nil, nil, nil, "red")
        end
    end
    mod:AddMsg("WAVE", sMessage, 5, mod:GetSetting("SpawnWarningSound") and "Info")
end

function mod:PrintUnitPos(nId)
    local unit = GameLib.GetUnitById(nId)
    local position = unit:GetPosition()
    Log:Add("ChannelCommStatus", "SpawnPosition - " .. unit:GetName() .. ": x " .. position.x .. " y " .. position.y .. " z " .. position.z)
end

function mod:DistanceBetween(uUnit, vPosition)
    local vUnit = Vector3.New(uUnit:GetPosition())
    return (vUnit - vPosition):Length()
end
