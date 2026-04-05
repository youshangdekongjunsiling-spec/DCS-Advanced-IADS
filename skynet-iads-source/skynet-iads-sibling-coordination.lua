do

SkynetIADSSiblingCoordination = {}
SkynetIADSSiblingCoordination.__index = SkynetIADSSiblingCoordination

SkynetIADSSiblingCoordination._familyByElement = setmetatable({}, { __mode = "k" })
SkynetIADSSiblingCoordination._memberByElement = setmetatable({}, { __mode = "k" })

SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION = "hold_dark"
SkynetIADSSiblingCoordination.DEFAULT_MODE = "ambush"
SkynetIADSSiblingCoordination.DEFAULT_DENIAL_ALERT_DISTANCE_NM = 25
SkynetIADSSiblingCoordination.DEFAULT_SUPPRESSED_SWITCH_DELAY_SECONDS = 10
SkynetIADSSiblingCoordination.DEFAULT_PRIMARY_LATCH_SECONDS = 8
SkynetIADSSiblingCoordination.DEFAULT_PRIMARY_DISTANCE_HYSTERESIS_NM = 1.5
SkynetIADSSiblingCoordination.DEFAULT_ROTATION_INTERVAL_SECONDS = 180
SkynetIADSSiblingCoordination.DEFAULT_ROTATION_MIN_MOVE_METERS = 1000
SkynetIADSSiblingCoordination.DEFAULT_ROTATION_COOLDOWN_SECONDS = 30

local function setGroundROE(controller, weaponHold)
    pcall(function()
        controller:setOption(
            AI.Option.Ground.id.ROE,
            weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or AI.Option.Ground.val.ROE.OPEN_FIRE
        )
    end)
end

local function setPatrolAlarmState(controller)
    pcall(function()
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
    end)
end

local function setCombatAlarmState(controller)
    pcall(function()
        controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
    end)
end

