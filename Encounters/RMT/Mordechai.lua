----------------------------------------------------------------------------------------------------
-- Mordechai Redmoon encounter script
--
-- Copyright (C) 2016 Joshua Shaffer
----------------------------------------------------------------------------------------------------
local core = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("RaidCore")
local mod = core:NewEncounter("Mordecai", 104, 0, 548)
if not mod then return end

mod:RegisterTrigMob("ANY", { "Mordechai Redmoon" })
mod:RegisterEnglishLocale({
    -- Unit names.
    ["Mordechai Redmoon"] = "Mordechai Redmoon",
	["Kinetic Orb"] = "Kinetic Orb",
    ["Airlock Anchor"] = "Airlock Anchor",
    ["Airlock Junk"] = "Airlock Junk",
    
    --This thing might be the star telegraph unit... maybe?
    ["star telegraph unit"] = "Ignores Collision Big Base Invisible Unit for Spells (1 hit radius)",
    -- Datachron messages.
    ["The airlock has been closed!"] = "The airlock has been closed!",
    ["The airlock has been opened!"] = "The airlock has been opened!",
    -- Cast.
    -- Bar and messages.
    ["Airlock soon!"] = "Airlock soon!",
    ["Shoot the orb!"] = "Shoot the orb!",
    ["ORB ON YOU!"] = "ORB ON YOU!",
})


mod:RegisterDefaultSetting("OrbLines")
mod:RegisterDefaultSetting("AnchorLines")
mod:RegisterDefaultSetting("OrbWarningSounds")
mod:RegisterDefaultSetting("OrbCountdown")
mod:RegisterDefaultSetting("StarsWarning")
mod:RegisterDefaultSetting("AirlockWarningSound")

----------------------------------------------------------------------------------------------------
-- Constants.
----------------------------------------------------------------------------------------------------
local DEBUFF__NULLIFIED = 85614 --negative 100% DPS debuff
local DEBUFF__KINETIC_LINK = 86797 -- dps target orb
local DEBUFF__KINETIC_FIXATION = 85566 -- tank target
local DEBUFF__ANCHOR_LOCKDOWN = 85601 -- ?
local DEBUFF__DECOMPRESSION = 75340 -- ?
local DEBUFF__ENDORPHIN_RUSH = 35023 -- ?
local DEBUFF__SHATTER_SHOCK = 86755 --Star stun?


----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local bWave1Spawned, bWave2Spawned, bWave3Spawned, bMiniSpawned

local nMordecaiId

local airlock1Warn, airlock2Warn

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    mod:AddTimerBar("ORBSPAWN", "Orb Spawn", 25, mod:GetSetting("OrbCountdown"))
    airlock1Warn = false
    airlock2Warn = false
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
end

function mod:OnHealthChanged(nId, nPercent, sName)
    if sName == self.L["Mordechai Redmoon"] then
        if nPercent >= 85 and nPercent <= 87 and not airlock1Warn then
            airlock1Warn = true
            mod:AddMsg("AIRLOCKWARN", self.L["Airlock soon!"], 5, mod:GetSetting("AirlockWarningSound") and "Algalon")
        elseif nPercent >= 60 and nPercent <= 62 and not airlock2Warn then
            airlock2Warn = true
            mod:AddMsg("AIRLOCKWARN", self.L["Airlock soon!"], 5, mod:GetSetting("AirlockWarningSound") and "Algalon")
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
    if self.L["Mordechai Redmoon"] == sName then
        if self.L["Shatter Shock"] == sCastName then
            mod:AddMsg("SHATTERSHOCK", "Stars Icoming!", 5, mod:GetSetting("StarsWarning") and "Beware")
        end
    end
end

function mod:OnCastEnd(nId, sCastName, nCastEndTime, sName)
    if self.L["Mordechai Redmoon"] == sName then
        if self.L["Moment of Opportunity"] == sCastName then
            mod:AddTimerBar("ORBSPAWN", "Orb Spawn", 15, mod:GetSetting("OrbCountdown")) --15 seconds to orb after airlock MoO ends
        end
    end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Mordechai Redmoon"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        nMordecaiId = nId
    elseif sName == self.L["Kinetic Orb"] then
        mod:AddTimerBar("ORBSPAWN", "Orb Spawn", 25, mod:GetSetting("OrbCountdown"))
        core:AddUnit(tUnit)
    elseif sName == self.L["Airlock Anchor"] then
        if mod:GetSetting("AnchorLines") then
            core:AddLineBetweenUnits(nId, player:GetId(), nId, 5, "Green")
        end
    elseif sName == self.L["star telegraph unit"] then
        --core:AddPixie(nId, 2, tUnit, nil, "Yellow", 5, 20, 0)
    end
end

function mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Kinetic Orb"] then
        core:RemoveLineBetweenUnits("ORB" .. nId)
    elseif sName == self.L["Airlock Anchor"] then
        core:RemoveLineBetweenUnits(nId)
    end
end

function mod:OnDebuffAdd(nId, nSpellId, nStack, fTimeRemaining)
    local tUnit = GameLib.GetUnitById(nId)
    local player = GameLib.GetPlayerUnit()
    
    if DEBUFF__KINETIC_FIXATION == nSpellId then
        if tUnit == player then
            mod:AddMsg("ORBTARGET", self.L["ORB ON YOU!"], 5, mod:GetSetting("OrbWarningSounds") and "RunAway")
            if mod:GetSetting("OrbLines") then
                core:AddLineBetweenUnits("ORB" .. nId, player:GetId(), nOrbId, 5, "Red")
            end
        end
    elseif DEBUFF__KINETIC_LINK == nSpellId then
		Print("Kinetic Link on ".. tUnit:GetName())
        if tUnit == player then
            mod:AddMsg("SHOOTORB", self.L["Shoot the orb!"], 5, mod:GetSetting("OrbWarningSounds") and "Destruction")
            if mod:GetSetting("OrbLines") then
                core:AddLineBetweenUnits("ORB" .. nId, player:GetId(), nOrbId, 5, "Green")
            end
        end
    end
end

function mod:OnDatachron(sMessage)
    if sMessage:find(self.L["The airlock has been opened!"]) then
        mod:AddTimerBar("AIRLOCK", "Airlock", 20, nil)
        mod:RemoveTimerBar("ORBSPAWN")
    end
end