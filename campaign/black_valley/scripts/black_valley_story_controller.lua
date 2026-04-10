do

BlackValleyStoryController = BlackValleyStoryController or {}
BlackValleyStoryController.__index = BlackValleyStoryController

BlackValleyStoryController.MISSION_NAME = "Black Valley"
BlackValleyStoryController.VERSION = "black-valley-story-v2"
BlackValleyStoryController.LOG_PREFIX = "[BLACK VALLEY] "

local DEFAULT_CONFIG = {
    missionName = "Black Valley",
    playerCoalition = coalition.side.BLUE,
    targetCoalition = coalition.side.RED,
    shemonaZoneName = "ZONE_SHEMONA_CAL",
    wp3EntryZoneName = "ZONE_WP3_ENTRY",
    riyakTargetZoneName = "ZONE_RIYAK_COMMAND",
    frontlineGroupNamePatterns = {
        "第七装甲师-第二装甲旅-第一营",
    },
    riyakStaticName = "静态-指挥中心-1",
    riyakStaticNameAliases = {
        "静态 指挥中心-1",
        "静态-指挥中心-1",
        "指挥中心-1",
    },
    recon1MaxDistanceNm = 15,
    recon2MaxDistanceNm = 115,
    recon2StaticTargetObservationHeightMeters = 120,
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
    introStartDelaySeconds = 2,
    phase4SilenceDelaySeconds = 4,
    retreatCallDelaySeconds = 18,
    missionEndDelaySeconds = 90,
    messageDurationSeconds = 10,
    missionCompleteFlag = 9101,
    skynetLockFlag = 9102,
    radioMenuRootText = "Black Valley - 侦察报告",
    radioMenuSouthText = "提交南口照片",
    radioMenuRiyakText = "提交里亚格照片",
    radioMenuHintText = "请求当前任务提示",
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

local function normalizeLookupName(value)
    local text = tostring(value or "")
    text = string.gsub(text, "%s+", "")
    text = string.gsub(text, "[-_－—–]+", "")
    return text
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

local function getUnitName(unit)
    local okName, name = pcall(function()
        return unit:getName()
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

local function getPlayerName(unit)
    local okPlayer, name = pcall(function()
        return unit:getPlayerName()
    end)
    if okPlayer then
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

local function getUnitTypeName(unit)
    local okType, typeName = pcall(function()
        return unit:getTypeName()
    end)
    if okType then
        return typeName
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

local function isUnitInAir(unit)
    local okAir, inAir = pcall(function()
        return unit:inAir()
    end)
    return okAir and inAir == true
end

local function getAliveUnits(group)
    local units = {}
    if group == nil or group:isExist() == false then
        return units
    end
    local okUnits, groupUnits = pcall(function()
        return group:getUnits()
    end)
    if okUnits and groupUnits then
        for i = 1, #groupUnits do
            local unit = groupUnits[i]
            if isUnitAlive(unit) then
                units[#units + 1] = unit
            end
        end
    end
    return units
end

local function getTerrainHeight(point)
    local okHeight, height = pcall(function()
        return land.getHeight({ x = point.x, y = point.z })
    end)
    if okHeight and height then
        return height
    end
    return 0
end

local function formatLatLon(point)
    if point == nil or coord == nil or coord.LOtoLL == nil then
        return "未知坐标"
    end
    local okLL, lat, lon = pcall(function()
        local latValue, lonValue = coord.LOtoLL(point)
        return latValue, lonValue
    end)
    if not okLL then
        return "未知坐标"
    end
    return string.format("纬度 %.4f，经度 %.4f", lat, lon)
end

local function createStoryLogger(prefix)
    return function(message)
        env.info(prefix .. tostring(message))
    end
end

function BlackValleyStoryController:create(config)
    local instance = setmetatable({}, self)
    instance.config = mergeConfig(DEFAULT_CONFIG, config or {})
    instance.logWriter = createStoryLogger(self.LOG_PREFIX)
    instance.phase = "phase_minus_2"
    instance.playersByName = {}
    instance.menusByGroupId = {}
    instance.search1Completed = false
    instance.search2Completed = false
    instance.ambushReleased = false
    instance.missionCompleted = false
    instance.firstCasualty = nil
    instance.reconPromptState = {
        phase1Started = false,
        phase2Started = false,
    }
    return instance
end

function BlackValleyStoryController:log(message)
    self.logWriter(message)
end

function BlackValleyStoryController:getTrackedUnit(playerState)
    if playerState == nil or playerState.unitName == nil then
        return nil
    end
    local unit = Unit.getByName(playerState.unitName)
    if isUnitAlive(unit) then
        return unit
    end
    return nil
end

function BlackValleyStoryController:notifyPlayer(playerState, text, duration)
    if playerState == nil or text == nil or text == "" then
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
    if playerState.groupId then
        trigger.action.outTextForGroup(playerState.groupId, text, duration or self.config.messageDurationSeconds)
    else
        trigger.action.outText(text, duration or self.config.messageDurationSeconds)
    end
end

function BlackValleyStoryController:notifyAllPlayers(text, duration)
    for _, playerState in pairs(self.playersByName) do
        self:notifyPlayer(playerState, text, duration)
    end
end

function BlackValleyStoryController:getSpeakerLabel(playerState, speaker)
    if speaker == "玩家" and playerState and playerState.playerName then
        return playerState.playerName
    end
    if speaker == "僚机" and playerState and playerState.playerName then
        return playerState.playerName
    end
    if speaker == "中队长" then
        return "中队长"
    end
    return speaker
end

function BlackValleyStoryController:renderText(playerState, text)
    if playerState and playerState.playerName and text then
        return string.gsub(text, "玩家", playerState.playerName)
    end
    return text
end

function BlackValleyStoryController:renderSpeakerLine(playerState, speaker, text)
    local renderedText = self:renderText(playerState, text)
    if speaker == "系统静默" then
        return renderedText
    end
    return self:getSpeakerLabel(playerState, speaker) .. "：" .. renderedText
end

function BlackValleyStoryController:speakerLineToPlayer(playerState, speaker, text, duration)
    self:notifyPlayer(playerState, self:renderSpeakerLine(playerState, speaker, text), duration)
end

function BlackValleyStoryController:speakerLine(speaker, text, duration)
    for _, playerState in pairs(self.playersByName) do
        self:speakerLineToPlayer(playerState, speaker, text, duration)
    end
end

function BlackValleyStoryController:queuePlayerSequence(playerState, sequenceKey, entries, initialDelay)
    if playerState == nil then
        return
    end
    playerState.sequenceFlags = playerState.sequenceFlags or {}
    if playerState.sequenceFlags[sequenceKey] == true then
        return
    end
    playerState.sequenceFlags[sequenceKey] = true
    local when = getCurrentTime() + (initialDelay or 0)
    for i = 1, #entries do
        local entry = entries[i]
        when = when + (entry.delay or 0)
        local scheduledAt = when
        timer.scheduleFunction(function()
            self:speakerLineToPlayer(playerState, entry.speaker, entry.text, entry.duration or self.config.messageDurationSeconds)
            return nil
        end, {}, scheduledAt)
    end
end

function BlackValleyStoryController:markPhase(phaseName)
    if self.phase == phaseName then
        return
    end
    self.phase = phaseName
    self:log("phase | " .. tostring(phaseName))
end

function BlackValleyStoryController:setFlag(flagValue, value)
    trigger.action.setUserFlag(flagValue, value)
end

function BlackValleyStoryController:setSkynetAmbushLock(locked, reason)
    _G.BEKAA_STORY_SKYNET_AMBUSH_LOCK = locked
    self:setFlag(self.config.skynetLockFlag, locked and 1 or 0)
    if type(_G.SkynetStorySetAmbushLock) == "function" then
        pcall(_G.SkynetStorySetAmbushLock, locked, reason or "black_valley")
    end
    self:log("skynet_lock | locked=" .. tostring(locked) .. " | reason=" .. tostring(reason))
end

function BlackValleyStoryController:getZone(zoneName)
    return trigger.misc.getZone(zoneName)
end

function BlackValleyStoryController:ensureMenusForGroup(groupId)
    if groupId == nil or self.menusByGroupId[groupId] then
        return
    end
    local root = missionCommands.addSubMenuForGroup(groupId, self.config.radioMenuRootText)
    self.menusByGroupId[groupId] = {
        root = root,
        south = missionCommands.addCommandForGroup(groupId, self.config.radioMenuSouthText, root, function()
            self:handleReconSubmission(groupId, 1)
        end),
        riyak = missionCommands.addCommandForGroup(groupId, self.config.radioMenuRiyakText, root, function()
            self:handleReconSubmission(groupId, 2)
        end),
        hint = missionCommands.addCommandForGroup(groupId, self.config.radioMenuHintText, root, function()
            self:sendTaskHintToGroup(groupId)
        end),
    }
    self:log("radio_menu_create | groupId=" .. tostring(groupId))
end

function BlackValleyStoryController:ensurePlayerTracked(unit)
    if unit == nil then
        return nil
    end
    local playerName = getPlayerName(unit)
    if playerName == nil or playerName == "" then
        return nil
    end
    local playerState = self.playersByName[playerName]
    if playerState == nil then
        playerState = {
            playerName = playerName,
            sequenceFlags = {},
            storyFlags = {},
        }
        self.playersByName[playerName] = playerState
        self:log("player_track | player=" .. tostring(playerName))
    end

    local group = getUnitGroup(unit)
    playerState.unitName = getUnitName(unit)
    playerState.group = group
    playerState.groupId = group and group:getID() or nil
    playerState.lastSeen = getCurrentTime()

    if playerState.groupId then
        self:ensureMenusForGroup(playerState.groupId)
    end

    if playerState.storyFlags.introQueued ~= true then
        playerState.storyFlags.introQueued = true
        self:beginPlayerIntro(playerState)
    end

    if isUnitInAir(unit) == true and playerState.storyFlags.takeoffQueued ~= true then
        playerState.storyFlags.takeoffQueued = true
        self:beginPlayerTakeoff(playerState)
    end

    return playerState
end

function BlackValleyStoryController:findPlayerUnits()
    local units = coalition.getPlayers(self.config.playerCoalition) or {}
    local active = {}
    for i = 1, #units do
        local unit = units[i]
        if isUnitAlive(unit) and getPlayerName(unit) then
            active[#active + 1] = unit
        end
    end
    return active
end

function BlackValleyStoryController:updatePlayerRoster()
    local activeUnits = self:findPlayerUnits()
    for i = 1, #activeUnits do
        self:ensurePlayerTracked(activeUnits[i])
    end
end

function BlackValleyStoryController:getPlayerStateByGroupId(groupId)
    if groupId == nil then
        return nil, nil
    end
    for _, playerState in pairs(self.playersByName) do
        if playerState.groupId == groupId then
            local unit = self:getTrackedUnit(playerState)
            if unit then
                return playerState, unit
            end
        end
    end
    return nil, nil
end

function BlackValleyStoryController:getNearestFrontlineTarget(unitPoint)
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
                            unitName = getUnitName(units[j]),
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

function BlackValleyStoryController:findStaticObjectByFlexibleName(primaryName, aliases)
    local exactCandidates = {}
    if primaryName and primaryName ~= "" then
        exactCandidates[#exactCandidates + 1] = primaryName
    end
    for i = 1, #(aliases or {}) do
        local alias = aliases[i]
        if alias and alias ~= "" then
            exactCandidates[#exactCandidates + 1] = alias
        end
    end

    for i = 1, #exactCandidates do
        local staticObject = StaticObject.getByName(exactCandidates[i])
        if staticObject and StaticObject.isExist(staticObject) == true then
            if exactCandidates[i] ~= primaryName then
                self:log("riyak_static_match | mode=exact_alias | requested=" .. tostring(primaryName) .. " | matched=" .. tostring(exactCandidates[i]))
            end
            return staticObject, exactCandidates[i], "exact"
        end
    end

    local wanted = normalizeLookupName(primaryName)
    for i = 1, #(aliases or {}) do
        local normalizedAlias = normalizeLookupName(aliases[i])
        if normalizedAlias ~= "" then
            wanted = normalizedAlias
            break
        end
    end

    local coalitionsToScan = {
        coalition.side.RED,
        coalition.side.BLUE,
        coalition.side.NEUTRAL,
    }

    for i = 1, #coalitionsToScan do
        local staticObjects = coalition.getStaticObjects(coalitionsToScan[i]) or {}
        for j = 1, #staticObjects do
            local staticObject = staticObjects[j]
            if staticObject and StaticObject.isExist(staticObject) == true then
                local name = nil
                local okName, foundName = pcall(function()
                    return staticObject:getName()
                end)
                if okName then
                    name = foundName
                end
                if name and normalizeLookupName(name) == wanted then
                    self:log("riyak_static_match | mode=normalized_scan | requested=" .. tostring(primaryName) .. " | matched=" .. tostring(name))
                    return staticObject, name, "normalized_scan"
                end
            end
        end
    end

    self:log("riyak_static_match | mode=failed | requested=" .. tostring(primaryName))
    return nil, nil, "missing"
end

function BlackValleyStoryController:getRiyakStaticTarget()
    local staticObject, matchedName = self:findStaticObjectByFlexibleName(self.config.riyakStaticName, self.config.riyakStaticNameAliases)
    if staticObject == nil or StaticObject.isExist(staticObject) ~= true then
        local zone = self:getZone(self.config.riyakTargetZoneName)
        if zone and zone.point then
            local point = {
                x = zone.point.x,
                y = zone.point.y + (self.config.recon2StaticTargetObservationHeightMeters or 0),
                z = zone.point.z,
            }
            self:log("riyak_target_fallback | mode=zone | zone=" .. tostring(self.config.riyakTargetZoneName))
            return {
                name = self.config.riyakTargetZoneName,
                point = point,
            }
        end
        return nil
    end
    local point = getStaticPoint(staticObject)
    if point and self.config.recon2StaticTargetObservationHeightMeters > 0 then
        point = {
            x = point.x,
            y = point.y + self.config.recon2StaticTargetObservationHeightMeters,
            z = point.z,
        }
    end
    return {
        name = matchedName or self.config.riyakStaticName,
        point = point,
    }
end

function BlackValleyStoryController:hasReconPod(unit)
    if self.config.requireTargetingPod ~= true then
        return true, "pod_check_disabled"
    end
    local okAmmo, ammo = pcall(function()
        return unit:getAmmo()
    end)
    if okAmmo and ammo then
        for i = 1, #ammo do
            local ammoEntry = ammo[i]
            local candidates = {}
            if ammoEntry.desc then
                candidates[#candidates + 1] = ammoEntry.desc.typeName
                candidates[#candidates + 1] = ammoEntry.desc.displayName
            end
            if ammoEntry.name then
                candidates[#candidates + 1] = ammoEntry.name
            end
            for j = 1, #candidates do
                if candidates[j] and containsPattern(candidates[j], self.config.podKeywordPatterns) then
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

function BlackValleyStoryController:hasLineOfSight(unitPoint, targetPoint)
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

function BlackValleyStoryController:validateReconSubmission(unit, reconIndex)
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
        target.distanceMeters = distanceMeters
        if distanceMeters > nmToMeters(self.config.recon2MaxDistanceNm) then
            return false, "distance_too_far_riyak", target
        end
        return true, "valid_riyak_photo", target
    end

    return false, "invalid_recon_index"
end

function BlackValleyStoryController:getReconFailureMessage(reconIndex, reason)
    local reasonText = tostring(reason or "")
    if string.find(reasonText, "not_in_air", 1, true) then
        return "AWACS：你必须保持空中状态后才能提交侦察照片。"
    end
    if string.find(reasonText, "no_recon_pod_detected", 1, true) then
        return "AWACS：未检测到可用吊舱，无法确认图像。"
    end
    if string.find(reasonText, "line_of_sight_blocked", 1, true) then
        if reconIndex == 1 then
            return "AWACS：目标被地形遮挡，调整观察角度后重拍。"
        end
        return "AWACS：指挥中心被地形遮挡，调整航向或高度后重拍。"
    end
    if string.find(reasonText, "riyak_target_missing", 1, true) then
        return "AWACS：未能确认里亚格指挥中心目标。"
    end
    if string.find(reasonText, "distance_too_far", 1, true) then
        if reconIndex == 1 then
            return "AWACS：你们的照片不够清晰，请靠近点重拍。"
        end
        return "AWACS：画面不够，再靠近。"
    end
    return "AWACS：图像条件不足，请调整位置后重拍。"
end

function BlackValleyStoryController:sendTaskHintToGroup(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    local hint
    if self.phase == "phase1_recon" then
        hint = "前往谢莫纳建立观察位，使用吊舱侦察谷口装甲，进入15海里内后通过菜单提交南口照片。"
    elseif self.phase == "phase2_transit_wp3" or self.phase == "phase2_recon" then
        hint = "向北推进至WP3附近，使用吊舱侦察里亚格的静态-指挥中心-1，然后通过菜单提交里亚格照片。"
    elseif self.phase == "phase3_silence" or self.phase == "phase4_ambush" or self.phase == "phase5_retreat" then
        hint = "防空伏击已开始，立即脱离并防御机动。"
    else
        hint = "AWACS：战区已进入交战状态，按当前任务提示执行。"
    end

    if playerState then
        self:notifyPlayer(playerState, hint, self.config.messageDurationSeconds)
    else
        trigger.action.outTextForGroup(groupId, hint, self.config.messageDurationSeconds)
    end
    self:log("task_hint | groupId=" .. tostring(groupId) .. " | phase=" .. tostring(self.phase))
end

function BlackValleyStoryController:beginPlayerIntro(playerState)
    self:queuePlayerSequence(playerState, "cold_start", {
        { speaker = "玩家", text = "黎巴嫩那边发什么颠，听说已经发生暴乱了。", delay = 0, duration = 7 },
        { speaker = "地面频率", text = "玩家，这是紧急的空中侦察任务。请集中精力到任务上，迅速起飞。", delay = 7, duration = 8 },
        { speaker = "玩家", text = "我们这是去干嘛，人肉侦察？", delay = 8, duration = 7 },
        { speaker = "中队长", text = "不知道。摩萨德的人已经疯了，居然强压我们的人来做这种高风险的任务。一堆饭桶！居然要我们给他们搞情报？", delay = 8, duration = 12 },
        { speaker = "塔台", text = "玩家，起飞后，爬升到30000。联系AWACS。", delay = 9, duration = 8 },
        { speaker = "AWACS", text = "所有单位，这里是灯塔。当前空域清晰，没有检测到空中威胁，推进到WP1。", delay = 8, duration = 10 },
        { speaker = "僚机", text = "你听说了吗？黎巴嫩对我们宣战了，怎么敢的啊。", delay = 8, duration = 8 },
        { speaker = "中队长", text = "嗯。摩萨德那群虫豸居然一点风声没听到，好像整个黎巴嫩的情报网都下线了。", delay = 8, duration = 10 },
        { speaker = "玩家", text = "所以就要我们来干这些脏活？卫星看不见吗。", delay = 8, duration = 8 },
        { speaker = "中队长", text = "他们部署了新的干扰设备，从叙利亚方向运过去的，卫星都看不见里面的情况。", delay = 8, duration = 10 },
        { speaker = "玩家", text = "这群穆斯林原始人能有这种高科技？肯定是那群俄国佬给他们的。", delay = 8, duration = 9 },
        { speaker = "中队长", text = "多长个心眼。30分钟前，俄罗斯空天军已经宣布接管了叙利亚空域。我有预感，这次的敌人，不是黎巴嫩，更不是叙利亚。", delay = 8, duration = 12 },
        { speaker = "AWACS", text = "贝卡谷地当前无电磁活动。重复，无电磁活动。空域安全，你们可以推进。", delay = 8, duration = 10 },
    }, self.config.introStartDelaySeconds)
end

function BlackValleyStoryController:beginPlayerTakeoff(playerState)
    self:queuePlayerSequence(playerState, "takeoff", {
        { speaker = "AWACS", text = "空情清晰，无空中目标。仅检测到四处黎巴嫩固定雷达站。未发现新增节点。未检测到防空系统信号。", delay = 0, duration = 10 },
        { speaker = "僚机", text = "听起来挺干净。", delay = 9, duration = 6 },
        { speaker = "中队长", text = "太干净了。有点不太正常。", delay = 7, duration = 7 },
    }, 1)
end

function BlackValleyStoryController:beginRecon1Phase(triggeringPlayer)
    if self.reconPromptState.phase1Started == true then
        return
    end
    self.reconPromptState.phase1Started = true
    self:markPhase("phase1_recon")
    self:speakerLine("AWACS", "你们正在接近谢莫纳，在那里建立观察位置，对WP2附近进行侦察。", 9)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "如果那边真的有部队，这么大规模，不可能没有防空设施。", 8)
        return nil
    end, {}, getCurrentTime() + 8)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "同意。但我们确实没有看到。", 8)
        return nil
    end, {}, getCurrentTime() + 16)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "玩家，保持高度。使用吊舱侦察谷地出口。报告你们的接触。通过通讯菜单提交侦察结果。", 10)
        return nil
    end, {}, getCurrentTime() + 23)
    if triggeringPlayer then
        self:notifyPlayer(triggeringPlayer, "前往谢莫纳建立观察位，使用吊舱侦察谷口装甲，进入15海里内后通过菜单提交南口照片。", 10)
    end
end

function BlackValleyStoryController:handleSearch1Success(target)
    self:markPhase("phase2_transit_wp3")
    self:speakerLine("AWACS", "收到。确认装甲单位，数量很多，正在向谷口推进。", 9)
    timer.scheduleFunction(function()
        self:speakerLine("中队长", "推进速度太快了。按这个速度，明天早上就会到谢莫纳。", 8)
        return nil
    end, {}, getCurrentTime() + 8)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "我看到了一些单位，有两根炮管。像防空。", 8)
        return nil
    end, {}, getCurrentTime() + 16)
    timer.scheduleFunction(function()
        self:speakerLine("中队长", "意料之中，藏得不错。", 7)
        return nil
    end, {}, getCurrentTime() + 24)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "未检测到防空雷达信号。如果存在，应处于静默状态。", 9)
        return nil
    end, {}, getCurrentTime() + 31)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "那我们可以从高空打。激光制导。这些东西，射高不够。应该会是 easy task，就像打靶。", 11)
        return nil
    end, {}, getCurrentTime() + 40)
    timer.scheduleFunction(function()
        self:speakerLine("中队长", "嗯。", 5)
        return nil
    end, {}, getCurrentTime() + 50)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "当前未发现高空防空威胁。继续推进，前往航路点3，搜索谷地内部。", 10)
        return nil
    end, {}, getCurrentTime() + 55)
