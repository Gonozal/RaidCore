----------------------------------------------------------------------------------------------------
-- Engineers encounter script
--
-- Copyright (C) 2016 Joshua Shaffer
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Engineers", 104, 548, 552)
local Log = Apollo.GetPackage("Log-1.0").tPackage
if not mod then return end

mod:RegisterTrigMob("ANY", { "Head Engineer Orvulgh", "Chief Engineer Wilbargh" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Fusion Core"] = "Fusion Core",
	["Cooling Turbine"] = "Cooling Turbine",
    ["Spark Plug"] = "Spark Plug",
    ["Lubricant Nozzle"] = "Lubricant Nozzle",
    ["Head Engineer Orvulgh"] = "Head Engineer Orvulgh",
    ["Chief Engineer Wilbargh"] = "Chief Engineer Wilbargh",
    ["Air Current"] = "Air Current", --Tornado units?
	["Electroshock"] = "Electroshock",
	["Discharged Plasma"] = "Discharged Plasma",
    -- Datachron messages.
    -- Cast.
    -- Bar and messages.
    ["%s pillar at N%!"] = "%s pillar at 85%!"
})

local lastPillarHealth = 29
local disablePillarWarning = false

mod:RegisterDefaultSetting("PillarWarningSound")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF__ELECTROSHOCK_VULNERABILITY = 83798 --2nd shock -> death
local DEBUFF__OIL_SLICK = 84072 --Sliding platform debuff
local DEBUFF__ATOMIC_ATTRACTION = 84053 -- plasma ball

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local bWave1Spawned

local tPillars
local tOrvulgh
local tWillbargh

------------
-- Raw event handlers
---------
Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreatedRaw", mod)


----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    --mod:AddTimerBar("ORBSPAWN", "Orb Spawn", 45, nil) 
    --30s to orb after airlock phase
    
    --These don't fire combat start (or combat logs in general?) so we have to do this the hard way with UnitCreated
    if tPillars then
        local nFusionCoreId = tPillars[self.L["Fusion Core"]].id
        local tFusionCoreUnit = GameLib.GetUnitById(nFusionCoreId)
        if tFusionCoreUnit then
            core:AddUnit(tFusionCoreUnit)
            core:WatchUnit(tFusionCoreUnit)
        else
            Log:Add("ERROR", "Combat started but no Lubricant Fusion Core")
            mod:AddMsg("ERROR", "Missing pillars!", 10, "Alarm")
        end
        
        
        local nCollingTurbineId = tPillars[self.L["Cooling Turbine"]].id
        local tCoolingTurbineUnit = GameLib.GetUnitById(nCollingTurbineId)
        if tCoolingTurbineUnit then
            core:AddUnit(tCoolingTurbineUnit)
            core:WatchUnit(tCoolingTurbineUnit)
        else
            Log:Add("ERROR", "Combat started but no Cooling Turbine")
            mod:AddMsg("ERROR", "Missing pillars!", 10, "Alarm")
        end
        
        local nSparkPlugId = tPillars[self.L["Spark Plug"]].id
        local tSparkPlugUnit = GameLib.GetUnitById(nSparkPlugId)
        if tSparkPlugUnit then
            core:AddUnit(tSparkPlugUnit)
            core:WatchUnit(tSparkPlugUnit)
        else
            Log:Add("ERROR", "Combat started but no Spark Plug")
            mod:AddMsg("ERROR", "Missing pillars!", 10, "Alarm")
        end
        
        local nLubricantNozzleId = tPillars[self.L["Lubricant Nozzle"]].id
        local tLubricantNozzleUnit = GameLib.GetUnitById(nLubricantNozzleId)
        if tLubricantNozzleUnit then
            core:AddUnit(tLubricantNozzleUnit)
            core:WatchUnit(tLubricantNozzleUnit)
        else
            Log:Add("ERROR", "Combat started but no Lubricant Nozzle")
            mod:AddMsg("ERROR", "Missing pillars!", 10, "Alarm")
        end
    end
end

function mod:OnUnitCreatedRaw(tUnit)
    tPillars = tPillars or {}
    
    if tUnit then        
        local sName = tUnit:GetName()
        if sName == self.L["Fusion Core"] or
            sName == self.L["Cooling Turbine"] or
            sName == self.L["Spark Plug"] or
            sName == self.L["Lubricant Nozzle"] then
                tPillars[sName] = {id = tUnit:GetId()}
        end
    end
end

