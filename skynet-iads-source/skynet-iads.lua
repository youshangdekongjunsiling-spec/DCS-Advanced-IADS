do
-- ============================================================================
-- Skynet IADS 主控制器类
-- 这是整个综合防空系统（IADS）的核心控制器，负责协调所有雷达、SAM站点和指挥中心
-- ============================================================================

-- 定义 SkynetIADS 类
SkynetIADS = {}
SkynetIADS.__index = SkynetIADS

-- 设置 SAM 类型数据库引用，用于识别不同类型的防空武器系统
SkynetIADS.database = samTypesDB

-- ============================================================================
-- 创建 IADS 实例的构造函数
-- 参数: name - IADS 系统的名称（如 "RED IADS", "BLUE IADS"）
-- 返回: 新创建的 IADS 实例
-- ============================================================================
function SkynetIADS:create(name)
	-- 创建新的 IADS 实例表
	local iads = {}
	-- 设置元表，实现面向对象继承
	setmetatable(iads, SkynetIADS)
	
	-- 初始化 IADS 实例的所有属性
	iads.radioMenu = nil                    -- 无线电菜单（用于调试和状态显示）
	iads.detailedStateMenu = nil
	iads.detailedStatePageMenus = {}
	iads.detailedStatePageSize = 8
	iads.earlyWarningRadars = {}           -- 早期预警雷达数组
	iads.samSites = {}                     -- SAM（地空导弹）站点数组
	iads.commandCenters = {}               -- 指挥中心数组
	iads.ewRadarScanMistTaskID = nil       -- MIST 任务ID（用于定期扫描）
	iads.coalition = nil                   -- 联盟ID（红方/蓝方/中立）
	iads.contacts = {}                     -- 检测到的目标接触数组
	iads.maxTargetAge = 32                 -- 目标最大存活时间（秒）
	iads.name = name                       -- IADS 系统名称
	iads.harmDetection = SkynetIADSHARMDetection:create(iads)  -- HARM检测模块
	iads.logger = SkynetIADSLogger:create(iads)               -- 日志记录模块
	iads.orderTrace = nil
	if SkynetIADSOrderTrace and SkynetIADSOrderTrace.create then
		iads.orderTrace = SkynetIADSOrderTrace:create(iads)
	end
	iads.gpsSpoofer = nil
	iads.contactUpdateInterval = 5         -- 目标更新间隔（秒）
	
	-- 确保名称不为空
	if iads.name == nil then
		iads.name = ""
	end
	
	-- 向 DCS 世界注册事件处理器，用于响应游戏事件
	world.addEventHandler(iads)
	
	return iads
end

-- ============================================================================
-- DCS 世界事件处理器
-- 当 DCS 世界中发生事件时，此函数会被调用
-- 参数: event - DCS 事件对象
-- ============================================================================
function SkynetIADS:onEvent(event)
	if self.gpsSpoofer and self.gpsSpoofer.onEvent then
		self.gpsSpoofer:onEvent(event)
	end
	-- 检查是否为新单位生成事件
	if (event.id == world.event.S_EVENT_BIRTH ) then
		-- 记录新单位生成信息到 DCS 日志
		env.info("New Object Spawned")
		-- 注释掉的代码：自动添加新生成的 SAM 站点
		-- 这可以用于动态添加新单位到 IADS 系统
	--	self:addSAMSite(event.initiator:getGroup():getName());
	end
end

-- ============================================================================
-- 设置目标更新间隔
-- 参数: interval - 更新间隔时间（秒）
-- 功能: 控制 IADS 系统多久扫描一次目标
-- ============================================================================
function SkynetIADS:setUpdateInterval(interval)
	self.contactUpdateInterval = interval
end

-- ============================================================================
-- 设置和验证联盟归属
-- 参数: item - 要检查联盟的单位或组
-- 功能: 确保 IADS 中的所有元素都属于同一联盟（红方/蓝方/中立）
-- ============================================================================
function SkynetIADS:setCoalition(item)
	if item then
		-- 获取单位的联盟ID
		local coalitionID = item:getCoalition()
		
		-- 如果 IADS 还没有设置联盟，则设置为第一个单位的联盟
		if self.coalitionID == nil then
			self.coalitionID = coalitionID
		end
		
		-- 检查联盟是否一致，如果不一致则记录警告
		if self.coalitionID ~= coalitionID then
			self:printOutputToLog("element: "..item:getName().." has a different coalition than the IADS", true)
		end
	end
end

