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
SkynetIADSMobilePatrol.DEFAULT_COMBAT_EXIT_NO_TARGET_SECONDS = 10
SkynetIADSMobilePatrol.DEFAULT_POST_COMBAT_MOBILE_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS = 8
SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS = 25
SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS = { 3, 10 }
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_DISTANCE_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM = "Diamond"
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS = 1
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_MIN_COMPLETION_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS = 20
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_FORMATION_INTERVAL_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_NATO_NAMES = {
	["SA-8 Gecko"] = true,
	["SA-15 Gauntlet"] = true,
	["SA-19 Grison"] = true,
	["Gepard"] = true,
	["Zues"] = true,
}
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_LAUNCHER_TYPE_NAMES = {
	["Osa 9A33 ln"] = true,
	["Tor 9A331"] = true,
	["2S6 Tunguska"] = true,
	["Gepard"] = true,
	["ZSU-23-4 Shilka"] = true,
}

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

local function isAirContact(contact)
	if contact == nil or contact.getDesc == nil then
		return false
	end
	local representation = nil
	local okRepresentation = pcall(function()
		representation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okRepresentation ~= true or representation == nil then
		return false
	end
	if representation.isExist and representation:isExist() == false then
		return false
	end
	local categoryId = nil
	if representation.getCategory ~= nil then
		local okCategory, resolvedCategoryId = pcall(function()
			return representation:getCategory()
		end)
		if okCategory ~= true then
			return false
		end
		categoryId = resolvedCategoryId
	end
	if categoryId ~= nil and categoryId ~= Object.Category.UNIT then
		return false
	end
	local okDesc, desc = pcall(function()
		return contact:getDesc() or {}
	end)
	if okDesc ~= true then
		return false
	end
	local category = desc.category
	return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
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

local function setGroundFormationInterval(controller, meters)
	if controller == nil or meters == nil then
		return
	end
	local intervalMeters = math.max(0, math.min(100, math.floor(meters + 0.5)))
	pcall(function()
		controller:setOption(30, intervalMeters)
	end)
end

local function applyFormationIntervalToEntry(entry, meters)
	if entry == nil then
		return
	end
	local group = entry.group
	if group and group.isExist and group:isExist() then
		local okController, controller = pcall(function()
			return group:getController()
		end)
		if okController and controller then
			setGroundFormationInterval(controller, meters)
		end
	end
	local element = entry.element
	if element and element.getController then
		local okController, controller = pcall(function()
			return element:getController()
		end)
		if okController and controller then
			setGroundFormationInterval(controller, meters)
		end
	end
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

local function setMovingCombatROEForRepresentation(representation, weaponHold)
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

local function setElementMovingCombatState(element, weaponHold)
	if element == nil or element.isDestroyed == nil or element:isDestroyed() then
		return
	end
	local representations = collectElementEmitterRepresentations(element)
	for i = 1, #representations do
		setMovingCombatROEForRepresentation(representations[i], weaponHold)
	end
	local controller = element.getController and element:getController() or nil
	if controller then
		pcall(function()
			controller:setOnOff(true)
		end)
		setCombatAlarmState(controller)
		setGroundROE(controller, weaponHold)
	end
	element.goLiveTime = timer.getTime()
	element.aiState = true
	if element.pointDefencesStopActingAsEW then
		element:pointDefencesStopActingAsEW()
	end
	if element.scanForHarms then
		element:scanForHarms()
	end
end

local function setElementMovingSilenceState(element)
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
	local controller = element.getController and element:getController() or nil
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
	local controller = element.getController and element:getController() or nil
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

function SkynetIADSMobilePatrol:notifyDebug(message)
	if _G.SkynetRuntimeDebugNotify and message then
		pcall(_G.SkynetRuntimeDebugNotify, message)
	end
end

function SkynetIADSMobilePatrol:announceCombatState(entry, threatDecision)
	if entry == nil or threatDecision == nil then
		return
	end
	local triggerInfo = threatDecision.triggerInfo or {}
	local targetName = triggerInfo.contactName or "unknown"
	local mode = threatDecision.combatMode or entry.combatMode or "default"
	local distanceDetails = ""
	if entry.combatCommitted == true and (mode == "combat_latched" or mode == "sibling_primary") then
		mode = "combat_committed"
		if entry.lastDeployTrigger and entry.lastDeployTrigger.contactName then
			targetName = entry.lastDeployTrigger.contactName
		end
		if entry.lastDeployTrigger then
			triggerInfo = entry.lastDeployTrigger
		end
	end
	local shouldGoLive = threatDecision.shouldGoLive == true
	local shouldWeaponHold = threatDecision.shouldWeaponHold == true
	local moveFireCapable = self:isMoveFireCapable(entry)
	if entry.kind == "MSAM" then
		local debugRangeMeters = self:getDeployTriggerRangeMeters(entry)
		if triggerInfo.engageRangeNm == nil then
			local combatRangeMeters = self:getCombatRangeMeters(entry)
			if combatRangeMeters and combatRangeMeters > 0 then
				triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(combatRangeMeters), 1)
			end
		end
		if triggerInfo.directDistanceNm == nil and debugRangeMeters and debugRangeMeters > 0 then
			local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, debugRangeMeters)
			if directUnit ~= nil and directUnitDistanceMeters < math.huge then
				triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
				if triggerInfo.contactName == nil or triggerInfo.contactName == "unknown" then
					local okDirectName, directName = pcall(function()
						return directUnit:getName()
					end)
					if okDirectName and directName then
						triggerInfo.contactName = directName
						targetName = directName
					end
				end
			end
		end
		if triggerInfo.distanceNm == nil and debugRangeMeters and debugRangeMeters > 0 then
			local debugContact, contactDistanceMeters = self:findNearestEligibleContact(entry, debugRangeMeters)
			if debugContact ~= nil and contactDistanceMeters < math.huge then
				triggerInfo.distanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
				if triggerInfo.contactName == nil or triggerInfo.contactName == "unknown" then
					triggerInfo.contactName = self:getContactName(debugContact)
					targetName = triggerInfo.contactName
				end
			end
		end
		if triggerInfo.effectiveDistanceNm == nil then
			triggerInfo.effectiveDistanceNm = triggerInfo.directDistanceNm or triggerInfo.distanceNm
		end
	end
	local announcementKey = table.concat({
		tostring(mode),
		tostring(shouldGoLive),
		tostring(shouldWeaponHold),
		tostring(targetName),
		tostring(moveFireCapable),
	}, "|")
	if entry.debugLastCombatAnnouncementKey == announcementKey then
		return
	end
	entry.debugLastCombatAnnouncementKey = announcementKey
	local action = moveFireCapable and "机动警戒" or "进入警戒模式"
	if shouldGoLive then
		if moveFireCapable then
			action = shouldWeaponHold and "机动锁定待射" or "机动交战"
		else
			action = shouldWeaponHold and "进入锁定待射" or "进入战斗模式"
		end
	end
	if triggerInfo.distanceNm ~= nil then
		distanceDetails = distanceDetails .. " | contact=" .. tostring(triggerInfo.distanceNm) .. "nm"
	end
	if triggerInfo.directDistanceNm ~= nil then
		distanceDetails = distanceDetails .. " | direct=" .. tostring(triggerInfo.directDistanceNm) .. "nm"
	end
	if triggerInfo.effectiveDistanceNm ~= nil then
		distanceDetails = distanceDetails .. " | effective=" .. tostring(triggerInfo.effectiveDistanceNm) .. "nm"
	end
	if triggerInfo.engageRangeNm ~= nil then
		distanceDetails = distanceDetails .. " | engage=" .. tostring(triggerInfo.engageRangeNm) .. "nm"
	end
	if triggerInfo.source ~= nil then
		distanceDetails = distanceDetails .. " | source=" .. tostring(triggerInfo.source)
	end
	self:notifyDebug(
		entry.groupName
		.. " "
		.. action
		.. " | mode="
		.. tostring(mode)
		.. " | target="
		.. tostring(targetName)
		.. distanceDetails
	)
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

