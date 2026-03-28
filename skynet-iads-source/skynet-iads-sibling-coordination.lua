do

SkynetIADSSiblingCoordination = {}
SkynetIADSSiblingCoordination.__index = SkynetIADSSiblingCoordination

SkynetIADSSiblingCoordination._familyByElement = setmetatable({}, { __mode = "k" })
SkynetIADSSiblingCoordination._memberByElement = setmetatable({}, { __mode = "k" })

SkynetIADSSiblingCoordination.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSSiblingCoordination.DEFAULT_PASSIVE_ACTION = "hold_dark"

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
        role = member.lastRole or "released",
        primaryGroupName = family.activeGroupName,
        reason = family.activeReason,
        passiveAction = family.passiveAction,
    }
end

function SkynetIADSSiblingCoordination:log(message)
    if self.iads and self.iads.printOutputToLog then
        self.iads:printOutputToLog("[SiblingCoord] " .. message)
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
    if member.forcedPassive == true then
        return element:isActive() or element.targetsInRange == true or element:getNumberOfMissilesInFlight() > 0
    end
    if element:isActive() or element.targetsInRange == true or element:getNumberOfMissilesInFlight() > 0 then
        return true
    end
    local entry = self:getMobilePatrolEntry(element)
    return entry ~= nil and entry.state == "deployed"
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

function SkynetIADSSiblingCoordination:choosePrimaryMember(family)
    local currentPrimary = self:findMemberByGroupName(family, family.activeGroupName)
    if currentPrimary and self:isSuppressed(currentPrimary) == false and self:isEngaged(currentPrimary) then
        return currentPrimary, "engaged"
    end

    if currentPrimary and self:isSuppressed(currentPrimary) then
        local coverMember = self:pickCoverMember(family, currentPrimary.groupName)
        if coverMember then
            return coverMember, "cover_for_" .. currentPrimary.groupName
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) == false and self:isEngaged(member) then
            return member, "engaged"
        end
    end

    for i = 1, #family.members do
        local member = family.members[i]
        if self:isSuppressed(member) then
            local coverMember = self:pickCoverMember(family, member.groupName)
            if coverMember then
                return coverMember, "cover_for_" .. member.groupName
            end
        end
    end

    return nil, nil
end

function SkynetIADSSiblingCoordination:activateMember(family, member, reason)
    if self:isSuppressed(member) then
        return
    end
    member.forcedPassive = false
    member.lastRole = "primary"
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.state == "patrolling" and entry.manager and entry.manager.pausePatrolForDeployment then
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
    if family.activeGroupName ~= member.groupName or family.activeReason ~= reason then
        self:log("Primary active | family=" .. family.name .. " | group=" .. member.groupName .. " | reason=" .. tostring(reason))
    end
    family.activeGroupName = member.groupName
    family.activeReason = reason
end

function SkynetIADSSiblingCoordination:setPassiveMember(family, member)
    if self:isSuppressed(member) then
        member.lastRole = "suppressed"
        return
    end
    member.forcedPassive = true
    member.lastRole = "passive"
    local entry = self:getMobilePatrolEntry(member.element)
    if family.passiveAction == "relocate" and entry and entry.manager and entry.manager.beginPatrol then
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        return
    end
    if entry and entry.manager and entry.manager.issueHold then
        entry.manager:issueHold(entry)
    end
    forceElementIntoDarkStandby(member.element)
end

function SkynetIADSSiblingCoordination:releaseMember(member)
    member.forcedPassive = false
    member.lastRole = "released"
    if self:isSuppressed(member) then
        return
    end
    local entry = self:getMobilePatrolEntry(member.element)
    if entry and entry.manager and entry.manager.beginPatrol and entry.kind == "MSAM" then
        if entry.state ~= "patrolling" then
            entry.manager:beginPatrol(entry)
        end
        return
    end
    if member.element.setToCorrectAutonomousState then
        member.element:setToCorrectAutonomousState()
    else
        member.element:goDark()
    end
end

function SkynetIADSSiblingCoordination:updateFamily(family)
    local primary, reason = self:choosePrimaryMember(family)
    if primary then
        for i = 1, #family.members do
            local member = family.members[i]
            if member == primary then
                self:activateMember(family, member, reason)
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
        passiveAction = definition.passiveAction or self.defaultPassiveAction,
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
    self:log("registered | family=" .. family.name .. " | members=" .. tostring(#family.members) .. " | passiveAction=" .. tostring(family.passiveAction))
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
    self.families = {}
    self.taskID = nil
    return self
end

trigger.action.outText("Skynet Sibling Coordination module loaded", 10)

end
