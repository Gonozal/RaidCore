----------------------------------------------------------------------------------------------------
-- StarEater encounter script (HE'LL ALWAYS BE OCTOC TO ME!)
--
-- Copyright (C) 2016 Joshua Shaffer
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("StarEater", 104, 0, 548)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Star-Eater the Voracious" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Star-Eater the Voracious"] = "Star-Eater the Voracious",
	["Astral Shard"] = "Astral Shard",
    ["Squirgling"] = "Squirgling",
    ["Chaos Orb"] = "Chaos Orb",
    ["Noxious Ink Pool"] = "Noxious Ink Pool",
    -- Datachron messages.
    -- Casts
    ["Hookshot"] = "Hookshot",
    ["Summon Squirglings"] = "Summon Squirglings",
    ["Flamethrower"] = "Flamethrower",
    ["Supernova"] = "Supernova",
    -- Bar and messages.
    ["%u shields remain"] = "%u shields remain",
    ["Hookshot!"] = "Hookshot!",
    ["Shard phase soon!"] = "Shard phase soon!",
    ["Orb soon!"] = "Orb soon!",
    ["5 rend stacks on %s"] = "5 rend stacks on %s",
    ["5 rend stacks on YOU"] = "5 rend stacks on YOU",
})

mod:RegisterDefaultSetting("ShardLines")
mod:RegisterDefaultSetting("ShowHookshotCircles")
mod:RegisterDefaultSetting("TankStacksWarning", false)
mod:RegisterDefaultSetting("OrbCountdown")
mod:RegisterDefaultSetting("HookshotWarningSound")
mod:RegisterDefaultSetting("MidphaseWarningSound")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF__NOXIOUS_INK = 85533 -- DoT for standing in circles
local DEBUFF__SQUINGLING_SMASHER = 86804 -- +5% DPS/heals, -10% incoming heals; per stack
local DEBUFF__CHAOS_TETHER = 85583 -- kills you if you leave orb area
local DEBUFF__CHAOS_ORB = 85582 -- 10% more damage taken per stack
local DEBUFF__REND = 85443 -- main tank stacking debuff, 2.5% less mitigation per stack
local DEBUFF__SPACE_FIRE = 87159 -- 12k dot from flame, lasts 45 seconds
local BUFF__CHAOS_ORB = 86876 -- Countdown to something, probably the orb wipe
local BUFF__CHAOS_AMPLIFIER = 86876 -- Bosun Buff that increases orb count?
local BUFF__FLAMETHROWER = 87059 -- Flamethrower countdown buff -- DOESN'T EXIST ANYMORE, used to be 15s countdown to flame cast
local BUFF__ASTRAL_SHIELD = 85643 -- Shard phase shield, 20 stacks
local BUFF__ASTRAL_SHARD = 85611 --Buff shards get right before they die, probably meaningless

local ROCKET_HEIGHT = 20
local ROOM_FLOOR_Y = 378

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local tShardIds
local tShardTimer, tHookshotCircleTimer, tHookshotRedrawTimer
local bShard1Warning, bShard2Warning
local iSquirgCount
local iNextOrbs
local nStarEaterId

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    tShardIds = {}
    bShard1Warning = false
    
    mod:AddTimerBar("HOOKSHOT", "Next Hookshot", 10, nil)
    mod:AddTimerBar("FLAMETHROWER", "Next Flamethrower", 35, nil)
    mod:AddTimerBar("ORBS", "Next Orbs", 48, mod:GetSetting("OrbCountdown"))
    iNextOrbs = GameLib.GetGameTime() + 48    
end


function mod:OnHealthChanged(nId, nPercent, sName)
    if sName == self.L["Star-Eater the Voracious"] then
        if nPercent >= 65 and nPercent <= 67 and not bShard1Warning then
            bShard1Warning = true
            mod:AddMsg("SHARDWARNING", self.L["Shard phase soon!"], 5, mod:GetSetting("MidphaseWarningSound") and "Algalon")
        elseif nPercent >= 35 and nPercent <= 37 and not bShard2Warning then
            bShard2Warning = true
            mod:AddMsg("SHARDWARNING", self.L["Shard phase soon!"], 5, mod:GetSetting("MidphaseWarningSound") and "Algalon")
        end
    end
end

