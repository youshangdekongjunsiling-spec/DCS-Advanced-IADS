-- === EA-18G EW Script by Timberwolf ===
-- Requires MIST to be loaded before this script
trigger.action.outText("Timberwolf's EA-18G EW Script Loaded", 10)

local jammerUnits = {
  "Growler"
}

local jammerSettings = {}
local jammerGroupIDs = {}
local jammerMenus = {}
local spotTargetMenus = {}
local spotTargetCommands = {}
local emitterCapacity = {}
local maxEmitterCapacity = {}
local defaultMaxCapacity = 0
local regenRate = 20
local drainRateArea = 15
local drainRateDirectional = 5
local jammerUpdateInterval = 5
local menuCheckInterval = 2
local reportInterval = 20
local overheatThreshold = 15
local lastReportTime = {}
local trackedMissiles = {}
local missileUID = 1
local suppressedSAMs = {}

local function get3DDist(p1, p2)
    local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    local dz = p1.z - p2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getClockBearing(jammerUnit, missilePos)
    if not jammerUnit or not jammerUnit:isExist() then return "?" end
    local jammerPos = jammerUnit:getPosition().p
    local heading = mist.getHeading(jammerUnit)
    local dx = missilePos.x - jammerPos.x
    local dz = missilePos.z - jammerPos.z
    local angleToMissile = math.atan2(dz, dx)
    local relAngle = angleToMissile - heading
    if relAngle < 0 then relAngle = relAngle + 2 * math.pi end
    local hours = math.floor((relAngle / (2 * math.pi)) * 12 + 0.5)
    if hours == 0 then hours = 12 end
    return hours .. " o'clock"
end

local function debugEmitterCapacity(jammer)
    local msg = jammer .. " Jammer capacity: " .. emitterCapacity[jammer] .. "/" .. maxEmitterCapacity[jammer]
    local active = {}
    if jammerSettings[jammer].defensive then table.insert(active, "defensive area jamming") end
    if jammerSettings[jammer].offensive then table.insert(active, "offensive area jamming") end
    if jammerSettings[jammer].defDir then table.insert(active, "defensive " .. jammerSettings[jammer].defDir) end
    if jammerSettings[jammer].offDir then table.insert(active, "offensive " .. jammerSettings[jammer].offDir) end
    if #active > 0 then
        msg = msg .. " | Active: " .. table.concat(active, ", ")
    end
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], msg, 4)
end
end

local EW_EventHandler = {}
function EW_EventHandler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT and event.weapon then
        local desc = event.weapon:getDesc()
        if desc and (desc.guidance == 3 or desc.guidance == 4) then
            local target = Weapon.getTarget(event.weapon)
            if target and target:isExist() then
                trackedMissiles[missileUID] = {
                    missile = event.weapon,
                    target = target,
                    uid = missileUID
                }
                missileUID = missileUID + 1
            end
        end
    end
end
world.addEventHandler(EW_EventHandler)

local function isInSector(jammerUnit, targetPos, sector)
    if not jammerUnit or not jammerUnit:isExist() then return false end
    local jammerPos = jammerUnit:getPosition().p
    local heading = mist.getHeading(jammerUnit)
    local dx = targetPos.x - jammerPos.x
    local dz = targetPos.z - jammerPos.z
    local angleToTarget = math.deg(math.atan2(dz, dx))
    local relAngle = (angleToTarget - math.deg(heading)) % 360
    if sector == "front" then return relAngle >= 315 or relAngle <= 45
    elseif sector == "right" then return relAngle > 45 and relAngle <= 135
    elseif sector == "rear" then return relAngle > 135 and relAngle <= 225
    elseif sector == "left" then return relAngle > 225 and relAngle < 315 end
    return false
end

local function defensiveLoop(jammer)
    local drain = jammerSettings[jammer].defensive and drainRateArea or drainRateDirectional
    if emitterCapacity[jammer] >= drain then
        emitterCapacity[jammer] = emitterCapacity[jammer] - drain
    end

    local unit = Unit.getByName(jammer)
    if not unit or not unit:isExist() then return end
    local pos = unit:getPoint()
    local spoofZones = {
        {dist = 37000, pkill = 50}, {dist = 27800, pkill = 70},
        {dist = 18500, pkill = 85}, {dist = 11100, pkill = 90},
        {dist = 5556,  pkill = 98}
    }
    for id, entry in pairs(trackedMissiles) do
        local m = entry.missile
        if m and Object.isExist(m) then
            local mpos = m:getPoint()
            local dist = get3DDist(pos, mpos)
            local allowed = jammerSettings[jammer].defensive or
                (jammerSettings[jammer].defDir and isInSector(unit, mpos, jammerSettings[jammer].defDir))
            if allowed then
                for _, zone in ipairs(spoofZones) do
                    if dist < zone.dist and math.random(100) <= zone.pkill then
                        local distNM = math.floor(dist / 1852)
                        local bearing = getClockBearing(unit, mpos)
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spoofed missile at ~" .. distNM .. " nm (" .. bearing .. ")", 4)
end
                        Object.destroy(m)
                        trackedMissiles[id] = nil
                        break
                    end
                end
            end
        else
            trackedMissiles[id] = nil
        end
    end
