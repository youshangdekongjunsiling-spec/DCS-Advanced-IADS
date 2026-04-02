do

SkynetIADSOrderTrace = {}
SkynetIADSOrderTrace.__index = SkynetIADSOrderTrace

local function safeString(value)
	if value == nil then
		return nil
	end
	if type(value) == "boolean" then
		return value and "true" or "false"
	end
	if type(value) == "number" then
		return tostring(value)
	end
	if type(value) == "table" then
		if value.x ~= nil and (value.z ~= nil or value.y ~= nil) then
			local x = math.floor((value.x or 0) + 0.5)
			local z = math.floor(((value.z or value.y) or 0) + 0.5)
			return x .. "," .. z
		end
		return tostring(value)
	end
	local text = tostring(value)
	text = string.gsub(text, "[\r\n]+", " ")
	text = string.gsub(text, "|", "/")
	text = string.gsub(text, "%s%s+", " ")
	return text
end

local function safeRound(value, digits)
	if type(value) ~= "number" then
		return value
	end
	local precision = 10 ^ (digits or 1)
	return math.floor((value * precision) + 0.5) / precision
end

local function safeBoolFlag(value)
	if value == nil then
		return nil
	end
	return value and "Y" or "N"
end

local function mergeInto(target, source, overwrite)
	if source == nil then
		return target
	end
	for key, value in pairs(source) do
		if overwrite == true or target[key] == nil then
			target[key] = value
		end
	end
	return target
end

local function sanitizeFileComponent(value)
	local text = safeString(value) or "skynet"
	text = string.gsub(text, "[\\/:*?\"<>|]", "_")
	text = string.gsub(text, "%s+", "_")
	if text == "" then
		text = "skynet"
	end
	return text
end

local function formatClock(seconds)
	local totalSeconds = math.max(0, math.floor((seconds or 0) + 0.5))
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local secs = totalSeconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function SkynetIADSOrderTrace:create(iads, options)
	local trace = {}
	setmetatable(trace, SkynetIADSOrderTrace)
	trace.iads = iads
	trace.options = options or {}
	trace.sequence = 0
	trace.warningIssued = false
	trace.filePath = trace:resolveLogPath()
	trace.fileSinkAvailable = io ~= nil and io.open ~= nil
	trace:writeSessionBanner("START")
	return trace
end

function SkynetIADSOrderTrace:resolveLogPath()
	local explicitPath = self.options.filePath
	if explicitPath ~= nil then
		return explicitPath
	end
	local explicitDirectory = self.options.logDirectory
	local fileName = self.options.fileName
	if fileName == nil then
		fileName = "skynet-order-trace-" .. sanitizeFileComponent(self.iads and self.iads.name or "iads") .. ".log"
	end

	local directory = explicitDirectory
	if directory == nil and lfs ~= nil and lfs.writedir ~= nil then
		local writableRoot = lfs.writedir()
		if writableRoot ~= nil then
			local logsRoot = writableRoot .. "Logs"
			local skynetRoot = logsRoot .. "\\Skynet"
			pcall(function()
				lfs.mkdir(logsRoot)
			end)
			pcall(function()
				lfs.mkdir(skynetRoot)
			end)
			directory = skynetRoot
		end
	end

	if directory ~= nil then
		if string.sub(directory, -1) ~= "\\" and string.sub(directory, -1) ~= "/" then
			directory = directory .. "\\"
		end
		return directory .. fileName
	end

	return fileName
end

function SkynetIADSOrderTrace:getMissionTimeSeconds()
	local okAbs, absTime = pcall(function()
		return timer.getAbsTime()
	end)
	if okAbs == true and absTime ~= nil then
		return absTime
	end
	local okMission, missionTime = pcall(function()
		return timer.getTime()
	end)
	if okMission == true and missionTime ~= nil then
		return missionTime
	end
	return 0
end

function SkynetIADSOrderTrace:emitFallbackWarning(message)
	if self.warningIssued == true then
		return
	end
	self.warningIssued = true
	if env and env.info then
		env.info("SKYNET ORDER TRACE: " .. tostring(message), false)
	end
