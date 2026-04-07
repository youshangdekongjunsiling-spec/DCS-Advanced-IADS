do

-- Required mission objects:
-- Zones:
--   ZONE_SHEMONA_CAL
--   ZONE_WP3_ENTRY
-- Static target:
--   静态-指挥中心-1
-- Frontline armor:
--   group names must contain one of BekaaStoryConfig.frontlineGroupNamePatterns
-- Optional Skynet hook:
--   _G.SkynetStorySetAmbushLock(locked, reason)

BekaaStoryController = BekaaStoryController or {}
BekaaStoryController.__index = BekaaStoryController

BekaaStoryController.VERSION = "bekaa-story-v1"
BekaaStoryController.LOG_PREFIX = "[BEKAA STORY] "

local DEFAULT_CONFIG = {
    playerCoalition = coalition.side.BLUE,
    targetCoalition = coalition.side.RED,
    shemonaZoneName = "ZONE_SHEMONA_CAL",
    wp3EntryZoneName = "ZONE_WP3_ENTRY",
    frontlineGroupNamePatterns = { "第七装甲师-第二装甲旅-第一营" },
    riyakStaticName = "静态-指挥中心-1",
    recon1MaxDistanceNm = 15,
    recon2MaxDistanceNm = 115,
    requireTargetingPod = true,
    allowPodCapableFallback = true,
    podCapableAircraftTypes = {
        ["F-16C_50"] = true,
        ["FA-18C_hornet"] = true,
        ["A-10C"] = true,
        ["A-10C_2"] = true,
        ["AV8BNA"] = true,
        ["JF-17"] = true,
        ["F-15ESE"] = true,
    },
    podKeywordPatterns = {
        "LITENING",
        "Litening",
        "ATFLIR",
        "SNIPER",
        "Sniper",
        "TGP",
        "Targeting Pod",
        "XR",
        "WMD7",
    },
    scanIntervalSeconds = 2,
    startupDelaySeconds = 35,
    phase4SilenceDelaySeconds = 4,
    retreatCallDelaySeconds = 20,
    missionEndDelaySeconds = 90,
    messageDurationSeconds = 10,
    debugDurationSeconds = 6,
    missionCompleteFlag = 9101,
    skynetLockFlag = 9102,
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

local function safeToString(value)
    if value == nil then
        return "nil"
    end
    return tostring(value)
end

local function round(value, digits)
    digits = digits or 0
    local factor = 10 ^ digits
    return math.floor(value * factor + 0.5) / factor
end

local function metersToNm(value)
    return value / 1852
end

local function nmToMeters(value)
    return value * 1852
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

local function containsPattern(source, patterns)
    if source == nil then
        return false
    end
    local text = tostring(source)
    for i = 1, #patterns do
        if string.find(text, patterns[i], 1, true) then
            return true
        end
    end
    return false
end

local function getUnitTypeName(unit)
    local okType, typeName = pcall(function()
        return unit:getTypeName()
    end)
    if okType then
        return typeName
    end
    return nil
end

local function getAliveUnits(group)
    local units = {}
    if group == nil or group:isExist() == false then
        return units
    end
    local okGroupUnits, groupUnits = pcall(function()
        return group:getUnits()
    end)
    if okGroupUnits and groupUnits then
        for i = 1, #groupUnits do
            local unit = groupUnits[i]
            if unit and unit:isExist() and unit:getLife() > 0 then
                units[#units + 1] = unit
            end
        end
    end
    return units
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

local function getUnitPoint(unit)
    local okPoint, point = pcall(function()
        return unit:getPoint()
    end)
    if okPoint then
        return point
    end
    return nil
end

local function getStaticPoint(staticObject)
    local okPoint, point = pcall(function()
        return staticObject:getPoint()
    end)
    if okPoint then
        return point
    end
    return nil
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
    return okLife and life and life > 0
end

local function getPlayerName(unit)
    local okPlayer, playerName = pcall(function()
        return unit:getPlayerName()
    end)
    if okPlayer then
        return playerName
    end
    return nil
end

local function isUnitInAir(unit)
    local okAir, inAir = pcall(function()
        return unit:inAir()
    end)
    return okAir and inAir == true
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

local function getTerrainHeight(point)
    if point == nil then
        return 0
    end
    local okHeight, height = pcall(function()
        return land.getHeight({ x = point.x, y = point.z })
    end)
    if okHeight and height then
        return height
    end
    return 0
end

local function createStoryLogger()
    local logger = {
        filePath = nil,
    }

    local okPath, logPath = pcall(function()
        if lfs and lfs.writedir then
            return lfs.writedir() .. "Logs\\bekaa-story.log"
        end
        return nil
    end)
    if okPath then
        logger.filePath = logPath
    end

    function logger:writeLine(line)
        env.info(BekaaStoryController.LOG_PREFIX .. line)
        if self.filePath == nil or io == nil then
            return
        end
        local okFile = pcall(function()
            local handle = io.open(self.filePath, "a")
            if handle then
                handle:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. line .. "\n")
                handle:close()
            end
        end)
        if not okFile then
            env.info(BekaaStoryController.LOG_PREFIX .. "story file logger unavailable")
            self.filePath = nil
        end
    end

    return logger
end

function BekaaStoryController:create(config)
    local instance = {
        config = mergeConfig(DEFAULT_CONFIG, config or {}),
        logger = createStoryLogger(),
        started = false,
        phase = "idle",
        phaseStartedAt = 0,
        firstPlayerDetectedAt = nil,
        playersByUnitName = {},
        menusByGroupId = {},
        eventHandler = nil,
        search1Completed = false,
        search2Completed = false,
        missionCompleted = false,
        skynetAmbushLocked = true,
        sequenceGeneration = 0,
    }
    setmetatable(instance, BekaaStoryController)
    return instance
end

function BekaaStoryController:log(message)
    self.logger:writeLine(safeToString(message))
end

function BekaaStoryController:notifyCoalition(message, duration)
    trigger.action.outTextForCoalition(self.config.playerCoalition, tostring(message), duration or self.config.messageDurationSeconds)
end

function BekaaStoryController:getTrackedPlayerState(unitName)
    if unitName == nil then
        return nil
    end
    return self.playersByUnitName[unitName]
end

function BekaaStoryController:getTrackedUnit(playerState)
    if playerState == nil or playerState.unitName == nil then
        return nil
    end
    local unit = Unit.getByName(playerState.unitName)
    if isUnitAlive(unit) then
        return unit
    end
    return nil
end

function BekaaStoryController:notifyPlayer(playerState, message, duration)
    local text = tostring(message)
    local messageDuration = duration or self.config.messageDurationSeconds
    local unit = self:getTrackedUnit(playerState)

    if unit and type(trigger.action.outTextForUnit) == "function" then
        local okUnitId, unitId = pcall(function()
            return unit:getID()
        end)
        if okUnitId and unitId then
            local okSend = pcall(function()
                trigger.action.outTextForUnit(unitId, text, messageDuration)
            end)
            if okSend then
                return
            end
        end
    end

    if playerState and playerState.groupId then
        local okGroupSend = pcall(function()
            trigger.action.outTextForGroup(playerState.groupId, text, messageDuration)
        end)
        if okGroupSend then
            return
        end
    end

    self:notifyCoalition(text, messageDuration)
end

function BekaaStoryController:notifyDebug(message)
    if _G.SkynetRuntimeDebugNotify then
        pcall(_G.SkynetRuntimeDebugNotify, "[Story] " .. tostring(message))
    else
        trigger.action.outText("[Story DBG] " .. tostring(message), self.config.debugDurationSeconds)
    end
end

function BekaaStoryController:notifyDebugForPlayer(playerState, message)
    if _G.SkynetRuntimeDebugNotify then
        pcall(
            _G.SkynetRuntimeDebugNotify,
            "[Story " .. tostring(playerState and playerState.playerName or "?") .. "] " .. tostring(message)
        )
    else
        self:notifyPlayer(playerState, "[Story DBG] " .. tostring(message), self.config.debugDurationSeconds)
    end
end

function BekaaStoryController:getActivePlayerStates()
    local states = {}
    for _, playerState in pairs(self.playersByUnitName) do
        if playerState.activeParticipant == true and playerState.alive == true and self:getTrackedUnit(playerState) ~= nil then
            states[#states + 1] = playerState
        end
    end
    table.sort(states, function(a, b)
        return tostring(a.unitName) < tostring(b.unitName)
    end)
    return states
end

function BekaaStoryController:notifyActivePlayers(message, duration)
    local activePlayers = self:getActivePlayerStates()
    for i = 1, #activePlayers do
        self:notifyPlayer(activePlayers[i], message, duration)
    end
end

function BekaaStoryController:speakerLineToPlayer(playerState, speaker, text, duration)
    local line = tostring(speaker) .. ":\n" .. tostring(text)
    self:notifyPlayer(playerState, line, duration)
    self:log(
        "radio | player=" .. tostring(playerState and playerState.playerName or "nil")
        .. " | unit=" .. tostring(playerState and playerState.unitName or "nil")
        .. " | " .. tostring(speaker)
        .. " | " .. tostring(text)
    )
end

function BekaaStoryController:speakerLine(speaker, text, duration)
    local line = tostring(speaker) .. "：\n" .. tostring(text)
    self:notifyCoalition(line, duration)
    self:log("radio | " .. tostring(speaker) .. " | " .. tostring(text))
end

function BekaaStoryController:setFlag(flag, value)
    pcall(function()
        trigger.action.setUserFlag(flag, value)
    end)
end

function BekaaStoryController:setSkynetAmbushLock(locked, reason)
    self.skynetAmbushLocked = locked == true
    _G.BEKAA_STORY_SKYNET_AMBUSH_LOCK = self.skynetAmbushLocked
    self:setFlag(self.config.skynetLockFlag, self.skynetAmbushLocked and 1 or 0)
    if _G.SkynetStorySetAmbushLock then
        pcall(_G.SkynetStorySetAmbushLock, self.skynetAmbushLocked, reason or "story")
    end
    self:log("skynet_lock | locked=" .. tostring(self.skynetAmbushLocked) .. " | reason=" .. tostring(reason))
end

function BekaaStoryController:getZone(zoneName)
    local okZone, zone = pcall(function()
        return trigger.misc.getZone(zoneName)
    end)
    if okZone then
        return zone
    end
    return nil
end

function BekaaStoryController:queueSequence(sequenceName, entries, initialDelay)
    self.sequenceGeneration = self.sequenceGeneration + 1
    local sequenceGeneration = self.sequenceGeneration
    local currentDelay = initialDelay or 0
    for i = 1, #entries do
        local entry = entries[i]
        local executeAt = getCurrentTime() + currentDelay
        timer.scheduleFunction(function(args)
            if self.sequenceGeneration ~= args.sequenceGeneration then
                return nil
            end
            self:speakerLine(args.speaker, args.text, args.duration)
            return nil
        end, {
            speaker = entry.speaker,
            text = entry.text,
            duration = entry.duration or self.config.messageDurationSeconds,
            sequenceGeneration = sequenceGeneration,
        }, executeAt)
        currentDelay = currentDelay + (entry.delay or self.config.messageDurationSeconds)
    end
    self:log("sequence_start | name=" .. tostring(sequenceName) .. " | entries=" .. tostring(#entries))
end

function BekaaStoryController:queuePlayerSequence(playerState, sequenceName, entries, initialDelay)
    if playerState == nil then
        return
    end

    local now = getCurrentTime()
    local executeAt = math.max(playerState.nextMessageAt or now, now) + (initialDelay or 0)

    for i = 1, #entries do
        local entry = entries[i]
        local scheduledTime = executeAt
        timer.scheduleFunction(function(args)
            local latestState = self:getTrackedPlayerState(args.unitName)
            if latestState == nil then
                return nil
            end
            self:speakerLineToPlayer(latestState, args.speaker, args.text, args.duration)
            return nil
        end, {
            unitName = playerState.unitName,
            speaker = entry.speaker,
            text = entry.text,
            duration = entry.duration or self.config.messageDurationSeconds,
        }, scheduledTime)
        executeAt = scheduledTime + (entry.delay or self.config.messageDurationSeconds)
    end

    playerState.nextMessageAt = executeAt
    self:log(
        "player_sequence_start | player=" .. tostring(playerState.playerName)
        .. " | unit=" .. tostring(playerState.unitName)
        .. " | name=" .. tostring(sequenceName)
        .. " | entries=" .. tostring(#entries)
    )
end

function BekaaStoryController:markPhase(phaseName)
    self.phase = phaseName
    self.phaseStartedAt = getCurrentTime()
    self:log("phase | " .. tostring(phaseName))
end

function BekaaStoryController:markPlayerStoryPhase(playerState, phaseName)
    if playerState == nil then
        return
    end
    playerState.storyPhase = phaseName
    playerState.storyPhaseStartedAt = getCurrentTime()
    self:log(
        "player_phase | player=" .. tostring(playerState.playerName)
        .. " | unit=" .. tostring(playerState.unitName)
        .. " | phase=" .. tostring(phaseName)
    )
end

-- Override coalition-wide dialogue with per-player delivery.
function BekaaStoryController:speakerLine(speaker, text, duration)
    local line = tostring(speaker) .. "：\n" .. tostring(text)
    self:notifyActivePlayers(line, duration)
    self:log("radio_broadcast | " .. tostring(speaker) .. " | " .. tostring(text))
end

function BekaaStoryController:findPlayerUnits()
    local playerUnits = {}
    local groups = coalition.getGroups(self.config.playerCoalition) or {}
    for i = 1, #groups do
        local group = groups[i]
        if group and group:isExist() then
            local units = getAliveUnits(group)
            for j = 1, #units do
                local unit = units[j]
                local playerName = getPlayerName(unit)
                if playerName and string.len(playerName) > 0 then
                    playerUnits[#playerUnits + 1] = unit
                end
            end
        end
    end
    return playerUnits
end

function BekaaStoryController:ensurePlayerTracked(unit)
    local unitName = Unit.getName(unit)
    local playerName = getPlayerName(unit)
    local group = getUnitGroup(unit)
    if unitName == nil or playerName == nil or group == nil then
        return nil
    end
    local groupId = Group.getID(group)
    local playerState = self.playersByUnitName[unitName]
    if playerState == nil then
        playerState = {
            unitName = unitName,
            playerName = playerName,
            groupId = groupId,
            groupName = getGroupName(group),
            firstSeenAt = getCurrentTime(),
            activeParticipant = true,
            alive = true,
            storyPhase = "new",
            storyPhaseStartedAt = 0,
            nextMessageAt = 0,
            introStarted = false,
            startupBriefed = false,
            takeoffBriefed = false,
            recon1Prompted = false,
            recon2Prompted = false,
            search1SuccessSeen = false,
            search2SuccessSeen = false,
            ambushSeen = false,
            retreatSeen = false,
            missionCompleteSeen = false,
        }
        self.playersByUnitName[unitName] = playerState
        self:log("player_detected | unit=" .. tostring(unitName) .. " | player=" .. tostring(playerName) .. " | group=" .. tostring(playerState.groupName))
    else
        playerState.playerName = playerName
        playerState.groupId = groupId
        playerState.groupName = getGroupName(group)
        playerState.alive = true
    end
    return playerState
end

function BekaaStoryController:updatePlayerRoster()
    local seen = {}
    local playerUnits = self:findPlayerUnits()
    local newlyDetected = {}
    for i = 1, #playerUnits do
        local unit = playerUnits[i]
        local playerState = self:ensurePlayerTracked(unit)
        if playerState then
            seen[playerState.unitName] = true
            self:ensureMenusForGroup(playerState.groupId)
            if playerState.introStarted ~= true then
                newlyDetected[#newlyDetected + 1] = playerState
            end
        end
    end
    for unitName, playerState in pairs(self.playersByUnitName) do
        if seen[unitName] then
            playerState.lastSeenAt = getCurrentTime()
            playerState.alive = true
        else
            playerState.alive = false
        end
    end
    if self.firstPlayerDetectedAt == nil and #playerUnits > 0 then
        self.firstPlayerDetectedAt = getCurrentTime()
    end
    for i = 1, #newlyDetected do
        self:beginIntroTimeline(newlyDetected[i])
    end
end

function BekaaStoryController:ensureMenusForGroup(groupId)
    if groupId == nil or self.menusByGroupId[groupId] then
        return
    end
    local root = missionCommands.addSubMenuForGroup(groupId, "侦察报告")
    local menuData = {
        root = root,
        south = missionCommands.addCommandForGroup(groupId, "提交南口照片", root, function()
            self:handleReconSubmission(groupId, 1)
        end),
        riyak = missionCommands.addCommandForGroup(groupId, "提交里亚格照片", root, function()
            self:handleReconSubmission(groupId, 2)
        end),
        hint = missionCommands.addCommandForGroup(groupId, "请求当前任务提示", root, function()
            self:sendTaskHintToGroup(groupId)
        end),
    }
    self.menusByGroupId[groupId] = menuData
    self:log("radio_menu_create | groupId=" .. tostring(groupId))
end

function BekaaStoryController:getPlayerStateByGroupId(groupId)
    for _, playerState in pairs(self.playersByUnitName) do
        if playerState.groupId == groupId and playerState.alive == true then
            local unit = Unit.getByName(playerState.unitName)
            if isUnitAlive(unit) then
                return playerState, unit
            end
        end
    end
    return nil, nil
end

function BekaaStoryController:getNearestFrontlineTarget(unitPoint)
    local groups = coalition.getGroups(self.config.targetCoalition) or {}
    local best = nil
    local bestDistance = nil
    for i = 1, #groups do
        local group = groups[i]
        local groupName = group and getGroupName(group) or nil
        if groupName and containsPattern(groupName, self.config.frontlineGroupNamePatterns) then
            local units = getAliveUnits(group)
            for j = 1, #units do
                local point = getUnitPoint(units[j])
                if point then
                    local distance = get2dDistance(unitPoint, point)
                    if bestDistance == nil or distance < bestDistance then
                        bestDistance = distance
                        best = {
                            groupName = groupName,
                            unitName = Unit.getName(units[j]),
                            point = point,
                            distanceMeters = distance,
                        }
                    end
                end
            end
        end
    end
    return best
end

function BekaaStoryController:getRiyakStaticTarget()
    local staticObject = StaticObject.getByName(self.config.riyakStaticName)
    if staticObject == nil or StaticObject.isExist(staticObject) ~= true then
        return nil
    end
    return {
        name = self.config.riyakStaticName,
        point = getStaticPoint(staticObject),
    }
end

function BekaaStoryController:hasReconPod(unit)
    if self.config.requireTargetingPod ~= true then
        return true, "pod_check_disabled"
    end
    local okAmmo, ammo = pcall(function()
        return unit:getAmmo()
    end)
    if okAmmo and ammo then
        for i = 1, #ammo do
            local ammoEntry = ammo[i]
            local candidateTexts = {}
            if ammoEntry.desc then
                candidateTexts[#candidateTexts + 1] = ammoEntry.desc.typeName
                candidateTexts[#candidateTexts + 1] = ammoEntry.desc.displayName
            end
            if ammoEntry.name then
                candidateTexts[#candidateTexts + 1] = ammoEntry.name
            end
            for j = 1, #candidateTexts do
                local candidate = candidateTexts[j]
                if candidate and containsPattern(candidate, self.config.podKeywordPatterns) then
                    return true, "pod_keyword_match"
                end
            end
        end
    end
    if self.config.allowPodCapableFallback == true then
        local typeName = getUnitTypeName(unit)
        if typeName and self.config.podCapableAircraftTypes[typeName] then
            return true, "aircraft_type_fallback"
        end
    end
    return false, "no_recon_pod_detected"
end

function BekaaStoryController:hasLineOfSight(unitPoint, targetPoint)
    local okVisible, visible = pcall(function()
        return land.isVisible(unitPoint, targetPoint)
    end)
    if okVisible then
        return visible == true, "land.isVisible"
    end
    local samples = 12
    local terrainClearanceMeters = 30
    for i = 1, samples - 1 do
        local ratio = i / samples
        local samplePoint = {
            x = unitPoint.x + (targetPoint.x - unitPoint.x) * ratio,
            y = unitPoint.y + (targetPoint.y - unitPoint.y) * ratio,
            z = unitPoint.z + (targetPoint.z - unitPoint.z) * ratio,
        }
        local terrainHeight = getTerrainHeight(samplePoint)
        if terrainHeight + terrainClearanceMeters > samplePoint.y then
            return false, "terrain_profile_block"
        end
    end
    return true, "terrain_profile_clear"
end

function BekaaStoryController:validateReconSubmission(unit, reconIndex)
    if isUnitAlive(unit) ~= true then
        return false, "unit_dead"
    end
    if isUnitInAir(unit) ~= true then
        return false, "not_in_air"
    end
    local hasPod, podReason = self:hasReconPod(unit)
    if hasPod ~= true then
        return false, podReason
    end
    local unitPoint = getUnitPoint(unit)
    if unitPoint == nil then
        return false, "no_unit_point"
    end

    if reconIndex == 1 then
        local target = self:getNearestFrontlineTarget(unitPoint)
        if target == nil then
            return false, "no_frontline_target"
        end
        if target.distanceMeters > nmToMeters(self.config.recon1MaxDistanceNm) then
            return false, "distance_too_far_frontline", target
        end
        local lineOfSight, losReason = self:hasLineOfSight(unitPoint, target.point)
        if lineOfSight ~= true then
            return false, "line_of_sight_blocked:" .. tostring(losReason), target
        end
        return true, "valid_frontline_photo", target
    end

    if reconIndex == 2 then
        local target = self:getRiyakStaticTarget()
        if target == nil or target.point == nil then
            return false, "riyak_target_missing"
        end
        local distanceMeters = get2dDistance(unitPoint, target.point)
        if distanceMeters > nmToMeters(self.config.recon2MaxDistanceNm) then
            target.distanceMeters = distanceMeters
            return false, "distance_too_far_riyak", target
        end
        local lineOfSight, losReason = self:hasLineOfSight(unitPoint, target.point)
        if lineOfSight ~= true then
            target.distanceMeters = distanceMeters
            return false, "line_of_sight_blocked:" .. tostring(losReason), target
        end
        target.distanceMeters = distanceMeters
        return true, "valid_riyak_photo", target
    end

    return false, "invalid_recon_index"
end

function BekaaStoryController:sendTaskHintToGroup(groupId)
    local hint
    if self.phase == "phase1_recon" then
        hint = "前往谢莫纳建立观察位，使用吊舱侦察谷口装甲，进入15海里内后通过菜单提交南口照片。"
    elseif self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" then
        hint = "向北推进至WP3附近，使用吊舱侦察里亚格的静态-指挥中心-1，然后通过菜单提交里亚格照片。"
    elseif self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" then
        hint = "防空伏击已开始，立即脱离并防御机动。"
    else
        hint = "按AWACS指示推进。"
    end
    trigger.action.outTextForGroup(groupId, hint, self.config.messageDurationSeconds)
    self:log("task_hint | groupId=" .. tostring(groupId) .. " | phase=" .. tostring(self.phase))
end

function BekaaStoryController:handleReconSubmission(groupId, reconIndex)
    local playerState, unit = self:getPlayerStateByGroupId(groupId)
    if playerState == nil or unit == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end

    if reconIndex == 1 and self.phase ~= "phase1_recon" then
        trigger.action.outTextForGroup(groupId, "当前尚未进入第一轮侦察阶段。", self.config.messageDurationSeconds)
        return
    end
    if reconIndex == 2 and self.phase ~= "phase2_recon" then
        trigger.action.outTextForGroup(groupId, "当前尚未进入第二轮侦察阶段。", self.config.messageDurationSeconds)
        return
    end

    local okSubmission, reason, target = self:validateReconSubmission(unit, reconIndex)
    local distanceNm = target and target.distanceMeters and round(metersToNm(target.distanceMeters), 1) or nil
    self:log(
        "recon_submit | phase=" .. tostring(self.phase)
        .. " | player=" .. tostring(playerState.playerName)
        .. " | unit=" .. tostring(playerState.unitName)
        .. " | recon=" .. tostring(reconIndex)
        .. " | ok=" .. tostring(okSubmission)
        .. " | reason=" .. tostring(reason)
        .. " | distanceNm=" .. tostring(distanceNm)
    )

    if okSubmission ~= true then
        if reconIndex == 1 then
            trigger.action.outTextForGroup(groupId, "AWACS：你们的照片不够清晰，请靠近点重拍。", self.config.messageDurationSeconds)
        else
            trigger.action.outTextForGroup(groupId, "AWACS：画面不够，再靠近。", self.config.messageDurationSeconds)
        end
        return
    end

    if reconIndex == 1 and self.search1Completed ~= true then
        self.search1Completed = true
        self:setFlag(9103, 1)
        self:handleSearch1Success(playerState, target)
        return
    end
    if reconIndex == 2 and self.search2Completed ~= true then
        self.search2Completed = true
        self:setFlag(9104, 1)
        self:handleSearch2Success(playerState, target)
        return
    end

    trigger.action.outTextForGroup(groupId, "AWACS：已收到，阶段已推进。", self.config.messageDurationSeconds)
end

function BekaaStoryController:handleSearch1Success(playerState, target)
    self:markPhase("phase2_transit_wp3")
    self:speakerLine("AWACS", "收到。确认装甲单位，数量很多，正在向谷口推进。", 10)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "推进速度太快了。按这个速度，明天早上就会到谢莫纳。", 10)
        return nil
    end, {}, getCurrentTime() + 9)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "我看到伴随单位。像防空。", 8)
        return nil
    end, {}, getCurrentTime() + 18)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "未检测到防空雷达信号。如果存在，应处于静默状态。", 10)
        return nil
    end, {}, getCurrentTime() + 26)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "那我们可以从高空打。激光制导。避开这些东西。", 9)
        return nil
    end, {}, getCurrentTime() + 36)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "当前未发现高空防空威胁。继续推进，前往航路点3，搜索谷地内部。", 12)
        return nil
    end, {}, getCurrentTime() + 46)
    self:notifyDebug("search1 complete by " .. tostring(playerState.playerName))