end

function BlackValleyStoryController:beginRecon2Phase(triggeringPlayer)
    if self.search1Completed ~= true or self.reconPromptState.phase2Started == true then
        return
    end
    self.reconPromptState.phase2Started = true
    self:markPhase("phase2_recon")
    self:speakerLine("AWACS", "前往航路点3，搜索谷地内部。重点观察里亚格。", 9)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "看起来他们还没准备好。", 7)
        return nil
    end, {}, getCurrentTime() + 8)
    timer.scheduleFunction(function()
        self:speakerLine("中队长", "或者我们还没看到。", 7)
        return nil
    end, {}, getCurrentTime() + 15)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "收到后通过数据链提交图像。", 8)
        return nil
    end, {}, getCurrentTime() + 22)
    if triggeringPlayer then
        self:notifyPlayer(triggeringPlayer, "向北推进至WP3附近，使用吊舱侦察里亚格的静态-指挥中心-1，然后通过菜单提交里亚格照片。", 10)
    end
end

function BlackValleyStoryController:handleSearch2Success(target)
    self:markPhase("phase3_silence")
    self:speakerLine("AWACS", "收到图像。", 6)
    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "这不是前沿部队。这是集结区。他们在这里组织进攻。", 10)
        return nil
    end, {}, getCurrentTime() + 7)
    timer.scheduleFunction(function()
        self:speakerLine("僚机", "规模比想象的大。", 7)
        return nil
    end, {}, getCurrentTime() + 16)
    timer.scheduleFunction(function()
        self:beginAmbushSequence()
        return nil
    end, {}, getCurrentTime() + 24)