function mod:OnBossDisable()
    if tShardTimer then
        tShardTimer:Stop()
        tShardTimer = nil
    end
    if tHookshotRedrawTimer then
        tHookshotRedrawTimer:Stop()
        tHookshotRedrawTimer = nil
    end
    if tHookshotCircleTimer then
        tHookshotCircleTimer:Stop()
        tHookshotCircleTimer = nil
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    local tUnit = GameLib.GetUnitById(nId)

    if self.L["Star-Eater the Voracious"] == sName then
        if self.L["Hookshot"] == sCastName then
            mod:AddMsg("HOOKSHOTWARN", self.L["Hookshot!"], 5, mod:GetSetting("HookshotWarningSound") and "Beware")
            mod:AddTimerBar("HOOKSHOT", "Next Hookshot", 30, nil)
            if mod:GetSetting("ShowHookshotCircles") then
                tHookshotRedrawTimer = ApolloTimer.Create(.1, true, "RedrawHookshotCircles", self)
                tHookshotCircleTimer = ApolloTimer.Create(5, true, "RemoveHookshotCircles", self)
            end
        elseif self.L["Supernova"] == sCastName then
            mod:AddTimerBar("SUPERNOVA", "Supernova!", 25, true)
            mod:RemoveTimerBar("ORBS")
            mod:RemoveTimerBar("HOOKSHOT")
            mod:RemoveTimerBar("FLAMETHROWER")
        elseif self.L["Summon Squirglings"] == sCastName then
            iSquirgCount = 0
        elseif self.L["Flamethrower"] == sCastName then
            mod:AddTimerBar("FLAMETHROWER", "Next Flamethrower", 45, nil)
        end
    end
end

function mod:OnCastEnd(nId, sCastName, bInterrupted, nCastEndTime, sName)
    if self.L["Star-Eater the Voracious"] == sName then
        if self.L["Supernova"] == sCastName then
            mod:RemoveTimerBar("SUPERNOVA")
            
            tShardIds = {}
            if tShardTimer then
                tShardTimer:Stop()
                tShardTimer = nil
            end
            
            local timeToNextOrbs = iNextOrbs - GameLib.GetGameTime()
            if timeToNextOrbs < 10 then
                mod:AddTimerBar("ORBS", "Next Orbs", 10, mod:GetSetting("OrbCountdown"))
            else
                mod:AddTimerBar("ORBS", "Next Orbs", timeToNextOrbs, mod:GetSetting("OrbCountdown"))
            end
        elseif self.L["Hookshot"] == sCastName then
            if tHookshotRedrawTimer then
                tHookshotRedrawTimer:Stop()
                tHookshotRedrawTimer = nil
            end
        end
    end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    --local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Star-Eater the Voracious"] then
        nStarEaterId = nId
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif sName == self.L["Squirgling"] then
        iSquirgCount = iSquirgCount + 1
        if iSquirgCount < 9 then
            mod:AddTimerBar("SQUIRGLINGS", "2 Squirgs", 8, nil)
        end
        --core:AddUnit(tUnit)
        --core:WatchUnit(tUnit)
    elseif sName == self.L["Astral Shard"] then
		
        if mod:GetSetting("ShardLines") then
			local shardPos = tUnit:GetPosition()
			if shardPos.y - ROOM_FLOOR_Y < 30 then
				local size = 2 - ((shardPos.y - ROOM_FLOOR_Y) / 40)
				shardPos.y = ROOM_FLOOR_Y
				core:AddPolygon(nId, Vector3.New(shardPos), size, 0, 3, "red", 20)
			end
        --     if not tShardTimer then
        --         tShardTimer = ApolloTimer.Create(.1, true, "CheckShardsTimer", self)
        --     end
        --     tShardIds[nId] = false;
         end
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Astral Shard"] then
		--core:AddPolygon(nId, circleLeft, 2, 0, 3, "red", 20)
		core:RemovePolygon(nId)
        tShardIds[nId] = nil;
        core:RemoveLineBetweenUnits(nId)
    end
end

function mod:CheckShardsTimer()
    local playerUnit = GameLib.GetPlayerUnit()
    local playerPosition = Vector3.New(playerUnit:GetPosition())
    
    for nId, hasLine in pairs(tShardIds) do
        local unit = GameLib.GetUnitById(nId)
        if unit then
            local shardPosition = Vector3.New(unit:GetPosition())
            local horizontalDistance = mod:HorizontalDistance(playerPosition, shardPosition)
            local isClose = horizontalDistance < 18
            if shardPosition.y + 5 < playerPosition.y then
                -- Don't draw lines to shards far below than player
                core:RemoveLineBetweenUnits(nId)
                tShardIds[nId] = false
            elseif isClose and shardPosition.y < (playerPosition.y + ROCKET_HEIGHT + 2) then
                -- Draw lines to shards player can reach with rocket boost
                if not hasLine then
                    local lineThickness = 4 --Thicker lines for closer shards?
                    if horizontalDistance < 5 then
                        lineThickness = 6
                    elseif horizontalDistance > 12 then
                        lineThickness = 2
                    end
                    local color = "red"
                    if shardPosition.y > ROOM_FLOOR_Y + 40 then
                        color = "green" --Orange shards are 40m+ up from floor
                    end
                    if false then
                        --Verticle lines from shards, rather than to player?
                        local belowShardPos = Vector3.New(shardPosition)
                        belowShardPos.y = belowShardPos.y - 42
                        core:AddLineBetweenUnits(nId, shardPosition, belowShardPos, lineThickness, color)
                    else
                        core:AddLineBetweenUnits(nId, playerUnit:GetId(), nId, lineThickness, color)
                    end
                    tShardIds[nId] = true
                end
            else
                -- Don't draw lines to shards the player can't reach
                core:RemoveLineBetweenUnits(nId)
                tShardIds[nId] = false
            end
        else
            tShardIds[nId] = nil
        end
    end