function SkynetIADSMobilePatrol:getPatrolForwardVector(entry)
	if entry == nil then
		return nil
	end
	local units = nil
	if entry.group and entry.group.isExist and entry.group:isExist() then
		local okUnits, groupUnits = pcall(function()
			return entry.group:getUnits()
		end)
		if okUnits and groupUnits then
			units = groupUnits
		end
	end
	if units then
		for i = 1, #units do
			local unit = units[i]
			if unit and unit.isExist and unit:isExist() then
				local okPos, position = pcall(function()
					return unit:getPosition()
				end)
				if okPos and position and position.x then
					return { x = position.x.x, z = position.x.z }
				end
			end
		end
	end
	local dcsRepresentation = entry.element and entry.element.getDCSRepresentation and entry.element:getDCSRepresentation() or nil
	if dcsRepresentation and dcsRepresentation.isExist and dcsRepresentation:isExist() then
		local okPos, position = pcall(function()
			return dcsRepresentation:getPosition()
		end)
		if okPos and position and position.x then
			return { x = position.x.x, z = position.x.z }
		end
	end
	return nil
end

function SkynetIADSMobilePatrol:isWaypointAhead(entry, point)
	local currentPoint = self:getPatrolReferencePoint(entry)
	local heading = self:getPatrolForwardVector(entry)
	if currentPoint == nil or point == nil or heading == nil then
		return nil
	end
	local vecX = point.x - currentPoint.x
	local vecZ = point.z - currentPoint.z
	local vecMag = math.sqrt((vecX * vecX) + (vecZ * vecZ))
	local headingMag = math.sqrt((heading.x * heading.x) + (heading.z * heading.z))
	if vecMag <= 1 or headingMag <= 0.001 then
		return nil
	end
	local dot = ((vecX / vecMag) * (heading.x / headingMag)) + ((vecZ / vecMag) * (heading.z / headingMag))
	return dot >= 0.15
end