local function appendUniqueRepresentation(representations, representation, seenKeys)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    local key = nil
    local okName, name = pcall(function()
        return representation:getName()
    end)
    if okName and name then
        key = name
    end
    if key == nil then
        key = tostring(representation)
    end
    if seenKeys[key] then
        return
    end
    seenKeys[key] = true
    representations[#representations + 1] = representation
end

local function collectElementEmitterRepresentations(element)
    local representations = {}
    local seenKeys = {}
    appendUniqueRepresentation(representations, element:getDCSRepresentation(), seenKeys)

    local searchRadars = element.getSearchRadars and element:getSearchRadars() or {}
    for i = 1, #searchRadars do
        appendUniqueRepresentation(representations, searchRadars[i]:getDCSRepresentation(), seenKeys)
    end

    local trackingRadars = element.getTrackingRadars and element:getTrackingRadars() or {}
    for i = 1, #trackingRadars do
        appendUniqueRepresentation(representations, trackingRadars[i]:getDCSRepresentation(), seenKeys)
    end

    local launchers = element.getLaunchers and element:getLaunchers() or {}
    for i = 1, #launchers do
        appendUniqueRepresentation(representations, launchers[i]:getDCSRepresentation(), seenKeys)
    end

    return representations
end

local function applyDarkStandbyToRepresentation(representation)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    pcall(function()
        representation:enableEmission(false)
    end)
    local okController, controller = pcall(function()
        return representation:getController()
    end)
    if okController and controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setPatrolAlarmState(controller)
        setGroundROE(controller, true)
    end
end

local function forceElementIntoDarkStandby(element)
    if element == nil or element.isDestroyed == nil or element:isDestroyed() then
        return
    end
    local representations = collectElementEmitterRepresentations(element)
    for i = 1, #representations do
        applyDarkStandbyToRepresentation(representations[i])
    end
    local controller = element.getController and element:getController() or nil
    if controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setPatrolAlarmState(controller)
        setGroundROE(controller, true)
    end
    element.aiState = false
    if element.targetsInRange ~= nil then
        element.targetsInRange = false
    end
    element.cachedTargets = {}
    if element.stopScanningForHARMs then
        element:stopScanningForHARMs()
    end
end

local function setCombatROEForRepresentation(representation, weaponHold)
    if representation == nil or representation.isExist == nil or representation:isExist() == false then
        return
    end
    local okController, controller = pcall(function()
        return representation:getController()
    end)
    if okController and controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setCombatAlarmState(controller)
        setGroundROE(controller, weaponHold)
        pcall(function()
            representation:enableEmission(true)
        end)
    end
end

local function setElementCombatROE(element, weaponHold)
    if element == nil or element.isDestroyed == nil or element:isDestroyed() then
        return
    end
    local representations = collectElementEmitterRepresentations(element)
    for i = 1, #representations do
        setCombatROEForRepresentation(representations[i], weaponHold)
    end
    local controller = element.getController and element:getController() or nil
    if controller then
        pcall(function()
            controller:setOnOff(true)
        end)
        setCombatAlarmState(controller)
        setGroundROE(controller, weaponHold)
    end
    if weaponHold then
        element.aiState = true
    end
end

function SkynetIADSSiblingCoordination.getFamilyForElement(element)
    local family = SkynetIADSSiblingCoordination._familyByElement[element]
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    if family == nil or member == nil then
        return nil
    end
    return {
        name = family.name,
        mode = family.mode,
        role = member.lastRole or "released",
        primaryGroupName = family.activeGroupName,
        preferredPrimaryGroupName = family.preferredPrimaryGroupName,
        denialAlertDistanceNm = family.denialAlertDistanceNm,
        reason = family.activeReason,
        sharedReason = family.activeReason,
        passiveAction = family.passiveAction,
        passiveMode = member.passiveMode,
    }
end

function SkynetIADSSiblingCoordination.isElementForcedPassive(element)
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    return member ~= nil and member.forcedPassive == true
end

function SkynetIADSSiblingCoordination:log(message)
    if self.iads and self.iads.printOutputToLog then
        self.iads:printOutputToLog("[SiblingCoord] " .. message)
    end
end

function SkynetIADSSiblingCoordination:notifyDebug(message)
    if _G.SkynetRuntimeDebugNotify and message then
        pcall(_G.SkynetRuntimeDebugNotify, message)
    end
end

function SkynetIADSSiblingCoordination:withOrderTraceOrigin(details, functionName)
    local payload = {}
    if details then
        for key, value in pairs(details) do
            payload[key] = value
        end
    end
    payload.originModule = payload.originModule or "skynet-iads-sibling-coordination.lua"
    payload.originFunction = payload.originFunction or functionName
    return payload
end

function SkynetIADSSiblingCoordination:setOrderTraceContext(element, reason, details, functionName)
    if self.iads and self.iads.setOrderTraceContext then
        local context = {
            reason = reason,
        }
        local payload = self:withOrderTraceOrigin(details, functionName)
        if payload then
            for key, value in pairs(payload) do
                context[key] = value
            end
        end
        self.iads:setOrderTraceContext(element, context)
    end
end

function SkynetIADSSiblingCoordination:traceElementCommand(element, command, details, functionName)
    if self.iads and self.iads.traceElementCommand then
        return self.iads:traceElementCommand(element, command, self:withOrderTraceOrigin(details, functionName))
    end
    return false
end

function SkynetIADSSiblingCoordination:getMobilePatrolEntry(element)
    local entry = nil
    if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
        entry = SkynetIADSMobilePatrol.getEntryForElement(element)
    end
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    if entry ~= nil then
        if member ~= nil then
            member.mobileEntry = entry
        end
        return entry
    end
    if member ~= nil then
        return member.mobileEntry
    end
    return nil
end

function SkynetIADSSiblingCoordination:isMSAMDeployState(entry)
    return entry ~= nil
        and entry.kind == "MSAM"
        and (entry.state == "deployed" or entry.state == "deploy_scattering")
end

function SkynetIADSSiblingCoordination:isSuppressed(member)
    local element = member.element
    return element.harmSilenceID ~= nil or element.harmRelocationInProgress == true
end

function SkynetIADSSiblingCoordination:isFamilyGroupName(family, groupName)
    if family == nil or groupName == nil then
        return false
    end
    for i = 1, #family.members do
        local member = family.members[i]
        if member and member.groupName == groupName then
            return true
        end
    end
    return false
end

function SkynetIADSSiblingCoordination:getSafeThreatName(family, ...)
    local candidates = { ... }
    for i = 1, #candidates do
        local candidate = candidates[i]
        if candidate ~= nil and self:isFamilyGroupName(family, candidate) ~= true then
            return candidate
        end
    end
    return nil
end

function SkynetIADSSiblingCoordination:cacheFamilyThreat(family, member, threatDecision)
    if family == nil or threatDecision == nil then
        return
    end
    local triggerInfo = threatDecision.triggerInfo or nil
    local contact = threatDecision.contact or nil
    if contact ~= nil and contact.isIdentifiedAsHARM and contact:isIdentifiedAsHARM() then
        return
    end
    family.lastThreatContact = contact
    family.lastThreatSourceGroupName = member and member.groupName or nil
    if triggerInfo ~= nil then
        family.lastThreatTriggerInfo = mist.utils.deepCopy(triggerInfo)
    end
end

function SkynetIADSSiblingCoordination:isEngaged(member)
    if member and member.forcedPassive == true then
        return false
    end
    local element = member.element
    local entry = self:getMobilePatrolEntry(element)
    if entry ~= nil then
        local missilesInFlight = element:getNumberOfMissilesInFlight() > 0
        local targetsInRange = element.targetsInRange == true
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            return (
                (entry.combatMode ~= nil and entry.combatMode ~= "patrolling" and entry.combatMode ~= "searching")
                or targetsInRange
                or missilesInFlight
            )
        end
        return (
            entry.combatCommitted == true
            or targetsInRange
            or missilesInFlight
        )
    end
    return element:isActive() or element.targetsInRange == true or element:getNumberOfMissilesInFlight() > 0
end

function SkynetIADSSiblingCoordination:canCover(member)
    local element = member.element
    return element:isDestroyed() == false
        and element:hasWorkingPowerSource()
        and element:hasRemainingAmmo()
        and element:hasWorkingRadar()
end

function SkynetIADSSiblingCoordination:hasLiveRadarUnits(member)
    if member == nil or member.element == nil or member.element.getRadars == nil then
        return false
    end
    local radars = member.element:getRadars() or {}
    if #radars == 0 then
        return true
    end
    for i = 1, #radars do
        local radar = radars[i]
        if radar ~= nil then
            local okExists, exists = pcall(function()
                return radar:isExist()
            end)
            if okExists and exists == true then
                return true
            end
            local okDestroyed, destroyed = pcall(function()
                return radar:isDestroyed()
            end)
            if okDestroyed and destroyed == false then
                return true
            end
        end
    end
    return false
end

function SkynetIADSSiblingCoordination:canParticipate(member)
    local element = member and member.element or nil
    if element == nil then
        return false
    end
    return element:isDestroyed() == false
        and element:hasWorkingPowerSource()
        and element:hasRemainingAmmo()
        and self:hasLiveRadarUnits(member)
end

function SkynetIADSSiblingCoordination:refreshMemberDeploymentObserved(member, now)
    if member == nil then
        return nil, false
    end
    local entry = self:getMobilePatrolEntry(member.element)
    local deployed = self:isMSAMDeployState(entry) and self:isSuppressed(member) ~= true
    if deployed then
        if member.deployedObservedSince == nil then
            member.deployedObservedSince = now
        end
    else
        member.deployedObservedSince = nil
    end
    return entry, deployed
end

function SkynetIADSSiblingCoordination:getRotationMoveDistanceMeters(member)
    if member == nil or member.rotationMoveStartPoint == nil then
        return 0
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry == nil or entry.manager == nil or entry.manager.getPatrolReferencePoint == nil then
        return 0
    end
    local currentPoint = entry.manager:getPatrolReferencePoint(entry)
    if currentPoint == nil then
        return 0
    end
    return mist.utils.get2DDist(currentPoint, member.rotationMoveStartPoint)
end

function SkynetIADSSiblingCoordination:clearRotationState(family, member)
    if member ~= nil then
        member.rotationMoveActive = false
        member.rotationMoveStartPoint = nil
        member.rotationStartedAt = nil
        member.rotationReason = nil
    end
    if family ~= nil then
        family.rotationActiveGroupName = nil
        family.rotationCoverGroupName = nil
        family.rotationStartedAt = nil
    end
end

function SkynetIADSSiblingCoordination:finishRotation(family, member, outcome, note)
    if family == nil or member == nil then
        return
    end
    local movedMeters = mist.utils.round(self:getRotationMoveDistanceMeters(member), 1)
    self:traceElementCommand(member.element, outcome == "complete" and "family_rotation_complete" or "family_rotation_abort", {
        outcome = outcome,
        source = "family_rotation",
        family = family.name,
        familyMode = family.mode,
        familyRole = member.lastRole or "passive",
        coverGroup = family.rotationCoverGroupName,
        movedMeters = movedMeters,
        rotationReason = member.rotationReason,
        rotationMinMoveMeters = family.rotationMinMoveMeters,
        rotationIntervalSeconds = family.rotationIntervalSeconds,
        note = note,
    }, "finishRotation")
    self:log(
        "rotation " .. tostring(outcome)
        .. " | family=" .. family.name
        .. " | group=" .. member.groupName
        .. " | moved=" .. tostring(movedMeters) .. "m"
        .. " | cover=" .. tostring(family.rotationCoverGroupName)
        .. " | reason=" .. tostring(member.rotationReason)
        .. (note and (" | note=" .. tostring(note)) or "")
    )
    if outcome == "complete" then
        self:notifyDebug(member.groupName .. " rotation complete | family=" .. family.name)
    elseif note ~= "family_released" then
        self:notifyDebug(member.groupName .. " rotation abort | family=" .. family.name .. " | note=" .. tostring(note))
    end
    self:clearRotationState(family, member)
    family.rotationCooldownUntil = timer.getTime() + (family.rotationCooldownSeconds or self.defaultRotationCooldownSeconds)
end

function SkynetIADSSiblingCoordination:startRotation(family, member, coverMember, reason)
    if family == nil or member == nil then
        return false
    end
    if family.rotationActiveGroupName ~= nil and family.rotationActiveGroupName ~= member.groupName then
        return false
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry == nil or entry.manager == nil or entry.manager.getPatrolReferencePoint == nil then
        return false
    end
    local startPoint = entry.manager:getPatrolReferencePoint(entry)
    member.rotationMoveActive = true
    member.rotationMoveStartPoint = startPoint and mist.utils.deepCopy(startPoint) or nil
    member.rotationStartedAt = timer.getTime()
    member.rotationReason = reason
    family.rotationActiveGroupName = member.groupName
    family.rotationCoverGroupName = coverMember and coverMember.groupName or nil
    family.rotationStartedAt = timer.getTime()
    self:traceElementCommand(member.element, "family_rotation_start", {
        outcome = "issued",
        source = "family_rotation",
        family = family.name,
        familyMode = family.mode,
        familyRole = member.lastRole or "passive",
        coverGroup = family.rotationCoverGroupName,
        rotationReason = reason,
        rotationMinMoveMeters = family.rotationMinMoveMeters,
        rotationIntervalSeconds = family.rotationIntervalSeconds,
    }, "startRotation")
    if coverMember and coverMember.element then
        self:traceElementCommand(coverMember.element, "family_rotation_cover_takeover", {
            outcome = "issued",
            source = "family_rotation",
            family = family.name,
            familyMode = family.mode,
            familyRole = "primary",
            coverGroup = member.groupName,
            rotationReason = reason,
            rotationMinMoveMeters = family.rotationMinMoveMeters,
            rotationIntervalSeconds = family.rotationIntervalSeconds,
        }, "startRotation")
    end
    self:log(
        "rotation start | family=" .. family.name
        .. " | rotate=" .. member.groupName
        .. " | cover=" .. tostring(family.rotationCoverGroupName)
        .. " | reason=" .. tostring(reason)
        .. " | minMove=" .. tostring(family.rotationMinMoveMeters) .. "m"
        .. " | interval=" .. tostring(family.rotationIntervalSeconds) .. "s"
    )
    self:notifyDebug(member.groupName .. " rotate out | family=" .. family.name)
    if coverMember and coverMember.groupName ~= nil then
        self:notifyDebug(coverMember.groupName .. " cover active | family=" .. family.name)
    end
    return true
end

function SkynetIADSSiblingCoordination:refreshFamilyRotation(family)
    if family == nil then
        return
    end
    local now = timer.getTime()
    for i = 1, #family.members do
        self:refreshMemberDeploymentObserved(family.members[i], now)
    end
    local rotatingMember = self:findMemberByGroupName(family, family.rotationActiveGroupName)
    if rotatingMember == nil then
        if family.rotationActiveGroupName ~= nil then
            self:clearRotationState(family, nil)
        end
        return
    end
    if rotatingMember.element:isDestroyed() then
        self:finishRotation(family, rotatingMember, "abort", "destroyed")
        return
    end
    if self:isSuppressed(rotatingMember) then
        self:finishRotation(family, rotatingMember, "abort", "suppressed")
        return
    end
    local movedMeters = self:getRotationMoveDistanceMeters(rotatingMember)
    if movedMeters >= (family.rotationMinMoveMeters or self.defaultRotationMinMoveMeters) then
        self:finishRotation(family, rotatingMember, "complete", "min_move_reached")
    end
end

function SkynetIADSSiblingCoordination:isRotationDue(family, member, now)
    if family == nil or member == nil then
        return false
    end
    if member.rotationMoveActive == true or self:isSuppressed(member) then
        return false
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if self:isMSAMDeployState(entry) ~= true then
        return false
    end
    if member.deployedObservedSince == nil then
        return false
    end
    return (now - member.deployedObservedSince) >= (family.rotationIntervalSeconds or self.defaultRotationIntervalSeconds)
end

function SkynetIADSSiblingCoordination:pickStandbyRotationCandidate(family, primary, now)
    if family == nil then
        return nil
    end
    local bestMember = nil
    local bestObservedSince = math.huge
    for i = 1, #family.members do
        local member = family.members[i]
        if member ~= primary and member.passiveMode == "standby" and self:isRotationDue(family, member, now) then
            local observedSince = member.deployedObservedSince or now
            if observedSince < bestObservedSince then
                bestMember = member
                bestObservedSince = observedSince
            end
        end
    end
    return bestMember
end

function SkynetIADSSiblingCoordination:pickDeployedRotationCandidate(family, excludedGroupName, now)
    if family == nil then
        return nil
    end
    local bestMember = nil
    local bestObservedSince = math.huge
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName ~= excludedGroupName and self:isRotationDue(family, member, now) then
            local observedSince = member.deployedObservedSince or now
            if observedSince < bestObservedSince then
                bestMember = member
                bestObservedSince = observedSince
            end
        end
    end
    return bestMember
end

function SkynetIADSSiblingCoordination:hasReleasedDeployedMembers(family)
    if family == nil then
        return false
    end
    for i = 1, #family.members do
        local member = family.members[i]
        local entry = self:getMobilePatrolEntry(member.element)
        if self:isMSAMDeployState(entry) == true and self:isSuppressed(member) ~= true then
            return true
        end
    end
    return false
end

function SkynetIADSSiblingCoordination:findMemberByGroupName(family, groupName)
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName == groupName then
            return member
        end
    end
    return nil
end

function SkynetIADSSiblingCoordination:pickCoverMember(family, excludedGroupName)
    local bestMember = self:getBestThreatCandidate(family, excludedGroupName)
    if bestMember ~= nil then
        return bestMember
    end
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName ~= excludedGroupName and self:isSuppressed(member) == false and self:canParticipate(member) then
            return member
        end
    end
    return nil
end

function SkynetIADSSiblingCoordination:getPreferredPrimaryMember(family)
    if family.preferredPrimaryGroupName then
        local preferred = self:findMemberByGroupName(family, family.preferredPrimaryGroupName)
        if preferred then
            return preferred
        end
    end
    return family.members[1]
end

function SkynetIADSSiblingCoordination:getMemberThreatDecision(family, member)
    if family == nil or member == nil then
        return nil
    end
    if self:isSuppressed(member) or self:canParticipate(member) == false then
        return nil
    end
    if family.mode == "denial" then
        return self:getDenialThreatDecision(family, member)
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.kind == "MSAM" and entry.manager and entry.manager.findSAMThreatContact then
        return entry.manager:findSAMThreatContact(entry)
    end
    return nil
end

function SkynetIADSSiblingCoordination:getThreatDecisionDistanceNm(threatDecision)
    if threatDecision == nil then
        return math.huge
    end
    local triggerInfo = threatDecision.triggerInfo or {}
    return tonumber(triggerInfo.effectiveDistanceNm)
        or tonumber(triggerInfo.distanceNm)
        or tonumber(triggerInfo.contactDistanceNm)
        or tonumber(triggerInfo.directDistanceNm)
        or math.huge
end

function SkynetIADSSiblingCoordination:getThreatDecisionPriority(threatDecision)
    if threatDecision == nil then
        return -1
    end
    if threatDecision.shouldGoLive == true then
        return 1
    end
    return 0
end

function SkynetIADSSiblingCoordination:clearPrimarySelectionLock(family)
    if family == nil then
        return
    end
    family.primarySelectionGroupName = nil
    family.primarySelectionUntil = 0
end

function SkynetIADSSiblingCoordination:setPrimarySelectionLock(family, member)
    if family == nil or member == nil then
        return
    end
    family.primarySelectionGroupName = member.groupName
    family.primarySelectionUntil = timer.getTime() + (family.primaryLatchSeconds or self.defaultPrimaryLatchSeconds)
end

function SkynetIADSSiblingCoordination:getPrimarySelectionLockRemaining(family, member)
    if family == nil or member == nil then
        return 0
    end
    if family.primarySelectionGroupName ~= member.groupName then
        return 0
    end
    local remaining = (family.primarySelectionUntil or 0) - timer.getTime()
    if remaining <= 0 then
        return 0
    end
    return remaining
end

function SkynetIADSSiblingCoordination:isPrimarySelectionLocked(family, member)
    return self:getPrimarySelectionLockRemaining(family, member) > 0
end

function SkynetIADSSiblingCoordination:shouldRetainCurrentPrimary(family, currentPrimary, currentDecision, bestMember, bestDecision)
    if family == nil or currentPrimary == nil or currentDecision == nil then
        return false
    end
    if self:isSuppressed(currentPrimary) or self:canParticipate(currentPrimary) == false then
        return false
    end
    if bestMember == nil or bestMember == currentPrimary then
        return true
    end

    local currentPriority = self:getThreatDecisionPriority(currentDecision)
    local bestPriority = self:getThreatDecisionPriority(bestDecision)
    if bestPriority > currentPriority then
        return false
    end
    if self:isPrimarySelectionLocked(family, currentPrimary) then
        return true
    end

    local currentDistanceNm = self:getThreatDecisionDistanceNm(currentDecision)
    local bestDistanceNm = self:getThreatDecisionDistanceNm(bestDecision)
    local hysteresisNm = family.primaryDistanceHysteresisNm or self.defaultPrimaryDistanceHysteresisNm
    return bestDistanceNm >= (currentDistanceNm - hysteresisNm)
end

function SkynetIADSSiblingCoordination:getBestThreatCandidate(family, excludedGroupName)
    local bestMember = nil
    local bestDecision = nil
    local bestShouldGoLive = -1
    local bestDistanceNm = math.huge
    local bestPreferred = -1
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName ~= excludedGroupName then
            local threatDecision = self:getMemberThreatDecision(family, member)
            if threatDecision then
                local shouldGoLiveScore = threatDecision.shouldGoLive == true and 1 or 0
                local distanceNm = self:getThreatDecisionDistanceNm(threatDecision)
                local preferredScore = family.preferredPrimaryGroupName == member.groupName and 1 or 0
                local isBetter =
                    shouldGoLiveScore > bestShouldGoLive
                    or (shouldGoLiveScore == bestShouldGoLive and distanceNm < bestDistanceNm)
                    or (shouldGoLiveScore == bestShouldGoLive and distanceNm == bestDistanceNm and preferredScore > bestPreferred)
                if isBetter then
                    bestMember = member
                    bestDecision = threatDecision
                    bestShouldGoLive = shouldGoLiveScore
                    bestDistanceNm = distanceNm
                    bestPreferred = preferredScore
                end
            end
        end
    end
    return bestMember, bestDecision
end

function SkynetIADSSiblingCoordination:clearSuppressedSwitchLock(family)
    if family == nil then
        return
    end
    family.suppressedSwitchGroupName = nil
    family.suppressedSwitchUntil = 0
end

function SkynetIADSSiblingCoordination:ensureSuppressedSwitchLock(family, member)
    if family == nil or member == nil then
        return false
    end
    local now = timer.getTime()
    if family.suppressedSwitchGroupName == member.groupName then
        return false
    end
    self:clearPrimarySelectionLock(family)
    family.suppressedSwitchGroupName = member.groupName
    family.suppressedSwitchUntil = now + (family.suppressedSwitchDelaySeconds or self.defaultSuppressedSwitchDelaySeconds)
    local delaySeconds = mist.utils.round((family.suppressedSwitchUntil or now) - now, 1)
    self:log("switch lock start | family=" .. family.name .. " | suppressed=" .. member.groupName .. " | delay=" .. tostring(delaySeconds) .. "s")
    self:notifyDebug(family.name .. " switch lock -> " .. member.groupName .. " | delay=" .. tostring(delaySeconds) .. "s")
    return true
end

function SkynetIADSSiblingCoordination:getSuppressedSwitchLockRemaining(family, member)
    if family == nil or member == nil then
        return 0
    end
    if family.suppressedSwitchGroupName ~= member.groupName then
        return 0
    end
    local remaining = (family.suppressedSwitchUntil or 0) - timer.getTime()
    if remaining <= 0 then
        return 0
    end
    return remaining
end

function SkynetIADSSiblingCoordination:getSuppressedSwitchLockedMember(family)
    if family == nil or family.suppressedSwitchGroupName == nil then
        return nil
    end
    local member = self:findMemberByGroupName(family, family.suppressedSwitchGroupName)
    if member == nil then
        self:clearSuppressedSwitchLock(family)
    end
    return member
end

function SkynetIADSSiblingCoordination:arbitrateThreatDecision(element)
    local family = SkynetIADSSiblingCoordination._familyByElement[element]
    local member = SkynetIADSSiblingCoordination._memberByElement[element]
    if family == nil or member == nil then
        return nil, true
    end
    if member.forcedPassive == true then
        return nil, false
    end

    local currentPrimary = self:findMemberByGroupName(family, family.activeGroupName)
    local lockedPrimary = self:getSuppressedSwitchLockedMember(family)
    if currentPrimary and self:isSuppressed(currentPrimary) then
        self:ensureSuppressedSwitchLock(family, currentPrimary)
        lockedPrimary = currentPrimary
    end
    if lockedPrimary and currentPrimary == lockedPrimary then
        local lockRemainingSeconds = self:getSuppressedSwitchLockRemaining(family, lockedPrimary)
        if lockRemainingSeconds > 0 then
            return nil, false
        end
        local coverMember, coverDecision = self:getBestThreatCandidate(family, lockedPrimary.groupName)
        if coverMember then
            if coverMember ~= member then
                return nil, false
            end
            return coverDecision, true
        end
        self:clearSuppressedSwitchLock(family)
    end
    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        if currentPrimary ~= member then
            return nil, false
        end
        if family.mode == "denial" then
            local denialThreatDecision = self:getDenialThreatDecision(family, currentPrimary)
            if denialThreatDecision then
                return denialThreatDecision, true
            end
        end
        local entry = self:getMobilePatrolEntry(member.element)
        if entry and entry.kind == "MSAM" and entry.manager and entry.manager.findSAMThreatContact then
            return entry.manager:findSAMThreatContact(entry), true
        end
        return nil, true
    end

    local currentDecision = nil
    if currentPrimary and self:isSuppressed(currentPrimary) == false then
        currentDecision = self:getMemberThreatDecision(family, currentPrimary)
    end
    local bestMember, bestDecision = self:getBestThreatCandidate(family, nil)
    if self:shouldRetainCurrentPrimary(family, currentPrimary, currentDecision, bestMember, bestDecision) then
        if currentPrimary ~= member then
            return nil, false
        end
        return currentDecision, true
    end
    if bestMember == nil then
        return nil, true
    end
    if bestMember ~= member then
        return nil, false
    end
    return bestDecision, true
end

function SkynetIADSSiblingCoordination:getDenialThreatDecision(family, member)
    local entry = self:getMobilePatrolEntry(member.element)
    if entry == nil or entry.kind ~= "MSAM" or entry.manager == nil then
        return nil
    end
    local moveFireCapable = entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
    local alertRangeMeters = mist.utils.NMToMeters(family.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm)
    local directUnit = nil
    local directUnitDistanceMeters = math.huge
    if entry.manager.findNearestEnemyAircraftUnit then
        directUnit, directUnitDistanceMeters = entry.manager:findNearestEnemyAircraftUnit(entry, alertRangeMeters)
    end

    local contact = nil
    local contactDistanceMeters = math.huge
    if entry.manager.findNearestEligibleContact then
        contact, contactDistanceMeters = entry.manager:findNearestEligibleContact(entry, alertRangeMeters)
    end

    if directUnit == nil and contact == nil then
        return nil
    end

    local canGoLive = moveFireCapable or contact ~= nil
    local combatMode = canGoLive and "sibling_denial_alert" or "sibling_denial_deploy"
    local triggerInfo = nil
    if directUnit ~= nil and entry.manager.buildAircraftUnitTriggerInfo then
        triggerInfo = entry.manager:buildAircraftUnitTriggerInfo(entry, directUnit, "sibling_denial_alert", alertRangeMeters)
    else
        triggerInfo = entry.manager:buildDeployTriggerInfo(entry, contact, "sibling_denial_alert")
        triggerInfo.distanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
    end

    triggerInfo.combatMode = combatMode
    triggerInfo.familyMode = family.mode
    triggerInfo.denialAlertDistanceNm = family.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm
    triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(alertRangeMeters), 1)
    if contact ~= nil and contactDistanceMeters < math.huge then
        triggerInfo.contactDistanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
    end
    if directUnit ~= nil and directUnitDistanceMeters < math.huge then
        triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
        triggerInfo.effectiveDistanceNm = triggerInfo.directDistanceNm
        triggerInfo.distanceNm = triggerInfo.directDistanceNm
    elseif contactDistanceMeters < math.huge then
        triggerInfo.effectiveDistanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
        triggerInfo.distanceNm = triggerInfo.contactDistanceNm or triggerInfo.distanceNm
    end

    return {
        contact = contact,
        triggerInfo = triggerInfo,
        shouldDeploy = not moveFireCapable,
        shouldGoLive = canGoLive,
        shouldWeaponHold = false,
        combatMode = combatMode,
    }