end

function BlackValleyStoryController:beginAmbushSequence()
    if self.ambushReleased == true or self.missionCompleted == true then
        return
    end

    self.ambushReleased = true
    self:markPhase("phase4_ambush")
    self:speakerLine("系统静默", "……", 3)

    timer.scheduleFunction(function()
        self:setSkynetAmbushLock(false, "black_valley_ambush_release")
        self:speakerLine("AWACS", "我们探测到新的辐射源！SA11高空防御系统！立即规避！", 10)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds)

    timer.scheduleFunction(function()
        self:speakerLine("玩家", "什么玩意！不是没有信号吗？这些东西不该靠搜索雷达提供预警吗？", 10)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 8)

    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "导弹发射！！", 8)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 14)

    timer.scheduleFunction(function()
        self:speakerLine("中队长", "它们刚才是关机状态——它们一直在那里。一直在跟踪你们。", 10)
        self:markPhase("phase5_retreat")
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + 21)

    timer.scheduleFunction(function()
        self:speakerLine("AWACS", "全体撤离！！你们在包线内！！立即脱离！！防御机动！！", 12)
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.retreatCallDelaySeconds)

    timer.scheduleFunction(function()
        self:finishMission()
        return nil
    end, {}, getCurrentTime() + self.config.phase4SilenceDelaySeconds + self.config.missionEndDelaySeconds)
