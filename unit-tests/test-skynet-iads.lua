do
-- ============================================================================
-- Skynet IADS 单元测试套件
-- 此文件包含对 IADS 系统各个组件的单元测试
-- 使用 LuaUnit 测试框架进行测试
-- ============================================================================

-- 定义测试类
TestSkynetIADS = {}

-- ============================================================================
-- 测试设置函数
-- 在每个测试用例运行前调用，用于初始化测试环境
-- 功能: 创建测试用的 IADS 实例并添加测试用的雷达和 SAM 站点
-- ============================================================================
function TestSkynetIADS:setUp()
	-- 设置测试常量
	self.numSAMSites = SKYNET_UNIT_TESTS_NUM_SAM_SITES_RED 
	self.numEWSites = SKYNET_UNIT_TESTS_NUM_EW_SITES_RED
	
	-- 创建测试用的 IADS 实例
	self.testIADS = SkynetIADS:create()
	
	-- 添加测试用的雷达和 SAM 站点
	self.testIADS:addEarlyWarningRadarsByPrefix('EW')
	self.testIADS:addSAMSitesByPrefix('SAM')
end

-- ============================================================================
-- 测试清理函数
-- 在每个测试用例运行后调用，用于清理测试环境
-- 功能: 停用并清理测试用的 IADS 实例
-- ============================================================================
function TestSkynetIADS:tearDown()
	if	self.testIADS then
		-- 停用 IADS 系统
		self.testIADS:deactivate()
	end
	-- 清理引用
	self.testIADS = nil
end

-- this function checks constants in DCS that the IADS relies on. A change to them might indicate that functionallity is broken.
-- In the code constants are refereed to with their constant name calue, not the values the represent.
-- 此函数检查IADS依赖的DCS常量。对它们的更改可能表明功能已损坏。
-- 在代码中，常量以其常量名称值引用，而不是它们表示的值。
function TestSkynetIADS:testDCSContstantsHaveNotChanged()
	lu.assertEquals(Weapon.Category.MISSILE, 1)
	lu.assertEquals(Weapon.Category.SHELL, 0)
	lu.assertEquals(world.event.S_EVENT_SHOT, 1)
	lu.assertEquals(world.event.S_EVENT_DEAD, 8)
	lu.assertEquals(Unit.Category.AIRPLANE, 0)
end

function TestSkynetIADS:testCaclulateNumberOfSamSitesAndEWRadars()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	lu.assertEquals(#self.testIADS:getSAMSites(), 0)
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), 0)
	self.testIADS:addEarlyWarningRadarsByPrefix('EW')
	self.testIADS:addSAMSitesByPrefix('SAM')
	lu.assertEquals(#self.testIADS:getSAMSites(), self.numSAMSites)
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), self.numEWSites)
end

function TestSkynetIADS:testCaclulateNumberOfSamSitesAndEWRadarsWhenAddMethodsCalledTwice()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	lu.assertEquals(#self.testIADS:getSAMSites(), 0)
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), 0)
	self.testIADS:addEarlyWarningRadarsByPrefix('EW')
	self.testIADS:addEarlyWarningRadarsByPrefix('EW')
	self.testIADS:addSAMSitesByPrefix('SAM')
	self.testIADS:addSAMSitesByPrefix('SAM')
	lu.assertEquals(#self.testIADS:getSAMSites(), self.numSAMSites)
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), self.numEWSites)
end

function TestSkynetIADS:testWrongCaseStringWillNotLoadSAMGroup()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	self.testIADS:addSAMSitesByPrefix('sam')
	lu.assertEquals(#self.testIADS:getSAMSites(), 0)
end	

function TestSkynetIADS:testWrongCaseStringWillNotLoadEWRadars()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	self.testIADS:addEarlyWarningRadarsByPrefix('ew')
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), 0)
end	

