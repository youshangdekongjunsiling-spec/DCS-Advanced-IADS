do

SkynetIADSMobilePatrol = {}
SkynetIADSMobilePatrol.__index = SkynetIADSMobilePatrol

SkynetIADSMobilePatrol._hooksInstalled = false
SkynetIADSMobilePatrol._entriesByElement = setmetatable({}, { __mode = "k" })

SkynetIADSMobilePatrol.DEFAULT_CHECK_INTERVAL = 1
SkynetIADSMobilePatrol.DEFAULT_PATROL_SPEED_KMPH = 35
SkynetIADSMobilePatrol.DEFAULT_RESUME_DELAY_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_RESUME_MULTIPLIER = 2
SkynetIADSMobilePatrol.DEFAULT_MSAM_RESUME_MULTIPLIER = 1.2
SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM = 25
SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ENGAGE_DISTANCE_NM = 16
SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS = 8
SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS = 25
SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS = { 3, 10 }

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

local function setCombatAlarmState(controller)
	pcall(function()
		controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
	end)
end

local collectElementEmitterRepresentations

local function setGroundROE(controller, weaponHold)
	pcall(function()
		controller:setOption(
			AI.Option.Ground.id.ROE,
			weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or AI.Option.Ground.val.ROE.OPEN_FIRE
		)
	end)
end

local function setPatrolROE(controller)
	setGroundROE(controller, true)
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

collectElementEmitterRepresentations = function(element)
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

local function applyPatrolOptionsToRepresentation(representation)
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
		setPatrolAlarmState(controller)
		setPatrolROE(controller)
	end
end

local function forceElementIntoPatrolDarkState(element)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		local representation = representations[i]
		pcall(function()
			representation:enableEmission(false)
		end)
		applyPatrolOptionsToRepresentation(representation)
	end
	local controller = element:getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setPatrolAlarmState(controller)
		setPatrolROE(controller)
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
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing group or destination")
		return false
	end
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing start point")
		return false
	end
	local ok = pcall(function()
		mist.goRoute(entry.group, {
			mist.ground.buildWP(startPoint, "On Road", mist.utils.kmphToMps(entry.patrolSpeedKmph)),
			mist.ground.buildWP(destination, "On Road", mist.utils.kmphToMps(entry.patrolSpeedKmph)),
		})
	end)
	if ok then
		entry.currentDestination = destination
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = startPoint
		self:log("Road move issued for "..entry.groupName.." | speed="..entry.patrolSpeedKmph.."km/h")
	else
		self:log("Road move failed for "..entry.groupName)
	end
	return ok
end

function SkynetIADSMobilePatrol:issuePatrolRoute(entry)
	if entry.group == nil or entry.group:isExist() == false then
		self:log("Patrol route skipped for "..tostring(entry.groupName).." | missing group")
		return false
	end
	local ok = pcall(function()
		mist.ground.patrolRoute({
			gpData = entry.groupName,
			useGroupRoute = entry.groupName,
			onRoadForm = "On Road",
			speed = mist.utils.kmphToMps(entry.patrolSpeedKmph),
		})
	end)
	if ok then
		entry.currentDestination = nil
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
		self:log("Patrol route issued for "..entry.groupName.." | speed="..entry.patrolSpeedKmph.."km/h")
	else
		self:log("Patrol route failed for "..entry.groupName)
	end
	return ok
end

function SkynetIADSMobilePatrol:shouldReissuePatrolRoute(entry)
	if entry.lastRouteIssueTime == nil or entry.lastRouteIssueReferencePoint == nil then
		return false
	end
	if (timer.getTime() - entry.lastRouteIssueTime) < self.defaultRouteReissueSeconds then
		return false
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return false
	end
	local movedDistance = mist.utils.get2DDist(currentPoint, entry.lastRouteIssueReferencePoint)
	return movedDistance < self.defaultMinMovementMeters
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

