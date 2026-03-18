do


--Setup Syknet IADS:
--设置Skynet IADS：
redIADS = SkynetIADS:create('Enemy IADS')


local iadsDebug = redIADS:getDebugSettings()  
iadsDebug.IADSStatus = true
iadsDebug.contacts = true

--[[
iadsDebug.radarWentDark = true
iadsDebug.radarWentLive = true
iadsDebug.ewRadarNoConnection = true
iadsDebug.samNoConnection = true
iadsDebug.jammerProbability = true
iadsDebug.addedEWRadar = true
iadsDebug.hasNoPower = true
iadsDebug.addedSAMSite = true
iadsDebug.warnings = true
iadsDebug.harmDefence = true
iadsDebug.samSiteStatusEnvOutput = true
iadsDebug.earlyWarningRadarStatusEnvOutput = true
--]]

redIADS:addSAMSitesByPrefix('SAM')

local power = StaticObject.getByName('power-source')
redIADS:addEarlyWarningRadarsByPrefix('EW')
redIADS:getEarlyWarningRadarByUnitName('EW-1'):addConnectionNode(power)

redIADS:activate()


-- Define a SET_GROUP object that builds a collection of groups that define the EWR network.
-- 定义一个SET_GROUP对象，构建定义EWR网络的组集合。
DetectionSetGroup = SET_GROUP:New()

-- add the MOOSE SET_GROUP to the Skynet IADS, from now on Skynet will update active radars that the MOOSE SET_GROUP can use for EW detection.
-- 将MOOSE SET_GROUP添加到Skynet IADS，从现在开始Skynet将更新MOOSE SET_GROUP可用于EW检测的活跃雷达。
redIADS:addMooseSetGroup(DetectionSetGroup)

-- Setup the detection and group targets to a 30km range!
-- 设置检测和组目标到30公里范围！
Detection = DETECTION_AREAS:New( DetectionSetGroup, 30000 )

-- Setup the A2A dispatcher, and initialize it.
-- 设置A2A调度器并初始化它。
A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )

-- Set 100km as the radius to engage any target by airborne friendlies.
-- 设置100公里作为空中友军攻击任何目标的半径。
A2ADispatcher:SetEngageRadius() -- 100000 is the default value.

-- Set 200km as the radius to ground control intercept.
-- 设置200公里作为地面控制拦截的半径。
A2ADispatcher:SetGciRadius() -- 200000 is the default value.

CCCPBorderZone = ZONE_POLYGON:New( "RED-BORDER", GROUP:FindByName( "RED-BORDER" ) )
A2ADispatcher:SetBorderZone( CCCPBorderZone )

A2ADispatcher:SetSquadron( "Kutaisi", AIRBASE.Caucasus.Kutaisi, { "Squadron red SU-27" }, 2 )
A2ADispatcher:SetSquadronGrouping( "Kutaisi", 2 )
A2ADispatcher:SetSquadronGci( "Kutaisi", 900, 1200 )
A2ADispatcher:SetTacticalDisplay(true)
A2ADispatcher:Start()

--test to see which groups are added and removed to the SET_GROUP at runtime by Skynet:
--测试查看Skynet在运行时向SET_GROUP添加和移除哪些组：
function outputNames()
	env.info("IADS Radar Groups added by Skynet:")
	env.info(DetectionSetGroup:GetObjectNames())
end

mist.scheduleFunction(outputNames, self, 1, 2)
--end test
--结束测试
end