end

function SkynetIADSSiblingCoordination:choosePrimaryMember(family)
    local currentPrimary = self:findMemberByGroupName(family, family.activeGroupName)
    local now = timer.getTime()
    if currentPrimary and self:isSuppressed(currentPrimary) then
        self:ensureSuppressedSwitchLock(family, currentPrimary)
    end
    local lockedPrimary = self:getSuppressedSwitchLockedMember(family)
    if lockedPrimary and currentPrimary == lockedPrimary then
        local lockRemainingSeconds = self:getSuppressedSwitchLockRemaining(family, lockedPrimary)
        if lockRemainingSeconds > 0 then
            return lockedPrimary, "switch_lock_" .. lockedPrimary.groupName, nil
        end
        local coverMember, coverDecision = self:getBestThreatCandidate(family, lockedPrimary.groupName)
        if coverMember then
            self:clearSuppressedSwitchLock(family)
            return coverMember, "cover_for_" .. lockedPrimary.groupName, coverDecision
        end
        self:clearSuppressedSwitchLock(family)
    end

    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        if family.rotationActiveGroupName == nil and (family.rotationCooldownUntil or 0) <= now and self:isRotationDue(family, currentPrimary, now) then
            local coverMember, coverDecision = self:getBestThreatCandidate(family, currentPrimary.groupName)
            if coverMember and coverMember ~= currentPrimary then
                return coverMember, "rotation_cover_for_" .. currentPrimary.groupName, coverDecision
            end
        end
        return currentPrimary, "engaged", nil
    end

    local currentDecision = nil
    if currentPrimary and self:isSuppressed(currentPrimary) == false then
        currentDecision = self:getMemberThreatDecision(family, currentPrimary)
    end
    local bestMember, bestDecision = self:getBestThreatCandidate(family, nil)
    if self:shouldRetainCurrentPrimary(family, currentPrimary, currentDecision, bestMember, bestDecision) then
        return currentPrimary, family.activeReason or "nearest_trigger", currentDecision
    end
    if bestMember then
        return bestMember, "nearest_trigger", bestDecision
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:isEngaged(member) then
            return member, "engaged", nil
        end
    end

    return nil, nil, nil
