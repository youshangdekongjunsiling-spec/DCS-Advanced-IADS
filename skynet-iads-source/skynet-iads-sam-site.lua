do

SkynetIADSSamSite = {}
SkynetIADSSamSite = inheritsFrom(SkynetIADSAbstractRadarElement)

local NATIVE_TARGET_IN_RANGE_LATCH_SECONDS = 8

local function getContactIdentity(contact)
	local contactName = nil
	local contactType = nil
	if contact ~= nil then
		pcall(function()
			contactName = contact:getName()
		end)
		pcall(function()
			contactType = contact:getTypeName()
		end)
	end
	return contactName, contactType
end

local function clearTargetsInRangeLatch(sam)
	sam.targetsInRangeLatchedUntil = 0
	sam.targetsInRangeLatchedContactName = nil
	sam.targetsInRangeLatchedContactType = nil
end

local function latchTargetsInRange(sam, contact, durationSeconds)
	local now = timer.getTime()
	local contactName, contactType = getContactIdentity(contact)
	sam.targetsInRangeLatchedUntil = now + (durationSeconds or NATIVE_TARGET_IN_RANGE_LATCH_SECONDS)
	sam.targetsInRangeLatchedContactName = contactName
	sam.targetsInRangeLatchedContactType = contactType
end

local function hasLatchedTargetsInRange(sam)
	local latchedUntil = sam.targetsInRangeLatchedUntil
	if latchedUntil == nil or latchedUntil <= 0 then
		return false
	end
	return timer.getTime() <= latchedUntil
end

function SkynetIADSSamSite:create(samGroup, iads)
	local sam = self:superClass():create(samGroup, iads)
	setmetatable(sam, self)
	self.__index = self
	sam.targetsInRange = false
	sam.targetsInRangeLatchedUntil = 0
	sam.targetsInRangeLatchedContactName = nil
	sam.targetsInRangeLatchedContactType = nil
	sam.targetsInRangeLatchSeconds = NATIVE_TARGET_IN_RANGE_LATCH_SECONDS
	sam.goLiveConstraints = {}
	return sam
end

function SkynetIADSSamSite:addGoLiveConstraint(constraintName, constraint)
	self.goLiveConstraints[constraintName] = constraint
end

function SkynetIADSAbstractRadarElement:areGoLiveConstraintsSatisfied(contact)
	for constraintName, constraint in pairs(self.goLiveConstraints) do
		if ( constraint(contact) ~= true ) then
			return false
		end
	end
	return true
end

function SkynetIADSAbstractRadarElement:removeGoLiveConstraint(constraintName)
	local constraints = {}
	for cName, constraint in pairs(self.goLiveConstraints) do
		if cName ~= constraintName then
			constraints[cName] = constraint
		end
	end
	self.goLiveConstraints = constraints
end

function SkynetIADSAbstractRadarElement:getGoLiveConstraints()
	return self.goLiveConstraints
end

function SkynetIADSSamSite:isDestroyed()
	local isDestroyed = true
	for i = 1, #self.launchers do
		local launcher = self.launchers[i]
		if launcher:isExist() == true then
			isDestroyed = false
		end
	end
	local radars = self:getRadars()
	for i = 1, #radars do
		local radar = radars[i]
		if radar:isExist() == true then
			isDestroyed = false
		end
	end
	return isDestroyed
end

function SkynetIADSSamSite:targetCycleUpdateStart()
	if hasLatchedTargetsInRange(self) ~= true then
		clearTargetsInRangeLatch(self)
	end
	self.targetsInRange = false
end

function SkynetIADSSamSite:targetCycleUpdateEnd()
	if self.iads and self.iads.isMasterSwitchEnabled and self.iads:isMasterSwitchEnabled() ~= true then
		clearTargetsInRangeLatch(self)
		self:applyMasterSwitchStandby()
		return
	end
	local effectiveTargetsInRange = self.targetsInRange == true or hasLatchedTargetsInRange(self) == true
	if effectiveTargetsInRange == false and self.actAsEW == false and self:getAutonomousState() == false and self:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI then
		self:goDark()
	end
end

function SkynetIADSSamSite:informOfContact(contact)
	if self.iads and self.iads.isMasterSwitchEnabled and self.iads:isMasterSwitchEnabled() ~= true then
		self.targetsInRange = false
		clearTargetsInRangeLatch(self)
		self:applyMasterSwitchStandby()
		return
	end
	-- We only perform the expensive in-range check until one valid target has been confirmed for this cycle.
	if ( self.targetsInRange == false
		and self:areGoLiveConstraintsSatisfied(contact) == true
		and self:isTargetInRange(contact)
		and ( contact:isIdentifiedAsHARM() == false or ( contact:isIdentifiedAsHARM() == true and self:getCanEngageHARM() == true ) ) ) then
		self:goLive()
		self.targetsInRange = true
		latchTargetsInRange(self, contact, self.targetsInRangeLatchSeconds)
	end
end

end