-- ============================================================================
-- 添加干扰器到 IADS 系统
-- 参数: jammer - 干扰器对象
-- 功能: 将电子干扰器添加到 IADS 系统中
-- ============================================================================
function SkynetIADS:addJammer(jammer)
	table.insert(self.jammers, jammer)
end

-- ============================================================================
-- 获取 IADS 系统的联盟归属
-- 返回: 联盟ID（红方/蓝方/中立）
-- ============================================================================
function SkynetIADS:getCoalition()
	return self.coalitionID
end

-- ============================================================================
-- 获取被摧毁的早期预警雷达列表
-- 返回: 被摧毁的 EW 雷达数组
-- 功能: 用于统计和清理被摧毁的雷达站点
-- ============================================================================
function SkynetIADS:getDestroyedEarlyWarningRadars()
	local destroyedSites = {}
	-- 遍历所有早期预警雷达
	for i = 1, #self.earlyWarningRadars do
		local ewSite = self.earlyWarningRadars[i]
		-- 检查雷达是否被摧毁
		if ewSite:isDestroyed() then
			table.insert(destroyedSites, ewSite)
		end
	end
	return destroyedSites
end

-- ============================================================================
-- 从雷达元素表中筛选可用的雷达元素
-- 参数: abstractRadarTable - 要筛选的雷达元素表
-- 返回: 可用的雷达元素数组
-- 功能: 筛选出有电源、有连接且未被摧毁的雷达元素
-- ============================================================================
function SkynetIADS:getUsableAbstractRadarElemtentsOfTable(abstractRadarTable)
	local usable = {}
	-- 遍历所有雷达元素
	for i = 1, #abstractRadarTable do
		local abstractRadarElement = abstractRadarTable[i]
		-- 检查三个条件：有活跃连接节点、有工作电源、未被摧毁
		if abstractRadarElement:hasActiveConnectionNode() and 
		   abstractRadarElement:hasWorkingPowerSource() and 
		   abstractRadarElement:isDestroyed() == false then
			table.insert(usable, abstractRadarElement)
		end
	end
	return usable
end

-- ============================================================================
-- 获取可用的早期预警雷达列表
-- 返回: 可用的 EW 雷达数组
-- 功能: 返回所有有电源、有连接且未被摧毁的 EW 雷达
-- ============================================================================
function SkynetIADS:getUsableEarlyWarningRadars()
	return self:getUsableAbstractRadarElemtentsOfTable(self.earlyWarningRadars)
end

function SkynetIADS:createTableDelegator(units) 
	local sites = SkynetIADSTableDelegator:create()
	for i = 1, #units do
		local site = units[i]
		table.insert(sites, site)
	end
	return sites
end

function SkynetIADS:addEarlyWarningRadarsByPrefix(prefix)
	self:deactivateEarlyWarningRadars()
	self.earlyWarningRadars = {}
	for unitName, unit in pairs(mist.DBs.unitsByName) do
		local pos = self:findSubString(unitName, prefix)
		--somehow the MIST unit db contains StaticObject, we check to see we only add Units
	--MIST单位数据库包含StaticObject，我们检查确保只添加Units
		local unit = Unit.getByName(unitName)
		if pos and pos == 1 and unit then
			self:addEarlyWarningRadar(unitName)
		end
	end
	return self:createTableDelegator(self.earlyWarningRadars)
end

function SkynetIADS:addEarlyWarningRadar(earlyWarningRadarUnitName)
	local earlyWarningRadarUnit = Unit.getByName(earlyWarningRadarUnitName)
	if earlyWarningRadarUnit == nil then
		self:printOutputToLog("you have added an EW Radar that does not exist, check name of Unit in Setup and Mission editor: "..earlyWarningRadarUnitName, true)
		return
	end
	self:setCoalition(earlyWarningRadarUnit)
	local ewRadar = nil
	local category = earlyWarningRadarUnit:getDesc().category
	if category == Unit.Category.AIRPLANE or category == Unit.Category.SHIP then
		ewRadar = SkynetIADSAWACSRadar:create(earlyWarningRadarUnit, self)
	else
		ewRadar = SkynetIADSEWRadar:create(earlyWarningRadarUnit, self)
	end
	ewRadar:setupElements()
	ewRadar:setCachedTargetsMaxAge(self:getCachedTargetsMaxAge())	
	-- for performance improvement, if iads is not scanning no update coverage update needs to be done, will be executed once when iads activates
	-- 为了性能优化，如果IADS未扫描则无需更新覆盖范围，将在IADS激活时执行一次
	if self.ewRadarScanMistTaskID ~= nil then
		self:buildRadarCoverageForEarlyWarningRadar(ewRadar)
	end
	ewRadar:setActAsEW(true)
	ewRadar:setToCorrectAutonomousState()
	ewRadar:goLive()
	table.insert(self.earlyWarningRadars, ewRadar)
	if self:getDebugSettings().addedEWRadar then
			self:printOutputToLog("ADDED: "..ewRadar:getDescription())
	end
	return ewRadar