end

function SkynetIADSSiblingCoordination:activateMember(family, member, reason, threatDecision)
    if self:isSuppressed(member) then
        return
    end
    if member.rotationMoveActive == true then
        self:finishRotation(family, member, "abort", "reactivated:" .. tostring(reason))
    end
    local switchedPrimary = family.activeGroupName ~= member.groupName or family.activeReason ~= reason
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "primary"
    local entry = self:getMobilePatrolEntry(member.element)
    local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
    local shouldForceDeploy = reason ~= nil and string.find(reason, "cover_for_", 1, true) == 1
    local coveredGroupName = shouldForceDeploy and string.sub(reason, string.len("cover_for_") + 1) or nil
    local coveredMember = coveredGroupName and self:findMemberByGroupName(family, coveredGroupName) or nil
    local coveredEntry = coveredMember and self:getMobilePatrolEntry(coveredMember.element) or nil
    local skipEngagedFastPath = false
    local liveDecision = nil
    if entry and entry.combatCommitted == true and entry.manager and entry.manager.findSAMThreatContact then
        liveDecision = entry.manager:findSAMThreatContact(entry)
        if liveDecision and liveDecision.shouldGoLive == true then
            skipEngagedFastPath = true
        end
    end
    if entry and entry.combatCommitted == true and shouldForceDeploy ~= true and reason == "engaged" and skipEngagedFastPath ~= true then
        if switchedPrimary then
            self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
            self:notifyDebug(family.name .. " primary -> " .. member.groupName .. " | reason=" .. tostring(reason))
        end
        family.activeGroupName = member.groupName
        family.activeReason = reason
        return
    end
    if entry and entry.manager and entry.manager.applyMSAMThreatDecision then
        if threatDecision == nil and liveDecision ~= nil then
            threatDecision = liveDecision
        end
        if threatDecision == nil and entry.manager.findSAMThreatContact then
            threatDecision = entry.manager:findSAMThreatContact(entry)
        end
        local inheritedTriggerInfo = coveredEntry and coveredEntry.lastDeployTrigger and mist.utils.deepCopy(coveredEntry.lastDeployTrigger) or nil
        if inheritedTriggerInfo == nil and family.lastThreatTriggerInfo ~= nil then
            inheritedTriggerInfo = mist.utils.deepCopy(family.lastThreatTriggerInfo)
        end
        local inheritedContact = coveredEntry and coveredEntry.lastThreatContact or family.lastThreatContact or nil
        if threatDecision ~= nil and threatDecision.contact == nil and inheritedContact ~= nil then
            if inheritedContact ~= nil and inheritedContact.isExist and inheritedContact:isExist() then
                threatDecision.contact = inheritedContact
                if coveredEntry and coveredEntry.manager and coveredEntry.manager.refreshThreatContact then
                    coveredEntry.manager:refreshThreatContact(inheritedContact)
                end
                if threatDecision.triggerInfo then
                    local inheritedTargetName = coveredEntry and coveredEntry.manager and coveredEntry.manager.getContactName and coveredEntry.manager:getContactName(inheritedContact) or nil
                    threatDecision.triggerInfo.source = "cover_inherited_contact"
                    threatDecision.triggerInfo.inheritedContactName = inheritedTargetName
                    threatDecision.triggerInfo.contactName = self:getSafeThreatName(family, inheritedTargetName, threatDecision.triggerInfo.contactName)
                end
            end
        end
        if threatDecision ~= nil and shouldForceDeploy == true and threatDecision.shouldGoLive ~= true then
            local preservedContact = threatDecision.contact
            threatDecision = mist.utils.deepCopy(threatDecision)
            threatDecision.contact = preservedContact
            threatDecision.shouldGoLive = true
            threatDecision.shouldWeaponHold = false
            threatDecision.combatMode = moveFireCapable and "sibling_cover_fire" or "sibling_cover"
            threatDecision.triggerInfo = threatDecision.triggerInfo or {}
            threatDecision.triggerInfo.source = "sibling_cover"
            threatDecision.triggerInfo.combatMode = threatDecision.combatMode
            threatDecision.skipPauseDeployment = moveFireCapable ~= true
        end
        if threatDecision == nil and shouldForceDeploy ~= true then
            if switchedPrimary then
                self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
                self:notifyDebug(family.name .. " primary -> " .. member.groupName .. " | reason=" .. tostring(reason))
            end
            family.activeGroupName = member.groupName
            family.activeReason = reason
            return
        end
        if threatDecision == nil then
            local preferredTargetName = self:getSafeThreatName(
                family,
                inheritedTriggerInfo and inheritedTriggerInfo.contactName or nil,
                entry.lastDeployTrigger and entry.lastDeployTrigger.contactName or nil,
                family.lastThreatTriggerInfo and family.lastThreatTriggerInfo.contactName or nil,
                "unknown"
            )
            local syntheticTriggerInfo = inheritedTriggerInfo or (entry.lastDeployTrigger and mist.utils.deepCopy(entry.lastDeployTrigger) or nil)
            if syntheticTriggerInfo == nil and entry.manager.findSAMThreatContact then
                local inferredThreatDecision = entry.manager:findSAMThreatContact(entry)
                if inferredThreatDecision and inferredThreatDecision.triggerInfo then
                    syntheticTriggerInfo = mist.utils.deepCopy(inferredThreatDecision.triggerInfo)
                end
            end
            threatDecision = {
                shouldDeploy = moveFireCapable ~= true,
                shouldGoLive = true,
                shouldWeaponHold = false,
                combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                triggerInfo = syntheticTriggerInfo or {
                    source = "sibling_coord",
                    contactName = preferredTargetName,
                    contactType = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                    time = timer.getTime(),
                    combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary",
                },
            }
            threatDecision.triggerInfo.source = threatDecision.triggerInfo.source or "sibling_coord"
            threatDecision.triggerInfo.contactName = self:getSafeThreatName(family, threatDecision.triggerInfo.contactName, preferredTargetName) or "unknown"
            threatDecision.triggerInfo.contactType = threatDecision.triggerInfo.contactType or (shouldForceDeploy and "sibling_cover" or "sibling_primary")
            threatDecision.triggerInfo.combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary"
            threatDecision.skipPauseDeployment = shouldForceDeploy and moveFireCapable ~= true or false
        end
        if threatDecision.triggerInfo then
            threatDecision.triggerInfo.contactName = self:getSafeThreatName(
                family,
                threatDecision.triggerInfo.contactName,
                inheritedTriggerInfo and inheritedTriggerInfo.contactName or nil,
                family.lastThreatTriggerInfo and family.lastThreatTriggerInfo.contactName or nil
            ) or threatDecision.triggerInfo.contactName
        end
        entry.manager:applyMSAMThreatDecision(entry, threatDecision, threatDecision.skipPauseDeployment == true)
        self:cacheFamilyThreat(family, member, threatDecision)
    else
        if shouldForceDeploy and moveFireCapable ~= true and entry and entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = self:getSafeThreatName(
                    family,
                    coveredEntry and coveredEntry.lastDeployTrigger and coveredEntry.lastDeployTrigger.contactName or nil,
                    family.lastThreatTriggerInfo and family.lastThreatTriggerInfo.contactName or nil,
                    "sibling_cover"
                ),
                contactType = "sibling_cover",
                distanceNm = 0,
                threatRangeNm = 0,
                time = timer.getTime(),
                combatMode = "sibling_cover",
            })
        end
        if member.element.targetsInRange ~= nil then
            member.element.targetsInRange = true
        end
        self:setOrderTraceContext(member.element, "sibling_activate", {
            source = "sibling_coord",
            family = family.name,
            familyMode = family.mode,
            familyRole = "primary",
            note = reason,
        }, "activateMember")
        member.element:goLive()
        setElementCombatROE(member.element, false)
    end
    if switchedPrimary then
        self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
        self:notifyDebug(family.name .. " primary -> " .. member.groupName .. " | reason=" .. tostring(reason))
    end
    if family.suppressedSwitchGroupName ~= nil and family.suppressedSwitchGroupName ~= member.groupName then
        self:clearSuppressedSwitchLock(family)
    end
    family.activeGroupName = member.groupName
    family.activeReason = reason
    if switchedPrimary then
        self:setPrimarySelectionLock(family, member)
    end