end

function BekaaStoryController:handleSearch2Success(playerState, target)
    self:markPhase("phase3_silence")
    self:speakerLine("AWACS", "收到图像。", 6)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "这不是前沿部队。这是集结区。他们在这里组织进攻。", 10)
        return nil
    end, {}, getCurrentTime() + 7)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "规模比想象的大。", 8)
        return nil
    end, {}, getCurrentTime() + 18)
    timer.scheduleFunction(function()
        self:beginAmbushSequence()
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 22)
    self:notifyDebug("search2 complete by " .. tostring(playerState.playerName))
end

function BekaaStoryController:beginAmbushSequence()
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.missionCompleted == true then
        return
    end
    self:markPhase("phase4_ambush")
    self:notifyCoalition("……", 3)
    timer.scheduleFunction(function()
        self:setSkynetAmbushLock(false, "story_ambush_release")
        self:speakerLine("AWACS", "锁定！！锁定！！多源雷达上线！！SA-11！！", 10)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "导弹发射！！", 8)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 8)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "刚才没有任何信号！！", 8)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 15)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "它们刚才是关机状态——它们一直在那里。一直在跟踪你们。", 10)
        self:markPhase("phase5_retreat")
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 24)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "全体撤离！！你们在包线内！！立即脱离！！防御机动！！", 12)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.retreatCallDelaySeconds)
    timer.scheduleFunction(function()
        self:finishMission()
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.missionEndDelaySeconds)
end

