-- === EA-18G EW Script by Timberwolf - Minimal Update ===
-- 基于原始脚本的最小化修改版本
-- 只修改导弹诱爆逻辑，其他功能保持不变
-- 修改：使用新的干扰值计算和0.5秒循环频率
-- Requires MIST to be loaded before this script
trigger.action.outText("EA-18G 电子战脚本已加载 (最小化更新版)", 10)

local jammerUnits = {
  "Growler"
}

-- 新增：干扰值参数
local ALQ99_JAM_VALUE = 3   -- ALQ-99 单吊舱干扰值
local ALQ249_JAM_VALUE = 4  -- ALQ-249 单吊舱干扰值
local MISSILE_THRESHOLD = 100  -- 导弹自爆阈值
local REFERENCE_DISTANCE = 9260  -- 参考距离：5海里 = 9260米

local jammerSettings = {}
local jammerGroupIDs = {}
local jammerMenus = {}
local spotTargetMenus = {}
local spotTargetCommands = {}
local emitterCapacity = {}
local maxEmitterCapacity = {}
local defaultMaxCapacity = 0
local regenRate = 20
local drainRateArea = 15
local drainRateDirectional = 5
local jammerUpdateInterval = 5
local menuCheckInterval = 2
local reportInterval = 20
local overheatThreshold = 15
local lastReportTime = {}
local trackedMissiles = {}
local missileUID = 1
local suppressedSAMs = {}

-- 修改：导弹循环间隔改为0.5秒
local missileUpdateInterval = 1

local function get3DDist(p1, p2)
    local dx = p1.x - p2.x
    local dy = p1.y - p2.y
    local dz = p1.z - p2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getClockBearing(jammerUnit, missilePos)
    if not jammerUnit or not jammerUnit:isExist() then return "?" end
    local jammerPos = jammerUnit:getPosition().p
    local heading = mist.getHeading(jammerUnit)
    local dx = missilePos.x - jammerPos.x
    local dz = missilePos.z - jammerPos.z
    local angleToMissile = math.atan2(dz, dx)
    local relAngle = angleToMissile - heading
    if relAngle < 0 then relAngle = relAngle + 2 * math.pi end
    local hours = math.floor((relAngle / (2 * math.pi)) * 12 + 0.5)
    if hours == 0 then hours = 12 end
    return hours .. " o'clock"
end

-- 新增：计算干扰值 - 平方反比定律（5海里内解锁上限）
local function calculateJamValue(distance, direction, alq99Count, alq249Count)
    if distance <= 0 then return 0 end
    
    -- 计算总干扰值
    local totalJamValue = (alq99Count * ALQ99_JAM_VALUE) + (alq249Count * ALQ249_JAM_VALUE)
    
    -- 方向权重
    local DIR_MULT = { front=1.0, left=0.8, right=0.8, rear=0.6 }
    local directionWeight = DIR_MULT[direction] or 0.5
    
    -- 修改：5海里内解锁平方反比限制
    local jamValue
    if distance <= REFERENCE_DISTANCE then
        -- 5海里内：使用真实平方反比，无下限限制
        jamValue = totalJamValue * (REFERENCE_DISTANCE / distance) ^ 2 * directionWeight
    else
        -- 5海里外：正常的平方反比衰减
        jamValue = totalJamValue * (REFERENCE_DISTANCE / distance) ^ 2 * directionWeight
    end
    
    return jamValue
end

-- 新增：根据干扰机方位计算方向
local function calculateDirection(jammerUnit, missilePos)
    if not jammerUnit or not jammerUnit:isExist() then return "front" end
    local jammerPos = jammerUnit:getPosition().p
    local heading = mist.getHeading(jammerUnit)
    local dx = missilePos.x - jammerPos.x
    local dz = missilePos.z - jammerPos.z
    local angleToMissile = math.atan2(dz, dx)
    local relAngle = angleToMissile - heading
    if relAngle < 0 then relAngle = relAngle + 2 * math.pi end
    
    local angle = math.deg(relAngle)
    if angle >= 315 or angle <= 45 then return "front"
    elseif angle > 45 and angle <= 135 then return "right"
    elseif angle > 135 and angle <= 225 then return "rear"
    elseif angle > 225 and angle < 315 then return "left" end
    return "front"