end

function BlackValleyStoryController:recordCasualty(event)
    if self.firstCasualty ~= nil then
        return
    end
    local initiator = event and event.initiator or nil
    if not initiator or getPlayerName(initiator) == nil then
        return
    end
    local point = getUnitPoint(initiator)
    self.firstCasualty = {
        playerName = getPlayerName(initiator),
        point = point,
        coordText = formatLatLon(point),
    }
    self:log("casualty | player=" .. tostring(self.firstCasualty.playerName) .. " | coord=" .. tostring(self.firstCasualty.coordText))
end

function BlackValleyStoryController:finishMission()
    if self.missionCompleted == true then
        return
    end
    self.missionCompleted = true
    self:markPhase("complete")
    self:setFlag(self.config.missionCompleteFlag, 1)
    self:speakerLine("AWACS", "继续撤出……确认。整片谷地，都是它们的。", 10)

    if self.firstCasualty then
        local casualty = self.firstCasualty
        timer.scheduleFunction(function()
            self:speakerLine("AWACS", "我们损失惨重！玩家，有没有看到" .. casualty.playerName .. "跳伞。", 10)
            return nil
        end, {}, getCurrentTime() + 10)
        timer.scheduleFunction(function()
            self:speakerLine("玩家", "确认" .. casualty.playerName .. "位置！" .. casualty.coordText .. "。你们必须马上去把他救回来！", 12)
            return nil
        end, {}, getCurrentTime() + 20)
        timer.scheduleFunction(function()
            self:speakerLine("AWACS", "坐标已记录……我们会尽力。不过你要做好心理准备……那边已经是敌占区了。", 12)
            return nil
        end, {}, getCurrentTime() + 31)
        timer.scheduleFunction(function()
            self:speakerLine("玩家", "直升机呢！我们的搜救队呢！！" .. casualty.playerName .. "一定还没死！你们不能让他落到那群阿拉伯畜生手里！", 12)
            return nil
        end, {}, getCurrentTime() + 43)
        timer.scheduleFunction(function()
            self:speakerLine("AWACS", "刚刚开机的不仅仅是山毛榉……我们还监测到了大量低空防御系统的雷达，从道尔到通古斯卡。短暂的开机探测你们后又消失了。请务必确保你自己的安全！我们不能接受损失更多的飞机了……", 14)
            return nil
        end, {}, getCurrentTime() + 57)
    else
        timer.scheduleFunction(function()
            self:speakerLine("AWACS", "没有信号……不是因为没有系统。是因为它们选择不发射。", 12)
            return nil
        end, {}, getCurrentTime() + 12)
    end