function SkynetIADSMobilePatrol:selectStartingWaypointIndex(entry)
	if #entry.routePoints <= 1 then
		return 1
	end
	local nearestIndex = 1
	local nearestDistance = math.huge
	local nearestAheadIndex = nil
	local nearestAheadDistance = math.huge
	for i = 1, #entry.routePoints do
		local distance = self:getWaypointDistance(entry, entry.routePoints[i])
		if distance < nearestDistance then
			nearestDistance = distance
			nearestIndex = i
		end
		if self:isWaypointAhead(entry, entry.routePoints[i]) == true and distance < nearestAheadDistance then
			nearestAheadDistance = distance
			nearestAheadIndex = i
		end
	end
	if nearestAheadIndex ~= nil then
		if nearestAheadDistance <= entry.arrivalToleranceMeters then
			return (nearestAheadIndex % #entry.routePoints) + 1
		end
		return nearestAheadIndex
	end
	if nearestDistance <= entry.arrivalToleranceMeters then
		return (nearestIndex % #entry.routePoints) + 1
	end
	return nearestIndex
end

function SkynetIADSMobilePatrol:buildRoadPatrolRoute(entry, startIndex)
	if entry == nil or #entry.routePoints == 0 then
		return nil
	end
	local route = {}
	local speedMps = mist.utils.kmphToMps(entry.patrolSpeedKmph)
	for offset = 0, (#entry.routePoints - 1) do
		local index = ((startIndex - 1 + offset) % #entry.routePoints) + 1
		local point = entry.routePoints[index]
		if point then
			route[#route + 1] = mist.ground.buildWP(point, "On Road", speedMps)
		end
	end
	return #route > 0 and route or nil
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

function SkynetIADSMobilePatrol:isDeployScatterPointOnLand(point)
	if point == nil then
		return false
	end
	if land == nil or land.getSurfaceType == nil or land.SurfaceType == nil or land.SurfaceType.LAND == nil then
		return true
	end
	local ok, surfaceType = pcall(function()
		return land.getSurfaceType({
			x = point.x,
			y = point.z
		})
	end)
	if ok ~= true then
		return true
	end
	return surfaceType == land.SurfaceType.LAND
end

function SkynetIADSMobilePatrol:calculateDeployScatterPoint(entry)
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		return nil, 0, nil
	end
	local distanceMeters = SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_DISTANCE_METERS
	local fallbackPoint = nil
	for i = 1, 50 do
		local headingRad = math.random() * 2 * math.pi
		local candidate = {
			x = startPoint.x + math.cos(headingRad) * distanceMeters,
			y = startPoint.y,
			z = startPoint.z + math.sin(headingRad) * distanceMeters
		}
		if fallbackPoint == nil then
			fallbackPoint = candidate
		end
		if self:isDeployScatterPointOnLand(candidate) then
			return candidate, distanceMeters, startPoint
		end
	end
	return fallbackPoint, distanceMeters, startPoint
end

function SkynetIADSMobilePatrol:issueDeployScatterRoute(entry, destination, speedKmph)
	if entry == nil or entry.group == nil or entry.group:isExist() == false or destination == nil then
		return false
	end
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		return false
	end
	local speedMps = mist.utils.kmphToMps(speedKmph)
	local path = {
		mist.ground.buildWP(startPoint, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
		mist.ground.buildWP({
			x = startPoint.x + 25,
			z = startPoint.z + 25
		}, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
		mist.ground.buildWP(destination, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM, speedMps),
	}
	local ok = pcall(function()
		mist.goRoute(entry.group, path)
	end)
	return ok == true
end

function SkynetIADSMobilePatrol:calculateDeployScatterTravelTimeSeconds(distanceMeters, speedKmph)
	local speedMps = mist.utils.kmphToMps(speedKmph or self.defaultPatrolSpeedKmph)
	if speedMps <= 0 then
		speedMps = 1
	end
	return math.max(8, math.ceil(distanceMeters / speedMps) + 4)
end

function SkynetIADSMobilePatrol:getDeployScatterDistanceMovedMeters(entry)
	if entry == nil or entry.deployScatterStartPoint == nil then
		return 0
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return 0
	end
	return mist.utils.get2DDist(currentPoint, entry.deployScatterStartPoint)
end

function SkynetIADSMobilePatrol:hasReachedDeployScatterDestination(entry)
	if entry == nil or entry.deployScatterDestination == nil then
		return true
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return false
	end
	return mist.utils.get2DDist(currentPoint, entry.deployScatterDestination) <= entry.arrivalToleranceMeters
end

function SkynetIADSMobilePatrol:getDeployScatterSpeedKmph(entry)
	local speed = entry.patrolSpeedKmph or self.defaultPatrolSpeedKmph
	if entry.element and entry.element.getHARMRelocationSpeedKmph then
		local okSpeed, relocationSpeed = pcall(function()
			return entry.element:getHARMRelocationSpeedKmph()
		end)
		if okSpeed and relocationSpeed and relocationSpeed > speed then
			speed = relocationSpeed
		end
	end
	return speed
end

function SkynetIADSMobilePatrol:issueDeployScatter(entry)
	if entry.group == nil or entry.group:isExist() == false then
		return false
	end
	local destination, distanceMeters, startPoint = self:calculateDeployScatterPoint(entry)
	if destination == nil then
		return false
	end
	local speedKmph = self:getDeployScatterSpeedKmph(entry)
	local ok = self:issueDeployScatterRoute(entry, destination, speedKmph)
	if ok then
		entry.currentDestination = destination
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
		entry.deployScatterStartPoint = startPoint
		entry.deployScatterDestination = destination
		entry.deployScatterDeadline = timer.getTime() + self:calculateDeployScatterTravelTimeSeconds(distanceMeters, speedKmph)
		entry.deployScatterMinimumCompletionMeters = math.max(
			SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_MIN_COMPLETION_METERS,
			math.floor(distanceMeters * 0.6)
		)
		self:log("Deploy scatter issued for "..entry.groupName.." | speed="..speedKmph.."km/h | distance="..distanceMeters.."m")
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

function SkynetIADSMobilePatrol:isMoveFireCapable(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return false
	end
	local natoName = entry.element.getNatoName and entry.element:getNatoName() or nil
	if natoName ~= nil and self.moveFireNatoNames[natoName] == true then
		return true
	end

	local launchers = entry.element.getLaunchers and entry.element:getLaunchers() or {}
	if #launchers == 0 then
		return false
	end

	for i = 1, #launchers do
		local launcher = launchers[i]
		local typeName = launcher and launcher.getTypeName and launcher:getTypeName() or nil
		if typeName == nil then
			local representation = launcher and launcher.getDCSRepresentation and launcher:getDCSRepresentation() or nil
			if representation and representation.getTypeName then
				typeName = representation:getTypeName()
			end
		end
		if typeName == nil or self.moveFireLauncherTypeNames[typeName] ~= true then
			return false
		end
	end

	return true
end

function SkynetIADSMobilePatrol:getDeployTriggerRangeMeters(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		return profile.alertRangeMeters
	end
	return self:getThreatRangeMeters(entry)
end

function SkynetIADSMobilePatrol:getCombatRangeMeters(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		return profile.engageRangeMeters
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
	local targetPoint = nil
	if contact and contact.getPosition then
		pcall(function()
			local position = contact:getPosition()
			targetPoint = position and position.p or nil
		end)
	end
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
			and isAirContact(contact)
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
	local targetPoint = nil
	if contact and contact.getPosition then
		pcall(function()
			local position = contact:getPosition()
			targetPoint = position and position.p or nil
		end)
	end
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

function SkynetIADSMobilePatrol:buildAircraftUnitTriggerInfo(entry, unit, source, threatRangeMeters)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local targetPoint = unit and unit.getPoint and unit:getPoint() or nil
	local distanceNm = 0
	local threatRangeNm = 0
	if radarPoint and targetPoint then
		distanceNm = mist.utils.metersToNM(mist.utils.get2DDist(radarPoint, targetPoint))
	end
	if threatRangeMeters and threatRangeMeters > 0 then
		threatRangeNm = mist.utils.metersToNM(threatRangeMeters)
	end
	local targetName = "unknown"
	local okName, unitName = pcall(function()
		return unit:getName()
	end)
	if okName and unitName then
		targetName = unitName
	end
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return unit:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return {
		source = source or "direct_unit_scan",
		time = timer.getTime(),
		contactName = targetName,
		contactType = targetType,
		distanceNm = mist.utils.round(distanceNm, 1),
		directDistanceNm = mist.utils.round(distanceNm, 1),
		effectiveDistanceNm = mist.utils.round(distanceNm, 1),
		threatRangeNm = mist.utils.round(threatRangeNm, 1),
	}
end

function SkynetIADSMobilePatrol:findSAMThreatContact(entry)
	local moveFireCapable = self:isMoveFireCapable(entry)
	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local contact, contactDistanceMeters = self:findNearestEligibleContact(entry, profile.alertRangeMeters)
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, profile.alertRangeMeters)
		if contact == nil and directUnit == nil then
			return nil
		end
		local effectiveDistanceMeters = math.huge
		if contact ~= nil and contactDistanceMeters < effectiveDistanceMeters then
			effectiveDistanceMeters = contactDistanceMeters
		end
		if directUnit ~= nil and directUnitDistanceMeters < effectiveDistanceMeters then
			effectiveDistanceMeters = directUnitDistanceMeters
		end
		if effectiveDistanceMeters == math.huge then
			return nil
		end

		local inEngageRange = effectiveDistanceMeters <= profile.engageRangeMeters
		local hasFireQualityContact = contact ~= nil and contactDistanceMeters <= profile.engageRangeMeters
		local shouldGoLive = inEngageRange
		local shouldWeaponHold = inEngageRange and hasFireQualityContact ~= true
		local triggerInfo = nil
		if contact ~= nil then
			triggerInfo = self:buildDeployTriggerInfo(
				entry,
				contact,
				(hasFireQualityContact and "contact_scan_engage" or "contact_scan_alert")
			)
			triggerInfo.contactDistanceNm = triggerInfo.distanceNm
		else
			triggerInfo = self:buildAircraftUnitTriggerInfo(
				entry,
				directUnit,
				(inEngageRange and "direct_unit_track" or "direct_unit_alert"),
				profile.alertRangeMeters
			)
			triggerInfo.contactDistanceNm = nil
		end

		triggerInfo.directDistanceNm = nil
		if directUnit ~= nil and directUnitDistanceMeters < math.huge then
			triggerInfo.directDistanceNm = mist.utils.round(mist.utils.metersToNM(directUnitDistanceMeters), 1)
			local okDirectName, directName = pcall(function()
				return directUnit:getName()
			end)
			if okDirectName and directName then
				triggerInfo.directUnitName = directName
			end
		end
		triggerInfo.effectiveDistanceNm = mist.utils.round(mist.utils.metersToNM(effectiveDistanceMeters), 1)
		triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(profile.engageRangeMeters), 1)
		if inEngageRange then
			triggerInfo.combatMode = hasFireQualityContact and "engage_fire" or "engage_track"
		else
			triggerInfo.combatMode = "alert_hold"
		end
		return {
			contact = contact,
			triggerInfo = triggerInfo,
			shouldDeploy = moveFireCapable ~= true,
			shouldGoLive = shouldGoLive,
			shouldWeaponHold = shouldWeaponHold,
			combatMode = triggerInfo.combatMode,
		}
	end

	if moveFireCapable then
		local threatRangeMeters = self:getThreatRangeMeters(entry)
		if threatRangeMeters <= 0 then
			return nil
		end
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, threatRangeMeters)
		if directUnit == nil then
			return nil
		end
		local triggerInfo = self:buildAircraftUnitTriggerInfo(entry, directUnit, "direct_unit_scan", threatRangeMeters)
		triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(threatRangeMeters), 1)
		return {
			contact = nil,
			triggerInfo = triggerInfo,
			shouldDeploy = false,
			shouldGoLive = true,
			shouldWeaponHold = false,
			combatMode = "direct_unit_fire",
		}
	end

	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact)
			and entry.element:isTargetInRange(contact) then
			return {
				contact = contact,
				triggerInfo = self:buildDeployTriggerInfo(entry, contact, "contact_scan"),
				shouldDeploy = moveFireCapable ~= true,
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
		entry.debugLastCombatAnnouncementKey = nil
		return false
	end

	local now = timer.getTime()
	local wasCombatCommitted = entry.combatCommitted == true
	local triggerInfo = threatDecision.triggerInfo
	if triggerInfo then
		entry.lastDeployTrigger = triggerInfo
	end
	entry.combatMode = threatDecision.combatMode or "default_fire"
	local moveFireCapable = self:isMoveFireCapable(entry)

	if moveFireCapable ~= true and threatDecision.shouldDeploy and entry.state ~= "deployed" and entry.state ~= "deploy_scattering" and skipPause ~= true then
		self:pausePatrolForDeployment(entry, triggerInfo)
	end

	if entry.state == "deploy_scattering" then
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		if threatDecision.shouldGoLive == true then
			if entry.element.targetsInRange ~= nil then
				entry.element.targetsInRange = true
			end
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false and entry.element.informOfContact then
				pcall(function()
					entry.element:informOfContact(threatDecision.contact)
				end)
			end
			if threatDecision.shouldGoLive == true then
				entry.combatCommitted = true
				entry.combatNoTargetSince = nil
				entry.mobileLockUntil = 0
			end
			self:announceCombatState(entry, threatDecision)
		end
		return true
	end

	if threatDecision.shouldGoLive then
		if entry.element.targetsInRange ~= nil then
			entry.element.targetsInRange = true
		end
		if moveFireCapable then
			setElementMovingCombatState(entry.element, threatDecision.shouldWeaponHold == true)
		else
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false and entry.element.informOfContact then
				pcall(function()
					entry.element:informOfContact(threatDecision.contact)
				end)
			end
		end
	else
		forceElementIntoPatrolDarkState(entry.element)
	end

	if moveFireCapable then
		entry.state = "patrolling"
	else
		entry.state = "deployed"
	end
	if threatDecision.shouldGoLive == true then
		entry.combatCommitted = true
		entry.combatNoTargetSince = nil
		entry.mobileLockUntil = 0
	end
	entry.lastThreatTime = now
	entry.noThreatSince = nil
	self:announceCombatState(entry, threatDecision)
	if wasCombatCommitted ~= true and entry.combatCommitted == true and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
		pcall(function()
			_G.redIADSSiblingCoordination:requestImmediateEvaluation("msam_threat:" .. tostring(entry.groupName))
		end)
	end
	return true
end

function SkynetIADSMobilePatrol:hasSAMCombatThreat(entry)
	if entry == nil or entry.kind ~= "MSAM" then
		return false
	end

	local combatRangeMeters = self:getCombatRangeMeters(entry)
	if combatRangeMeters <= 0 then
		return false
	end

	local siblingInfo = self:getSiblingInfo(entry)
	if siblingInfo ~= nil and siblingInfo.mode == "denial" and siblingInfo.role == "primary" then
		local denialRangeMeters = mist.utils.NMToMeters(
			siblingInfo.denialAlertDistanceNm
			or self.sa11MSAMAlertDistanceNm
			or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM
		)
		local directUnit = self:findNearestEnemyAircraftUnit(entry, denialRangeMeters)
		if directUnit ~= nil then
			return true
		end
		local contacts = self.iads:getContacts()
		for i = 1, #contacts do
			local contact = contacts[i]
			if contact
				and isAirContact(contact)
				and contact:isIdentifiedAsHARM() == false
				and entry.element:areGoLiveConstraintsSatisfied(contact)
				and self:getContactDistanceMeters(entry, contact) <= denialRangeMeters then
				return true
			end
		end
	end

	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		if directUnit ~= nil then
			return true
		end
	end

	if self:isMoveFireCapable(entry) then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		return directUnit ~= nil
	end
	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			if profile then
				if self:getContactDistanceMeters(entry, contact) <= combatRangeMeters then
					return true
				end
			elseif entry.element:isTargetInRange(contact) then
				return true
			end
		end
	end
	return false
end

function SkynetIADSMobilePatrol:findNearestEnemyAircraftUnit(entry, maxDistanceMeters)
	local center = self:getPatrolReferencePoint(entry)
	if center == nil or maxDistanceMeters <= 0 then
		return nil, math.huge
	end
	local enemyAircraft = collectEnemyAirUnits(self.enemyCoalitionId)
	local nearestUnit = nil
	local nearestDistanceMeters = math.huge
	for i = 1, #enemyAircraft do
		local unit = enemyAircraft[i]
		local unitPoint = unit:getPoint()
		if unitPoint then
			local distanceMeters = mist.utils.get2DDist(center, unitPoint)
			if distanceMeters <= maxDistanceMeters and distanceMeters < nearestDistanceMeters then
				nearestUnit = unit
				nearestDistanceMeters = distanceMeters
			end
		end
	end
	return nearestUnit, nearestDistanceMeters
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
	local wasDeployed = entry.state == "deployed"
	applyFormationIntervalToEntry(entry, SkynetIADSMobilePatrol.DEFAULT_DEPLOY_FORMATION_INTERVAL_METERS)
	local scatterIssued = self:issueDeployScatter(entry) == true
	if scatterIssued ~= true then
		self:issueHold(entry)
		entry.deployScatterStartPoint = nil
		entry.deployScatterDestination = nil
		entry.deployScatterDeadline = 0
		entry.deployScatterMinimumCompletionMeters = 0
		entry.state = "deployed"
	else
		entry.state = "deploy_scattering"
	end
	entry.noThreatSince = nil
	entry.lastThreatTime = timer.getTime()
	entry.debugLastCombatAnnouncementKey = nil
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
	if wasDeployed ~= true then
		local deployMode = triggerInfo and (triggerInfo.combatMode or triggerInfo.source) or "default"
		local targetName = triggerInfo and triggerInfo.contactName or "unknown"
		self:notifyDebug(
			entry.groupName
			.. " 停车展开 | mode="
			.. tostring(deployMode)
			.. " | target="
			.. tostring(targetName)
		)
	end
end

function SkynetIADSMobilePatrol:beginPatrol(entry)
	local previousState = entry.state
	entry.state = "patrolling"
	entry.combatMode = "patrolling"
	entry.combatCommitted = false
	entry.combatNoTargetSince = nil
	entry.noThreatSince = nil
	entry.lastThreatTime = 0
	entry.contactKinematics = {}
	entry.debugLastCombatAnnouncementKey = nil
	forceElementIntoPatrolDarkState(entry.element)
	applyFormationIntervalToEntry(entry, SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS)
	entry.currentDestination = nil
	entry.patrolRefreshDelays = mist.utils.deepCopy(self.defaultPatrolRefreshDelays)
	entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
	self:issuePatrolRoute(entry)
	if previousState ~= "patrolling" then
		self:notifyDebug(entry.groupName .. " 恢复巡逻")
	end
end

function SkynetIADSMobilePatrol:advancePatrol(entry, force)
	if entry.state ~= "patrolling" then
		return false
	end
	if entry.group == nil or entry.group:isExist() == false or #entry.routePoints == 0 then
		return false
	end
	local nextPoint = entry.routePoints[entry.currentWaypointIndex]
	if nextPoint == nil then
		entry.currentWaypointIndex = 1
		nextPoint = entry.routePoints[1]
	end
	if force ~= true and entry.currentDestination and self:getWaypointDistance(entry, entry.currentDestination) > entry.arrivalToleranceMeters then
		return false
	end
	if self:getWaypointDistance(entry, nextPoint) <= entry.arrivalToleranceMeters then
		entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
		nextPoint = entry.routePoints[entry.currentWaypointIndex]
	end
	if nextPoint then
		local startIndex = entry.currentWaypointIndex
		local route = self:buildRoadPatrolRoute(entry, startIndex)
		if route and pcall(function()
			mist.goRoute(entry.group, route)
		end) then
			entry.currentDestination = nextPoint
			entry.lastRouteIssueTime = timer.getTime()
			entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
			self:log("Road patrol issued for "..entry.groupName.." | wp="..tostring(startIndex).." | speed="..entry.patrolSpeedKmph.."km/h")
			entry.currentWaypointIndex = (entry.currentWaypointIndex % #entry.routePoints) + 1
			return true
		end
	end
	return false
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

function SkynetIADSMobilePatrol:handleDeployScatterState(entry)
	local timedOut = timer.getTime() >= (entry.deployScatterDeadline or 0)
	local movedDistance = self:getDeployScatterDistanceMovedMeters(entry)
	local movedEnough = movedDistance >= (entry.deployScatterMinimumCompletionMeters or 0)
	if self:hasReachedDeployScatterDestination(entry) or (timedOut and movedEnough) then
		entry.state = "deployed"
		entry.currentDestination = nil
		entry.deployScatterStartPoint = nil
		entry.deployScatterDestination = nil
		entry.deployScatterDeadline = 0
		entry.deployScatterMinimumCompletionMeters = 0
		self:log("Deploy scatter complete for "..entry.groupName.." | moved="..mist.utils.round(movedDistance, 0).."m")
		self:notifyDebug(entry.groupName .. " 散开完成，进入战斗展开")
		return true
	end
	if timedOut then
		entry.deployScatterDeadline = timer.getTime() + SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS
	end
	return false
end

function SkynetIADSMobilePatrol:getSiblingInfo(entry)
	if SkynetIADSSiblingCoordination and SkynetIADSSiblingCoordination.getFamilyForElement then
		return SkynetIADSSiblingCoordination.getFamilyForElement(entry.element)
	end
	return nil
end

function SkynetIADSMobilePatrol:updateEntry(entry)
	if entry.element:isDestroyed() or entry.group == nil or entry.group:isExist() == false then
		return
	end

	local now = timer.getTime()
	local moveFireCapable = self:isMoveFireCapable(entry)

	if moveFireCapable and entry.element.harmSilenceID ~= nil and entry.element.harmRelocationInProgress ~= true then
		entry.state = "patrolling"
		entry.combatMode = "harm_silent"
		entry.noThreatSince = nil
		return
	end

	if self:isHarmEvading(entry) then
		entry.state = "harm_evading"
		entry.noThreatSince = nil
		return
	end

	if entry.state == "deploy_scattering" then
		if self:handleDeployScatterState(entry) ~= true then
			if entry.kind == "MSAM" then
				local threatDecision = self:findSAMThreatContact(entry)
				if threatDecision and threatDecision.shouldGoLive == true then
					self:applyMSAMThreatDecision(entry, threatDecision, true)
				end
			end
			entry.noThreatSince = nil
			entry.lastThreatTime = timer.getTime()
			return
		end
	end

	local siblingInfo = self:getSiblingInfo(entry)
	local siblingPassiveRelocate = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "relocate"
	local siblingPassiveHold = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "hold_dark"
	local siblingPassiveStandby = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "standby"

	if siblingPassiveHold then
		entry.combatCommitted = false
		entry.combatNoTargetSince = nil
		entry.noThreatSince = nil
		if entry.state == "deployed" then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		end
		return
	end

	if siblingPassiveStandby then
		entry.combatCommitted = false
		entry.combatNoTargetSince = nil
		entry.noThreatSince = nil
		entry.lastThreatTime = now
		if entry.state ~= "deployed" then
			entry.state = "deployed"
			entry.combatMode = "sibling_standby"
		end
		return
	end

	if siblingPassiveRelocate and entry.state ~= "patrolling" then
		self:beginPatrol(entry)
		return
	end

	if entry.mobileLockUntil and entry.mobileLockUntil > now then
		if entry.state ~= "patrolling" then
			self:beginPatrol(entry)
		end
		entry.noThreatSince = nil
		entry.combatNoTargetSince = nil
		return
	end
	entry.mobileLockUntil = 0

	local threatPresent = false
	if entry.kind == "MSAM" and siblingPassiveRelocate ~= true then
		local threatDecision = nil
		local allowThreatScan = true
		if siblingInfo ~= nil and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.arbitrateThreatDecision then
			local okArbitrate, arbitratedDecision, arbitratedAllowed = pcall(function()
				return _G.redIADSSiblingCoordination:arbitrateThreatDecision(entry.element)
			end)
			if okArbitrate then
				threatDecision = arbitratedDecision
				allowThreatScan = arbitratedAllowed ~= false
			end
		end
		if threatDecision == nil and allowThreatScan then
			threatDecision = self:findSAMThreatContact(entry)
		end

		if entry.combatCommitted == true then
			local combatThreatPresent = self:hasSAMCombatThreat(entry)
			if combatThreatPresent == true then
				entry.combatNoTargetSince = nil
			else
				if entry.combatNoTargetSince == nil then
					entry.combatNoTargetSince = now
				elseif (now - entry.combatNoTargetSince) >= entry.combatExitNoTargetSeconds then
					entry.combatCommitted = false
					entry.combatNoTargetSince = nil
					entry.mobileLockUntil = now + entry.postCombatMobileSeconds
					entry.combatMode = "patrolling"
					entry.debugLastCombatAnnouncementKey = nil
					self:notifyDebug(entry.groupName .. " combat exit -> mobile")
					self:beginPatrol(entry)
					if _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
						pcall(function()
							_G.redIADSSiblingCoordination:requestImmediateEvaluation("combat_exit:" .. tostring(entry.groupName))
						end)
					end
					return
				end
			end

			if threatDecision == nil or threatDecision.shouldGoLive ~= true then
				local triggerInfo = threatDecision and threatDecision.triggerInfo or entry.lastDeployTrigger or nil
				if triggerInfo then
					triggerInfo.combatMode = "combat_latched"
				end
				threatDecision = {
					contact = threatDecision and threatDecision.contact or nil,
					triggerInfo = triggerInfo,
					shouldDeploy = true,
					shouldGoLive = true,
					shouldWeaponHold = false,
					combatMode = "combat_latched",
				}
			end
		else
			entry.combatNoTargetSince = nil
		end

		threatPresent = threatDecision ~= nil
		if threatDecision then
			self:applyMSAMThreatDecision(entry, threatDecision)
			return
		elseif self:isMoveFireCapable(entry) and entry.combatMode ~= "patrolling" then
			forceElementIntoPatrolDarkState(entry.element)
			entry.combatMode = "patrolling"
			entry.debugLastCombatAnnouncementKey = nil
		end
	elseif entry.kind ~= "MSAM" then
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
		if self:isMoveFireCapable(entry) then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		else
			entry.state = "deployed"
		end
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
		combatCommitted = false,
		combatNoTargetSince = nil,
		mobileLockUntil = 0,
		combatExitNoTargetSeconds = (options and options.combatExitNoTargetSeconds) or self.defaultCombatExitNoTargetSeconds,
		postCombatMobileSeconds = (options and options.postCombatMobileSeconds) or self.defaultPostCombatMobileSeconds,
		lastThreatTime = 0,
		noThreatSince = nil,
		lastRouteIssueTime = nil,
		lastRouteIssueReferencePoint = nil,
		deployScatterStartPoint = nil,
		deployScatterDestination = nil,
		deployScatterDeadline = 0,
		deployScatterMinimumCompletionMeters = 0,
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
		defaultCombatExitNoTargetSeconds = (config and config.defaultCombatExitNoTargetSeconds) or SkynetIADSMobilePatrol.DEFAULT_COMBAT_EXIT_NO_TARGET_SECONDS,
		defaultPostCombatMobileSeconds = (config and config.defaultPostCombatMobileSeconds) or SkynetIADSMobilePatrol.DEFAULT_POST_COMBAT_MOBILE_SECONDS,
		defaultArrivalToleranceMeters = (config and config.defaultArrivalToleranceMeters) or SkynetIADSMobilePatrol.DEFAULT_ARRIVAL_TOLERANCE_METERS,
		defaultRouteReissueSeconds = (config and config.defaultRouteReissueSeconds) or SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS,
		defaultMinMovementMeters = (config and config.defaultMinMovementMeters) or SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS,
		defaultPatrolRefreshDelays = (config and config.defaultPatrolRefreshDelays) or SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS,
		moveFireNatoNames = mist.utils.deepCopy((config and config.moveFireNatoNames) or SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_NATO_NAMES),
		moveFireLauncherTypeNames = mist.utils.deepCopy((config and config.moveFireLauncherTypeNames) or SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_LAUNCHER_TYPE_NAMES),
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
		local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
		if entry and entry.kind == "MSAM" and isAirContact(contact) == false then
			return nil
		end
		if entry and entry.kind == "MSAM" then
			local profile = entry.manager:getMSAMCombatProfile(entry)
			if profile and isAirContact(contact) and contact:isIdentifiedAsHARM() == false and self:areGoLiveConstraintsSatisfied(contact) == true then
				local contactDistanceMeters = entry.manager:getContactDistanceMeters(entry, contact)
				local directUnit, directUnitDistanceMeters = entry.manager:findNearestEnemyAircraftUnit(entry, profile.alertRangeMeters)
				local effectiveDistanceMeters = contactDistanceMeters
				if directUnit ~= nil and directUnitDistanceMeters < effectiveDistanceMeters then
					effectiveDistanceMeters = directUnitDistanceMeters
				end
				if effectiveDistanceMeters <= profile.alertRangeMeters then
					if entry.state == "patrolling" and moveFireCapable ~= true then
						entry.manager:pausePatrolForDeployment(
							entry,
							entry.manager:buildDeployTriggerInfo(entry, contact, "inform_of_contact_alert")
						)
					end
					if effectiveDistanceMeters <= profile.engageRangeMeters then
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
				isAirContact(contact)
				and
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
		if shouldDeployFromThisContact and moveFireCapable ~= true then
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
	local function goSilentToEvadeHARMWhileMoving(element, timeToImpact)
		local now = timer.getTime()
		if element.harmSilenceID ~= nil or element.harmRelocationInProgress == true then
			return false
		end
		if element.harmReactionLockUntil ~= nil and now < element.harmReactionLockUntil then
			return false
		end
		element.harmReactionLockUntil = now + element.harmReactionCooldownSeconds
		element.minHarmShutdownTime = element:calculateMinimalShutdownTimeInSeconds(timeToImpact)
		element.maxHarmShutDownTime = element:calculateMaximalShutdownTimeInSeconds(element.minHarmShutdownTime)
		element.harmShutdownTime = element:calculateHARMShutdownTime()
		if element.iads:getDebugSettings().harmDefence then
			element.iads:printOutputToLog("HARM DEFENCE SHUTDOWN + CONTINUE MOVING: "..element:getDCSName().." | FOR: "..element.harmShutdownTime.." seconds | TTI: "..timeToImpact)
		end
		element.harmSilenceID = mist.scheduleFunction(SkynetIADSAbstractRadarElement.finishHarmDefence, {element}, timer.getTime() + element.harmShutdownTime, 1)
		setElementMovingSilenceState(element)
		return true
	end

	function SkynetIADSAbstractRadarElement:goSilentToEvadeHARM(timeToImpact)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local shouldAnnounce = false
		local moveFireCapable = false
		if entry then
			shouldAnnounce = entry.debugHarmActive ~= true
			moveFireCapable = entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
		end
		local result
		if moveFireCapable then
			result = goSilentToEvadeHARMWhileMoving(self, timeToImpact)
		else
			result = originalGoSilentToEvadeHARM(self, timeToImpact)
		end
		if result ~= false and entry and (self.harmRelocationInProgress == true or moveFireCapable) then
			if moveFireCapable then
				entry.state = "patrolling"
				entry.combatMode = "harm_silent"
			else
				entry.state = "harm_evading"
			end
			entry.noThreatSince = nil
			entry.debugHarmActive = true
			entry.debugLastCombatAnnouncementKey = nil
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " 进入HARM规避")
			end
		end
		if result ~= false and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
			pcall(function()
				_G.redIADSSiblingCoordination:requestImmediateEvaluation("harm_evade_start:" .. tostring(self:getDCSName()))
			end)
		end
		return result
	end

	local originalFinishHarmDefence = SkynetIADSAbstractRadarElement.finishHarmDefence
	function SkynetIADSAbstractRadarElement.finishHarmDefence(self)
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local shouldAnnounce = entry and entry.debugHarmActive == true
		local result = originalFinishHarmDefence(self)
		if entry then
			if entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true then
				entry.state = "patrolling"
				entry.combatMode = "patrolling"
			end
			entry.debugHarmActive = false
			entry.debugLastCombatAnnouncementKey = nil
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " HARM规避结束")
			end
		end
		if _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
			pcall(function()
				_G.redIADSSiblingCoordination:requestImmediateEvaluation("harm_evade_end:" .. tostring(self:getDCSName()))
			end)
		end
		return result
	end
end

SkynetIADSMobilePatrol.installHooks()
MobileIADSPatrol = SkynetIADSMobilePatrol
trigger.action.outText("Skynet Mobile Patrol module loaded", 10)

end