end

local function debugEmitterCapacity(jammer)
    local msg = jammer .. " 干扰机容量: " .. emitterCapacity[jammer] .. "/" .. maxEmitterCapacity[jammer]
    local active = {}
    if jammerSettings[jammer].defensive then table.insert(active, "防御区域干扰") end
    if jammerSettings[jammer].offensive then table.insert(active, "攻击区域干扰") end
    if jammerSettings[jammer].defDir then table.insert(active, "防御定向 " .. jammerSettings[jammer].defDir) end
    if jammerSettings[jammer].offDir then table.insert(active, "攻击定向 " .. jammerSettings[jammer].offDir) end
    if #active > 0 then
        msg = msg .. " | 活动: " .. table.concat(active, ", ")
    end
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], msg, 4)
end
end

local EW_EventHandler = {}
function EW_EventHandler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT and event.weapon then
        local desc = event.weapon:getDesc()
        if desc and (desc.guidance == 3 or desc.guidance == 4) then
            local target = Weapon.getTarget(event.weapon)
            if target and target:isExist() then
                trackedMissiles[missileUID] = {
                    missile = event.weapon,
                    target = target,
                    uid = missileUID
                }
                missileUID = missileUID + 1
            end
        end
    end
end
world.addEventHandler(EW_EventHandler)

local function isInSector(jammerUnit, targetPos, sector)
    if not jammerUnit or not jammerUnit:isExist() then return false end
    local jammerPos = jammerUnit:getPosition().p
    local heading = mist.getHeading(jammerUnit)
    local dx = targetPos.x - jammerPos.x
    local dz = targetPos.z - jammerPos.z
    local angleToTarget = math.deg(math.atan2(dz, dx))
    local relAngle = (angleToTarget - math.deg(heading)) % 360
    if sector == "front" then return relAngle >= 315 or relAngle <= 45
    elseif sector == "right" then return relAngle > 45 and relAngle <= 135
    elseif sector == "rear" then return relAngle > 135 and relAngle <= 225
    elseif sector == "left" then return relAngle > 225 and relAngle < 315 end
    return false
end

-- 修改：defensiveLoop现在只处理能量消耗，导弹判定已移到missileLoop
local function defensiveLoop(jammer)
    local drain = jammerSettings[jammer].defensive and drainRateArea or drainRateDirectional
    if emitterCapacity[jammer] >= drain then
        emitterCapacity[jammer] = emitterCapacity[jammer] - drain
    end
end

local function offensiveLoop(jammer)
    local unit = Unit.getByName(jammer)
    if not unit or not unit:isExist() then return end
    local jammerPos = unit:getPoint()
    for _, name in ipairs(mist.makeUnitTable({'[red][vehicle]', '[red][ship]'})) do
        local sam = Unit.getByName(name)
        if sam and sam:isExist() and sam:hasAttribute("SAM TR") then
            local samPos = sam:getPoint()
            local dist = get3DDist(jammerPos, samPos)
            local allowed = jammerSettings[jammer].offensive or
                (jammerSettings[jammer].offDir and isInSector(unit, samPos, jammerSettings[jammer].offDir))
            if allowed and dist < 50000 and land.isVisible(samPos, jammerPos) then
                local drain = jammerSettings[jammer].offensive and drainRateArea or drainRateDirectional
                if emitterCapacity[jammer] >= drain then
                    emitterCapacity[jammer] = emitterCapacity[jammer] - drain
                    local ctrl = sam:getGroup():getController()
                    ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
                    suppressedSAMs[name] = {sam = sam, lastSuppressed = timer.getTime()}
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "SAM已被" .. jammer .. "压制: " .. name, 3)
end
                end
            end
        end
    end
end

