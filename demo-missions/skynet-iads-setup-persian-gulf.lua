do
-- ============================================================================
-- Skynet IADS 波斯湾演示任务设置脚本
-- 此脚本演示如何设置一个完整的 IADS 系统，包括：
-- 1. 创建 IADS 实例
-- 2. 配置调试选项
-- 3. 添加雷达和 SAM 站点
-- 4. 设置指挥中心和电源
-- 5. 配置 HARM 防御
-- 6. 激活系统
-- ============================================================================

-- ============================================================================
-- 第一步：创建 IADS 实例
-- 创建一个名为 'IRAN' 的 IADS 系统实例
-- ============================================================================
redIADS = SkynetIADS:create('IRAN')

-- ============================================================================
-- 第二步：配置调试选项
-- 这些设置控制 IADS 系统在 DCS 日志中的输出信息
-- 如果不需要调试信息，可以将这些设置为 false 或删除此部分
-- ============================================================================
local iadsDebug = redIADS:getDebugSettings()

-- 基本状态信息
iadsDebug.IADSStatus = true                    -- 显示 IADS 系统状态
iadsDebug.contacts = true                      -- 显示检测到的目标信息
iadsDebug.radarWentLive = true                 -- 显示雷达上线信息
iadsDebug.radarWentDark = true                 -- 显示雷达关闭信息

-- 连接和电源状态
iadsDebug.noWorkingCommmandCenter = false      -- 显示指挥中心不可用警告
iadsDebug.ewRadarNoConnection = false          -- 显示 EW 雷达连接问题
iadsDebug.samNoConnection = false              -- 显示 SAM 站点连接问题
iadsDebug.hasNoPower = false                   -- 显示电源问题

-- 高级功能
iadsDebug.jammerProbability = true             -- 显示干扰器概率信息
iadsDebug.harmDefence = true                   -- 显示 HARM 防御信息
iadsDebug.addedEWRadar = false                 -- 显示添加的 EW 雷达信息

-- 详细状态输出
iadsDebug.samSiteStatusEnvOutput = true        -- 输出 SAM 站点详细状态
iadsDebug.earlyWarningRadarStatusEnvOutput = true  -- 输出 EW 雷达详细状态
iadsDebug.commandCenterStatusEnvOutput = true  -- 输出指挥中心详细状态

--add all units with unit name beginning with 'EW' to the IADS:
--将所有以'EW'开头的单位名称添加到IADS：
redIADS:addEarlyWarningRadarsByPrefix('EW')

--add all groups begining with group name 'SAM' to the IADS:
--将所有以组名'SAM'开头的组添加到IADS：
redIADS:addSAMSitesByPrefix('SAM')

--add a command center:
--添加指挥中心：
commandCenter = StaticObject.getByName('Command-Center')
redIADS:addCommandCenter(commandCenter)

---we add a K-50 AWACs, manually. This could just as well be automated by adding an 'EW' prefix to the unit name:
---我们手动添加K-50 AWACs。这也可以通过给单位名称添加'EW'前缀来自动化：
redIADS:addEarlyWarningRadar('AWACS-K-50')

--add a power source and a connection node for this EW radar:
--为此EW雷达添加电源和连接节点：
local powerSource = StaticObject.getByName('Power-Source-EW-Center3')
local connectionNodeEW = StaticObject.getByName('Connection-Node-EW-Center3')
redIADS:getEarlyWarningRadarByUnitName('EW-Center3'):addPowerSource(powerSource):addConnectionNode(connectionNodeEW)

--add a connection node to this SA-2 site, and set the option for it to go dark, if it looses connection to the IADS:
--为此SA-2站点添加连接节点，并设置选项使其在失去与IADS连接时关闭：
local connectionNode = Unit.getByName('Mobile-Command-Post-SAM-SA-2')
redIADS:getSAMSiteByGroupName('SAM-SA-2'):addConnectionNode(connectionNode):setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)

--this SA-2 site will go live at 70% of its max search range:
--此SA-2站点将在其最大搜索范围的70%时上线：
redIADS:getSAMSiteByGroupName('SAM-SA-2'):setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE):setGoLiveRangeInPercent(70)

--all SA-10 sites shall act as EW sites, meaning their radars will be on all the time:
--所有SA-10站点应作为EW站点，意味着它们的雷达将一直开启：
redIADS:getSAMSitesByNatoName('SA-10'):setActAsEW(true)

--set the sa15 as point defence for the SA-10 site, we set it to always react to a HARM so we can demonstrate the point defence mechanism in Skynet
--将sa15设置为SA-10站点的点防御，我们设置它总是对HARM做出反应，这样我们可以演示Skynet中的点防御机制
local sa15 = redIADS:getSAMSiteByGroupName('SAM-SA-15-point-defence-SA-10')
redIADS:getSAMSiteByGroupName('SAM-SA-10'):addPointDefence(sa15):setHARMDetectionChance(100)


--set this SA-11 site to go live 70% of max range of its missiles (default value: 100%), its HARM detection probability is set to 50% (default value: 70%)
--设置此SA-11站点在其导弹最大射程的70%时上线（默认值：100%），其HARM检测概率设置为50%（默认值：70%）
redIADS:getSAMSiteByGroupName('SAM-SA-11'):setGoLiveRangeInPercent(70):setHARMDetectionChance(50)

--this SA-6 site will always react to a HARM being fired at it:
--此SA-6站点将总是对向其发射的HARM做出反应：
redIADS:getSAMSiteByGroupName('SAM-SA-6'):setHARMDetectionChance(100)

--set this SA-11 site to go live at maximunm search range (default is at maximung firing range):
--设置此SA-11站点在最大搜索范围时上线（默认在最大射击范围）：
redIADS:getSAMSiteByGroupName('SAM-SA-11-2'):setEngagementZone(SkynetIADSAbstractRadarElement.GO_LIVE_WHEN_IN_SEARCH_RANGE)

--activate the radio menu to toggle IADS Status output
--激活无线电菜单以切换IADS状态输出
redIADS:addRadioMenu()

-- activate the IADS
-- 激活IADS
redIADS:activate()	

--add the jammer
--添加干扰器
local jammer = SkynetIADSJammer:create(Unit.getByName('jammer-emitter'), redIADS)
jammer:masterArmOn()
jammer:addRadioMenu()

---some special code to remove the jammer aircraft if player is not flying with it in formation, has nothing to do with the IADS:
---一些特殊代码，如果玩家没有与干扰器飞机编队飞行，则移除干扰器飞机，与IADS无关：
local hornet = Unit.getByName('Hornet SA-11-2 Attack')
if hornet == nil then
	Unit.getByName('jammer-emitter'):destroy()
	jammer:removeRadioMenu()
end
--end special code
--结束特殊代码

------setup blue IADS:
------设置蓝色IADS：
blueIADS = SkynetIADS:create('UAE')
blueIADS:addSAMSitesByPrefix('BLUE-SAM')
blueIADS:addEarlyWarningRadarsByPrefix('BLUE-EW')
blueIADS:activate()
blueIADS:addRadioMenu()

local iadsDebug = blueIADS:getDebugSettings()
iadsDebug.IADSStatus = true
iadsDebug.contacts = true

end