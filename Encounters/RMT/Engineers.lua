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
local electroshockTimer = nil 
local electroshockCounter = 0
local electroshockAngleCounter = 0

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
	
	electroshockTimer = ApolloTimer.Create(10, true, "electroshockLines", mod)

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
 

    if sName == self.L["Fusion Core"] or
        sName == self.L["Cooling Turbine"] or
        sName == self.L["Spark Plug"] or
        sName == self.L["Lubricant Nozzle"] then
			local distanceToPlayer = self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), tUnit)
			
			
			
            if nPercent >= 85 and not tPillars[sName].warning then
                local player = GameLib.GetPlayerUnit()
                tPillars[sName].warning = true
                mod:AddMsg("PILLARWARN", self.L["%s pillar at N%!"]:format(sName), 5, mod:GetSetting("PillarWarningSound") and "Destruction")
                core:AddLineBetweenUnits(nId, player:GetId(), nId, 5, "red")
            elseif nPercent <= 80 then
                tPillars[sName].warning = false
                core:RemoveLineBetweenUnits(nId)
            end
			
			local sumHealthPercent = 0
			local healthPercent = 0
			local uPillar
			for k in pairs(tPillars) do
				--uPillar = GameLib.GetUnitById(tPillars[k]["id"])
				--healthPercent = uPillar:GetHealth() / uPillar:GetHealthCeiling()
				--sumHealthPercent = sumHealthPercent + healthPercent*100
			end
			-- mod:AddMsg("pillars", "Combined health at ".. tostring(sumHealthPercent), 2, false)
			--Print(tostring(distanceToPlayer))
			--Print("Pillar Health Change")
			--Print(sName)
			if distanceToPlayer < 55 then
				
				core:SetWorldMarker(sName .. "hptext", nPercent, GameLib.GetUnitById(nId):GetPosition())
				if nPercent < lastPillarHealth and nPercent < 20 and not disablePillarWarning then
					mod:AddMsg("PILLAR", "Watch Pillar Health", 5, "Beware")
					disablePillarWarning = true
				elseif nPercent >= 20.5 then
					disablePillarWarning = false
				end
				if nPercent < lastPillarHealth and nPercent < 13 then
					mod:AddMsg("PILLAR", "Watch Pillar Health", 5, "Info")
				end
				lastPillarHealth = nPercent
			end
    end
end

function mod:OnBossDisable()
	mod:removeElectroshockLines()
	if electroshockTimer then
		electroshockTimer:Stop()
	end
	electroshockTimer = nil
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if sCastName == self.L["Electroshock"] and self:GetDistanceBetweenUnits(GameLib.GetPlayerUnit(), tOrvulgh) < 60 then
		mod:AddTimerBar("Electroshock", "Electroshock", 20 , true, { sColor = "blue" })
	end
end

function mod:onCastEnd(nId, sCastName, isInterrupted, sName)
    if sCastName == self.L["Electroshock"] then
		mod:removeElectroshockLines()
		if electroshockTimer then
			electroshockTimer:Stop()
		end
		electroshockTimer = nil
		mod:removeElectroshockLines()
		electroshockTimer = ApolloTimer.Create(14, true, "electroshockLines", mod)
	end
end

function mod:OnNPCSay(sMessage)
	if sMessage == "Time fer a change o' scenery!" then
		mod:removeElectroshockLines()
		if electroshockTimer then
			electroshockTimer:Stop()
		end
		electroshockTimer = nil

		electroshockTimer = ApolloTimer.Create(5, true, "electroshockLines", mod)
	end
end

-- dirty electrocute tracking hack... any better ideas?
function mod:electroshockLines()
	local tPartyUnit
	for i = 1, 20, 1 do
		tPartyUnit = GroupLib.GetUnitForGroupMember(i)
		if self:GetDistanceBetweenUnits(tOrvulgh, tPartyUnit) < 60 then
			--Print(i)
			core:AddLineBetweenUnits("player" .. tostring(i), tPartyUnit:GetId(), tOrvulgh:GetId())
		end
	end
	--electroshockTimer:Stop()
	electroshockTimer = nil
end

function mod:removeElectroshockLines()
	local tPartyUnit
	for i = 1, 20, 1 do
		tPartyUnit = GroupLib.GetUnitForGroupMember(i)
		core:RemoveLineBetweenUnits("player" .. tostring(i))
	end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Head Engineer Orvulgh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		tOrvulgh = tUnit
		core:AddPixie(nId .. "_1", 2, tUnit, nil, "Green", 20, 20, 0)
    elseif sName == self.L["Chief Engineer Wilbargh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
		tWillbargh = tUnit
        core:AddPixie(nId .. "_1", 2, tUnit, nil, "Green", 20, 20, 45)
        core:AddPixie(nId .. "_2", 2, tUnit, nil, "Green", 20, 20, 315)
    elseif sName == self.L["Air Current"] then --Track these moving?
        core:AddPixie(nId, 2, tUnit, nil, "Yellow", 5, 15, 0)
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

function mod:OnDebuffRemove(nId, nSpellId, nStack, fTimeRemaining)
	if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
		core:RemovePicture(nId)
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
			mod:AddMsg("PlasmaBallElse", "Plasma Ball on " .. GameLib.GetUnitById(nId):GetName(), 5)
		end
		-- core:AddLineBetweenUnits("ORB", player:GetId(), nOrbId, 2, "red")
	end
	

	
    if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
		if nId == tPlayerUnit:GetId() then
			mod:AddTimerBar("ElectroshockReturn", "Electroshock Return", 55 , "RunAway", { sColor = "red" })
			mod:AddTimerBar("ElectroshockLeave", "Electroshock LEAVE", 10 , "RunAway", { sColor = "red" })
		end
		mod:removeElectroshockLines()
		core:AddPicture(nId, nId, "Crosshair", 30)

	end
end