local function restoreSAMs()
    for name, info in pairs(suppressedSAMs) do
        local sam = info.sam
        local stillSuppressed = false

        if info.spot then
            for _, jammer in ipairs(jammerUnits) do
                if jammerSettings[jammer] and jammerSettings[jammer].spotTarget == name then
                    local unit = Unit.getByName(jammer)
                    if unit and unit:isExist() and sam and sam:isExist() then
                        local jammerPos = unit:getPoint()
                        local samPos = sam:getPoint()
                        local maxCap = maxEmitterCapacity[jammer] or 0
                        local maxRange = maxCap >= 3000 and 148160 or 111120
                        if get3DDist(jammerPos, samPos) <= maxRange and land.isVisible(samPos, jammerPos) and emitterCapacity[jammer] > 15 then
                            stillSuppressed = true
                            break
                        end
                    end
                end
            end
        else
            stillSuppressed = (timer.getTime() - info.lastSuppressed <= 5)
        end

        if not stillSuppressed then
            local sam = info.sam
            if sam and sam:isExist() then
                local ctrl = sam:getGroup():getController()
                ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
                -- 修复：移除未定义的jammer变量引用
                for _, jammer in ipairs(jammerUnits) do
                    if jammerGroupIDs[jammer] then
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "SAM已重新激活: " .. name, 3)
                        break
                    end
                end
            end
            suppressedSAMs[name] = nil
        end
    end
end

local function jammerLoop()
    for _, jammer in ipairs(jammerUnits) do
        jammerSettings[jammer] = jammerSettings[jammer] or {}
        emitterCapacity[jammer] = emitterCapacity[jammer] or maxEmitterCapacity[jammer] or defaultMaxCapacity
        maxEmitterCapacity[jammer] = maxEmitterCapacity[jammer] or defaultMaxCapacity
        lastReportTime[jammer] = lastReportTime[jammer] or 0

        local active = false
        local totalDrain = 0

        -- Defensive drain - 固定100点/周期
        if jammerSettings[jammer].defensive then
            totalDrain = totalDrain + 100
            active = true
        elseif jammerSettings[jammer].defDir then
            totalDrain = totalDrain + 100
            active = true
        end

        -- Offensive drain
        -- Spot jamming drain
        if jammerSettings[jammer].spotTarget then
            totalDrain = totalDrain + 30
            active = true
        end

        if jammerSettings[jammer].offensive then
            totalDrain = totalDrain + drainRateArea
            active = true
        elseif jammerSettings[jammer].offDir then
            totalDrain = totalDrain + drainRateDirectional
            active = true
        end

        -- Apply drain
        if active then
            emitterCapacity[jammer] = math.max(0, emitterCapacity[jammer] - totalDrain)
            debugEmitterCapacity(jammer)
        else
            -- Regen when idle - 基于吊舱类型计算充能速度
            local preset = jammerSettings[jammer].currentPreset or {}
            local alq99Count = preset.alq99 or 0
            local alq249Count = preset.alq249 or 0
            local regenAmount = (alq99Count * 15) + (alq249Count * 20)  -- ALQ-99: 15/周期, ALQ-249: 20/周期
            
            if regenAmount > 0 then
                emitterCapacity[jammer] = math.min(maxEmitterCapacity[jammer], emitterCapacity[jammer] + regenAmount)
            else
                -- 无吊舱时充能速度为0，不进行任何充能
                -- emitterCapacity[jammer] 保持不变
            end
            
            if (timer.getTime() - lastReportTime[jammer] >= reportInterval) and emitterCapacity[jammer] < maxEmitterCapacity[jammer] then
                debugEmitterCapacity(jammer)
                lastReportTime[jammer] = timer.getTime()
            end
        end

        -- Overheat protection
        if emitterCapacity[jammer] <= overheatThreshold and active then
            jammerSettings[jammer].offensive = false
            jammerSettings[jammer].offDir = nil
            jammerSettings[jammer].defensive = false
            jammerSettings[jammer].defDir = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], jammer .. " 干扰系统过热自动关闭", 4)