end

function SkynetIADSOrderTrace:writeLine(line)
	if self.fileSinkAvailable ~= true then
		self:emitFallbackWarning("file output unavailable because io.open is not accessible. MissionScripting.lua must allow io/lfs.")
		return false
	end

	local okWrite, writeError = pcall(function()
		local handle = io.open(self.filePath, "a")
		if handle == nil then
			error("unable to open " .. tostring(self.filePath))
		end
		handle:write(line .. "\n")
		handle:flush()
		handle:close()
	end)
	if okWrite ~= true then
		self:emitFallbackWarning("write failed for " .. tostring(self.filePath) .. " | " .. tostring(writeError))
		return false
	end
	return true
end

function SkynetIADSOrderTrace:writeSessionBanner(label)
	local line = table.concat({
		"==== SKYNET ORDER TRACE " .. tostring(label) .. " ====",
		"clock=" .. formatClock(self:getMissionTimeSeconds()),
		"iads=" .. safeString(self.iads and self.iads.name or "unnamed"),
		"file=" .. safeString(self.filePath),
	}, " | ")
	self:writeLine(line)
end

function SkynetIADSOrderTrace:getMobilePatrolEntry(element)
	local mobilePatrolClass = rawget(_G, "SkynetIADSMobilePatrol")
	if mobilePatrolClass and mobilePatrolClass.getEntryForElement then
		local okEntry, entry = pcall(function()
			return mobilePatrolClass.getEntryForElement(element)
		end)
		if okEntry == true then
			return entry
		end
	end
	return nil
end

function SkynetIADSOrderTrace:getSiblingInfo(element)
	local siblingClass = rawget(_G, "SkynetIADSSiblingCoordination")
	if siblingClass and siblingClass.getFamilyForElement then
		local okInfo, info = pcall(function()
			return siblingClass.getFamilyForElement(element)
		end)
		if okInfo == true then
			return info
		end
	end
	return nil
end

function SkynetIADSOrderTrace:setElementContext(element, context)
	if type(element) == "table" then
		element._skynetOrderTraceContext = context
	end
end

function SkynetIADSOrderTrace:getElementContext(element)
	if type(element) == "table" then
		return element._skynetOrderTraceContext
	end
	return nil
end

function SkynetIADSOrderTrace:clearElementContext(element)
	if type(element) == "table" then
		element._skynetOrderTraceContext = nil
	end
end

function SkynetIADSOrderTrace:buildElementSnapshot(element)
	local snapshot = {}
	if element == nil then
		return snapshot
	end
	local okName, name = pcall(function()
		return element:getDCSName()
	end)
	if okName and name then
		snapshot.element = name
	end
	local okNato, natoName = pcall(function()
		return element:getNatoName()
	end)
	if okNato and natoName then
		snapshot.nato = natoName
	end
	local okDestroyed, destroyed = pcall(function()
		return element:isDestroyed()
	end)
	if okDestroyed then
		snapshot.destroyed = safeBoolFlag(destroyed)
	end
	local okActive, active = pcall(function()
		return element:isActive()
	end)
	if okActive then
		snapshot.active = safeBoolFlag(active)
	end
	local okAutonomous, autonomous = pcall(function()
		return element:getAutonomousState()
	end)
	if okAutonomous then
		snapshot.autonomous = safeBoolFlag(autonomous)
	end
	if element.targetsInRange ~= nil then
		snapshot.targetsInRange = safeBoolFlag(element.targetsInRange == true)
	end
	snapshot.defendingHARM = safeBoolFlag(element.harmSilenceID ~= nil or element.harmRelocationInProgress == true)
	local okMissiles, missilesInFlight = pcall(function()
		return element:getNumberOfMissilesInFlight()
	end)
	if okMissiles then
		snapshot.missilesInFlight = missilesInFlight
	end
	local okAmmo, hasAmmo = pcall(function()
		return element:hasRemainingAmmo()
	end)
	if okAmmo then
		snapshot.hasAmmo = safeBoolFlag(hasAmmo)
	end
	local okActAsEW, actAsEW = pcall(function()
		return element:getActAsEW()
	end)
	if okActAsEW then
		snapshot.actAsEW = safeBoolFlag(actAsEW)
	end
	return snapshot
