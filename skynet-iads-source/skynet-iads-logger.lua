do

SkynetIADSLogger = {}
SkynetIADSLogger.__index = SkynetIADSLogger

function SkynetIADSLogger:create(iads)
	local logger = {}
	setmetatable(logger, SkynetIADSLogger)
	logger.debugOutput = {}
	logger.debugOutput.IADSStatus = false
	logger.debugOutput.samWentDark = false
	logger.debugOutput.contacts = false
	logger.debugOutput.radarWentLive = false
	logger.debugOutput.jammerProbability = false
	logger.debugOutput.addedEWRadar = false
	logger.debugOutput.addedSAMSite = false
	logger.debugOutput.warnings = true
	logger.debugOutput.harmDefence = false
	logger.debugOutput.samSiteStatusEnvOutput = false
	logger.debugOutput.earlyWarningRadarStatusEnvOutput = false
	logger.debugOutput.commandCenterStatusEnvOutput = false
	logger.iads = iads
	return logger
end

function SkynetIADSLogger:getDebugSettings()
	return self.debugOutput
end

function SkynetIADSLogger:printOutput(output, typeWarning)
	if typeWarning == true and self:getDebugSettings().warnings or typeWarning == nil then
		if typeWarning == true then
			output = "WARNING: "..output
		end
		trigger.action.outText(output, 4)
	end
end

function SkynetIADSLogger:printOutputToLog(output)
	env.info("SKYNET: "..output, 4)
end

local function joinStrings(values, separator)
	if values == nil or #values == 0 then
		return ""
	end
	return table.concat(values, separator or ", ")
end

local function boolFlag(value)
	if value then
		return "Y"
	end
	return "N"
end

local function safeUnitAmmoCount(unit)
	if unit == nil or unit.isExist == nil or unit:isExist() == false then
		return 0
	end
	local okAmmo, ammo = pcall(function()
		return unit:getAmmo()
	end)
	if okAmmo ~= true or ammo == nil then
		return 0
	end
	local count = 0
	for i = 1, #ammo do
		local entry = ammo[i]
		if entry and entry.count and entry.count > 0 then
			count = count + entry.count
		end
	end
	return count
end

function SkynetIADSLogger:getMobilePatrolEntry(abstractRadarElement)
	if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
		return SkynetIADSMobilePatrol.getEntryForElement(abstractRadarElement)
	end
	return nil
end

function SkynetIADSLogger:getUsableParentEWCount(samSite)
	local parents = samSite:getParentRadars()
	local count = 0
	for i = 1, #parents do
		local parent = parents[i]
		if parent
			and parent:getActAsEW() == true
			and parent:isDestroyed() == false
			and parent:hasWorkingPowerSource()
			and parent:hasActiveConnectionNode()
		then
			count = count + 1
		end
	end
	return count
end

function SkynetIADSLogger:getSAMSiteStateLabel(samSite)
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	if samSite:isDestroyed() then
		return "DESTROYED"
	end
	if patrolEntry and patrolEntry.state == "harm_evading" then
		return "HARM_EVADING"
	end
	if samSite:isDefendingHARM() then
		return "HARM_DEFENCE"
	end
	if patrolEntry and patrolEntry.state == "patrolling" then
		return "PATROLLING"
	end
	if samSite:isActive() then
		if samSite:isJammed() then
			return "COMBAT_JAMMED"
		end
		return "COMBAT"
	end
	if samSite:getAutonomousState() then
		if samSite:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK then
			return "AUTONOMOUS_DARK"
		end
		return "AUTONOMOUS_DCS_AI"
	end
	if samSite:getActAsEW() then
		return "ACTING_AS_EW"
	end
	return "DARK"
end