end
        end

        -- Run spoof/suppress logic AFTER draining
        -- Spot jamming logic
        if jammerSettings[jammer].spotTarget and emitterCapacity[jammer] > 15 then
            local unit = Unit.getByName(jammer)
            local targetGroup = Group.getByName(jammerSettings[jammer].spotTarget)
            if unit and unit:isExist() and targetGroup then
                local jammerPos = unit:getPoint()
                local targetUnits = targetGroup:getUnits()
                local targetUnit = nil
                for _, u in ipairs(targetUnits) do
                    if u:isExist() then
                        targetUnit = u
                        break
                    end
                end
                if targetUnit then
                    local targetPos = targetUnit:getPoint()
                    local dist = get3DDist(jammerPos, targetPos)
                    local los = land.isVisible(targetPos, jammerPos)
                    local altitudeBoost = math.min(unit:getPoint().y / 10000, 0.2)
                    local maxCap = maxEmitterCapacity[jammer] or 0
                    local maxRange = maxCap >= 3000 and 148160 or 111120
                    local fullEffectDist = maxCap >= 3000 and 101860 or 64820

                    if dist <= maxRange and los then
                        local probability = 0.2
                        if dist <= fullEffectDist then
                            probability = 1.0
                        else
                            probability = 0.2 + ((fullEffectDist / dist) * 0.8)
                        end
                        probability = math.min(probability + altitudeBoost, 1.0)

                        if math.random() < probability then
                            local ctrl = targetGroup:getController()
                            ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
                            suppressedSAMs[jammerSettings[jammer].spotTarget] = {
                                sam = targetUnit,
                                lastSuppressed = timer.getTime(),
                                spot = true
                            }
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰成功: " .. jammerSettings[jammer].spotTarget, 3)
end
                        else
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰尝试失败: " .. jammerSettings[jammer].spotTarget, 3)
end
                        end
                    else
                        jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰取消: 目标超出范围或无直线视线", 3)
end
                    end
                else
                    jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰取消: 目标丢失或被摧毁", 3)
end
                end
            else
                jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰禁用: 找不到干扰机或目标", 3)
end
            end
        elseif jammerSettings[jammer].spotTarget and emitterCapacity[jammer] <= 15 then
            jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰禁用: 发射器电量耗尽", 4)
end
        end

        if jammerSettings[jammer].defensive or jammerSettings[jammer].defDir then
            defensiveLoop(jammer)
        end
        if jammerSettings[jammer].offensive or jammerSettings[jammer].offDir then
            offensiveLoop(jammer)
        end
    end

    restoreSAMs()
    return timer.getTime() + jammerUpdateInterval
end

-- 修改：defensiveLoop只处理导弹判定，不再扣除能量（能量由jammerLoop统一管理）
local function defensiveLoop(jammer)
    local unit = Unit.getByName(jammer)
    if not unit or not unit:isExist() then return end
    local pos = unit:getPoint()
    
    -- 获取当前负载配置
    local preset = jammerSettings[jammer].currentPreset or {}
    local alq99Count = preset.alq99 or 0
    local alq249Count = preset.alq249 or 0
    
    for id, entry in pairs(trackedMissiles) do
        local m = entry.missile
        if m and Object.isExist(m) then
            local mpos = m:getPoint()
            local dist = get3DDist(pos, mpos)
            local allowed = jammerSettings[jammer].defensive or
                (jammerSettings[jammer].defDir and isInSector(unit, mpos, jammerSettings[jammer].defDir))
            
            -- 检查视线
            if allowed and land.isVisible(pos, mpos) then
                -- 计算方向和干扰值
                local direction = calculateDirection(unit, mpos)
                local jamValue = calculateJamValue(dist, direction, alq99Count, alq249Count)
                local explosionProbability = jamValue / MISSILE_THRESHOLD
                
                -- 扇面防御模式下，诱爆概率提升到130%
                if jammerSettings[jammer].defDir then
                    explosionProbability = explosionProbability * 1.3
                end
                
                -- 成功率上限20%（但扇面模式可以超过这个限制到26%）
                local maxProbability = jammerSettings[jammer].defDir and 0.26 or 0.20
                explosionProbability = math.min(explosionProbability, maxProbability)
                
                -- 获取导弹速度信息
                local mvel = m:getVelocity()
                local speed = math.sqrt(mvel.x^2 + mvel.y^2 + mvel.z^2)
                local speedKmh = math.floor(speed * 3.6)
                
                -- 格式化输出信息
                local probabilityPercent = math.floor(explosionProbability * 100 * 100) / 100
                local distNM = math.floor(dist / 1852 * 100) / 100
                
                -- 进行判定
                local randomValue = math.random()
                local success = randomValue < explosionProbability
                
                -- 输出详细判定信息
                if jammerGroupIDs[jammer] then
                    local modeText
                    if jammerSettings[jammer].defDir then
                        local dirNames = {front="前方", left="左侧", right="右侧", rear="后方"}
                        local dirChinese = dirNames[jammerSettings[jammer].defDir] or jammerSettings[jammer].defDir
                        modeText = "[扇面+" .. dirChinese .. "]"
                    else
                        modeText = "[区域]"
                    end
                    local debugMsg = string.format("导弹#%s判定%s | 距离:%.2f海里 | 速度:%dkm/h | 干扰值:%.1f | 成功率:%.2f%% | ", 
                        tostring(id), modeText, distNM, speedKmh, jamValue, probabilityPercent)
                    
                    if success then
                        local bearing = getClockBearing(unit, mpos)
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], debugMsg .. "✓ 诱爆成功 (" .. bearing .. ")", 4)
                        Object.destroy(m)
                        trackedMissiles[id] = nil -- 只移除这一枚导弹
                    else
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], debugMsg .. "✗ 诱爆失败", 3)
                    end
                else
                    if success then
                        Object.destroy(m)
                        trackedMissiles[id] = nil -- 只移除这一枚导弹
                    end
                end
            end
        else
            trackedMissiles[id] = nil
        end
    end
