do

SkynetIADSGPSSpoofer = {}
SkynetIADSGPSSpoofer.__index = SkynetIADSGPSSpoofer

local NM_TO_METERS = 1852

local DEFAULT_SPOOFER_TYPE_NAMES = {
	["GPS_Spoofer_Red"] = true,
	["GPS_Spoofer_Blue"] = true,
}

-- GPS / INS guided weapon type names collected from local DCS data:
-- MissionEditor/data/scripts/Enc/Weapon and Scripts/Speech/NATO.lua
local DEFAULT_GPS_WEAPON_TYPES = {
	["AGM_84E"] = true,
	["AGM_84H"] = true,
	["AGM_154"] = true,
	["AGM_154A"] = true,
	["AGM_154B"] = true,
	["GBU_31"] = true,
	["GBU_31_V_1B"] = true,
	["GBU_31_V_2B"] = true,
	["GBU_31_V_3B"] = true,
	["GBU_31_V_4B"] = true,
	["GBU_32_V_2B"] = true,
	["GBU_38"] = true,
	["GBU_54_V_1B"] = true,
	["CBU_103"] = true,
	["CBU_105"] = true,
	["CM_802AKG"] = true,
	["LS_6_100"] = true,
	["LS_6"] = true,
	["LS_6_500"] = true,
	["GB-6"] = true,
	["GB-6-HE"] = true,
	["GB-6-SFW"] = true,
}