end

function mod:HorizontalDistance(pos1, pos2)
    return (Vector2.New(pos1.x, pos1.z) - Vector2.New(pos2.x, pos2.z)):Length()
end

function mod:OnBuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    --local tUnit = GameLib.GetUnitById(nId)
    --local playerUnit = GameLib.GetPlayerUnit()
    
    if BUFF__ASTRAL_SHARD == nSpellId then
        --if tUnit == player then
            --mod:AddMsg("ORBTARGET", self.L["ORB ON YOU!"], 5, "RunAway")
            --core:AddLineBetweenUnits("ORB", player:GetId(), nOrbId, 2, "red")
            --local chatMessage = tUnit:GetName() .. " got shocked debuff"
            --ChatSystemLib.Command("/p " .. chatMessage)
        --end
    elseif BUFF__CHAOS_AMPLIFIER == nSpellId then
        mod:AddTimerBar("ORBS", "Next Orbs", 80, mod:GetSetting("OrbCountdown"))
        iNextOrbs = GameLib.GetGameTime() + 80
    end
end


function mod:OnBuffUpdate(nId, nSpellId, nStack, fTimeRemaining)
    if BUFF__ASTRAL_SHIELD == nSpellId then
        mod:AddMsg("SHIELD_STACKS", self.L["%u shields remain"]:format(nStack), 5, nil, "red")
    elseif BUFF__CHAOS_AMPLIFIER == nSpellId then
        mod:AddTimerBar("ORBS", "Next Orbs", 85, mod:GetSetting("OrbCountdown"))
        iNextOrbs = GameLib.GetGameTime() + 85
    end
end

function mod:OnDebuffUpdate(nId, nSpellId, nStack, fTimeRemaining)
    if DEBUFF__REND == nSpellId then
        if mod:GetSetting("TankStacksWarning") and nStack == 5 then
            local tUnit = GameLib.GetUnitById(nId)
            local playerUnit = GameLib.GetPlayerUnit()
            if tUnit == playerUnit then
                mod:AddMsg("RENDSTACKS", self.L["5 rend stacks on YOU"], 5, "Info", "red")
            else 
                mod:AddMsg("RENDSTACKS", self.L["5 rend stacks on %s"]:format(tUnit:GetName()), 5, "Info", "red")
            end
        end
    end
end

function mod:RemoveHookshotCircles()
    if tHookshotRedrawTimer then
        tHookshotRedrawTimer:Stop()
        tHookshotRedrawTimer = nil
    end
    tHookshotCircleTimer:Stop()
    tHookshotCircleTimer = nil
    core:RemovePolygon("HOOSHOT1")
    core:RemovePolygon("HOOSHOT2")
end

function mod:RedrawHookshotCircles()
    local tStarEater = GameLib.GetUnitById(nStarEaterId)
    if tStarEater then
        local facing = Vector3.New(tStarEater:GetFacing())
        local starEaterPosition = Vector3.New(tStarEater:GetPosition())
        local targetUnit = tStarEater:GetTarget()
        if targetUnit then
            --Calculate real location based on StarEater's target since he can spin after the cast completes
            local targetPosition = Vector3.New(targetUnit:GetPosition())
            facing = targetPosition - starEaterPosition
            facing = facing / facing:Length() --To unit vector
        end
    
        local FRONT_DISTANCE = 9.25
        local SIDE_DISTANCE = 3
        local CIRCLE_SIZE = 10.5
        
        local leftVector = Vector3.New(-facing.z, 0, facing.x)
        local rightVector = Vector3.New(facing.z, 0, -facing.x)
        local starEaterPosition = Vector3.New(tStarEater:GetPosition())

        local circleLeft = starEaterPosition + facing * FRONT_DISTANCE + leftVector * SIDE_DISTANCE
        local circleRight = starEaterPosition + facing * FRONT_DISTANCE + rightVector * SIDE_DISTANCE

        core:AddPolygon("HOOSHOT1", circleLeft, CIRCLE_SIZE, 0, 3, "xkcdBrightPurple", 20)
        core:AddPolygon("HOOSHOT2", circleRight, CIRCLE_SIZE, 0, 3, "xkcdBrightPurple", 20)
    end
end