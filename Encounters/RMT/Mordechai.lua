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
mod:RegisterDefaultSetting("TelegraphLines")
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
local DEBUFF__SHOCKING_ATTRACTION = 86861 -- Shuriken-Link
local DEBUFF__MOO = 85559 -- MoO


----------------------------------------------------------------------------------------------------
-- Locals.
----------------------------------------------------------------------------------------------------
local bWave1Spawned, bWave2Spawned, bWave3Spawned, bMiniSpawned

local nMordechaiId
local phase
local airlock1Warn, airlock2Warn

----------------------------------------------------------------------------------------------------
-- Encounter description.
----------------------------------------------------------------------------------------------------
function mod:OnBossEnable()
    mod:AddTimerBar("ORBSPAWN", "Next Orb", 25, mod:GetSetting("OrbCountdown"))
    airlock1Warn = false
    airlock2Warn = false
	local stackPointPos = Vector3.New(109, 353, 175)
	core:AddPicture("StackStars", stackPointPos, "Crosshair", 100, nil, nil, nil, "red")
	core:SetWorldMarker("StackStarsText", "STACK HERE", stackPointPos)
end

function mod:OnHealthChanged(nId, nPercent, sName)
    if sName == self.L["Mordechai Redmoon"] then
        if nPercent >= 85 and nPercent <= 87 and not airlock1Warn then
            airlock1Warn = true
           -- mod:AddMsg("AIRLOCKWARN", self.L["Airlock soon!"], 5, mod:GetSetting("AirlockWarningSound") and "Algalon")
        elseif nPercent >= 60 and nPercent <= 62 and not airlock2Warn then
            airlock2Warn = true
            --mod:AddMsg("AIRLOCKWARN", self.L["Airlock soon!"], 5, mod:GetSetting("AirlockWarningSound") and "Algalon")
        end
    end
end

function mod:OnCastStart(nId, sCastName, nCastEndTime, sName)
	phase = 1
    if self.L["Mordechai Redmoon"] == sName then
        if self.L["Shatter Shock"] == sCastName then
            -- mod:AddMsg("SHATTERSHOCK", "Stars Icoming!", 5, mod:GetSetting("StarsWarning") and "Beware")
			mod:AddTimerBar("SHURIKEN", "Next Shuriken", 21, mod:GetSetting("OrbCountdown")) --21 seconds between shuriken casts
        end
		if "Vicious Barrage" == sCastName then
            -- mod:AddMsg("SHATTERSHOCK", "Stars Icoming!", 5, mod:GetSetting("StarsWarning") and "Beware")
			mod:AddTimerBar("BARRAGE", "Vicious Barrage", 42) -- 45 seconds between shuriken casts
        end
    end
end

function mod:OnCastEnd(nId, sCastName, nCastEndTime, sName)
    if self.L["Mordechai Redmoon"] == sName then
        if self.L["Moment of Opportunity"] == sCastName then
            mod:AddTimerBar("ORBSPAWN", "Next Orb", 15, mod:GetSetting("OrbCountdown")) --15 seconds to orb after airlock MoO ends
            mod:AddTimerBar("SHURIKEN", "Next Shuriken", 9, mod:GetSetting("OrbCountdown")) -- 9 seconds to shuriken after airlock MoO ends
        end
    end
end