function BekaaStoryController:finishMission()
    if self.missionCompleted == true then
        return
    end
    self.missionCompleted = true
    self:markPhase("complete")
    self:setFlag(self.config.missionCompleteFlag, 1)
    self:speakerLine("AWACS", "继续撤出……确认。整片谷地，都是它们的。", 10)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "没有信号……不是因为没有系统。是因为它们选择不发射。", 12)
        return nil
    end, {}, getCurrentTime() + 10)
end

function BekaaStoryController:beginIntroTimeline()
    if self.started == true then
        return
    end
    self.started = true
    self:setSkynetAmbushLock(true, "story_start")
    self:markPhase("phase_minus_2")
    self:queueSequence("cold_start", {
        { speaker = "地面频率", text = "今天早上边境那边又打起来了。", delay = 6, duration = 7 },
        { speaker = "地面频率", text = "听说黎巴嫩那边已经乱了。", delay = 7, duration = 7 },
        { speaker = "僚机", text = "我们这是去干嘛，侦察？", delay = 7, duration = 7 },
        { speaker = "长机", text = "不知道。他们自己也不知道。", delay = 10, duration = 9 },
    }, 2)
    timer.scheduleFunction(function()
        self:beginStartupPhase()
        return nil
    end, {}, getCurrentTime() + self.config.startupDelaySeconds)