end

-- 新增：导弹循环函数（0.5秒间隔）
local function missileLoop()
    -- 运行防御循环处理导弹
    for _, jammer in ipairs(jammerUnits) do
        if jammerSettings[jammer] and (jammerSettings[jammer].defensive or jammerSettings[jammer].defDir) then
            defensiveLoop(jammer)
        end
    end
    return timer.getTime() + missileUpdateInterval
end

local function getBearing(from, to)
    local dx = to.x - from.x
    local dz = to.z - from.z
    local bearing = math.deg(math.atan2(dz, dx))
    if bearing < 0 then bearing = bearing + 360 end
    return math.floor(bearing + 0.5)
end

local function getNatoName(unit)
    local typeName = unit:getTypeName()
    local mapping = {
        ["S-300PS 40B6M tr"] = "SA-10 TR",
        ["S-300PS 40B6MD sr"] = "SA-10 SR",
        ["S-300PS 64H6E sr"] = "SA-10 BB",
        ["SNR_75V"] = "SA-2",
        ["Kub STR"] = "SA-6",
        ["Tor 9A331"] = "SA-15",
        ["Buk SR 9S18M1"] = "SA-11 SR",
        ["SA-11 Buk LN 9A310M1"] = "SA-11 TR",
        ["SA-17 Buk M1-2 LN"] = "SA-17",
        ["Roland ADS"] = "Roland",
        ["Patriot str"] = "Patriot",
        ["Hawk tr"] = "Hawk TR",
        ["Hawk sr"] = "Hawk SR"
    }
    return mapping[typeName] or typeName
end