end

local function offensiveLoop(jammer)
    local unit = Unit.getByName(jammer)
    if not unit or not unit:isExist() then return end
    local jammerPos = unit:getPoint()
    for _, name in ipairs(mist.makeUnitTable({'[red][vehicle]', '[red][ship]'})) do
        local sam = Unit.getByName(name)
        if sam and sam:isExist() and sam:hasAttribute("SAM TR") then
            local samPos = sam:getPoint()
            local dist = get3DDist(jammerPos, samPos)
            local allowed = jammerSettings[jammer].offensive or
                (jammerSettings[jammer].offDir and isInSector(unit, samPos, jammerSettings[jammer].offDir))
            if allowed and dist < 50000 and land.isVisible(samPos, jammerPos) then
                local drain = jammerSettings[jammer].offensive and drainRateArea or drainRateDirectional
                if emitterCapacity[jammer] >= drain then
                    emitterCapacity[jammer] = emitterCapacity[jammer] - drain
                    local ctrl = sam:getGroup():getController()
                    ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
                    suppressedSAMs[name] = {sam = sam, lastSuppressed = timer.getTime()}
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "SAM suppressed by " .. jammer .. ": " .. name, 3)
end
                end
            end
        end
    end
end

local function restoreSAMs()
    for name, info in pairs(suppressedSAMs) do
        
        local sam = info.sam
        local stillSuppressed = false

        if info.spot then
            for _, jammer in ipairs(jammerUnits) do
                if jammerSettings[jammer] and jammerSettings[jammer].spotTarget == name then
                    local unit = Unit.getByName(jammer)
                    if unit and unit:isExist() and sam and sam:isExist() then
                        local jammerPos = unit:getPoint()
                        local samPos = sam:getPoint()
                        local maxCap = maxEmitterCapacity[jammer] or 0
                        local maxRange = maxCap >= 3000 and 148160 or 111120
                        if get3DDist(jammerPos, samPos) <= maxRange and land.isVisible(samPos, jammerPos) and emitterCapacity[jammer] > 15 then
                            stillSuppressed = true
                            break
                        end
                    end
                end
            end
        else
            stillSuppressed = (timer.getTime() - info.lastSuppressed <= 5)
        end

        if not stillSuppressed then
    
            local sam = info.sam
            if sam and sam:isExist() then
                local ctrl = sam:getGroup():getController()
                ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "SAM reactivated: " .. name, 3)
end
            end
            suppressedSAMs[name] = nil
        end
    end
end

local function jammerLoop()
    for _, jammer in ipairs(jammerUnits) do
        jammerSettings[jammer] = jammerSettings[jammer] or {}
        emitterCapacity[jammer] = emitterCapacity[jammer] or maxEmitterCapacity[jammer] or defaultMaxCapacity
        maxEmitterCapacity[jammer] = maxEmitterCapacity[jammer] or defaultMaxCapacity
        lastReportTime[jammer] = lastReportTime[jammer] or 0

        local active = false
        local totalDrain = 0

        -- Defensive drain
        if jammerSettings[jammer].defensive then
            totalDrain = totalDrain + drainRateArea
            active = true
        elseif jammerSettings[jammer].defDir then
            totalDrain = totalDrain + drainRateDirectional
            active = true
        end

        -- Offensive drain
        -- Spot jamming drain
        if jammerSettings[jammer].spotTarget then
            totalDrain = totalDrain + 30
            active = true
        end

        if jammerSettings[jammer].offensive then
            totalDrain = totalDrain + drainRateArea
            active = true
        elseif jammerSettings[jammer].offDir then
            totalDrain = totalDrain + drainRateDirectional
            active = true
        end

        -- Apply drain
        if active then
            emitterCapacity[jammer] = math.max(0, emitterCapacity[jammer] - totalDrain)
            debugEmitterCapacity(jammer)
        else
            -- Regen when idle
            emitterCapacity[jammer] = math.min(maxEmitterCapacity[jammer], emitterCapacity[jammer] + regenRate)
            if (timer.getTime() - lastReportTime[jammer] >= reportInterval) and emitterCapacity[jammer] < maxEmitterCapacity[jammer] then
                debugEmitterCapacity(jammer)
                lastReportTime[jammer] = timer.getTime()
            end
        end

        -- Overheat protection
        if emitterCapacity[jammer] <= overheatThreshold and active then
            jammerSettings[jammer].offensive = false
            jammerSettings[jammer].offDir = nil
            jammerSettings[jammer].defensive = false
            jammerSettings[jammer].defDir = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], jammer .. " jamming automatically shut down due to overheat", 4)
