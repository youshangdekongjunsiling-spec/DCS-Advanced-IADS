do

ProbeStoryController = ProbeStoryController or {}
ProbeStoryController.__index = ProbeStoryController

ProbeStoryController.MISSION_NAME = "Probe"
ProbeStoryController.VERSION = "probe-story-v1"
ProbeStoryController.LOG_PREFIX = "[PROBE] "

local DEFAULT_CONFIG = {
    missionName = "Probe",
    playerCoalition = coalition.side.BLUE,
    targetCoalition = coalition.side.RED,
    scanIntervalSeconds = 2,
    readyStabilizeSeconds = 10,
    messageDurationSeconds = 10,
    missionCompleteFlag = 9201,
    radioMenuRootText = "任务02：探针",
    radioMenuReadyText = "准备完毕，可以出发",
    radioMenuHintText = "请求当前任务提示",
    radioMenuCoordsReadyText = "准备好接受坐标",
    radioMenuCoordsAckText = "坐标输入完成",
    radioMenuCoordsRepeatText = "灯塔，请重复",
    highAltZoneName = "ZONE_PROBE_HIGH_ALT",
    lowAltZoneName = "ZONE_PROBE_LOW_ALT",
    coordinateFallbackZoneName = "ZONE_PROBE_LOW_ALT",
    coordinateSourceGroupNames = { "EW-1" },
    highAltMinAltitudeMeters = 6500,
    lowAltMaxAltitudeMeters = 1200,
    requiredNodeKills = 2,
    nodeKillGroupNames = {
        "MSAM-7-第七装甲防空团-第一近程防空营-1",
    },
    nodeKillGroupPatterns = {
        "第一近程防空营",
        "近程防空营",
        "外围节点",
    },
    harmWeaponPatterns = {
        "AGM-88",
        "HARM",
        "LD-10",
        "Kh-31P",
        "KH-31P",
        "Kh-58",
        "ARM",
    },
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

local function containsPattern(source, patterns)
    if source == nil then
        return false
    end
    local text = tostring(source)
    for i = 1, #(patterns or {}) do
        if string.find(text, patterns[i], 1, true) then
            return true
        end
    end
    return false
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

local function createStoryLogger(prefix)
    return function(message)
        env.info(prefix .. tostring(message))
    end
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

local function getUnitGroup(unit)
    local okGroup, group = pcall(function()
        return unit:getGroup()
    end)
    if okGroup then
        return group
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

local function getGroupCoalition(group)
    local okCoalition, coalitionId = pcall(function()
        return group:getCoalition()
    end)
    if okCoalition then
        return coalitionId
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
            if isUnitAlive(groupUnits[i]) then
                units[#units + 1] = groupUnits[i]
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

local function getAltitudeAglMeters(point)
    if point == nil then
        return 0
    end
    return point.y - getTerrainHeight(point)
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

local function getWeaponTypeText(weapon)
    if weapon == nil then
        return nil
    end
    local candidates = {}
    local okType, typeName = pcall(function()
        return weapon:getTypeName()
    end)
    if okType and typeName then
        candidates[#candidates + 1] = typeName
    end
    local okDesc, desc = pcall(function()
        return weapon:getDesc()
    end)
    if okDesc and desc then
        candidates[#candidates + 1] = desc.typeName
        candidates[#candidates + 1] = desc.displayName
    end
    for i = 1, #candidates do
        if candidates[i] and candidates[i] ~= "" then
            return tostring(candidates[i])
        end
    end
    return nil
end

function ProbeStoryController:create(config)
    local instance = setmetatable({}, self)
    instance.config = mergeConfig(DEFAULT_CONFIG, config or {})
    instance.logWriter = createStoryLogger(self.LOG_PREFIX)
    instance.phase = "phase_ready_gate"
    instance.playersByName = {}
    instance.menusByGroupId = {}
    instance.lastRosterChangeTime = getCurrentTime()
    instance.nextReadyIndex = 1
    instance.readyPlayerNames = {}
    instance.playerDialogueCounts = {}
    instance.sequenceFlags = {}
    instance.missionStarted = false
    instance.highAltUnlocked = false
    instance.highAltHintSent = false
    instance.firstHarmShotHandled = false
    instance.secondHarmShotHandled = false
    instance.highAltConclusionStarted = false
    instance.lowAltUnlocked = false
    instance.coordsRequested = false
    instance.coordsText = nil
    instance.coordsRequesterName = nil
    instance.lowAltContactStarted = false
    instance.lowAltTacticStarted = false
    instance.firstKillHandled = false
    instance.nodeKillCount = 0
    instance.destroyedNodeGroups = {}
    instance.designatedHarmPlayerName = nil
    instance.supportSpeakerName = nil
    instance.missionCompleted = false
    return instance
end

function ProbeStoryController:log(message)
    self.logWriter(message)
end

function ProbeStoryController:markPhase(phaseName)
    if self.phase == phaseName then
        return
    end
    self.phase = phaseName
    self:log("phase | " .. tostring(phaseName))
end

function ProbeStoryController:setFlag(flagValue, value)
    trigger.action.setUserFlag(flagValue, value)
end

function ProbeStoryController:getTrackedUnit(playerState)
    if playerState == nil or playerState.unitName == nil then
        return nil
    end
    local unit = Unit.getByName(playerState.unitName)
    if isUnitAlive(unit) then
        return unit
    end
    return nil
end

function ProbeStoryController:notifyPlayer(playerState, text, duration)
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

function ProbeStoryController:getAudiencePlayers()
    local audience = {}
    for _, playerState in pairs(self.playersByName) do
        if self:getTrackedUnit(playerState) then
            audience[#audience + 1] = playerState
        end
    end
    table.sort(audience, function(a, b)
        return (a.readyIndex or 999) < (b.readyIndex or 999)
    end)
    return audience
end

function ProbeStoryController:notifyAllPlayers(text, duration)
    local audience = self:getAudiencePlayers()
    if #audience == 0 then
        trigger.action.outText(text, duration or self.config.messageDurationSeconds)
        return
    end
    for i = 1, #audience do
        self:notifyPlayer(audience[i], text, duration)
    end
end

function ProbeStoryController:getZone(zoneName)
    return trigger.misc.getZone(zoneName)
end

function ProbeStoryController:getPlayerStateByGroupId(groupId)
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

function ProbeStoryController:assignReadyIndex(playerState)
    if playerState.readyIndex ~= nil then
        return playerState.readyIndex
    end
    playerState.readyIndex = self.nextReadyIndex
    self.nextReadyIndex = self.nextReadyIndex + 1
    self.readyPlayerNames[#self.readyPlayerNames + 1] = playerState.playerName
    self:log("ready_index | player=" .. tostring(playerState.playerName) .. " | index=" .. tostring(playerState.readyIndex))
    return playerState.readyIndex
end

function ProbeStoryController:getOrderedReadyStates()
    local readyStates = {}
    for _, playerState in pairs(self.playersByName) do
        if playerState.ready == true and playerState.readyIndex ~= nil then
            readyStates[#readyStates + 1] = playerState
        end
    end
    table.sort(readyStates, function(a, b)
        return (a.readyIndex or 999) < (b.readyIndex or 999)
    end)
    return readyStates
end

function ProbeStoryController:getLeaderState()
    local readyStates = self:getOrderedReadyStates()
    return readyStates[1]
end

function ProbeStoryController:getPlayerLabel(playerState)
    if playerState and playerState.readyIndex then
        return tostring(playerState.readyIndex) .. "号机"
    end
    return "玩家"
end

function ProbeStoryController:getFixedSupportSpeaker()
    if self.supportSpeakerName then
        local speaker = self.playersByName[self.supportSpeakerName]
        if speaker and self:getTrackedUnit(speaker) then
            return speaker
        end
    end
    local readyStates = self:getOrderedReadyStates()
    if #readyStates >= 2 then
        return readyStates[2]
    end
    return readyStates[1]
end

function ProbeStoryController:selectDynamicPlayerSpeaker()
    local readyStates = self:getOrderedReadyStates()
    if #readyStates == 0 then
        return nil
    end
    if #readyStates == 1 then
        return readyStates[1]
    end
    if #readyStates <= 3 then
        return self:getFixedSupportSpeaker()
    end

    local candidates = {}
    local lowestCount = nil
    for i = 2, #readyStates do
        local candidate = readyStates[i]
        if self:getTrackedUnit(candidate) then
            local spokenCount = self.playerDialogueCounts[candidate.playerName] or 0
            if lowestCount == nil or spokenCount < lowestCount then
                lowestCount = spokenCount
                candidates = { candidate }
            elseif spokenCount == lowestCount then
                candidates[#candidates + 1] = candidate
            end
        end
    end

    if #candidates == 0 then
        return self:getFixedSupportSpeaker()
    end

    return candidates[math.random(1, #candidates)]
end

function ProbeStoryController:markPlayerSpeakerUsed(playerState)
    if playerState == nil or playerState.playerName == nil then
        return
    end
    self.playerDialogueCounts[playerState.playerName] = (self.playerDialogueCounts[playerState.playerName] or 0) + 1
end

function ProbeStoryController:getDesignatedHarmPlayer()
    if self.designatedHarmPlayerName then
        local playerState = self.playersByName[self.designatedHarmPlayerName]
        if playerState and self:getTrackedUnit(playerState) then
            return playerState
        end
    end
    return self:getFixedSupportSpeaker()
end

function ProbeStoryController:chooseDialogueSpeaker(role, explicitPlayerState)
    if role == "leader" then
        return self:getLeaderState()
    end
    if role == "player" then
        return self:selectDynamicPlayerSpeaker()
    end
    if role == "designated_harm" then
        return self:getDesignatedHarmPlayer()
    end
    if role == "explicit" then
        return explicitPlayerState
    end
    return nil
end

function ProbeStoryController:broadcastLine(label, text, duration)
    if label == nil or text == nil then
        return
    end
    self:notifyAllPlayers(label .. "：" .. text, duration or self.config.messageDurationSeconds)
end

function ProbeStoryController:broadcastRoleLine(role, text, duration, explicitPlayerState)
    if role == "AWACS" or role == "塔台" or role == "地面频率" then
        self:broadcastLine(role, text, duration)
        return
    end

    local speakerState = self:chooseDialogueSpeaker(role, explicitPlayerState)
    if speakerState == nil then
        self:broadcastLine("玩家", text, duration)
        return
    end

    local label = self:getPlayerLabel(speakerState)
    self:markPlayerSpeakerUsed(speakerState)
    self:broadcastLine(label, text, duration)
end

function ProbeStoryController:queueSharedSequence(sequenceKey, entries, initialDelay)
    if self.sequenceFlags[sequenceKey] == true then
        return
    end
    self.sequenceFlags[sequenceKey] = true
    local when = getCurrentTime() + (initialDelay or 0)
    for i = 1, #entries do
        local entry = entries[i]
        when = when + (entry.delay or 0)
        local scheduledAt = when
        timer.scheduleFunction(function()
            if entry.action then
                entry.action()
                return nil
            end
            self:broadcastRoleLine(entry.speaker, entry.text, entry.duration or self.config.messageDurationSeconds, entry.playerState)
            return nil
        end, {}, scheduledAt)
    end
end

function ProbeStoryController:ensureMenusForGroup(groupId)
    if groupId == nil or self.menusByGroupId[groupId] then
        return
    end
    local root = missionCommands.addSubMenuForGroup(groupId, self.config.radioMenuRootText)
    self.menusByGroupId[groupId] = {
        root = root,
        ready = missionCommands.addCommandForGroup(groupId, self.config.radioMenuReadyText, root, function()
            self:handleReadyCommand(groupId)
        end),
        hint = missionCommands.addCommandForGroup(groupId, self.config.radioMenuHintText, root, function()
            self:sendTaskHintToGroup(groupId)
        end),
        coordsReady = missionCommands.addCommandForGroup(groupId, self.config.radioMenuCoordsReadyText, root, function()
            self:handleCoordsReadyCommand(groupId)
        end),
        coordsAck = missionCommands.addCommandForGroup(groupId, self.config.radioMenuCoordsAckText, root, function()
            self:handleCoordsAckCommand(groupId)
        end),
        coordsRepeat = missionCommands.addCommandForGroup(groupId, self.config.radioMenuCoordsRepeatText, root, function()
            self:handleCoordsRepeatCommand(groupId)
        end),
    }
    self:log("radio_menu_create | groupId=" .. tostring(groupId))
end

function ProbeStoryController:ensurePlayerTracked(unit)
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
            ready = false,
            readyIndex = nil,
            coordAck = false,
        }
        self.playersByName[playerName] = playerState
        self.lastRosterChangeTime = getCurrentTime()
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

    return playerState
end

function ProbeStoryController:findPlayerUnits()
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

function ProbeStoryController:updatePlayerRoster()
    local activeUnits = self:findPlayerUnits()
    for i = 1, #activeUnits do
        self:ensurePlayerTracked(activeUnits[i])
    end
end

function ProbeStoryController:allActivePlayersReady()
    local activeUnits = self:findPlayerUnits()
    if #activeUnits == 0 then
        return false
    end
    for i = 1, #activeUnits do
        local playerState = self:ensurePlayerTracked(activeUnits[i])
        if playerState == nil or playerState.ready ~= true then
            return false
        end
    end
    return true
end

function ProbeStoryController:hasHarmWeapon(unit)
    local okAmmo, ammo = pcall(function()
        return unit:getAmmo()
    end)
    if not okAmmo or ammo == nil then
        return false
    end
    for i = 1, #ammo do
        local entry = ammo[i]
        local candidates = {}
        if entry.desc then
            candidates[#candidates + 1] = entry.desc.typeName
            candidates[#candidates + 1] = entry.desc.displayName
        end
        if entry.name then
            candidates[#candidates + 1] = entry.name
        end
        for j = 1, #candidates do
            if candidates[j] and containsPattern(candidates[j], self.config.harmWeaponPatterns) then
                return true
            end
        end
    end
    return false
end

function ProbeStoryController:finalizeSpeakerAssignments()
    local readyStates = self:getOrderedReadyStates()
    if #readyStates >= 2 then
        self.supportSpeakerName = readyStates[2].playerName
    end
    for i = 1, #readyStates do
        local playerState = readyStates[i]
        local unit = self:getTrackedUnit(playerState)
        if unit and self:hasHarmWeapon(unit) then
            self.designatedHarmPlayerName = playerState.playerName
            break
        end
    end
    if self.designatedHarmPlayerName == nil then
        self.designatedHarmPlayerName = self.supportSpeakerName or (readyStates[1] and readyStates[1].playerName) or nil
    end
    self:log("speaker_assign | support=" .. tostring(self.supportSpeakerName) .. " | designatedHarm=" .. tostring(self.designatedHarmPlayerName))
end

function ProbeStoryController:beginMissionBrief()
    if self.missionStarted == true then
        return
    end
    self.missionStarted = true
    self:setFlag(self.config.readyCompleteFlag, 1)
    self:markPhase("phase_brief")
    self:finalizeSpeakerAssignments()
    self:queueSharedSequence("mission_brief", {
        { speaker = "player", text = "昨晚失去的兄弟还没消息。", delay = 0, duration = 8 },
        { speaker = "leader", text = "别在频道里说这个，专注于你的任务。", delay = 7, duration = 8 },
        { speaker = "player", text = "……我们今天还是飞那边？", delay = 8, duration = 8 },
        { speaker = "leader", text = "飞。", delay = 7, duration = 6 },
        { speaker = "player", text = "能干死那群阿拉伯混账吗？", delay = 6, duration = 8 },
        { speaker = "leader", text = "先试探一下，逼他们露头，再用 HARM 送他们上天。", delay = 8, duration = 10 },
        { speaker = "地面频率", text = "Alpha 中队，可以起飞。编队起飞后爬升到3000，转向000，切换到 AWACS 频率。", delay = 8, duration = 10 },
        { speaker = "AWACS", text = "灯塔已经激活且上线。正在监视敌方动向。目前没有空中威胁和防空系统信号。", delay = 9, duration = 10 },
        { speaker = "AWACS", text = "任务目标：SEAD and DEAD。试探性打击敌方防空网，如果可以，摧毁防空网的远程防御。", delay = 9, duration = 11 },
        { speaker = "AWACS", text = "今天先把那些 SA11 逼出来。", delay = 9, duration = 8 },
        { action = function() self:unlockHighAltitudeLine() end, delay = 8 },
    }, 1)
end

function ProbeStoryController:unlockHighAltitudeLine()
    if self.highAltUnlocked == true then
        return
    end
    self.highAltUnlocked = true
    self:markPhase("phase_high_alt_open")
    local designated = self:getDesignatedHarmPlayer()
    local designatedLabel = designated and self:getPlayerLabel(designated) or "玩家"
    self:queueSharedSequence("high_alt_unlock", {
        { speaker = "AWACS", text = designatedLabel .. "，从高空向北接近里亚格，保持警惕。", delay = 0, duration = 9 },
        { speaker = "AWACS", text = "我们根据昨天的导弹升空坐标已经划定了大致威胁区，不要飞太低，不要深入过远。", delay = 8, duration = 10 },
        { speaker = "AWACS", text = "先把外围高空节点逼出来。", delay = 8, duration = 8 },
        { speaker = "designated_harm", text = "灯塔，收到。交给我。等它亮机，直接请它吃 HARM。", delay = 8, duration = 10 },
        { speaker = "leader", text = "希望能有那么简单。", delay = 8, duration = 8 },
    }, 0)
end

function ProbeStoryController:isPlayerInHighAltitudeEnvelope(unit)
    local point = getUnitPoint(unit)
    if point == nil then
        return false
    end
    local zone = self:getZone(self.config.highAltZoneName)
    if zone and pointInZone(point, zone) ~= true then
        return false
    end
    return getAltitudeAglMeters(point) >= self.config.highAltMinAltitudeMeters
end

function ProbeStoryController:isPlayerInLowAltitudeEnvelope(unit)
    local point = getUnitPoint(unit)
    if point == nil then
        return false
    end
    local zone = self:getZone(self.config.lowAltZoneName)
    if zone and pointInZone(point, zone) ~= true then
        return false
    end
    return getAltitudeAglMeters(point) <= self.config.lowAltMaxAltitudeMeters
end

function ProbeStoryController:handleFirstHarmShot(playerState, weaponType)
    if self.firstHarmShotHandled == true then
        return
    end
    self.firstHarmShotHandled = true
    self:markPhase("phase_high_alt_contact")
    self:log("harm_first | player=" .. tostring(playerState.playerName) .. " | weapon=" .. tostring(weaponType))
    self:queueSharedSequence("first_harm_reaction", {
        { speaker = "explicit", playerState = playerState, text = "HARM 出手。", delay = 0, duration = 6 },
        { speaker = "explicit", playerState = playerState, text = "确认雷达信号消失！让这群阿拉伯虫豸喝一壶！正在脱离！", delay = 4, duration = 10 },
        { speaker = "player", text = "干得漂亮！已经准备好推进！", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "等等。", delay = 6, duration = 6 },
        { speaker = "AWACS", text = "情况不对。", delay = 4, duration = 6 },
        { speaker = "leader", text = "哪里不对？", delay = 5, duration = 6 },
        { speaker = "AWACS", text = "信号消失得太早了。HARM 还在飞的时候它就关机了。", delay = 6, duration = 10 },
        { speaker = "leader", text = "该死，我就知道没那么简单。", delay = 7, duration = 8 },
        { speaker = "AWACS", text = "Alpha 中队，保持高度警惕，敌方防空威胁没有解除。控制好你们的接近距离！", delay = 7, duration = 11 },
    }, 0)
    timer.scheduleFunction(function()
        if self.highAltConclusionStarted ~= true then
            self:beginHighAltitudeConclusion()
        end
        return nil
    end, {}, getCurrentTime() + 28)
end

function ProbeStoryController:handleSecondHarmShot(playerState, weaponType)
    if self.secondHarmShotHandled == true then
        return
    end
    self.secondHarmShotHandled = true
    self:log("harm_second | player=" .. tostring(playerState.playerName) .. " | weapon=" .. tostring(weaponType))
    self:queueSharedSequence("second_harm_reaction", {
        { speaker = "explicit", playerState = playerState, text = "收到，备用反辐射小队正在接敌。让我们来试探一下。", delay = 0, duration = 9 },
        { speaker = "explicit", playerState = playerState, text = "该死，监测到火控雷达信号源！", delay = 7, duration = 8 },
        { speaker = "explicit", playerState = playerState, text = "HARM 一发离架，正在脱离。", delay = 6, duration = 8 },
        { speaker = "AWACS", text = "又关机了，大概率什么都不会打到。", delay = 7, duration = 8 },
        { speaker = "leader", text = "这怎么打！", delay = 6, duration = 7 },
    }, 0)
    timer.scheduleFunction(function()
        if self.highAltConclusionStarted ~= true then
            self:beginHighAltitudeConclusion()
        end
        return nil
    end, {}, getCurrentTime() + 12)
end

function ProbeStoryController:beginHighAltitudeConclusion()
    if self.highAltConclusionStarted == true then
        return
    end
    self.highAltConclusionStarted = true
    self:markPhase("phase_high_alt_conclusion")
    self:setFlag(self.config.highAltConclusionFlag, 1)
    self:queueSharedSequence("high_alt_conclusion", {
        { speaker = "AWACS", text = "辐射源重新出现，位置在第一轮接触的信号源附近。", delay = 0, duration = 9 },
        { speaker = "player", text = "什么？第一轮的打击失败了？它怎么又开机了？", delay = 7, duration = 9 },
        { speaker = "leader", text = "所以远距离的 HARM 射击，只能压制它，很难真正摧毁。", delay = 8, duration = 10 },
        { speaker = "AWACS", text = "初步判断成立。远距离反辐射攻击可压制外围高空节点，但不能稳定清除。", delay = 9, duration = 11 },
        { action = function() self:unlockLowAltitudeLine() end, delay = 8 },
    }, 0)
end

function ProbeStoryController:unlockLowAltitudeLine()
    if self.lowAltUnlocked == true then
        return
    end
    self.lowAltUnlocked = true
    self:markPhase("phase_low_alt_open")
    self:setFlag(self.config.lowAltUnlockedFlag, 1)
    self:queueSharedSequence("low_alt_unlock", {
        { speaker = "player", text = "高空发射 HARM 没用，我们可以压低，从下面钻进去，近距离摧毁它们。", delay = 0, duration = 10 },
        { speaker = "AWACS", text = "否定。", delay = 6, duration = 5 },
        { speaker = "AWACS", text = "直接低空进谷地，敌方低空防御部署完全不知道，等于送死。", delay = 5, duration = 10 },
        { speaker = "player", text = "那就真拿它们没办法？", delay = 8, duration = 8 },
        { speaker = "AWACS", text = "你们已经做得很好了，这次我们拿到了不少有用的信息。对方的防空部队非常专业。", delay = 7, duration = 11 },
        { speaker = "AWACS", text = "批准在刚才探到的 SA-11 射程边缘下高，做一次有限测试，试探一下它们的低空防御能力。", delay = 9, duration = 12 },
        { speaker = "leader", text = "也就是说，不进谷地。只对外围进行一次有限试探打击。", delay = 8, duration = 11 },
        { speaker = "AWACS", text = "对。", delay = 8, duration = 5 },
        { speaker = "AWACS", text = "坐标传输预备。贝卡谷地外围雷达站位置，应该已经被敌方接管，疑似有伴随防空系统。你们准备好接受坐标时报告。", delay = 7, duration = 13 },
    }, 0)
end

function ProbeStoryController:getCoordinateSourcePoint()
    for i = 1, #self.config.coordinateSourceGroupNames do
        local group = Group.getByName(self.config.coordinateSourceGroupNames[i])
        local units = getAliveUnits(group)
        if #units > 0 then
            return getUnitPoint(units[1]), self.config.coordinateSourceGroupNames[i]
        end
    end
    local fallbackZone = self:getZone(self.config.coordinateFallbackZoneName)
    if fallbackZone and fallbackZone.point then
        return {
            x = fallbackZone.point.x,
            y = fallbackZone.point.y,
            z = fallbackZone.point.z,
        }, self.config.coordinateFallbackZoneName
    end
    return nil, nil
end

function ProbeStoryController:broadcastCoordinates(requesterState)
    local point, sourceName = self:getCoordinateSourcePoint()
    self.coordsRequested = true
    self.coordsRequesterName = requesterState and requesterState.playerName or nil
    self.coordsText = point and formatLatLon(point) or "未知坐标"
    self:log("coords_broadcast | requester=" .. tostring(self.coordsRequesterName) .. " | source=" .. tostring(sourceName) .. " | coords=" .. tostring(self.coordsText))
    local requesterLabel = requesterState and self:getPlayerLabel(requesterState) or "玩家"
    self:queueSharedSequence("coords_broadcast", {
        { speaker = "explicit", playerState = requesterState, text = "准备好进行坐标接收。", delay = 0, duration = 7 },
        { speaker = "AWACS", text = "坐标传输开始。参考源：" .. tostring(sourceName or "未知源") .. "。", delay = 4, duration = 8 },
        { speaker = "AWACS", text = "贝卡谷地外围雷达站参考点：" .. tostring(self.coordsText) .. "。窗口三十秒。", delay = 7, duration = 12 },
        { speaker = "AWACS", text = requesterLabel .. "，输入完成后报告。需要重复时通过菜单呼叫。", delay = 8, duration = 10 },
    }, 0)
end

function ProbeStoryController:beginLowAltitudeContact(triggeringPlayer)
    if self.lowAltContactStarted == true then
        return
    end
    self.lowAltContactStarted = true
    self:markPhase("phase_low_alt_contact")
    self:log("low_alt_contact | player=" .. tostring(triggeringPlayer and triggeringPlayer.playerName or "nil"))
    self:queueSharedSequence("low_alt_contact", {
        { speaker = "explicit", playerState = triggeringPlayer, text = "推进中，正在接敌。", delay = 0, duration = 7 },
        { speaker = "AWACS", text = "新的雷达源！", delay = 5, duration = 6 },
        { speaker = "AWACS", text = "低空节点开机！", delay = 4, duration = 6 },
        { speaker = "AWACS", text = "型号判断：SA15 道尔。", delay = 4, duration = 7 },
        { speaker = "player", text = "下面果然还有一层。", delay = 6, duration = 7 },
        { speaker = "leader", text = "低空不是空白。只是换了对手。", delay = 6, duration = 9 },
        { speaker = "AWACS", text = "确认敌方为机动防空系统，信号定位中，雷达辐射源正在移动。", delay = 7, duration = 10 },
        { speaker = "leader", text = "我敢肯定，我们一打它又会关机跑路。", delay = 7, duration = 8 },
        { action = function() self:beginLowAltitudeTacticConclusion() end, delay = 7 },
    }, 0)
end

function ProbeStoryController:beginLowAltitudeTacticConclusion()
    if self.lowAltTacticStarted == true then
        return
    end
    self.lowAltTacticStarted = true
    self:markPhase("phase_low_alt_tactic")
    self:queueSharedSequence("low_alt_tactic", {
        { speaker = "leader", text = "远距离不行。得压近。", delay = 0, duration = 7 },
        { speaker = "player", text = "先用 HARM 逼它关机，再上去补刀？", delay = 6, duration = 8 },
        { speaker = "leader", text = "对。", delay = 6, duration = 5 },
        { speaker = "AWACS", text = "确认。这类节点在近距压制关机后更容易被后续武器摧毁。", delay = 6, duration = 10 },
        { speaker = "player", text = "那就让我们来把它撬开。", delay = 7, duration = 8 },
    }, 0)
end

function ProbeStoryController:isTrackedNodeGroup(groupName)
    if groupName == nil then
        return false
    end
    for i = 1, #self.config.nodeKillGroupNames do
        if groupName == self.config.nodeKillGroupNames[i] then
            return true
        end
    end
    return containsPattern(groupName, self.config.nodeKillGroupPatterns)
end

function ProbeStoryController:checkNodeDestroyed(groupName)
    if groupName == nil or self.destroyedNodeGroups[groupName] == true then
        return
    end
    if self:isTrackedNodeGroup(groupName) ~= true then
        return
    end
    local group = Group.getByName(groupName)
    if group and #getAliveUnits(group) > 0 then
        return
    end
    self.destroyedNodeGroups[groupName] = true
    self.nodeKillCount = self.nodeKillCount + 1
    self:setFlag(self.config.nodeKillCountFlagBase + self.nodeKillCount, 1)
    self:log("node_kill | group=" .. tostring(groupName) .. " | count=" .. tostring(self.nodeKillCount))
    if self.firstKillHandled ~= true then
        self.firstKillHandled = true
        self:setFlag(self.config.firstKillFlag, 1)
        self:queueSharedSequence("first_node_kill", {
            { speaker = "player", text = "目视命中确认。", delay = 0, duration = 6 },
            { speaker = "player", text = "终于打掉一个。", delay = 5, duration = 6 },
            { speaker = "leader", text = "干得不错。但是外围不会只摆一个。", delay = 6, duration = 8 },
            { speaker = "player", text = "干它娘的，你继续躲啊，怎么不跑了。来，继续。", delay = 7, duration = 10 },
            { speaker = "AWACS", text = "够了，Alpha 小队，不要上头，今天先收点利息。", delay = 7, duration = 9 },
            { speaker = "leader", text = "别误会。我们只是终于知道它怎么打了。", delay = 7, duration = 9 },
        }, 0)
    end
    if self.nodeKillCount >= self.config.requiredNodeKills then
        self:beginMissionComplete()
    end
end

function ProbeStoryController:beginMissionComplete()
    if self.missionCompleted == true then
        return
    end
    self.missionCompleted = true
    self:markPhase("phase_retreat")
    self:setFlag(self.config.missionCompleteFlag, 1)
    self:queueSharedSequence("mission_complete", {
        { speaker = "AWACS", text = "全体脱离。今天的目标已经达到。", delay = 0, duration = 9 },
        { speaker = "player", text = "这就算报仇了？", delay = 7, duration = 7 },
        { speaker = "leader", text = "不。", delay = 6, duration = 5 },
        { speaker = "leader", text = "但至少现在我们知道，自己面对的不是靶子。", delay = 5, duration = 9 },
        { speaker = "AWACS", text = "结论更新。贝卡谷地外围防空具备成体系响应能力。", delay = 7, duration = 10 },
        { speaker = "AWACS", text = "远距压制有效，但难以稳定摧毁。低空路线存在独立接管层，会在进入射高射程后立即开机。", delay = 8, duration = 12 },
        { speaker = "AWACS", text = "可以在使用反辐射压制后，使用其他武器进行摧毁。", delay = 9, duration = 10 },
        { speaker = "player", text = "也就是说。它不是铜墙铁壁，也是有弱点的。", delay = 7, duration = 10 },
        { speaker = "leader", text = "对。是一群会换手、会藏、会咬人的东西。", delay = 7, duration = 10 },
    }, 0)
end

function ProbeStoryController:getTaskHint()
    if self.missionStarted ~= true then
        return "等待所有有效玩家通过菜单点击“准备完毕，可以出发”。"
    end
    if self.phase == "phase_brief" then
        return "任务简报中，等待高空试探线解锁。"
    end
    if self.phase == "phase_high_alt_open" or self.phase == "phase_high_alt_contact" then
        return "高空试探线：进入高空试探区，引诱外围 SA-11 亮机，测试远距 HARM 效果。"
    end
    if self.phase == "phase_high_alt_conclusion" then
        return "高空结论已成立：远距 HARM 更接近压制。等待低空试探线解锁。"
    end
    if self.phase == "phase_low_alt_open" then
        return "低空试探线已解锁。通过菜单请求坐标，然后在外围边缘低空试探，不要深入谷地。"
    end
    if self.phase == "phase_low_alt_contact" or self.phase == "phase_low_alt_tactic" then
        return "低空节点已出现。尝试压近、逼规避，再用后续武器补刀。"
    end
    if self.phase == "phase_retreat" then
        return "任务目标达成，立即脱离。"
    end
    return "按当前态势执行，保持高度警惕。"
end

function ProbeStoryController:sendTaskHintToGroup(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    local hint = self:getTaskHint()
    if playerState then
        self:notifyPlayer(playerState, hint, self.config.messageDurationSeconds)
    else
        trigger.action.outTextForGroup(groupId, hint, self.config.messageDurationSeconds)
    end
end

function ProbeStoryController:handleReadyCommand(groupId)
    if self.missionStarted == true then
        self:sendTaskHintToGroup(groupId)
        return
    end
    local playerState = self:getPlayerStateByGroupId(groupId)
    if playerState == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end
    if playerState.ready == true then
        self:notifyPlayer(playerState, "你已确认准备完毕，等待其他玩家。", self.config.messageDurationSeconds)
        return
    end
    playerState.ready = true
    self:assignReadyIndex(playerState)
    self:notifyPlayer(playerState, self:getPlayerLabel(playerState) .. "，准备完毕。", self.config.messageDurationSeconds)
    self:log("ready | player=" .. tostring(playerState.playerName) .. " | index=" .. tostring(playerState.readyIndex))
end

function ProbeStoryController:handleCoordsReadyCommand(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    if playerState == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end
    if self.lowAltUnlocked ~= true then
        self:notifyPlayer(playerState, "低空试探线尚未解锁。", self.config.messageDurationSeconds)
        return
    end
    self:broadcastCoordinates(playerState)
end

function ProbeStoryController:handleCoordsAckCommand(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    if playerState == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end
    local coordsText = self.coordsText or "尚未发送坐标"
    self:notifyPlayer(playerState, self:getPlayerLabel(playerState) .. "：坐标输入完成，" .. coordsText, self.config.messageDurationSeconds)
end

function ProbeStoryController:handleCoordsRepeatCommand(groupId)
    local playerState = self:getPlayerStateByGroupId(groupId)
    if playerState == nil then
        trigger.action.outTextForGroup(groupId, "未识别到有效玩家座机。", self.config.messageDurationSeconds)
        return
    end
    local coordsText = self.coordsText or "当前没有可重复的坐标。"
    self:notifyPlayer(playerState, "AWACS：重复坐标，" .. coordsText, self.config.messageDurationSeconds)
end

function ProbeStoryController:checkReadyGate()
    if self.missionStarted == true then
        return
    end
    if self:allActivePlayersReady() ~= true then
        return
    end
    if getCurrentTime() - self.lastRosterChangeTime < self.config.readyStabilizeSeconds then
        return
    end
    self:beginMissionBrief()
end

function ProbeStoryController:checkPhaseTriggers()
    local playerUnits = self:findPlayerUnits()
    for i = 1, #playerUnits do
        local unit = playerUnits[i]
        local playerState = self:ensurePlayerTracked(unit)
        if self.highAltUnlocked == true and self.highAltHintSent ~= true and self:isPlayerInHighAltitudeEnvelope(unit) == true then
            self.highAltHintSent = true
            self:notifyPlayer(playerState, "你已进入高空试探线，尝试引诱外围高空节点开机。", self.config.messageDurationSeconds)
        end
        if self.lowAltUnlocked == true and self.lowAltContactStarted ~= true and self:isPlayerInLowAltitudeEnvelope(unit) == true then
            self:beginLowAltitudeContact(playerState)
        end
    end
end

function ProbeStoryController:isWeaponHarm(weapon)
    local weaponText = getWeaponTypeText(weapon)
    return containsPattern(weaponText, self.config.harmWeaponPatterns), weaponText
end

function ProbeStoryController:handlePlayerShot(event)
    local initiator = event and event.initiator or nil
    if initiator == nil or getPlayerName(initiator) == nil then
        return
    end
    local isHarm, weaponText = self:isWeaponHarm(event.weapon)
    if isHarm ~= true then
        return
    end
    local playerState = self:ensurePlayerTracked(initiator)
    if playerState == nil then
        return
    end
    if self.highAltUnlocked ~= true or self:isPlayerInHighAltitudeEnvelope(initiator) ~= true then
        self:log("harm_shot_ignored | player=" .. tostring(playerState.playerName) .. " | weapon=" .. tostring(weaponText))
        return
    end
    if self.firstHarmShotHandled ~= true then
        self:handleFirstHarmShot(playerState, weaponText)
        return
    end
    if self.highAltConclusionStarted ~= true and self.secondHarmShotHandled ~= true then
        self:handleSecondHarmShot(playerState, weaponText)
    end
end

function ProbeStoryController:handleRedUnitLoss(event)
    local unit = event and event.initiator or nil
    if unit == nil then
        return
    end
    local group = getUnitGroup(unit)
    if group and getGroupCoalition(group) ~= self.config.targetCoalition then
        return
    end
    local groupName = group and getGroupName(group) or nil
    self:checkNodeDestroyed(groupName)
end

function ProbeStoryController:tick()
    self:updatePlayerRoster()
    self:checkReadyGate()
    self:checkPhaseTriggers()
    return getCurrentTime() + self.config.scanIntervalSeconds
end

function ProbeStoryController:onWorldEvent(event)
    if event == nil then
        return
    end
    if event.id == world.event.S_EVENT_BIRTH and event.initiator and getPlayerName(event.initiator) then
        self:ensurePlayerTracked(event.initiator)
        return
    end
    if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT and event.initiator and getPlayerName(event.initiator) then
        self:ensurePlayerTracked(event.initiator)
        return
    end
    if event.id == world.event.S_EVENT_SHOT then
        self:handlePlayerShot(event)
        return
    end
    if event.id == world.event.S_EVENT_DEAD or event.id == world.event.S_EVENT_CRASH then
        self:handleRedUnitLoss(event)
    end
end

function ProbeStoryController:start()
    self:log("start | version=" .. tostring(self.VERSION))
    if math and math.randomseed and os and os.time then
        pcall(function()
            math.randomseed(os.time())
        end)
    end
    _G.BEKAA_STORY_SKYNET_AMBUSH_LOCK = false
    if type(_G.SkynetStorySetAmbushLock) == "function" then
        pcall(_G.SkynetStorySetAmbushLock, false, "probe_start_reset")
    end
    if self.eventHandler == nil then
        self.eventHandler = {}
        function self.eventHandler:onEvent(event)
            if ProbeStoryControllerInstance and ProbeStoryControllerInstance.onWorldEvent then
                ProbeStoryControllerInstance:onWorldEvent(event)
            end
        end
        world.addEventHandler(self.eventHandler)
    end
    timer.scheduleFunction(function()
        return self:tick()
    end, {}, getCurrentTime() + 1)
end

ProbeStoryControllerInstance = ProbeStoryController:create(_G.PROBE_STORY_CONFIG)
ProbeStoryControllerInstance:start()

end
