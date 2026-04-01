do

SkynetIADSHARMDetection = {}
SkynetIADSHARMDetection.__index = SkynetIADSHARMDetection

SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS = 400

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

function SkynetIADSHARMDetection:evaluateContacts()
	self:cleanAgedContacts()
	for i = 1, #self.contacts do
		local contact = self.contacts[i]
		local directTargetElement = self:getDirectTargetElement(contact)
		local hasDirectTarget = directTargetElement ~= nil
		if hasDirectTarget then
			contact._skynetDirectTargetGroupName = directTargetElement:getDCSName()
			contact:setHARMState(SkynetIADSContact.HARM)
		else
			contact._skynetDirectTargetGroupName = nil
		end
		local groundSpeed  = contact:getGroundSpeedInKnots(0)
		--if a contact has only been hit by a radar once it's speed is 0
		--如果接触只被雷达击中一次，其速度为0
		if groundSpeed == 0 then
			-- Ignore this incomplete contact and continue evaluating the rest.
		end
		local simpleAltitudeProfile = contact:getSimpleAltitudeProfile()
		local newRadarsToEvaluate = self:getNewRadarsThatHaveDetectedContact(contact)
		--self.iads:printOutputToLog(contact:getName().." new Radars to evaluate: "..#newRadarsToEvaluate)
		--self.iads:printOutputToLog(contact:getName().." ground speed: "..groundSpeed)
		--self.iads:printOutputToLog(contact:getName().." 要评估的新雷达："..#newRadarsToEvaluate)
		--self.iads:printOutputToLog(contact:getName().." 地面速度："..groundSpeed)
		if ( hasDirectTarget == false and #newRadarsToEvaluate > 0 and contact:isIdentifiedAsHARM() == false and ( groundSpeed > SkynetIADSHARMDetection.HARM_THRESHOLD_SPEED_KTS and #simpleAltitudeProfile <= 2 ) ) then
			local detectionProbability = self:getDetectionProbability(newRadarsToEvaluate)
			--self.iads:printOutputToLog("DETECTION PROB: "..detectionProbability)
			--self.iads:printOutputToLog("检测概率："..detectionProbability)
			if ( self:shallReactToHARM(detectionProbability) ) then
				contact:setHARMState(SkynetIADSContact.HARM)
				if (self.iads:getDebugSettings().harmDefence ) then
					self.iads:printOutputToLog("HARM IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
				end
			else
				contact:setHARMState(SkynetIADSContact.NOT_HARM)
				if (self.iads:getDebugSettings().harmDefence ) then
					self.iads:printOutputToLog("HARM NOT IDENTIFIED: "..contact:getTypeName().." | DETECTION PROBABILITY WAS: "..detectionProbability.."%")
				end
			end
		end
		
		if ( hasDirectTarget == false and #simpleAltitudeProfile > 2 and contact:isIdentifiedAsHARM() ) then
			contact:setHARMState(SkynetIADSContact.HARM_UNKNOWN)
			if (self.iads:getDebugSettings().harmDefence ) then
				self.iads:printOutputToLog("CORRECTING HARM STATE: CONTACT IS NOT A HARM: "..contact:getName())
			end
		end
		
		if ( contact:isIdentifiedAsHARM() ) then
			self:informRadarsOfHARM(contact)
		end
	end
end

function SkynetIADSHARMDetection:cleanAgedContacts()
	local activeContactRadars = {}
	for contact, radars in pairs (self.contactRadarsEvaluated) do
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
	return chance >=  math.random(1, 100)
end

function SkynetIADSHARMDetection:getDetectionProbability(radars)
	local detectionChance = 0
	local missChance = 100
	local detection = 0
	for i = 1, #radars do
		detection = radars[i]:getHARMDetectionChance()
		if ( detectionChance == 0 ) then
			detectionChance = detection
		else
			detectionChance = detectionChance + (detection * (missChance / 100))
		end	
		missChance = 100 - detection
	end
	return detectionChance
end

end
