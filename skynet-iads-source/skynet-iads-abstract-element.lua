do
-- ============================================================================
-- Skynet IADS 抽象元素基类
-- 这是所有 IADS 元素（雷达、SAM站点、指挥中心等）的基类
-- 提供了电源管理、连接节点管理、事件处理等通用功能
-- ============================================================================

-- 定义抽象元素类，继承自 DCS 对象包装器
SkynetIADSAbstractElement = {}
SkynetIADSAbstractElement = inheritsFrom(SkynetIADSAbstractDCSObjectWrapper)

-- ============================================================================
-- 创建抽象元素实例的构造函数
-- 参数: dcsRepresentation - DCS 中的单位或组对象
--       iads - 所属的 IADS 系统实例
-- 返回: 新创建的抽象元素实例
-- ============================================================================
function SkynetIADSAbstractElement:create(dcsRepresentation, iads)
	-- 调用父类构造函数创建基础实例
	local instance = self:superClass():create(dcsRepresentation)
	-- 设置元表实现继承
	setmetatable(instance, self)
	self.__index = self
	
	-- 初始化抽象元素特有的属性
	instance.connectionNodes = {}    -- 连接节点数组（用于通信）
	instance.powerSources = {}       -- 电源数组（用于供电）
	instance.iads = iads            -- 所属的 IADS 系统引用
	instance.natoName = "UNKNOWN"   -- NATO 代号（如 SA-10, Patriot 等）
	
	-- 向 DCS 世界注册事件处理器
	world.addEventHandler(instance)
	
	return instance
end

function SkynetIADSAbstractElement:removeEventHandlers()
	world.removeEventHandler(self)
end

function SkynetIADSAbstractElement:cleanUp()
	self:removeEventHandlers()
end

function SkynetIADSAbstractElement:isDestroyed()
	return self:getDCSRepresentation():isExist() == false
end

function SkynetIADSAbstractElement:addPowerSource(powerSource)
	table.insert(self.powerSources, powerSource)
	self:informChildrenOfStateChange()
	return self
end

function SkynetIADSAbstractElement:getPowerSources()
	return self.powerSources
end

function SkynetIADSAbstractElement:addConnectionNode(connectionNode)
	table.insert(self.connectionNodes, connectionNode)
	self:informChildrenOfStateChange()
	return self
end

function SkynetIADSAbstractElement:getConnectionNodes()
	return self.connectionNodes
end

function SkynetIADSAbstractElement:hasActiveConnectionNode()
	local connectionNode = self:genericCheckOneObjectIsAlive(self.connectionNodes)
	if connectionNode == false and self.iads:getDebugSettings().samNoConnection then
		self.iads:printOutput(self:getDescription().." no connection to Command Center")
	end
	return connectionNode
end

function SkynetIADSAbstractElement:hasWorkingPowerSource()
	local power = self:genericCheckOneObjectIsAlive(self.powerSources)
	if power == false and self.iads:getDebugSettings().hasNoPower then
		self.iads:printOutput(self:getDescription().." has no power")
	end
	return power
end

function SkynetIADSAbstractElement:getDCSName()
	return self.dcsName
end

-- generic function to theck if power plants, command centers, connection nodes are still alive
-- 通用函数检查发电厂、指挥中心、连接节点是否仍然存活
function SkynetIADSAbstractElement:genericCheckOneObjectIsAlive(objects)
	local isAlive = (#objects == 0)
	for i = 1, #objects do
		local object = objects[i]
		--if we find one object that is not fully destroyed we assume the IADS is still working
		--如果我们找到一个未完全摧毁的对象，我们假设IADS仍在工作
		if object:isExist() then
			isAlive = true
			break
		end
	end
	return isAlive
end

function SkynetIADSAbstractElement:getNatoName()
	return self.natoName
end

function SkynetIADSAbstractElement:getDescription()
	return "IADS ELEMENT: "..self:getDCSName().." | Type: "..tostring(self:getNatoName())
end

function SkynetIADSAbstractElement:onEvent(event)
	--if a unit is destroyed we check to see if its a power plant powering the unit or a connection node
	--如果单位被摧毁，我们检查它是否为该单位供电的发电厂或连接节点
	if event.id == world.event.S_EVENT_DEAD then
		if self:hasWorkingPowerSource() == false or self:isDestroyed() then
			self:goDark()
			self:informChildrenOfStateChange()
		end
		if self:hasActiveConnectionNode() == false then
			self:informChildrenOfStateChange()
		end
	end
	if event.id == world.event.S_EVENT_SHOT then
		self:weaponFired(event)
	end
end

--placeholder method, can be implemented by subclasses
--占位符方法，可以由子类实现
function SkynetIADSAbstractElement:weaponFired(event)
	
end

--placeholder method, can be implemented by subclasses
--占位符方法，可以由子类实现
function SkynetIADSAbstractElement:goDark()
	
end

--placeholder method, can be implemented by subclasses
--占位符方法，可以由子类实现
function SkynetIADSAbstractElement:goAutonomous()

end

--placeholder method, can be implemented by subclasses
--占位符方法，可以由子类实现
function SkynetIADSAbstractElement:setToCorrectAutonomousState()

end

--placeholder method, can be implemented by subclasses
--占位符方法，可以由子类实现
function SkynetIADSAbstractElement:informChildrenOfStateChange()
	
end

end