end

function SkynetIADSSiblingCoordination:setPassiveMember(family, member)
    local previousPassiveMode = member.passiveMode
    local entry = self:getMobilePatrolEntry(member.element)
    if self:isSuppressed(member) then
        member.lastRole = "suppressed"
        member.passiveMode = "suppressed"
        if previousPassiveMode ~= "suppressed" then
            self:notifyDebug(member.groupName .. " suppressed standby | family=" .. family.name)
        end
        return
    end
    local previousRole = member.lastRole
    member.forcedPassive = true
    member.lastRole = "passive"
    if member.rotationMoveActive == true and entry and entry.manager and entry.manager.beginPatrol then
        member.passiveMode = "relocate"
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousPassiveMode ~= "relocate" then
            self:notifyDebug(member.groupName .. " rotation relocating | family=" .. family.name)
        end
        return
    end
    if family.passiveAction == "relocate" and entry and entry.kind == "MSAM" then
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            member.passiveMode = "relocate"
            if entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " relocate standby | family=" .. family.name)
            end
            return
        end
        if previousRole == "primary" or previousRole == "suppressed" then
            member.passiveMode = "relocate"
            if entry.manager and entry.manager.beginPatrol and entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " relocate standby | family=" .. family.name)
            end
            return
        end
        member.passiveMode = "standby"
        if entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = self:getSafeThreatName(
                    family,
                    family.lastThreatTriggerInfo and family.lastThreatTriggerInfo.contactName or nil,
                    "sibling_standby"
                ),
                contactType = "sibling_standby",
                distanceNm = 0,
                threatRangeNm = 0,
                time = timer.getTime(),
                combatMode = "sibling_standby",
            })
        end
        forceElementIntoDarkStandby(member.element)
        if previousPassiveMode ~= "standby" then
            self:notifyDebug(member.groupName .. " deployed standby | family=" .. family.name)
        end
        return
    end
    if family.passiveAction == "relocate" and entry and entry.manager and entry.manager.beginPatrol then
        member.passiveMode = "relocate"
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousPassiveMode ~= "relocate" then
            self:notifyDebug(member.groupName .. " relocate standby | family=" .. family.name)
        end
        return
    end
    member.passiveMode = "hold_dark"
    if entry and entry.manager and entry.manager.issueHold then
        entry.manager:setOrderTraceContext(entry, "sibling_passive_hold", {
            source = "sibling_coord",
            family = family.name,
            familyMode = family.mode,
            familyRole = "passive",
        }, "setPassiveMember")
        entry.manager:issueHold(entry)
    end
    forceElementIntoDarkStandby(member.element)
    self:traceElementCommand(member.element, "sibling_dark_standby", {
        outcome = "issued",
        reason = "sibling_passive_hold",
        source = "sibling_coord",
        family = family.name,
        familyMode = family.mode,
        familyRole = "passive",
    }, "setPassiveMember")
    if previousPassiveMode ~= "hold_dark" then
        self:notifyDebug(member.groupName .. " dark standby | family=" .. family.name)
    end