end

function BekaaStoryController:beginStartupPhase()
    if self.phase == "phase0_takeoff" or self.phase == "phase1_recon" or self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" or self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end
    self:markPhase("phase_minus_1")
    self:queueSequence("startup_taxi", {
        { speaker = "塔台", text = "Alpha flight，允许启动。", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "所有单位，当前空域清晰。", delay = 8, duration = 8 },
        { speaker = "僚机", text = "你听说了吗？谷地那边整个断了。", delay = 8, duration = 8 },
        { speaker = "长机", text = "嗯。连卫星都看不见。", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "贝卡谷地当前无电磁活动。重复，无电磁活动。", delay = 10, duration = 10 },
    }, 0)
end

function BekaaStoryController:beginTakeoffPhase()
    if self.phase == "phase0_takeoff" or self.phase == "phase1_recon" or self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" or self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end
    self:markPhase("phase0_takeoff")
    self:queueSequence("takeoff", {
        { speaker = "塔台", text = "Alpha flight，允许起飞。", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "空情清晰，无空中目标。仅检测到三处黎巴嫩固定雷达站。未发现新增节点。", delay = 11, duration = 11 },
        { speaker = "僚机", text = "听起来挺干净。", delay = 7, duration = 7 },
        { speaker = "长机", text = "太干净了。", delay = 8, duration = 8 },
    }, 0)