function mod:OnHealthChanged(nId, nPercent, sName)
	local tUnit = GameLib.GetUnitById(nId)
	local distanceToPlayer = self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), tUnit)
 

    if sName == self.L["Fusion Core"] or
        sName == self.L["Cooling Turbine"] or
        sName == self.L["Spark Plug"] or
        sName == self.L["Lubricant Nozzle"] then
            if nPercent >= 85 and not tPillars[sName].warning then
                local player = GameLib.GetPlayerUnit()
                tPillars[sName].warning = true
                mod:AddMsg("PILLARWARN", self.L["%s pillar at N%!"]:format(sName), 5, mod:GetSetting("PillarWarningSound") and "Destruction")
                core:AddLineBetweenUnits(nId, player:GetId(), nId, 5, "red")
            elseif nPercent <= 80 then
                tPillars[sName].warning = false
                core:RemoveLineBetweenUnits(nId)
            end
			
			if distanceToPlayer < 55 then
				if nPercent < lastPillarHealth and nPercent < 20 and not disablePillarWarning then
					mod:AddMsg("PILLAR", "Watch Pillar Health", 5, "Beware")
					disablePillarWarning = true
				elseif nPercent >= 20.5 then
					disablePillarWarning = false
				end
				
				lastPillarHealth = nPercent
			end
    end
	
	
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sCastName == self.L["Electroshock"] and self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), tOrvulgh) < 60 then
		mod:AddTimerBar("Electroshock", "Electroshock", 20 , true, { sColor = "blue" })
	end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Head Engineer Orvulgh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		tOrvulgh = tUnit
    elseif sName == self.L["Chief Engineer Wilbargh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		tWillbargh = tUnit
    elseif sName == self.L["Air Current"] then --Track these moving?
        core:AddPixie(nId, 2, tUnit, nil, "Yellow", 5, 15, 0)
        
     --These don't fire enter combat or created, but need to figure out how to track their HP
    -- elseif sName == self.L["Fusion Core"] then
        -- core:AddUnit(tUnit)
        -- core:WatchUnit(tUnit)
    -- elseif sName == self.L["Cooling Turbine"] then
        -- core:AddUnit(tUnit)
        -- core:WatchUnit(tUnit)
    -- elseif sName == self.L["Spark Plug"] then
        -- core:AddUnit(tUnit)
        -- core:WatchUnit(tUnit)
    -- elseif sName == self.L["Lubricant Nozzle"] then
        -- core:AddUnit(tUnit)
        -- core:WatchUnit(tUnit)
    end
	
	if sName == self.L["Discharged Plasma"] and self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), tUnit) < 60 then 
		mod:AddTimerBar("ENGIDP", "Next Plasma Ball", 23)
	end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    --if sName == self.L["Air Current"] then
    --    core:RemovePixie("TORNADO" .. nId)
    --end
end

function  mod:OnDebuffRemove(nId, nSpellId, nStack, fTimeRemaining)
	if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
		core:AddPicture(nId, nId, "Crosshair", 30)
	end
end


function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    --local tUnit = GameLib.GetUnitById(nId)
    --local player = GameLib.GetPlayerUnit()
	local tPlayerUnit = GameLib.GetPlayerUnit()
	local tTargetUnit = GameLib.GetUnitById(nId)
	
	
	if nSpellId == DEBUFF__ATOMIC_ATTRACTION then
		if nId == tPlayerUnit:GetId() then
			mod:AddMsg("PlasmaBall", "Plasma Ball on you!", 5, "RunAway")
			mod:AddTimerBar("PlasmaBallExpired", "Run into Plasmaball in...", 15 , "Inferno", { sColor = "red" })			
		else
			mod:AddMsg("PlasmaBallElse", "Plasma Ball on" + GameLib.GetUnitById(nId):GetName(), 5)
		end
		-- core:AddLineBetweenUnits("ORB", player:GetId(), nOrbId, 2, "red")
	end
	

	
    if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
		if nId == tPlayerUnit:GetId() then
			mod:AddTimerBar("ElectroshockReturn", "Electroshock Return", 55 , "RunAway", { sColor = "red" })
			mod:AddTimerBar("ElectroshockLeave", "Electroshock LEAVE", 10 , "RunAway", { sColor = "red" })

			--if tUnit == player then
				--mod:AddMsg("ORBTARGET", self.L["ORB ON YOU!"], 5, "RunAway")
				--core:AddLineBetweenUnits("ORB", player:GetId(), nOrbId, 2, "red")
				--local chatMessage = tUnit:GetName() .. " got shocked debuff"
				--ChatSystemLib.Command("/p " .. chatMessage)
			--end
		end
		core:AddPicture(nId, nId, "Crosshair", 30)
	end
end