end
        end

        -- Run spoof/suppress logic AFTER draining
        -- Spot jamming logic
        if jammerSettings[jammer].spotTarget and emitterCapacity[jammer] > 15 then
            local unit = Unit.getByName(jammer)
            local targetGroup = Group.getByName(jammerSettings[jammer].spotTarget)
            if unit and unit:isExist() and targetGroup then
                local jammerPos = unit:getPoint()
                local targetUnits = targetGroup:getUnits()
                local targetUnit = nil
                for _, u in ipairs(targetUnits) do
                    if u:isExist() then
                        targetUnit = u
                        break
                    end
                end
                if targetUnit then
                    local targetPos = targetUnit:getPoint()
                    local dist = get3DDist(jammerPos, targetPos)
                    local los = land.isVisible(targetPos, jammerPos)
                    local altitudeBoost = math.min(unit:getPoint().y / 10000, 0.2)
                    local maxCap = maxEmitterCapacity[jammer] or 0
                    local maxRange = maxCap >= 3000 and 148160 or 111120
                    local fullEffectDist = maxCap >= 3000 and 101860 or 64820

                    if dist <= maxRange and los then
                        local probability = 0.2
                        if dist <= fullEffectDist then
                            probability = 1.0
                        else
                            probability = 0.2 + ((fullEffectDist / dist) * 0.8)
                        end
                        probability = math.min(probability + altitudeBoost, 1.0)

                        if math.random() < probability then
                            local ctrl = targetGroup:getController()
                            ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
                            suppressedSAMs[jammerSettings[jammer].spotTarget] = {
                                sam = targetUnit,
                                lastSuppressed = timer.getTime(),
                                spot = true
                            }
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming successful: " .. jammerSettings[jammer].spotTarget, 3)
end
                        else
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming attempt failed: " .. jammerSettings[jammer].spotTarget, 3)
end
                        end
                    else
                        jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming canceled: target out of range or LOS", 3)
end
                    end
                else
                    jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming canceled: target lost or destroyed", 3)
end
                end
            else
                jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming disabled: jammer or target not found", 3)
end
            end
        elseif jammerSettings[jammer].spotTarget and emitterCapacity[jammer] <= 15 then
            jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming disabled: emitter capacity depleted", 4)
end
        end

        if jammerSettings[jammer].defensive or jammerSettings[jammer].defDir then
            defensiveLoop(jammer)
        end
        if jammerSettings[jammer].offensive or jammerSettings[jammer].offDir then
            offensiveLoop(jammer)
        end
    end

    restoreSAMs()
    return timer.getTime() + jammerUpdateInterval
end


local function getBearing(from, to)
    local dx = to.x - from.x
    local dz = to.z - from.z
    local bearing = math.deg(math.atan2(dz, dx))
    if bearing < 0 then bearing = bearing + 360 end
    return math.floor(bearing + 0.5)
end

local function getNatoName(unit)
    local typeName = unit:getTypeName()
    local mapping = {
        ["S-300PS 40B6M tr"] = "SA-10",
        ["S-300PS 40B6MD sr"] = "SA-10",
        ["S-300PS 64H6E sr"] = "SA-10",
        ["SNR_75V"] = "SA-2",
        ["Kub STR"] = "SA-6",
        ["Tor 9A331"] = "SA-15",
        ["Buk SR 9S18M1"] = "SA-11",
        ["SA-11 Buk LN 9A310M1"] = "SA-11",
        ["SA-17 Buk M1-2 LN"] = "SA-17",
        ["Roland ADS"] = "Roland",
        ["Patriot str"] = "Patriot",
        ["Hawk tr"] = "Hawk",
        ["Hawk sr"] = "Hawk"
    }
    return mapping[typeName] or typeName
end