function TestSkynetIADS:testEvaluateContacts1EWAnd1SAMSiteWithContactInRange()
	self:tearDown()
	local iads = SkynetIADS:create()
	local ewRadar = iads:addEarlyWarningRadar('EW-west23')
	
	function ewRadar:getDetectedTargets()
		return {IADSContactFactory('test-in-firing-range-of-sa-2')}
	end
	
	local samSite = iads:addSAMSite('SAM-SA-2')
	
	
	function samSite:getDetectedTargets()
		return {}
	end
	
	samSite:goDark()
	lu.assertEquals(samSite:isInRadarDetectionRangeOf(ewRadar), true)
	iads:activate()
	iads:evaluateContacts()
	lu.assertEquals(#iads:getContacts(), 1)
	lu.assertEquals(samSite:isActive(), true)
	
	-- we remove the target to test if the sam site will now go dark, was added for the performance optimised code
	-- 我们移除目标以测试SAM站点现在是否会关闭，这是为性能优化代码添加的
	function ewRadar:getDetectedTargets()
		return {}
	end
	iads:evaluateContacts()
	lu.assertEquals(samSite:isActive(), false)
	iads:deactivate()
end

function TestSkynetIADS:testEarlyWarningRadarHasWorkingPowerSourceByDefault()
	local ewRadar = self.testIADS:getEarlyWarningRadarByUnitName('EW-west')
	lu.assertEquals(ewRadar:hasWorkingPowerSource(), true)
end

function TestSkynetIADS:testAWACSHasMovedAndThereforeRebuildAutonomousStatesOfSAMSites()

	local iads = SkynetIADS:create()
	local awacs = iads:addEarlyWarningRadar('EW-AWACS-A-50')

	local updateCalls = 0
	function iads:buildRadarCoverageForEarlyWarningRadar(ewRadar)
		SkynetIADS.buildRadarCoverageForEarlyWarningRadar(self, ewRadar)
		updateCalls = updateCalls + 1
	end
	
	lu.assertEquals(awacs:getDistanceTraveledSinceLastUpdate(), 0)
	lu.assertEquals(getmetatable(awacs), SkynetIADSAWACSRadar)
	lu.assertEquals(awacs:getMaxAllowedMovementForAutonomousUpdateInNM(), 10)
	lu.assertEquals(awacs:isUpdateOfAutonomousStateOfSAMSitesRequired(), false)
	
	iads:evaluateContacts()
	lu.assertEquals(updateCalls, 0)
	
	--test distance calculation by giving the awacs a different position:
	--通过给AWACS一个不同的位置来测试距离计算：
	local firstPos = Unit.getByName('EW-AWACS-KJ-2000'):getPosition().p
	awacs.lastUpdatePosition = firstPos
	
	lu.assertEquals(awacs:getDistanceTraveledSinceLastUpdate(), 763)
	lu.assertEquals(awacs:isUpdateOfAutonomousStateOfSAMSitesRequired(), true)
	
	-- a second imediate call shall result in false
	-- 第二次立即调用应导致false
	lu.assertEquals(awacs:getDistanceTraveledSinceLastUpdate(), 0)
	lu.assertEquals(awacs:isUpdateOfAutonomousStateOfSAMSitesRequired(), false)
	
	--we reset lastUpdatePosition to firstPos to test call in the IADS code
	-- TODO: when refactoring move this test to te AWACS Radar and use mock objects for integration tests in the IADS
	--我们重置lastUpdatePosition为firstPos以测试IADS代码中的调用
	-- TODO: 重构时将此测试移动到AWACS雷达，并在IADS的集成测试中使用模拟对象
	awacs.lastUpdatePosition = firstPos
	iads:evaluateContacts()
	lu.assertEquals(updateCalls, 1)
	iads:deactivate()
end

function TestSkynetIADS:testSAMSiteLoosesPower()
	local powerSource = StaticObject.getByName('SA-6 Power')
	local samSite = self.testIADS:getSAMSiteByGroupName('SAM-SA-6'):addPowerSource(powerSource)
	lu.assertEquals(#self.testIADS:getUsableSAMSites(), self.numSAMSites)
	samSite:goLive()
	lu.assertEquals(samSite:isActive(), true)
	trigger.action.explosion(powerSource:getPosition().p, 100)
	--we simulate a call to the event, since in game will be triggered to late to for later checks in this unit test
	--我们模拟对事件的调用，因为在游戏中触发得太晚，无法在此单元测试中进行后续检查
	samSite:onEvent(createDeadEvent())
	lu.assertEquals(#self.testIADS:getUsableSAMSites(), self.numSAMSites-1)
	lu.assertEquals(samSite:isActive(), false)
end

function TestSkynetIADS:testSAMSiteSA6LostConnectionNodeAutonomusStateDCSAI()
	local sa6ConnectionNode = StaticObject.getByName('SA-6 Connection Node')
	self.testIADS:getSAMSiteByGroupName('SAM-SA-6'):addConnectionNode(sa6ConnectionNode)
	
	lu.assertEquals(#self.testIADS:getSAMSites(), self.numSAMSites)
	lu.assertEquals(#self.testIADS:getUsableSAMSites(), self.numSAMSites)
	
	trigger.action.explosion(sa6ConnectionNode:getPosition().p, 100)
	lu.assertEquals(#self.testIADS:getUsableSAMSites(), self.numSAMSites-1)

	lu.assertEquals(#self.testIADS:getUsableSAMSites(), self.numSAMSites-1)
	lu.assertEquals(#self.testIADS:getSAMSites(), self.numSAMSites)
	
	local samSite = self.testIADS:getSAMSiteByGroupName('SAM-SA-6')
	lu.assertEquals(samSite:isActive(), true)

	lu.assertEquals(samSite:getAutonomousState(), true)
	lu.assertEquals(samSite:isActive(), true)
end

function TestSkynetIADS:testAddRadarsToCommandCenter()
	local comCenter = StaticObject.getByName('command-center-3')
	self.testIADS:addCommandCenter(comCenter)
	local comC = self.testIADS:getCommandCenters()[1]
	local called = false
	function comC:clearChildRadars()
		called = true
	end
	--as long as IADS is not active addCommandCenter will not trigger addRadarsToCommandCenters when called:
	--只要IADS不活跃，addCommandCenter在调用时不会触发addRadarsToCommandCenters：
	self.testIADS:addRadarsToCommandCenters()
	lu.assertEquals(called, true)
	lu.assertEquals(#comC:getChildRadars(), (self.numEWSites + self.numSAMSites))
end

function TestSkynetIADS:testAddCommandCenter()
	local called = false
	function self.testIADS:addRadarsToCommandCenters()
		called = true
	end
	
	local comCenter = StaticObject.getByName('command-center-3')
	self.testIADS:addCommandCenter(comCenter)
	lu.assertEquals(called, false)
	
	self.testIADS:activate()
	self.testIADS:addCommandCenter(comCenter)
	lu.assertEquals(called, true)
	self.testIADS:deactivate()
end

function TestSkynetIADS:testOneCommandCenterHasNoConnectionNode()
	local commandCenter2 = StaticObject.getByName("Command Center2")
	local commandCenter2ConnectionNode = StaticObject.getByName("command-center-2-connection-node")
	local comCenter = self.testIADS:addCommandCenter(commandCenter2):addConnectionNode(commandCenter2ConnectionNode)
	lu.assertEquals(#comCenter:getConnectionNodes(), 1)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), true)
	
	local samSites = self.testIADS:getSAMSites()
	lu.assertEquals(#samSites, SKYNET_UNIT_TESTS_NUM_SAM_SITES_RED)
	
	local ewRadars = self.testIADS:getEarlyWarningRadars()
	lu.assertEquals(#ewRadars, SKYNET_UNIT_TESTS_NUM_EW_SITES_RED)
	
	self.testIADS:activate()

	trigger.action.explosion(commandCenter2ConnectionNode:getPosition().p, 500)
	--we simulate a call to the event, since in game will be triggered to late to for later checks in this unit test
	--我们模拟对事件的调用，因为在游戏中触发得太晚，无法在此单元测试中进行后续检查
	comCenter:onEvent(createDeadEvent())
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), false)

	
	--after the command center is no longer reachable we check to see if all SAM and EW radars are in their expected autonomous state:
	for i = 1, #samSites do
		local sam = samSites[i]
		lu.assertEquals(sam:getAutonomousState(), true)
	end
	
	
	for i = 1, #ewRadars do
		local ewRad = ewRadars[i]
		lu.assertEquals(ewRad:getAutonomousState(), true)
	end
	
end

function TestSkynetIADS:testOneCommandCenterLoosesPower()
	local commandCenter2Power = StaticObject.getByName("Command Center2 Power")
	local commandCenter2 = StaticObject.getByName("Command Center2")
	lu.assertEquals(#self.testIADS:getCommandCenters(), 0)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), true)
	local comCenter = self.testIADS:addCommandCenter(commandCenter2):addPowerSource(commandCenter2Power)
	lu.assertEquals(#comCenter:getPowerSources(), 1)
	lu.assertEquals(#self.testIADS:getCommandCenters(), 1)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), true)
	trigger.action.explosion(commandCenter2Power:getPosition().p, 10000)
	lu.assertEquals(#self.testIADS:getCommandCenters(), 1)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), false)
end


function TestSkynetIADS:testOneCommandCenterIsDestroyed()
	local commandCenter1 = StaticObject.getByName("Command Center")	
	lu.assertEquals(#self.testIADS:getCommandCenters(), 0)
	self.testIADS:addCommandCenter(commandCenter1)
	lu.assertEquals(#self.testIADS:getCommandCenters(), 1)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), true)
	trigger.action.explosion(commandCenter1:getPosition().p, 10000)
	lu.assertEquals(#self.testIADS:getCommandCenters(), 1)
	lu.assertEquals(self.testIADS:isCommandCenterUsable(), false)
end

function TestSkynetIADS:testSetOptionsForSAMSiteType()
	local powerSource = StaticObject.getByName('SA-11-power-source')
	local connectionNode = StaticObject.getByName('SA-11-connection-node')
	lu.assertEquals(#self.testIADS:getSAMSitesByNatoName('SA-6'), 2)
	--lu.assertIs(getmetatable(self.testIADS:getSAMSitesByNatoName('SA-6')), SkynetIADSTableForwarder)
	local samSites = self.testIADS:getSAMSitesByNatoName('SA-6'):setActAsEW(true):addPowerSource(powerSource):addConnectionNode(connectionNode):setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(90):setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
	lu.assertEquals(#samSites, 2)
	for i = 1, #samSites do
		local samSite = samSites[i]
		lu.assertEquals(samSite:getActAsEW(), true)
		lu.assertEquals(samSite:getEngagementZone(), SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)
		lu.assertEquals(samSite:getGoLiveRangeInPercent(), 90)
		lu.assertEquals(samSite:getAutonomousBehaviour(), SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
		lu.assertIs(samSite:getConnectionNodes()[1], connectionNode)
		lu.assertIs(samSite:getPowerSources()[1], powerSource)
	end
end

function TestSkynetIADS:testSetOptionsForAllAddedSamSitesByPrefix()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local samSites = self.testIADS:addSAMSitesByPrefix('SAM'):setActAsEW(true):addPowerSource(powerSource):addConnectionNode(connectionNode):setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(90):setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
	lu.assertEquals(#samSites, self.numSAMSites)
	for i = 1, #samSites do
		local samSite = samSites[i]
		lu.assertEquals(samSite:getActAsEW(), true)
		lu.assertEquals(samSite:getEngagementZone(), SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)
		lu.assertEquals(samSite:getGoLiveRangeInPercent(), 90)
		lu.assertEquals(samSite:getAutonomousBehaviour(), SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
		lu.assertIs(samSite:getConnectionNodes()[1], connectionNode)
		lu.assertIs(samSite:getPowerSources()[1], powerSource)
	end
end

function TestSkynetIADS:testSetOptionsForAllAddedSAMSites()
	local samSites = self.testIADS:getSAMSites():setActAsEW(true):addPowerSource(powerSource):addConnectionNode(connectionNode):setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(90):setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
	lu.assertEquals(#samSites, self.numSAMSites)
	for i = 1, #samSites do
		local samSite = samSites[i]
		lu.assertEquals(samSite:getActAsEW(), true)
		lu.assertEquals(samSite:getEngagementZone(), SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)
		lu.assertEquals(samSite:getGoLiveRangeInPercent(), 90)
		lu.assertEquals(samSite:getAutonomousBehaviour(), SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
		lu.assertIs(samSite:getConnectionNodes()[1], connectionNode)
		lu.assertIs(samSite:getPowerSources()[1], powerSource)
	end
end

function TestSkynetIADS:testSetOptionsForAllAddedEWSitesByPrefix()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local ewSites = self.testIADS:addEarlyWarningRadarsByPrefix('EW'):addPowerSource(powerSource):addConnectionNode(connectionNode)
	lu.assertEquals(#ewSites, self.numEWSites)
	for i = 1, #ewSites do
		local ewSite = ewSites[i]
		lu.assertIs(ewSite:getConnectionNodes()[1], connectionNode)
		lu.assertIs(ewSite:getPowerSources()[1], powerSource)
	end
	
end

function TestSkynetIADS:testSetOptionsForAllAddedEWSites()
	local ewSites = self.testIADS:getEarlyWarningRadars()
	lu.assertEquals(#ewSites, self.numEWSites)
	for i = 1, #ewSites do
		local ewSite = ewSites[i]
		lu.assertIs(ewSite:getConnectionNodes()[1], connectionNode)
		lu.assertIs(ewSite:getPowerSources()[1], powerSource)
	end
end

function TestSkynetIADS:testMergeContacts()
	lu.assertEquals(#self.testIADS:getContacts(), 0)
	self.testIADS:mergeContact(IADSContactFactory('Harrier Pilot'))
	lu.assertEquals(#self.testIADS:getContacts(), 1)
	
	local contact = IADSContactFactory('Harrier Pilot')
	local mockRadar = {}
	function contact:getAbstractRadarElementsDetected()
		return {mockRadar}
	end
	self.testIADS:mergeContact(contact)
	lu.assertEquals(#self.testIADS:getContacts(), 1)
	local iadsContact = self.testIADS:getContacts()[1]
	lu.assertEquals(#iadsContact:getAbstractRadarElementsDetected(), 1)
	
	self.testIADS:mergeContact(IADSContactFactory('test-in-firing-range-of-sa-2'))
	lu.assertEquals(#self.testIADS:getContacts(), 2)
	
end

function TestSkynetIADS:testCleanAgedTargets()
	local iads = SkynetIADS:create()
	
	target1 = IADSContactFactory('test-in-firing-range-of-sa-2')
	function target1:getAge()
		return iads.maxTargetAge + 1
	end
	
	target2 = IADSContactFactory('test-distance-calculation')
	function target2:getAge()
		return 1
	end
	
	iads.contacts[1] = target1
	iads.contacts[2] = target2
	lu.assertEquals(#iads:getContacts(), 2)
	iads:cleanAgedTargets()
	lu.assertEquals(#iads:getContacts(), 1)
	iads:deactivate()
end

function TestSkynetIADS:testOnlyLoadGroupsWithPrefixForSAMSiteNotOtherUnitsOrStaticObjectsWithSamePrefix()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local calledPrint = false
	function self.testIADS:printOutput(str, isWarning)
		calledPrint = true
	end
	self.testIADS:addSAMSitesByPrefix('prefixtest')
	lu.assertEquals(#self.testIADS:getSAMSites(), 1)
	lu.assertEquals(calledPrint, false)
end

function TestSkynetIADS:testOnlyLoadGroupsWithPrefixForSAMSiteNotOtherUnitsOrStaticObjectsWithSamePrefix2()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local calledPrint = false
	function self.testIADS:printOutput(str, isWarning)
		calledPrint = true
	end
	--happened when the string.find method was not set to plain special characters messed up the regex pattern
	self.testIADS:addSAMSitesByPrefix('IADS-EW')
	lu.assertEquals(#self.testIADS:getSAMSites(), 1)
	lu.assertEquals(calledPrint, false)
end

function TestSkynetIADS:testOnlyLoadUnitsWithPrefixForEWSiteNotStaticObjectssWithSamePrefix()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local calledPrint = false
	function self.testIADS:printOutput(str, isWarning)
		calledPrint = true
	end
	self.testIADS:addEarlyWarningRadarsByPrefix('prefixewtest')
	lu.assertEquals(#self.testIADS:getEarlyWarningRadars(), 1)
	lu.assertEquals(calledPrint, false)
end

--TODO rework this test for new evaluateContacts code:
--[[
function TestSkynetIADS:testDontPassShipsGroundUnitsAndStructuresToSAMSites()
	
	-- make sure we don't get any targets in the test mission
	local ewRadars = self.testIADS:getEarlyWarningRadars()
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		function ewRadar:getDetectedTargets()
			return {}
		end
	end
	
	
	local samSites = self.testIADS:getSAMSites()
	for i = 1, #samSites do
		local samSite = samSites[i]
		function samSite:getDetectedTargets()
			return {}
		end
	end
	

	self.testIADS:evaluateContacts()
	-- verifies we have a clean test setup
	lu.assertEquals(#self.testIADS.contacts, 0)
	

	
	-- ground units should not be passed to the SAM	
	local mockContactGroundUnit = {}
	function mockContactGroundUnit:getDesc()
		return {category = Unit.Category.GROUND_UNIT}
	end
	function mockContactGroundUnit:getAge()
		return 0
	end
	
	
	table.insert(self.testIADS.contacts, mockContactGroundUnit)
	
	local correlatedCalled = false
	function self.testIADS:informOfContact(contact)
		correlatedCalled = true
	end
	
	self.testIADS:evaluateContacts()
	lu.assertEquals(correlatedCalled, false)
	lu.assertEquals(#self.testIADS.contacts, 1)
	
	
	
	self.testIADS.contacts = {}
	
	-- ships should not be passed to the SAM	
	local mockContactShip = {}
	function mockContactShip:getDesc()
		return {category = Unit.Category.SHIP}
	end
	function mockContactShip:getAge()
		return 0
	end
	
	table.insert(self.testIADS.contacts, mockContactShip)
	
	correlatedCalled = false
	function self.testIADS:informOfContact(contact)
		correlatedCalled = true
	end
	self.testIADS:evaluateContacts()
	lu.assertEquals(correlatedCalled, false)
	lu.assertEquals(#self.testIADS.contacts, 1)
	
	self.testIADS.contacts = {}
	
	-- aircraft should be passed to the SAM	
	local mockContactAirplane = {}
	function mockContactAirplane:getDesc()
		return {category = Unit.Category.AIRPLANE}
	end
	function mockContactAirplane:getAge()
		return 0
	end
	
	table.insert(self.testIADS.contacts, mockContactAirplane)
	
	correlatedCalled = false
	function self.testIADS:informOfContact(contact)
		correlatedCalled = true
	end
	self.testIADS:evaluateContacts()
	--TODO: FIX TEST
	lu.assertEquals(correlatedCalled, true)
	lu.assertEquals(#self.testIADS.contacts, 1)
	self.testIADS.contacts = {}

end
--]]

function TestSkynetIADS:testAddMooseSetGroup()

	local mockMooseSetGroup = {}
	local mockMooseConnector = {}
	local setGroupCalled = false
	
	function mockMooseConnector:addMooseSetGroup(group)
		setGroupCalled = true
		lu.assertEquals(mockMooseSetGroup, group)
	end
	
	function self.testIADS:getMooseConnector()
		return mockMooseConnector
	end
	
	self.testIADS:addMooseSetGroup(mockMooseSetGroup)
	lu.assertEquals(setGroupCalled, true)
end

--TODO: add more comparisons in this test, this test also tests buildRadarCoverageForAbstractRadarElement
function TestSkynetIADS:testBuildRadarCoverage()	
	
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	local ewWest2 = self.testIADS:addEarlyWarningRadar('EW-west2')
	local samSA6 = self.testIADS:addSAMSite('SAM-SA-6')
	local samSA62 = self.testIADS:addSAMSite('SAM-SA-6-2')
	local samSA2 = self.testIADS:addSAMSite('SAM-SA-2')
	self.testIADS:buildRadarCoverage()

	local ewWestChildren = ewWest2:getChildRadars()
	lu.assertEquals(#ewWestChildren, 3)
	
	local containsSa6 = false
	local containsSA62 = false
	local containsSA2  = false
	for i =  1, #ewWestChildren do
		local radar = ewWestChildren[i]
		if radar == samSA6 then
			containsSa6 = true
		end
		if radar == samSA2 then
			containsSA2 = true
		end
		if radar == samSA62 then
			containsSA62 = true
		end
	end
	lu.assertEquals(containsSA2, true)
	lu.assertEquals(containsSA62, true)
	lu.assertEquals(containsSa6, true)
	
	--further tests to verify the exact content of the parent radars could be done with these:
	lu.assertEquals(#samSA6:getParentRadars(), 2)
	lu.assertEquals(#samSA6:getChildRadars(), 1)
	
	lu.assertEquals(#samSA62:getParentRadars(), 2)
	lu.assertEquals(#samSA62:getChildRadars(), 1)
	
	lu.assertEquals(#samSA2:getParentRadars(), 1)
end

--this test adds an EW Radar to an existing IADS, SAM site under coverage must then be adopted by the new EW radar
function TestSkynetIADS:testBuildRadarCoverageForSingleEarlyWarningRadar()	
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	
	
	self.testIADS:addCommandCenter(StaticObject.getByName("Command Center"))
	
	local ewRadar = self.testIADS:getEarlyWarningRadarByUnitName('EW-west2')
	local sam2 = self.testIADS:addSAMSite('SAM-SA-6')
	local sam1 = self.testIADS:addSAMSite('SAM-SA-6-2')
	
	self.testIADS:buildRadarCoverage()

	
	lu.assertEquals(#sam1:getParentRadars(), 1)
	lu.assertEquals(#sam2:getParentRadars(), 1)
	
	lu.assertEquals(#self.testIADS:getCommandCenters()[1]:getChildRadars(), 2)
	
	local ewWest2 = self.testIADS:addEarlyWarningRadar('EW-west2')
		
	self.testIADS:buildRadarCoverageForEarlyWarningRadar(ewWest2)
	
	lu.assertEquals(#sam1:getParentRadars(), 2)
	lu.assertEquals(#sam2:getParentRadars(), 2)
	lu.assertEquals(#ewWest2:getChildRadars(), 2)
	lu.assertEquals(ewWest2:getAutonomousState(), false)

	lu.assertEquals(#self.testIADS:getCommandCenters()[1]:getChildRadars(), 3)
end

--this tet adds a SAM site to a IADS network, SAM site under coverage must then be adopted by the new SAM site also EW radars must be added as parents
function TestSkynetIADS:testBuildRadarCoverageForSingleSAMSite()
	self:tearDown()
	self.testIADS = SkynetIADS:create()
	
	local sam1 = self.testIADS:addSAMSite('SAM-SA-6-2')
	local ewWest2 = self.testIADS:addEarlyWarningRadar('EW-west2')
	self.testIADS:buildRadarCoverage()
	
	lu.assertEquals(#sam1:getParentRadars(), 1)
	lu.assertEquals(#ewWest2:getChildRadars(), 1)
	
	local sam2 = self.testIADS:addSAMSite('SAM-SA-6')
	lu.assertEquals(sam2:getAutonomousState(), true)
	
	self.testIADS:buildRadarCoverageForSAMSite(sam2)
	lu.assertEquals(sam2:getAutonomousState(), false)
	lu.assertEquals(#sam2:getParentRadars(), 2)
	lu.assertEquals(#sam1:getParentRadars(), 2)
	lu.assertEquals(#ewWest2:getChildRadars(), 2)
end

	
function TestSkynetIADS:testGetSAMSitesByPrefix()
	local samSites = self.testIADS:getSAMSitesByPrefix('SAM-SA-15')
	lu.assertEquals(#samSites, 3)
end

function TestSkynetIADS:testSetMaxAgeOfCachedTargets()
	local iads = SkynetIADS:create()
	
	-- test default value
	lu.assertEquals(iads.contactUpdateInterval, 5)
	
	iads:setUpdateInterval(10)
	lu.assertEquals(iads.contactUpdateInterval, 10)
	
	lu.assertEquals(iads:getCachedTargetsMaxAge(), 10)
	
	local ewRadar = iads:addEarlyWarningRadar('EW-west')
	local samSite = iads:addSAMSite('SAM-SA-15-1')
	
	lu.assertEquals(ewRadar.cachedTargetsMaxAge, 10)
	lu.assertEquals(samSite.cachedTargetsMaxAge, 10)
	iads:deactivate()
	
end

function TestSkynetIADS:testAddSingleEWRadarAndSAMSiteWhenIADSIsActiveWillTriggerCorrectRadarCoverageUpdates()
	local iads = SkynetIADS:create()
	local calledSAMUpdate = 0
	local calledEWUpdate = 0
	

	function iads:buildRadarCoverageForSAMSite(samSite)
		calledSAMUpdate = calledSAMUpdate + 1
	end
	
	function iads:buildRadarCoverageForEarlyWarningRadar(ewRadar)
		calledEWUpdate = calledEWUpdate + 1
	end
	
	local ewRadar = iads:addEarlyWarningRadar('EW-west')
	lu.assertEquals(calledEWUpdate, 0)
	
	local samSite = iads:addSAMSite('SAM-SA-6-2')
	lu.assertEquals(calledSAMUpdate, 0)
	
	--simulate an active IADS:
	iads.ewRadarScanMistTaskID = 1
	
	local ewRadar = iads:addEarlyWarningRadar('EW-west')
	lu.assertEquals(calledEWUpdate, 1)
	
	local samSite = iads:addSAMSite('SAM-SA-6-2')
	lu.assertEquals(calledSAMUpdate, 1)
	iads:deactivate()
	
end

function TestSkynetIADS:testBuildIADSWithAutonomousSAMS()
	local iads = SkynetIADS:create()
	local samSite = iads:addSAMSite('SAM-SA-10')
	iads:activate()
	lu.assertEquals(samSite:isActive(), true) 
	iads:deactivate()
end

end