end

function BekaaStoryController:beginRecon1Phase()
    if self.search1Completed == true or self.phase == "phase1_recon" or self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" or self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end
    self:markPhase("phase1_recon")
    self:queueSequence("recon1", {
        { speaker = "AWACS", text = "你们正在接近谢莫纳。在那里建立观察位置。", delay = 9, duration = 9 },
        { speaker = "僚机", text = "如果那边真的有部队，这么大规模，不可能没信号。", delay = 9, duration = 9 },
        { speaker = "AWACS", text = "同意。但我们确实没有看到。", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "Alpha flight，保持高度。使用吊舱侦察谷地出口。报告你们的接触。", delay = 10, duration = 10 },
    }, 0)
end

function BekaaStoryController:beginRecon2Phase()
    if self.search1Completed ~= true or self.search2Completed == true or self.phase == "phase2_recon" or self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end
    self:markPhase("phase2_recon")
    self:queueSequence("recon2", {
        { speaker = "AWACS", text = "前往航路点3，搜索谷地内部。重点观察里亚格。", delay = 10, duration = 10 },
        { speaker = "僚机", text = "看起来他们还没准备好。", delay = 7, duration = 7 },
        { speaker = "长机", text = "或者我们还没看到。", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "收到后通过无线电提交图像。", delay = 8, duration = 8 },
    }, 0)