end

function SkynetIADS:getCachedTargetsMaxAge()
	return self.contactUpdateInterval
end

function SkynetIADS:getEarlyWarningRadars()
	return self:createTableDelegator(self.earlyWarningRadars)
end

function SkynetIADS:getEarlyWarningRadarByUnitName(unitName)
	for i = 1, #self.earlyWarningRadars do
		local ewRadar = self.earlyWarningRadars[i]
		if ewRadar:getDCSName() == unitName then
			return ewRadar
		end
	end
end

function SkynetIADS:findSubString(haystack, needle)
	return string.find(haystack, needle, 1, true)
end

function SkynetIADS:addSAMSitesByPrefix(prefix)
	self:deativateSAMSites()
	self.samSites = {}
	for groupName, groupData in pairs(mist.DBs.groupsByName) do
		local pos = self:findSubString(groupName, prefix)
		if pos and pos == 1 then
			--mist returns groups, units and, StaticObjects
		--mist返回groups、units和StaticObjects
			local dcsObject = Group.getByName(groupName)
			if dcsObject and dcsObject:getUnits()[1]:isActive() then
				self:addSAMSite(groupName)
			end
		end
	end
	return self:createTableDelegator(self.samSites)
end

function SkynetIADS:getSAMSitesByPrefix(prefix)
	local returnSams = {}
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		local groupName = samSite:getDCSName()
		local pos = self:findSubString(groupName, prefix)
		if pos and pos == 1 then
			table.insert(returnSams, samSite)
		end
	end
	return self:createTableDelegator(returnSams)
end

function SkynetIADS:addSAMSite(samSiteName)
	local samSiteDCS = Group.getByName(samSiteName)
	if samSiteDCS == nil then
		self:printOutputToLog("you have added an SAM Site that does not exist, check name of Group in Setup and Mission editor: "..tostring(samSiteName), true)
		return
	end
	self:setCoalition(samSiteDCS)
	local samSite = SkynetIADSSamSite:create(samSiteDCS, self)
	samSite:setupElements()
	samSite:setCanEngageAirWeapons(true)
	samSite:goLive()
	samSite:setCachedTargetsMaxAge(self:getCachedTargetsMaxAge())
	if samSite:getNatoName() == "UNKNOWN" then
		self:printOutputToLog("you have added an SAM site that Skynet IADS can not handle: "..samSite:getDCSName(), true)
		samSite:cleanUp()
	else
		samSite:goDark()
		table.insert(self.samSites, samSite)
		if self:getDebugSettings().addedSAMSite then
			self:printOutputToLog("ADDED: "..samSite:getDescription())
		end
		-- for performance improvement, if iads is not scanning no update coverage update needs to be done, will be executed once when iads activates
		-- 为了性能优化，如果IADS未扫描则无需更新覆盖范围，将在IADS激活时执行一次
		if self.ewRadarScanMistTaskID ~= nil then
			self:buildRadarCoverageForSAMSite(samSite)
		end
		return samSite
	end 
end

function SkynetIADS:getUsableSAMSites()
	return self:getUsableAbstractRadarElemtentsOfTable(self.samSites)
end

function SkynetIADS:getDestroyedSAMSites()
	local destroyedSites = {}
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:isDestroyed() then
			table.insert(destroyedSites, samSite)
		end
	end
	return destroyedSites
end

function SkynetIADS:getSAMSites()
	return self:createTableDelegator(self.samSites)
end

function SkynetIADS:getSAMSiteByGroupName(groupName)
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:getDCSName() == groupName then
			return samSite
		end
	end
	return nil
end

function SkynetIADS:getActiveSAMSites()
	local activeSAMSites = {}
	for i = 1, #self.samSites do
		if self.samSites[i]:isActive() then
			table.insert(activeSAMSites, self.samSites[i])
		end
	end
	return activeSAMSites
end

function SkynetIADS:getSAMSiteByGroupName(groupName)
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:getDCSName() == groupName then
			return samSite
		end
	end
end