local function setupMenus()
    for _, jammer in ipairs(jammerUnits) do
        if not jammerMenus[jammer] then
            local unit = Unit.getByName(jammer)
            if unit and unit:isExist() then
                local gid = unit:getGroup():getID()
                jammerGroupIDs[jammer] = gid
                local root = missionCommands.addSubMenuForGroup(gid, "电子战干扰")
                jammerMenus[jammer] = true

                -- 修改：更新负载预设，包含干扰值信息
                local loadout = missionCommands.addSubMenuForGroup(gid, "载荷配置", root)
                local presets = {
                    {label = "无干扰吊舱", cap = 0, alq99=0, alq249=0},
                    {label = "1x ALQ-99", cap = 1000, alq99=1, alq249=0},
                    {label = "2x ALQ-99", cap = 2000, alq99=2, alq249=0},
                    {label = "3x ALQ-99", cap = 3000, alq99=3, alq249=0},
                    {label = "1x ALQ-249", cap = 1500, alq99=0, alq249=1},
                    {label = "2x ALQ-249", cap = 3000, alq99=0, alq249=2},
                    {label = "1x ALQ-249 + 1x ALQ-99", cap = 2500, alq99=1, alq249=1},
                    {label = "2x ALQ-249 + 1x ALQ-99", cap = 4000, alq99=1, alq249=2}
                }
                for _, p in ipairs(presets) do
                    missionCommands.addCommandForGroup(gid, p.label, loadout, function()
                        maxEmitterCapacity[jammer] = p.cap
                        emitterCapacity[jammer] = math.min(emitterCapacity[jammer], p.cap)
                        -- 保存负载配置
                        jammerSettings[jammer].currentPreset = {alq99=p.alq99, alq249=p.alq249}
                        local totalJam = (p.alq99 * ALQ99_JAM_VALUE) + (p.alq249 * ALQ249_JAM_VALUE)
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], jammer .. " 载荷设置: " .. p.label .. " (总干扰值: " .. totalJam .. ")", 4)
end
                    end)
                end

                -- Area Defensive
                local dmenu = missionCommands.addSubMenuForGroup(gid, "防御区域干扰", root)
                missionCommands.addCommandForGroup(gid, "开启", dmenu, function()
                    jammerSettings[jammer].defensive = true
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御区域干扰已开启", 4)
end
                end)
                missionCommands.addCommandForGroup(gid, "关闭", dmenu, function()
                    jammerSettings[jammer].defensive = false
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御区域干扰已关闭", 4)
end
                end)

                -- Area Offensive
                local aomenu = missionCommands.addSubMenuForGroup(gid, "攻击区域干扰", root)
                missionCommands.addCommandForGroup(gid, "On", aomenu, function()
                    jammerSettings[jammer].offensive = true
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击区域干扰已开启", 4)
end
                end)
                missionCommands.addCommandForGroup(gid, "Off", aomenu, function()
                    jammerSettings[jammer].offensive = false
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击区域干扰已关闭", 4)
end
                end)

                -- Directional menus (offensive/defensive)
                -- Spot Jamming
                local sjMenu = missionCommands.addSubMenuForGroup(gid, "点目标干扰", root)
                missionCommands.addCommandForGroup(gid, "Off", sjMenu, function()
                    jammerSettings[jammer].spotTarget = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰已关闭", 4)
end
                end)

                -- Target Selection Submenu
                local tsMenu = missionCommands.addSubMenuForGroup(gid, "目标选择", sjMenu)
spotTargetMenus[jammer] = tsMenu

                -- Scan for targets within 80nm
                local jammerUnit = Unit.getByName(jammer)
                if jammerUnit and jammerUnit:isExist() then
                    local jammerPos = jammerUnit:getPoint()
                    local redGroups = coalition.getGroups(coalition.side.RED)
                    for _, group in ipairs(redGroups) do
                        local hasSAM = false
                        local targetUnit = nil
                        for _, unit in ipairs(group:getUnits()) do
                            if unit:hasAttribute("SAM SR") or unit:hasAttribute("SAM TR") or unit:hasAttribute("SAM STR") then
                                hasSAM = true
                                targetUnit = unit
                                break
                            end
                        end
                        if not hasSAM then
                            for _, unit in ipairs(group:getUnits()) do
                                if unit:getCategory() == Object.Category.UNIT and unit:hasAttribute("Ships") then
                                    hasSAM = true
                                    targetUnit = unit
                                    break
                                end
                            end
                        end
                        if hasSAM and targetUnit and targetUnit:isExist() then
                            local tgtPos = targetUnit:getPoint()
                            local dist = get3DDist(jammerPos, tgtPos)
                            if dist <= 148160 then -- 80nm in meters
                                local bearing = getBearing(jammerPos, tgtPos)
                                local distNM = math.floor(dist / 1852 + 0.5)
                                local name = getNatoName(targetUnit)
                                local label = name .. " | " .. bearing .. "° | " .. distNM .. "nm"
                                missionCommands.addCommandForGroup(gid, label, tsMenu, function()
                                    jammerSettings[jammer].spotTarget = group:getName()
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰已开启: " .. label, 4)
end
                                end)
                            end
                        end
                    end
                end

                for _, mode in ipairs({"攻击", "防御"}) do
                    local submenu = missionCommands.addSubMenuForGroup(gid, "定向" .. mode .. "干扰", root)
                    for _, dir in ipairs({"前方", "左侧", "右侧", "后方"}) do
                        missionCommands.addCommandForGroup(gid, "激活 " .. dir, submenu, function()
                            jammerSettings[jammer][mode == "攻击" and "offDir" or "defDir"] = (dir == "前方" and "front" or dir == "左侧" and "left" or dir == "右侧" and "right" or "rear")
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], mode .. "定向干扰已开启: " .. dir, 4)
end
                        end)
                    end
                    missionCommands.addCommandForGroup(gid, "关闭", submenu, function()
                        jammerSettings[jammer][mode == "攻击" and "offDir" or "defDir"] = nil
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "定向" .. mode .. "干扰已关闭", 4)
end
                    end)
                end