end

function BlackValleyStoryController:handleReconSubmission(groupId, reconIndex)
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
        .. " | recon=" .. tostring(reconIndex)
        .. " | ok=" .. tostring(okSubmission)
        .. " | reason=" .. tostring(reason)
        .. " | distanceNm=" .. tostring(distanceNm)
    )

    if okSubmission ~= true then
        self:notifyPlayer(playerState, self:getReconFailureMessage(reconIndex, reason), self.config.messageDurationSeconds)
        return
    end

    if reconIndex == 1 and self.search1Completed ~= true then
        self.search1Completed = true
        self:setFlag(9103, 1)
        self:handleSearch1Success(target)
        return
    end

    if reconIndex == 2 and self.search2Completed ~= true then
        self.search2Completed = true
        self:setFlag(9104, 1)
        self:handleSearch2Success(target)
        return
    end

    self:notifyPlayer(playerState, "AWACS：已收到，阶段已推进。", self.config.messageDurationSeconds)
end

function BlackValleyStoryController:checkPhaseTriggers()
    local playerUnits = self:findPlayerUnits()
    local shemonaZone = self:getZone(self.config.shemonaZoneName)
    local wp3Zone = self:getZone(self.config.wp3EntryZoneName)

    for i = 1, #playerUnits do
        local unit = playerUnits[i]
        local playerState = self:ensurePlayerTracked(unit)
        local point = getUnitPoint(unit)

        if playerState and point and shemonaZone and pointInZone(point, shemonaZone) and self.phase ~= "phase4_ambush" and self.phase ~= "phase5_retreat" and self.phase ~= "complete" then
            if playerState.storyFlags.shemonaPrompt ~= true then
                playerState.storyFlags.shemonaPrompt = true
                self:beginRecon1Phase(playerState)
            end
        end

        if self.search1Completed == true and playerState and point and wp3Zone and pointInZone(point, wp3Zone) and self.phase ~= "phase4_ambush" and self.phase ~= "phase5_retreat" and self.phase ~= "complete" then
            if playerState.storyFlags.wp3Prompt ~= true then
                playerState.storyFlags.wp3Prompt = true
                self:beginRecon2Phase(playerState)
            end
        end
    end