end

function SkynetIADSSiblingCoordination:releaseMember(member)
    local previousRole = member.lastRole
    if previousRole == "released" and member.rotationMoveActive ~= true then
        return
    end
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "released"
    member.rotationMoveActive = false
    member.rotationMoveStartPoint = nil
    member.rotationStartedAt = nil
    member.rotationReason = nil
    member.deployedObservedSince = nil
    if self:isSuppressed(member) then
        return
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.manager and entry.manager.beginPatrol and entry.kind == "MSAM" then
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousRole ~= "released" then
            self:notifyDebug(member.groupName .. " sibling constraint released")
        end
        return
    end
    if member.element.setToCorrectAutonomousState then
        member.element:setToCorrectAutonomousState()
    else
        self:setOrderTraceContext(member.element, "sibling_release", {
            source = "sibling_coord",
        }, "releaseMember")
        member.element:goDark()
    end
    if previousRole ~= "released" then
        self:notifyDebug(member.groupName .. " sibling constraint released")
    end
end

function SkynetIADSSiblingCoordination:updateFamily(family)
    self:refreshFamilyRotation(family)
    local primary, reason, threatDecision = self:choosePrimaryMember(family)
    if primary then
        local now = timer.getTime()
        local switchLockActive = reason ~= nil and string.find(reason, "switch_lock_", 1, true) == 1
        if switchLockActive then
            family.activeGroupName = primary.groupName
            family.activeReason = reason
        end
        if switchLockActive ~= true and family.rotationActiveGroupName == nil and (family.rotationCooldownUntil or 0) <= now then
            if reason ~= nil and string.find(reason, "rotation_cover_for_", 1, true) == 1 then
                local rotatingGroupName = string.sub(reason, string.len("rotation_cover_for_") + 1)
                local rotatingMember = self:findMemberByGroupName(family, rotatingGroupName)
                if rotatingMember then
                    self:startRotation(family, rotatingMember, primary, reason)
                end
            else
                local standbyRotationMember = self:pickStandbyRotationCandidate(family, primary, now)
                if standbyRotationMember then
                    self:startRotation(family, standbyRotationMember, primary, "standby_rotate")
                end
            end
        end
        for i = 1, #family.members do
            local member = family.members[i]
            if switchLockActive ~= true and member == primary then
                if self:isSuppressed(member) then
                    self:setPassiveMember(family, member)
                else
                    self:activateMember(family, member, reason, threatDecision)
                end
            else
                self:setPassiveMember(family, member)
            end
        end
        return
    end

    local now = timer.getTime()
    local hasReleasedDeployedMembers = self:hasReleasedDeployedMembers(family)
    if family.rotationActiveGroupName ~= nil or hasReleasedDeployedMembers == true then
        if family.rotationActiveGroupName == nil and (family.rotationCooldownUntil or 0) <= now then
            local rotatingMember = self:pickDeployedRotationCandidate(family, nil, now)
            if rotatingMember ~= nil then
                local coverMember = self:pickCoverMember(family, rotatingMember.groupName)
                self:startRotation(family, rotatingMember, coverMember, "released_standby_rotate")
            end
        end
        self:clearSuppressedSwitchLock(family)
        self:clearPrimarySelectionLock(family)
        family.activeGroupName = nil
        family.activeReason = nil
        for i = 1, #family.members do
            self:setPassiveMember(family, family.members[i])
        end
        return
    end

    if family.activeGroupName ~= nil then
        self:log("Family released | family=" .. family.name)
    end
    local rotatingMember = self:findMemberByGroupName(family, family.rotationActiveGroupName)
    if rotatingMember ~= nil then
        self:finishRotation(family, rotatingMember, "abort", "family_released")
    else
        self:clearRotationState(family, nil)
    end
    self:clearSuppressedSwitchLock(family)
    self:clearPrimarySelectionLock(family)
    family.activeGroupName = nil
    family.activeReason = nil
    for i = 1, #family.members do
        self:releaseMember(family.members[i])
    end
