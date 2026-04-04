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
SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_SECONDS = 30
SkynetIADSMobilePatrol.DEFAULT_MIN_MOVEMENT_METERS = 25
SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_FALLBACK_COUNT = 2
SkynetIADSMobilePatrol.DEFAULT_PATROL_REFRESH_DELAYS = { 3, 10 }
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_DISTANCE_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_FORM = "Diamond"
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS = 1
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_MIN_COMPLETION_METERS = 60
SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS = 20
SkynetIADSMobilePatrol.DEFAULT_DEPLOY_FORMATION_INTERVAL_METERS = 100
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_CONTACT_LATCH_SECONDS = 4
SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_ROUTE_RESUME_COOLDOWN_SECONDS = 8
SkynetIADSMobilePatrol.DEFAULT_POST_LAUNCH_LIVE_HOLD_SECONDS = 12
SkynetIADSMobilePatrol.DEFAULT_CONTACT_FEED_REISSUE_SECONDS = 5
SkynetIADSMobilePatrol.DEFAULT_LAUNCH_READY_STABLE_SECONDS = 8
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
	return startsWith(samSite:getDCSName(), prefix)
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
						local isAlive = false
						local isInAir = false
						if unit and unit:isExist() then
							local okLife, life = pcall(function()
								return unit:getLife()
							end)
							if okLife and type(life) == "number" and life > 0 then
								isAlive = true
							end
							local okInAir, inAir = pcall(function()
								return unit:inAir()
							end)
							if okInAir and inAir == true then
								isInAir = true
							end
						end
						if isAlive and isInAir then
							airUnits[#airUnits + 1] = unit
						end
					end
				end
			end
		end
	end
	return airUnits
end

local function getUnitSpeedMetersPerSecond(unit)
	if unit == nil or unit.isExist == nil or unit:isExist() == false or unit.getVelocity == nil then
		return math.huge
	end
	local okVelocity, velocity = pcall(function()
		return unit:getVelocity()
	end)
	if okVelocity ~= true or velocity == nil then
		return math.huge
	end
	local x = velocity.x or 0
	local y = velocity.y or 0
	local z = velocity.z or 0
	return math.sqrt((x * x) + (y * y) + (z * z))
end

local function getUnitAltitudeAGLMeters(unit)
	if unit == nil or unit.isExist == nil or unit:isExist() == false or unit.getPoint == nil then
		return math.huge
	end
	local okPoint, point = pcall(function()
		return unit:getPoint()
	end)
	if okPoint ~= true or point == nil or point.x == nil or point.z == nil then
		return math.huge
	end
	local terrainHeight = land.getHeight({ x = point.x, y = point.z }) or 0
	local altitudeAGL = (point.y or 0) - terrainHeight
	if altitudeAGL < 0 then
		altitudeAGL = 0
	end
	return altitudeAGL
end

local function isLikelyGroundedResidualAirUnit(unit)
	return getUnitAltitudeAGLMeters(unit) <= 5 and getUnitSpeedMetersPerSecond(unit) <= 20
end

local function toRoundedNm(distanceMeters)
	if distanceMeters == nil or distanceMeters == math.huge then
		return nil
	end
	return mist.utils.round(mist.utils.metersToNM(distanceMeters), 1)
end

local function resetMoveFireContactSession(entry)
	if entry == nil then
		return
	end
	entry.moveFireContactActive = false
	entry.moveFireLastSeenTime = nil
	entry.moveFireLastContactName = nil
	entry.moveFireRouteResumeLockUntil = 0
end

local function hasRecentMoveFireContactSession(entry, now)
	if entry == nil or entry.moveFireContactActive ~= true or entry.moveFireLastSeenTime == nil then
		return false
	end
	now = now or timer.getTime()
	return (now - entry.moveFireLastSeenTime) <= SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_CONTACT_LATCH_SECONDS
end

local function touchMoveFireContactSession(entry, contact)
	if entry == nil then
		return
	end
	entry.moveFireContactActive = true
	entry.moveFireLastSeenTime = timer.getTime()
	if entry.manager and entry.manager.getContactName then
		entry.moveFireLastContactName = entry.manager:getContactName(contact)
	end
end

local function shouldIssueMoveFireRouteResume(entry, element, now)
	if entry == nil then
		return false
	end
	now = now or timer.getTime()
	if entry.combatMode == "harm_silent" or entry.debugHarmActive == true then
		return false
	end
	if element and (element.harmSilenceID ~= nil or element.harmRelocationInProgress == true) then
		return false
	end
	return entry.moveFireRouteResumeLockUntil == nil or now >= entry.moveFireRouteResumeLockUntil
end

local function markMoveFireRouteResumeIssued(entry, now)
	if entry == nil then
		return
	end
	now = now or timer.getTime()
	entry.moveFireRouteResumeLockUntil =
		now + SkynetIADSMobilePatrol.DEFAULT_MOVE_FIRE_ROUTE_RESUME_COOLDOWN_SECONDS
end

local function setThreatProbeCandidate(details, prefix, name, typeName, distanceMeters)
	if details == nil or prefix == nil then
		return
	end
	details[prefix .. "Candidate"] = name or "none"
	details[prefix .. "CandidateType"] = typeName or "unknown"
	local distanceNm = toRoundedNm(distanceMeters)
	if distanceNm ~= nil then
		details[prefix .. "CandidateDistanceNm"] = distanceNm
	end
end

local function toThreatProbeSignatureValue(value)
	if value == nil then
		return "-"
	end
	return tostring(value)
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
	if representation.getCategory ~= nil then
		local okCategory, categoryId = pcall(function()
			return representation:getCategory()
		end)
		if okCategory ~= true or categoryId ~= Object.Category.UNIT then
			return false
		end
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

local function isLikelyGroundedResidualAirContact(contact)
	if contact == nil then
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
	if representation.getCategory ~= nil then
		local okCategory, categoryId = pcall(function()
			return representation:getCategory()
		end)
		if okCategory ~= true or categoryId ~= Object.Category.UNIT then
			return false
		end
	end
	return isLikelyGroundedResidualAirUnit(representation)
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

local function getGroundOpenFireROEValue()
	local groundROE = AI.Option and AI.Option.Ground and AI.Option.Ground.val and AI.Option.Ground.val.ROE or nil
	if groundROE == nil then
		return nil
	end
	return groundROE.WEAPON_FREE or groundROE.OPEN_FIRE
end

local function setGroundROE(controller, weaponHold)
	local roeValue = weaponHold and AI.Option.Ground.val.ROE.WEAPON_HOLD or getGroundOpenFireROEValue()
	if roeValue == nil then
		return
	end
	pcall(function()
		controller:setOption(
			AI.Option.Ground.id.ROE,
			roeValue
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
		setPatrolAlarmState(controller)
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
	element.aiState = true
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
	local wasActive = element.aiState == true
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
	if wasActive ~= true then
		element.goLiveTime = timer.getTime()
	end
	element.aiState = true
	if element.pointDefencesStopActingAsEW then
		element:pointDefencesStopActingAsEW()
	end
	if wasActive ~= true and element.scanForHarms then
		element:scanForHarms()
	end
end

local applyPatrolOptionsToRepresentation

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

applyPatrolOptionsToRepresentation = function(representation)
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

function SkynetIADSMobilePatrol:withOrderTraceOrigin(details, functionName)
	local payload = {}
	if details then
		for key, value in pairs(details) do
			payload[key] = value
		end
	end
	payload.originModule = payload.originModule or "skynet-iads-mobile-patrol.lua"
	payload.originFunction = payload.originFunction or functionName
	return payload
end

function SkynetIADSMobilePatrol:buildOrderTraceContext(entry, reason, details)
	local context = {
		reason = reason,
	}
	if details == nil then
		return context
	end
	if details.source ~= nil then
		context.source = details.source
	end
	if details.note ~= nil then
		context.note = details.note
	end
	if details.originModule ~= nil then
		context.originModule = details.originModule
	end
	if details.originFunction ~= nil then
		context.originFunction = details.originFunction
	end
	if details.destination ~= nil then
		context.destination = details.destination
	end
	if details.triggerInfo ~= nil then
		context.triggerInfo = details.triggerInfo
	end
	if details.threatDecision ~= nil then
		local threatDecision = details.threatDecision
		context.shouldDeploy = threatDecision.shouldDeploy == true and "Y" or "N"
		context.shouldGoLive = threatDecision.shouldGoLive == true and "Y" or "N"
		context.weaponHold = threatDecision.shouldWeaponHold == true and "Y" or "N"
		context.combatMode = threatDecision.combatMode or context.combatMode
		if threatDecision.triggerInfo ~= nil then
			context.triggerInfo = threatDecision.triggerInfo
		end
	end
	return context
end

function SkynetIADSMobilePatrol:setOrderTraceContext(entry, reason, details, functionName)
	if entry == nil then
		return
	end
	local context = self:buildOrderTraceContext(entry, reason, self:withOrderTraceOrigin(details, functionName))
	entry._skynetOrderTraceContext = context
	if self.iads and self.iads.setOrderTraceContext then
		self.iads:setOrderTraceContext(entry.element, context)
	end
end

function SkynetIADSMobilePatrol:traceEntryCommand(entry, command, details, functionName)
	if self.iads and self.iads.traceEntryCommand then
		return self.iads:traceEntryCommand(entry, command, self:withOrderTraceOrigin(details, functionName))
	end
	return false
end

function SkynetIADSMobilePatrol:traceStateSnapshot(entry, reason, details, functionName)
	if entry == nil then
		return false
	end
	local siblingInfo = self:getSiblingInfo(entry)
	local key = table.concat({
		tostring(entry.state),
		tostring(entry.combatMode),
		tostring(reason),
		tostring(entry.combatCommitted == true),
		tostring(entry.mobileLockUntil and entry.mobileLockUntil > timer.getTime()),
		tostring(siblingInfo and siblingInfo.role or "none"),
		tostring(siblingInfo and siblingInfo.passiveMode or "none"),
		tostring(entry.element and (entry.element.harmSilenceID ~= nil or entry.element.harmRelocationInProgress == true) or false),
	}, "|")
	if entry.debugLastStateTraceKey == key then
		return false
	end
	entry.debugLastStateTraceKey = key
	local payload = {
		event = "state_change",
		command = "state_eval",
		outcome = "entered",
		reason = reason,
	}
	if siblingInfo then
		payload.family = siblingInfo.name
		payload.familyMode = siblingInfo.mode
		payload.familyRole = siblingInfo.role
		payload.familyReason = siblingInfo.reason
		payload.passiveMode = siblingInfo.passiveMode
	end
	if entry.mobileLockUntil and entry.mobileLockUntil > timer.getTime() then
		payload.note = "mobileLockUntil=" .. tostring(mist.utils.round(entry.mobileLockUntil - timer.getTime(), 1)) .. "s"
	end
	if details then
		for keyName, value in pairs(details) do
			payload[keyName] = value
		end
	end
	return self:traceEntryCommand(entry, "state_eval", payload, functionName or "traceStateSnapshot")
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
	local action = moveFireCapable and "moving alert" or "deploy alert"
	if shouldGoLive then
		if moveFireCapable then
			action = shouldWeaponHold and "moving track" or "moving engage"
		else
			action = shouldWeaponHold and "track hold" or "engage fire"
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

function SkynetIADSMobilePatrol:selectNearestWaypointIndex(entry)
	if #entry.routePoints <= 1 then
		return 1
	end
	local nearestIndex = 1
	local nearestDistance = math.huge
	for i = 1, #entry.routePoints do
		local distance = self:getWaypointDistance(entry, entry.routePoints[i])
		if distance < nearestDistance then
			nearestDistance = distance
			nearestIndex = i
		end
	end
	return nearestIndex
end

function SkynetIADSMobilePatrol:getPatrolRouteForm(entry)
	if entry and entry.patrolRouteMode == "off_road" then
		return "off_road"
	end
	return "On Road"
end

function SkynetIADSMobilePatrol:buildPatrolRoute(entry, startIndex, form, prependCurrentPoint)
	if entry == nil or #entry.routePoints == 0 then
		return nil
	end
	local route = {}
	local speedMps = mist.utils.kmphToMps(entry.patrolSpeedKmph)
	if prependCurrentPoint == true then
		local currentPoint = self:getPatrolReferencePoint(entry)
		if currentPoint then
			route[#route + 1] = mist.ground.buildWP(currentPoint, form, speedMps)
		end
	end
	for offset = 0, (#entry.routePoints - 1) do
		local index = ((startIndex - 1 + offset) % #entry.routePoints) + 1
		local point = entry.routePoints[index]
		if point then
			route[#route + 1] = mist.ground.buildWP(point, form, speedMps)
		end
	end
	return #route > 0 and route or nil
end

function SkynetIADSMobilePatrol:buildRoadPatrolRoute(entry, startIndex)
	return self:buildPatrolRoute(entry, startIndex, "On Road", false)
end

function SkynetIADSMobilePatrol:buildOffRoadPatrolRoute(entry, startIndex, prependCurrentPoint)
	return self:buildPatrolRoute(entry, startIndex, "off_road", prependCurrentPoint == true)
end

function SkynetIADSMobilePatrol:issueRoadMove(entry, destination)
	if entry.group == nil or entry.group:isExist() == false or destination == nil then
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing group or destination")
		self:traceEntryCommand(entry, "road_move", {
			outcome = "skipped",
			destination = destination,
			note = "missing group or destination",
		}, "issueRoadMove")
		return false
	end
	local startPoint = self:getPatrolReferencePoint(entry)
	if startPoint == nil then
		self:log("Road move skipped for "..tostring(entry.groupName).." | missing start point")
		self:traceEntryCommand(entry, "road_move", {
			outcome = "skipped",
			destination = destination,
			note = "missing start point",
		}, "issueRoadMove")
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
	self:traceEntryCommand(entry, "road_move", {
		outcome = ok and "issued" or "failed",
		destination = destination,
		speedKmph = entry.patrolSpeedKmph,
	}, "issueRoadMove")
	return ok
end

function SkynetIADSMobilePatrol:issuePatrolRoute(entry)
	if entry.group == nil or entry.group:isExist() == false then
		self:log("Patrol route skipped for "..tostring(entry.groupName).." | missing group")
		self:traceEntryCommand(entry, "patrol_route", {
			outcome = "skipped",
			note = "missing group",
		}, "issuePatrolRoute")
		return false
	end
	local routeMode = entry.patrolRouteMode or "road"
	local routeForm = self:getPatrolRouteForm(entry)
	local startIndex = entry.currentWaypointIndex or 1
	local ok = pcall(function()
		if routeMode == "off_road" then
			local route = self:buildOffRoadPatrolRoute(entry, startIndex, true)
			if route == nil then
				error("missing off-road patrol route")
			end
			mist.ground.patrolRoute({
				gpData = entry.groupName,
				route = route,
				speed = mist.utils.kmphToMps(entry.patrolSpeedKmph),
			})
			return
		end
		local route = self:buildRoadPatrolRoute(entry, startIndex)
		if route == nil then
			error("missing road patrol route")
		end
		mist.ground.patrolRoute({
			gpData = entry.groupName,
			route = route,
			speed = mist.utils.kmphToMps(entry.patrolSpeedKmph),
		})
	end)
	if ok then
		entry.currentDestination = nil
		entry.lastRouteIssueTime = timer.getTime()
		entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
		self:log("Patrol route issued for "..entry.groupName.." | mode="..routeMode.." | wp="..tostring(startIndex).." | speed="..entry.patrolSpeedKmph.."km/h")
	else
		self:log("Patrol route failed for "..entry.groupName.." | mode="..routeMode.." | wp="..tostring(startIndex))
	end
	self:traceEntryCommand(entry, "patrol_route", {
		outcome = ok and "issued" or "failed",
		speedKmph = entry.patrolSpeedKmph,
		routeMode = routeMode,
		routeForm = routeForm,
		waypoint = startIndex,
	}, "issuePatrolRoute")
	return ok
end

function SkynetIADSMobilePatrol:shouldReissuePatrolRoute(entry)
	if entry.lastRouteIssueTime == nil or entry.lastRouteIssueReferencePoint == nil then
		return false, nil, nil
	end
	local elapsedSeconds = timer.getTime() - entry.lastRouteIssueTime
	if elapsedSeconds < self.defaultRouteReissueSeconds then
		return false, nil, elapsedSeconds
	end
	local currentPoint = self:getPatrolReferencePoint(entry)
	if currentPoint == nil then
		return false, nil, elapsedSeconds
	end
	local movedDistance = mist.utils.get2DDist(currentPoint, entry.lastRouteIssueReferencePoint)
	if movedDistance >= self.defaultMinMovementMeters then
		entry.stationaryReissueCount = 0
		return false, movedDistance, elapsedSeconds
	end
	return true, movedDistance, elapsedSeconds
end

function SkynetIADSMobilePatrol:handlePatrolStationaryRecovery(entry, source)
	local shouldReissue, movedDistance, elapsedSeconds = self:shouldReissuePatrolRoute(entry)
	if shouldReissue ~= true then
		return false
	end

	entry.stationaryReissueCount = (entry.stationaryReissueCount or 0) + 1
	local stationaryCount = entry.stationaryReissueCount
	local fallbackTriggered = false
	local forcedAdvance = false
	if stationaryCount >= self.defaultRouteReissueFallbackCount and entry.patrolRouteMode ~= "off_road" then
		entry.patrolRouteMode = "off_road"
		fallbackTriggered = true
	end
	if entry.patrolRouteMode == "off_road" then
		if fallbackTriggered then
			entry.currentWaypointIndex = self:selectNearestWaypointIndex(entry)
		elseif stationaryCount > self.defaultRouteReissueFallbackCount and #entry.routePoints > 1 then
			entry.currentWaypointIndex = ((entry.currentWaypointIndex or 1) % #entry.routePoints) + 1
			forcedAdvance = self:advancePatrol(entry, true) == true
		end
	end

	local roundedMovedDistance = movedDistance and mist.utils.round(movedDistance, 1) or nil
	local roundedElapsedSeconds = elapsedSeconds and mist.utils.round(elapsedSeconds, 1) or nil
	local note = "elapsed="..tostring(roundedElapsedSeconds).."s moved="..tostring(roundedMovedDistance).."m count="..tostring(stationaryCount).." mode="..tostring(entry.patrolRouteMode or "road")
	if entry.patrolRouteMode == "off_road" then
		note = note .. " wp=" .. tostring(entry.currentWaypointIndex)
	end
	if forcedAdvance then
		note = note .. " forcedAdvance=Y"
	end
	self:log("Patrol route reissued for "..entry.groupName.." | source="..tostring(source).." | moved="..tostring(roundedMovedDistance).."m | elapsed="..tostring(roundedElapsedSeconds).."s | count="..tostring(stationaryCount).." | mode="..tostring(entry.patrolRouteMode or "road"))
	self:traceEntryCommand(entry, "patrol_reissue_stationary", {
		event = "decision",
		outcome = "reissue",
		source = source,
		movedMeters = roundedMovedDistance,
		elapsedSeconds = roundedElapsedSeconds,
		stationaryCount = stationaryCount,
		routeMode = entry.patrolRouteMode or "road",
		waypoint = entry.currentWaypointIndex,
		fallbackTriggered = fallbackTriggered and "Y" or "N",
		forcedAdvance = forcedAdvance and "Y" or "N",
	}, "handlePatrolStationaryRecovery")
	self:setOrderTraceContext(entry, "patrol_reissue_stationary", {
		source = source,
		note = note,
	}, "handlePatrolStationaryRecovery")
	if forcedAdvance == true then
		return true
	end
	self:issuePatrolRoute(entry)
	return true
end

function SkynetIADSMobilePatrol:issueHold(entry)
	local holdPoint = self:getPatrolReferencePoint(entry)
	if entry.group == nil or entry.group:isExist() == false or holdPoint == nil then
		self:traceEntryCommand(entry, "hold", {
			outcome = "skipped",
			destination = holdPoint,
			note = "missing group or hold point",
		}, "issueHold")
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
	self:traceEntryCommand(entry, "hold", {
		outcome = ok and "issued" or "failed",
		destination = holdPoint,
	}, "issueHold")
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
		self:traceEntryCommand(entry, "deploy_scatter", {
			outcome = "skipped",
			note = "missing group",
		}, "issueDeployScatter")
		return false
	end
	local destination, distanceMeters, startPoint = self:calculateDeployScatterPoint(entry)
	if destination == nil then
		self:traceEntryCommand(entry, "deploy_scatter", {
			outcome = "skipped",
			note = "no valid destination",
		}, "issueDeployScatter")
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
	self:traceEntryCommand(entry, "deploy_scatter", {
		outcome = ok and "issued" or "failed",
		destination = destination,
		speedKmph = speedKmph,
		note = distanceMeters and ("distance=" .. tostring(distanceMeters) .. "m") or nil,
	}, "issueDeployScatter")
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

function SkynetIADSMobilePatrol:getUnitName(unit)
	if unit == nil then
		return "unknown"
	end
	local targetName = "unknown"
	local okName, name = pcall(function()
		return unit:getName()
	end)
	if okName and name then
		targetName = name
	end
	return targetName
end

function SkynetIADSMobilePatrol:getContactTypeName(contact)
	if contact == nil then
		return "unknown"
	end
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return contact:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return targetType
end

function SkynetIADSMobilePatrol:getUnitTypeName(unit)
	if unit == nil then
		return "unknown"
	end
	local targetType = "unknown"
	local okType, typeName = pcall(function()
		return unit:getTypeName()
	end)
	if okType and typeName then
		targetType = typeName
	end
	return targetType
end

function SkynetIADSMobilePatrol:traceAirUnitTrack(entry, unit, distanceMeters, details, functionName)
	if entry == nil or unit == nil or self.iads == nil or self.iads.traceAirUnit == nil then
		return false
	end
	local payload = details or {}
	payload.originModule = payload.originModule or "skynet-iads-mobile-patrol"
	payload.originFunction = payload.originFunction or functionName or "traceAirUnitTrack"
	payload.observerGroup = payload.observerGroup or entry.groupName
	payload.observerKind = payload.observerKind or entry.kind
	payload.source = payload.source or "direct_unit_scan"
	payload.distanceNm = payload.distanceNm or toRoundedNm(distanceMeters)
	return self.iads:traceAirUnit(unit, payload)
end

function SkynetIADSMobilePatrol:traceThreatProbe(entry, details)
	if entry == nil then
		return false
	end
	local payload = details or {}
	payload.event = payload.event or "decision"
	payload.outcome = payload.outcome or "observed"
	payload.reason = payload.reason or "sam_threat_probe"
	payload.source = payload.source or "findSAMThreatContact"
	local signature = table.concat({
		toThreatProbeSignatureValue(payload.outcome),
		toThreatProbeSignatureValue(payload.selectedBy),
		toThreatProbeSignatureValue(payload.rejectReason),
		toThreatProbeSignatureValue(payload.matchedContactSource),
		toThreatProbeSignatureValue(payload.rawDirectCandidate),
		toThreatProbeSignatureValue(payload.rawDirectCandidateDistanceNm),
		toThreatProbeSignatureValue(payload.rawContactCandidate),
		toThreatProbeSignatureValue(payload.rawContactCandidateDistanceNm),
		toThreatProbeSignatureValue(payload.directCandidate),
		toThreatProbeSignatureValue(payload.directCandidateDistanceNm),
		toThreatProbeSignatureValue(payload.contactCandidate),
		toThreatProbeSignatureValue(payload.contactCandidateDistanceNm),
		toThreatProbeSignatureValue(payload.contact),
		toThreatProbeSignatureValue(payload.distanceNm),
		toThreatProbeSignatureValue(payload.shouldGoLive),
		toThreatProbeSignatureValue(payload.weaponHold),
	}, "|")
	local now = timer.getTime()
	if entry.lastThreatProbeSignature == signature and entry.lastThreatProbeTime ~= nil and (now - entry.lastThreatProbeTime) < 5 then
		return false
	end
	entry.lastThreatProbeSignature = signature
	entry.lastThreatProbeTime = now
	return self:traceEntryCommand(entry, "threat_probe", payload, "traceThreatProbe")
end

function SkynetIADSMobilePatrol:traceCombatExitCheck(entry, details, originFunction)
	if entry == nil then
		return false
	end
	local payload = details or {}
	payload.event = payload.event or "decision"
	payload.outcome = payload.outcome or "observed"
	payload.reason = payload.reason or "combat_exit_check"
	payload.source = payload.source or "combat_scan"
	return self:traceEntryCommand(entry, "combat_exit_check", payload, originFunction or "traceCombatExitCheck")
end

function SkynetIADSMobilePatrol:traceLaunchMonitor(entry, details, originFunction)
	if entry == nil then
		return false
	end
	local payload = details or {}
	payload.event = payload.event or "decision"
	payload.outcome = payload.outcome or "observed"
	payload.reason = payload.reason or "launch_monitor"
	payload.source = payload.source or "combat_launch_gate"
	local signature = table.concat({
		toThreatProbeSignatureValue(payload.outcome),
		toThreatProbeSignatureValue(payload.contact),
		toThreatProbeSignatureValue(payload.distanceNm),
		toThreatProbeSignatureValue(payload.targetsInRange),
		toThreatProbeSignatureValue(payload.missilesInFlight),
		toThreatProbeSignatureValue(payload.launchReady),
		toThreatProbeSignatureValue(payload.launchConstraintOk),
		toThreatProbeSignatureValue(payload.launchRangeCheck),
		toThreatProbeSignatureValue(payload.launchReadyLatched),
		toThreatProbeSignatureValue(payload.launchReadySinceSeconds),
		toThreatProbeSignatureValue(payload.launchDroppedSinceSeconds),
	}, "|")
	local now = timer.getTime()
	if entry.lastLaunchMonitorSignature == signature and entry.lastLaunchMonitorTime ~= nil and (now - entry.lastLaunchMonitorTime) < 3 then
		return false
	end
	entry.lastLaunchMonitorSignature = signature
	entry.lastLaunchMonitorTime = now
	return self:traceEntryCommand(entry, "launch_monitor", payload, originFunction or "traceLaunchMonitor")
end

function SkynetIADSMobilePatrol:refreshThreatContact(contact)
	if contact == nil or contact.refresh == nil then
		return false
	end
	local okRefresh = pcall(function()
		contact:refresh()
	end)
	return okRefresh == true
end

function SkynetIADSMobilePatrol:doesContactMatchUnit(contact, unit)
	if contact == nil or unit == nil then
		return false
	end

	local contactName = self:getContactName(contact)
	local unitName = self:getUnitName(unit)
	if contactName ~= "unknown" and unitName ~= "unknown" and contactName == unitName then
		return true
	end

	local contactRepresentation = nil
	local okContactRepresentation = pcall(function()
		contactRepresentation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okContactRepresentation == true and contactRepresentation ~= nil then
		if contactRepresentation == unit then
			return true
		end

		local okContactId, contactId = pcall(function()
			return contactRepresentation:getID()
		end)
		local okUnitId, unitId = pcall(function()
			return unit:getID()
		end)
		if okContactId == true and okUnitId == true and contactId ~= nil and contactId == unitId then
			return true
		end
	end

	return false
end

function SkynetIADSMobilePatrol:findMatchingEligibleContact(entry, unit, maxDistanceMeters)
	if entry == nil or unit == nil then
		return nil, math.huge, nil
	end

	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and isLikelyGroundedResidualAirContact(contact) ~= true
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact)
			and self:doesContactMatchUnit(contact, unit) then
			self:refreshThreatContact(contact)
			local distanceMeters = self:getContactDistanceMeters(entry, contact)
			if maxDistanceMeters == nil or distanceMeters <= maxDistanceMeters then
				return contact, distanceMeters, "live_contact_match"
			end
		end
	end

	local cachedContact = entry.lastThreatContact
	if cachedContact
		and cachedContact.isExist
		and cachedContact:isExist()
		and isLikelyGroundedResidualAirContact(cachedContact) ~= true
		and cachedContact:isIdentifiedAsHARM() == false
		and entry.element:areGoLiveConstraintsSatisfied(cachedContact)
		and self:doesContactMatchUnit(cachedContact, unit) then
		self:refreshThreatContact(cachedContact)
		local distanceMeters = self:getContactDistanceMeters(entry, cachedContact)
		if maxDistanceMeters == nil or distanceMeters <= maxDistanceMeters then
			return cachedContact, distanceMeters, "cached_contact_match"
		end
	end

	return nil, math.huge, nil
end

function SkynetIADSMobilePatrol:getUnitDistanceMeters(entry, unit)
	local radarPoint = self:getPatrolReferencePoint(entry)
	local unitPoint = nil
	if unit and unit.getPoint then
		pcall(function()
			unitPoint = unit:getPoint()
		end)
	end
	if radarPoint and unitPoint then
		return mist.utils.get2DDist(radarPoint, unitPoint)
	end
	return math.huge
end

function SkynetIADSMobilePatrol:findCachedThreatContactFallback(entry, unit, maxDistanceMeters)
	if entry == nil or unit == nil then
		return nil, math.huge, nil
	end

	local cachedContact = entry.lastThreatContact
	if cachedContact == nil
		or cachedContact.isExist == nil
		or cachedContact:isExist() == false
		or isLikelyGroundedResidualAirContact(cachedContact) == true
		or cachedContact:isIdentifiedAsHARM() == true
		or entry.element:areGoLiveConstraintsSatisfied(cachedContact) ~= true then
		return nil, math.huge, nil
	end

	self:refreshThreatContact(cachedContact)
	local cachedDistanceMeters = self:getContactDistanceMeters(entry, cachedContact)
	if maxDistanceMeters ~= nil and cachedDistanceMeters > maxDistanceMeters then
		return nil, math.huge, nil
	end

	local unitDistanceMeters = self:getUnitDistanceMeters(entry, unit)
	local proximityToleranceMeters = mist.utils.NMToMeters(5)
	local contactType = self:getContactTypeName(cachedContact)
	local unitType = self:getUnitTypeName(unit)
	local compatibleType =
		contactType == "unknown"
		or unitType == "unknown"
		or contactType == unitType
	local distanceClose =
		unitDistanceMeters < math.huge
		and math.abs(cachedDistanceMeters - unitDistanceMeters) <= proximityToleranceMeters

	if self:doesContactMatchUnit(cachedContact, unit) or (compatibleType and distanceClose) then
		return cachedContact, cachedDistanceMeters, "cached_contact_fallback"
	end

	return nil, math.huge, nil
end

function SkynetIADSMobilePatrol:getReusableThreatContact(entry, triggerInfo)
	if entry == nil or triggerInfo == nil then
		return nil, math.huge
	end

	local cachedContact = entry.lastThreatContact
	if cachedContact == nil
		or cachedContact.isExist == nil
		or cachedContact:isExist() == false
		or isLikelyGroundedResidualAirContact(cachedContact) == true
		or cachedContact:isIdentifiedAsHARM() == true
		or entry.element:areGoLiveConstraintsSatisfied(cachedContact) ~= true then
		return nil, math.huge
	end

	self:refreshThreatContact(cachedContact)
	local cachedDistanceMeters = self:getContactDistanceMeters(entry, cachedContact)
	local expectedDistanceNm =
		triggerInfo.contactDistanceNm
		or triggerInfo.directDistanceNm
		or triggerInfo.effectiveDistanceNm
		or triggerInfo.distanceNm
	local expectedDistanceMeters = expectedDistanceNm and mist.utils.NMToMeters(expectedDistanceNm) or math.huge
	local proximityToleranceMeters = mist.utils.NMToMeters(5)
	local cachedName = self:getContactName(cachedContact)
	local expectedName = triggerInfo.contactName or triggerInfo.directUnitName
	local cachedType = self:getContactTypeName(cachedContact)
	local expectedType = triggerInfo.contactType
	local nameMatches =
		expectedName ~= nil
		and expectedName ~= "unknown"
		and cachedName ~= "unknown"
		and cachedName == expectedName
	local compatibleType =
		expectedType == nil
		or expectedType == "unknown"
		or cachedType == "unknown"
		or cachedType == expectedType
	local distanceClose =
		expectedDistanceMeters == math.huge
		or math.abs(cachedDistanceMeters - expectedDistanceMeters) <= proximityToleranceMeters

	if nameMatches or (compatibleType and distanceClose) then
		return cachedContact, cachedDistanceMeters
	end

	return nil, math.huge
end

function SkynetIADSMobilePatrol:informEntryOfThreatContacts(entry, preferredContact)
	if entry == nil or entry.element == nil or entry.element.informOfContact == nil then
		return {
			informedAny = false,
			contactsInformed = 0,
			preferredContactInformed = false,
		}
	end

	local function evaluateContact(contact)
		if contact == nil then
			return false, "contact_nil", nil, nil
		end
		if isAirContact(contact) ~= true then
			return false, "non_air_contact", nil, nil
		end
		if isLikelyGroundedResidualAirContact(contact) == true then
			return false, "residual_contact", nil, nil
		end
		if contact.isIdentifiedAsHARM and contact:isIdentifiedAsHARM() == true then
			return false, "harm_contact", nil, nil
		end
		local okConstraints, constraintsSatisfied = pcall(function()
			return entry.element:areGoLiveConstraintsSatisfied(contact)
		end)
		local constraintOk = okConstraints == true and constraintsSatisfied == true
		local targetInRangeCheck = nil
		local okTargetInRange, inRange = pcall(function()
			return entry.element:isTargetInRange(contact)
		end)
		if okTargetInRange == true then
			targetInRangeCheck = inRange == true and "Y" or "N"
		end
		if constraintOk ~= true then
			return false, "constraints_failed", "N", targetInRangeCheck
		end
		return true, "eligible", "Y", targetInRangeCheck
	end

	local summary = {
		informedAny = false,
		contactsInformed = 0,
		preferredContactInformed = false,
	}

	local function inform(contact, isPreferred)
		local canInformContact, outcomeReason, constraintOk, targetInRangeCheck = evaluateContact(contact)
		local hadTargetInRange = entry.element.targetsInRange == true and "Y" or "N"
		local contactName = self:getContactName(contact)
		local contactType = self:getContactTypeName(contact)
		local distanceNm = nil
		if contact ~= nil then
			local distanceMeters = self:getContactDistanceMeters(entry, contact)
			if distanceMeters < math.huge then
				distanceNm = toRoundedNm(distanceMeters)
			end
		end
		if canInformContact ~= true then
			self:traceEntryCommand(entry, "contact_feed", {
				event = "decision",
				outcome = "blocked",
				reason = outcomeReason,
				source = "inform_entry_of_threat_contacts",
				contact = contactName,
				contactType = contactType,
				distanceNm = distanceNm,
				constraintOk = constraintOk,
				targetInRangeCheck = targetInRangeCheck,
				hadTargetInRange = hadTargetInRange,
				preferredContactInformed = isPreferred == true and "Y" or "N",
			}, "informEntryOfThreatContacts")
			return false
		end
		local now = timer.getTime()
		local samePreferredContact =
			isPreferred == true
			and entry.lastPreferredContactFeedName ~= nil
			and contactName ~= nil
			and contactName == entry.lastPreferredContactFeedName
		local recentPreferredFeed =
			samePreferredContact == true
			and entry.lastPreferredContactFeedTime ~= nil
			and (now - entry.lastPreferredContactFeedTime) < SkynetIADSMobilePatrol.DEFAULT_CONTACT_FEED_REISSUE_SECONDS
		if recentPreferredFeed == true and entry.element.targetsInRange == true then
			self:traceEntryCommand(entry, "contact_feed", {
				event = "decision",
				outcome = "skipped",
				reason = "preferred_contact_latched",
				source = "inform_entry_of_threat_contacts",
				contact = contactName,
				contactType = contactType,
				distanceNm = distanceNm,
				constraintOk = constraintOk,
				targetInRangeCheck = targetInRangeCheck,
				hadTargetInRange = hadTargetInRange,
				targetsInRangeAfter = "Y",
				preferredContactInformed = "Y",
				note = "reissueCooldown="
					.. tostring(SkynetIADSMobilePatrol.DEFAULT_CONTACT_FEED_REISSUE_SECONDS)
					.. "s",
			}, "informEntryOfThreatContacts")
			summary.preferredContactInformed = true
			return true
		end
		local okInform = pcall(function()
			entry.element:informOfContact(contact)
		end)
		local targetsInRangeAfter = entry.element.targetsInRange == true and "Y" or "N"
		local issued = okInform == true
		if issued == true then
			summary.informedAny = true
			summary.contactsInformed = summary.contactsInformed + 1
			if isPreferred == true then
				summary.preferredContactInformed = true
				entry.lastPreferredContactFeedName = contactName
				entry.lastPreferredContactFeedTime = now
			end
		end
		self:traceEntryCommand(entry, "contact_feed", {
			event = "decision",
			outcome = issued == true and "issued" or "failed",
			reason = issued == true and "inform_called" or "inform_error",
			source = "inform_entry_of_threat_contacts",
			contact = contactName,
			contactType = contactType,
			distanceNm = distanceNm,
			constraintOk = constraintOk,
			targetInRangeCheck = targetInRangeCheck,
			hadTargetInRange = hadTargetInRange,
			targetsInRangeAfter = targetsInRangeAfter,
			preferredContactInformed = isPreferred == true and "Y" or "N",
		}, "informEntryOfThreatContacts")
		return issued
	end

	if preferredContact ~= nil then
		inform(preferredContact, true)
	end

	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact ~= preferredContact then
			inform(contact, false)
		end
	end

	self:traceEntryCommand(entry, "contact_feed_summary", {
		event = "decision",
		outcome = summary.informedAny == true and "issued" or "blocked",
		reason = "inform_entry_of_threat_contacts",
		source = "inform_entry_of_threat_contacts",
		contactsInformed = summary.contactsInformed,
		preferredContactInformed = summary.preferredContactInformed == true and "Y" or "N",
	}, "informEntryOfThreatContacts")
	return summary
end

function SkynetIADSMobilePatrol:findFallbackEligibleContact(entry, unit, expectedDistanceMeters, maxDistanceMeters)
	if entry == nil or unit == nil then
		return nil, math.huge, nil
	end

	local eligibleCount = 0
	local nearestContact = nil
	local nearestDistanceMeters = math.huge
	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact
			and isAirContact(contact)
			and isLikelyGroundedResidualAirContact(contact) ~= true
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			self:refreshThreatContact(contact)
			local distanceMeters = self:getContactDistanceMeters(entry, contact)
			if maxDistanceMeters == nil or distanceMeters <= maxDistanceMeters then
				eligibleCount = eligibleCount + 1
				if distanceMeters < nearestDistanceMeters then
					nearestContact = contact
					nearestDistanceMeters = distanceMeters
				end
			end
		end
	end

	if nearestContact == nil then
		return nil, math.huge, nil
	end

	if eligibleCount == 1 then
		return nearestContact, nearestDistanceMeters, "sole_contact_fallback"
	end

	if expectedDistanceMeters ~= nil and expectedDistanceMeters < math.huge then
		local proximityToleranceMeters = mist.utils.NMToMeters(3)
		if math.abs(nearestDistanceMeters - expectedDistanceMeters) <= proximityToleranceMeters then
			local contactType = self:getContactTypeName(nearestContact)
			local unitType = self:getUnitTypeName(unit)
			if contactType == "unknown" or unitType == "unknown" or contactType == unitType then
				return nearestContact, nearestDistanceMeters, "proximity_contact_fallback"
			end
		end
	end

	return nil, math.huge, nil
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
			and isLikelyGroundedResidualAirContact(contact) ~= true
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
		if unitPoint and isLikelyGroundedResidualAirUnit(unit) ~= true and mist.utils.get2DDist(center, unitPoint) <= distanceMeters then
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
		local rawContact, rawContactDistanceMeters = self:findNearestEligibleContact(entry, math.huge)
		local rawDirectUnit, rawDirectUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, math.huge)
		local contact, contactDistanceMeters = self:findNearestEligibleContact(entry, profile.alertRangeMeters)
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, profile.alertRangeMeters)
		local matchedContactSource = nil
		if contact == nil and directUnit ~= nil then
			contact, contactDistanceMeters, matchedContactSource = self:findMatchingEligibleContact(entry, directUnit, profile.alertRangeMeters)
			if contact == nil then
				contact, contactDistanceMeters, matchedContactSource = self:findFallbackEligibleContact(entry, directUnit, directUnitDistanceMeters, profile.alertRangeMeters)
			end
			if contact == nil then
				contact, contactDistanceMeters, matchedContactSource = self:findCachedThreatContactFallback(entry, directUnit, profile.alertRangeMeters)
			end
		end
		if contact == nil and directUnit ~= nil and isLikelyGroundedResidualAirUnit(directUnit) then
			directUnit = nil
			directUnitDistanceMeters = math.huge
		end
		if contact == nil and directUnit == nil then
			local rejectReason = "no_alert_candidate"
			if rawDirectUnit ~= nil and isLikelyGroundedResidualAirUnit(rawDirectUnit) and rawContact == nil then
				rejectReason = "grounded_residual_air_unit"
			elseif (rawDirectUnitDistanceMeters ~= nil and rawDirectUnitDistanceMeters < math.huge and rawDirectUnitDistanceMeters > profile.alertRangeMeters)
				or (rawContactDistanceMeters ~= nil and rawContactDistanceMeters < math.huge and rawContactDistanceMeters > profile.alertRangeMeters) then
				rejectReason = "outside_alert_range"
			end
			local probeDetails = {
				outcome = "rejected",
				source = "findSAMThreatContact_profile",
				rejectReason = rejectReason,
				moveFireCapable = moveFireCapable == true and "Y" or "N",
				threatRangeNm = toRoundedNm(profile.alertRangeMeters),
				engageRangeNm = toRoundedNm(profile.engageRangeMeters),
			}
			setThreatProbeCandidate(probeDetails, "rawDirect", self:getUnitName(rawDirectUnit), self:getUnitTypeName(rawDirectUnit), rawDirectUnitDistanceMeters)
			setThreatProbeCandidate(probeDetails, "rawContact", self:getContactName(rawContact), self:getContactTypeName(rawContact), rawContactDistanceMeters)
			self:traceThreatProbe(entry, probeDetails)
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
		local hasFireQualityContact = (
			(contact ~= nil and contactDistanceMeters <= profile.engageRangeMeters)
			or
			(directUnit ~= nil and directUnitDistanceMeters <= profile.engageRangeMeters)
		)
		local shouldGoLive = inEngageRange
		local shouldWeaponHold = inEngageRange and hasFireQualityContact ~= true
		local triggerInfo = nil
		if contact ~= nil then
			local contactSource = hasFireQualityContact and "contact_scan_engage" or "contact_scan_alert"
			if matchedContactSource == "live_contact_match" then
				contactSource = hasFireQualityContact and "matched_contact_engage" or "matched_contact_alert"
			elseif matchedContactSource == "cached_contact_match" then
				contactSource = hasFireQualityContact and "cached_contact_engage" or "cached_contact_alert"
			elseif matchedContactSource == "cached_contact_fallback" then
				contactSource = hasFireQualityContact and "cached_fallback_engage" or "cached_fallback_alert"
			elseif matchedContactSource == "sole_contact_fallback" then
				contactSource = hasFireQualityContact and "fallback_contact_engage" or "fallback_contact_alert"
			elseif matchedContactSource == "proximity_contact_fallback" then
				contactSource = hasFireQualityContact and "proximity_contact_engage" or "proximity_contact_alert"
			end
			triggerInfo = self:buildDeployTriggerInfo(
				entry,
				contact,
				contactSource
			)
			triggerInfo.contactDistanceNm = triggerInfo.distanceNm
		else
			triggerInfo = self:buildAircraftUnitTriggerInfo(
				entry,
				directUnit,
				(inEngageRange and "direct_unit_engage" or "direct_unit_alert"),
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
		local probeDetails = {
			outcome = "selected",
			source = "findSAMThreatContact_profile",
			selectedBy = triggerInfo.source,
			matchedContactSource = matchedContactSource,
			moveFireCapable = moveFireCapable == true and "Y" or "N",
			shouldGoLive = shouldGoLive == true and "Y" or "N",
			weaponHold = shouldWeaponHold == true and "Y" or "N",
			threatRangeNm = toRoundedNm(profile.alertRangeMeters),
			engageRangeNm = toRoundedNm(profile.engageRangeMeters),
			distanceNm = toRoundedNm(effectiveDistanceMeters),
			contact = triggerInfo.contactName,
			contactType = triggerInfo.contactType,
			contactDistanceNm = triggerInfo.contactDistanceNm,
			directDistanceNm = triggerInfo.directDistanceNm,
			effectiveDistanceNm = triggerInfo.effectiveDistanceNm,
		}
		setThreatProbeCandidate(probeDetails, "rawDirect", self:getUnitName(rawDirectUnit), self:getUnitTypeName(rawDirectUnit), rawDirectUnitDistanceMeters)
		setThreatProbeCandidate(probeDetails, "rawContact", self:getContactName(rawContact), self:getContactTypeName(rawContact), rawContactDistanceMeters)
		setThreatProbeCandidate(probeDetails, "direct", self:getUnitName(directUnit), self:getUnitTypeName(directUnit), directUnitDistanceMeters)
		setThreatProbeCandidate(probeDetails, "contact", self:getContactName(contact), self:getContactTypeName(contact), contactDistanceMeters)
		self:traceThreatProbe(entry, probeDetails)
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
		local rawDirectUnit, rawDirectUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, math.huge)
		local rawContact, rawContactDistanceMeters = self:findNearestEligibleContact(entry, math.huge)
		local directUnit, directUnitDistanceMeters = self:findNearestEnemyAircraftUnit(entry, threatRangeMeters)
		if directUnit == nil then
			local rejectReason = "no_direct_candidate"
			if rawDirectUnit ~= nil and isLikelyGroundedResidualAirUnit(rawDirectUnit) then
				rejectReason = "grounded_residual_air_unit"
			elseif rawDirectUnitDistanceMeters ~= nil and rawDirectUnitDistanceMeters < math.huge and rawDirectUnitDistanceMeters > threatRangeMeters then
				rejectReason = "outside_engage_range"
			end
			local probeDetails = {
				outcome = "rejected",
				source = "findSAMThreatContact_move_fire",
				rejectReason = rejectReason,
				moveFireCapable = "Y",
				threatRangeNm = toRoundedNm(threatRangeMeters),
				engageRangeNm = toRoundedNm(threatRangeMeters),
			}
			setThreatProbeCandidate(probeDetails, "rawDirect", self:getUnitName(rawDirectUnit), self:getUnitTypeName(rawDirectUnit), rawDirectUnitDistanceMeters)
			setThreatProbeCandidate(probeDetails, "rawContact", self:getContactName(rawContact), self:getContactTypeName(rawContact), rawContactDistanceMeters)
			self:traceThreatProbe(entry, probeDetails)
			return nil
		end
		local contact, contactDistanceMeters, matchedContactSource = self:findMatchingEligibleContact(entry, directUnit, threatRangeMeters)
		if contact == nil then
			contact, contactDistanceMeters, matchedContactSource = self:findFallbackEligibleContact(entry, directUnit, directUnitDistanceMeters, threatRangeMeters)
		end
		if contact == nil and isLikelyGroundedResidualAirUnit(directUnit) then
			local probeDetails = {
				outcome = "rejected",
				source = "findSAMThreatContact_move_fire",
				rejectReason = "grounded_residual_air_unit",
				moveFireCapable = "Y",
				threatRangeNm = toRoundedNm(threatRangeMeters),
				engageRangeNm = toRoundedNm(threatRangeMeters),
			}
			setThreatProbeCandidate(probeDetails, "rawDirect", self:getUnitName(rawDirectUnit), self:getUnitTypeName(rawDirectUnit), rawDirectUnitDistanceMeters)
			setThreatProbeCandidate(probeDetails, "rawContact", self:getContactName(rawContact), self:getContactTypeName(rawContact), rawContactDistanceMeters)
			setThreatProbeCandidate(probeDetails, "direct", self:getUnitName(directUnit), self:getUnitTypeName(directUnit), directUnitDistanceMeters)
			self:traceThreatProbe(entry, probeDetails)
			return nil
		end
		local directSource = "direct_unit_scan"
		if matchedContactSource == "live_contact_match" then
			directSource = "direct_unit_contact_match"
		elseif matchedContactSource == "cached_contact_match" then
			directSource = "direct_unit_cached_contact"
		elseif matchedContactSource == "sole_contact_fallback" then
			directSource = "direct_unit_fallback_contact"
		elseif matchedContactSource == "proximity_contact_fallback" then
			directSource = "direct_unit_proximity_contact"
		end
		local triggerInfo = self:buildAircraftUnitTriggerInfo(entry, directUnit, directSource, threatRangeMeters)
		if contact ~= nil and contactDistanceMeters < math.huge then
			triggerInfo.contactDistanceNm = mist.utils.round(mist.utils.metersToNM(contactDistanceMeters), 1)
		end
		triggerInfo.engageRangeNm = mist.utils.round(mist.utils.metersToNM(threatRangeMeters), 1)
		local probeDetails = {
			outcome = "selected",
			source = "findSAMThreatContact_move_fire",
			selectedBy = directSource,
			matchedContactSource = matchedContactSource,
			moveFireCapable = "Y",
			shouldGoLive = "Y",
			weaponHold = "N",
			threatRangeNm = toRoundedNm(threatRangeMeters),
			engageRangeNm = toRoundedNm(threatRangeMeters),
			distanceNm = triggerInfo.distanceNm,
			contact = triggerInfo.contactName,
			contactType = triggerInfo.contactType,
			contactDistanceNm = triggerInfo.contactDistanceNm,
			directDistanceNm = triggerInfo.directDistanceNm,
			effectiveDistanceNm = triggerInfo.effectiveDistanceNm,
		}
		setThreatProbeCandidate(probeDetails, "rawDirect", self:getUnitName(rawDirectUnit), self:getUnitTypeName(rawDirectUnit), rawDirectUnitDistanceMeters)
		setThreatProbeCandidate(probeDetails, "rawContact", self:getContactName(rawContact), self:getContactTypeName(rawContact), rawContactDistanceMeters)
		setThreatProbeCandidate(probeDetails, "direct", self:getUnitName(directUnit), self:getUnitTypeName(directUnit), directUnitDistanceMeters)
		setThreatProbeCandidate(probeDetails, "contact", self:getContactName(contact), self:getContactTypeName(contact), contactDistanceMeters)
		self:traceThreatProbe(entry, probeDetails)
		return {
			contact = contact,
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
	local moveFireCapable = self:isMoveFireCapable(entry)
	if threatDecision.contact == nil and threatDecision.shouldGoLive == true and moveFireCapable ~= true then
		local reusableContact, reusableDistanceMeters = self:getReusableThreatContact(entry, triggerInfo)
		if reusableContact ~= nil then
			threatDecision.contact = reusableContact
			if triggerInfo then
				triggerInfo.source = "reused_cached_contact"
				if triggerInfo.contactDistanceNm == nil and reusableDistanceMeters < math.huge then
					triggerInfo.contactDistanceNm = mist.utils.round(mist.utils.metersToNM(reusableDistanceMeters), 1)
				end
				if triggerInfo.contactName == nil or triggerInfo.contactName == "unknown" then
					triggerInfo.contactName = self:getContactName(reusableContact)
				end
				if triggerInfo.contactType == nil or triggerInfo.contactType == "unknown" then
					triggerInfo.contactType = self:getContactTypeName(reusableContact)
				end
			end
		end
	end
	if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false then
		entry.lastThreatContact = threatDecision.contact
		self:refreshThreatContact(entry.lastThreatContact)
		if moveFireCapable == true then
			touchMoveFireContactSession(entry, threatDecision.contact)
		end
	end
	if triggerInfo then
		entry.lastDeployTrigger = triggerInfo
	end
	entry.combatMode = threatDecision.combatMode or "default_fire"
	local effectiveSkipPause = skipPause == true or threatDecision.skipPauseDeployment == true
	local informedContactsSummary = nil

	if moveFireCapable ~= true and threatDecision.shouldDeploy and entry.state ~= "deployed" and entry.state ~= "deploy_scattering" and effectiveSkipPause ~= true then
		self:pausePatrolForDeployment(entry, triggerInfo)
	end

	if entry.state == "deploy_scattering" then
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		if threatDecision.shouldGoLive == true then
			self:setOrderTraceContext(entry, "msam_threat_decision", {
				source = triggerInfo and triggerInfo.source or "deploy_scattering",
				triggerInfo = triggerInfo,
				threatDecision = threatDecision,
			}, "applyMSAMThreatDecision")
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			informedContactsSummary = self:informEntryOfThreatContacts(entry, threatDecision.contact)
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
		if moveFireCapable then
			self:traceEntryCommand(entry, "moving_combat_state", {
				outcome = "issued",
				reason = "msam_threat_decision",
				source = triggerInfo and triggerInfo.source or "move_fire",
				triggerInfo = triggerInfo,
				shouldDeploy = threatDecision.shouldDeploy == true and "Y" or "N",
				shouldGoLive = threatDecision.shouldGoLive == true and "Y" or "N",
				weaponHold = threatDecision.shouldWeaponHold == true and "Y" or "N",
			}, "applyMSAMThreatDecision")
			setElementMovingCombatState(entry.element, threatDecision.shouldWeaponHold == true)
			if threatDecision.contact and threatDecision.contact:isIdentifiedAsHARM() == false and entry.element.informOfContact then
				pcall(function()
					entry.element:informOfContact(threatDecision.contact)
				end)
			end
		else
			self:setOrderTraceContext(entry, "msam_threat_decision", {
				source = triggerInfo and triggerInfo.source or "go_live",
				triggerInfo = triggerInfo,
				threatDecision = threatDecision,
			}, "applyMSAMThreatDecision")
			entry.element:goLive()
			setElementCombatROE(entry.element, threatDecision.shouldWeaponHold == true)
			informedContactsSummary = self:informEntryOfThreatContacts(entry, threatDecision.contact)
		end
	else
		self:traceEntryCommand(entry, "patrol_dark_state", {
			outcome = "issued",
			reason = "msam_threat_decision_dark",
			source = triggerInfo and triggerInfo.source or "threat_hold",
			triggerInfo = triggerInfo,
			shouldDeploy = threatDecision.shouldDeploy == true and "Y" or "N",
			shouldGoLive = threatDecision.shouldGoLive == true and "Y" or "N",
			weaponHold = threatDecision.shouldWeaponHold == true and "Y" or "N",
		}, "applyMSAMThreatDecision")
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
	if moveFireCapable ~= true then
		local missilesInFlight = 0
		local okMissilesInFlight, trackedMissilesInFlight = pcall(function()
			return entry.element:getNumberOfMissilesInFlight()
		end)
		if okMissilesInFlight == true and type(trackedMissilesInFlight) == "number" then
			missilesInFlight = trackedMissilesInFlight
		end
		if threatDecision.shouldGoLive == true and missilesInFlight <= 0 then
			local trackedContactName = nil
			local trackedContactType = nil
			if triggerInfo then
				trackedContactName = triggerInfo.contactName or triggerInfo.directUnitName
				trackedContactType = triggerInfo.contactType
			end
			if trackedContactName == nil and threatDecision.contact ~= nil then
				trackedContactName = self:getContactName(threatDecision.contact)
				trackedContactType = self:getContactTypeName(threatDecision.contact)
			end
			if entry.launchAwaitSince == nil or entry.launchAwaitContactName ~= trackedContactName then
				entry.launchAwaitSince = now
				entry.launchAwaitContactName = trackedContactName
				entry.launchAwaitContactType = trackedContactType
			end
		else
			entry.launchAwaitSince = nil
			entry.launchAwaitContactName = nil
			entry.launchAwaitContactType = nil
			entry.lastPreferredContactFeedName = nil
			entry.lastPreferredContactFeedTime = nil
			entry.launchReadyLatchedUntil = 0
			entry.launchReadyLastSeenTime = nil
			entry.launchReadyDroppedAt = nil
		end
	end
	entry.lastThreatTime = now
	entry.noThreatSince = nil
	self:traceStateSnapshot(entry, "msam_threat_decision", {
		source = triggerInfo and triggerInfo.source or "threat_decision",
		triggerInfo = triggerInfo,
		shouldDeploy = threatDecision.shouldDeploy == true and "Y" or "N",
		shouldGoLive = threatDecision.shouldGoLive == true and "Y" or "N",
		weaponHold = threatDecision.shouldWeaponHold == true and "Y" or "N",
		contactsInformed = informedContactsSummary and informedContactsSummary.contactsInformed or nil,
		preferredContactInformed =
			informedContactsSummary ~= nil
			and (informedContactsSummary.preferredContactInformed == true and "Y" or "N")
			or nil,
	}, "applyMSAMThreatDecision")
	self:announceCombatState(entry, threatDecision)
	if wasCombatCommitted ~= true and entry.combatCommitted == true and _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
		pcall(function()
			_G.redIADSSiblingCoordination:requestImmediateEvaluation("msam_threat:" .. tostring(entry.groupName))
		end)
	end
	return true
end

function SkynetIADSMobilePatrol:hasSAMCombatThreat(entry)
	local details = {
		source = "none",
		directUnitName = "unknown",
		directUnitType = "unknown",
		directDistanceNm = nil,
		contactName = "unknown",
		contactType = "unknown",
		contactDistanceNm = nil,
		residualContactFiltered = false,
	}
	if entry == nil or entry.kind ~= "MSAM" then
		return false, details
	end

	local combatRangeMeters = self:getCombatRangeMeters(entry)
	if combatRangeMeters <= 0 then
		return false, details
	end

	local siblingInfo = self:getSiblingInfo(entry)
	if siblingInfo ~= nil and siblingInfo.mode == "denial" and siblingInfo.role == "primary" then
		local denialRangeMeters = mist.utils.NMToMeters(
			siblingInfo.denialAlertDistanceNm
			or self.sa11MSAMAlertDistanceNm
			or SkynetIADSMobilePatrol.DEFAULT_SA11_MSAM_ALERT_DISTANCE_NM
		)
		local directUnit = self:findNearestEnemyAircraftUnit(entry, denialRangeMeters)
		if directUnit ~= nil and isLikelyGroundedResidualAirUnit(directUnit) then
			directUnit = nil
		end
		if directUnit ~= nil then
			details.source = "direct_unit_denial"
			details.directUnitName = self:getUnitName(directUnit)
			details.directUnitType = self:getUnitTypeName(directUnit)
			details.directDistanceNm = toRoundedNm(self:getUnitDistanceMeters(entry, directUnit))
			return true, details
		end
		local contacts = self.iads:getContacts()
		for i = 1, #contacts do
			local contact = contacts[i]
			if contact and isAirContact(contact) and isLikelyGroundedResidualAirContact(contact) == true then
				details.residualContactFiltered = true
			elseif contact
				and isAirContact(contact)
				and contact:isIdentifiedAsHARM() == false
				and entry.element:areGoLiveConstraintsSatisfied(contact)
				and self:getContactDistanceMeters(entry, contact) <= denialRangeMeters then
				details.source = "contact_denial"
				details.contactName = self:getContactName(contact)
				details.contactType = self:getContactTypeName(contact)
				details.contactDistanceNm = toRoundedNm(self:getContactDistanceMeters(entry, contact))
				return true, details
			end
		end
	end

	local profile = self:getMSAMCombatProfile(entry)
	if profile then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		if directUnit ~= nil and isLikelyGroundedResidualAirUnit(directUnit) then
			directUnit = nil
		end
		if directUnit ~= nil then
			details.source = "direct_unit_profile"
			details.directUnitName = self:getUnitName(directUnit)
			details.directUnitType = self:getUnitTypeName(directUnit)
			details.directDistanceNm = toRoundedNm(self:getUnitDistanceMeters(entry, directUnit))
			return true, details
		end
	end

	if self:isMoveFireCapable(entry) then
		local directUnit = self:findNearestEnemyAircraftUnit(entry, combatRangeMeters)
		if directUnit ~= nil and isLikelyGroundedResidualAirUnit(directUnit) then
			directUnit = nil
		end
		if directUnit ~= nil then
			details.source = "direct_unit_move_fire"
			details.directUnitName = self:getUnitName(directUnit)
			details.directUnitType = self:getUnitTypeName(directUnit)
			details.directDistanceNm = toRoundedNm(self:getUnitDistanceMeters(entry, directUnit))
			return true, details
		end
		return false, details
	end
	local contacts = self.iads:getContacts()
	for i = 1, #contacts do
		local contact = contacts[i]
		if contact and isAirContact(contact) and isLikelyGroundedResidualAirContact(contact) == true then
			details.residualContactFiltered = true
		elseif contact
			and isAirContact(contact)
			and contact:isIdentifiedAsHARM() == false
			and entry.element:areGoLiveConstraintsSatisfied(contact) then
			if profile then
				if self:getContactDistanceMeters(entry, contact) <= combatRangeMeters then
					details.source = "contact_profile"
					details.contactName = self:getContactName(contact)
					details.contactType = self:getContactTypeName(contact)
					details.contactDistanceNm = toRoundedNm(self:getContactDistanceMeters(entry, contact))
					return true, details
				end
			elseif entry.element:isTargetInRange(contact) then
				details.source = "contact_in_range"
				details.contactName = self:getContactName(contact)
				details.contactType = self:getContactTypeName(contact)
				details.contactDistanceNm = toRoundedNm(self:getContactDistanceMeters(entry, contact))
				return true, details
			end
		end
	end
	return false, details
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
		if isLikelyGroundedResidualAirUnit(unit) ~= true then
			local unitPoint = unit:getPoint()
			if unitPoint then
				local distanceMeters = mist.utils.get2DDist(center, unitPoint)
				if distanceMeters <= maxDistanceMeters then
					self:traceAirUnitTrack(entry, unit, distanceMeters, {
						outcome = "candidate",
						command = "air_contact",
						scope = "air_track",
						note = "within_scan_range=Y",
					}, "findNearestEnemyAircraftUnit")
				end
				if distanceMeters <= maxDistanceMeters and distanceMeters < nearestDistanceMeters then
					nearestUnit = unit
					nearestDistanceMeters = distanceMeters
				end
			end
		end
	end
	if nearestUnit ~= nil then
		self:traceAirUnitTrack(entry, nearestUnit, nearestDistanceMeters, {
			outcome = "selected",
			command = "air_contact",
			scope = "air_track",
			note = "nearest_candidate=Y",
		}, "findNearestEnemyAircraftUnit")
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
	self:setOrderTraceContext(entry, "pause_for_deployment", {
		source = triggerInfo and triggerInfo.source or "deployment_trigger",
		triggerInfo = triggerInfo,
	}, "pausePatrolForDeployment")
	local scatterIssued = self:issueDeployScatter(entry) == true
	if scatterIssued ~= true then
		self:setOrderTraceContext(entry, "deploy_hold_fallback", {
			source = triggerInfo and triggerInfo.source or "deployment_trigger",
			triggerInfo = triggerInfo,
			note = "scatter route unavailable",
		}, "pausePatrolForDeployment")
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
	self:traceStateSnapshot(entry, scatterIssued == true and "pause_for_deployment_scatter" or "pause_for_deployment_hold", {
		source = triggerInfo and triggerInfo.source or "deployment_trigger",
		triggerInfo = triggerInfo,
	}, "pausePatrolForDeployment")
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
			.. " deploy and hold | mode="
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
	entry.debugHarmActive = false
	entry.debugLastCombatAnnouncementKey = nil
	entry.lastThreatProbeSignature = nil
	entry.lastThreatProbeTime = nil
	entry.launchAwaitSince = nil
	entry.launchAwaitContactName = nil
	entry.launchAwaitContactType = nil
	entry.lastLaunchMonitorSignature = nil
	entry.lastLaunchMonitorTime = nil
	entry.lastPreferredContactFeedName = nil
	entry.lastPreferredContactFeedTime = nil
	entry.launchReadyLatchedUntil = 0
	entry.launchReadyLastSeenTime = nil
	entry.launchReadyDroppedAt = nil
	resetMoveFireContactSession(entry)
	forceElementIntoPatrolDarkState(entry.element)
	applyFormationIntervalToEntry(entry, SkynetIADSMobilePatrol.DEFAULT_PATROL_FORMATION_INTERVAL_METERS)
	entry.currentDestination = nil
	entry.stationaryReissueCount = 0
	if entry.patrolRouteMode == "off_road" then
		entry.currentWaypointIndex = self:selectNearestWaypointIndex(entry)
	end
	entry.patrolRefreshDelays = mist.utils.deepCopy(self.defaultPatrolRefreshDelays)
	entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
	self:setOrderTraceContext(entry, "begin_patrol", {
		source = previousState or "startup",
	}, "beginPatrol")
	self:traceStateSnapshot(entry, "begin_patrol", {
		source = previousState or "startup",
	}, "beginPatrol")
	self:issuePatrolRoute(entry)
	if previousState ~= "patrolling" then
		self:notifyDebug(entry.groupName .. " resume patrol")
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
		local routeMode = entry.patrolRouteMode or "road"
		local route = routeMode == "off_road" and self:buildOffRoadPatrolRoute(entry, startIndex, false) or self:buildRoadPatrolRoute(entry, startIndex)
		if route and pcall(function()
			mist.goRoute(entry.group, route)
		end) then
			entry.currentDestination = nextPoint
			entry.lastRouteIssueTime = timer.getTime()
			entry.lastRouteIssueReferencePoint = self:getPatrolReferencePoint(entry)
			entry.stationaryReissueCount = 0
			self:log("Patrol resume issued for "..entry.groupName.." | mode="..routeMode.." | wp="..tostring(startIndex).." | speed="..entry.patrolSpeedKmph.."km/h")
			self:traceEntryCommand(entry, routeMode == "off_road" and "offroad_patrol_resume" or "road_patrol_resume", {
				outcome = "issued",
				reason = "advance_patrol",
				speedKmph = entry.patrolSpeedKmph,
				waypoint = startIndex,
				routeMode = routeMode,
				destination = nextPoint,
			}, "advancePatrol")
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

function SkynetIADSMobilePatrol:handleCombatThreatLoss(entry, now, combatThreatPresent, source, threatDetails)
	if entry == nil or entry.combatCommitted ~= true then
		if entry then
			entry.combatNoTargetSince = nil
		end
		return false
	end
	if combatThreatPresent == true then
		entry.combatNoTargetSince = nil
		self:traceCombatExitCheck(entry, {
			source = source or "combat_scan",
			outcome = "blocked",
			note = "combatThreatPresent=Y",
			threatSource = threatDetails and threatDetails.source or "unknown",
			directCandidate = threatDetails and threatDetails.directUnitName or "unknown",
			directCandidateType = threatDetails and threatDetails.directUnitType or "unknown",
			directCandidateDistanceNm = threatDetails and threatDetails.directDistanceNm or nil,
			contactCandidate = threatDetails and threatDetails.contactName or "unknown",
			contactCandidateType = threatDetails and threatDetails.contactType or "unknown",
			contactCandidateDistanceNm = threatDetails and threatDetails.contactDistanceNm or nil,
			residualContactFiltered = threatDetails and threatDetails.residualContactFiltered == true and "Y" or "N",
		}, "handleCombatThreatLoss")
		return false
	end
	if entry.combatNoTargetSince == nil then
		entry.combatNoTargetSince = now
		self:traceCombatExitCheck(entry, {
			source = source or "combat_scan",
			outcome = "arming",
			note = "combatThreatPresent=N",
			elapsedNoTargetSeconds = 0,
			thresholdSeconds = entry.combatExitNoTargetSeconds,
			residualContactFiltered = threatDetails and threatDetails.residualContactFiltered == true and "Y" or "N",
		}, "handleCombatThreatLoss")
		return false
	end
	local elapsedNoTargetSeconds = now - entry.combatNoTargetSince
	if elapsedNoTargetSeconds < entry.combatExitNoTargetSeconds then
		self:traceCombatExitCheck(entry, {
			source = source or "combat_scan",
			outcome = "waiting",
			note = "combatThreatPresent=N",
			elapsedNoTargetSeconds = mist.utils.round(elapsedNoTargetSeconds, 1),
			thresholdSeconds = entry.combatExitNoTargetSeconds,
			residualContactFiltered = threatDetails and threatDetails.residualContactFiltered == true and "Y" or "N",
		}, "handleCombatThreatLoss")
		return false
	end
	self:cancelDeployScatter(entry)
	entry.combatCommitted = false
	entry.combatNoTargetSince = nil
	entry.mobileLockUntil = now + entry.postCombatMobileSeconds
	entry.combatMode = "patrolling"
	entry.debugLastCombatAnnouncementKey = nil
	self:notifyDebug(entry.groupName .. " combat exit -> mobile")
	self:traceCombatExitCheck(entry, {
		source = source or "combat_scan",
		outcome = "exit",
		note = "combatThreatPresent=N",
		elapsedNoTargetSeconds = mist.utils.round(elapsedNoTargetSeconds, 1),
		thresholdSeconds = entry.combatExitNoTargetSeconds,
		residualContactFiltered = threatDetails and threatDetails.residualContactFiltered == true and "Y" or "N",
	}, "handleCombatThreatLoss")
	self:traceStateSnapshot(entry, "combat_exit_mobile", {
		source = source or "combat_exit",
		note = "state=" .. tostring(entry.state or "unknown"),
	}, "handleCombatThreatLoss")
	self:beginPatrol(entry)
	if _G.redIADSSiblingCoordination and _G.redIADSSiblingCoordination.requestImmediateEvaluation then
		pcall(function()
			_G.redIADSSiblingCoordination:requestImmediateEvaluation("combat_exit:" .. tostring(entry.groupName))
		end)
	end
	return true
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
		self:notifyDebug(entry.groupName .. " deploy scatter complete -> deployed")
		self:traceStateSnapshot(entry, "deploy_scatter_complete", {
			source = "deploy_scatter",
			note = "moved=" .. tostring(mist.utils.round(movedDistance, 0)) .. "m",
		}, "handleDeployScatterState")
		return true
	end
	if timedOut then
		entry.deployScatterDeadline = timer.getTime() + SkynetIADSMobilePatrol.DEFAULT_DEPLOY_SCATTER_CHECK_INTERVAL_SECONDS
	end
	return false
end

function SkynetIADSMobilePatrol:cancelDeployScatter(entry)
	if entry == nil then
		return
	end
	entry.currentDestination = nil
	entry.deployScatterStartPoint = nil
	entry.deployScatterDestination = nil
	entry.deployScatterDeadline = 0
	entry.deployScatterMinimumCompletionMeters = 0
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
		if entry.nextPatrolRefreshTime and timer.getTime() >= entry.nextPatrolRefreshTime then
			forceElementIntoPatrolDarkState(entry.element)
			self:log("Patrol refresh reissued for "..entry.groupName.." | delayed startup refresh (harm_silent)")
			self:setOrderTraceContext(entry, "patrol_refresh_harm_silent", {
				source = "harm_silent_refresh",
			}, "updateEntry")
			self:issuePatrolRoute(entry)
			table.remove(entry.patrolRefreshDelays, 1)
			if #entry.patrolRefreshDelays > 0 then
				entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
			else
				entry.nextPatrolRefreshTime = nil
			end
		end
		self:handlePatrolStationaryRecovery(entry, "harm_silent_stationary")
		self:traceStateSnapshot(entry, "harm_silent", {
			source = "harm_detected",
		}, "updateEntry")
		return
	end

	if self:isHarmEvading(entry) then
		entry.state = "harm_evading"
		entry.noThreatSince = nil
		self:traceStateSnapshot(entry, "harm_evading", {
			source = "harm_detected",
		}, "updateEntry")
		return
	end

	local siblingInfo = self:getSiblingInfo(entry)
	local siblingPassiveRelocate = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "relocate"
	local siblingPassiveHold = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "hold_dark"
	local siblingPassiveStandby = siblingInfo ~= nil and siblingInfo.role == "passive" and siblingInfo.passiveMode == "standby"

	if entry.state == "deploy_scattering" then
		if siblingPassiveRelocate then
			self:cancelDeployScatter(entry)
			self:beginPatrol(entry)
			return
		end
		if siblingPassiveHold or siblingPassiveStandby then
			self:cancelDeployScatter(entry)
			entry.combatCommitted = false
			entry.combatNoTargetSince = nil
			entry.noThreatSince = nil
			entry.lastThreatTime = now
			entry.debugLastCombatAnnouncementKey = nil
			forceElementIntoPatrolDarkState(entry.element)
			if siblingPassiveStandby then
				entry.state = "deployed"
				entry.combatMode = "sibling_standby"
				self:traceStateSnapshot(entry, "sibling_passive_standby", {
					source = "sibling_coord",
					note = "deploy_scatter_cancelled",
				}, "updateEntry")
			else
				entry.state = "patrolling"
				entry.combatMode = "patrolling"
				if entry.manager and entry.manager.issueHold then
					entry.manager:issueHold(entry)
				end
				self:traceStateSnapshot(entry, "sibling_passive_hold", {
					source = "sibling_coord",
					note = "deploy_scatter_cancelled",
				}, "updateEntry")
			end
			return
		end
		if self:handleDeployScatterState(entry) ~= true then
			if entry.kind == "MSAM" then
				local threatDecision = self:findSAMThreatContact(entry)
				if threatDecision and threatDecision.shouldGoLive == true then
					self:applyMSAMThreatDecision(entry, threatDecision, true)
				else
					local combatThreatPresent, combatThreatDetails = self:hasSAMCombatThreat(entry)
					if self:handleCombatThreatLoss(entry, now, combatThreatPresent, "deploy_scattering", combatThreatDetails) then
						return
					end
				end
			end
			entry.noThreatSince = nil
			entry.lastThreatTime = timer.getTime()
			self:traceStateSnapshot(entry, "deploy_scattering", {
				source = "deploy_scatter",
			}, "updateEntry")
			return
		end
	end

	if siblingPassiveHold then
		entry.combatCommitted = false
		entry.combatNoTargetSince = nil
		entry.noThreatSince = nil
		if entry.state == "deployed" then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		end
		self:traceStateSnapshot(entry, "sibling_passive_hold", {
			source = "sibling_coord",
		}, "updateEntry")
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
		self:traceStateSnapshot(entry, "sibling_passive_standby", {
			source = "sibling_coord",
		}, "updateEntry")
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
		self:traceStateSnapshot(entry, "mobile_lock", {
			source = "post_combat_mobile",
		}, "updateEntry")
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
			local combatThreatPresent, combatThreatDetails = self:hasSAMCombatThreat(entry)
			local missilesInFlight = 0
			local okMissilesInFlight, trackedMissilesInFlight = pcall(function()
				return entry.element:getNumberOfMissilesInFlight()
			end)
			if okMissilesInFlight == true and type(trackedMissilesInFlight) == "number" then
				missilesInFlight = trackedMissilesInFlight
			end
			local recentWeaponLaunchHold = false
			local lastWeaponLaunchTime = entry.element and entry.element.lastWeaponLaunchTime or nil
			if type(lastWeaponLaunchTime) == "number" then
				recentWeaponLaunchHold =
					(now - lastWeaponLaunchTime) <= SkynetIADSMobilePatrol.DEFAULT_POST_LAUNCH_LIVE_HOLD_SECONDS
			end
			local maintainByWeaponCommit = missilesInFlight > 0 or recentWeaponLaunchHold == true

			if maintainByWeaponCommit ~= true and self:handleCombatThreatLoss(entry, now, combatThreatPresent, "combat_scan", combatThreatDetails) then
				return
			elseif maintainByWeaponCommit == true then
				entry.combatNoTargetSince = nil
				self:traceCombatExitCheck(entry, {
					source = "combat_scan",
					outcome = "blocked",
					note = missilesInFlight > 0 and "missilesInFlight>0" or "recentLaunchHold=Y",
					missilesInFlight = missilesInFlight,
					residualContactFiltered = combatThreatDetails and combatThreatDetails.residualContactFiltered == true and "Y" or "N",
				}, "updateEntry")
			end

			if self:isMoveFireCapable(entry) ~= true and missilesInFlight <= 0 and entry.launchAwaitSince ~= nil then
				local launchStateAgeSeconds = now - entry.launchAwaitSince
				if launchStateAgeSeconds >= 4 then
					local monitoredContact = nil
					if threatDecision and threatDecision.contact ~= nil then
						monitoredContact = threatDecision.contact
					else
						monitoredContact = entry.lastThreatContact
					end
					local launchConstraintOk = nil
					local launchRangeCheck = nil
					if monitoredContact ~= nil then
						local okConstraintCheck, constraintSatisfied = pcall(function()
							return entry.element:areGoLiveConstraintsSatisfied(monitoredContact)
						end)
						if okConstraintCheck == true then
							launchConstraintOk = constraintSatisfied == true and "Y" or "N"
						end
						local okRangeCheck, inRange = pcall(function()
							return entry.element:isTargetInRange(monitoredContact)
						end)
						if okRangeCheck == true then
							launchRangeCheck = inRange == true and "Y" or "N"
						end
					end
					local workingRadar = nil
					local okWorkingRadar, hasWorkingRadar = pcall(function()
						return entry.element:hasWorkingRadar()
					end)
					if okWorkingRadar == true then
						workingRadar = hasWorkingRadar == true and "Y" or "N"
					end
					local workingPower = nil
					local okWorkingPower, hasWorkingPower = pcall(function()
						return entry.element:hasWorkingPowerSource()
					end)
					if okWorkingPower == true then
						workingPower = hasWorkingPower == true and "Y" or "N"
					end
					local instantaneousLaunchReady =
						(entry.element.targetsInRange == true)
						and (launchConstraintOk ~= "N")
						and (launchRangeCheck ~= "N")
						and (entry.element.harmSilenceID == nil)
					if instantaneousLaunchReady == true then
						entry.launchReadyLastSeenTime = now
						entry.launchReadyLatchedUntil = now + SkynetIADSMobilePatrol.DEFAULT_LAUNCH_READY_STABLE_SECONDS
						entry.launchReadyDroppedAt = nil
					elseif entry.launchReadyLastSeenTime ~= nil and entry.launchReadyDroppedAt == nil then
						entry.launchReadyDroppedAt = now
					end
					local launchReadyLatched =
						entry.launchReadyLatchedUntil ~= nil
						and entry.launchReadyLatchedUntil > now
						and entry.element.harmSilenceID == nil
					local launchReady = instantaneousLaunchReady == true or launchReadyLatched == true
					local launchReadySinceSeconds = nil
					if entry.launchReadyLastSeenTime ~= nil then
						launchReadySinceSeconds = mist.utils.round(now - entry.launchReadyLastSeenTime, 1)
					end
					local launchDroppedSinceSeconds = nil
					if instantaneousLaunchReady ~= true and entry.launchReadyDroppedAt ~= nil then
						launchDroppedSinceSeconds = mist.utils.round(now - entry.launchReadyDroppedAt, 1)
					end
					self:traceLaunchMonitor(entry, {
						outcome = "waiting_fire",
						source = "combat_launch_gate",
						contact = entry.launchAwaitContactName or (threatDecision and threatDecision.triggerInfo and threatDecision.triggerInfo.contactName) or nil,
						contactType = entry.launchAwaitContactType or (threatDecision and threatDecision.triggerInfo and threatDecision.triggerInfo.contactType) or nil,
						distanceNm = threatDecision and threatDecision.triggerInfo and (threatDecision.triggerInfo.effectiveDistanceNm or threatDecision.triggerInfo.distanceNm) or nil,
						launchReady = launchReady == true and "Y" or "N",
						launchReadyLatched = launchReadyLatched == true and "Y" or "N",
						launchConstraintOk = launchConstraintOk,
						launchRangeCheck = launchRangeCheck,
						launchStateAgeSeconds = mist.utils.round(launchStateAgeSeconds, 1),
						launchReadySinceSeconds = launchReadySinceSeconds,
						launchDroppedSinceSeconds = launchDroppedSinceSeconds,
						launchTimeoutSeconds = 4,
						workingRadar = workingRadar,
						workingPower = workingPower,
						targetsInRange = entry.element.targetsInRange == true and "Y" or "N",
						missilesInFlight = missilesInFlight,
					}, "updateEntry")
				end
			end

			local shouldMaintainCombatLatch = maintainByWeaponCommit == true
			if shouldMaintainCombatLatch ~= true and combatThreatPresent == true then
				if threatDecision == nil then
					shouldMaintainCombatLatch = true
				elseif threatDecision.shouldGoLive ~= true then
					local threatSource = threatDecision.triggerInfo and threatDecision.triggerInfo.source or nil
					local isAlertOnlyDecision =
						threatDecision.combatMode == "alert_hold"
						or (threatSource ~= nil and string.find(threatSource, "_alert", 1, true) ~= nil)
					shouldMaintainCombatLatch = isAlertOnlyDecision ~= true
				end
			end

			if shouldMaintainCombatLatch then
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
			self:traceEntryCommand(entry, "patrol_dark_state", {
				outcome = "issued",
				reason = "move_fire_reset_to_patrol",
				source = "no_threat",
			}, "updateEntry")
			forceElementIntoPatrolDarkState(entry.element)
			entry.combatMode = "patrolling"
			entry.debugLastCombatAnnouncementKey = nil
			resetMoveFireContactSession(entry)
			local resumedRoute = false
			pcall(function()
				resumedRoute = self:issuePatrolRoute(entry)
			end)
			if resumedRoute ~= true then
				entry.patrolRouteMode = "off_road"
				entry.currentWaypointIndex = self:selectNearestWaypointIndex(entry)
				self:setOrderTraceContext(entry, "move_fire_resume_patrol", {
					source = "move_fire_reset",
					note = "fallback=off_road",
				}, "updateEntry")
				self:issuePatrolRoute(entry)
			end
			self:traceStateSnapshot(entry, "move_fire_reset_to_patrol", {
				source = "no_threat",
			}, "updateEntry")
		end
	elseif entry.kind ~= "MSAM" then
		threatPresent = self:findMEWThreat(entry)
		if threatPresent and entry.state ~= "deployed" then
			self:pausePatrolForDeployment(entry)
			self:setOrderTraceContext(entry, "mew_threat_detected", {
				source = "mew_threat_scan",
			}, "updateEntry")
			entry.element:goLive()
			entry.combatMode = "default_fire"
		end
	end

	if threatPresent then
		entry.state = "deployed"
		entry.lastThreatTime = timer.getTime()
		entry.noThreatSince = nil
		self:traceStateSnapshot(entry, "threat_present", {
			source = entry.kind == "MSAM" and "sam_threat_scan" or "mew_threat_scan",
		}, "updateEntry")
		return
	end

	if entry.state == "harm_evading" then
		if self:isMoveFireCapable(entry) then
			entry.state = "patrolling"
			entry.combatMode = "patrolling"
		else
			entry.state = "deployed"
		end
		self:traceStateSnapshot(entry, "harm_state_recovered", {
			source = "harm_recovery",
		}, "updateEntry")
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
		self:setOrderTraceContext(entry, "patrol_refresh", {
			source = "startup_refresh",
		}, "updateEntry")
		self:issuePatrolRoute(entry)
		table.remove(entry.patrolRefreshDelays, 1)
		if #entry.patrolRefreshDelays > 0 then
			entry.nextPatrolRefreshTime = timer.getTime() + entry.patrolRefreshDelays[1]
		else
			entry.nextPatrolRefreshTime = nil
		end
	end

	self:handlePatrolStationaryRecovery(entry, "stationary_recovery")
	self:traceStateSnapshot(entry, "patrolling", {
		source = "patrol_tick",
	}, "updateEntry")
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
		patrolRouteMode = "road",
		stationaryReissueCount = 0,
		deployScatterStartPoint = nil,
		deployScatterDestination = nil,
		deployScatterDeadline = 0,
		deployScatterMinimumCompletionMeters = 0,
		patrolRefreshDelays = {},
		nextPatrolRefreshTime = nil,
		debugHarmActive = false,
		moveFireContactActive = false,
		moveFireLastSeenTime = nil,
		moveFireLastContactName = nil,
		moveFireRouteResumeLockUntil = 0,
		launchAwaitSince = nil,
		launchAwaitContactName = nil,
		launchAwaitContactType = nil,
		lastLaunchMonitorSignature = nil,
		lastLaunchMonitorTime = nil,
		lastPreferredContactFeedName = nil,
		lastPreferredContactFeedTime = nil,
		launchReadyLatchedUntil = 0,
		launchReadyLastSeenTime = nil,
		launchReadyDroppedAt = nil,
		lastThreatProbeSignature = nil,
		lastThreatProbeTime = nil,
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
		defaultRouteReissueFallbackCount = (config and config.defaultRouteReissueFallbackCount) or SkynetIADSMobilePatrol.DEFAULT_ROUTE_REISSUE_FALLBACK_COUNT,
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

	local function shouldSuppressManagedTargetCycleAutoDark(entry)
		if entry == nil or entry.manager == nil then
			return false
		end
		local siblingInfo = entry.manager.getSiblingInfo and entry.manager:getSiblingInfo(entry) or nil
		if siblingInfo and siblingInfo.role == "passive" then
			if siblingInfo.passiveMode == "standby" or siblingInfo.passiveMode == "hold_dark" then
				return false
			end
		end
		if entry.element and (entry.element.harmSilenceID ~= nil or entry.element.harmRelocationInProgress == true) then
			return true
		end
		if entry.combatCommitted == true then
			return true
		end
		if entry.state == "deployed" or entry.state == "deploy_scattering" or entry.state == "harm_evading" then
			return true
		end
		if entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true and entry.combatMode ~= "patrolling" then
			return true
		end
		if siblingInfo and siblingInfo.role == "passive" and siblingInfo.passiveMode == "relocate" then
			return true
		end
		return false
	end

	local originalSAMTargetCycleUpdateEnd = SkynetIADSSamSite.targetCycleUpdateEnd
	function SkynetIADSSamSite:targetCycleUpdateEnd()
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local autoDarkWouldTrigger =
			self.targetsInRange == false
			and self.actAsEW == false
			and self:getAutonomousState() == false
			and self:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI

		if entry and autoDarkWouldTrigger then
			if shouldSuppressManagedTargetCycleAutoDark(entry) then
				if entry.manager and entry.manager.traceStateSnapshot then
					entry.manager:traceStateSnapshot(entry, "target_cycle_hold_live", {
						source = "target_cycle_update_end",
						note = "auto_dark_suppressed",
					}, "SkynetIADSSamSite:targetCycleUpdateEnd")
				end
				return
			end
			if entry.manager and entry.manager.setOrderTraceContext then
				entry.manager:setOrderTraceContext(entry, "target_cycle_auto_dark", {
					source = "target_cycle_update_end",
					note = "targetsInRange=N",
				}, "SkynetIADSSamSite:targetCycleUpdateEnd")
			end
		end

		return originalSAMTargetCycleUpdateEnd(self)
	end

	local originalSAMInformOfContact = SkynetIADSSamSite.informOfContact
	function SkynetIADSSamSite:informOfContact(contact)
		local hadTargetInRange = self.targetsInRange == true
		local entry = SkynetIADSMobilePatrol.getEntryForElement(self)
		local now = timer.getTime()
		local hadRecentMoveFireContact = hasRecentMoveFireContactSession(entry, now)
		local moveFireCapable = entry and entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true
		local siblingInfo = entry and entry.manager and entry.manager.getSiblingInfo and entry.manager:getSiblingInfo(entry) or nil
		local passiveSiblingBlocked =
			siblingInfo ~= nil
			and siblingInfo.role == "passive"
			and (
				siblingInfo.passiveMode == "standby"
				or siblingInfo.passiveMode == "hold_dark"
				or siblingInfo.passiveMode == "relocate"
			)
		if entry and entry.kind == "MSAM" and isAirContact(contact) == false then
			return nil
		end
		if entry and entry.kind == "MSAM" and passiveSiblingBlocked then
			if entry.manager and entry.manager.traceEntryCommand then
				entry.manager:traceEntryCommand(entry, "sibling_passive_contact_block", {
					event = "decision",
					outcome = "blocked",
					source = "sibling_coord",
					note = "mode=" .. tostring(siblingInfo.passiveMode),
				}, "SkynetIADSSamSite:informOfContact")
			end
			return nil
		end
		if entry and entry.kind == "MSAM" and moveFireCapable then
			if isAirContact(contact) ~= true then
				return nil
			end
			if entry.combatMode == "harm_silent" or self.harmSilenceID ~= nil or self.harmRelocationInProgress == true then
				return nil
			end
			if self:areGoLiveConstraintsSatisfied(contact) ~= true then
				return nil
			end
			local threatRangeMeters = entry.manager and entry.manager.getThreatRangeMeters and entry.manager:getThreatRangeMeters(entry) or 0
			if threatRangeMeters == nil or threatRangeMeters <= 0 then
				return nil
			end
			local contactDistanceMeters = entry.manager:getContactDistanceMeters(entry, contact)
			local directUnit, directUnitDistanceMeters = entry.manager:findNearestEnemyAircraftUnit(entry, threatRangeMeters)
			local effectiveDistanceMeters = contactDistanceMeters
			if directUnit ~= nil and directUnitDistanceMeters < effectiveDistanceMeters then
				effectiveDistanceMeters = directUnitDistanceMeters
			end
			if effectiveDistanceMeters > threatRangeMeters then
				return nil
			end
			local result = originalSAMInformOfContact(self, contact)
			touchMoveFireContactSession(entry, contact)
			if entry.state == "patrolling"
				and hadRecentMoveFireContact ~= true
				and entry.manager
				and entry.manager.issuePatrolRoute
				and shouldIssueMoveFireRouteResume(entry, self, now)
			then
				markMoveFireRouteResumeIssued(entry, now)
				entry.manager:setOrderTraceContext(entry, "move_fire_contact_route_resume", {
					source = "inform_of_contact_move_fire",
					contactName = entry.manager:getContactName(contact),
					contactType = entry.manager:getContactTypeName(contact),
					distanceNm = toRoundedNm(effectiveDistanceMeters),
					threatRangeNm = toRoundedNm(threatRangeMeters),
				}, "SkynetIADSSamSite:informOfContact")
				entry.manager:issuePatrolRoute(entry)
			end
			if entry.manager and hadRecentMoveFireContact ~= true then
				entry.manager:log(
					"informOfContact moving | "
					.. entry.groupName
					.. " | contact="
					.. entry.manager:getContactName(contact)
					.. " | distance="
					.. tostring(toRoundedNm(effectiveDistanceMeters))
					.. "nm | threatRange="
					.. tostring(toRoundedNm(threatRangeMeters))
					.. "nm"
				)
			end
			return result
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
			if element.iads and element.iads.traceElementCommand then
				element.iads:traceElementCommand(element, "harm_move_resume", {
					event = "decision",
					outcome = "blocked",
					reason = "already_defending_harm",
					originModule = "skynet-iads-mobile-patrol.lua",
					originFunction = "goSilentToEvadeHARMWhileMoving",
				})
			end
			return false
		end
		if element.harmReactionLockUntil ~= nil and now < element.harmReactionLockUntil then
			if element.iads and element.iads.traceElementCommand then
				element.iads:traceElementCommand(element, "harm_move_resume", {
					event = "decision",
					outcome = "blocked",
					reason = "reaction_lock",
					note = "lockRemaining=" .. tostring(mist.utils.round(element.harmReactionLockUntil - now, 1)),
					originModule = "skynet-iads-mobile-patrol.lua",
					originFunction = "goSilentToEvadeHARMWhileMoving",
				})
			end
			return false
		end
		element.harmReactionLockUntil = now + element.harmReactionCooldownSeconds
		element.minHarmShutdownTime = element:calculateMinimalShutdownTimeInSeconds(timeToImpact)
		element.maxHarmShutDownTime = element:calculateMaximalShutdownTimeInSeconds(element.minHarmShutdownTime)
		local calculatedShutdownTime = element:calculateHARMShutdownTime()
		element.harmShutdownTime = math.max(6, math.min(18, calculatedShutdownTime))
		if element.iads:getDebugSettings().harmDefence then
			element.iads:printOutputToLog("HARM DEFENCE SHUTDOWN + CONTINUE MOVING: "..element:getDCSName().." | FOR: "..element.harmShutdownTime.." seconds | RAW: "..calculatedShutdownTime.." seconds | TTI: "..timeToImpact)
		end
		element.harmSilenceID = mist.scheduleFunction(SkynetIADSAbstractRadarElement.finishHarmDefence, {element}, timer.getTime() + element.harmShutdownTime, 1)
		setElementMovingSilenceState(element)
		if element.iads and element.iads.traceElementCommand then
			element.iads:traceElementCommand(element, "harm_silent_continue_moving", {
				outcome = "issued",
				reason = "harm_detected",
				harmTTI = timeToImpact and mist.utils.round(timeToImpact, 1) or nil,
				harmShutdown = element.harmShutdownTime and mist.utils.round(element.harmShutdownTime, 1) or nil,
				originModule = "skynet-iads-mobile-patrol.lua",
				originFunction = "goSilentToEvadeHARMWhileMoving",
			})
		end
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
				resetMoveFireContactSession(entry)
				if entry.manager and entry.manager.advancePatrol then
					local resumedRoute = false
					local fallbackPatrolRouteIssued = false
					pcall(function()
						resumedRoute = entry.manager:advancePatrol(entry, true)
					end)
					if resumedRoute ~= true and entry.manager.issuePatrolRoute then
						pcall(function()
							fallbackPatrolRouteIssued = entry.manager:issuePatrolRoute(entry) == true
						end)
					end
					if resumedRoute == true and entry.manager.issuePatrolRoute then
						pcall(function()
							entry.manager:issuePatrolRoute(entry)
						end)
					end
					if entry.manager and entry.manager.traceEntryCommand then
						entry.manager:traceEntryCommand(entry, "harm_move_resume", {
							event = "decision",
							outcome =
								resumedRoute == true and "advance_patrol"
								or (fallbackPatrolRouteIssued == true and "patrol_route")
								or "failed",
							reason = "harm_detected",
							source = "move_fire_harm_resume",
							advancePatrolResult = resumedRoute == true and "Y" or "N",
							issuePatrolRouteResult = fallbackPatrolRouteIssued == true and "Y" or "N",
						}, "SkynetIADSAbstractRadarElement:goSilentToEvadeHARM")
					end
				end
			else
				entry.state = "harm_evading"
			end
			entry.noThreatSince = nil
			entry.debugHarmActive = true
			entry.debugLastCombatAnnouncementKey = nil
			if entry.manager and entry.manager.setOrderTraceContext then
				entry.manager:setOrderTraceContext(entry, "harm_evasion_start", {
					source = "harm_detected",
					harmTTI = timeToImpact and mist.utils.round(timeToImpact, 1) or nil,
					harmShutdown = self.harmShutdownTime and mist.utils.round(self.harmShutdownTime, 1) or nil,
				}, "SkynetIADSAbstractRadarElement:goSilentToEvadeHARM")
			end
			if entry.manager and entry.manager.traceStateSnapshot then
				entry.manager:traceStateSnapshot(entry, "harm_evasion_start", {
					source = "harm_detected",
					harmTTI = timeToImpact and mist.utils.round(timeToImpact, 1) or nil,
					harmShutdown = self.harmShutdownTime and mist.utils.round(self.harmShutdownTime, 1) or nil,
				}, "SkynetIADSAbstractRadarElement:goSilentToEvadeHARM")
			end
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " enter HARM evasion")
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
				resetMoveFireContactSession(entry)
				if entry.manager.advancePatrol then
					local resumedRoute = false
					local fallbackPatrolRouteIssued = false
					pcall(function()
						resumedRoute = entry.manager:advancePatrol(entry, true)
					end)
					if resumedRoute ~= true and entry.manager.issuePatrolRoute then
						if entry.manager.setOrderTraceContext then
							entry.manager:setOrderTraceContext(entry, "harm_resume_patrol", {
								source = "harm_silence_expired",
							}, "SkynetIADSAbstractRadarElement.finishHarmDefence")
						end
						pcall(function()
							fallbackPatrolRouteIssued = entry.manager:issuePatrolRoute(entry) == true
						end)
					end
					if entry.manager and entry.manager.traceEntryCommand then
						entry.manager:traceEntryCommand(entry, "harm_move_resume", {
							event = "decision",
							outcome =
								resumedRoute == true and "advance_patrol"
								or (fallbackPatrolRouteIssued == true and "patrol_route")
								or "failed",
							reason = "harm_silence_expired",
							source = "move_fire_harm_resume",
							advancePatrolResult = resumedRoute == true and "Y" or "N",
							issuePatrolRouteResult = fallbackPatrolRouteIssued == true and "Y" or "N",
						}, "SkynetIADSAbstractRadarElement.finishHarmDefence")
					end
				end
			end
			entry.debugHarmActive = false
			entry.debugLastCombatAnnouncementKey = nil
			if entry.manager and entry.manager.traceEntryCommand then
				entry.manager:traceEntryCommand(entry, "harm_evasion_complete", {
					outcome = "completed",
					reason = "harm_silence_expired",
				}, "SkynetIADSAbstractRadarElement.finishHarmDefence")
			end
			if entry.manager and entry.manager.traceStateSnapshot then
				entry.manager:traceStateSnapshot(entry, "harm_evasion_complete", {
					source = "harm_silence_expired",
				}, "SkynetIADSAbstractRadarElement.finishHarmDefence")
			end
			if shouldAnnounce and entry.manager and entry.manager.notifyDebug then
				entry.manager:notifyDebug(entry.groupName .. " HARM evasion complete")
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