end

function BekaaStoryController:checkPhaseTriggers()
    local playerUnits = self:findPlayerUnits()
    local anyAirborne = false
    for i = 1, #playerUnits do
        local unit = playerUnits[i]
        if isUnitInAir(unit) then
            anyAirborne = true
            break
        end
    end

    if anyAirborne and (self.phase == "phase_minus_2" or self.phase == "phase_minus_1") then
        self:beginTakeoffPhase()
    end

    if self.search1Completed ~= true then
        local zone = self:getZone(self.config.shemonaZoneName)
        if zone then
            for i = 1, #playerUnits do
                local point = getUnitPoint(playerUnits[i])
                if point and pointInZone(point, zone) then
                    self:beginRecon1Phase()
                    break
                end
            end
        end
    end

    if self.search1Completed == true and self.search2Completed ~= true and (self.phase == "phase2_transit_wp3" or self.phase == "phase1_recon" or self.phase == "phase0_takeoff") then
        local zone = self:getZone(self.config.wp3EntryZoneName)
        if zone then
            for i = 1, #playerUnits do
                local point = getUnitPoint(playerUnits[i])
                if point and pointInZone(point, zone) then
                    self:beginRecon2Phase()
                    break
                end
            end
        end
    end
end

-- Per-player story flow overrides.
function BekaaStoryController:beginIntroTimeline(playerState)
    if playerState == nil or playerState.introStarted == true then
        return
    end

    playerState.introStarted = true
    playerState.activeParticipant = true

    if self.started ~= true then
        self.started = true
        self:setSkynetAmbushLock(true, "story_start")
        self:markPhase("phase_minus_2")
    end

    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        self:markPlayerStoryPhase(playerState, self.phase)
        self:notifyPlayer(playerState, "AWACS：战区已进入交战状态，按当前任务提示执行。", self.config.messageDurationSeconds)
        return
    end

    self:markPlayerStoryPhase(playerState, "phase_minus_2")
    self:queuePlayerSequence(playerState, "cold_start", {
        { speaker = "鍦伴潰棰戠巼", text = "浠婂ぉ鏃╀笂杈瑰閭ｈ竟鍙堟墦璧锋潵浜嗐€?", delay = 6, duration = 7 },
        { speaker = "鍦伴潰棰戠巼", text = "鍚榛庡反瀚╅偅杈瑰凡缁忎贡浜嗐€?", delay = 7, duration = 7 },
        { speaker = "鍍氭満", text = "鎴戜滑杩欐槸鍘诲共鍢涳紝渚﹀療锛?", delay = 7, duration = 7 },
        { speaker = "闀挎満", text = "涓嶇煡閬撱€備粬浠嚜宸变篃涓嶇煡閬撱€?", delay = 10, duration = 9 },
    }, 2)

    timer.scheduleFunction(function(args)
        local latestState = self:getTrackedPlayerState(args.unitName)
        if latestState then
            self:beginStartupPhase(latestState)
        end
        return nil
    end, { unitName = playerState.unitName }, getCurrentTime() + self.config.startupDelaySeconds)
end

function BekaaStoryController:beginStartupPhase(playerState)
    if playerState == nil or playerState.startupBriefed == true then
        return
    end
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end

    playerState.startupBriefed = true
    self:markPlayerStoryPhase(playerState, "phase_minus_1")
    self:queuePlayerSequence(playerState, "startup_taxi", {
        { speaker = "濉斿彴", text = "Alpha flight锛屽厑璁稿惎鍔ㄣ€?", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "鎵€鏈夊崟浣嶏紝褰撳墠绌哄煙娓呮櫚銆?", delay = 8, duration = 8 },
        { speaker = "鍍氭満", text = "浣犲惉璇翠簡鍚楋紵璋峰湴閭ｈ竟鏁翠釜鏂簡銆?", delay = 8, duration = 8 },
        { speaker = "闀挎満", text = "鍡€傝繛鍗槦閮界湅涓嶈銆?", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "璐濆崱璋峰湴褰撳墠鏃犵數纾佹椿鍔ㄣ€傞噸澶嶏紝鏃犵數纾佹椿鍔ㄣ€?", delay = 10, duration = 10 },
    }, 0)
end

function BekaaStoryController:beginTakeoffPhase(playerState)
    if playerState == nil or playerState.takeoffBriefed == true then
        return
    end
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end

    playerState.takeoffBriefed = true
    if self.phase == "phase_minus_2" or self.phase == "phase_minus_1" then
        self:markPhase("phase0_takeoff")
    end
    self:markPlayerStoryPhase(playerState, "phase0_takeoff")
    self:queuePlayerSequence(playerState, "takeoff", {
        { speaker = "濉斿彴", text = "Alpha flight锛屽厑璁歌捣椋炪€?", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "绌烘儏娓呮櫚锛屾棤绌轰腑鐩爣銆備粎妫€娴嬪埌涓夊榛庡反瀚╁浐瀹氶浄杈剧珯銆傛湭鍙戠幇鏂板鑺傜偣銆?", delay = 11, duration = 11 },
        { speaker = "鍍氭満", text = "鍚捣鏉ユ尯骞插噣銆?", delay = 7, duration = 7 },
        { speaker = "闀挎満", text = "澶共鍑€浜嗐€?", delay = 8, duration = 8 },
    }, 0)
end