end

function SkynetIADSOrderTrace:buildEntrySnapshot(entry)
	local snapshot = {}
	if entry == nil then
		return snapshot
	end
	snapshot.group = entry.groupName
	snapshot.kind = entry.kind
	snapshot.state = entry.state
	snapshot.combatMode = entry.combatMode
	snapshot.waypoint = entry.currentWaypointIndex
	snapshot.routePoints = entry.routePoints and #entry.routePoints or nil
	snapshot.speedKmph = entry.patrolSpeedKmph
	snapshot.currentDestination = entry.currentDestination
	snapshot.moveFireCapable = entry.manager and entry.manager.isMoveFireCapable and entry.manager:isMoveFireCapable(entry) == true and "Y" or "N"
	return snapshot
end

function SkynetIADSOrderTrace:buildSiblingSnapshot(element)
	local snapshot = {}
	local siblingInfo = self:getSiblingInfo(element)
	if siblingInfo == nil then
		return snapshot
	end
	snapshot.family = siblingInfo.name
	snapshot.familyMode = siblingInfo.mode
	snapshot.familyRole = siblingInfo.role
	snapshot.familyReason = siblingInfo.reason
	snapshot.passiveMode = siblingInfo.passiveMode
	return snapshot
end

function SkynetIADSOrderTrace:applyTriggerInfoFields(target, triggerInfo)
	if triggerInfo == nil then
		return
	end
	target.source = target.source or triggerInfo.source
	target.contact = target.contact or triggerInfo.contactName
	target.contactType = target.contactType or triggerInfo.contactType
	target.distanceNm = target.distanceNm or triggerInfo.distanceNm
	target.contactDistanceNm = target.contactDistanceNm or triggerInfo.contactDistanceNm
	target.directDistanceNm = target.directDistanceNm or triggerInfo.directDistanceNm
	target.effectiveDistanceNm = target.effectiveDistanceNm or triggerInfo.effectiveDistanceNm
	target.threatRangeNm = target.threatRangeNm or triggerInfo.threatRangeNm
	target.engageRangeNm = target.engageRangeNm or triggerInfo.engageRangeNm
	target.closureNmps = target.closureNmps or triggerInfo.closingRateNmps
	target.directUnit = target.directUnit or triggerInfo.directUnitName
	target.note = target.note or triggerInfo.note
end

function SkynetIADSOrderTrace:normalizeDetails(details)
	local normalized = {}
	if details then
		mergeInto(normalized, details, true)
	end
	local context = details and details.context or nil
	if context then
		mergeInto(normalized, context, false)
		self:applyTriggerInfoFields(normalized, context.triggerInfo)
	end
	self:applyTriggerInfoFields(normalized, normalized.triggerInfo)
	if normalized.distanceNm ~= nil then
		normalized.distanceNm = safeRound(normalized.distanceNm, 1)
	end
	if normalized.contactDistanceNm ~= nil then
		normalized.contactDistanceNm = safeRound(normalized.contactDistanceNm, 1)
	end
	if normalized.directDistanceNm ~= nil then
		normalized.directDistanceNm = safeRound(normalized.directDistanceNm, 1)
	end
	if normalized.effectiveDistanceNm ~= nil then
		normalized.effectiveDistanceNm = safeRound(normalized.effectiveDistanceNm, 1)
	end
	if normalized.threatRangeNm ~= nil then
		normalized.threatRangeNm = safeRound(normalized.threatRangeNm, 1)
	end
	if normalized.engageRangeNm ~= nil then
		normalized.engageRangeNm = safeRound(normalized.engageRangeNm, 1)
	end
	if normalized.closureNmps ~= nil then
		normalized.closureNmps = safeRound(normalized.closureNmps, 2)
	end
	return normalized