local function cloneSet(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = value
	end
	return copy
end

local function getNow()
	return timer.getTime()
end

local function safeCall(fn, fallback)
	local ok, result = pcall(fn)
	if ok == true then
		return result
	end
	return fallback
end

local function getObjectName(object)
	if object == nil then
		return nil
	end
	return safeCall(function()
		return object:getName()
	end, nil)
end

local function getObjectTypeName(object)
	if object == nil then
		return nil
	end
	return safeCall(function()
		return object:getTypeName()
	end, nil)
end

local function getGroupName(group)
	if group == nil then
		return nil
	end
	return safeCall(function()
		return group:getName()
	end, nil)
end

local function vec2FromPoint(point)
	return {
		x = point.x,
		y = point.z,
	}
end

local function getGroundHeight(point)
	if point == nil then
		return 0
	end
	return land.getHeight(vec2FromPoint(point)) or 0
end

local function buildGroundPoint(x, z)
	local point = { x = x, z = z }
	point.y = getGroundHeight(point)
	return point
end

local function horizontalDistanceMeters(pointA, pointB)
	if pointA == nil or pointB == nil then
		return nil
	end
	local dx = (pointA.x or 0) - (pointB.x or 0)
	local dz = (pointA.z or 0) - (pointB.z or 0)
	return math.sqrt((dx * dx) + (dz * dz))
end

local function speedMetersPerSecond(velocity)
	if velocity == nil then
		return 0
	end
	local vx = velocity.x or 0
	local vy = velocity.y or 0
	local vz = velocity.z or 0
	return math.sqrt((vx * vx) + (vy * vy) + (vz * vz))
end

local function horizontalSpeedMetersPerSecond(velocity)
	if velocity == nil then
		return 0
	end
	local vx = velocity.x or 0
	local vz = velocity.z or 0
	return math.sqrt((vx * vx) + (vz * vz))
end

local function normalizeHorizontalVelocity(velocity)
	local horizontalSpeed = horizontalSpeedMetersPerSecond(velocity)
	if horizontalSpeed < 1 then
		return nil
	end
	return {
		x = velocity.x / horizontalSpeed,
		z = velocity.z / horizontalSpeed,
	}
end

local function offsetPoint(point, distanceMeters, bearingRadians)
	local x = point.x + (math.cos(bearingRadians) * distanceMeters)
	local z = point.z + (math.sin(bearingRadians) * distanceMeters)
	return buildGroundPoint(x, z)
end

local function getWeaponDescriptor(weapon)
	if weapon == nil then
		return {}
	end
	return safeCall(function()
		return weapon:getDesc() or {}
	end, {})
end

local function getWeaponKey(weapon)
	local weaponName = getObjectName(weapon)
	if weaponName ~= nil and weaponName ~= "" then
		return weaponName
	end
	return tostring(weapon)
end

local function getWarheadPower(desc)
	local warhead = desc and desc.warhead or nil
	local explosiveMass = 120
	if warhead ~= nil then
		explosiveMass = warhead.explosiveMass or warhead.expl_mass or warhead.mass or explosiveMass
	end
	if explosiveMass < 40 then
		explosiveMass = 40
	end
	if explosiveMass > 800 then
		explosiveMass = 800
	end
	return math.floor(explosiveMass + 0.5)
end

local function formatMetersToNm(distanceMeters)
	if type(distanceMeters) ~= "number" then
		return nil
	end
	return math.floor(((distanceMeters / NM_TO_METERS) * 10) + 0.5) / 10
end

local function runtimeNotify(message)
	local notifier = rawget(_G, "SkynetRuntimeDebugNotify")
	if notifier ~= nil then
		pcall(notifier, message)
	end
end

function SkynetIADSGPSSpoofer:create(iads, options)
	local spoofer = {}
	setmetatable(spoofer, SkynetIADSGPSSpoofer)
	spoofer.iads = iads
	spoofer.options = options or {}
	spoofer.spoofers = {}
	spoofer.spoofersByGroupName = {}
	spoofer.trackedWeapons = {}
	spoofer.taskID = nil
	spoofer.checkIntervalSeconds = spoofer.options.checkIntervalSeconds or 0.5
	spoofer.spoofRadiusMeters = (spoofer.options.spoofRadiusNm or 40) * NM_TO_METERS
	spoofer.offsetMinMeters = spoofer.options.offsetMinMeters or 50
	spoofer.offsetMaxMeters = spoofer.options.offsetMaxMeters or 200
	spoofer.terminalAglMeters = spoofer.options.terminalAglMeters or 180
	spoofer.baseTerminalDistanceMeters = spoofer.options.terminalDistanceMeters or 450
	spoofer.spoofTimeoutSeconds = spoofer.options.spoofTimeoutSeconds or 180
	spoofer.spooferTypeNames = cloneSet(DEFAULT_SPOOFER_TYPE_NAMES)
	spoofer.gpsWeaponTypes = cloneSet(DEFAULT_GPS_WEAPON_TYPES)
	if type(spoofer.options.spooferTypeNames) == "table" then
		spoofer:setSpooferTypeNames(spoofer.options.spooferTypeNames)
	end
	if type(spoofer.options.additionalGPSWeaponTypes) == "table" then
		for i = 1, #spoofer.options.additionalGPSWeaponTypes do
			local typeName = spoofer.options.additionalGPSWeaponTypes[i]
			if type(typeName) == "string" and typeName ~= "" then
				spoofer.gpsWeaponTypes[typeName] = true
			end
		end
	end
	return spoofer
end

function SkynetIADSGPSSpoofer:setSpooferTypeNames(typeNames)
	self.spooferTypeNames = {}
	for i = 1, #typeNames do
		local typeName = typeNames[i]
		if type(typeName) == "string" and typeName ~= "" then
			self.spooferTypeNames[typeName] = true
		end
	end
	return self
end

function SkynetIADSGPSSpoofer:getCoalitionId()
	return self.iads and self.iads.getCoalition and self.iads:getCoalition() or nil
end

function SkynetIADSGPSSpoofer:isEnemyShot(event)
	if event == nil or event.initiator == nil then
		return true
	end
	local initiatorCoalition = safeCall(function()
		return event.initiator:getCoalition()
	end, nil)
	local iadsCoalition = self:getCoalitionId()
	if initiatorCoalition == nil or iadsCoalition == nil then
		return true
	end
	return initiatorCoalition ~= iadsCoalition
end

function SkynetIADSGPSSpoofer:trace(command, details)
	if self.iads and self.iads.traceCommand then
		local payload = details or {}
		payload.command = command
		payload.scope = payload.scope or "gps_spoofer"
		payload.originModule = payload.originModule or "skynet-iads-gps-spoofer"
		return self.iads:traceCommand(payload)
	end
	return false
end

function SkynetIADSGPSSpoofer:getSpooferUnitsForGroup(group)
	if group == nil then
		return {}
	end
	local units = safeCall(function()
		return group:getUnits()
	end, nil)
	if units == nil then
		return {}
	end
	local spoofers = {}
	for i = 1, #units do
		local unit = units[i]
		if unit and unit:isExist() then
			local typeName = getObjectTypeName(unit)
			if typeName ~= nil and self.spooferTypeNames[typeName] == true then
				spoofers[#spoofers + 1] = unit
			end
		end
	end
	return spoofers
end

function SkynetIADSGPSSpoofer:isSpooferGroup(group)
	return #self:getSpooferUnitsForGroup(group) > 0
end

function SkynetIADSGPSSpoofer:addSpooferGroup(groupName)
	if groupName == nil or self.spoofersByGroupName[groupName] ~= nil then
		return false
	end
	local group = Group.getByName(groupName)
	if group == nil or group:isExist() == false then
		return false
	end
	local groupCoalition = safeCall(function()
		return group:getCoalition()
	end, nil)
	local iadsCoalition = self:getCoalitionId()
	if groupCoalition ~= nil and iadsCoalition ~= nil and groupCoalition ~= iadsCoalition then
		return false
	end
	if self:isSpooferGroup(group) == false then
		return false
	end
	local entry = {
		groupName = groupName,
	}
	self.spoofers[#self.spoofers + 1] = entry
	self.spoofersByGroupName[groupName] = entry
	self:trace("gps_spoofer_register", {
		event = "setup",
		group = groupName,
		note = "registered",
	})
	return true
end

function SkynetIADSGPSSpoofer:registerBySpooferTypeNames(typeNames)
	if type(typeNames) == "table" then
		self:setSpooferTypeNames(typeNames)
	end
	local registeredNames = {}
	for groupName, _ in pairs(mist.DBs.groupsByName) do
		if self:addSpooferGroup(groupName) then
			registeredNames[#registeredNames + 1] = groupName
		end
	end
	return #registeredNames, table.concat(registeredNames, ", ")
end

function SkynetIADSGPSSpoofer:start()
	if self.taskID ~= nil then
		mist.removeFunction(self.taskID)
	end
	self.taskID = mist.scheduleFunction(SkynetIADSGPSSpoofer.runCycle, { self }, getNow() + self.checkIntervalSeconds, self.checkIntervalSeconds)
	self:trace("gps_spoofer_start", {
		event = "lifecycle",
		outcome = "started",
		note = "checkInterval=" .. tostring(self.checkIntervalSeconds),
	})
end

function SkynetIADSGPSSpoofer:stop()
	if self.taskID ~= nil then
		mist.removeFunction(self.taskID)
		self.taskID = nil
	end
	self:trace("gps_spoofer_stop", {
		event = "lifecycle",
		outcome = "stopped",
	})
end

function SkynetIADSGPSSpoofer:isGPSWeaponType(typeName)
	return typeName ~= nil and self.gpsWeaponTypes[typeName] == true
end

function SkynetIADSGPSSpoofer:getLiveSpooferPositions()
	local positions = {}
	for i = 1, #self.spoofers do
		local entry = self.spoofers[i]
		local group = Group.getByName(entry.groupName)
		if group and group:isExist() then
			local units = self:getSpooferUnitsForGroup(group)
			for j = 1, #units do
				local unit = units[j]
				local point = safeCall(function()
					return unit:getPoint()
				end, nil)
				if point ~= nil then
					positions[#positions + 1] = {
						groupName = entry.groupName,
						unitName = getObjectName(unit),
						point = point,
					}
				end
			end
		end
	end
	return positions
end

function SkynetIADSGPSSpoofer:findNearestSpoofer(weaponPoint)
	local best = nil
	local bestDistance = nil
	local spoofers = self:getLiveSpooferPositions()
	for i = 1, #spoofers do
		local spoofer = spoofers[i]
		local distanceMeters = horizontalDistanceMeters(weaponPoint, spoofer.point)
		if distanceMeters ~= nil and distanceMeters <= self.spoofRadiusMeters then
			if bestDistance == nil or distanceMeters < bestDistance then
				best = spoofer
				bestDistance = distanceMeters
			end
		end
	end
	return best, bestDistance
end

function SkynetIADSGPSSpoofer:estimateImpactPoint(weaponPoint, velocity)
	if weaponPoint == nil then
		return nil
	end
	local forward = normalizeHorizontalVelocity(velocity or {})
	if forward == nil then
		return buildGroundPoint(weaponPoint.x, weaponPoint.z)
	end
	local aglMeters = math.max(0, (weaponPoint.y or 0) - getGroundHeight(weaponPoint))
	local verticalSpeed = (velocity and velocity.y) or 0
	local timeToGround = 0
	if verticalSpeed < -3 then
		timeToGround = aglMeters / math.abs(verticalSpeed)
	else
		timeToGround = aglMeters / 45
	end
	if timeToGround < 4 then
		timeToGround = 4
	elseif timeToGround > 60 then
		timeToGround = 60
	end
	local horizontalSpeed = horizontalSpeedMetersPerSecond(velocity)
	if horizontalSpeed < 30 then
		horizontalSpeed = 30
	end
	local travelDistance = horizontalSpeed * timeToGround
	local x = weaponPoint.x + (forward.x * travelDistance)
	local z = weaponPoint.z + (forward.z * travelDistance)
	return buildGroundPoint(x, z)
end

function SkynetIADSGPSSpoofer:getCurrentAimPoint(entry, weaponPoint)
	if entry.targetObject ~= nil then
		local exists = safeCall(function()
			return entry.targetObject:isExist()
		end, false)
		if exists == true then
			local targetPoint = safeCall(function()
				return entry.targetObject:getPoint()
			end, nil)
			if targetPoint ~= nil then
				return targetPoint, "target_object"
			end
		end
	end
	if entry.targetPoint ~= nil then
		return entry.targetPoint, "stored_target"
	end
	local estimate = self:estimateImpactPoint(weaponPoint, safeCall(function()
		return entry.weapon:getVelocity()
	end, nil))
	if estimate ~= nil then
		return estimate, "predicted"
	end
	return nil, "unknown"
end

function SkynetIADSGPSSpoofer:getTerminalRangeMeters(entry)
	local currentVelocity = safeCall(function()
		return entry.weapon:getVelocity()
	end, nil)
	local currentSpeed = speedMetersPerSecond(currentVelocity)
	local dynamicRange = currentSpeed * 1.5
	if dynamicRange < self.baseTerminalDistanceMeters then
		dynamicRange = self.baseTerminalDistanceMeters
	end
	return dynamicRange
end

function SkynetIADSGPSSpoofer:applySpoof(entry, spoofer, distanceMeters, weaponPoint)
	entry.spoofed = true
	entry.spoofedAt = getNow()
	entry.spooferGroup = spoofer.groupName
	entry.spooferUnit = spoofer.unitName
	entry.offsetMeters = math.random(self.offsetMinMeters, self.offsetMaxMeters)
	entry.offsetBearingRadians = math.rad(math.random(0, 359))
	local aimPoint, targetKind = self:getCurrentAimPoint(entry, weaponPoint)
	entry.originalAimPoint = aimPoint
	entry.targetKind = targetKind
	if aimPoint ~= nil then
		entry.spoofPoint = offsetPoint(aimPoint, entry.offsetMeters, entry.offsetBearingRadians)
	end
	self:trace("gps_spoof_apply", {
		event = "track",
		outcome = "spoofed",
		group = entry.spooferGroup,
		weaponName = entry.weaponKey,
		weaponType = entry.weaponType,
		distanceNm = formatMetersToNm(distanceMeters),
		offsetMeters = entry.offsetMeters,
		targetKind = entry.targetKind,
		target = entry.targetName,
		targetGroup = entry.targetGroupName,
		targetPoint = entry.originalAimPoint,
		spoofPoint = entry.spoofPoint,
	})
	runtimeNotify("GPS spoof "..tostring(entry.weaponType).." | spoofer="..tostring(entry.spooferGroup).." | offset="..tostring(entry.offsetMeters).."m")
end

function SkynetIADSGPSSpoofer:buildFallbackSpoofPoint(entry, weaponPoint)
	local aimPoint = self:estimateImpactPoint(weaponPoint, safeCall(function()
		return entry.weapon:getVelocity()
	end, nil))
	if aimPoint == nil then
		aimPoint = buildGroundPoint(weaponPoint.x, weaponPoint.z)
	end
	entry.originalAimPoint = aimPoint
	entry.spoofPoint = offsetPoint(aimPoint, entry.offsetMeters or self.offsetMinMeters, entry.offsetBearingRadians or 0)
	return entry.spoofPoint
end

function SkynetIADSGPSSpoofer:shouldDetonate(entry, weaponPoint)
	local spoofAge = getNow() - (entry.spoofedAt or getNow())
	if spoofAge >= self.spoofTimeoutSeconds then
		return true, "timeout"
	end
	local aglMeters = math.max(0, (weaponPoint.y or 0) - getGroundHeight(weaponPoint))
	if aglMeters <= self.terminalAglMeters then
		return true, "terminal_agl"
	end
	local terminalRangeMeters = self:getTerminalRangeMeters(entry)
	if entry.originalAimPoint ~= nil then
		local distanceToAim = horizontalDistanceMeters(weaponPoint, entry.originalAimPoint)
		if distanceToAim ~= nil and distanceToAim <= terminalRangeMeters then
			return true, "near_target"
		end
	end
	if entry.spoofPoint ~= nil then
		local distanceToSpoofPoint = horizontalDistanceMeters(weaponPoint, entry.spoofPoint)
		if distanceToSpoofPoint ~= nil and distanceToSpoofPoint <= terminalRangeMeters then
			return true, "near_spoof_point"
		end
	end
	return false, nil
end

function SkynetIADSGPSSpoofer:detonateSpoof(id, entry, reason, weaponPoint)
	local detonationPoint = entry.spoofPoint or self:buildFallbackSpoofPoint(entry, weaponPoint)
	if detonationPoint == nil then
		return self:removeTrackedWeapon(id, "no_spoof_point")
	end
	local weaponStillExists = safeCall(function()
		return Object.isExist(entry.weapon)
	end, false)
	if weaponStillExists == true then
		pcall(function()
			Object.destroy(entry.weapon)
		end)
	end
	pcall(function()
		trigger.action.explosion(detonationPoint, entry.warheadPower or 120)
	end)
	self:trace("gps_spoof_detonate", {
		event = "track",
		outcome = "detonated",
		reason = reason,
		group = entry.spooferGroup,
		weaponName = entry.weaponKey,
		weaponType = entry.weaponType,
		offsetMeters = entry.offsetMeters,
		target = entry.targetName,
		targetGroup = entry.targetGroupName,
		targetPoint = entry.originalAimPoint,
		spoofPoint = detonationPoint,
		warheadPower = entry.warheadPower,
	})
	runtimeNotify("GPS spoof detonate "..tostring(entry.weaponType).." | group="..tostring(entry.spooferGroup).." | reason="..tostring(reason))
	self.trackedWeapons[id] = nil
end

function SkynetIADSGPSSpoofer:removeTrackedWeapon(id, reason)
	local entry = self.trackedWeapons[id]
	if entry ~= nil then
		self:trace("gps_weapon_cleanup", {
			event = "track",
			outcome = "removed",
			reason = reason,
			weaponName = entry.weaponKey,
			weaponType = entry.weaponType,
			group = entry.spooferGroup,
		})
	end
	self.trackedWeapons[id] = nil
end

function SkynetIADSGPSSpoofer:trackWeapon(event)
	if event == nil or event.weapon == nil or self:isEnemyShot(event) == false then
		return
	end
	local weapon = event.weapon
	local weaponType = getObjectTypeName(weapon)
	if self:isGPSWeaponType(weaponType) == false then
		return
	end
	local weaponKey = getWeaponKey(weapon)
	if self.trackedWeapons[weaponKey] ~= nil then
		return
	end
	local desc = getWeaponDescriptor(weapon)
	local targetObject = safeCall(function()
		return Weapon.getTarget(weapon)
	end, nil)
	local targetName = getObjectName(targetObject)
	local targetType = getObjectTypeName(targetObject)
	local targetGroupName = nil
	if targetObject ~= nil then
		targetGroupName = safeCall(function()
			return targetObject:getGroup():getName()
		end, nil)
	end
	local targetPoint = nil
	if targetObject ~= nil then
		targetPoint = safeCall(function()
			return targetObject:getPoint()
		end, nil)
	end
	local initiatorName = getObjectName(event.initiator)
	local initiatorGroupName = nil
	if event.initiator ~= nil then
		initiatorGroupName = safeCall(function()
			return event.initiator:getGroup():getName()
		end, nil)
	end
	self.trackedWeapons[weaponKey] = {
		weapon = weapon,
		weaponKey = weaponKey,
		weaponType = weaponType,
		weaponGuidance = desc.guidance,
		warheadPower = getWarheadPower(desc),
		shotTime = getNow(),
		initiatorName = initiatorName,
		initiatorGroupName = initiatorGroupName,
		targetObject = targetObject,
		targetName = targetName,
		targetType = targetType,
		targetGroupName = targetGroupName,
		targetPoint = targetPoint,
		spoofed = false,
	}
	self:trace("gps_weapon_track", {
		event = "track",
		outcome = "tracked",
		weaponName = weaponKey,
		weaponType = weaponType,
		guidance = desc.guidance,
		initiator = initiatorName,
		initiatorGroup = initiatorGroupName,
		target = targetName,
		targetType = targetType,
		targetGroup = targetGroupName,
		targetPoint = targetPoint,
	})
end

function SkynetIADSGPSSpoofer:onEvent(event)
	if event == nil then
		return
	end
	if event.id == world.event.S_EVENT_BIRTH and event.initiator ~= nil then
		local group = safeCall(function()
			return event.initiator:getGroup()
		end, nil)
		local groupName = getGroupName(group)
		if groupName ~= nil then
			self:addSpooferGroup(groupName)
		end
	end
	if event.id == world.event.S_EVENT_SHOT or event.id == world.event.S_EVENT_WEAPON_ADD then
		self:trackWeapon(event)
	end
end

function SkynetIADSGPSSpoofer:updateTrackedWeapon(id, entry)
	local weaponExists = safeCall(function()
		return Object.isExist(entry.weapon)
	end, false)
	if weaponExists ~= true then
		return self:removeTrackedWeapon(id, "weapon_gone")
	end
	local weaponPoint = safeCall(function()
		return entry.weapon:getPoint()
	end, nil)
	if weaponPoint == nil then
		return self:removeTrackedWeapon(id, "no_point")
	end
	if entry.spoofed ~= true then
		local spoofer, distanceMeters = self:findNearestSpoofer(weaponPoint)
		if spoofer ~= nil then
			self:applySpoof(entry, spoofer, distanceMeters, weaponPoint)
		else
			return
		end
	end
	local shouldDetonate, reason = self:shouldDetonate(entry, weaponPoint)
	if shouldDetonate == true then
		self:detonateSpoof(id, entry, reason, weaponPoint)
	end
end

function SkynetIADSGPSSpoofer.runCycle(self)
	for id, entry in pairs(self.trackedWeapons) do
		self:updateTrackedWeapon(id, entry)
	end
	return getNow() + self.checkIntervalSeconds
end

end