function SkynetIADSMobilePatrol:getMSAMCombatProfile(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return nil
	end
	local natoName = entry.element.getNatoName and entry.element:getNatoName() or nil
	if natoName ~= "SA-11" then
		return nil
	end
	return {
		alertRangeMeters = mist.utils.NMToMeters(self.sa11MSAMAlertDistanceNm),
		engageRangeMeters = mist.utils.NMToMeters(self.sa11MSAMEngageDistanceNm),
	}
end

function SkynetIADSMobilePatrol:getDeployTriggerRangeMeters(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		return profile.alertRangeMeters
	end
	return self:getThreatRangeMeters(entry)
end

function SkynetIADSMobilePatrol:getContactName(contact)
	local targetName = "unknown"
	local okName, name = pcall(function()
		return contact:getName()
	end)
	if okName and name then
		targetName = name
	end
	return targetName
end

function SkynetIADSMobilePatrol:getContactDistanceMeters(entry, contact)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = contact and contact.getPosition and contact:getPosition().p or nil
	if radarPoint and targetPoint then
		return mist.utils.get2DDist(radarPoint, targetPoint)
	end
	return math.huge
end

function SkynetIADSMobilePatrol:findNearestEligibleContact(entry, maxDistanceMeters)
	local contacts = self.iads:getContacts()
	local nearestContact = nil
	local nearestDistanceMeters = math.huge
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			local distanceMeters = self:getContactDistanceMeters(entry, contact)
			if distanceMeters <= maxDistanceMeters and distanceMeters < nearestDistanceMeters then
				nearestContact = contact
				nearestDistanceMeters = distanceMeters
			end
		end
	end
	return nearestContact, nearestDistanceMeters
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

function SkynetIADSMobilePatrol:buildDeployTriggerInfo(entry, contact, source)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = contact and contact.getPosition and contact:getPosition().p or nil
	local distanceNm = 0
	local threatRangeNm = 0
	if radarPoint and targetPoint then
		distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
	end
	local threatRangeMeters = self:getDeployTriggerRangeMeters(entry)
	if threatRangeMeters and threatRangeMeters > 0 then
		threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
	end
	local targetName = self:getContactName(contact)
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return contact:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return {
		source = source or "unknown",
		time = timer.getTime(),
		contactName = targetName,
		contactType = targetType,
		distanceNm = mist.utils.round(distanceNm, 1),
		threatRangeNm = mist.utils.round(threatRangeNm, 1),
	}
end

function SkynetIADSMobilePatrol:findSAMThreatContact(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local contact, distanceMeters = self:findNearestEligibleContact(entry, profile.alertRangeMeters)
		if contact == nil then
			return nil
		end
		local shouldGoLive = distanceMeters <= profile.engageRangeMeters
		local triggerInfo = self:buildDeployTriggerInfo(
			entry,
			contact,
			shouldGoLive and "contact_scan_engage" or "contact_scan_alert"
		)
		triggerInfo.combatMode = shouldGoLive and "engage_fire" or "alert_hold"
		return {
			contact = contact,
			triggerInfo = triggerInfo,
			shouldDeploy = true,
			shouldGoLive = shouldGoLive,
			shouldWeaponHold = false,
			combatMode = triggerInfo.combatMode,
		}
	end

	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact)
			and entry.element:isTargetInRange(contact) then
			return {
				contact = contact,
				triggerInfo = self:buildDeployTriggerInfo(entry, contact, "contact_scan"),
				shouldDeploy = true,
				shouldGoLive = true,
				shouldWeaponHold = false,
				combatMode = "default_fire",
			}
		end
	end
	return nil
end

function SkynetIADSMobilePatrol:applyMSAMThreatDecision(entry, threatDecision, skipPause)
	if entry == nil then
		return false
	end

	if threatDecision == nil then
		entry.combatMode = "searching"
		return false
	end

	local triggerInfo = threatDecision.triggerInfo
	entry.combatMode = threatDecision.combatMode or "default_fire"

	if threatDecision.shouldDeploy and entry.state ~= "deployed" and skipPause ~= true then
		self:pausePatrolForDeployment(entry, triggerInfo)
	end

	if threatDecision.shouldGoLive then
		if entry.element.targetsInRange ~= nil then
			entry.element.targetsInRange = true
		end
		entry.element:goLive()
		setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
	else
		forceElementIntoPatrolDarkState(entry.element)
	end

	entry.state = "deployed"
	entry.lastThreatTime = timer.getTime()
	entry.noThreatSince = nil
	return true
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

function SkynetIADSMobilePatrol:pausePatrolForDeployment(entry, triggerInfo)
	self:issueHold(entry)
	entry.state = "deployed"
	entry.noThreatSince = nil
	entry.lastThreatTime = timer.getTime()
	if triggerInfo then
		entry.lastDeployTrigger = triggerInfo
		self:log(
			"MSAM deploy | "..entry.groupName
			.." | source="..tostring(triggerInfo.source)
			.." | contact="..tostring(triggerInfo.contactName)
			.." | type="..tostring(triggerInfo.contactType)
			.." | distance="..tostring(triggerInfo.distanceNm).."nm"
			.." | threatRange="..tostring(triggerInfo.threatRangeNm).."nm"
			.." | mode="..tostring(triggerInfo.combatMode or "default")
			.." | closure="..tostring(triggerInfo.closingRateNmps or "n/a")
		)
	end
end

function SkynetIADSMobilePatrol:beginPatrol(entry)
	entry.state = "patrolling"
	entry.combatMode = "patrolling"
	entry.noThreatSince = nil
	entry.lastThreatTime = 0
	entry.contactKinematics = {}
	forceElementIntoPatrolDarkState(entry.element)
	entry.currentDestination = nil
	entry.patrolRefreshDelays = mist.utils.deepCopy(self.defaultPatrolRefreshDelays)
	entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
	self:issuePatrolRoute(entry)
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
	local resumeRange = self:getDeployTriggerRangeMeters(entry) * entry.resumeMultiplier
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
		local threatDecision = self:findSAMThreatContact(entry)
		threatPresent = threatDecision ~= nil
		if threatDecision then
			self:applyMSAMThreatDecision(entry, threatDecision)
			return
		end
	else
		threatPresent = self:findMEWThreat(entry)
		if threatPresent and entry.state ~= "deployed" then
			self:pausePatrolForDeployment(entry)
			entry.element:goLive()
			entry.combatMode = "default_fire"
		end
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

	if entry.nextPatrolRefreshTime and timer.getTime() >= entry.nextPatrolRefreshTime then
		forceElementIntoPatrolDarkState(entry.element)
		self:log("Patrol refresh reissued for "..entry.groupName.." | delayed startup refresh")
		self:issuePatrolRoute(entry)
		table.remove(entry.patrolRefreshDelays, 1)
		if #entry.patrolRefreshDelays > 0 then
			entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
		else
			entry.nextPatrolRefreshTime = nil
		end
	end

	if self:shouldReissuePatrolRoute(entry) then
		self:log("Patrol route reissued for "..entry.groupName.." | group appears stationary")
		self:issuePatrolRoute(entry)
	end
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
		combatMode = "patrolling",
		lastThreatTime = 0,
		noThreatSince = nil,
		lastRouteIssueTime = nil,
		lastRouteIssueReferencePoint = nil,
		patrolRefreshDelays = {},
		nextPatrolRefreshTime = nil,
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
		sa11MSAMAlertDistanceNm = (config and config.sa11MSAMAlertDistanceNm) or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM,
		sa11MSAMEngageDistanceNm = (config and config.sa11MSAMEngageDistanceNm) or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ENGAGE_DISTANCE_NM,
		defaultArrivalToleranceMeters = (config and config.defaultArrivalToleranceMeters) or SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS,
		defaultRouteReissueSeconds = (config and config.defaultRouteReissueSeconds) or SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS,
		defaultMinMovementMeters = (config and config.defaultMinMovementMeters) or SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS,
		defaultPatrolRefreshDelays = (config and config.defaultPatrolRefreshDelays) or SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS,
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
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		if entry and entry.kind == "MSAM" then
			local profile = entry.manager:getMSAMCombatProfile(entry)
			if profile and contact:isIdentifiedAsHARM() == false and self:areGoLiveConstraintsSatisfied(contact) == true then
				local distanceMeters = entry.manager:getContactDistanceMeters(entry, contact)
				if distanceMeters <= profile.alertRangeMeters then
					if entry.state == "patrolling" then
						entry.manager:pausePatrolForDeployment(
							entry,
							entry.manager:buildDeployTriggerInfo(entry, contact, "inform_of_contact_alert")
						)
					end
					if distanceMeters <= profile.engageRangeMeters then
						return originalSAMInformOfContact(self, contact)
					end
					return
				end
			end
		end

		local shouldDeployFromThisContact = false
		local deployTriggerInfo = nil
		if entry and hadTargetInRange == false and entry.state == "patrolling" then
			shouldDeployFromThisContact =
				self:areGoLiveConstraintsSatisfied(contact) == true
				and self:isTargetInRange(contact)
				and (
					contact:isIdentifiedAsHARM() == false
					or (contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true)
				)
			if shouldDeployFromThisContact then
				deployTriggerInfo = entry.manager:buildDeployTriggerInfo(entry, contact, "inform_of_contact")
			end
		end
		if shouldDeployFromThisContact then
			entry.manager:pausePatrolForDeployment(entry, deployTriggerInfo)
		end
		local result = originalSAMInformOfContact(self, contact)
		if entry and hadTargetInRange == false and self.targetsInRange == true then
			local radarPoint = entry.manager:getPatrolReferencePoint(entry)
			local targetPoint = contact:getPosition().p
			local distanceNm = 0
			local threatRangeNm = 0
			if radarPoint and targetPoint then
				distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
			end
			local threatRangeMeters = entry.manager:getThreatRangeMeters(entry)
			if threatRangeMeters and threatRangeMeters > 0 then
				threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
			end
			local targetName = "unknown"
			local okName, name = pcall(function()
				return contact:getName()
			end)
			if okName and name then
				targetName = name
			end
			entry.manager:log("informOfContact deploy | "..entry.groupName.." | contact="..targetName.." | distance="..mist.utils.round(distanceNm, 1).."nm | threatRange="..mist.utils.round(threatRangeNm, 1).."nm")
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