function SkynetIADS:getSAMSitesByNatoName(natoName)
	local selectedSAMSites = SkynetIADSTableDelegator:create()
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		if samSite:getNatoName() == natoName then
			table.insert(selectedSAMSites, samSite)
		end
	end
	return selectedSAMSites
end

function SkynetIADS:addCommandCenter(commandCenter)
	self:setCoalition(commandCenter)
	local comCenter = SkynetIADSCommandCenter:create(commandCenter, self)
	table.insert(self.commandCenters, comCenter)
	-- when IADS is active the radars will be added to the new command center. If it not active this will happen when radar coverage is built
	-- 当IADS激活时，雷达将被添加到新的指挥中心。如果未激活，这将在构建雷达覆盖范围时发生
	if self.ewRadarScanMistTaskID ~= nil then
		self:addRadarsToCommandCenters()
	end
	return comCenter
end

function SkynetIADS:isCommandCenterUsable()
	if #self:getCommandCenters() == 0 then
		return true
	end
	local usableComCenters = self:getUsableAbstractRadarElemtentsOfTable(self:getCommandCenters())
	return (#usableComCenters > 0)
end

function SkynetIADS:getCommandCenters()
	return self.commandCenters
end


-- ============================================================================
-- 核心目标评估函数 - IADS 系统的心脏
-- 这是整个 IADS 系统最重要的函数，负责：
-- 1. 收集所有雷达检测到的目标
-- 2. 将目标信息分发给相关 SAM 站点
-- 3. 管理雷达的开关状态
-- 4. 处理 HARM 威胁检测
-- 此函数由 MIST 定时器定期调用（默认每5秒）
-- ============================================================================
function SkynetIADS.evaluateContacts(self)
	-- 获取所有可用的早期预警雷达和 SAM 站点
	local ewRadars = self:getUsableEarlyWarningRadars()
	local samSites = self:getUsableSAMSites()
	
	-- ========================================================================
	-- 第一阶段：处理 SAM 站点
	-- 将作为 EW 雷达的 SAM 站点添加到 EW 雷达数组中
	-- ========================================================================
	for i = 1, #samSites do
		local samSite = samSites[i]
		
		-- 通知 SAM 站点目标更新周期开始
		-- 如果循环后没有目标在范围内，SAM 站点将关闭雷达
		samSite:targetCycleUpdateStart()
		
		-- 如果 SAM 站点配置为 EW 模式，将其添加到 EW 雷达数组
		if samSite:getActAsEW() then
			table.insert(ewRadars, samSite)
		end
		
		-- 如果 SAM 站点不在 EW 模式且处于活动状态，直接获取其检测到的目标
		-- 这样可以减少重复的目标检测
		if samSite:isActive() and samSite:getActAsEW() == false then
			local contacts = samSite:getDetectedTargets()
			for j = 1, #contacts do
				local contact = contacts[j]
				self:mergeContact(contact)
			end
		end
	end

	-- ========================================================================
	-- 第二阶段：处理 EW 雷达
	-- 收集 EW 雷达检测到的目标，并准备触发相关 SAM 站点
	-- ========================================================================
	local samSitesToTrigger = {}  -- 需要触发的 SAM 站点哈希表
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		
		-- 尝试让 EW 雷达上线（如果之前因 HARM 攻击而关闭）
		ewRadar:goLive()
		
		-- 如果是 AWACS 且移动距离超过阈值，更新 SAM 站点的自主状态
		-- 这确保了移动的 AWACS 能正确覆盖其范围内的 SAM 站点
		if getmetatable(ewRadar) == SkynetIADSAWACSRadar and ewRadar:isUpdateOfAutonomousStateOfSAMSitesRequired() then
			self:buildRadarCoverageForEarlyWarningRadar(ewRadar)
		end
		
		-- 获取 EW 雷达检测到的目标
		local ewContacts = ewRadar:getDetectedTargets()
		if EA18GSkynetJammerBridge and EA18GSkynetJammerBridge.filterEWContacts then
			local filteredContacts = EA18GSkynetJammerBridge.filterEWContacts(ewRadar, ewContacts)
			if filteredContacts ~= nil then
				ewContacts = filteredContacts
			end
		end
		if #ewContacts > 0 then
			-- 获取该 EW 雷达覆盖范围内的可用 SAM 站点
			local samSitesUnderCoverage = ewRadar:getUsableChildRadars()
			
			-- 收集需要触发的非活跃 SAM 站点
			for j = 1, #samSitesUnderCoverage do
				local samSiteUnterCoverage = samSitesUnderCoverage[j]
				-- 只有非活跃的 SAM 站点才需要被触发
				if samSiteUnterCoverage:isActive() == false then
					-- 使用哈希表确保每个 SAM 站点只被添加一次，提高性能
					samSitesToTrigger[samSiteUnterCoverage:getDCSName()] = samSiteUnterCoverage
				end
			end
			
			-- 将 EW 雷达检测到的目标合并到 IADS 目标列表中
			for j = 1, #ewContacts do
				local contact = ewContacts[j]
				self:mergeContact(contact)
			end
		end
	end

	-- ========================================================================
	-- 第三阶段：清理过期目标
	-- 移除超过最大存活时间的目标，保持目标列表的时效性
	-- ========================================================================
	self:cleanAgedTargets()
	
	-- ========================================================================
	-- 第四阶段：目标分发
	-- 将检测到的目标分发给需要触发的 SAM 站点
	-- ========================================================================
	for samName, samToTrigger in pairs(samSitesToTrigger) do
		for j = 1, #self.contacts do
			local contact = self.contacts[j]
			
			-- 获取目标的类别信息
			local description = contact:getDesc()
			local category = description.category
			
			-- 只将空中目标（飞机、导弹等）分发给 SAM 站点
			-- 排除地面单位、舰船和建筑物
			if category and category ~= Unit.Category.GROUND_UNIT and 
			   category ~= Unit.Category.SHIP and 
			   category ~= Unit.Category.STRUCTURE then
				samToTrigger:informOfContact(contact)
			end
		end
	end
	
	-- ========================================================================
	-- 第五阶段：完成目标更新周期
	-- 通知所有 SAM 站点目标更新周期结束
	-- ========================================================================
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:targetCycleUpdateEnd()
	end
	
	-- ========================================================================
	-- 第六阶段：HARM 威胁检测
	-- 分析所有目标，识别可能的 HARM 导弹威胁
	-- ========================================================================
	self.harmDetection:setContacts(self:getContacts())
	self.harmDetection:evaluateContacts()
	
	-- ========================================================================
	-- 第七阶段：系统状态记录
	-- 记录当前 IADS 系统的状态信息
	-- ========================================================================
	self.logger:printSystemStatus()
end

-- ============================================================================
-- 清理过期目标函数
-- 功能: 移除超过最大存活时间的目标，保持目标列表的时效性
-- 参数: 无
-- 返回: 无
-- ============================================================================
function SkynetIADS:cleanAgedTargets()
	local contactsToKeep = {}
	-- 遍历所有目标
	for i = 1, #self.contacts do
		local contact = self.contacts[i]
		-- 只保留未过期的目标
		if contact:getAge() < self.maxTargetAge then
			table.insert(contactsToKeep, contact)
		end
	end
	-- 更新目标列表
	self.contacts = contactsToKeep
end

--TODO unit test this method:
--TODO 单元测试此方法：
function SkynetIADS:getAbstracRadarElements()
	local abstractRadarElements = {}
	local ewRadars = self:getEarlyWarningRadars()
	local samSites = self:getSAMSites()
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		table.insert(abstractRadarElements, ewRadar)
	end
	
	for i = 1, #samSites do
		local samSite = samSites[i]
		table.insert(abstractRadarElements, samSite)
	end
	return abstractRadarElements
end


function SkynetIADS:addRadarsToCommandCenters()

	--we clear any existing radars that may have been added earlier
	--我们清除可能之前添加的任何现有雷达
	local comCenters = self:getCommandCenters()
	for i = 1, #comCenters do
		local comCenter = comCenters[i]
		comCenter:clearChildRadars()
	end	
	
	-- then we add child radars to the command centers
	-- 然后我们将子雷达添加到指挥中心
	local abstractRadarElements = self:getAbstracRadarElements()
		for i = 1, #abstractRadarElements do
			local abstractRadar = abstractRadarElements[i]
			self:addSingleRadarToCommandCenters(abstractRadar)
		end
end

function SkynetIADS:addSingleRadarToCommandCenters(abstractRadarElement)
	local comCenters = self:getCommandCenters()
	for i = 1, #comCenters do
		local comCenter = comCenters[i]
		comCenter:addChildRadar(abstractRadarElement)
	end	
end

-- this method rebuilds the radar coverage of the IADS, a complete rebuild is only required the first time the IADS is activated
-- during runtime it is sufficient to call buildRadarCoverageForSAMSite or buildRadarCoverageForEarlyWarningRadar method that just updates the IADS for one unit, this saves script execution time
-- 此方法重建IADS的雷达覆盖范围，完整重建仅在IADS首次激活时需要
-- 在运行时，调用buildRadarCoverageForSAMSite或buildRadarCoverageForEarlyWarningRadar方法仅更新一个单元的IADS就足够了，这节省了脚本执行时间
function SkynetIADS:buildRadarCoverage()	
	
	--to build the basic radar coverage we use all SAM sites. Checks if SAM site has power or a connection node is done when using the SAM site later on
	--为了构建基本雷达覆盖范围，我们使用所有SAM站点。检查SAM站点是否有电源或连接节点在使用SAM站点时进行
	local samSites = self:getSAMSites()
	
	--first we clear all child and parent radars that may have been added previously
	--首先我们清除可能之前添加的所有子雷达和父雷达
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:clearChildRadars()
		samSite:clearParentRadars()
	end
	
	local ewRadars = self:getEarlyWarningRadars()
	
	for i = 1, #ewRadars do
		local ewRadar = ewRadars[i]
		ewRadar:clearChildRadars()
	end	
	
	--then we rebuild the radar coverage
	--然后我们重建雷达覆盖范围
	local abstractRadarElements = self:getAbstracRadarElements()
	for i = 1, #abstractRadarElements do
		local abstract = abstractRadarElements[i]
		self:buildRadarCoverageForAbstractRadarElement(abstract)
	end
	
	self:addRadarsToCommandCenters()
	
	--we call this once on all sam sites, to make sure autonomous sites go live when IADS activates
	--我们在所有SAM站点上调用一次，确保自主站点在IADS激活时上线
	for i = 1, #samSites do
		local samSite = samSites[i]
		samSite:informChildrenOfStateChange()
	end

end

function SkynetIADS:buildRadarCoverageForAbstractRadarElement(abstractRadarElement)
	local abstractRadarElements = self:getAbstracRadarElements()
	for i = 1, #abstractRadarElements do
		local aElementToCompare = abstractRadarElements[i]
		if aElementToCompare ~= abstractRadarElement then
			if abstractRadarElement:isInRadarDetectionRangeOf(aElementToCompare) then
				self:buildRadarAssociation(aElementToCompare, abstractRadarElement)
			end
			if aElementToCompare:isInRadarDetectionRangeOf(abstractRadarElement) then
				self:buildRadarAssociation(abstractRadarElement, aElementToCompare)
			end
		end
	end
end

function SkynetIADS:buildRadarAssociation(parent, child)
	--chilren should only be SAM sites not EW radars
	--子项应该只是SAM站点，不是EW雷达
	if ( getmetatable(child) == SkynetIADSSamSite ) then
		parent:addChildRadar(child)
	end
	--Only SAM Sites should have parent Radars, not EW Radars
	--只有SAM站点应该有父雷达，不是EW雷达
	if ( getmetatable(child) == SkynetIADSSamSite ) then
		child:addParentRadar(parent)
	end
end

function SkynetIADS:buildRadarCoverageForSAMSite(samSite)
	self:buildRadarCoverageForAbstractRadarElement(samSite)
	self:addSingleRadarToCommandCenters(samSite)
end

function SkynetIADS:buildRadarCoverageForEarlyWarningRadar(ewRadar)
	self:buildRadarCoverageForAbstractRadarElement(ewRadar)
	self:addSingleRadarToCommandCenters(ewRadar)
end

function SkynetIADS:mergeContact(contact)
	local existingContact = false
	for i = 1, #self.contacts do
		local iadsContact = self.contacts[i]
		if iadsContact:getName() == contact:getName() then
			iadsContact:refresh()
			--these contacts are used in the logger we set a kown harm state of a contact coming from a SAM site. So the logger will show them als HARMs
			--这些接触用于记录器，我们设置来自SAM站点的接触的已知HARM状态。所以记录器将显示它们为HARMs
			contact:setHARMState(iadsContact:getHARMState())
			local radars = contact:getAbstractRadarElementsDetected()
			for j = 1, #radars do
				local radar = radars[j]
				iadsContact:addAbstractRadarElementDetected(radar)
			end
			existingContact = true
		end
	end
	if existingContact == false then
		table.insert(self.contacts, contact)
	end
end


function SkynetIADS:getContacts()
	return self.contacts
end

function SkynetIADS:getDebugSettings()
	return self.logger.debugOutput
end

function SkynetIADS:printOutput(output, typeWarning)
	self.logger:printOutput(output, typeWarning)
end

function SkynetIADS:printOutputToLog(output)
	self.logger:printOutputToLog(output)
end

function SkynetIADS:getOrderTrace()
	return self.orderTrace
end

function SkynetIADS:setOrderTraceContext(element, context)
	if self.orderTrace and self.orderTrace.setElementContext then
		self.orderTrace:setElementContext(element, context)
	end
end

function SkynetIADS:clearOrderTraceContext(element)
	if self.orderTrace and self.orderTrace.clearElementContext then
		self.orderTrace:clearElementContext(element)
	end
end

function SkynetIADS:traceCommand(details)
	if self.orderTrace and self.orderTrace.traceCommand then
		return self.orderTrace:traceCommand(details)
	end
	return false
end

function SkynetIADS:traceEntryCommand(entry, command, details)
	if self.orderTrace and self.orderTrace.traceEntryCommand then
		return self.orderTrace:traceEntryCommand(entry, command, details)
	end
	return false
end

function SkynetIADS:traceElementCommand(element, command, details)
	if self.orderTrace and self.orderTrace.traceElementCommand then
		return self.orderTrace:traceElementCommand(element, command, details)
	end
	return false
end

function SkynetIADS:traceAirUnit(unit, details)
	if self.orderTrace and self.orderTrace.traceAirUnit then
		return self.orderTrace:traceAirUnit(unit, details)
	end
	return false
end

function SkynetIADS:traceWeaponContact(contact, details)
	if self.orderTrace and self.orderTrace.traceWeaponContact then
		return self.orderTrace:traceWeaponContact(contact, details)
	end
	return false
end

function SkynetIADS:getGPSSpoofer()
	return self.gpsSpoofer
end

function SkynetIADS:enableGPSSpoofing(options)
	if self.gpsSpoofer == nil then
		self.gpsSpoofer = SkynetIADSGPSSpoofer:create(self, options or {})
	elseif options ~= nil then
		self.gpsSpoofer.options = options
	end
	if self.ewRadarScanMistTaskID ~= nil and self.gpsSpoofer.start then
		self.gpsSpoofer:start()
	end
	return self.gpsSpoofer
end

-- ============================================================================
-- 激活 IADS 系统
-- 功能: 启动整个 IADS 系统，开始目标检测和跟踪
-- 参数: 无
-- 返回: 无
-- 说明: 这是 IADS 系统的核心启动函数，会启动定时扫描任务
-- ============================================================================
function SkynetIADS.activate(self)
	-- 移除可能存在的旧扫描任务
	mist.removeFunction(self.ewRadarScanMistTaskID)
	
	-- 启动新的定时扫描任务
	-- 每 contactUpdateInterval 秒调用一次 evaluateContacts 函数
	self.ewRadarScanMistTaskID = mist.scheduleFunction(SkynetIADS.evaluateContacts, {self}, 1, self.contactUpdateInterval)
	
	-- 构建雷达覆盖网络
	self:buildRadarCoverage()
	if self.gpsSpoofer and self.gpsSpoofer.start then
		self.gpsSpoofer:start()
	end
end

-- ============================================================================
-- 已废弃的 SAM 站点设置和激活函数
-- 功能: 旧版本的激活函数，现在已不再需要
-- 参数: setupTime - 设置时间（已废弃）
-- 返回: 无
-- 说明: 此函数已废弃，保留仅为向后兼容
-- ============================================================================
function SkynetIADS:setupSAMSitesAndThenActivate(setupTime)
	self:activate()
	self.logger:printOutputToLog("DEPRECATED: setupSAMSitesAndThenActivate, no longer needed since using enableEmission instead of AI on / off allows for the Ground units to setup with their radars turned off")
end

-- ============================================================================
-- 停用 IADS 系统
-- 功能: 完全关闭 IADS 系统，清理所有资源
-- 参数: 无
-- 返回: 无
-- 说明: 停止所有扫描任务并清理所有组件
-- ============================================================================
function SkynetIADS:deactivate()
	-- 停止所有 MIST 定时任务
	mist.removeFunction(self.ewRadarScanMistTaskID)
	mist.removeFunction(self.samSetupMistTaskID)
	if self.gpsSpoofer and self.gpsSpoofer.stop then
		self.gpsSpoofer:stop()
	end
	
	-- 停用所有组件
	self:deativateSAMSites()           -- 停用所有 SAM 站点
	self:deactivateEarlyWarningRadars() -- 停用所有 EW 雷达
	self:deactivateCommandCenters()     -- 停用所有指挥中心
end

function SkynetIADS:deactivateCommandCenters()
	for i = 1, #self.commandCenters do
		local comCenter = self.commandCenters[i]
		comCenter:cleanUp()
	end
end

function SkynetIADS:deativateSAMSites()
	for i = 1, #self.samSites do
		local samSite = self.samSites[i]
		samSite:cleanUp()
	end
end

function SkynetIADS:deactivateEarlyWarningRadars()
	for i = 1, #self.earlyWarningRadars do
		local ewRadar = self.earlyWarningRadars[i]
		ewRadar:cleanUp()
	end
end	

function SkynetIADS:addRadioMenu()
	self.radioMenu = missionCommands.addSubMenu('SKYNET IADS '..self:getCoalitionString())
	local displayIADSStatus = missionCommands.addCommand('show IADS Status', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = true, option = 'IADSStatus'})
	local displayIADSStatus = missionCommands.addCommand('hide IADS Status', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = false, option = 'IADSStatus'})
	local displayIADSStatus = missionCommands.addCommand('show contacts', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = true, option = 'contacts'})
	local displayIADSStatus = missionCommands.addCommand('hide contacts', self.radioMenu, SkynetIADS.updateDisplay, {self = self, value = false, option = 'contacts'})
	self.detailedStateMenu = missionCommands.addSubMenu('Detailed State', self.radioMenu)
	missionCommands.addCommand('Refresh List', self.detailedStateMenu, SkynetIADS.rebuildDetailedStateMenu, self)
	self:rebuildDetailedStateMenu()