function SkynetIADSLogger:getSAMSiteWhyText(samSite)
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	local usableParents = self:getUsableParentEWCount(samSite)
	if samSite:isDestroyed() then
		return "Launcher and radar assets are destroyed."
	end
	if patrolEntry and patrolEntry.state == "harm_evading" then
		return "Mobile patrol state is harm_evading; the group is repositioning to evade HARM."
	end
	if samSite:isDefendingHARM() then
		return "The site detected a HARM threat and is executing HARM defence."
	end
	if patrolEntry and patrolEntry.state == "patrolling" then
		return "Mobile patrol state is patrolling; emitters are forced dark until a threat enters the patrol trigger range."
	end
	if samSite:isActive() then
		if samSite.targetsInRange == true then
			return "A target is in range and go-live constraints are satisfied, so the site is active."
		end
		if samSite:getActAsEW() then
			return "The site is active because it is configured to act as EW."
		end
		return "The site is active due to current Skynet/DCS AI state."
	end
	if samSite:isJammed() then
		return "The site is currently jammed and not actively radiating."
	end
	if samSite:hasWorkingPowerSource() == false then
		return "The site has no working power source."
	end
	if samSite:hasActiveConnectionNode() == false then
		return "The site has no active connection node."
	end
	if self.iads:isCommandCenterUsable() == false then
		return "The command center is unavailable."
	end
	if samSite:hasWorkingRadar() == false then
		return "The site has no working radar."
	end
	if samSite:hasRemainingAmmo() == false and samSite:getActAsEW() == false then
		return "The site has no remaining ammunition."
	end
	if samSite:getAutonomousState() then
		if samSite:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK then
			return "The site is autonomous and configured to stay dark."
		end
		return "The site is autonomous and waiting for local DCS AI conditions to trigger."
	end
	if usableParents > 0 then
		return "The site is dark and waiting for a target to enter range or for Skynet to promote it from external EW coverage."
	end
	return "The site is dark because no target is in range and no higher-priority trigger is active."
end