end

function SkynetIADSOrderTrace:appendField(parts, key, value)
	local text = safeString(value)
	if text == nil or text == "" then
		return
	end
	parts[#parts + 1] = key .. "=" .. text
end

function SkynetIADSOrderTrace:traceCommand(details)
	local normalized = self:normalizeDetails(details or {})
	self.sequence = self.sequence + 1

	local parts = {
		"seq=" .. tostring(self.sequence),
		"clock=" .. formatClock(self:getMissionTimeSeconds()),
		"iads=" .. safeString(self.iads and self.iads.name or "unnamed"),
	}

	local orderedKeys = {
		"event",
		"command",
		"originModule",
		"originFunction",
		"scope",
		"outcome",
		"group",
		"element",
		"nato",
		"kind",
		"state",
		"combatMode",
		"reason",
		"source",
		"contact",
		"contactType",
		"distanceNm",
		"contactDistanceNm",
		"directDistanceNm",
		"effectiveDistanceNm",
		"threatRangeNm",
		"engageRangeNm",
		"closureNmps",
		"shouldDeploy",
		"shouldGoLive",
		"weaponHold",
		"moveFireCapable",
		"family",
		"familyMode",
		"familyRole",
		"familyReason",
		"passiveMode",
		"waypoint",
		"routePoints",
		"speedKmph",
		"currentDestination",
		"destination",
		"harmTTI",
		"harmShutdown",
		"active",
		"autonomous",
		"targetsInRange",
		"defendingHARM",
		"missilesInFlight",
		"hasAmmo",
		"actAsEW",
		"destroyed",
		"note",
	}
	local seen = {}
	for i = 1, #orderedKeys do
		local key = orderedKeys[i]
		seen[key] = true
		self:appendField(parts, key, normalized[key])
	end

	local extraKeys = {}
	for key, _ in pairs(normalized) do
		if type(key) == "string" and seen[key] ~= true and key ~= "context" and key ~= "triggerInfo" then
			extraKeys[#extraKeys + 1] = key
		end
	end
	table.sort(extraKeys)
	for i = 1, #extraKeys do
		local key = extraKeys[i]
		self:appendField(parts, key, normalized[key])
	end

	return self:writeLine(table.concat(parts, " | "))
end

function SkynetIADSOrderTrace:traceEntryCommand(entry, command, details)
	local payload = {}
	mergeInto(payload, self:buildEntrySnapshot(entry), true)
	if entry and entry.element then
		mergeInto(payload, self:buildElementSnapshot(entry.element), false)
		mergeInto(payload, self:buildSiblingSnapshot(entry.element), false)
		mergeInto(payload, self:getElementContext(entry.element), false)
	end
	if entry and type(entry) == "table" then
		mergeInto(payload, entry._skynetOrderTraceContext, false)
	end
	mergeInto(payload, details, true)
	payload.command = command or payload.command or "entry_command"
	payload.event = payload.event or "ai_command"
	local ok = self:traceCommand(payload)
	if entry and entry.element then
		self:clearElementContext(entry.element)
	end
	if entry and type(entry) == "table" then
		entry._skynetOrderTraceContext = nil
	end
	return ok
end

function SkynetIADSOrderTrace:traceElementCommand(element, command, details)
	local payload = {}
	mergeInto(payload, self:buildElementSnapshot(element), true)
	local entry = self:getMobilePatrolEntry(element)
	mergeInto(payload, self:buildEntrySnapshot(entry), false)
	mergeInto(payload, self:buildSiblingSnapshot(element), false)
	mergeInto(payload, self:getElementContext(element), false)
	mergeInto(payload, details, true)
	payload.command = command or payload.command or "element_command"
	payload.event = payload.event or "ai_command"
	local ok = self:traceCommand(payload)
	self:clearElementContext(element)
	if entry and type(entry) == "table" then
		entry._skynetOrderTraceContext = nil
	end
	return ok
end

end