end

function SkynetIADSSiblingCoordination:tick(time)
    local nextRunTime = timer.getTime() + self.checkInterval
    for i = 1, #self.families do
        local ok, err = pcall(function()
            self:updateFamily(self.families[i])
        end)
        if ok ~= true then
            self:log("tick error | familyIndex=" .. tostring(i) .. " | err=" .. tostring(err))
        end
    end
    return nextRunTime
end

function SkynetIADSSiblingCoordination._tick(params, time)
    local self = params and params.self or nil
    if self == nil then
        return nil
    end
    return self:tick(time)
end

function SkynetIADSSiblingCoordination:requestImmediateEvaluation(reason)
    if self._immediateEvaluationInProgress == true or #self.families == 0 then
        return
    end
    self._immediateEvaluationInProgress = true
    for i = 1, #self.families do
        local ok, err = pcall(function()
            self:updateFamily(self.families[i])
        end)
        if ok ~= true then
            self:log("immediate evaluation error | familyIndex=" .. tostring(i) .. " | err=" .. tostring(err))
        end
    end
    self._immediateEvaluationInProgress = false
    if reason then
        self:log("immediate evaluation | reason=" .. tostring(reason))
    end
end

function SkynetIADSSiblingCoordination:start()
    if self.taskID ~= nil or #self.families == 0 then
        return
    end
    self.taskID = mist.scheduleFunction(
        SkynetIADSSiblingCoordination._tick,
        { self = self },
        timer.getTime() + self.checkInterval,
        self.checkInterval
    )
    self:log("started | families=" .. tostring(#self.families) .. " | interval=" .. tostring(self.checkInterval) .. "s")
end

function SkynetIADSSiblingCoordination:registerFamily(definition)
    if definition == nil or definition.members == nil or #definition.members < 2 then
        return false, 0
    end
    local family = {
        name = definition.name or ("SiblingFamily-" .. tostring(#self.families + 1)),
        mode = definition.mode or self.defaultMode,
        passiveAction = definition.passiveAction or self.defaultPassiveAction,
        preferredPrimaryGroupName = definition.primary,
        denialAlertDistanceNm = definition.denialAlertDistanceNm or self.defaultDenialAlertDistanceNm,
        suppressedSwitchDelaySeconds = definition.suppressedSwitchDelaySeconds or self.defaultSuppressedSwitchDelaySeconds,
        primaryLatchSeconds = definition.primaryLatchSeconds or self.defaultPrimaryLatchSeconds,
        primaryDistanceHysteresisNm = definition.primaryDistanceHysteresisNm or self.defaultPrimaryDistanceHysteresisNm,
        rotationIntervalSeconds = definition.rotationIntervalSeconds or self.defaultRotationIntervalSeconds,
        rotationMinMoveMeters = definition.rotationMinMoveMeters or self.defaultRotationMinMoveMeters,
        rotationCooldownSeconds = definition.rotationCooldownSeconds or self.defaultRotationCooldownSeconds,
        members = {},
        activeGroupName = nil,
        activeReason = nil,
        lastThreatContact = nil,
        lastThreatTriggerInfo = nil,
        lastThreatSourceGroupName = nil,
        suppressedSwitchGroupName = nil,
        suppressedSwitchUntil = 0,
        primarySelectionGroupName = nil,
        primarySelectionUntil = 0,
        rotationActiveGroupName = nil,
        rotationCoverGroupName = nil,
        rotationStartedAt = nil,
        rotationCooldownUntil = 0,
    }

    for i = 1, #definition.members do
        local groupName = definition.members[i]
        local samSite = self.iads:getSAMSiteByGroupName(groupName)
        if samSite then
            local member = {
                groupName = groupName,
                element = samSite,
                mobileEntry = self:getMobilePatrolEntry(samSite),
                family = family,
                forcedPassive = false,
                lastRole = "released",
                deployedObservedSince = nil,
                rotationMoveActive = false,
                rotationMoveStartPoint = nil,
                rotationStartedAt = nil,
                rotationReason = nil,
            }
            family.members[#family.members + 1] = member
            SkynetIADSSiblingCoordination._familyByElement[samSite] = family
            SkynetIADSSiblingCoordination._memberByElement[samSite] = member
        else
            self:log("register skipped | family=" .. family.name .. " | missing group=" .. tostring(groupName))
        end
    end

    if #family.members < 2 then
        self:log("register ignored | family=" .. family.name .. " | not enough valid members")
        return false, #family.members
    end

    self.families[#self.families + 1] = family
    if family.preferredPrimaryGroupName == nil and #family.members > 0 then
        family.preferredPrimaryGroupName = family.members[1].groupName
    end

    self:log(
        "registered | family=" .. family.name
        .. " | mode=" .. tostring(family.mode)
        .. " | preferredPrimary=" .. tostring(family.preferredPrimaryGroupName)
        .. " | members=" .. tostring(#family.members)
        .. " | passiveAction=" .. tostring(family.passiveAction)
        .. " | primaryLatch=" .. tostring(family.primaryLatchSeconds) .. "s"
        .. " | primaryHysteresis=" .. tostring(family.primaryDistanceHysteresisNm) .. "nm"
        .. " | rotationInterval=" .. tostring(family.rotationIntervalSeconds) .. "s"
        .. " | rotationMinMove=" .. tostring(family.rotationMinMoveMeters) .. "m"
    )
    return true, #family.members
end

function SkynetIADSSiblingCoordination:registerFamilies(definitions)
    local registeredFamilies = 0
    local registeredMembers = 0
    if definitions == nil then
        return registeredFamilies, registeredMembers
    end
    for i = 1, #definitions do
        local ok, memberCount = self:registerFamily(definitions[i])
        if ok then
            registeredFamilies = registeredFamilies + 1
            registeredMembers = registeredMembers + memberCount
        end
    end
    return registeredFamilies, registeredMembers
end

function SkynetIADSSiblingCoordination.create(iads, config)
    local self = {}
    setmetatable(self, SkynetIADSSiblingCoordination)
    self.iads = iads
    self.checkInterval = (config and config.checkInterval) or SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL
    self.defaultPassiveAction = (config and config.defaultPassiveAction) or SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION
    self.defaultMode = (config and config.defaultMode) or SkynetIADSSiblingCoordination.DEFAULT_MODE
    self.defaultDenialAlertDistanceNm = (config and config.defaultDenialAlertDistanceNm) or SkynetIADSSiblingCoordination.DEFAULT_DENIAL_ALERT_DISTANCE_NM
    self.defaultSuppressedSwitchDelaySeconds = (config and config.defaultSuppressedSwitchDelaySeconds) or SkynetIADSSiblingCoordination.DEFAULT_SUPPRESSED_SWITCH_DELAY_SECONDS
    self.defaultPrimaryLatchSeconds = (config and config.defaultPrimaryLatchSeconds) or SkynetIADSSiblingCoordination.DEFAULT_PRIMARY_LATCH_SECONDS
    self.defaultPrimaryDistanceHysteresisNm = (config and config.defaultPrimaryDistanceHysteresisNm) or SkynetIADSSiblingCoordination.DEFAULT_PRIMARY_DISTANCE_HYSTERESIS_NM
    self.defaultRotationIntervalSeconds = (config and config.defaultRotationIntervalSeconds) or SkynetIADSSiblingCoordination.DEFAULT_ROTATION_INTERVAL_SECONDS
    self.defaultRotationMinMoveMeters = (config and config.defaultRotationMinMoveMeters) or SkynetIADSSiblingCoordination.DEFAULT_ROTATION_MIN_MOVE_METERS
    self.defaultRotationCooldownSeconds = (config and config.defaultRotationCooldownSeconds) or SkynetIADSSiblingCoordination.DEFAULT_ROTATION_COOLDOWN_SECONDS
    self.families = {}
    self.taskID = nil
    self._immediateEvaluationInProgress = false
    return self
end

trigger.action.outText("Skynet Sibling Coordination module loaded", 10)

end