local function setupMenus()
    for _, jammer in ipairs(jammerUnits) do
        if not jammerMenus[jammer] then
            local unit = Unit.getByName(jammer)
            if unit and unit:isExist() then
                local gid = unit:getGroup():getID()
                jammerGroupIDs[jammer] = gid
                local root = missionCommands.addSubMenuForGroup(gid, "EW Jamming")
                jammerMenus[jammer] = true
                jammerMenus[jammer] = true

                -- Loadout menu (emitter capacity presets)
                local loadout = missionCommands.addSubMenuForGroup(gid, "Loadout", root)
                local presets = {
                    {label = "No Jammers", cap = 0},
                    {label = "1x ALQ-99", cap = 500},
                    {label = "2x ALQ-99", cap = 1000},
                    {label = "3x ALQ-99", cap = 1500},
                    {label = "2x ALQ-249", cap = 3000},
                    {label = "2x ALQ-249 + 1x ALQ-99", cap = 3500}
                }
                for _, p in ipairs(presets) do
                    missionCommands.addCommandForGroup(gid, p.label, loadout, function()
                        maxEmitterCapacity[jammer] = p.cap
                        emitterCapacity[jammer] = math.min(emitterCapacity[jammer], p.cap)
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], jammer .. " loadout set: " .. p.label, 4)
end
                    end)
                end

                -- Remaining menus unchanged...

                -- Area Defensive
                local dmenu = missionCommands.addSubMenuForGroup(gid, "Defensive Area Jamming", root)
                missionCommands.addCommandForGroup(gid, "On", dmenu, function()
                    jammerSettings[jammer].defensive = true
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Defensive area jamming enabled", 4)
end
                end)
                missionCommands.addCommandForGroup(gid, "Off", dmenu, function()
                    jammerSettings[jammer].defensive = false
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Defensive area jamming disabled", 4)
end
                end)

                -- Area Offensive
                local aomenu = missionCommands.addSubMenuForGroup(gid, "Offensive Area Jamming", root)
                missionCommands.addCommandForGroup(gid, "On", aomenu, function()
                    jammerSettings[jammer].offensive = true
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Offensive area jamming enabled", 4)
end
                end)
                missionCommands.addCommandForGroup(gid, "Off", aomenu, function()
                    jammerSettings[jammer].offensive = false
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Offensive area jamming disabled", 4)
end
                end)

                -- Directional menus (offensive/defensive)
                -- Spot Jamming
                local sjMenu = missionCommands.addSubMenuForGroup(gid, "Spot Jamming", root)
                missionCommands.addCommandForGroup(gid, "Off", sjMenu, function()
                    jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming disabled", 4)
end
                end)

                -- Target Selection Submenu
                local tsMenu = missionCommands.addSubMenuForGroup(gid, "Target Selection", sjMenu)
spotTargetMenus[jammer] = tsMenu

                local function getBearing(from, to)
                    local dx = to.x - from.x
                    local dz = to.z - from.z
                    local bearing = math.deg(math.atan2(dz, dx))
                    if bearing < 0 then bearing = bearing + 360 end
                    return math.floor(bearing + 0.5)
                end

                local function getNatoName(unit)
                    local typeName = unit:getTypeName()
                    local mapping = {
                        ["S-300PS 40B6M tr"] = "SA-10",
                        ["S-300PS 40B6MD sr"] = "SA-10",
                        ["S-300PS 64H6E sr"] = "SA-10",
                        ["SNR_75V"] = "SA-2",
                        ["Kub STR"] = "SA-6",
                        ["Tor 9A331"] = "SA-15",
                        ["Buk SR 9S18M1"] = "SA-11",
                        ["SA-11 Buk LN 9A310M1"] = "SA-11",
                        ["SA-17 Buk M1-2 LN"] = "SA-17",
                        ["Roland ADS"] = "Roland",
                        ["Patriot str"] = "Patriot",
                        ["Hawk tr"] = "Hawk",
                        ["Hawk sr"] = "Hawk"
                    }
                    return mapping[typeName] or typeName
                end

                -- Scan for targets within 80nm
                local jammerUnit = Unit.getByName(jammer)
                if jammerUnit and jammerUnit:isExist() then
                    local jammerPos = jammerUnit:getPoint()
                    local redGroups = coalition.getGroups(coalition.side.RED)
                    for _, group in ipairs(redGroups) do
                        local hasSAM = false
                        local targetUnit = nil
                        for _, unit in ipairs(group:getUnits()) do
                            if unit:hasAttribute("SAM SR") or unit:hasAttribute("SAM TR") or unit:hasAttribute("SAM STR") then
                                hasSAM = true
                                targetUnit = unit
                                break
                            end
                        end
                        if not hasSAM then
                            for _, unit in ipairs(group:getUnits()) do
                                if unit:getCategory() == Object.Category.UNIT and unit:hasAttribute("Ships") then
                                    hasSAM = true
                                    targetUnit = unit
                                    break
                                end
                            end
                        end
                        if hasSAM and targetUnit and targetUnit:isExist() then
                            local tgtPos = targetUnit:getPoint()
                            local dist = get3DDist(jammerPos, tgtPos)
                            if dist <= 148160 then -- 80nm in meters
                                local bearing = getBearing(jammerPos, tgtPos)
                                local distNM = math.floor(dist / 1852 + 0.5)
                                local name = getNatoName(targetUnit)
                                local label = name .. " | " .. bearing .. "° | " .. distNM .. "nm"
                                missionCommands.addCommandForGroup(gid, label, tsMenu, function()
                                    jammerSettings[jammer].spotTarget = group:getName()
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Spot jamming enabled on: " .. label, 4)
end
                                end)
                            end
                        end
                    end
                end

                for _, mode in ipairs({"Offensive", "Defensive"}) do
                    local submenu = missionCommands.addSubMenuForGroup(gid, "Directional " .. mode .. " Jamming", root)
                    for _, dir in ipairs({"front", "left", "right", "rear"}) do
                        missionCommands.addCommandForGroup(gid, "Activate " .. dir, submenu, function()
                            jammerSettings[jammer][mode == "Offensive" and "offDir" or "defDir"] = dir
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], mode .. " directional jamming enabled: " .. dir, 4)
end
                        end)
                    end
                    missionCommands.addCommandForGroup(gid, "Off", submenu, function()
                        jammerSettings[jammer][mode == "Offensive" and "offDir" or "defDir"] = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "Directional " .. mode:lower() .. " jamming disabled", 4)