function BekaaStoryController:beginRecon1Phase(playerState)
    if playerState == nil or playerState.recon1Prompted == true then
        return
    end
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end

    playerState.recon1Prompted = true
    if self.search1Completed ~= true and (self.phase == "phase0_takeoff" or self.phase == "phase_minus_1" or self.phase == "phase_minus_2" or self.phase == "idle") then
        self:markPhase("phase1_recon")
    end
    self:markPlayerStoryPhase(playerState, "phase1_recon")
    self:queuePlayerSequence(playerState, "recon1", {
        { speaker = "AWACS", text = "浣犱滑姝ｅ湪鎺ヨ繎璋㈣帿绾炽€傚湪閭ｉ噷寤虹珛瑙傚療浣嶇疆銆?", delay = 9, duration = 9 },
        { speaker = "鍍氭満", text = "濡傛灉閭ｈ竟鐪熺殑鏈夐儴闃燂紝杩欎箞澶ц妯★紝涓嶅彲鑳芥病淇″彿銆?", delay = 9, duration = 9 },
        { speaker = "AWACS", text = "鍚屾剰銆備絾鎴戜滑纭疄娌℃湁鐪嬪埌銆?", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "Alpha flight锛屼繚鎸侀珮搴︺€備娇鐢ㄥ悐鑸变睛瀵熻胺鍦板嚭鍙ｃ€傛姤鍛婁綘浠殑鎺ヨЕ銆?", delay = 10, duration = 10 },
    }, 0)
end

function BekaaStoryController:beginRecon2Phase(playerState)
    if playerState == nil or playerState.recon2Prompted == true then
        return
    end
    if self.search1Completed ~= true then
        return
    end
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.phase == "complete" then
        return
    end

    playerState.recon2Prompted = true
    if self.search2Completed ~= true and (self.phase == "phase2_transit_wp3" or self.phase == "phase1_recon" or self.phase == "phase0_takeoff") then
        self:markPhase("phase2_recon")
    end
    self:markPlayerStoryPhase(playerState, "phase2_recon")
    self:queuePlayerSequence(playerState, "recon2", {
        { speaker = "AWACS", text = "鍓嶅線鑸矾鐐?锛屾悳绱㈣胺鍦板唴閮ㄣ€傞噸鐐硅瀵熼噷浜氭牸銆?", delay = 10, duration = 10 },
        { speaker = "鍍氭満", text = "鐪嬭捣鏉ヤ粬浠繕娌″噯澶囧ソ銆?", delay = 7, duration = 7 },
        { speaker = "闀挎満", text = "鎴栬€呮垜浠繕娌＄湅鍒般€?", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "鏀跺埌鍚庨€氳繃鏃犵嚎鐢垫彁浜ゅ浘鍍忋€?", delay = 8, duration = 8 },
    }, 0)
end

function BekaaStoryController:handleSearch1Success(playerState, target)
    self:markPhase("phase2_transit_wp3")
    playerState.search1SuccessSeen = true
    self:markPlayerStoryPhase(playerState, "phase2_transit_wp3")
    self:speakerLineToPlayer(playerState, "AWACS", "鏀跺埌銆傜‘璁よ鐢插崟浣嶏紝鏁伴噺寰堝锛屾鍦ㄥ悜璋峰彛鎺ㄨ繘銆?", 10)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "AWACS", "鎺ㄨ繘閫熷害澶揩浜嗐€傛寜杩欎釜閫熷害锛屾槑澶╂棭涓婂氨浼氬埌璋㈣帿绾炽€?", 10)
        return nil
    end, {}, getCurrentTime() + 9)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "鍍氭満", "鎴戠湅鍒颁即闅忓崟浣嶃€傚儚闃茬┖銆?", 8)
        return nil
    end, {}, getCurrentTime() + 18)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "AWACS", "鏈娴嬪埌闃茬┖闆疯揪淇″彿銆傚鏋滃瓨鍦紝搴斿浜庨潤榛樼姸鎬併€?", 10)
        return nil
    end, {}, getCurrentTime() + 26)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "鍍氭満", "閭ｆ垜浠彲浠ヤ粠楂樼┖鎵撱€傛縺鍏夊埗瀵笺€傞伩寮€杩欎簺涓滆タ銆?", 9)
        return nil
    end, {}, getCurrentTime() + 36)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "AWACS", "褰撳墠鏈彂鐜伴珮绌洪槻绌哄▉鑳併€傜户缁帹杩涳紝鍓嶅線鑸矾鐐?锛屾悳绱㈣胺鍦板唴閮ㄣ€?", 12)
        return nil
    end, {}, getCurrentTime() + 46)
    self:notifyDebugForPlayer(playerState, "search1 complete by " .. tostring(playerState.playerName))
end

function BekaaStoryController:handleSearch2Success(playerState, target)
    self:markPhase("phase3_silence")
    playerState.search2SuccessSeen = true
    self:markPlayerStoryPhase(playerState, "phase3_silence")
    self:speakerLineToPlayer(playerState, "AWACS", "鏀跺埌鍥惧儚銆?", 6)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "AWACS", "杩欎笉鏄墠娌块儴闃熴€傝繖鏄泦缁撳尯銆備粬浠湪杩欓噷缁勭粐杩涙敾銆?", 10)
        return nil
    end, {}, getCurrentTime() + 7)
    timer.scheduleFunction(function()
        self:speakerLineToPlayer(playerState, "鍍氭満", "瑙勬ā姣旀兂璞＄殑澶с€?", 8)
        return nil
    end, {}, getCurrentTime() + 18)
    timer.scheduleFunction(function()
        self:beginAmbushSequence()
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 22)
    self:notifyDebugForPlayer(playerState, "search2 complete by " .. tostring(playerState.playerName))
end

function BekaaStoryController:checkPhaseTriggers()
    local playerUnits = self:findPlayerUnits()
    local shemonaZone = self:getZone(self.config.shemonaZoneName)
    local wp3Zone = self:getZone(self.config.wp3EntryZoneName)

    for i = 1, #playerUnits do
        local unit = playerUnits[i]
        local playerState = self:ensurePlayerTracked(unit)
        local point = getUnitPoint(unit)

        if playerState and isUnitInAir(unit) == true then
            self:beginTakeoffPhase(playerState)
        end

        if playerState and point and shemonaZone and pointInZone(point, shemonaZone) then
            self:beginRecon1Phase(playerState)
        end

        if playerState and point and wp3Zone and pointInZone(point, wp3Zone) then
            self:beginRecon2Phase(playerState)
        end
    end
