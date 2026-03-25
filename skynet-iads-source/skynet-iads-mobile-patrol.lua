do

SkynetIADSMobilePatrol = {}
SkynetIADSMobilePatrol.__index = SkynetIADSMobilePatrol

SkynetIADSMobilePatrol._hooksInstalled = false
SkynetIADSMobilePatrol._entriesByElement = setmetatable({}, { __mode = "k" })

SkynetIADSMobilePatrol.DEFAULT_CHECK_INTERVAL = 5
SkynetIADSMobilePatrol.DEFAULT_PATROL_SPEED_KMPH = 35
SkynetIADSMobilePatrol.DEFAULT_RESUME_DELAY_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_RESUME_MULTIPLIER = 2
SkynetIADSMobilePatrol.DEFAULT_MSAM_RESUME_MULTIPLIER = 1.2
SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS = 60

local function startsWith(value, prefix)
	return value and prefix and string.find(value, prefix, 1, true) == 1
end

local getGroupNameFromElement

local function groupHasUnitWithPrefix(group, prefix)
	if group == nil or group:isExist() == false then
		return false
	end
	local okUnits, units = pcall(function()
		return group:getUnits()
	end)
	if okUnits and units then
		for i = 1, #units do
			local unit = units[i]
			if unit and unit:isExist() and startsWith(unit:getName(), prefix) then
				return true
			end
		end
	end
	return false
end

local function samSiteMatchesPrefix(samSite, prefix)
	if startsWith(samSite:getDCSName(), prefix) then
		return true
	end
	local group = samSite:getDCSRepresentation()
	return groupHasUnitWithPrefix(group, prefix)
end

local function ewRadarMatchesPrefix(ewRadar, prefix)
	if startsWith(ewRadar:getDCSName(), prefix) then
		return true
	end
	local groupName = getGroupNameFromElement(ewRadar)
	if groupName == nil then
		return false
	end
	local group = Group.getByName(groupName)
	return groupHasUnitWithPrefix(group, prefix)
end

local function normalizeVec3(point)
	if point == nil or point.x == nil then
		return nil
	end
	local z = point.z or point.y
	if z == nil then
		return nil
	end
	local y = point.z and point.y or land.getHeight({ x = point.x, y = z })
	return {
		x = point.x,
		y = y or 0,
		z = z,
	}
end

