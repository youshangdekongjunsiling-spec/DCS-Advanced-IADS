do

SkynetIADSSiblingCoordination = {}
SkynetIADSSiblingCoordination.__index = SkynetIADSSiblingCoordination

SkynetIADSSiblingCoordination._familyByElement = setmetatable({}, { __mode = "k" })
SkynetIADSSiblingCoordination._memberByElement = setmetatable({}, { __mode = "k" })

SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION = "hold_dark"
SkynetIADSSiblingCoordination.DEFAULT_MODE = "ambush"
SkynetIADSSiblingCoordination.DEFAULT_DENIAL_ALERT_DISTANCE_NM = 25

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

function SkynetIADSSiblingCoordination:getMobilePatrolEntry(element)
    if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
        return SkynetIADSMobilePatrol.getEntryForElement(element)
    end
    return nil
end

function SkynetIADSSiblingCoordination:isSuppressed(member)
    local element = member.element
    return element.harmSilenceID ~= nil or element.harmRelocationInProgress == true
end

function SkynetIADSSiblingCoordination:isEngaged(member)
    local element = member.element
    local entry = self:getMobilePatrolEntry(element)
    if entry ~= nil then
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            return (
                (entry.combatMode ~= nil and entry.combatMode ~= "patrolling" and entry.combatMode ~= "searching")
                or element.targetsInRange == true
                or element:getNumberOfMissilesInFlight() > 0
            )
        end
        return (
            entry.combatCommitted == true
            or element.targetsInRange == true
            or element:isActive()
            or element:getNumberOfMissilesInFlight() > 0
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
    for i = 1, #family.members do
        local member = family.members[i]
        if member.groupName ~= excludedGroupName and self:isSuppressed(member) == false and self:canCover(member) then
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

function SkynetIADSSiblingCoordination:getBestAmbushThreatCandidate(family)
    local bestMember = nil
    local bestDecision = nil
    local bestShouldGoLive = -1
    local bestDistanceNm = math.huge
    local bestPreferred = -1
    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:canCover(member) then
            local entry = self:getMobilePatrolEntry(member.element)
            if entry and entry.kind == "MSAM" and entry.manager and entry.manager.findSAMThreatContact then
                local threatDecision = entry.manager:findSAMThreatContact(entry)
                if threatDecision then
                    local triggerInfo = threatDecision.triggerInfo or {}
                    local shouldGoLiveScore = threatDecision.shouldGoLive == true and 1 or 0
                    local distanceNm = tonumber(triggerInfo.distanceNm) or math.huge
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
    end
    return bestMember, bestDecision
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

    if family.mode == "denial" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary ~= member or self:isSuppressed(preferredPrimary) or self:canCover(preferredPrimary) == false then
            return nil, false
        end
        return self:getDenialThreatDecision(family, preferredPrimary), true
    end

    if family.mode == "ambush" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local preferredEntry = self:getMobilePatrolEntry(preferredPrimary.element)
            if preferredEntry and preferredEntry.kind == "MSAM" and preferredEntry.manager and preferredEntry.manager.findSAMThreatContact then
                local preferredDecision = preferredEntry.manager:findSAMThreatContact(preferredEntry)
                if preferredDecision then
                    if preferredPrimary ~= member then
                        return nil, false
                    end
                    return preferredDecision, true
                end
            end
        end
    end

    local bestMember, bestDecision = self:getBestAmbushThreatCandidate(family)
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
    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        return currentPrimary, "engaged", nil
    end

    if currentPrimary and self:isSuppressed(currentPrimary) then
        local coverMember = self:pickCoverMember(family, currentPrimary.groupName)
        if coverMember then
            return coverMember, "cover_for_" .. currentPrimary.groupName, nil
        end
    end

    if family.mode == "denial" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local denialThreatDecision = self:getDenialThreatDecision(family, preferredPrimary)
            if denialThreatDecision then
                return preferredPrimary, "denial_trigger", denialThreatDecision
            end
        end
        if preferredPrimary and self:isSuppressed(preferredPrimary) then
            local coverMember = self:pickCoverMember(family, preferredPrimary.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. preferredPrimary.groupName, nil
            end
        end
    end

    if family.mode == "ambush" then
        local preferredPrimary = self:getPreferredPrimaryMember(family)
        if preferredPrimary and self:isSuppressed(preferredPrimary) == false and self:canCover(preferredPrimary) then
            local preferredEntry = self:getMobilePatrolEntry(preferredPrimary.element)
            if preferredEntry and preferredEntry.kind == "MSAM" and preferredEntry.manager and preferredEntry.manager.findSAMThreatContact then
                local preferredDecision = preferredEntry.manager:findSAMThreatContact(preferredEntry)
                if preferredDecision then
                    return preferredPrimary, "preferred_trigger", preferredDecision
                end
            end
        end
        if preferredPrimary and self:isSuppressed(preferredPrimary) then
            local coverMember = self:pickCoverMember(family, preferredPrimary.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. preferredPrimary.groupName, nil
            end
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:isEngaged(member) then
            return member, "engaged", nil
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) then
            local coverMember = self:pickCoverMember(family, member.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. member.groupName, nil
            end
        end
    end

    return nil, nil, nil
end

function SkynetIADSSiblingCoordination:activateMember(family, member, reason, threatDecision)
    if self:isSuppressed(member) then
        return
    end
    local switchedPrimary = family.activeGroupName ~= member.groupName or family.activeReason ~= reason
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "primary"
    local entry = self:getMobilePatrolEntry(member.element)
    local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
    local shouldForceDeploy = reason ~= nil and string.find(reason, "cover_for_", 1, true) == 1
    if entry and entry.combatCommitted == true and shouldForceDeploy ~= true and reason == "engaged" then
        if switchedPrimary then
            self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
            self:notifyDebug(family.name .. " 主战切换 -> " .. member.groupName .. " | reason=" .. tostring(reason))
        end
        family.activeGroupName = member.groupName
        family.activeReason = reason
        return
    end
    if entry and entry.manager and entry.manager.applyMSAMThreatDecision then
        if threatDecision == nil and entry.manager.findSAMThreatContact then
            threatDecision = entry.manager:findSAMThreatContact(entry)
        end
        if threatDecision == nil and shouldForceDeploy ~= true then
            if switchedPrimary then
                self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
                self:notifyDebug(family.name .. " 涓绘垬鍒囨崲 -> " .. member.groupName .. " | reason=" .. tostring(reason))
            end
            family.activeGroupName = member.groupName
            family.activeReason = reason
            return
        end
        if threatDecision == nil then
            local preferredTargetName = family.activeGroupName or family.name
            if entry.lastDeployTrigger and entry.lastDeployTrigger.contactName then
                preferredTargetName = entry.lastDeployTrigger.contactName
            end
            local syntheticTriggerInfo = entry.lastDeployTrigger and mist.utils.deepCopy(entry.lastDeployTrigger) or nil
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
            threatDecision.triggerInfo.contactName = threatDecision.triggerInfo.contactName or preferredTargetName
            threatDecision.triggerInfo.contactType = threatDecision.triggerInfo.contactType or (shouldForceDeploy and "sibling_cover" or "sibling_primary")
            threatDecision.triggerInfo.combatMode = shouldForceDeploy and "sibling_cover" or "sibling_primary"
        end
        entry.manager:applyMSAMThreatDecision(entry, threatDecision)
    else
        if shouldForceDeploy and moveFireCapable ~= true and entry and entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = family.activeGroupName or "sibling",
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
        member.element:goLive()
        setElementCombatROE(member.element, false)
    end
    if switchedPrimary then
        self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
        self:notifyDebug(family.name .. " 主战切换 -> " .. member.groupName .. " | reason=" .. tostring(reason))
    end
    family.activeGroupName = member.groupName
    family.activeReason = reason
end

function SkynetIADSSiblingCoordination:setPassiveMember(family, member)
    local previousPassiveMode = member.passiveMode
    if self:isSuppressed(member) then
        member.lastRole = "suppressed"
        member.passiveMode = "suppressed"
        if previousPassiveMode ~= "suppressed" then
            self:notifyDebug(member.groupName .. " 受压制待机 | family=" .. family.name)
        end
        return
    end
    local previousRole = member.lastRole
    member.forcedPassive = true
    member.lastRole = "passive"
    local entry = self:getMobilePatrolEntry(member.element)
    if family.passiveAction == "relocate" and entry and entry.kind == "MSAM" then
        if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
            member.passiveMode = "relocate"
            if entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
            end
            return
        end
        if previousRole == "primary" or previousRole == "suppressed" then
            member.passiveMode = "relocate"
            if entry.manager and entry.manager.beginPatrol and entry.state ~= "patrolling" then
                entry.manager:beginPatrol(entry)
            end
            if previousPassiveMode ~= "relocate" then
                self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
            end
            return
        end
        member.passiveMode = "standby"
        if entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
            entry.manager:pausePatrolForDeployment(entry, {
                source = "sibling_coord",
                contactName = family.activeGroupName or "sibling",
                contactType = "sibling_standby",
                distanceNm = 0,
                threatRangeNm = 0,
                time = timer.getTime(),
                combatMode = "sibling_standby",
            })
        end
        forceElementIntoDarkStandby(member.element)
        if previousPassiveMode ~= "standby" then
            self:notifyDebug(member.groupName .. " 部署待机 | family=" .. family.name)
        end
        return
    end
    if family.passiveAction == "relocate" and entry and entry.manager and entry.manager.beginPatrol then
        member.passiveMode = "relocate"
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousPassiveMode ~= "relocate" then
            self:notifyDebug(member.groupName .. " 转移待机 | family=" .. family.name)
        end
        return
    end
    member.passiveMode = "hold_dark"
    if entry and entry.manager and entry.manager.issueHold then
        entry.manager:issueHold(entry)
    end
    forceElementIntoDarkStandby(member.element)
    if previousPassiveMode ~= "hold_dark" then
        self:notifyDebug(member.groupName .. " 黑灯待命 | family=" .. family.name)
    end
end

function SkynetIADSSiblingCoordination:releaseMember(member)
    local previousRole = member.lastRole
    member.forcedPassive = false
    member.passiveMode = nil
    member.lastRole = "released"
    if self:isSuppressed(member) then
        return
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.manager and entry.manager.beginPatrol and entry.kind == "MSAM" then
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        if previousRole ~= "released" then
            self:notifyDebug(member.groupName .. " 解除兄弟约束")
        end
        return
    end
    if member.element.setToCorrectAutonomousState then
        member.element:setToCorrectAutonomousState()
    else
        member.element:goDark()
    end
    if previousRole ~= "released" then
        self:notifyDebug(member.groupName .. " 解除兄弟约束")
    end
end

function SkynetIADSSiblingCoordination:updateFamily(family)
    local primary, reason, threatDecision = self:choosePrimaryMember(family)
    if primary then
        for i = 1, #family.members do
            local member = family.members[i]
            if member == primary then
                self:activateMember(family, member, reason, threatDecision)
            else
                self:setPassiveMember(family, member)
            end
        end
        return
    end

    if family.activeGroupName ~= nil then
        self:log("Family released | family=" .. family.name)
    end
    family.activeGroupName = nil
    family.activeReason = nil
    for i = 1, #family.members do
        self:releaseMember(family.members[i])
    end
end

function SkynetIADSSiblingCoordination:tick(_, time)
    for i = 1, #self.families do
        self:updateFamily(self.families[i])
    end
    return time + self.checkInterval
end

function SkynetIADSSiblingCoordination:requestImmediateEvaluation(reason)
    if self._immediateEvaluationInProgress == true or #self.families == 0 then
        return
    end
    self._immediateEvaluationInProgress = true
    for i = 1, #self.families do
        self:updateFamily(self.families[i])
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
        SkynetIADSSiblingCoordination.tick,
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
        members = {},
        activeGroupName = nil,
        activeReason = nil,
    }

    for i = 1, #definition.members do
        local groupName = definition.members[i]
        local samSite = self.iads:getSAMSiteByGroupName(groupName)
        if samSite then
            local member = {
                groupName = groupName,
                element = samSite,
                family = family,
                forcedPassive = false,
                lastRole = "released",
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
    self.families = {}
    self.taskID = nil
    self._immediateEvaluationInProgress = false
    return self
end

trigger.action.outText("Skynet Sibling Coordination module loaded", 10)

end