if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "电子战干扰菜单已创建: " .. jammer, 4)
end
            end
        end
    end
    return timer.getTime() + menuCheckInterval
end

-- 修改：启动两个循环，导弹循环使用0.5秒间隔
timer.scheduleFunction(jammerLoop, {}, timer.getTime() + 3)
timer.scheduleFunction(missileLoop, {}, timer.getTime() + 1)  -- 导弹循环0.5秒间隔
timer.scheduleFunction(setupMenus, {}, timer.getTime() + 2)

local function refreshSpotTargets()
    for _, jammer in ipairs(jammerUnits) do
        local gid = jammerGroupIDs[jammer]
        local tsMenu = spotTargetMenus[jammer]
        if gid and tsMenu then
            if spotTargetCommands[jammer] then
                for _, cmd in ipairs(spotTargetCommands[jammer]) do
                    if cmd then
                        missionCommands.removeItemForGroup(gid, cmd)
                    end
                end
                spotTargetCommands[jammer] = {}
            else
                spotTargetCommands[jammer] = {}
            end

            local jammerUnit = Unit.getByName(jammer)
            if jammerUnit and jammerUnit:isExist() then
                local jammerPos = jammerUnit:getPoint()
                local redGroups = coalition.getGroups(coalition.side.RED)

                for _, group in ipairs(redGroups) do
                    local hasSAM = false
                    local targetUnit = nil
                    for _, unit in ipairs(group:getUnits()) do
                        if unit:hasAttribute("SAM SR") or unit:hasAttribute("SAM TR") or unit:hasAttribute("SAM STR") then
                            hasSAM = true
                            targetUnit = unit
                            break
                        end
                    end
                    if not hasSAM then
                        for _, unit in ipairs(group:getUnits()) do
                            if unit:getCategory() == Object.Category.UNIT and unit:hasAttribute("Ships") then
                                hasSAM = true
                                targetUnit = unit
                                break
                            end
                        end
                    end

                    if hasSAM and targetUnit and targetUnit:isExist() then
                        local tgtPos = targetUnit:getPoint()
                        local dist = get3DDist(jammerPos, tgtPos)
                        if dist <= 148160 then
                            local bearing = getBearing(jammerPos, tgtPos)
                            local distNM = math.floor(dist / 1852 + 0.5)
                            local name = getNatoName(targetUnit)
                            local label = name .. " | " .. bearing .. "° | " .. distNM .. "nm"
                            local cmd = missionCommands.addCommandForGroup(gid, label, tsMenu, function()
                                jammerSettings[jammer].spotTarget = group:getName()
                                trigger.action.outTextForGroup(gid, "点目标干扰已开启: " .. label, 4)
                            end)
                            table.insert(spotTargetCommands[jammer], cmd)
                        end
                    end
                end
            end
        end
    end
    return timer.getTime() + 10
end
timer.scheduleFunction(refreshSpotTargets, {}, timer.getTime() + 10)