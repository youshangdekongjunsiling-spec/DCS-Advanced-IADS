do

SkynetIADSHARMDetection = {}
SkynetIADSHARMDetection.__index = SkynetIADSHARMDetection

SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS = 400
SkynetIADSHARMDetection.DIRECT_TARGET_BACKSTOP_DELAY_SECONDS = 10

function SkynetIADSHARMDetection:create(iads)
	local harmDetection = {}
	setmetatable(harmDetection, self)
	harmDetection.contacts = {}
	harmDetection.iads = iads
	harmDetection.contactRadarsEvaluated = {}
	return harmDetection
end

function SkynetIADSHARMDetection:setContacts(contacts)
	self.contacts = contacts
end

function SkynetIADSHARMDetection:getContactCategory(contact)
	local representation = nil
	local okRepresentation = pcall(function()
		representation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okRepresentation ~= true or representation == nil or representation.getCategory == nil then
		return nil
	end
	local okCategory, categoryId = pcall(function()
		return representation:getCategory()
	end)
	if okCategory ~= true then
		return nil
	end
	return categoryId
end

function SkynetIADSHARMDetection:isLikelySEADThreatContact(contact, groundSpeed, categoryId)
	if contact == nil then
		return false
	end
	if groundSpeed == nil or groundSpeed <= SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS then
		return false
	end

	local resolvedCategoryId = categoryId
	if resolvedCategoryId == nil then
		resolvedCategoryId = self:getContactCategory(contact)
	end
	if resolvedCategoryId ~= Object.Category.WEAPON then
		return false
	end

	local typeName = ""
	local okType, resolvedTypeName = pcall(function()
		return contact.getTypeName and contact:getTypeName() or ""
	end)
	if okType == true and resolvedTypeName ~= nil then
		typeName = string.upper(resolvedTypeName)
	end

	local threatPatterns = {
		"HARM",
		"AARGM",
		"ALARM",
		"KH%-31P",
		"KH31P",
		"KH%-58",
		"KH58",
		"JSOW",
		"JDAM",
		"GBU%-31",
		"GBU%-32",
		"GBU%-38",
		"GBU%-54",
	}
	for i = 1, #threatPatterns do
		if string.find(typeName, threatPatterns[i]) then
			return true
		end
	end

	-- Generic high-speed weapon fallback.
	return true
end

function SkynetIADSHARMDetection:getDirectTargetElement(contact)
	local representation = nil
	local okRepresentation = pcall(function()
		representation = contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
	end)
	if okRepresentation ~= true or representation == nil or representation.getTarget == nil then
		return nil
	end

	local target = nil
	local okTarget = pcall(function()
		target = representation:getTarget()
	end)
	if okTarget ~= true or target == nil then
		return nil
	end

	local group = nil
	local okGroup = pcall(function()
		group = target.getGroup and target:getGroup() or nil
	end)
	if okGroup == true and group and group.getName then
		local okGroupName, groupName = pcall(function()
			return group:getName()
		end)
		if okGroupName and groupName then
			local samSite = self.iads:getSAMSiteByGroupName(groupName)
			if samSite then
				return samSite
			end
		end
	end

	local targetName = nil
	local okTargetName = pcall(function()
		targetName = target.getName and target:getName() or nil
	end)
	if okTargetName == true and targetName then
		local ewRadar = self.iads:getEarlyWarningRadarByUnitName(targetName)
		if ewRadar then
			return ewRadar
		end
	end

	return nil
end

function SkynetIADSHARMDetection:getContactAgeSeconds(contact)
	if contact == nil or contact.getAge == nil then
		return 0
	end
	local okAge, age = pcall(function()
		return contact:getAge()
	end)
	if okAge ~= true or type(age) ~= "number" then
		return 0
	end
	return age
end

function SkynetIADSHARMDetection:traceWeaponContact(contact, details)
	if self.iads == nil or self.iads.traceWeaponContact == nil or contact == nil then
		return false
	end
	local payload = details or {}
	payload.originModule = payload.originModule or "skynet-iads-harm-detection"
	payload.originFunction = payload.originFunction or "evaluateContacts"
	payload.source = payload.source or "harm_detection"
	return self.iads:traceWeaponContact(contact, payload)
end

function SkynetIADSHARMDetection:evaluateContacts()
	self:cleanAgedContacts()
	for i = 1, #self.contacts do
		local contact = self.contacts[i]
		if contact ~= nil then
			local categoryId = self:getContactCategory(contact)
			local isWeaponContact = categoryId == Object.Category.WEAPON
			if isWeaponContact ~= true then
				contact._skynetDirectTargetGroupName = nil
				contact._skynetPendingDirectTargetGroupName = nil
				contact._skynetPendingDirectTargetMatchCount = 0
				contact._skynetFrozenDirectTargetGroupName = nil
				if contact:isIdentifiedAsHARM() == true then
					contact:setHARMState(SkynetIADSContact.NOT_HARM)
					if self.iads:getDebugSettings().harmDefence then
						self.iads:printOutputToLog("HARM FILTERED (NON-WEAPON): "..contact:getTypeName())
					end
				end
			else
				local groundSpeed = contact:getGroundSpeedInKnots(0)
				local contactAgeSeconds = self:getContactAgeSeconds(contact)
				local directTargetElement = self:getDirectTargetElement(contact)
				local currentDirectTargetGroupName = directTargetElement and directTargetElement.getDCSName and directTargetElement:getDCSName() or nil
				if currentDirectTargetGroupName ~= nil and currentDirectTargetGroupName ~= "" then
					if contact._skynetPendingDirectTargetGroupName == currentDirectTargetGroupName then
						contact._skynetPendingDirectTargetMatchCount = (contact._skynetPendingDirectTargetMatchCount or 1) + 1
					else
						contact._skynetPendingDirectTargetGroupName = currentDirectTargetGroupName
						contact._skynetPendingDirectTargetMatchCount = 1
					end
					if contact._skynetPendingDirectTargetMatchCount >= 2 then
						contact._skynetFrozenDirectTargetGroupName = currentDirectTargetGroupName
					end
				elseif contact._skynetFrozenDirectTargetGroupName == nil then
					contact._skynetPendingDirectTargetGroupName = nil
					contact._skynetPendingDirectTargetMatchCount = 0
				end
				local frozenDirectTargetGroupName = contact._skynetFrozenDirectTargetGroupName
				local hasDirectTarget = frozenDirectTargetGroupName ~= nil and frozenDirectTargetGroupName ~= ""
				local directTargetBackstopActive =
					hasDirectTarget
					and contactAgeSeconds >= SkynetIADSHARMDetection.DIRECT_TARGET_BACKSTOP_DELAY_SECONDS
				local directTargetPending = hasDirectTarget and directTargetBackstopActive ~= true

				if directTargetBackstopActive then
					contact._skynetDirectTargetGroupName = frozenDirectTargetGroupName
					contact:setHARMState(SkynetIADSContact.HARM)
				else
					contact._skynetDirectTargetGroupName = nil
				end

				local likelyWeaponThreat = false
				if directTargetPending ~= true then
					likelyWeaponThreat = self:isLikelySEADThreatContact(contact, groundSpeed, categoryId)
				end
				local simpleAltitudePointCount = 0
				local newRadarCount = 0
				local detectionProbability = nil
				if directTargetBackstopActive == false and likelyWeaponThreat == true and contact:isIdentifiedAsHARM() ~= true then
					contact:setHARMState(SkynetIADSContact.HARM)
					if self.iads:getDebugSettings().harmDefence then
						self.iads:printOutputToLog("HARM PRIOR IDENTIFIED: "..contact:getTypeName().." | SPEED: "..groundSpeed.."kts")
					end
				end

				-- If a contact has only been hit by a radar once its speed is often 0, so skip probabilistic checks this cycle.
				if groundSpeed > 0 then
					local simpleAltitudeProfile = contact:getSimpleAltitudeProfile()
					simpleAltitudePointCount = #simpleAltitudeProfile
					local newRadarsToEvaluate = self:getNewRadarsThatHaveDetectedContact(contact)
					newRadarCount = #newRadarsToEvaluate
					if directTargetBackstopActive == false
						and likelyWeaponThreat == false
						and #newRadarsToEvaluate > 0
						and contact:isIdentifiedAsHARM() == false
						and groundSpeed > SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS
						and #simpleAltitudeProfile <= 2 then
						detectionProbability = self:getDetectionProbability(newRadarsToEvaluate)
						if self:shallReactToHARM(detectionProbability) then
							contact:setHARMState(SkynetIADSContact.HARM)
							if self.iads:getDebugSettings().harmDefence then
								self.iads:printOutputToLog("HARM IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
							end
						else
							contact:setHARMState(SkynetIADSContact.NOT_HARM)
							if self.iads:getDebugSettings().harmDefence then
								self.iads:printOutputToLog("HARM NOT IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
							end
						end
					end

					if directTargetBackstopActive == false
						and likelyWeaponThreat == false
						and #simpleAltitudeProfile > 2
						and contact:isIdentifiedAsHARM() then
						contact:setHARMState(SkynetIADSContact.HARM_UNKNOWN)
						if self.iads:getDebugSettings().harmDefence then
							self.iads:printOutputToLog("CORRECTING HARM STATE: CONTACT IS NOT A HARM: "..contact:getName())
						end
					end
				else
					simpleAltitudePointCount = 0
					newRadarCount = 0
				end

				self:traceWeaponContact(contact, {
					command = "weapon_contact",
					scope = "weapon_track",
					outcome = contact:isIdentifiedAsHARM() == true and "harm" or "observed",
					groundSpeedKts = groundSpeed,
					ageSeconds = contactAgeSeconds,
					directTargetGroup = contact._skynetFrozenDirectTargetGroupName or contact._skynetDirectTargetGroupName or nil,
					pendingDirectTargetGroup = contact._skynetPendingDirectTargetGroupName or nil,
					backstopActive = directTargetBackstopActive == true and "Y" or "N",
					directTargetPending = directTargetPending == true and "Y" or "N",
					simpleAltitudePoints = simpleAltitudePointCount,
					newRadarCount = newRadarCount,
					detectionProbability = detectionProbability,
					note = likelyWeaponThreat == true and "likelyWeaponThreat=Y" or nil,
				})

				if contact:isIdentifiedAsHARM() then
					self:informRadarsOfHARM(contact)
				end
			end
		end
	end
end

function SkynetIADSHARMDetection:cleanAgedContacts()
	local activeContactRadars = {}
	for contact, radars in pairs(self.contactRadarsEvaluated) do
		if contact:getAge() < 32 then
			activeContactRadars[contact] = radars
		end
	end
	self.contactRadarsEvaluated = activeContactRadars
end

function SkynetIADSHARMDetection:getNewRadarsThatHaveDetectedContact(contact)
	local radarsFromContact = contact:getAbstractRadarElementsDetected()
	local evaluatedRadars = self.contactRadarsEvaluated[contact]
	local newRadars = {}
	if evaluatedRadars == nil then
		evaluatedRadars = {}
		self.contactRadarsEvaluated[contact] = evaluatedRadars
	end
	for i = 1, #radarsFromContact do
		local contactRadar = radarsFromContact[i]
		if self:isElementInTable(evaluatedRadars, contactRadar) == false then
			table.insert(evaluatedRadars, contactRadar)
			table.insert(newRadars, contactRadar)
		end
	end
	return newRadars
end

function SkynetIADSHARMDetection:isElementInTable(tbl, element)
	for i = 1, #tbl do
		local tblElement = tbl[i]
		if tblElement == element then
			return true
		end
	end
	return false
end

function SkynetIADSHARMDetection:informRadarsOfHARM(contact)
	if self:getContactCategory(contact) ~= Object.Category.WEAPON then
		return
	end
	local samSites = self.iads:getUsableSAMSites()
	self:updateRadarsOfSites(samSites, contact)

	local ewRadars = self.iads:getUsableEarlyWarningRadars()
	self:updateRadarsOfSites(ewRadars, contact)
end

function SkynetIADSHARMDetection:updateRadarsOfSites(sites, contact)
	for i = 1, #sites do
		local site = sites[i]
		site:informOfHARM(contact)
	end
end

function SkynetIADSHARMDetection:shallReactToHARM(chance)
	return chance >= math.random(1, 100)
end

function SkynetIADSHARMDetection:getDetectionProbability(radars)
	local detectionChance = 0
	local missChance = 100
	local detection = 0
	for i = 1, #radars do
		detection = radars[i]:getHARMDetectionChance()
		if detectionChance == 0 then
			detectionChance = detection
		else
			detectionChance = detectionChance + (detection * (missChance / 100))
		end
		missChance = 100 - detection
	end
	return detectionChance
end

end