end
                    end)
                end

if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "EW Jamming menu created for " .. jammer, 4)
end
            end
        end
    end
    return timer.getTime() + menuCheckInterval
end

timer.scheduleFunction(jammerLoop, {}, timer.getTime() + 3)
timer.scheduleFunction(setupMenus, {}, timer.getTime() + 2)


local function refreshSpotTargets()
    for _, jammer in ipairs(jammerUnits) do
        local gid = jammerGroupIDs[jammer]
        local tsMenu = spotTargetMenus[jammer]
        if gid and tsMenu then
            if spotTargetCommands[jammer] then
                for _, cmd in ipairs(spotTargetCommands[jammer]) do
                    if cmd then
                        missionCommands.removeItemForGroup(gid, cmd)
                    end
                end
                spotTargetCommands[jammer] = {}
            else
                spotTargetCommands[jammer] = {}
            end

            local jammerUnit = Unit.getByName(jammer)
            if jammerUnit and jammerUnit:isExist() then
                local jammerPos = jammerUnit:getPoint()
                local redGroups = coalition.getGroups(coalition.side.RED)

                for _, group in ipairs(redGroups) do
                    local hasSAM = false
                    local targetUnit = nil
                    for _, unit in ipairs(group:getUnits()) do
                        if unit:hasAttribute("SAM SR") or unit:hasAttribute("SAM TR") or unit:hasAttribute("SAM STR") then
                            hasSAM = true
                            targetUnit = unit
                            break
                        end
                    end
                    if not hasSAM then
                        for _, unit in ipairs(group:getUnits()) do
                            if unit:getCategory() == Object.Category.UNIT and unit:hasAttribute("Ships") then
                                hasSAM = true
                                targetUnit = unit
                                break
                            end
                        end
                    end

                    if hasSAM and targetUnit and targetUnit:isExist() then
                        local tgtPos = targetUnit:getPoint()
                        local dist = get3DDist(jammerPos, tgtPos)
                        if dist <= 148160 then
                            local bearing = getBearing(jammerPos, tgtPos)
                            local distNM = math.floor(dist / 1852 + 0.5)
                            local name = getNatoName(targetUnit)
                            local label = name .. " | " .. bearing .. "° | " .. distNM .. "nm"
                            local cmd = missionCommands.addCommandForGroup(gid, label, tsMenu, function()
                                jammerSettings[jammer].spotTarget = group:getName()
                                trigger.action.outTextForGroup(gid, "Spot jamming enabled on: " .. label, 4)
                            end)
                            table.insert(spotTargetCommands[jammer], cmd)
                        end
                    end
                end
            end
        end
    end
    return timer.getTime() + 10
end
timer.scheduleFunction(refreshSpotTargets, {}, timer.getTime() + 10)