function SkynetIADSLogger:getSAMSiteUnitRoleMap(samSite)
	local roleMap = {}
	local function markUnits(wrappers, roleName)
		for i = 1, #wrappers do
			local wrapper = wrappers[i]
			if wrapper and wrapper.getDCSRepresentation then
				local dcsObject = wrapper:getDCSRepresentation()
				if dcsObject and dcsObject.isExist and dcsObject:isExist() and dcsObject.getName then
					local unitName = dcsObject:getName()
					if roleMap[unitName] == nil then
						roleMap[unitName] = {}
					end
					roleMap[unitName][#roleMap[unitName] + 1] = roleName
				end
			end
		end
	end

	markUnits(samSite:getSearchRadars(), "Search")
	markUnits(samSite:getTrackingRadars(), "Track")
	markUnits(samSite:getLaunchers(), "Launcher")
	markUnits(samSite:getPowerSources(), "Power")
	markUnits(samSite:getConnectionNodes(), "Conn")

	local emitters = samSite:getEmitterRepresentations()
	for i = 1, #emitters do
		local emitter = emitters[i]
		if emitter and emitter.isExist and emitter:isExist() and emitter.getName then
			local emitterName = emitter:getName()
			if roleMap[emitterName] == nil then
				roleMap[emitterName] = {}
			end
			roleMap[emitterName][#roleMap[emitterName] + 1] = "Emitter"
		end
	end

	return roleMap
end

function SkynetIADSLogger:buildDetailedSAMSiteReport(samSite)
	if samSite == nil then
		return "Detailed State | SAM site not found"
	end

	local lines = {}
	local dcsGroup = samSite:getDCSRepresentation()
	local groupName = samSite:getDCSName()
	local patrolEntry = self:getMobilePatrolEntry(samSite)
	local roleMap = self:getSAMSiteUnitRoleMap(samSite)
	local detectedTargets = samSite:getDetectedTargets()
	local reasons = {}

	reasons[#reasons + 1] = "active=" .. boolFlag(samSite:isActive())
	reasons[#reasons + 1] = "targetsInRange=" .. boolFlag(samSite.targetsInRange == true)
	reasons[#reasons + 1] = "autonomous=" .. boolFlag(samSite:getAutonomousState())
	reasons[#reasons + 1] = "power=" .. (samSite:hasWorkingPowerSource() and "OK" or "DOWN")
	reasons[#reasons + 1] = "connection=" .. (samSite:hasActiveConnectionNode() and "OK" or "DOWN")
	reasons[#reasons + 1] = "cmd=" .. (self.iads:isCommandCenterUsable() and "OK" or "DOWN")
	reasons[#reasons + 1] = "radar=" .. (samSite:hasWorkingRadar() and "OK" or "DOWN")
	reasons[#reasons + 1] = "ammo=" .. (samSite:hasRemainingAmmo() and "OK" or "EMPTY")
	reasons[#reasons + 1] = "jammed=" .. boolFlag(samSite:isJammed())
	reasons[#reasons + 1] = "harm=" .. boolFlag(samSite:isDefendingHARM())
	reasons[#reasons + 1] = "actAsEW=" .. boolFlag(samSite:getActAsEW())
	reasons[#reasons + 1] = "parents=" .. tostring(self:getUsableParentEWCount(samSite))
	reasons[#reasons + 1] = "detected=" .. tostring(#detectedTargets)
	reasons[#reasons + 1] = "mif=" .. tostring(samSite:getNumberOfMissilesInFlight())
	if patrolEntry then
		reasons[#reasons + 1] = "mobilePatrol=" .. tostring(patrolEntry.state)
	end

	lines[#lines + 1] = "Detailed State"
	lines[#lines + 1] = "GROUP: " .. groupName .. " | NATO: " .. samSite:getNatoName() .. " | STATE: " .. self:getSAMSiteStateLabel(samSite)
	lines[#lines + 1] = "WHY: " .. self:getSAMSiteWhyText(samSite)
	lines[#lines + 1] = "FLAGS: " .. joinStrings(reasons, " | ")
	if patrolEntry and patrolEntry.lastDeployTrigger then
		local triggerInfo = patrolEntry.lastDeployTrigger
		local ageSeconds = 0
		if triggerInfo.time then
			ageSeconds = math.max(0, timer.getTime() - triggerInfo.time)
		end
		lines[#lines + 1] =
			"LAST DEPLOY: source=" .. tostring(triggerInfo.source)
			.. " | contact=" .. tostring(triggerInfo.contactName)
			.. " | type=" .. tostring(triggerInfo.contactType)
			.. " | distance=" .. tostring(triggerInfo.distanceNm) .. "nm"
			.. " | threatRange=" .. tostring(triggerInfo.threatRangeNm) .. "nm"
			.. " | age=" .. tostring(mist.utils.round(ageSeconds, 1)) .. "s"
	end
	if SkynetIADSSiblingCoordination and SkynetIADSSiblingCoordination.getFamilyForElement then
		local siblingInfo = SkynetIADSSiblingCoordination.getFamilyForElement(samSite)
		if siblingInfo then
			lines[#lines + 1] =
				"SIBLING: family=" .. tostring(siblingInfo.name)
				.. " | role=" .. tostring(siblingInfo.role)
				.. " | primary=" .. tostring(siblingInfo.primaryGroupName)
				.. " | reason=" .. tostring(siblingInfo.reason)
				.. " | passive=" .. tostring(siblingInfo.passiveAction)
		end
	end

	local parentNames = {}
	local parents = samSite:getParentRadars()
	for i = 1, #parents do
		parentNames[#parentNames + 1] = parents[i]:getDCSName()
	end
	if #parentNames > 0 then
		lines[#lines + 1] = "PARENTS: " .. joinStrings(parentNames, ", ")
	end

	local childNames = {}
	local children = samSite:getChildRadars()
	for i = 1, #children do
		childNames[#childNames + 1] = children[i]:getDCSName()
	end
	if #childNames > 0 then
		lines[#lines + 1] = "CHILDREN: " .. joinStrings(childNames, ", ")
	end

	lines[#lines + 1] = "UNITS:"
	if dcsGroup and dcsGroup.isExist and dcsGroup:isExist() then
		local units = dcsGroup:getUnits()
		for i = 1, #units do
			local unit = units[i]
			local unitName = unit:getName()
			local typeName = unit:getTypeName()
			local roles = roleMap[unitName] or { "Other" }
			local sensors = "N"
			local okSensors, sensorData = pcall(function()
				return unit:getSensors()
			end)
			if okSensors and sensorData ~= nil then
				sensors = "Y"
			end
			lines[#lines + 1] = string.format(
				"%d. %s | %s | ALIVE | Roles:%s | Sensors:%s | Ammo:%d",
				i,
				unitName,
				typeName,
				joinStrings(roles, "/"),
				sensors,
				safeUnitAmmoCount(unit)
			)
		end
	else
		lines[#lines + 1] = "GROUP DESTROYED"
	end

	return table.concat(lines, "\n")
end

function SkynetIADSLogger:printEarlyWarningRadarStatus()
	local ewRadars = self.iads:getEarlyWarningRadars()
	self:printOutputToLog("------------------------------------------ EW RADAR STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		local numConnectionNodes = #ewRadar:getConnectionNodes()
		local numPowerSources = #ewRadar:getPowerSources()
		local isActive = ewRadar:isActive()
		local connectionNodes = ewRadar:getConnectionNodes()
		local firstRadar = nil
		local radars = ewRadar:getRadars()
		
		--get the first existing radar to prevent issues in calculating the distance later on:
		--获取第一个现有雷达以防止稍后计算距离时出现问题：
		for i = 1, #radars do
			if radars[i]:isExist() then
				firstRadar = radars[i]
				break
			end
		
		end
		local numDamagedConnectionNodes = 0
		
		
		for j = 1, #connectionNodes do
			local connectionNode = connectionNodes[j]
			if connectionNode:isExist() == false then
				numDamagedConnectionNodes = numDamagedConnectionNodes + 1
			end
		end
		local intactConnectionNodes = numConnectionNodes - numDamagedConnectionNodes
		
		local powerSources = ewRadar:getPowerSources()
		local numDamagedPowerSources = 0
		for j = 1, #powerSources do
			local powerSource = powerSources[j]
			if powerSource:isExist() == false then
				numDamagedPowerSources = numDamagedPowerSources + 1
			end
		end
		local intactPowerSources = numPowerSources - numDamagedPowerSources 
		
		local detectedTargets = ewRadar:getDetectedTargets()
		local samSitesInCoveredArea = ewRadar:getChildRadars()
		
		local unitName = "DESTROYED"
		
		if ewRadar:getDCSRepresentation():isExist() then
			unitName = ewRadar:getDCSName()
		end
		
		self:printOutputToLog("UNIT: "..unitName.." | TYPE: "..ewRadar:getNatoName())
		self:printOutputToLog("ACTIVE: "..tostring(isActive).."| DETECTED TARGETS: "..#detectedTargets.." | DEFENDING HARM: "..tostring(ewRadar:isDefendingHARM()))
		if numConnectionNodes > 0 then
			self:printOutputToLog("CONNECTION NODES: "..numConnectionNodes.." | DAMAGED: "..numDamagedConnectionNodes.." | INTACT: "..intactConnectionNodes)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if numPowerSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..numPowerSources.." | DAMAGED:"..numDamagedPowerSources.." | INTACT: "..intactPowerSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		
		self:printOutputToLog("SAM SITES IN COVERED AREA: "..#samSitesInCoveredArea)
		for j = 1, #samSitesInCoveredArea do
			local samSiteCovered = samSitesInCoveredArea[j]
			self:printOutputToLog(samSiteCovered:getDCSName())
		end
		
		for j = 1, #detectedTargets do
			local contact = detectedTargets[j]
			if firstRadar ~= nil and firstRadar:isExist() then
				local distance = mist.utils.round(mist.utils.metersToNM(ewRadar:getDistanceInMetersToContact(firstRadar:getDCSRepresentation(), contact:getPosition().p)), 2)
				self:printOutputToLog("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | DISTANCE NM: "..distance)
			end
		end
		
		self:printOutputToLog("---------------------------------------------------")
		
	end

end

function SkynetIADSLogger:getMetaInfo(abstractElementSupport)
	local info = {}
	info.numSources = #abstractElementSupport
	info.numDamagedSources = 0
	info.numIntactSources = 0
	for j = 1, #abstractElementSupport do
		local source = abstractElementSupport[j]
		if source:isExist() == false then
			info.numDamagedSources = info.numDamagedSources + 1
		end
	end
	info.numIntactSources = info.numSources - info.numDamagedSources
	return info
end

function SkynetIADSLogger:printSAMSiteStatus()
	local samSites = self.iads:getSAMSites()
	
	self:printOutputToLog("------------------------------------------ SAM STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	for i = 1, #samSites do
		local samSite = samSites[i]
		local numConnectionNodes = #samSite:getConnectionNodes()
		local numPowerSources = #samSite:getPowerSources()
		local isAutonomous = samSite:getAutonomousState()
		local isActive = samSite:isActive()
		
		local connectionNodes = samSite:getConnectionNodes()
		local firstRadar = samSite:getRadars()[1]
		local numDamagedConnectionNodes = 0
		for j = 1, #connectionNodes do
			local connectionNode = connectionNodes[j]
			if connectionNode:isExist() == false then
				numDamagedConnectionNodes = numDamagedConnectionNodes + 1
			end
		end
		local intactConnectionNodes = numConnectionNodes - numDamagedConnectionNodes
		
		local powerSources = samSite:getPowerSources()
		local numDamagedPowerSources = 0
		for j = 1, #powerSources do
			local powerSource = powerSources[j]
			if powerSource:isExist() == false then
				numDamagedPowerSources = numDamagedPowerSources + 1
			end
		end
		local intactPowerSources = numPowerSources - numDamagedPowerSources 
		
		local detectedTargets = samSite:getDetectedTargets()
		
		local samSitesInCoveredArea = samSite:getChildRadars()
		
		local engageAirWeapons = samSite:getCanEngageAirWeapons()
		
		local engageHARMS = samSite:getCanEngageHARM()
		
		local hasAmmo = samSite:hasRemainingAmmo()
		local isJammed = samSite:isJammed()
		
		self:printOutputToLog("GROUP: "..samSite:getDCSName().." | TYPE: "..samSite:getNatoName())
		self:printOutputToLog("ACTIVE: "..tostring(isActive).." | JAMMED: "..tostring(isJammed).." | AUTONOMOUS: "..tostring(isAutonomous).." | IS ACTING AS EW: "..tostring(samSite:getActAsEW()).." | CAN ENGAGE AIR WEAPONS : "..tostring(engageAirWeapons).." | CAN ENGAGE HARMS : "..tostring(engageHARMS).." | HAS AMMO: "..tostring(hasAmmo).." | DETECTED TARGETS: "..#detectedTargets.." | DEFENDING HARM: "..tostring(samSite:isDefendingHARM()).." | MISSILES IN FLIGHT: "..tostring(samSite:getNumberOfMissilesInFlight()))
		
		if numConnectionNodes > 0 then
			self:printOutputToLog("CONNECTION NODES: "..numConnectionNodes.." | DAMAGED: "..numDamagedConnectionNodes.." | INTACT: "..intactConnectionNodes)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if numPowerSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..numPowerSources.." | DAMAGED:"..numDamagedPowerSources.." | INTACT: "..intactPowerSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		
		self:printOutputToLog("SAM SITES IN COVERED AREA: "..#samSitesInCoveredArea)
		for j = 1, #samSitesInCoveredArea do
			local samSiteCovered = samSitesInCoveredArea[j]
			self:printOutputToLog(samSiteCovered:getDCSName())
		end
		
		for j = 1, #detectedTargets do
			local contact = detectedTargets[j]
			if firstRadar ~= nil and firstRadar:isExist() then
				local distance = mist.utils.round(mist.utils.metersToNM(samSite:getDistanceInMetersToContact(firstRadar:getDCSRepresentation(), contact:getPosition().p)), 2)
				self:printOutputToLog("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | DISTANCE NM: "..distance)
			end
		end
		
		self:printOutputToLog("---------------------------------------------------")
	end
end

function SkynetIADSLogger:printCommandCenterStatus()
	local commandCenters = self.iads:getCommandCenters()
	self:printOutputToLog("------------------------------------------ COMMAND CENTER STATUS: "..self.iads:getCoalitionString().." -------------------------------")
	
	for i = 1, #commandCenters do
		local commandCenter = commandCenters[i]
		local numConnectionNodes = #commandCenter:getConnectionNodes()
		local powerSourceInfo = self:getMetaInfo(commandCenter:getPowerSources())
		local connectionNodeInfo = self:getMetaInfo(commandCenter:getConnectionNodes())
		self:printOutputToLog("GROUP: "..commandCenter:getDCSName().." | TYPE: "..commandCenter:getNatoName())
		if connectionNodeInfo.numSources > 0 then
			self:printOutputToLog("CONNECTION NODES: "..connectionNodeInfo.numSources.." | DAMAGED: "..connectionNodeInfo.numDamagedSources.." | INTACT: "..connectionNodeInfo.numIntactSources)
		else
			self:printOutputToLog("NO CONNECTION NODES SET")
		end
		if powerSourceInfo.numSources > 0 then
			self:printOutputToLog("POWER SOURCES : "..powerSourceInfo.numSources.." | DAMAGED: "..powerSourceInfo.numDamagedSources.." | INTACT: "..powerSourceInfo.numIntactSources)
		else
			self:printOutputToLog("NO POWER SOURCES SET")
		end
		self:printOutputToLog("---------------------------------------------------")
	end
end

function SkynetIADSLogger:printSystemStatus()	

	if self:getDebugSettings().IADSStatus or self:getDebugSettings().contacts then
		local coalitionStr = self.iads:getCoalitionString()
		self:printOutput("---- IADS: "..coalitionStr.." ------")
	end
	
	if self:getDebugSettings().IADSStatus then

		local commandCenters = self.iads:getCommandCenters()
		local numComCenters = #commandCenters
		local numDestroyedComCenters = 0
		local numComCentersNoPower = 0
		local numComCentersNoConnectionNode = 0
		local numIntactComCenters = 0
		for i = 1, #commandCenters do
			local commandCenter = commandCenters[i]
			if commandCenter:hasWorkingPowerSource() == false then
				numComCentersNoPower = numComCentersNoPower + 1
			end
			if commandCenter:hasActiveConnectionNode() == false then
				numComCentersNoConnectionNode = numComCentersNoConnectionNode + 1
			end
			if commandCenter:isDestroyed() == false then
				numIntactComCenters = numIntactComCenters + 1
			end
		end
		
		numDestroyedComCenters = numComCenters - numIntactComCenters
		
		
		self:printOutput("COMMAND CENTERS: "..numComCenters.." | Destroyed: "..numDestroyedComCenters.." | NoPowr: "..numComCentersNoPower.." | NoCon: "..numComCentersNoConnectionNode)
	
		local ewNoPower = 0
		local earlyWarningRadars = self.iads:getEarlyWarningRadars()
		local ewTotal = #earlyWarningRadars
		local ewNoConnectionNode = 0
		local ewActive = 0
		local ewRadarsInactive = 0
		local mobileEWTotal = 0
		local mobileEWCombat = 0
		local mobileEWPatrol = 0
		local mobileEWHarm = 0

		for i = 1, #earlyWarningRadars do
			local ewRadar = earlyWarningRadars[i]
			if ewRadar:hasWorkingPowerSource() == false then
				ewNoPower = ewNoPower + 1
			end
			if ewRadar:hasActiveConnectionNode() == false then
				ewNoConnectionNode = ewNoConnectionNode + 1
			end
			if ewRadar:isActive() then
				ewActive = ewActive + 1
			end
			if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
				local entry = SkynetIADSMobilePatrol.getEntryForElement(ewRadar)
				if entry and entry.kind == "MEW" then
					mobileEWTotal = mobileEWTotal + 1
					if entry.state == "patrolling" then
						mobileEWPatrol = mobileEWPatrol + 1
					elseif entry.state == "harm_evading" then
						mobileEWHarm = mobileEWHarm + 1
					else
						mobileEWCombat = mobileEWCombat + 1
					end
				end
			end
		end
		
		ewRadarsInactive = ewTotal - ewActive	
		local numEWRadarsDestroyed = #self.iads:getDestroyedEarlyWarningRadars()
		self:printOutput("EW: "..ewTotal.." | On: "..ewActive.." | Off: "..ewRadarsInactive.." | Destroyed: "..numEWRadarsDestroyed.." | NoPowr: "..ewNoPower.." | NoCon: "..ewNoConnectionNode)
		if mobileEWTotal > 0 then
			self:printOutput("MEW: "..mobileEWTotal.." | Combat: "..mobileEWCombat.." | Patrol: "..mobileEWPatrol.." | HARM: "..mobileEWHarm)
		end
		
		local samSitesInactive = 0
		local samSitesActive = 0
		local samSites = self.iads:getSAMSites()
		local samSitesTotal = #samSites
		local samSitesNoPower = 0
		local samSitesNoConnectionNode = 0
		local samSitesOutOfAmmo = 0
		local samSiteAutonomous = 0
		local samSiteRadarDestroyed = 0
		local samSitesJammed = 0
		local mobileSAMTotal = 0
		local mobileSAMCombat = 0
		local mobileSAMPatrol = 0
		local mobileSAMHarm = 0
		for i = 1, #samSites do
			local samSite = samSites[i]
			if samSite:hasWorkingPowerSource() == false then
				samSitesNoPower = samSitesNoPower + 1
			end
			if samSite:hasActiveConnectionNode() == false then
				samSitesNoConnectionNode = samSitesNoConnectionNode + 1
			end
			if samSite:isActive() then
				samSitesActive = samSitesActive + 1
			end
			if samSite:hasRemainingAmmo() == false then
				samSitesOutOfAmmo = samSitesOutOfAmmo + 1
			end
			if samSite:getAutonomousState() == true then
				samSiteAutonomous = samSiteAutonomous + 1
			end
			if samSite:isJammed() then
				samSitesJammed = samSitesJammed + 1
			end
			if samSite:hasWorkingRadar() == false then
				samSiteRadarDestroyed = samSiteRadarDestroyed + 1
			end
			if SkynetIADSMobilePatrol and SkynetIADSMobilePatrol.getEntryForElement then
				local entry = SkynetIADSMobilePatrol.getEntryForElement(samSite)
				if entry and entry.kind == "MSAM" then
					mobileSAMTotal = mobileSAMTotal + 1
					if entry.state == "patrolling" then
						mobileSAMPatrol = mobileSAMPatrol + 1
					elseif entry.state == "harm_evading" then
						mobileSAMHarm = mobileSAMHarm + 1
					else
						mobileSAMCombat = mobileSAMCombat + 1
					end
				end
			end
		end
		
		samSitesInactive = samSitesTotal - samSitesActive
		self:printOutput("SAM: "..samSitesTotal.." | On: "..samSitesActive.." | Off: "..samSitesInactive.." | Jammed: "..samSitesJammed.." | Autonm: "..samSiteAutonomous.." | Raddest: "..samSiteRadarDestroyed.." | NoPowr: "..samSitesNoPower.." | NoCon: "..samSitesNoConnectionNode.." | NoAmmo: "..samSitesOutOfAmmo)
		if mobileSAMTotal > 0 then
			self:printOutput("MSAM: "..mobileSAMTotal.." | Combat: "..mobileSAMCombat.." | Patrol: "..mobileSAMPatrol.." | HARM: "..mobileSAMHarm)
		end
	end
	
	if self:getDebugSettings().contacts then
		local contacts = self.iads:getContacts()
		if contacts then
			for i = 1, #contacts do
				local contact = contacts[i]
					self:printOutput("CONTACT: "..contact:getName().." | TYPE: "..contact:getTypeName().." | GS: "..tostring(contact:getGroundSpeedInKnots()).." | LAST SEEN: "..contact:getAge())
			end
		end
	end
	
	if self:getDebugSettings().commandCenterStatusEnvOutput then
		self:printCommandCenterStatus()
	end

	if self:getDebugSettings().earlyWarningRadarStatusEnvOutput then
		self:printEarlyWarningRadarStatus()
	end
	
	if self:getDebugSettings().samSiteStatusEnvOutput then
		self:printSAMSiteStatus()
	end

end

end