local function appendNormalizedRoutePoints(routePoints, rawPoints)
	if rawPoints == nil then
		return
	end
	for i = 1, #rawPoints do
		local rawPoint = rawPoints[i]
		if rawPoint and rawPoint.point then
			rawPoint = rawPoint.point
		end
		local point = normalizeVec3(rawPoint)
		if point then
			routePoints[#routePoints + 1] = point
		end
	end
end

getGroupNameFromElement = function(element)
	local dcsRepresentation = element:getDCSRepresentation()
	if dcsRepresentation == nil or dcsRepresentation:isExist() == false then
		return nil
	end
	local okUnits, units = pcall(function()
		return dcsRepresentation:getUnits()
	end)
	if okUnits and units and #units > 0 then
		return dcsRepresentation:getName()
	end
	local okGroup, group = pcall(function()
		return dcsRepresentation:getGroup()
	end)
	if okGroup and group and group:isExist() then
		return group:getName()
	end
	return nil
end

local function getRoutePointsFromMissionGroup(groupName)
	local routePoints = {}
	local groupData = mist.DBs.groupsByName[groupName]
	if groupData and groupData.route and groupData.route.points then
		appendNormalizedRoutePoints(routePoints, groupData.route.points)
	end
	if #routePoints == 0 then
		local okRoute, route = pcall(function()
			return mist.getGroupRoute(groupName, true)
		end)
		if okRoute and route then
			appendNormalizedRoutePoints(routePoints, route)
		end
	end
	if #routePoints == 0 then
		local okPoints, points = pcall(function()
			return mist.getGroupPoints(groupName)
		end)
		if okPoints and points then
			appendNormalizedRoutePoints(routePoints, points)
		end
	end
	return routePoints
end

local function getLeadPointForGroup(group)
	local okPoint, point = pcall(function()
		return mist.getLeadPos(group)
	end)
	if okPoint then
		return point
	end
	return nil
end

local function getEnemyCoalition(coalitionId)
	if coalitionId == coalition.side.RED then
		return coalition.side.BLUE
	end
	if coalitionId == coalition.side.BLUE then
		return coalition.side.RED
	end
	return nil
end

local function collectEnemyAirUnits(enemyCoalitionId)
	local airUnits = {}
	if enemyCoalitionId == nil then
		return airUnits
	end
	local categories = {
		Group.Category.AIRPLANE,
		Group.Category.HELICOPTER,
	}
	for i = 1, #categories do
		local okGroups, groups = pcall(function()
			return coalition.getGroups(enemyCoalitionId, categories[i])
		end)
		if okGroups and groups then
			for j = 1, #groups do
				local group = groups[j]
				if group and group:isExist() then
					local units = group:getUnits()
					for k = 1, #units do
						local unit = units[k]
						if unit and unit:isExist() then
							airUnits[#airUnits + 1] = unit
						end
					end
				end
			end
		end
	end
	return airUnits
end

local function setPatrolAlarmState(controller)
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
	end)
end

local function forceElementIntoPatrolDarkState(element)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local dcsRepresentation = element:getDCSRepresentation()
	if dcsRepresentation and dcsRepresentation.isExist and dcsRepresentation:isExist() then
		pcall(function()
			dcsRepresentation:enableEmission(false)
		end)
	end
	local controller = element:getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setPatrolAlarmState(controller)
	end
	element.aiState = false
	element.cachedTargets = {}
	if element.stopScanningForHARMs then
		element:stopScanningForHARMs()
	end
end

function SkynetIADSMobilePatrol.getEntryForElement(element)
	return SkynetIADSMobilePatrol._entriesByElement[element]
end

function SkynetIADSMobilePatrol:log(message)
	if self.iads then
		self.iads:printOutputToLog("[MobilePatrol] " .. message)
	end
end

function SkynetIADSMobilePatrol:registerEntryForElement(element, entry)
	self.entries[#self.entries + 1] = entry
	SkynetIADSMobilePatrol._entriesByElement[element] = entry
end

function SkynetIADSMobilePatrol:getPatrolReferencePoint(entry)
	local group = entry.group
	if group and group:isExist() then
		local point = getLeadPointForGroup(group)
		if point then
			return point
		end
	end
	local dcsRepresentation = entry.element:getDCSRepresentation()
	if dcsRepresentation and dcsRepresentation:isExist() then
		return dcsRepresentation:getPosition().p
	end
	return nil
end

function SkynetIADSMobilePatrol:getWaypointDistance(entry, point)
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil or point == nil then
		return math.huge
	end
	return mist.utils.get2DDist(currentPoint, point)
end

function SkynetIADSMobilePatrol:selectStartingWaypointIndex(entry)
	if #entry.routePoints <= 1 then
		return 1
	end
	for i = 1, #entry.routePoints do
		if self:getWaypointDistance(entry, entry.routePoints[i]) > entry.arrivalToleranceMeters then
			return i
		end
	end
	return 1
end

function SkynetIADSMobilePatrol:issueRoadMove(entry, destination)
	if entry.group == nil or entry.group:isExist() == false or destination == nil then
		return false
	end
	local ok = pcall(function()
		mist.groupToPoint(entry.group, destination, "On Road", nil, entry.patrolSpeedKmph, false)
	end)
	if ok then
		entry.currentDestination = destination
		entry.lastRouteIssueTime = timer.getTime()
	end
	return ok
end

function SkynetIADSMobilePatrol:issueHold(entry)
	local holdPoint = self:getPatrolReferencePoint(entry)
	if entry.group == nil or entry.group:isExist() == false or holdPoint == nil then
		return false
	end
	local ok = pcall(function()
		mist.goRoute(entry.group, {
			mist.ground.buildWP(holdPoint, "off_road", 0.1),
		})
	end)
	if ok then
		entry.currentDestination = nil
	end
	return ok
end

function SkynetIADSMobilePatrol:getThreatRangeMeters(entry)
	local element = entry.element
	local maxRange = 0
	if entry.kind == "MSAM" then
		local launchers = element:getLaunchers()
		for i = 1, #launchers do
			local launcher = launchers[i]
			if launcher:isExist() and launcher.getRange then
				maxRange = math.max(maxRange, launcher:getRange())
			end
		end
		if maxRange > 0 then
			return maxRange * (element:getGoLiveRangeInPercent() / 100)
		end
	end
	local searchRadars = element.getSearchRadars and element:getSearchRadars() or {}
	for i = 1, #searchRadars do
		local radar = searchRadars[i]
		if radar:isExist() and radar.getMaxRangeFindingTarget then
			maxRange = math.max(maxRange, radar:getMaxRangeFindingTarget())
		end
	end
	return maxRange
end

function SkynetIADSMobilePatrol:hasAircraftWithinRange(entry, distanceMeters)
	local center = self:getPatrolReferencePoint(entry)
	if center == nil or distanceMeters <= 0 then
		return false
	end
	local enemyAircraft = collectEnemyAirUnits(self.enemyCoalitionId)
	for i = 1, #enemyAircraft do
		local unit = enemyAircraft[i]
		local unitPoint = unit:getPoint()
		if unitPoint and mist.utils.get2DDist(center, unitPoint) <= distanceMeters then
			return true
		end
	end
	return false
end

function SkynetIADSMobilePatrol:findSAMThreatContact(entry)
	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact)
			and entry.element:isTargetInRange(contact) then
			return contact
		end
	end
	return nil
end

function SkynetIADSMobilePatrol:findMEWThreat(entry)
	local searchRange = self:getThreatRangeMeters(entry)
	if searchRange <= 0 then
		return false
	end
	return self:hasAircraftWithinRange(entry, searchRange)
end

function SkynetIADSMobilePatrol:isHarmEvading(entry)
	return entry.element.harmSilenceID ~= nil or entry.element.harmRelocationInProgress == true
end

function SkynetIADSMobilePatrol:pausePatrolForDeployment(entry)
	self:issueHold(entry)
	entry.state = "deployed"
	entry.noThreatSince = nil
	entry.lastThreatTime = timer.getTime()
end

function SkynetIADSMobilePatrol:beginPatrol(entry)
	entry.state = "patrolling"
	entry.noThreatSince = nil
	entry.lastThreatTime = 0
	forceElementIntoPatrolDarkState(entry.element)
	if entry.currentWaypointIndex == nil or entry.currentWaypointIndex < 1 then
		entry.currentWaypointIndex = self:selectStartingWaypointIndex(entry)
	end
	entry.currentDestination = nil
	self:advancePatrol(entry, true)
end

function SkynetIADSMobilePatrol:advancePatrol(entry, force)
	if entry.state ~= "patrolling" then
		return
	end
	if entry.group == nil or entry.group:isExist() == false or #entry.routePoints == 0 then
		return
	end
	local nextPoint = entry.routePoints[entry.currentWaypointIndex]
	if nextPoint == nil then
		entry.currentWaypointIndex = 1
		nextPoint = entry.routePoints[1]
	end
	if force ~= true and entry.currentDestination and self:getWaypointDistance(entry, entry.currentDestination) > entry.arrivalToleranceMeters then
		return
	end
	if self:getWaypointDistance(entry, nextPoint) <= entry.arrivalToleranceMeters then
		entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
		nextPoint = entry.routePoints[entry.currentWaypointIndex]
	end
	if nextPoint then
		if self:issueRoadMove(entry, nextPoint) then
			entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
		end
	end
end

function SkynetIADSMobilePatrol:handleDeployedState(entry)
	local resumeRange = self:getThreatRangeMeters(entry) * entry.resumeMultiplier
	if self:hasAircraftWithinRange(entry, resumeRange) then
		entry.noThreatSince = nil
		entry.lastThreatTime = timer.getTime()
		return
	end
	if entry.noThreatSince == nil then
		entry.noThreatSince = timer.getTime()
		return
	end
	if (timer.getTime() - entry.noThreatSince) >= entry.resumeDelaySeconds then
		self:beginPatrol(entry)
	end
end

function SkynetIADSMobilePatrol:updateEntry(entry)
	if entry.element:isDestroyed() or entry.group == nil or entry.group:isExist() == false then
		return
	end

	if self:isHarmEvading(entry) then
		entry.state = "harm_evading"
		entry.noThreatSince = nil
		return
	end

	local threatPresent = false
	if entry.kind == "MSAM" then
		threatPresent = self:findSAMThreatContact(entry) ~= nil
	else
		threatPresent = self:findMEWThreat(entry)
		if threatPresent and entry.state ~= "deployed" then
			self:pausePatrolForDeployment(entry)
			entry.element:goLive()
		end
	end

	if threatPresent and entry.kind == "MSAM" and entry.state ~= "deployed" then
		self:pausePatrolForDeployment(entry)
	end

	if threatPresent then
		entry.state = "deployed"
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		return
	end

	if entry.state == "harm_evading" then
		entry.state = "deployed"
	end

	if entry.state == "deployed" then
		self:handleDeployedState(entry)
		return
	end

	if entry.state ~= "patrolling" then
		self:beginPatrol(entry)
		return
	end

	self:advancePatrol(entry, false)
end

function SkynetIADSMobilePatrol:tick(_, time)
	for i = 1, #self.entries do
		self:updateEntry(self.entries[i])
	end
	return time + self.checkInterval
end

function SkynetIADSMobilePatrol:start()
	if self.taskId then
		return self
	end
	self.taskId = timer.scheduleFunction(function(_, time)
		return self:tick(_, time)
	end, {}, timer.getTime() + self.checkInterval)
	return self
end

function SkynetIADSMobilePatrol:registerElement(kind, element, options)
	local groupName = getGroupNameFromElement(element)
	if groupName == nil then
		self:log("Unable to register " .. kind .. " without group: " .. tostring(element:getDCSName()))
		trigger.action.outText("Mobile Patrol: unable to register " .. tostring(element:getDCSName()) .. " | no group", 10)
		return nil
	end

	local routePoints = getRoutePointsFromMissionGroup(groupName)
	if #routePoints == 0 then
		self:log("Skipping " .. element:getDCSName() .. " because no readable mission route points were found")
		trigger.action.outText("Mobile Patrol: skipping " .. element:getDCSName() .. " | no readable mission route points", 10)
		return nil
	end

	local group = Group.getByName(groupName)
	if group == nil or group:isExist() == false then
		self:log("Skipping " .. element:getDCSName() .. " because group does not exist: " .. groupName)
		trigger.action.outText("Mobile Patrol: skipping " .. element:getDCSName() .. " | group missing", 10)
		return nil
	end

	local resumeMultiplier = (options and options.resumeMultiplier)
	if resumeMultiplier == nil then
		if kind == "MSAM" then
			resumeMultiplier = self.defaultMSAMResumeMultiplier
		else
			resumeMultiplier = self.defaultResumeMultiplier
		end
	end

	local entry = {
		kind = kind,
		element = element,
		group = group,
		groupName = groupName,
		routePoints = routePoints,
		currentWaypointIndex = 1,
		currentDestination = nil,
		patrolSpeedKmph = (options and options.patrolSpeedKmph) or self.defaultPatrolSpeedKmph,
		resumeDelaySeconds = (options and options.resumeDelaySeconds) or self.defaultResumeDelaySeconds,
		resumeMultiplier = resumeMultiplier,
		arrivalToleranceMeters = (options and options.arrivalToleranceMeters) or self.defaultArrivalToleranceMeters,
		state = "patrolling",
		lastThreatTime = 0,
		noThreatSince = nil,
		manager = self,
	}
	entry.currentWaypointIndex = self:selectStartingWaypointIndex(entry)
	self:registerEntryForElement(element, entry)
	self:beginPatrol(entry)
	return entry
end

function SkynetIADSMobilePatrol:registerSAMSite(samSite, options)
	return self:registerElement("MSAM", samSite, options)
end

function SkynetIADSMobilePatrol:registerEWRadar(ewRadar, options)
	return self:registerElement("MEW", ewRadar, options)
end

function SkynetIADSMobilePatrol:registerByPrefixes(mobileSAMPrefix, mobileEWPrefix, options)
	local registeredSAM = 0
	local registeredEW = 0
	local samSites = self.iads:getSAMSites()
	for i = 1, #samSites do
		local samSite = samSites[i]
		if samSiteMatchesPrefix(samSite, mobileSAMPrefix) then
			if self:registerSAMSite(samSite, options) then
				registeredSAM = registeredSAM + 1
			end
		end
	end

	local ewRadars = self.iads:getEarlyWarningRadars()
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		if ewRadarMatchesPrefix(ewRadar, mobileEWPrefix) then
			if self:registerEWRadar(ewRadar, options) then
				registeredEW = registeredEW + 1
			end
		end
	end

	self:log("Registered mobile patrol assets | MSAM=" .. registeredSAM .. " | MEW=" .. registeredEW)
	return registeredSAM, registeredEW
end

function SkynetIADSMobilePatrol.create(iads, config)
	local patrol = {
		iads = iads,
		entries = {},
		enemyCoalitionId = getEnemyCoalition(iads.coalitionID),
		checkInterval = (config and config.checkInterval) or SkynetIADSMobilePatrol.DEFAULT_CHECK_INTERVAL,
		defaultPatrolSpeedKmph = (config and config.defaultPatrolSpeedKmph) or SkynetIADSMobilePatrol.DEFAULT_PATROL_SPEED_KMPH,
		defaultResumeDelaySeconds = (config and config.defaultResumeDelaySeconds) or SkynetIADSMobilePatrol.DEFAULT_RESUME_DELAY_SECONDS,
		defaultResumeMultiplier = (config and config.defaultResumeMultiplier) or SkynetIADSMobilePatrol.DEFAULT_RESUME_MULTIPLIER,
		defaultMSAMResumeMultiplier = (config and config.defaultMSAMResumeMultiplier) or SkynetIADSMobilePatrol.DEFAULT_MSAM_RESUME_MULTIPLIER,
		defaultArrivalToleranceMeters = (config and config.defaultArrivalToleranceMeters) or SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS,
	}
	setmetatable(patrol, SkynetIADSMobilePatrol)
	return patrol
end

function SkynetIADSMobilePatrol.installHooks()
	if SkynetIADSMobilePatrol._hooksInstalled then
		return
	end
	SkynetIADSMobilePatrol._hooksInstalled = true

	local originalSAMInformOfContact = SkynetIADSSamSite.informOfContact
	function SkynetIADSSamSite:informOfContact(contact)
		local hadTargetInRange = self.targetsInRange == true
		local result = originalSAMInformOfContact(self, contact)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and hadTargetInRange == false and self.targetsInRange == true then
			entry.manager:pausePatrolForDeployment(entry)
		end
		return result
	end

	local originalSAMSetToCorrectAutonomousState = SkynetIADSAbstractRadarElement.setToCorrectAutonomousState
	function SkynetIADSSamSite:setToCorrectAutonomousState()
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and (entry.state == "patrolling" or entry.state == "harm_evading") then
			self.isAutonomous = false
			forceElementIntoPatrolDarkState(self)
			return
		end
		return originalSAMSetToCorrectAutonomousState(self)
	end

	local originalEWSetToCorrectAutonomousState = SkynetIADSEWRadar.setToCorrectAutonomousState
	function SkynetIADSEWRadar:setToCorrectAutonomousState()
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and (entry.state == "patrolling" or entry.state == "harm_evading") then
			self.isAutonomous = false
			forceElementIntoPatrolDarkState(self)
			return
		end
		return originalEWSetToCorrectAutonomousState(self)
	end

	local originalGoSilentToEvadeHARM = SkynetIADSAbstractRadarElement.goSilentToEvadeHARM
	function SkynetIADSAbstractRadarElement:goSilentToEvadeHARM(timeToImpact)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry then
			entry.state = "harm_evading"
			entry.noThreatSince = nil
		end
		return originalGoSilentToEvadeHARM(self, timeToImpact)
	end
end

SkynetIADSMobilePatrol.installHooks()
MobileIADSPatrol = SkynetIADSMobilePatrol
trigger.action.outText("Skynet Mobile Patrol module loaded", 10)

end
