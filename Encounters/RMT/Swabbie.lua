----------------------------------------------------------------------------------------------------
-- Client Lua Script for RaidCore Addon on WildStar Game.
--
-- Copyright (C) 2016 Sören Link
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Description:
--   RMT Swabbie Skil'li (AKA Shredder)
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Swabbie", 104, 548, 549)
local Log = Apollo.GetPackage("Log-1.0").tPackage
if not mod then return end

----------------------------------------------------------------------------------------------------
-- Registering combat.
----------------------------------------------------------------------------------------------------
mod:RegisterTrigMob("ANY", { "Swabbie Ski'Li" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Swabbie Ski'Li"] = "Swabbie Ski'Li",
	["Risen Redmoon Cadet"] = "Risen Redmoon Cadet",
	["Risen Redmoon Grunt"] = "Risen Redmoon Grunt",
	["Risen Redmoon Plunderer"] = "Risen Redmoon Plunderer",
	["Putrid Pouncer"] = "Putrid Pouncer",
    ["Noxious Nabber"] = "Noxious Nabber",
    ["Bilious Brute"] = "Bilious Brute",
    ["Sawblade"] = "Sawblade",
    ["Saw"] = "Saw",
    ["Tether Anchor"] = "Tether Anchor",
	["Bubbles"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",

    -- Datachron messages.
    ["WARNING: THE SHREDDER IS STARTING!"] = "WARNING: THE SHREDDER IS STARTING!",
    -- NPC Say
    ["Midphae starting"] = "Into the shredder with ye!", --Shredder is active!
	["Midphase over"] = "Ye've jammed me shredder, ye have! Blast ye filthy bilge slanks!",

    -- Cast.

	["Scrubber Bubbles"] = "Scrubber Bubbles", --Bubbles, duh 
    ["Risen Repellent"] = "Risen Repellent", -- knockback cast if undead get too close
    ["Swabbie Swoop"] = "Swabbie Swoop", --Fight start
    ["Necrotic Lash"] = "Necrotic Lash", --Needs to be interrupted. Disorient, Green AOE
    ["Deathwail"] = "Deathwail", -- Miniboss Stun-Cast. Interrupt this
    -- Bar and messages.
    ["Boss Speed"] = "Boss Speed: %.2f"
})
mod:RegisterFrenchLocale({

})
mod:RegisterGermanLocale({

})

local nBridgeYPos = 598 	-- y-coordinate of the bridge swabbie is walking on
local vBridgeXEdges = {0.5805, -42.0713}
local vBridgeXCenter = (vBridgeXEdges[2] + vBridgeXEdges[1]) / 2

local nNextSpawnWave		 	-- next wave / array index for wave triggers/positions
local vSwabbieSpawnTriggers = { -- z-positions where swabbie triggers mob spawns
     -827.36,  -883.33,	 -917.64
}
local nSwabbieShredderPos = -973
local vAddSpawnLocations = { -- z coordinates where mobs spawn
    { -884 , -956  },
    { -810 , -956  },
	{ -808 , -885  }
}


----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local nSwabbieId
local speedCheckInterval = 2
local posCheckInterval = 0.25
local bLinesDrawn
local bShredderPhase


local lastPos, tSpeedCheckTimer, tPosCheckTimer, speed
local bFightStarted = false
----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable() 
	lastPos = nil
	bFightStarted = false
	bLinesDrawn = false
	bShredderPhase = false

	nSwabbieId = nil
	nNextSpawnWave = 1
	
	--Print("Swabbie fight started")
	tSpeedCheckTimer = ApolloTimer.Create(speedCheckInterval, true, "calcSwabbieSpeed", mod)
	tPosCheckTimer = ApolloTimer.Create(posCheckInterval, true, "calcSwabbiePos", mod)

end

function mod:OnBossDisable()
    if tSpeedCheckTimer then
        tSpeedCheckTimer:Stop()
        tSpeedCheckTimer = nil
    end
	if tPosCheckTimer then
		tPosCheckTimer:Stop()
		tPosCheckTimer = nil
	end
end

function mod:removeSpawnMarkers()
	tSpeedCheckTimer:Stop()
	tRemoveMarkerTimer = nil
end

function mod:nextTriggerLine()
	if(vSwabbieSpawnTriggers[nNextSpawnWave] ) then
		bLinesDrawn = true
		local bridgeLeftEdge = Vector3.New(vBridgeXEdges[1], nBridgeYPos, vSwabbieSpawnTriggers[nNextSpawnWave])
		local bridgeRightEdge = Vector3.New(vBridgeXEdges[2], nBridgeYPos, vSwabbieSpawnTriggers[nNextSpawnWave])
		

		if(vAddSpawnLocations[nNextSpawnWave]) then
			local posSpawnA = Vector3.New(vBridgeXCenter, nBridgeYPos, vAddSpawnLocations[nNextSpawnWave][1])
			local posSpawnB = Vector3.New(vBridgeXCenter, nBridgeYPos, vAddSpawnLocations[nNextSpawnWave][2])
			core:AddPicture("SpawnA", posSpawnA, "Crosshair", 50, nil, nil, nil, "red")
			core:AddPicture("SpawnB", posSpawnB, "Crosshair", 50, nil, nil, nil, "red")
		end
		core:AddLineBetweenUnits("SwabbieTriggerLine", bridgeLeftEdge, bridgeRightEdge, 5, "xkcdBlue")
	end
end

function mod:shredderTriggerLine()
	bLinesDrawn = true
	local bridgeLeftEdge = Vector3.New(vBridgeXEdges[1], nBridgeYPos, nSwabbieShredderPos)
	local bridgeRightEdge = Vector3.New(vBridgeXEdges[2], nBridgeYPos, nSwabbieShredderPos)
	core:AddLineBetweenUnits("SwabbieTriggerLine", bridgeLeftEdge, bridgeRightEdge, 5, "xkcdBlue")
end

function mod:removeLastTriggerLine()
	bLinesDrawn = false
	core:RemoveLineBetweenUnits("SwabbieTriggerLine")
	core:RemovePicture("SpawnA")
	core:RemovePicture("SpawnB")
end

function mod:calcSwabbieSpeed()
    local swabbie = GameLib.GetUnitById(nSwabbieId)
    local currentPos = swabbie:GetPosition()
    if lastPos and not bShredderPhase then
		-- calc speed
		speed = (lastPos.z - currentPos.z) / speedCheckInterval
		if speed < 10 and speed > 0.1 then	
			bFightStarted = true
		end
    end
    lastPos = currentPos
end

function mod:calcSwabbiePos()
	local swabbie = GameLib.GetUnitById(nSwabbieId)
    local currentPos = swabbie:GetPosition()
	-- check if next wave should spawn
	-- moving towards neg. Z, so t1 > t2 -> z1 < z2
	if bFightStarted and vSwabbieSpawnTriggers[nNextSpawnWave] and currentPos.z <= vSwabbieSpawnTriggers[nNextSpawnWave] + 15 and not bLinesDrawn then
		local timeToNextSpawn = math.abs(vSwabbieSpawnTriggers[nNextSpawnWave] - currentPos.z) / speed
		mod:AddTimerBar("MobSpawn", "Next Add Wave", timeToNextSpawn , true, { sColor = "blue" })
		self:nextTriggerLine()
		nNextSpawnWave = nNextSpawnWave + 1
	end
	if bFightStarted and currentPos.z <= nSwabbieShredderPos + 25 and not bLinesDrawn then
		Print("Shredder soon...")
		local timeToNextSpawn = math.abs(nSwabbieShredderPos - currentPos.z) / speed + 8
		mod:AddTimerBar("ShredderStarting", "The shredder is starting ...", timeToNextSpawn , true, { sColor = "blue" })
		self:shredderTriggerLine()
	end
end

function mod:OnUnitDestroyed(nId, unit, sName)
    if sName == self.L["Sawblade"] then
        core:DropPixie(nId)
	elseif sName == self.L["Bubbles"] then
        core:RemovePolygon(nId)
    end
end

function mod:OnDatachron(sMessage)
	if(sMessage == self.L["WARNING: THE SHREDDER IS STARTING!"]) then
		mod:AddTimerBar("ShredderStarting", "The shredder is starting ...", 9, "Info", { sColor = "red", bEmphasize = true })
		bShredderPhase = true
	end
end

function mod:OnNPCSay(sMessage)
	if sMessage == self.L["Midphase over"] then
        bShredderPhase = false
		nNextSpawnWave = 1
		bLinesDrawn = false
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)    
	if sCastName == self.L["Necrotic Lash"] then
		if self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), GameLib.GetUnitById(nId)) <= 40 then
			mod:AddMsg("CASTTEXT", self.L["Necrotic Lash"], 5, true and "Inferno")
		end
	elseif sCastName == self.L["Deathwail"] then
		mod:AddMsg("CASTTEXT", self.L["Deathwail"], 5, true and "Info")
	end
end

function mod:OnUnitCreated(nId, unit, sName)
	if(unit:GetMaxHealth() and unit:GetMaxHealth() > 100000 and nSwabbieId) then
		local swabbie = GameLib.GetUnitById(nSwabbieId)
		local currentPos = swabbie:GetPosition()
	end
	
    if sName == self.L["Swabbie Ski'Li"] and unit:GetMaxHealth() then
		nSwabbieId = nId
		core:AddUnit(unit)
		core:WatchUnit(unit)
    elseif sName == self.L["Sawblade"] then
		core:AddPixie(nId, 2, unit, nil, "xkcdBrightPurple", 15, 70, 0)
	elseif (bLinesDrawn and (
			sName == self.L["Risen Redmoon Cadet"] or sName == self.L["Bilious Brute"] or 
			sName == self.L["Putrid Pouncer"] or sName == self.L["Risen Redmoon Grunt"] or 
			sName == self.L["Noxious Nabber"] or sName == self.L["Bilious Brute"]
			)) then
		mod:removeLastTriggerLine()
	elseif sName == self.L["Bubbles"] then
		core:AddPolygon(nId, nId, 6.5, 0, 6, "xkcdBlue", 24)
	end
end