function mod:OnUnitCreated(nId, tUnit, sName)
    local player = GameLib.GetPlayerUnit()
    
    if sName == self.L["Mordechai Redmoon"] then
        core:AddUnit(tUnit)
        core:WatchUnit(tUnit)
        nMordechaiId = nId
		
		local Offset = 3
		local Angle = 24
		local OffsetAngle = 90
		local Length = 30
		
		local Angle1 = 32.65
		local Offset1 = 5.08
		
		
		-- cleave lines
		if mod:GetSetting("TelegraphLines") then
			core:AddSimpleLine("Front Right Cleave", nMordechaiId, Offset1, Length, Angle, 8, "white", nil, (OffsetAngle - Angle1))
			core:AddSimpleLine("Front Left Cleave", nMordechaiId, Offset1, Length, -Angle, 8, "white", nil, -(OffsetAngle - Angle1))
			
			core:AddSimpleLine("Back Right Cleave", nMordechaiId, Offset1, Length, 180 - Angle, 8, "white", nil, (OffsetAngle + Angle1))
			core:AddSimpleLine("Back Left Cleave", nMordechaiId, Offset1, Length, 180 + Angle, 8, "white", nil, -(OffsetAngle + Angle1))
			
			core:AddSimpleLine("Front Right Middle Cleave", nMordechaiId, Offset+2.5, 3, -Angle, 8, "white", nil, OffsetAngle)
			core:AddSimpleLine("Front Left Middle Cleave", nMordechaiId, Offset+2.5, 3, Angle, 8, "white", nil, -OffsetAngle)
			
			core:AddSimpleLine("Back Right Middle Cleave", nMordechaiId, Offset+2.5, 3, 180 + Angle, 8, "white", nil, OffsetAngle)
			core:AddSimpleLine("Back Left Middle Cleave", nMordechaiId, Offset+2.5, 3, 180 - Angle, 8, "white", nil, -OffsetAngle)
			
			--core:AddSimpleLine("Circle Left Cleave", nMordechaiId, Offset+2, 3, 180 - Angle, 8, "white", nil, -OffsetAngle)
			--core:AddSimpleLine("Circle Left Cleave", nMordechaiId, Offset+2, 3, Angle, 8, "white", nil, -OffsetAngle)
			--core:AddSimpleLine("Circle Right Cleave", nMordechaiId, Offset+2, 3, 180 + Angle, 8, "white", nil, OffsetAngle)
			--core:AddSimpleLine("Circle Right Cleave", nMordechaiId, Offset+2, 3, - Angle, 8, "white", nil, OffsetAngle)
			--core:AddSimpleLine("Back Right Cleave",  nMordechaiId, Offset, Length, 180 - Angle, 8, "white", nil, OffsetAngle)
		end	
		--core:AddSimpleLine("Front Left Cleave", nMordechaiId, Offset, Length, Angle, 8, "white", nil, -OffsetAngle)
		--Wcore:AddSimpleLine("Back Left Cleave",  nMordechaiId, Offset, Length, 180 - Angle, 8, "white", nil, -OffsetAngle)
    elseif sName == self.L["Kinetic Orb"] then
        mod:AddTimerBar("ORBSPAWN", "Next Orb", 25, mod:GetSetting("OrbCountdown"))
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
		-- Print("Kinetic Link on ".. tUnit:GetName())
		core:AddPicture("orb crosshair" .. tostring(nId), nId, "Crosshair", 30, 0, 0, 0, "red")

        if tUnit == player then
            mod:AddMsg("SHOOTORB", self.L["Shoot the orb!"], 5, mod:GetSetting("OrbWarningSounds") and "Beware")
            if mod:GetSetting("OrbLines") then
                core:AddLineBetweenUnits("ORB" .. nId, player:GetId(), nOrbId, 5, "Green")
            end
        end
		
	elseif DEBUFF__SHOCKING_ATTRACTION == nSpellId then
		core:AddPicture("shuriken debuff" .. tostring(nId), nId, "Crosshair", 30, 0, 0, 0, "white")
		if tUnit == player then
            mod:AddMsg("SHURIKEN", "MOVE TO THE RIGHT", 5, mod:GetSetting("OrbWarningSounds") and "Destruction")
		end
    end
end

function mod:OnDebuffRemove(nId, nSpellId)
	if DEBUFF__KINETIC_LINK == nSpellId then
		core:RemovePicture("orb crosshair" .. tostring(nId))
	elseif DEBUFF__SHOCKING_ATTRACTION == nSpellId then
		core:RemovePicture("shuriken debuff" .. tostring(nId))
    end
end

function mod:OnBuffRemove(nId, nSpellId)
	if nId == nMordechaiId then
		if nSpellId == DEBUFF__MOO then
			phase = phase + 1
			mod:AddTimerBar("ORBSPAWN", "Next Orb", 15, mod:GetSetting("OrbCountdown")) --15 seconds to orb after airlock MoO ends
			mod:AddTimerBar("SHURIKEN", "Next Shuriken", 9, mod:GetSetting("OrbCountdown")) -- 9 seconds to shuriken after airlock MoO ends
			if phase >= 3 then
				mod:AddTimerBar("BARRAGE", "Vicious Barrage", 32) --32 seconds to Barrage after 2nd airlock MoO ends
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