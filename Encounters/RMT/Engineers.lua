----------------------------------------------------------------------------------------------------
-- Engineers encounter script
--
-- Copyright (C) 2016 Joshua Shaffer
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Engineers", 999, 999, 999)
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
    -- Datachron messages.
    -- Cast.
    -- Bar and messages.
    ["Shoot the orb!"] = "Shoot the orb!",
})

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF__ELECTROSHOCK_VULNERABILITY = 83798 --2nd shock -> death
local DEBUFF__ATOMIC_SPEAR = 70161 --Something on Wilbaugh tank?
local DEBUFF__OIL_SLICK = 84072 --Sliding platform debuff

----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local bWave1Spawned

local tPillars

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
        local nFusionCoreId = tPillars[self.L["Fusion Core"]]
        local tFusionCoreUnit = GameLib.GetUnitById(nFusionCoreId)
        if tFusionCoreUnit then
            core:AddUnit(tFusionCoreUnit)
            core:WatchUnit(tFusionCoreUnit)
        else
            Log:Add("ERROR", "Combat started but no Lubricant Fusion Core")
            mod:AddMsg("ERROR", "Missing pillars!", 20, "Alarm")
        end
        
        
        local nCollingTurbineId = tPillars[self.L["Cooling Turbine"]]
        local tCoolingTurbineUnit = GameLib.GetUnitById(nCollingTurbineId)
        if tCoolingTurbineUnit then
            core:AddUnit(tCoolingTurbineUnit)
            core:WatchUnit(tCoolingTurbineUnit)
        else
            Log:Add("ERROR", "Combat started but no Cooling Turbine")
            mod:AddMsg("ERROR", "Missing pillars!", 20, "Alarm")
        end
        
        local nSparkPlugId = tPillars[self.L["Spark Plug"]]
        local tSparkPlugUnit = GameLib.GetUnitById(nSparkPlugId)
        if tSparkPlugUnit then
            core:AddUnit(tSparkPlugUnit)
            core:WatchUnit(tSparkPlugUnit)
        else
            Log:Add("ERROR", "Combat started but no Spark Plug")
            mod:AddMsg("ERROR", "Missing pillars!", 20, "Alarm")
        end
        
        local nLubricantNozzleId = tPillars[self.L["Lubricant Nozzle"]]
        local tLubricantNozzleUnit = GameLib.GetUnitById(nLubricantNozzleId)
        if tLubricantNozzleUnit then
            core:AddUnit(tLubricantNozzleUnit)
            core:WatchUnit(tLubricantNozzleUnit)
        else
            Log:Add("ERROR", "Combat started but no Lubricant Nozzle")
            mod:AddMsg("ERROR", "Missing pillars!", 20, "Alarm")
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
                if not tPillars[sName] then
                    tPillars[sName] = tUnit:GetId();
                end
        end
    end
end


function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    --if self.L["Robomination"] == sName then
    --    if self.L["Noxious Belch"] == sCastName then
    --        mod:AddMsg("BELCH", "Noxious Belch", 5, "Beware")
    --    end
    --end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Head Engineer Orvulgh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
    elseif sName == self.L["Chief Engineer Wilbargh"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
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
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    --if sName == self.L["Air Current"] then
    --    core:RemovePixie("TORNADO" .. nId)
    --end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    --local tUnit = GameLib.GetUnitById(nId)
    --local player = GameLib.GetPlayerUnit()
    
    if DEBUFF__ELECTROSHOCK_VULNERABILITY == nSpellId then
        --if tUnit == player then
            --mod:AddMsg("ORBTARGET", self.L["ORB ON YOU!"], 5, "RunAway")
            --core:AddLineBetweenUnits("ORB", player:GetId(), nOrbId, 2, "red")
            --local chatMessage = tUnit:GetName() .. " got shocked debuff"
            --ChatSystemLib.Command("/p " .. chatMessage)
        --end
    end
end