do

Task03BeirutExtractionController = Task03BeirutExtractionController or {}
Task03BeirutExtractionController.__index = Task03BeirutExtractionController

Task03BeirutExtractionController.MISSION_NAME = "Beirut Extraction"
Task03BeirutExtractionController.VERSION = "task03-beirut-extraction-v2"
Task03BeirutExtractionController.LOG_PREFIX = "[TASK03] "

local DEFAULT_CONFIG = {
    missionName = "贝鲁特：孤城营救",
    playerCoalition = coalition.side.BLUE,
    targetCoalition = coalition.side.RED,
    scanIntervalSeconds = 2,
    startupRosterStabilizeSeconds = 8,
    messageDurationSeconds = 10,
    introInitialDelaySeconds = 2,
    introPostSilenceSeconds = 2,
    hotLoadSeconds = 120,
    atlasGroundStuckSeconds = 130,
    pressureReminderSeconds = 45,
    armorPressureUpdateCooldownSeconds = 18,
    shoradCycleCooldownSeconds = 20,
    airportRushAliveThreshold = 0.25,
    atlasLandedSpeedMps = 10,
    atlasRollingSpeedMps = 25,
    atlasSafeSeaAltitudeMeters = 300,
    debugMode = false,

    radioMenuRootText = "任务03：贝鲁特：孤城营救",
    radioMenuAtlasText = "Atlas，机场安全，立即近进！",
    radioMenuAbortText = "无法清空机场，营救已经不可能，放弃任务。",
    radioMenuDebugText = "Debug",

    phaseFlag = 9500,
    takeoffFlag = 9501,
    airportContactFlag = 9502,
    runwayRecoveredFlag = 9503,
    armorPressureFlag = 9504,
    atlasInboundFlag = 9505,
    atlasLandedFlag = 9506,
    hotLoadFlag = 9507,
    atlasDepartFlag = 9508,
    denialFlag = 9509,
    missionSuccessFlag = 9510,
    missionFailFlag = 9511,
    ravenReleasedFlag = 9512,
    atlasCallWindowFlag = 9513,
    airportRush1ActivateFlag = 9514,
    airportRush2ActivateFlag = 9515,

    airportRingZoneName = "Z_AIRPORT_RING",
    runwayZoneName = "Z_RUNWAY",
    innerRingZoneName = "Z_INNER_RING",
    runwayFireLockZoneName = "Z_RUNWAY_FIRE_LOCK",
    ravenGateZoneName = "Z_RAVEN_GATE",
    ravenLoadZoneName = "Z_RAVEN_LOAD",
    safeSeaZoneName = "Z_SAFE_SEA",
    runwayLockZoneName = "Z_RUNWAY_FIRE_LOCK",
    mechBreachZoneName = "Z_INNER_RING",
    atlasEscortRangeMeters = 1852,

    ravenGroupName = "Raven",
    atlasGroupName = "Atlas",
    airportRushGroupNames = {
        "AIRPORT_RUSH_1",
        "AIRPORT_RUSH_2",
    },
    mechAGroupName = "第七装甲师-第一装甲旅-机械化营-A连",
    armorGroupNames = {
        "第七装甲师-第一装甲旅-第一营-A连",
        "第七装甲师-第一装甲旅-第一营-B连",
        "第七装甲师-第一装甲旅-第一营-C连",
    },
    shoradGroupName = "第七装甲防空团-第一近程防空营-2",
}

local DIALOGUE = Task03BeirutExtractionDialogue or {}

local PHASE_VALUES = {
    intro = 1,
    startup = 2,
    takeoff = 3,
    airport_contact = 4,
    airport_rush = 5,
    runway_recovered = 6,
    armor_pressure = 7,
    atlas_call_window = 8,
    atlas_inbound = 9,
    atlas_land = 10,
    hot_load = 11,
    atlas_depart = 12,
    atlas_crash_denial = 13,
    success = 14,
    fail = 15,
}

local function cloneTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function mergeConfig(baseConfig, overrideConfig)
    local merged = cloneTable(baseConfig)
    for key, value in pairs(overrideConfig or {}) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = mergeConfig(merged[key], value)
        else
            merged[key] = value
        end
    end
    return merged
end

local function getCurrentTime()
    return timer.getTime()
end

local function createLogger(prefix)
    return function(message)
        env.info(prefix .. tostring(message))
    end
end

local function randomFrom(list)
    if list == nil or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

local function normalizeMatchText(source)
    if source == nil then
        return ""
    end
    local text = tostring(source):upper()
    text = string.gsub(text, "[%s%-%_%.]", "")
    return text
end

local function get2dDistance(pointA, pointB)
    local dx = pointA.x - pointB.x
    local dz = pointA.z - pointB.z
    return math.sqrt(dx * dx + dz * dz)
end

local function pointInZone(point, zone)
    if point == nil or zone == nil or zone.point == nil or zone.radius == nil then
        return false
    end
    return get2dDistance(point, zone.point) <= zone.radius
end

local function isUnitAlive(unit)
    if unit == nil then
        return false
    end
    local okExist, exists = pcall(function()
        return unit:isExist()
    end)
    if not okExist or exists ~= true then
        return false
    end
    local okLife, life = pcall(function()
        return unit:getLife()
    end)
    return okLife and life ~= nil and life > 0
end

local function getUnitName(unit)
    local okName, name = pcall(function()
        return unit:getName()
    end)
    if okName then
        return name
    end
    return nil
end

local function getGroupName(group)
    local okName, name = pcall(function()
        return group:getName()
    end)
    if okName then
        return name
    end
    return nil
end

local function getUnitGroup(unit)
    local okGroup, group = pcall(function()
        return unit:getGroup()
    end)
    if okGroup then
        return group
    end
    return nil
end

local function getPlayerName(unit)
    local okPlayer, name = pcall(function()
        return unit:getPlayerName()
    end)
    if okPlayer then
        return name
    end
    return nil
end

local function getUnitPoint(unit)
    local okPoint, point = pcall(function()
        return unit:getPoint()
    end)
    if okPoint then
        return point
    end
    return nil
end

local function isUnitInAir(unit)
    local okAir, inAir = pcall(function()
        return unit:inAir()
    end)
    return okAir and inAir == true
end

local function getUnitSpeedMps(unit)
    local okVelocity, velocity = pcall(function()
        return unit:getVelocity()
    end)
    if okVelocity and velocity then
        return math.sqrt((velocity.x or 0) ^ 2 + (velocity.y or 0) ^ 2 + (velocity.z or 0) ^ 2)
    end
    return 0
end