end

function BekaaStoryController:sendTaskHintToGroup(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    local hint
    if self.phase == "phase1_recon" then
        hint = "前往谢莫纳建立观察位，使用吊舱侦察谷口装甲，进入15海里内后通过菜单提交南口照片。"
    elseif self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" then
        hint = "向北推进至WP3附近，使用吊舱侦察里亚格的静态-指挥中心-1，然后通过菜单提交里亚格照片。"
    elseif self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" then
        hint = "防空伏击已开始，立即脱离并防御机动。"
    else
        hint = "按AWACS指示推进。"
    end

    if playerState then
        self:notifyPlayer(playerState, hint, self.config.messageDurationSeconds)
        self:log(
            "task_hint | player=" .. tostring(playerState.playerName)
            .. " | unit=" .. tostring(playerState.unitName)
            .. " | phase=" .. tostring(self.phase)
        )
    else
        trigger.action.outTextForGroup(groupId, hint, self.config.messageDurationSeconds)
        self:log("task_hint | groupId=" .. tostring(groupId) .. " | phase=" .. tostring(self.phase))
    end
end

function BekaaStoryController:handleReconSubmission(groupId, reconIndex)
    local playerState, unit = self:getPlayerStateByGroupId(groupId)
    if playerState == nil or unit == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end

    if reconIndex == 1 and self.phase ~= "phase1_recon" then
        self:notifyPlayer(playerState, "当前尚未进入第一轮侦察阶段。", self.config.messageDurationSeconds)
        return
    end
    if reconIndex == 2 and self.phase ~= "phase2_recon" then
        self:notifyPlayer(playerState, "当前尚未进入第二轮侦察阶段。", self.config.messageDurationSeconds)
        return
    end

    local okSubmission, reason, target = self:validateReconSubmission(unit, reconIndex)
    local distanceNm = target and target.distanceMeters and round(metersToNm(target.distanceMeters), 1) or nil
    self:log(
        "recon_submit | phase=" .. tostring(self.phase)
        .. " | player=" .. tostring(playerState.playerName)
        .. " | unit=" .. tostring(playerState.unitName)
        .. " | recon=" .. tostring(reconIndex)
        .. " | ok=" .. tostring(okSubmission)
        .. " | reason=" .. tostring(reason)
        .. " | distanceNm=" .. tostring(distanceNm)
    )

    if okSubmission ~= true then
        if reconIndex == 1 then
            self:notifyPlayer(playerState, "AWACS：你们的照片不够清晰，请靠近点重拍。", self.config.messageDurationSeconds)
        else
            self:notifyPlayer(playerState, "AWACS：画面不够，再靠近。", self.config.messageDurationSeconds)
        end
        return
    end

    if reconIndex == 1 and self.search1Completed ~= true then
        self.search1Completed = true
        self:setFlag(9103, 1)
        self:handleSearch1Success(playerState, target)
        return
    end
    if reconIndex == 2 and self.search2Completed ~= true then
        self.search2Completed = true
        self:setFlag(9104, 1)
        self:handleSearch2Success(playerState, target)
        return
    end

    self:notifyPlayer(playerState, "AWACS：已收到，阶段已推进。", self.config.messageDurationSeconds)
end

function BekaaStoryController:tick()
    self:updatePlayerRoster()
    self:checkPhaseTriggers()
    return getCurrentTime() + self.config.scanIntervalSeconds
end

function BekaaStoryController:start()
    if self.eventHandler == nil then
        self.eventHandler = {}
        function self.eventHandler:onEvent(event)
            if BekaaStoryControllerInstance and BekaaStoryControllerInstance.onWorldEvent then
                BekaaStoryControllerInstance:onWorldEvent(event)
            end
        end
        world.addEventHandler(self.eventHandler)
    end
    self:log("start | version=" .. tostring(BekaaStoryController.VERSION))
    timer.scheduleFunction(function()
        return self:tick()
    end, {}, getCurrentTime() + 1)
end

function BekaaStoryController:onWorldEvent(event)
    if event == nil then
        return
    end
    if event.id == world.event.S_EVENT_BIRTH and event.initiator and Object.getCategory(event.initiator) == 1 then
        local playerName = getPlayerName(event.initiator)
        if playerName then
            self:log("birth | player=" .. tostring(playerName) .. " | unit=" .. tostring(Unit.getName(event.initiator)))
            self:updatePlayerRoster()
        end
    end
end

function BekaaStoryController:beginAmbushSequence()
    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" or self.missionCompleted == true then
        return
    end

    self:markPhase("phase4_ambush")
    self:notifyActivePlayers("……", 3)

    timer.scheduleFunction(function()
        self:setSkynetAmbushLock(false, "story_ambush_release")
        self:speakerLine("AWACS", "锁定！！锁定！！多源雷达上线！！SA-11！！", 10)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds)

    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "导弹发射！！", 8)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 8)

    timer.scheduleFunction(function()
        self:speakerLine("僚机", "刚才没有任何信号！！", 8)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 15)

    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "它们刚才是关机状态——它们一直在那里。一直在跟踪你们。", 10)
        self:markPhase("phase5_retreat")
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 24)

    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "全体撤离！！你们在包线内！！立即脱离！！防御机动！！", 12)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.retreatCallDelaySeconds)

    timer.scheduleFunction(function()
        self:finishMission()
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.missionEndDelaySeconds)
end

function BekaaStoryController:finishMission()
    if self.missionCompleted == true then
        return
    end
    self.missionCompleted = true
    self:markPhase("complete")
    self:setFlag(self.config.missionCompleteFlag, 1)
    self:speakerLine("AWACS", "继续撤出……确认。整片谷地，都是它们的。", 10)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "没有信号……不是因为没有系统。是因为它们选择不发射。", 12)
        return nil
    end, {}, getCurrentTime() + 10)
end

function BekaaStoryController:speakerLine(speaker, text, duration)
    local line = tostring(speaker) .. ":\n" .. tostring(text)
    self:notifyActivePlayers(line, duration)
    self:log("radio_broadcast | " .. tostring(speaker) .. " | " .. tostring(text))
end

BekaaStoryControllerInstance = BekaaStoryController:create(_G.BekaaStoryConfig or nil)
BekaaStoryControllerInstance:start()

end