end

function BlackValleyStoryController:tick()
    self:updatePlayerRoster()
    self:checkPhaseTriggers()
    return getCurrentTime() + self.config.scanIntervalSeconds
end

function BlackValleyStoryController:onWorldEvent(event)
    if event == nil then
        return
    end

    if event.id == world.event.S_EVENT_BIRTH and event.initiator and getPlayerName(event.initiator) then
        self:log("birth | player=" .. tostring(getPlayerName(event.initiator)) .. " | unit=" .. tostring(getUnitName(event.initiator)))
        self:updatePlayerRoster()
        return
    end

    if self.phase == "phase4_ambush" or self.phase == "phase5_retreat" then
        if event.id == world.event.S_EVENT_SHOT and event.initiator then
            local targetName = nil
            if event.target and getPlayerName(event.target) then
                targetName = getPlayerName(event.target)
            end
            if targetName then
                self:speakerLine("AWACS", "导弹发射！！目标是 " .. targetName .. "！", 8)
            end
        end

        if event.id == world.event.S_EVENT_EJECTION or event.id == world.event.S_EVENT_CRASH or event.id == world.event.S_EVENT_DEAD then
            self:recordCasualty(event)
        end
    end
end

function BlackValleyStoryController:start()
    self:setSkynetAmbushLock(true, "black_valley_start")
    self:log("start | version=" .. tostring(self.VERSION))

    if self.eventHandler == nil then
        self.eventHandler = {}
        function self.eventHandler:onEvent(event)
            if BlackValleyStoryControllerInstance and BlackValleyStoryControllerInstance.onWorldEvent then
                BlackValleyStoryControllerInstance:onWorldEvent(event)
            end
        end
        world.addEventHandler(self.eventHandler)
    end

    timer.scheduleFunction(function()
        return self:tick()
    end, {}, getCurrentTime() + 1)
end

BlackValleyStoryControllerInstance = BlackValleyStoryController:create(_G.BLACK_VALLEY_STORY_CONFIG)
BlackValleyStoryControllerInstance:start()

end