local function getAliveUnits(group)
    local units = {}
    if group == nil then
        return units
    end
    local okExist, exists = pcall(function()
        return group:isExist()
    end)
    if not okExist or exists ~= true then
        return units
    end
    local okUnits, groupUnits = pcall(function()
        return group:getUnits()
    end)
    if okUnits and groupUnits then
        for i = 1, #groupUnits do
            if isUnitAlive(groupUnits[i]) then
                units[#units + 1] = groupUnits[i]
            end
        end
    end
    return units
end

local function groupAliveFraction(groupName)
    local group = Group.getByName(groupName)
    if group == nil then
        return 0
    end
    local okUnits, units = pcall(function()
        return group:getUnits()
    end)
    if not okUnits or units == nil or #units == 0 then
        return 0
    end
    local alive = 0
    for i = 1, #units do
        if isUnitAlive(units[i]) then
            alive = alive + 1
        end
    end
    return alive / #units
end

local function getEventTargetGroupName(eventObject)
    if eventObject == nil then
        return nil
    end
    local group = nil
    local okGroup = pcall(function()
        group = eventObject:getGroup()
    end)
    if okGroup and group then
        return getGroupName(group)
    end
    return nil
end

local function setGroupAIEnabled(groupName, enabled)
    local group = Group.getByName(groupName)
    if group == nil then
        return false
    end
    local okController, controller = pcall(function()
        return group:getController()
    end)
    if not okController or controller == nil then
        return false
    end
    local okOnOff = pcall(function()
        controller:setOnOff(enabled == true)
    end)
    return okOnOff == true
end

local function destroyGroupByName(groupName)
    local group = Group.getByName(groupName)
    if group == nil then
        return false
    end
    local okDestroy = pcall(function()
        group:destroy()
    end)
    return okDestroy == true
end

function Task03BeirutExtractionController:create(config)
    local instance = setmetatable({}, self)
    instance.config = mergeConfig(DEFAULT_CONFIG, config or {})
    instance.logWriter = createLogger(self.LOG_PREFIX)
    instance.phase = "intro"
    instance.playersByName = {}
    instance.playerOrder = {}
    instance.effectivePlayerNames = {}
    instance.effectivePlayerIndex = {}
    instance.rosterFrozen = false
    instance.lastRosterChangeTime = getCurrentTime()
    instance.sequenceFlags = {}
    instance.dialogueCounts = {}
    instance.menusByGroupId = {}
    instance.abortVotes = {}
    instance.nextMarkId = 20300
    instance.sa15MarkId = nil
    instance.activeArmorGroupNames = {}
    instance.enabledRushGroupNames = {}
    instance.rushObservedAlive = {}
    instance.selectedArmorCount = 0

    instance.introStarted = false
    instance.takeoffTriggered = false
    instance.airportContactTriggered = false
    instance.airportRushTriggered = false
    instance.runwayRecoveredTriggered = false
    instance.armorPressureTriggered = false
    instance.atlasCallUnlocked = false
    instance.atlasInboundTriggered = false
    instance.atlasApproachTriggered = false
    instance.atlasLandedTriggered = false
    instance.hotLoadStarted = false
    instance.hotLoadStartTime = nil
    instance.hotLoadCompleteTriggered = false
    instance.hotLoadCompleteTime = nil
    instance.atlasDepartTriggered = false
    instance.atlasRollingTriggered = false
    instance.atlasAirborneTriggered = false
    instance.successTriggered = false
    instance.failTriggered = false
    instance.denialTriggered = false
    instance.denialTarget = nil
    instance.ravenReleased = false
    instance.ravenGateTriggered = false
    instance.ravenLoadTriggered = false
    instance.armorHitCooldownUntil = 0
    instance.lastAnxietyTime = 0
    instance.lastShoradLiveTime = 0
    instance.shoradFirstTriggered = false
    instance.lastShoradHighPressureTime = 0
    instance.shoradKilledTriggered = false
    instance.atlasEscortTriggered = false
    instance.debugValidationDone = false
    return instance
end

function Task03BeirutExtractionController:log(message)
    self.logWriter(message)
end

function Task03BeirutExtractionController:setFlag(flagValue, value)
    if flagValue == nil then
        self:log("flag_skip | missing_flag_name | value=" .. tostring(value))
        return
    end
    trigger.action.setUserFlag(flagValue, value)
end

function Task03BeirutExtractionController:markPhase(phaseName)
    if self.phase == phaseName then
        return
    end
    self.phase = phaseName
    self:setFlag(self.config.phaseFlag, PHASE_VALUES[phaseName] or 0)
    self:log("phase | " .. tostring(phaseName))
end

function Task03BeirutExtractionController:getZone(zoneName)
    local okZone, zone = pcall(function()
        return trigger.misc.getZone(zoneName)
    end)
    if okZone then
        return zone
    end
    return nil
end

function Task03BeirutExtractionController:getTrackedUnit(playerState)
    if playerState == nil or playerState.unitName == nil then
        return nil
    end
    local unit = Unit.getByName(playerState.unitName)
    if isUnitAlive(unit) then
        return unit
    end
    return nil
end

function Task03BeirutExtractionController:getPlayerLabel(playerState)
    if playerState ~= nil then
        if playerState.playerName and playerState.playerName ~= "" then
            return tostring(playerState.playerName)
        end
        if playerState.unitName and playerState.unitName ~= "" then
            return tostring(playerState.unitName)
        end
    end
    return "玩家"
end

function Task03BeirutExtractionController:notifyPlayer(playerState, text, duration)
    if text == nil or text == "" then
        return
    end
    local unit = self:getTrackedUnit(playerState)
    if unit then
        local okUnitId, unitId = pcall(function()
            return unit:getID()
        end)
        if okUnitId and unitId then
            local okOut = pcall(function()
                trigger.action.outTextForUnit(unitId, text, duration or self.config.messageDurationSeconds)
            end)
            if okOut then
                return
            end
        end
    end
    if playerState and playerState.groupId then
        trigger.action.outTextForGroup(playerState.groupId, text, duration or self.config.messageDurationSeconds)
    else
        trigger.action.outText(text, duration or self.config.messageDurationSeconds)
    end
end

function Task03BeirutExtractionController:getAudiencePlayers()
    local audience = {}
    local names = self.rosterFrozen == true and self.effectivePlayerNames or self.playerOrder
    for i = 1, #names do
        local playerState = self.playersByName[names[i]]
        if playerState and self:getTrackedUnit(playerState) then
            audience[#audience + 1] = playerState
        end
    end
    return audience
end

function Task03BeirutExtractionController:notifyAllPlayers(text, duration)
    local audience = self:getAudiencePlayers()
    if #audience == 0 then
        trigger.action.outText(text, duration or self.config.messageDurationSeconds)
        return
    end
    for i = 1, #audience do
        self:notifyPlayer(audience[i], text, duration)
    end
end

function Task03BeirutExtractionController:broadcastLine(label, text, duration)
    self:notifyAllPlayers(tostring(label) .. "：" .. tostring(text), duration or self.config.messageDurationSeconds)
end

function Task03BeirutExtractionController:getOrderedEffectivePlayers()
    local players = {}
    local names = self.rosterFrozen == true and self.effectivePlayerNames or self.playerOrder
    for i = 1, #names do
        local playerState = self.playersByName[names[i]]
        if playerState and self:getTrackedUnit(playerState) then
            players[#players + 1] = playerState
        end
    end
    return players
end

function Task03BeirutExtractionController:selectDynamicPlayerSpeaker()
    local players = self:getOrderedEffectivePlayers()
    if #players == 0 then
        return nil
    end
    if #players == 1 then
        return players[1]
    end

    local candidates = {}
    local lowestCount = nil
    for i = 1, #players do
        local playerState = players[i]
        local count = self.dialogueCounts[playerState.playerName] or 0
        if lowestCount == nil or count < lowestCount then
            lowestCount = count
            candidates = { playerState }
        elseif count == lowestCount then
            candidates[#candidates + 1] = playerState
        end
    end
    return randomFrom(candidates)
end

function Task03BeirutExtractionController:markPlayerSpeakerUsed(playerState)
    if playerState == nil or playerState.playerName == nil then
        return
    end
    self.dialogueCounts[playerState.playerName] = (self.dialogueCounts[playerState.playerName] or 0) + 1
end

function Task03BeirutExtractionController:emitDialogueEntry(entry, options)
    if entry == nil then
        return
    end
    local label = entry.label or "系统"
    local text = entry.text or ""
    local duration = entry.duration or self.config.messageDurationSeconds

    if label == "玩家" then
        local playerState = options and options.playerState or nil
        if playerState == nil then
            playerState = self:selectDynamicPlayerSpeaker()
        end
        local playerLabel = self:getPlayerLabel(playerState)
        if playerState then
            self:markPlayerSpeakerUsed(playerState)
        end
        self:notifyAllPlayers(playerLabel .. "：" .. text, duration)
        return
    end

    self:broadcastLine(label, text, duration)
end

function Task03BeirutExtractionController:queueDialogueBlock(sequenceKey, blockName, options)
    if sequenceKey ~= nil and self.sequenceFlags[sequenceKey] == true then
        return
    end
    if sequenceKey ~= nil then
        self.sequenceFlags[sequenceKey] = true
    end
    local entries = DIALOGUE[blockName]
    if entries == nil then
        self:log("dialogue_missing | block=" .. tostring(blockName))
        if options and options.onComplete then
            options.onComplete()
        end
        return
    end

    local baseTime = getCurrentTime() + ((options and options.initialDelay) or 0)
    local lastFinishTime = baseTime
    for i = 1, #entries do
        local entry = cloneTable(entries[i])
        local scheduledTime = baseTime + (entry.delay or 0)
        baseTime = scheduledTime
        lastFinishTime = scheduledTime + (entry.duration or self.config.messageDurationSeconds)
        timer.scheduleFunction(function()
            if Task03BeirutExtractionControllerInstance ~= nil then
                Task03BeirutExtractionControllerInstance:emitDialogueEntry(entry, options)
            end
            return nil
        end, {}, scheduledTime)
    end

    if options and options.onComplete then
        timer.scheduleFunction(function()
            if Task03BeirutExtractionControllerInstance ~= nil then
                options.onComplete()
            end
            return nil
        end, {}, lastFinishTime)
    end
end

function Task03BeirutExtractionController:playPoolLine(poolName, label, explicitPlayerState)
    local pool = DIALOGUE[poolName]
    local text = randomFrom(pool)
    if text == nil then
        return
    end
    if label == "玩家" then
        local playerState = explicitPlayerState or self:selectDynamicPlayerSpeaker()
        local playerLabel = self:getPlayerLabel(playerState)
        if playerState then
            self:markPlayerSpeakerUsed(playerState)
        end
        self:notifyAllPlayers(playerLabel .. "：" .. text, self.config.messageDurationSeconds)
        return
    end
    self:broadcastLine(label, text, self.config.messageDurationSeconds)
end

function Task03BeirutExtractionController:getPlayerStateByGroupId(groupId)
    if groupId == nil then
        return nil
    end
    for _, playerState in pairs(self.playersByName) do
        if playerState.groupId == groupId then
            return playerState
        end
    end
    return nil
end

function Task03BeirutExtractionController:updatePlayerRoster()
    local seen = {}
    local coalitionPlayers = coalition.getPlayers(self.config.playerCoalition) or {}
    for i = 1, #coalitionPlayers do
        local unit = coalitionPlayers[i]
        if isUnitAlive(unit) then
            local playerName = getPlayerName(unit)
            local group = getUnitGroup(unit)
            if playerName ~= nil and playerName ~= "" and group ~= nil then
                local groupId = nil
                pcall(function()
                    groupId = group:getID()
                end)
                local playerState = self.playersByName[playerName]
                if playerState == nil then
                    playerState = {
                        playerName = playerName,
                        joinIndex = #self.playerOrder + 1,
                    }
                    self.playersByName[playerName] = playerState
                    self.playerOrder[#self.playerOrder + 1] = playerName
                    self.lastRosterChangeTime = getCurrentTime()
                    self:log("player_join | " .. tostring(playerName))
                end
                playerState.unitName = getUnitName(unit)
                playerState.groupId = groupId
                playerState.lastSeen = getCurrentTime()
                playerState.airborne = isUnitInAir(unit)
                seen[playerName] = true
            end
        end
    end

    for name, playerState in pairs(self.playersByName) do
        if seen[name] ~= true then
            playerState.airborne = false
        end
    end
end

function Task03BeirutExtractionController:freezeEffectiveRosterIfReady()
    if self.rosterFrozen == true or self.phase ~= "startup" then
        return
    end
    if #self.playerOrder == 0 then
        return
    end
    if getCurrentTime() - self.lastRosterChangeTime < self.config.startupRosterStabilizeSeconds then
        return
    end

    self.effectivePlayerNames = {}
    self.effectivePlayerIndex = {}
    for i = 1, #self.playerOrder do
        local playerName = self.playerOrder[i]
        local playerState = self.playersByName[playerName]
        if playerState ~= nil then
            self.effectivePlayerNames[#self.effectivePlayerNames + 1] = playerName
            self.effectivePlayerIndex[playerName] = #self.effectivePlayerNames
        end
    end
    self.rosterFrozen = true
    self:log("effective_roster_frozen | count=" .. tostring(#self.effectivePlayerNames))
    self:configureEnemyParticipation()
end

function Task03BeirutExtractionController:configureEnemyParticipation()
    local effectiveCount = #self.effectivePlayerNames
    local armorNames = self.config.armorGroupNames
    self.activeArmorGroupNames = {}

    local selectedCount = 0
    if effectiveCount <= 1 then
        selectedCount = 1
    elseif effectiveCount == 2 then
        selectedCount = 2
    else
        selectedCount = #armorNames
    end
    self.selectedArmorCount = selectedCount

    local shuffled = cloneTable(armorNames)
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local activeLookup = {}
    for i = 1, selectedCount do
        local groupName = shuffled[i]
        self.activeArmorGroupNames[#self.activeArmorGroupNames + 1] = groupName
        activeLookup[groupName] = true
        setGroupAIEnabled(groupName, true)
    end
    for i = 1, #armorNames do
        local groupName = armorNames[i]
        if activeLookup[groupName] ~= true then
            setGroupAIEnabled(groupName, false)
        end
    end

    self.enabledRushGroupNames = { self.config.airportRushGroupNames[1] }
    self.rushObservedAlive = {}
    self.rushObservedAlive[self.config.airportRushGroupNames[1]] = false
    if effectiveCount >= 2 then
        self.enabledRushGroupNames[#self.enabledRushGroupNames + 1] = self.config.airportRushGroupNames[2]
        self.rushObservedAlive[self.config.airportRushGroupNames[2]] = false
    end
end

function Task03BeirutExtractionController:allEffectivePlayersAirborne()
    if self.rosterFrozen ~= true or #self.effectivePlayerNames == 0 then
        return false
    end
    for i = 1, #self.effectivePlayerNames do
        local playerState = self.playersByName[self.effectivePlayerNames[i]]
        local unit = self:getTrackedUnit(playerState)
        if unit == nil or isUnitInAir(unit) ~= true then
            return false
        end
    end
    return true
end

function Task03BeirutExtractionController:isAnyEffectivePlayerInZone(zoneName)
    local zone = self:getZone(zoneName)
    if zone == nil then
        return false
    end
    local players = self:getOrderedEffectivePlayers()
    for i = 1, #players do
        local unit = self:getTrackedUnit(players[i])
        local point = getUnitPoint(unit)
        if point and pointInZone(point, zone) then
            return true
        end
    end
    return false
end

function Task03BeirutExtractionController:isAirportRushCleared()
    for i = 1, #self.enabledRushGroupNames do
        local groupName = self.enabledRushGroupNames[i]
        local aliveFraction = groupAliveFraction(groupName)
        if aliveFraction > 0 then
            self.rushObservedAlive[groupName] = true
        end
        if self.rushObservedAlive[groupName] ~= true then
            return false
        end
        if aliveFraction > self.config.airportRushAliveThreshold then
            return false
        end
    end
    return true
end

function Task03BeirutExtractionController:debugDestroyGroup(groupName, reason)
    if groupName == nil or groupName == "" then
        return false
    end
    local destroyed = destroyGroupByName(groupName)
    if destroyed == true then
        self:log("debug_clear | reason=" .. tostring(reason) .. " | group=" .. tostring(groupName))
    else
        self:log("debug_clear_skip | reason=" .. tostring(reason) .. " | group=" .. tostring(groupName))
    end
    return destroyed
end

function Task03BeirutExtractionController:debugClearAirportRush(reason)
    for i = 1, #self.config.airportRushGroupNames do
        self:debugDestroyGroup(self.config.airportRushGroupNames[i], reason or "airport_rush")
    end
end

function Task03BeirutExtractionController:debugClearRunwaySuppression(reason)
    self:debugDestroyGroup(self.config.mechAGroupName, reason or "runway_suppression")
    for i = 1, #self.config.armorGroupNames do
        self:debugDestroyGroup(self.config.armorGroupNames[i], reason or "runway_suppression")
    end
end

function Task03BeirutExtractionController:debugClearShorad(reason)
    if self:debugDestroyGroup(self.config.shoradGroupName, reason or "shorad") then
        self:handleShoradDead()
    end
end

function Task03BeirutExtractionController:debugForceRunwayRecovered()
    self:debugClearAirportRush("gate_d_runway_recovered")
    self:debugClearRunwaySuppression("gate_d_runway_recovered")
    self.runwayRecoveredTriggered = true
    self:unlockAtlasCallWindow()
end

function Task03BeirutExtractionController:debugForceAtlasInbound(playerState)
    self:debugClearAirportRush("atlas_inbound")
    self:debugClearRunwaySuppression("atlas_inbound")
    self.atlasCallUnlocked = true
    self.runwayRecoveredTriggered = true
    self:unlockAtlasCallWindow()
    self.atlasInboundTriggered = true
    self.ravenReleased = true
    self:setFlag(self.config.atlasInboundFlag, 1)
    self:setFlag(self.config.ravenReleasedFlag, 1)
    self:markPhase("atlas_inbound")
    self:queueDialogueBlock("atlas_call_success_debug", "atlas_call_success", {
        playerState = playerState,
        onComplete = function()
            self:queueDialogueBlock("raven_release_debug", "raven_release")
        end
    })
end

function Task03BeirutExtractionController:debugForceAtlasDeparture()
    self:debugClearAirportRush("atlas_depart")
    self:debugClearRunwaySuppression("atlas_depart")
    self:debugClearShorad("atlas_depart")
    self:startAtlasDeparture()
end

function Task03BeirutExtractionController:groupAnyUnitInZone(groupName, zoneName)
    local zone = self:getZone(zoneName)
    if zone == nil then
        return false
    end
    local group = Group.getByName(groupName)
    if group == nil then
        return false
    end
    local units = getAliveUnits(group)
    for i = 1, #units do
        local point = getUnitPoint(units[i])
        if point and pointInZone(point, zone) then
            return true
        end
    end
    return false
end

function Task03BeirutExtractionController:isRunwayClearOfEnemies()
    local zoneName = self.config.runwayZoneName
    local namesToCheck = cloneTable(self.enabledRushGroupNames)
    namesToCheck[#namesToCheck + 1] = self.config.mechAGroupName
    for i = 1, #self.activeArmorGroupNames do
        namesToCheck[#namesToCheck + 1] = self.activeArmorGroupNames[i]
    end
    for i = 1, #namesToCheck do
        if self:groupAnyUnitInZone(namesToCheck[i], zoneName) then
            return false
        end
    end
    return true
end

function Task03BeirutExtractionController:isRunwaySuppressedByArmor()
    if self:groupAnyUnitInZone(self.config.mechAGroupName, self.config.runwayLockZoneName) then
        return true
    end
    for i = 1, #self.activeArmorGroupNames do
        if self:groupAnyUnitInZone(self.activeArmorGroupNames[i], self.config.runwayLockZoneName) then
            return true
        end
    end
    return false
end

function Task03BeirutExtractionController:isMechABreachingAirport()
    return self:groupAnyUnitInZone(self.config.mechAGroupName, self.config.mechBreachZoneName)
end

function Task03BeirutExtractionController:getAtlasGroup()
    return Group.getByName(self.config.atlasGroupName)
end

function Task03BeirutExtractionController:getRavenGroup()
    return Group.getByName(self.config.ravenGroupName)
end

function Task03BeirutExtractionController:getAtlasLeadUnit()
    local group = self:getAtlasGroup()
    if group == nil then
        return nil
    end
    local units = getAliveUnits(group)
    return units[1]
end

function Task03BeirutExtractionController:getRavenLeadUnit()
    local group = self:getRavenGroup()
    if group == nil then
        return nil
    end
    local units = getAliveUnits(group)
    return units[1]
end

function Task03BeirutExtractionController:isAtlasInZone(zoneName)
    local zone = self:getZone(zoneName)
    local unit = self:getAtlasLeadUnit()
    local point = getUnitPoint(unit)
    return zone ~= nil and point ~= nil and pointInZone(point, zone)
end

function Task03BeirutExtractionController:isRavenInZone(zoneName)
    local zone = self:getZone(zoneName)
    local unit = self:getRavenLeadUnit()
    local point = getUnitPoint(unit)
    return zone ~= nil and point ~= nil and pointInZone(point, zone)
end

function Task03BeirutExtractionController:isAtlasLanded()
    local unit = self:getAtlasLeadUnit()
    if unit == nil then
        return false
    end
    if self:isAtlasInZone(self.config.runwayZoneName) ~= true then
        return false
    end
    return getUnitSpeedMps(unit) <= self.config.atlasLandedSpeedMps
end

function Task03BeirutExtractionController:isAtlasRolling()
    local unit = self:getAtlasLeadUnit()
    if unit == nil then
        return false
    end
    return getUnitSpeedMps(unit) >= self.config.atlasRollingSpeedMps
end

function Task03BeirutExtractionController:isAtlasAirborne()
    local unit = self:getAtlasLeadUnit()
    if unit == nil then
        return false
    end
    return isUnitInAir(unit) == true
end

function Task03BeirutExtractionController:isAtlasSafeAtSea()
    local unit = self:getAtlasLeadUnit()
    if unit == nil then
        return false
    end
    if self:isAtlasInZone(self.config.safeSeaZoneName) ~= true then
        return false
    end
    local point = getUnitPoint(unit)
    return point ~= nil and point.y >= self.config.atlasSafeSeaAltitudeMeters
end

function Task03BeirutExtractionController:updateSa15Mark()
    local group = Group.getByName(self.config.shoradGroupName)
    if group == nil then
        return
    end
    local units = getAliveUnits(group)
    if #units == 0 then
        return
    end
    local point = getUnitPoint(units[1])
    if point == nil then
        return
    end
    if self.sa15MarkId == nil then
        self.sa15MarkId = self.nextMarkId
        self.nextMarkId = self.nextMarkId + 1
    else
        pcall(function()
            trigger.action.removeMark(self.sa15MarkId)
        end)
    end
    pcall(function()
        trigger.action.markToCoalition(self.sa15MarkId, "SA-15 大致位置", point, self.config.playerCoalition, false)
    end)
end

function Task03BeirutExtractionController:handleShoradCycle()
    local now = getCurrentTime()
    if now - self.lastShoradLiveTime < self.config.shoradCycleCooldownSeconds then
        return
    end
    self.lastShoradLiveTime = now
    self:updateSa15Mark()
    if self.shoradFirstTriggered ~= true then
        self.shoradFirstTriggered = true
        self:queueDialogueBlock("shorad_first", "shorad_first")
        return
    end
    self:queueDialogueBlock("shorad_repeat_" .. tostring(math.floor(now)), "shorad_repeat")
end

function Task03BeirutExtractionController:playShoradHighPressureIfNeeded()
    if self.atlasInboundTriggered ~= true and self.hotLoadStarted ~= true and self.atlasDepartTriggered ~= true then
        return
    end
    local now = getCurrentTime()
    if now - self.lastShoradHighPressureTime < self.config.pressureReminderSeconds then
        return
    end
    self.lastShoradHighPressureTime = now
    self:playPoolLine("shorad_high_pressure", "AWACS / 灯塔")
end

function Task03BeirutExtractionController:onSkynetGoLive(info)
    if info == nil then
        return
    end
    local normalizedGroup = normalizeMatchText(info.groupName)
    local normalizedDcsName = normalizeMatchText(info.dcsName)
    local normalizedShorad = normalizeMatchText(self.config.shoradGroupName)
    if normalizedGroup ~= normalizedShorad and normalizedDcsName ~= normalizedShorad then
        self:log("skynet_live_ignored | group=" .. tostring(info.groupName) .. " | dcsName=" .. tostring(info.dcsName) .. " | nato=" .. tostring(info.natoName) .. " | type=" .. tostring(info.typeName))
        return
    end
    self:log("skynet_live_accept | group=" .. tostring(info.groupName) .. " | dcsName=" .. tostring(info.dcsName) .. " | nato=" .. tostring(info.natoName) .. " | type=" .. tostring(info.typeName))
    self:handleShoradCycle()
    self:playShoradHighPressureIfNeeded()
end

function Task03BeirutExtractionController:handleArmorFirstHit(triggeringPlayerState)
    if self.armorPressureTriggered ~= true then
        self.armorPressureTriggered = true
        self:setFlag(self.config.armorPressureFlag, 1)
        self:markPhase("armor_pressure")
        self:queueDialogueBlock("armor_first_hit", "armor_first_hit", { playerState = triggeringPlayerState })
        self.armorHitCooldownUntil = getCurrentTime() + self.config.armorPressureUpdateCooldownSeconds
        return
    end
    if getCurrentTime() < self.armorHitCooldownUntil then
        return
    end
    self.armorHitCooldownUntil = getCurrentTime() + self.config.armorPressureUpdateCooldownSeconds
    self:playPoolLine("armor_pressure_pool", "AWACS / 灯塔")
end

function Task03BeirutExtractionController:handleShoradDead()
    if self.shoradKilledTriggered == true then
        return
    end
    self.shoradKilledTriggered = true
    self:queueDialogueBlock("shorad_dead", "shorad_dead")
end

function Task03BeirutExtractionController:unlockAtlasCallWindow()
    if self.atlasCallUnlocked == true then
        return
    end
    self.atlasCallUnlocked = true
    self:setFlag(self.config.runwayRecoveredFlag, 1)
    self:setFlag(self.config.atlasCallWindowFlag, 1)
    self:markPhase("runway_recovered")
    self:queueDialogueBlock("runway_recovered", "runway_recovered", {
        onComplete = function()
            if self.atlasInboundTriggered ~= true then
                self:markPhase("atlas_call_window")
            end
        end
    })
end

function Task03BeirutExtractionController:triggerTakeoffGate()
    if self.takeoffTriggered == true then
        return
    end
    self.takeoffTriggered = true
    self:setFlag(self.config.takeoffFlag, 1)
    self:markPhase("takeoff")
    self:queueDialogueBlock("takeoff", "takeoff")
end

function Task03BeirutExtractionController:triggerAirportContact()
    if self.airportContactTriggered == true then
        return
    end
    self.airportContactTriggered = true
    self:setFlag(self.config.airportContactFlag, 1)
    self:markPhase("airport_contact")
    self:queueDialogueBlock("airport_contact", "airport_contact", {
        onComplete = function()
            if self.airportRushTriggered ~= true then
                self.airportRushTriggered = true
                self:setFlag(self.config.airportRush1ActivateFlag, 1)
                if #self.enabledRushGroupNames >= 2 then
                    self:setFlag(self.config.airportRush2ActivateFlag, 1)
                end
                self:markPhase("airport_rush")
                self:queueDialogueBlock("airport_rush", "airport_rush")
            end
        end
    })
end

function Task03BeirutExtractionController:attemptAtlasCall(playerState)
    if self.missionEnded == true or self.denialTriggered == true then
        return
    end
    if self.atlasInboundTriggered == true then
        self:notifyPlayer(playerState, "AWACS / 灯塔：Atlas 已经在路上。", self.config.messageDurationSeconds)
        return
    end
    if self.atlasCallUnlocked ~= true then
        self:notifyPlayer(playerState, "AWACS / 灯塔：现在还没到叫 Atlas 进来的时候。", self.config.messageDurationSeconds)
        return
    end

    local rushCleared = self:isAirportRushCleared()
    local runwaySuppressed = self:isRunwaySuppressedByArmor()
    if rushCleared ~= true or runwaySuppressed == true then
        self:queueDialogueBlock("atlas_call_fail_" .. tostring(math.floor(getCurrentTime())), "atlas_call_fail", {
            playerState = playerState,
        })
        return
    end

    self.atlasInboundTriggered = true
    self.ravenReleased = true
    self:setFlag(self.config.atlasInboundFlag, 1)
    self:setFlag(self.config.ravenReleasedFlag, 1)
    self:markPhase("atlas_inbound")
    self:queueDialogueBlock("atlas_call_success", "atlas_call_success", {
        playerState = playerState,
        onComplete = function()
            self:queueDialogueBlock("raven_release", "raven_release")
        end
    })
end

function Task03BeirutExtractionController:registerAbortVote(playerState)
    if self.missionEnded == true or self.denialTriggered == true or self.failTriggered == true or self.successTriggered == true then
        return
    end
    if playerState == nil or playerState.playerName == nil then
        return
    end
    self.abortVotes[playerState.playerName] = true
    self:notifyPlayer(playerState, "系统：已登记放弃任务表决。", 6)

    local required = 0
    local voted = 0
    local activePlayers = self:getOrderedEffectivePlayers()
    if #activePlayers == 0 then
        for i = 1, #self.effectivePlayerNames do
            local name = self.effectivePlayerNames[i]
            local state = self.playersByName[name]
            if state then
                activePlayers[#activePlayers + 1] = state
            end
        end
    end

    for i = 1, #activePlayers do
        local name = activePlayers[i].playerName
        required = required + 1
        if self.abortVotes[name] == true then
            voted = voted + 1
        end
    end

    if required <= 1 or voted >= required then
        if self.atlasLandedTriggered == true and self.atlasAirborneTriggered ~= true then
            self:enterDenialAtlas()
        else
            self:enterDenialRaven()
        end
    else
        self:notifyAllPlayers(string.format("系统：放弃表决 %d/%d。", voted, required), 6)
    end
end

function Task03BeirutExtractionController:triggerAtlasApproach()
    if self.atlasApproachTriggered == true then
        return
    end
    self.atlasApproachTriggered = true
    self:queueDialogueBlock("atlas_approach", "atlas_approach")
end

function Task03BeirutExtractionController:triggerAtlasEscort(playerState)
    if self.atlasEscortTriggered == true then
        return
    end
    self.atlasEscortTriggered = true
    self:queueDialogueBlock("atlas_player_escort", "atlas_player_escort", {
        playerState = playerState,
    })
end

function Task03BeirutExtractionController:triggerRavenGate()
    if self.ravenGateTriggered == true then
        return
    end
    self.ravenGateTriggered = true
    self:queueDialogueBlock("raven_gate", "raven_gate")
end

function Task03BeirutExtractionController:triggerAtlasLanded()
    if self.atlasLandedTriggered == true then
        return
    end
    self.atlasLandedTriggered = true
    self:setFlag(self.config.atlasLandedFlag, 1)
    self:markPhase("atlas_land")
    self:queueDialogueBlock("atlas_landed", "atlas_landed")
end

function Task03BeirutExtractionController:triggerRavenLoad()
    if self.ravenLoadTriggered == true then
        return
    end
    self.ravenLoadTriggered = true
    self:queueDialogueBlock("raven_load", "raven_load")
end

function Task03BeirutExtractionController:startHotLoad()
    if self.hotLoadStarted == true then
        return
    end
    self.hotLoadStarted = true
    self.hotLoadStartTime = getCurrentTime()
    self.hotLoadCompleteTriggered = false
    self.hotLoadCompleteTime = nil
    self:setFlag(self.config.hotLoadFlag, 1)
    self:markPhase("hot_load")
end

function Task03BeirutExtractionController:markHotLoadComplete()
    if self.hotLoadCompleteTriggered == true then
        return
    end
    self.hotLoadCompleteTriggered = true
    self.hotLoadCompleteTime = getCurrentTime()
    self:log("hot_load_complete")
end

function Task03BeirutExtractionController:isAtlasDepartureCleared()
    if self.hotLoadCompleteTriggered ~= true then
        return false
    end
    if self:isAirportRushCleared() ~= true then
        return false
    end
    if self:isRunwaySuppressedByArmor() == true then
        return false
    end
    return true
end

function Task03BeirutExtractionController:startAtlasDeparture()
    if self.atlasDepartTriggered == true then
        return
    end
    self.atlasDepartTriggered = true
    self:setFlag(self.config.atlasDepartFlag, 1)
    self:markPhase("atlas_depart")
    self:queueDialogueBlock("atlas_depart", "atlas_depart")
end

function Task03BeirutExtractionController:triggerAtlasRolling()
    if self.atlasRollingTriggered == true then
        return
    end
    self.atlasRollingTriggered = true
    self:queueDialogueBlock("atlas_rolling", "atlas_rolling")
end

function Task03BeirutExtractionController:triggerAtlasAirborne()
    if self.atlasAirborneTriggered == true then
        return
    end
    self.atlasAirborneTriggered = true
    self:queueDialogueBlock("atlas_airborne", "atlas_airborne")
end

function Task03BeirutExtractionController:triggerSuccess()
    if self.successTriggered == true then
        return
    end
    self.successTriggered = true
    self.missionEnded = true
    self:setFlag(self.config.missionSuccessFlag, 1)
    self:markPhase("success")
    self:queueDialogueBlock("success", "success")
end

function Task03BeirutExtractionController:triggerFailurePostTakeoff()
    if self.failTriggered == true then
        return
    end
    self.failTriggered = true
    self.missionEnded = true
    self:setFlag(self.config.missionFailFlag, 1)
    self:markPhase("fail")
    self:queueDialogueBlock("failure_posttakeoff", "failure_posttakeoff")
end

function Task03BeirutExtractionController:enterDenialRaven()
    if self.denialTriggered == true then
        return
    end
    self.denialTriggered = true
    self.denialTarget = "Raven"
    self:setFlag(self.config.denialFlag, 1)
    self:markPhase("atlas_crash_denial")
    self:queueDialogueBlock("denial_raven", "denial_raven")
end

function Task03BeirutExtractionController:enterDenialAtlas()
    if self.denialTriggered == true then
        return
    end
    self.denialTriggered = true
    self.denialTarget = "Atlas"
    self:setFlag(self.config.denialFlag, 1)
    self:markPhase("atlas_crash_denial")
    self:queueDialogueBlock("denial_atlas", "denial_atlas")
end

function Task03BeirutExtractionController:handleAtlasLost()
    if self.successTriggered == true or self.failTriggered == true then
        return
    end

    self:queueDialogueBlock("atlas_hit_" .. tostring(math.floor(getCurrentTime())), "atlas_hit")

    if self.atlasAirborneTriggered == true then
        self:triggerFailurePostTakeoff()
        return
    end

    if self.atlasLandedTriggered ~= true then
        self:enterDenialRaven()
        return
    end

    self.failTriggered = true
    self.missionEnded = true
    self:setFlag(self.config.missionFailFlag, 1)
    self:markPhase("fail")
    self:notifyAllPlayers("AWACS / 灯塔：Atlas 在地面损失。任务失败。", 10)
end

function Task03BeirutExtractionController:handleRavenLost()
    if self.successTriggered == true or self.failTriggered == true then
        return
    end
    if self.denialTriggered == true and self.denialTarget == "Raven" then
        self.failTriggered = true
        self.missionEnded = true
        self:setFlag(self.config.missionFailFlag, 1)
        self:markPhase("fail")
        self:notifyAllPlayers("AWACS / 灯塔：Raven 已失能。拒止完成。任务结束。", 10)
        return
    end
    self.failTriggered = true
    self.missionEnded = true
    self:setFlag(self.config.missionFailFlag, 1)
    self:markPhase("fail")
    self:notifyAllPlayers("AWACS / 灯塔：Raven 已失去响应。任务失败。", 10)
end

function Task03BeirutExtractionController:handleMechABreach()
    if self.successTriggered == true or self.failTriggered == true then
        return
    end
    if self.atlasLandedTriggered == true and self.atlasAirborneTriggered ~= true then
        self:enterDenialAtlas()
    else
        self:enterDenialRaven()
    end
end

function Task03BeirutExtractionController:playAnxietyIfNeeded()
    if self.missionEnded == true or self.denialTriggered == true then
        return
    end
    local now = getCurrentTime()
    if now - self.lastAnxietyTime < self.config.pressureReminderSeconds then
        return
    end

    local shouldPlay = false
    if self.atlasCallUnlocked == true and self.atlasInboundTriggered ~= true and self:isRunwaySuppressedByArmor() then
        shouldPlay = true
    elseif self.hotLoadCompleteTriggered == true and self.atlasAirborneTriggered ~= true and self.atlasDepartTriggered ~= true then
        shouldPlay = true
    end

    if shouldPlay ~= true then
        return
    end
    self.lastAnxietyTime = now
    self:playPoolLine("anxiety_awacs", "AWACS / 灯塔")
    if math.random(1, 100) <= 65 then
        self:playPoolLine("anxiety_leader_continue", "中队长")
    else
        self:playPoolLine("anxiety_leader_abort", "中队长")
    end
end

function Task03BeirutExtractionController:checkDebugValidation()
    if self.config.debugMode ~= true or self.debugValidationDone == true then
        return
    end
    self.debugValidationDone = true
    self:validateMissionObjects(true)
end

function Task03BeirutExtractionController:validateMissionObjects(outputToGame)
    local missing = {}
    local requiredZones = {
        self.config.runwayZoneName,
        self.config.airportRingZoneName,
        self.config.innerRingZoneName,
        self.config.runwayFireLockZoneName,
        self.config.ravenGateZoneName,
        self.config.ravenLoadZoneName,
        self.config.safeSeaZoneName,
    }
    for i = 1, #requiredZones do
        local zoneName = requiredZones[i]
        if self:getZone(zoneName) == nil then
            missing[#missing + 1] = "缺少触发区: " .. tostring(zoneName)
        end
    end

    local requiredGroups = {
        self.config.atlasGroupName,
        self.config.mechAGroupName,
        self.config.shoradGroupName,
    }
    for i = 1, #self.config.armorGroupNames do
        requiredGroups[#requiredGroups + 1] = self.config.armorGroupNames[i]
    end
    for i = 1, #requiredGroups do
        local groupName = requiredGroups[i]
        if Group.getByName(groupName) == nil then
            missing[#missing + 1] = "缺少群组: " .. tostring(groupName)
        end
    end

    local lateActivationGroups = {
        self.config.ravenGroupName,
    }
    for i = 1, #self.config.airportRushGroupNames do
        lateActivationGroups[#lateActivationGroups + 1] = self.config.airportRushGroupNames[i]
    end
    for i = 1, #lateActivationGroups do
        local groupName = lateActivationGroups[i]
        if Group.getByName(groupName) == nil then
            self:log("validate_skip_late_activation | group=" .. tostring(groupName))
        end
    end

    if #missing == 0 then
        self:log("validate | all_required_objects_present")
        if outputToGame == true then
            trigger.action.outText("TASK03 DEBUG：对象检查通过。", 10)
        end
        return true
    end

    for i = 1, #missing do
        self:log("validate_missing | " .. missing[i])
    end
    if outputToGame == true then
        for i = 1, #missing do
            trigger.action.outText("TASK03 DEBUG：" .. missing[i], 12)
        end
    end
    return false
end

function Task03BeirutExtractionController:ensureMenusForGroup(groupId)
    if groupId == nil or self.menusByGroupId[groupId] ~= nil then
        return
    end
    local root = missionCommands.addSubMenuForGroup(groupId, self.config.radioMenuRootText)
    local entries = {
        root = root,
    }

    missionCommands.addCommandForGroup(groupId, self.config.radioMenuAtlasText, root, function()
        if Task03BeirutExtractionControllerInstance then
            local playerState = Task03BeirutExtractionControllerInstance:getPlayerStateByGroupId(groupId)
            Task03BeirutExtractionControllerInstance:attemptAtlasCall(playerState)
        end
    end)

    missionCommands.addCommandForGroup(groupId, self.config.radioMenuAbortText, root, function()
        if Task03BeirutExtractionControllerInstance then
            local playerState = Task03BeirutExtractionControllerInstance:getPlayerStateByGroupId(groupId)
            Task03BeirutExtractionControllerInstance:registerAbortVote(playerState)
        end
    end)

    if self.config.debugMode == true then
        local debugMenu = missionCommands.addSubMenuForGroup(groupId, self.config.radioMenuDebugText, root)
        missionCommands.addCommandForGroup(groupId, "检查对象", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:validateMissionObjects(true)
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate A（黑场）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:startIntro()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate B（全部离地）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:triggerTakeoffGate()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate C（机场接触）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:triggerAirportContact()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate D（跑道恢复）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:debugForceRunwayRecovered()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate E（装甲首次受击）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                local playerState = Task03BeirutExtractionControllerInstance:getPlayerStateByGroupId(groupId)
                Task03BeirutExtractionControllerInstance:handleArmorFirstHit(playerState)
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Gate F（SA-15 开机）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:handleShoradCycle()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Atlas 成功放行", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                local playerState = Task03BeirutExtractionControllerInstance:getPlayerStateByGroupId(groupId)
                Task03BeirutExtractionControllerInstance:debugForceAtlasInbound(playerState)
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Atlas 进近", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:triggerAtlasApproach()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Atlas 落地", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:debugClearAirportRush("atlas_landed")
                Task03BeirutExtractionControllerInstance:debugClearRunwaySuppression("atlas_landed")
                Task03BeirutExtractionControllerInstance:triggerAtlasLanded()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 热装载开始", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:debugClearAirportRush("hot_load")
                Task03BeirutExtractionControllerInstance:debugClearRunwaySuppression("hot_load")
                Task03BeirutExtractionControllerInstance:triggerRavenLoad()
                Task03BeirutExtractionControllerInstance:startHotLoad()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 Atlas 起飞流程", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:debugForceAtlasDeparture()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 成功", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:triggerSuccess()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 进入拒止（Raven）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:enterDenialRaven()
            end
        end)
        missionCommands.addCommandForGroup(groupId, "强制 进入拒止（Atlas）", debugMenu, function()
            if Task03BeirutExtractionControllerInstance then
                Task03BeirutExtractionControllerInstance:enterDenialAtlas()
            end
        end)
    end

    self.menusByGroupId[groupId] = entries
end

function Task03BeirutExtractionController:ensureMenus()
    for _, playerState in pairs(self.playersByName) do
        if playerState.groupId ~= nil then
            self:ensureMenusForGroup(playerState.groupId)
        end
    end
end

function Task03BeirutExtractionController:startIntro()
    if self.introStarted == true then
        return
    end
    self.introStarted = true
    self:markPhase("intro")
    self:queueDialogueBlock("intro", "intro", {
        initialDelay = self.config.introInitialDelaySeconds,
        onComplete = function()
            timer.scheduleFunction(function()
                if Task03BeirutExtractionControllerInstance ~= nil then
                    Task03BeirutExtractionControllerInstance:markPhase("startup")
                end
                return nil
            end, {}, getCurrentTime() + self.config.introPostSilenceSeconds)
        end
    })
end

function Task03BeirutExtractionController:onWorldEvent(event)
    if event == nil or event.id == nil then
        return
    end

    if event.id == world.event.S_EVENT_HIT then
        local initiator = event.initiator
        if initiator and getPlayerName(initiator) then
            local targetGroupName = getEventTargetGroupName(event.target)
            if targetGroupName == self.config.mechAGroupName then
                self:handleArmorFirstHit(self.playersByName[getPlayerName(initiator)])
                return
            end
            for i = 1, #self.activeArmorGroupNames do
                if targetGroupName == self.activeArmorGroupNames[i] then
                    self:handleArmorFirstHit(self.playersByName[getPlayerName(initiator)])
                    return
                end
            end
        end
        return
    end

    if event.id == world.event.S_EVENT_DEAD
        or event.id == world.event.S_EVENT_CRASH
        or event.id == world.event.S_EVENT_KILL
    then
        local targetGroupName = getEventTargetGroupName(event.target)
        if targetGroupName == self.config.atlasGroupName then
            self:handleAtlasLost()
            return
        end
        if targetGroupName == self.config.ravenGroupName then
            self:handleRavenLost()
            return
        end
        if targetGroupName == self.config.shoradGroupName then
            local group = Group.getByName(self.config.shoradGroupName)
            if group == nil or #getAliveUnits(group) == 0 then
                self:handleShoradDead()
            end
            return
        end
    end
end

function Task03BeirutExtractionController:checkTakeoffGate()
    if self.takeoffTriggered == true then
        return
    end
    self:freezeEffectiveRosterIfReady()
    if self:allEffectivePlayersAirborne() then
        self:triggerTakeoffGate()
    end
end

function Task03BeirutExtractionController:checkAirportContactGate()
    if self.takeoffTriggered ~= true or self.airportContactTriggered == true then
        return
    end
    if self:isAnyEffectivePlayerInZone(self.config.airportRingZoneName) then
        self:triggerAirportContact()
    end
end

function Task03BeirutExtractionController:checkRunwayRecoveryGate()
    if self.runwayRecoveredTriggered == true then
        return
    end
    if self.airportRushTriggered ~= true then
        return
    end
    if self:isAirportRushCleared() ~= true then
        return
    end
    if self:isRunwayClearOfEnemies() ~= true then
        return
    end
    self.runwayRecoveredTriggered = true
    self:unlockAtlasCallWindow()
end

function Task03BeirutExtractionController:checkAtlasApproach()
    if self.atlasInboundTriggered ~= true or self.atlasApproachTriggered == true then
        return
    end
    if self:isAtlasInZone(self.config.airportRingZoneName) or self:isAnyEffectivePlayerInZone(self.config.airportRingZoneName) then
        self:triggerAtlasApproach()
    end
end

function Task03BeirutExtractionController:checkAtlasHoldArrival()
    return --[[
    if self.atlasHoldAnnounced == true then
        return
    end
    local inHoldZone = self:isAtlasInZone(self.config.atlasHoldZoneName) == true
    if inHoldZone == true and self.atlasWasInHoldZone ~= true then
        self.atlasHoldAnnounced = true
        self:notifyAllPlayers("AWACS / 灯塔：Atlas 已抵达汇合区，进入盘旋，等待机场肃清。", 10)
    end
    self.atlasWasInHoldZone = inHoldZone
    ]]
end

function Task03BeirutExtractionController:checkAtlasEscort()
    if self.atlasApproachTriggered ~= true or self.atlasEscortTriggered == true then
        return
    end
    local atlasUnit = self:getAtlasLeadUnit()
    local atlasPoint = getUnitPoint(atlasUnit)
    if atlasPoint == nil then
        return
    end
    local players = self:getOrderedEffectivePlayers()
    for i = 1, #players do
        local unit = self:getTrackedUnit(players[i])
        local point = getUnitPoint(unit)
        if point and get2dDistance(point, atlasPoint) <= self.config.atlasEscortRangeMeters then
            self:triggerAtlasEscort(players[i])
            return
        end
    end
end

function Task03BeirutExtractionController:checkAtlasLandedGate()
    if self.atlasInboundTriggered ~= true or self.atlasLandedTriggered == true then
        return
    end
    if self:isAtlasLanded() then
        self:triggerAtlasLanded()
    end
end

function Task03BeirutExtractionController:checkRavenGate()
    if self.ravenReleased ~= true or self.ravenGateTriggered == true then
        return
    end
    if self:isRavenInZone(self.config.ravenGateZoneName) then
        self:triggerRavenGate()
    end
end

function Task03BeirutExtractionController:checkRavenLoadGate()
    if self.ravenReleased ~= true or self.ravenLoadTriggered == true then
        return
    end
    if self:isRavenInZone(self.config.ravenLoadZoneName) then
        self:triggerRavenLoad()
        if self.atlasLandedTriggered == true then
            self:startHotLoad()
        end
    end
end

function Task03BeirutExtractionController:checkHotLoadGate()
    if self.hotLoadStarted ~= true or self.atlasDepartTriggered == true then
        return
    end
    if self.hotLoadCompleteTriggered ~= true and getCurrentTime() - (self.hotLoadStartTime or 0) >= self.config.hotLoadSeconds then
        self:markHotLoadComplete()
    end
    if self:isAtlasDepartureCleared() == true then
        self:startAtlasDeparture()
    end
end

function Task03BeirutExtractionController:checkAtlasRollingGate()
    if self.atlasDepartTriggered ~= true or self.atlasRollingTriggered == true then
        return
    end
    if self:isAtlasRolling() then
        self:triggerAtlasRolling()
    end
end

function Task03BeirutExtractionController:checkAtlasAirborneGate()
    if self.atlasDepartTriggered ~= true or self.atlasAirborneTriggered == true then
        return
    end
    if self:isAtlasAirborne() then
        self:triggerAtlasAirborne()
    end
end

function Task03BeirutExtractionController:checkSuccessGate()
    if self.atlasAirborneTriggered ~= true or self.successTriggered == true then
        return
    end
    if self:isAtlasSafeAtSea() then
        self:triggerSuccess()
    end
end

function Task03BeirutExtractionController:checkAtlasGroundStuck()
    if self.atlasLandedTriggered ~= true or self.atlasAirborneTriggered == true or self.hotLoadCompleteTriggered ~= true then
        return
    end
    if getCurrentTime() - (self.hotLoadCompleteTime or 0) >= self.config.atlasGroundStuckSeconds then
        self:playAnxietyIfNeeded()
    end
end

function Task03BeirutExtractionController:checkMissionFailureLines()
    if self.successTriggered == true or self.failTriggered == true then
        return
    end
    if self:isMechABreachingAirport() then
        self:handleMechABreach()
    end
end

function Task03BeirutExtractionController:tick()
    self:updatePlayerRoster()
    self:ensureMenus()
    self:checkDebugValidation()

    self:checkTakeoffGate()
    self:checkAirportContactGate()
    self:checkRunwayRecoveryGate()
    self:checkAtlasApproach()
    self:checkAtlasEscort()
    self:checkAtlasLandedGate()
    self:checkRavenGate()
    self:checkRavenLoadGate()
    self:checkHotLoadGate()
    self:checkAtlasRollingGate()
    self:checkAtlasAirborneGate()
    self:checkSuccessGate()
    self:checkAtlasGroundStuck()
    self:checkMissionFailureLines()
    self:playAnxietyIfNeeded()

    return getCurrentTime() + self.config.scanIntervalSeconds
end

function Task03BeirutExtractionController:start()
    self:log("start | version=" .. tostring(self.VERSION))
    if math and math.randomseed and os and os.time then
        pcall(function()
            math.randomseed(os.time())
        end)
    end

    _G.BEKAA_STORY_SKYNET_AMBUSH_LOCK = false
    if type(_G.SkynetStorySetAmbushLock) == "function" then
        pcall(_G.SkynetStorySetAmbushLock, false, "task03_start_reset")
    end

    _G.ProbeStoryOnSkynetGoLive = function(info)
        if Task03BeirutExtractionControllerInstance and Task03BeirutExtractionControllerInstance.onSkynetGoLive then
            Task03BeirutExtractionControllerInstance:onSkynetGoLive(info)
        end
    end

    if self.eventHandler == nil then
        self.eventHandler = {}
        function self.eventHandler:onEvent(event)
            if Task03BeirutExtractionControllerInstance and Task03BeirutExtractionControllerInstance.onWorldEvent then
                Task03BeirutExtractionControllerInstance:onWorldEvent(event)
            end
        end
        world.addEventHandler(self.eventHandler)
    end

    self:validateMissionObjects(false)
    self:startIntro()

    timer.scheduleFunction(function()
        if Task03BeirutExtractionControllerInstance then
            return Task03BeirutExtractionControllerInstance:tick()
        end
        return nil
    end, {}, getCurrentTime() + self.config.scanIntervalSeconds)
end

Task03BeirutExtractionControllerInstance = Task03BeirutExtractionController:create(_G.Task03BeirutExtractionConfig or {})
Task03BeirutExtractionControllerInstance:start()

end