end

function SkynetIADS:removeRadioMenu()
	missionCommands.removeItem(self.radioMenu)
end

function SkynetIADS.showDetailedSAMState(params)
	local self = params.self
	local groupName = params.groupName
	local samSite = self:getSAMSiteByGroupName(groupName)
	if samSite == nil then
		trigger.action.outText("Detailed State | SAM site not found: "..tostring(groupName), 10)
		return
	end
	trigger.action.outText(self.logger:buildDetailedSAMSiteReport(samSite), 18)
end

function SkynetIADS:rebuildDetailedStateMenu()
	if self.detailedStatePageMenus then
		for i = 1, #self.detailedStatePageMenus do
			missionCommands.removeItem(self.detailedStatePageMenus[i])
		end
	end
	self.detailedStatePageMenus = {}

	if self.detailedStateMenu == nil then
		return
	end

	local samSites = {}
	for i = 1, #self.samSites do
		samSites[#samSites + 1] = self.samSites[i]
	end
	table.sort(samSites, function(a, b)
		return a:getDCSName() < b:getDCSName()
	end)

	local pageSize = self.detailedStatePageSize or 8
	local pageCount = math.max(1, math.ceil(#samSites / pageSize))
	for pageIndex = 1, pageCount do
		local pageMenu = missionCommands.addSubMenu('Page '..pageIndex, self.detailedStateMenu)
		self.detailedStatePageMenus[#self.detailedStatePageMenus + 1] = pageMenu
		local startIndex = ((pageIndex - 1) * pageSize) + 1
		local endIndex = math.min(pageIndex * pageSize, #samSites)
		if startIndex > endIndex then
			missionCommands.addCommand('No SAM Sites', pageMenu, function()
				trigger.action.outText("Detailed State | no SAM sites registered", 8)
			end)
		else
			for i = startIndex, endIndex do
				local samSite = samSites[i]
				missionCommands.addCommand(samSite:getDCSName(), pageMenu, SkynetIADS.showDetailedSAMState, {
					self = self,
					groupName = samSite:getDCSName()
				})
			end
		end
	end
end

function SkynetIADS.updateDisplay(params)
	local option = params.option
	local self = params.self
	local value = params.value
	if option == 'IADSStatus' then
		self:getDebugSettings()[option] = value
	elseif option == 'contacts' then
		self:getDebugSettings()[option] = value
	end
end

function SkynetIADS:getCoalitionString()
	local coalitionStr = "RED"
	if self.coalitionID == coalition.side.BLUE then
		coalitionStr = "BLUE"
	elseif self.coalitionID == coalition.side.NEUTRAL then
		coalitionStr = "NEUTRAL"
	end
		
	if self.name then
		coalitionStr = "COALITION: "..coalitionStr.." | NAME: "..self.name
	end
	
	return coalitionStr
end

function SkynetIADS:getMooseConnector()
	if self.mooseConnector == nil then
		self.mooseConnector = SkynetMooseA2ADispatcherConnector:create(self)
	end
	return self.mooseConnector
end

function SkynetIADS:addMooseSetGroup(mooseSetGroup)
	self:getMooseConnector():addMooseSetGroup(mooseSetGroup)
end

end
