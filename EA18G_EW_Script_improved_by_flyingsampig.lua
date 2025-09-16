-- === EA-18G EW Script by Timberwolf - Minimal Update ===
-- 基于原始脚本的最小化修改版本
-- 只修改导弹诱爆逻辑，其他功能保持不变
-- 修改：使用新的干扰值计算和1秒循环频率
-- Requires MIST to be loaded before this script
trigger.action.outText("EA-18G 电子战脚本已加载 (Flyingsampig版)", 10)

-- === SAFE wrapper: prevent silent loop crashes ===
local function SAFE(name, fn)
    return function(...)
        local args = {...}
        local ok, ret = xpcall(function() return fn(unpack(args)) end, function(err)
            env.error(string.format("[EW:%s] %s\n%s", name, tostring(err), debug.traceback()), false)
            return nil  -- 不再续约
        end)
        return ret
    end
end

-- === Radar helpers: define BEFORE any use (global, not local) ===
function isRadarishUnit(u)
    if not u or not u.isExist or not u:isExist() then return false end
    return u:hasAttribute("SAM SR") or u:hasAttribute("SAM TR")
        or u:hasAttribute("SAM STR") or u:hasAttribute("EWR")
end

function pickRadarLeadUnit(g)
    if not g or not g.isExist or not g:isExist() then return nil end
    local units = g:getUnits()
    if not units then return nil end
    for _, u in ipairs(units) do
        if isRadarishUnit(u) then return u end
    end
    local u1 = units[1]
    return (u1 and u1.isExist and u1:isExist()) and u1 or nil
end

function getNatoName(unit)
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

-- ESM 标记相关常量
local ESM_MARK_COAL = coalition.side.BLUE
local ESM_MARK_READONLY = true
local g_esmMarkUid = 910000

function addCoalMark(text, pos)
    g_esmMarkUid = g_esmMarkUid + 1
    trigger.action.markToCoalition(g_esmMarkUid, text, pos, ESM_MARK_COAL, ESM_MARK_READONLY, "ELINT")
    return g_esmMarkUid
end

local jammerUnits = {
  "Growler"
}

-- 新增：干扰值参数
local ALQ99_JAM_VALUE = 3   -- ALQ-99 单吊舱干扰值
local ALQ249_JAM_VALUE = 4  -- ALQ-249 单吊舱干扰值
local MISSILE_THRESHOLD = 100  -- 导弹自爆阈值
local REFERENCE_DISTANCE = 9260  -- 参考距离：5海里 = 9260米

-- Debug 模式开关
local DEBUG_MODE = true  -- 设为 true 启用详细调试信息

-- === 载荷模拟系统配置 ===
local LOADOUT_SIM = {
    LBI = {
        names = {"AIM-9L"},  -- 只有AIM-9L可以模拟长基线定位吊舱
        required = 2,
        description = "长基线干涉定位吊舱"
    },
    ALQ99 = {
        names = {"Mk-83"},  -- 只有Mk-83可以模拟ALQ-99
        perPod = 1,
        description = "ALQ-99战术干扰吊舱"
    },
    ALQ249 = {
        names = {"Mk-84"},  -- 只有Mk-84可以模拟ALQ-249
        perPod = 1,
        description = "ALQ-249下一代干扰吊舱"
    }
}

-- 载荷模拟状态跟踪
local loadoutState = {}  -- [unitName] = {hasLBI=false, alq99Count=0, alq249Count=0, lastCheck=0}
local esmEnabled = {}    -- [unitName] = boolean，ESM功能是否启用

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

-- === ESM / ELINT（基于 RWR） ===
local ESM_TICK            = 1.0          -- 判定周期（秒）
local ESM_DWELL_SEC       = 30           -- 连续探测阈值（秒）
local ESM_DROPOUT_SEC     = 2.0          -- 允许短丢失（秒）
local ESM_MAX_RANGE_M     = 80 * 1852    -- 80nm
local ESM_REQUIRE_LOS     = true         -- 是否要求地形LOS
-- ESM 标记常量已移动到文件开头

-- === 分层次定位精度配置 ===
local ESM_TIERS = {
    {t = 1,  r = 3000, color = {1, 0.4, 0, 0.95}, fill = {1, 0.4, 0, 0.10}, msg = "ELINT: 初始粗定位 (3 km)"},
    {t = 5,  r = 1000, color = {1, 0.8, 0, 0.95}, fill = {1, 0.8, 0, 0.10}, msg = "ELINT: 提升精度 (1 km)"},
    {t = 10, r = 500,  color = {0.2, 1, 0.2, 0.95}, fill = {0.2, 1, 0.2, 0.10}, msg = "ELINT: 高精度定位 (500 m)"}
    -- 30秒为最终精确点，不画圈，直接打点标记
}
local ESM_FINAL_T = 30
local ESM_LINE_TYPE = 1      -- 圈线型
local g_ringUid = 920000     -- 圈标记ID递增器

-- 圈标记管理辅助函数
local function groundSnap(p)
    local gy = land.getHeight({x = p.x, z = p.z})
    return {x = p.x, y = gy + 2.0, z = p.z}
end

-- ESM定位误差模拟算法 - 圆内均匀分布（DCS兼容版本）
local function calculateESMOffset(realPos, currentStage, targetUnitName, jammerName, radius)
    -- 为每个目标-干扰机对生成一致的伪随机数
    local seedStr = targetUnitName .. "_" .. jammerName .. "_" .. tostring(currentStage)
    local seed = 0
    for i = 1, #seedStr do
        seed = seed + string.byte(seedStr, i)
    end

    -- 简单的线性同余发生器（LCG）实现伪随机数
    local function pseudoRandom(s)
        s = (s * 1103515245 + 12345) % (2^31)
        return s / (2^31), s
    end

    -- 生成第一个伪随机数用于X坐标
    local rand1, newSeed1 = pseudoRandom(seed)
    -- 生成第二个伪随机数用于X的符号
    local rand2, newSeed2 = pseudoRandom(newSeed1)
    -- 生成第三个伪随机数用于Y坐标
    local rand3, newSeed3 = pseudoRandom(newSeed2)
    -- 生成第四个伪随机数用于Y的符号
    local rand4, newSeed4 = pseudoRandom(newSeed3)

    -- 按用户建议的算法：圆内均匀分布
    -- 1. 在0到r范围内取x坐标偏移（正负随机）
    local offsetX = (rand1 * radius) * (rand2 > 0.5 and 1 or -1)

    -- 2. 根据x计算y的最大偏移：sqrt(r² - x²)
    local maxY = math.sqrt(radius * radius - offsetX * offsetX)

    -- 3. 在正负范围内取y的实际偏移
    local offsetZ = (rand3 * maxY) * (rand4 > 0.5 and 1 or -1)

    return {
        x = realPos.x + offsetX,
        y = realPos.y,
        z = realPos.z + offsetZ
    }
end

local function addESMRing(realCenter, radius, color, fill, message, stage, targetName, jammerName)
    g_ringUid = g_ringUid + 1

    -- 计算带误差的圆心位置（目标在圆内随机位置）
    local offsetCenter = calculateESMOffset(realCenter, stage, targetName, jammerName, radius)
    local c = groundSnap(offsetCenter)

    trigger.action.circleToAll(ESM_MARK_COAL, g_ringUid, c, radius, color, fill, ESM_LINE_TYPE, ESM_MARK_READONLY, message)
    return g_ringUid
end

local function removeMarkId(id)
    if id then
        pcall(trigger.action.removeMark, id)
    end
end

local esmState = {}       -- [jammerName] = { targetUnitName=..., dwell=0, lastSeen=0, markId=nil, ringId=nil, ringStage=0, lastProgressReport=0 }
local esmMenus = {}       -- [jammerName] = {root=..., listRoot=...}
-- g_esmMarkUid 已移动到文件开头

-- ESM 进度报告间隔
local ESM_PROGRESS_INTERVAL = 5  -- 每5秒报告一次进度

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

-- === 载荷模拟系统函数 ===

-- 统计指定武器名称的数量
local function countAmmoByNames(unit, weaponNames)
    local count = 0
    local ammo = unit:getAmmo()
    if not ammo then return 0 end

    for _, ammoData in ipairs(ammo) do
        if ammoData.desc and ammoData.desc.displayName then
            local displayName = ammoData.desc.displayName
            for _, weaponName in ipairs(weaponNames) do
                if string.find(displayName, weaponName, 1, true) then
                    count = count + (ammoData.count or 1)
                    break
                end
            end
        end
    end
    return count
end

-- 检查单位的载荷状态
local function checkLoadoutState(unitName)
    local unit = Unit.getByName(unitName)
    if not (unit and unit:isExist()) then
        return {hasLBI = false, alq99Count = 0, alq249Count = 0, valid = false}
    end

    -- 统计各类武器数量
    local aim9Count = countAmmoByNames(unit, LOADOUT_SIM.LBI.names)
    local mk83Count = countAmmoByNames(unit, LOADOUT_SIM.ALQ99.names)
    local mk84Count = countAmmoByNames(unit, LOADOUT_SIM.ALQ249.names)

    -- 计算可用的吊舱数量
    local state = {
        hasLBI = aim9Count >= LOADOUT_SIM.LBI.required,
        alq99Count = math.floor(mk83Count / LOADOUT_SIM.ALQ99.perPod),
        alq249Count = math.floor(mk84Count / LOADOUT_SIM.ALQ249.perPod),
        valid = true,
        rawCounts = {aim9 = aim9Count, mk83 = mk83Count, mk84 = mk84Count}
    }

    return state
end

-- 尝试启用长基线干涉定位
local function tryEnableLBI(jammerName)
    local state = checkLoadoutState(jammerName)
    if not state.valid then
        trigger.action.outTextForGroup(jammerGroupIDs[jammerName], "无法检查载荷状态", 3)
        return false
    end

    if state.hasLBI then
        esmEnabled[jammerName] = true
        trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
            string.format("长基线干涉定位已启用 (检测到%d枚AIM-9)", state.rawCounts.aim9), 5)
        return true
    else
        trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
            string.format("需要2枚AIM-9L才能启用长基线定位 (当前:%d枚)", state.rawCounts.aim9), 5)
        return false
    end
end

-- 检查干扰吊舱预设是否可用
local function checkJammerPreset(jammerName, requiredALQ99, requiredALQ249)
    local state = checkLoadoutState(jammerName)
    if not state.valid then return false, "无法检查载荷状态" end

    local missingItems = {}

    if state.alq99Count < requiredALQ99 then
        local needed = requiredALQ99 - state.alq99Count
        table.insert(missingItems, string.format("需要%d枚Mk-83 (ALQ-99模拟)", needed))
    end

    if state.alq249Count < requiredALQ249 then
        local needed = requiredALQ249 - state.alq249Count
        table.insert(missingItems, string.format("需要%d枚Mk-84 (ALQ-249模拟)", needed))
    end

    if #missingItems > 0 then
        return false, table.concat(missingItems, ", ")
    end

    return true, "载荷验证通过"
end

-- 载荷状态监控循环
local function loadoutMonitorLoop()
    for _, jammerName in ipairs(jammerUnits) do
        if jammerGroupIDs[jammerName] then
            local currentState = checkLoadoutState(jammerName)
            local previousState = loadoutState[jammerName] or {}

            if currentState.valid then
                -- 检查LBI状态变化
                if esmEnabled[jammerName] and not currentState.hasLBI then
                    esmEnabled[jammerName] = false
                    trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
                        "警告: AIM-9L数量不足，长基线定位已禁用", 5)
                end

                -- 检查干扰吊舱状态变化
                local currentPreset = jammerSettings[jammerName] and jammerSettings[jammerName].currentPreset
                if currentPreset then
                    local needALQ99 = currentPreset.alq99 or 0
                    local needALQ249 = currentPreset.alq249 or 0

                    if currentState.alq99Count < needALQ99 or currentState.alq249Count < needALQ249 then
                        -- 载荷不足，禁用干扰功能
                        jammerSettings[jammerName].offensive = false
                        jammerSettings[jammerName].defensive = false
                        jammerSettings[jammerName].offDir = nil
                        jammerSettings[jammerName].defDir = nil
                        maxEmitterCapacity[jammerName] = 0
                        emitterCapacity[jammerName] = 0

                        trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
                            "警告: 干扰吊舱载荷不足，干扰功能已禁用", 5)
                    end
                end

                loadoutState[jammerName] = currentState
            end
        end
    end
    return timer.getTime() + 5  -- 每5秒检查一次
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
            local targetUnit = Unit.getByName(jammerSettings[jammer].spotTarget)
            if unit and unit:isExist() and targetUnit and targetUnit:isExist() then
                local jammerPos = unit:getPoint()
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
                        local targetGroup = targetUnit:getGroup()
                        if targetGroup then
                            local ctrl = targetGroup:getController()
                            ctrl:setOption(AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD)
                            local targetName = getNatoName(targetUnit)
                            suppressedSAMs[jammerSettings[jammer].spotTarget] = {
                                sam = targetUnit,
                                lastSuppressed = timer.getTime(),
                                spot = true
                            }
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰成功: " .. targetName, 3)
end
                        end
                    else
                        local targetName = getNatoName(targetUnit)
if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰尝试失败: " .. targetName, 3)
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
                    if success then
                        if DEBUG_MODE then
                            local bearing = getClockBearing(unit, mpos)
                            local debugMsg = string.format("导弹#%s判定%s | 距离:%.2f海里 | 速度:%dkm/h | 干扰值:%.1f | 成功率:%.2f%% | ",
                                tostring(id), modeText, distNM, speedKmh, jamValue, probabilityPercent)
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], debugMsg .. "诱爆成功 (" .. bearing .. ")", 4)
                        end
                        -- 非调试模式下静默处理 - 飞行员无法知道干扰是否成功
                        Object.destroy(m)
                        trackedMissiles[id] = nil -- 只移除这一枚导弹
                    else
                        if DEBUG_MODE then
                            local debugMsg = string.format("导弹#%s判定%s | 距离:%.2f海里 | 速度:%dkm/h | 干扰值:%.1f | 成功率:%.2f%% | ",
                                tostring(id), modeText, distNM, speedKmh, jamValue, probabilityPercent)
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], debugMsg .. "诱爆失败", 3)
                        end
                        -- 非调试模式下静默处理 - 飞行员无法知道干扰是否成功
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

-- ESM 辅助函数：检查单个雷达单位是否开机
local function checkRadarUnitActive(unit)
    local methods = {
        unit_exists = false,
        unit_radar_on = false,
        unit_life = false,
        has_tracked_obj = false
    }

    local detectionMethods = {}
    local isActive = false
    local trackedObj = nil

    -- 方法1: 检查单位是否存在
    if unit and unit:isExist() then
        methods.unit_exists = true
    else
        return false, {}, methods, nil  -- 单位不存在直接返回
    end

    -- 方法2: 检查生命值
    local life = unit:getLife()
    local life0 = unit:getLife0()
    if life and life0 and life > 0 and life0 > 0 and (life / life0) > 0.1 then -- 生命值超过10%
        methods.unit_life = true
    else
        return false, {}, methods, nil  -- 单位已毁坏
    end

    -- 方法3: 使用正确的 Unit.getRadar() 方法检查雷达开机状态
    if unit.getRadar then
        local radarOn, trackedObject = unit:getRadar()
        if radarOn then
            methods.unit_radar_on = true
            isActive = true
            table.insert(detectionMethods, "雷达开机")

            if trackedObject then
                methods.has_tracked_obj = true
                table.insert(detectionMethods, "正在跟踪")
                trackedObj = trackedObject
            end
        end
    end

    return isActive, detectionMethods, methods, trackedObj
end

-- ESM 循环函数 - 要求雷达真正开机且无地形阻挡持续30秒
local function esmLoop()
    local now = timer.getTime()

    -- 运行计数器调试
    if not _ESM_LOOP_COUNT then
        _ESM_LOOP_COUNT = 0
    end
    _ESM_LOOP_COUNT = _ESM_LOOP_COUNT + 1

    -- 全局 ESM 循环调试信息（每30秒一次）
    if not _ESM_LOOP_DEBUG_LAST then
        _ESM_LOOP_DEBUG_LAST = 0
    end
    if (now - _ESM_LOOP_DEBUG_LAST) >= 10 then  -- 改为10秒间隔
        local activeTargets = 0
        for _, jammer in ipairs(jammerUnits) do
            if esmState[jammer] and esmState[jammer].targetUnitName then
                activeTargets = activeTargets + 1
            end
        end
        -- 调试信息（仅 DEBUG 模式）
        if DEBUG_MODE then
            env.info(string.format("[ESM循环调试] 计数=%d, 时间=%.1fs, 活跃目标=%d", _ESM_LOOP_COUNT, now, activeTargets))

            -- 如果有活跃目标，同时向相关群组发送消息
            if activeTargets > 0 then
                for _, jammer in ipairs(jammerUnits) do
                    if esmState[jammer] and esmState[jammer].targetUnitName and jammerGroupIDs[jammer] then
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                            string.format("ESM循环状态检查\n计数: %d | 时间: %.1fs\n目标: %s",
                                _ESM_LOOP_COUNT, now, esmState[jammer].targetUnitName), 3)
                        break  -- 只发送一次
                    end
                end
            end
        end
        _ESM_LOOP_DEBUG_LAST = now
    end

    for _, jammer in ipairs(jammerUnits) do
        local st = esmState[jammer]
        local me = Unit.getByName(jammer)

        -- 调试：直接检查状态（仅 DEBUG 模式）
        if DEBUG_MODE and _ESM_LOOP_COUNT <= 5 and jammerGroupIDs[jammer] then
            local stStatus = st and "存在" or "nil"
            local targetStatus = (st and st.targetUnitName) and st.targetUnitName or "无目标"
            local meStatus = (me and me:isExist()) and "存在" or "不存在"
            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                string.format("ESM状态[%d]: 干扰器=%s, st=%s, 目标=%s, me=%s",
                    _ESM_LOOP_COUNT, jammer, stStatus, targetStatus, meStatus), 3)
        end

        -- 调试：打印 ESM 循环状态（仅 DEBUG 模式）
        if DEBUG_MODE and st and st.targetUnitName then
            local debugPrefix = string.format("[ESM循环] %s -> %s: ", jammer, st.targetUnitName)
            if jammerGroupIDs[jammer] then
                -- 每10秒输出一次调试信息以避免刷屏
                local debugInterval = 10
                if not st.lastDebugReport then
                    st.lastDebugReport = 0
                end
                if (now - st.lastDebugReport) >= debugInterval then
                    trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                        debugPrefix .. "循环运行中...", 2)
                    st.lastDebugReport = now
                end
            end
        end
        if st and st.targetUnitName and me and me:isExist() then
            -- 载荷模拟检查：在定位过程中检查载荷状态
            local currentState = checkLoadoutState(jammer)
            if not (currentState.valid and currentState.hasLBI) then
                if jammerGroupIDs[jammer] then
                    if DEBUG_MODE then
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                            "ESM定位中断：AIM-9L数量不足 (当前:" .. (currentState.rawCounts and currentState.rawCounts.aim9 or 0) .. "枚)", 5)
                    else
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "定位中断：载荷不足", 4)
                    end
                end
                -- 清除ESM状态，但保留已完成的精确定位标记
                -- 清理圈标记（进行中的定位）
                if st.ringId then
                    removeMarkId(st.ringId)
                    st.ringId = nil
                end
                -- 只有当定位未完成时才移除精确点标记（防止误删已完成的定位）
                if st.markId and st.dwell < ESM_FINAL_T then
                    trigger.action.removeMark(st.markId)
                    st.markId = nil
                end
                st.targetUnitName = nil
                st.dwell = 0
                st.lastSeen = 0
                st.lastProgressReport = 0
                st.ringStage = 0
                -- 注意：已完成的精确定位标记（markId且dwell >= ESM_FINAL_T）会被保留
                -- 不自动禁用ESM，允许用户选择新目标重新开始
            else
                local targetUnit = Unit.getByName(st.targetUnitName)
                if not (targetUnit and targetUnit:isExist()) then
                    if jammerGroupIDs[jammer] then
                        if DEBUG_MODE then
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], "ESM：目标单位丢失，停止监听 "..st.targetUnitName, 4)
                        else
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], "目标雷达接触中断，定位中止", 4)
                        end
                    end
                    st.targetUnitName = nil
                    st.dwell = 0
                    st.lastSeen = 0
            else
                -- 使用正确的 Unit.getRadar() 方法检查单个雷达单位的开机状态
                local radarActive, detectionMethods, unitMethods, trackedObj = checkRadarUnitActive(targetUnit)

                -- 计算到目标雷达单位的距离
                local meP = me:getPoint()
                local rp = targetUnit:getPoint()
                local dx, dz = rp.x - meP.x, rp.z - meP.z
                local dist = math.sqrt(dx*dx + dz*dz)
                local distNM = math.floor(dist / 1852 + 0.5)
                local inRange = dist <= ESM_MAX_RANGE_M
                local losOK = land.isVisible(meP, rp)

                local detectionStr = #detectionMethods > 0 and ("(" .. table.concat(detectionMethods, ",") .. ")") or "(无探测)"
                local losStr = losOK and "LOS:通" or "LOS:阻"
                local statusStr = radarActive and "开机" or "关机"
                local trackStr = trackedObj and ("跟踪:" .. tostring(trackedObj)) or ""

                -- 初始化进度报告时间
                if not st.lastProgressReport then
                    st.lastProgressReport = 0
                end

                -- 调试：详细的三门槛诊断（仅 DEBUG 模式）
                if DEBUG_MODE then
                    if not st.lastGateReport then
                        st.lastGateReport = 0
                    end
                    if (now - st.lastGateReport) >= 30 and jammerGroupIDs[jammer] then
                        local unitName = getNatoName(targetUnit)
                        local gateResult = ""
                        gateResult = gateResult .. string.format("门槛检查 [%s]\n", unitName)
                        gateResult = gateResult .. string.format("1. 距离: %.1fnm/%dnm %s\n", distNM, math.floor(ESM_MAX_RANGE_M/1852), inRange and "通过" or "失败")
                        gateResult = gateResult .. string.format("2. 地形: %s %s\n", losStr, losOK and "通过" or "失败")
                        gateResult = gateResult .. string.format("3. 雷达: %s %s\n", statusStr, radarActive and "通过" or "失败")
                        if radarActive then
                            gateResult = gateResult .. string.format("   检测方法: %s\n", detectionStr)
                            if trackedObj then
                                gateResult = gateResult .. string.format("   跟踪目标: %s\n", trackStr)
                            end
                        end
                        gateResult = gateResult .. string.format("综合结果: %s", (inRange and losOK and radarActive) and "累积中" or "等待中")

                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], gateResult, 8)
                        st.lastGateReport = now
                    end
                end

                if inRange and losOK and radarActive then
                    -- 雷达开机且满足条件，累积时间
                    local oldDwell = st.dwell
                    st.dwell = math.min(ESM_DWELL_SEC, st.dwell + ESM_TICK)
                    st.lastSeen = now

                    -- === 分层圈标记逻辑 ===
                    st.ringStage = st.ringStage or 0
                    local stageBefore = st.ringStage

                    -- 计算应该处于哪个阶段（1/5/10秒）
                    local targetStage = 0
                    for i, tier in ipairs(ESM_TIERS) do
                        if st.dwell >= tier.t then
                            targetStage = i
                        end
                    end

                    -- 阶段变化：删旧圈、画新圈
                    if targetStage ~= stageBefore then
                        -- 移除旧圈
                        if st.ringId then
                            removeMarkId(st.ringId)
                            st.ringId = nil
                        end

                        -- 画新圈（若目标阶段>0）
                        if targetStage > 0 then
                            local tier = ESM_TIERS[targetStage]
                            local unitName = getNatoName(targetUnit)
                            st.ringId = addESMRing(rp, tier.r, tier.color, tier.fill, tier.msg, targetStage, st.targetUnitName, jammer)
                            if jammerGroupIDs[jammer] then
                                trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                    string.format("%s：已绘制半径 %.0f m 定位圈（累计 %.1fs）",
                                        unitName, tier.r, st.dwell), 5)
                            end
                        end

                        st.ringStage = targetStage
                    end

                    -- 每5秒或首次开始计时时报告进度
                    local shouldReport = false
                    if st.dwell <= ESM_TICK then
                        -- 刚开始计时
                        shouldReport = true
                        st.lastProgressReport = now
                    elseif (now - st.lastProgressReport) >= ESM_PROGRESS_INTERVAL then
                        -- 达到报告间隔
                        shouldReport = true
                        st.lastProgressReport = now
                    end

                    if jammerGroupIDs[jammer] and shouldReport then
                        local progressPercent = math.floor((st.dwell / ESM_DWELL_SEC) * 100)
                        local unitName = getNatoName(targetUnit)

                        if DEBUG_MODE then
                            -- 格式化坐标信息
                            local coordStr = string.format("%.0fm,%.0fm", rp.x, rp.z)
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                string.format("ESM进度：%s\n位置：%s (%dnm %s)\n计时：%.1f/%.0fs (%d%%)\n状态：%s %s %s",
                                    unitName, coordStr, distNM, losStr, st.dwell, ESM_DWELL_SEC, progressPercent, statusStr, detectionStr, trackStr), 8)
                        else
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                string.format("已定位 %.0f/30秒", st.dwell), 2)
                        end
                    end
                else
                    -- 雷达关机或不满足条件，立即重置计时
                    if st.dwell > 0 and jammerGroupIDs[jammer] then
                        local reason = ""
                        if not inRange then reason = reason .. "超出范围 " end
                        if not losOK then reason = reason .. "地形阻挡 " end
                        if not radarActive then reason = reason .. "雷达关机 " end

                        local unitName = getNatoName(targetUnit)
                        if DEBUG_MODE then
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                string.format("ESM中断：%s\n%dnm | %s | %s %s\n计时重置：%.1fs → 0s\n原因：%s",
                                    unitName, distNM, losStr, statusStr, detectionStr, st.dwell, reason), 6)
                        else
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], "目标雷达接触中断，定位中止", 4)
                        end
                    end
                    -- 清理圈标记
                    if st.ringId then
                        removeMarkId(st.ringId)
                        st.ringId = nil
                    end
                    st.dwell = 0
                    st.lastSeen = 0
                    st.lastProgressReport = 0
                    st.ringStage = 0
                end

                -- 检查是否达到最终精确定位条件
                if st.dwell >= ESM_FINAL_T then
                    -- 清理圈标记
                    if st.ringId then
                        removeMarkId(st.ringId)
                        st.ringId = nil
                    end
                    st.ringStage = 0

                    -- 创建精确点标记
                    local rp = targetUnit:getPoint()
                    local nato = getNatoName(targetUnit)
                    local txt = string.format("ELINT FIX: %s (%s)\n持续开机≥%ds\n(精确坐标)", nato, targetUnit:getName(), ESM_FINAL_T)

                    local ok, err = pcall(function()
                        st.markId = addCoalMark(txt, groundSnap(rp))
                    end)

                    if DEBUG_MODE then
                        env.info(string.format("[ESM成功调试] 达到精确定位条件: dwell=%.1fs >= %ds", st.dwell, ESM_FINAL_T))
                        if ok then
                            env.info(string.format("[ESM成功调试] 精确点标记已创建: ID=%d", st.markId))
                        else
                            env.info(string.format("[ESM成功调试] 精确点标记创建失败: %s", tostring(err)))
                        end
                    end

                    -- 格式化详细的成功报告
                    local coordStr = string.format("%.0fm,%.0fm", rp.x, rp.z)

                    -- 尝试获取MGRS坐标（如果coord库可用）
                    local mgrsStr = "N/A"
                    if coord and coord.LLtoMGRS and coord.LOtoLL then
                        local success, mgrs = pcall(function()
                            return coord.LLtoMGRS(coord.LOtoLL(rp))
                        end)
                        if success and mgrs and mgrs.MGRSDigits then
                            mgrsStr = mgrs.MGRSDigits
                        end
                    end

                    if jammerGroupIDs[jammer] then
                        if DEBUG_MODE then
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                string.format("ESM精确定位完成！\n目标：%s (%s)\n坐标：%s\nMGRS：%s\n雷达：%s\n用时：%.1fs\n精确点ID：%d\n已在F10地图标注",
                                    targetUnit:getName(), nato, coordStr, mgrsStr, nato, st.dwell, st.markId or 0), 10)
                        else
                            -- 简化输出：只显示目标名称、坐标和性质
                            local lat, lon = coord.LOtoLL(rp)
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                string.format("精确定位完成：%s (%s)\n经纬度：%.6f, %.6f\nMGRS：%s",
                                    nato, targetUnit:getName(), lat, lon, mgrsStr), 6)
                        end

                        if ok then
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], "已完成精确定位并在F10标注: " .. nato, 5)
                        else
                            trigger.action.outTextForGroup(jammerGroupIDs[jammer], "定位达成但打点失败: " .. tostring(err), 5)
                        end
                    end

                    -- 定位完成后自动退出，重置所有状态
                    st.targetUnitName = nil
                    st.dwell = 0
                    st.lastSeen = 0
                    st.lastProgressReport = 0
                    st.ringStage = 0
                    -- 注意：保留st.markId，这是已完成的精确定位标记
                end
            end
        end
        end
    end
    return now + ESM_TICK
end

local function getBearing(from, to)
    local dx = to.x - from.x
    local dz = to.z - from.z
    local bearing = math.deg(math.atan2(dz, dx))
    if bearing < 0 then bearing = bearing + 360 end
    return math.floor(bearing + 0.5)
end

-- 已移动到文件开头的全局函数

-- addCoalMark 已移动到文件开头

-- 正确的雷达开机状态检测（使用 Unit.getRadar()）

-- 检查雷达组的开机状态（使用正确的 Unit.getRadar() 方法）
local function checkRadarGroupActive(group, debugGroupName)
    if not group or not group:isExist() then
        return false, {}, nil, {}, "组无效"
    end

    local activeRadars = {}
    local detectionMethods = {}
    local bestRadarUnit = nil
    local groupActive = false
    local debugInfo = ""

    debugInfo = debugInfo .. string.format("\n  检查组 %s:\n", debugGroupName or group:getName())

    local units = group:getUnits()
    debugInfo = debugInfo .. string.format("    组内单位数: %d\n", #units)

    for i, unit in ipairs(units) do
        if unit and unit:isExist() then
            local unitType = unit:getTypeName()
            local isRadar = isRadarishUnit(unit)
            debugInfo = debugInfo .. string.format("    单位%d: %s | 是雷达:%s", i, unitType, isRadar and "是" or "否")

            if isRadar then
                -- 使用正确的 Unit.getRadar() 方法检测雷达开机状态
                local unitActive, unitDetections, allMethods, trackedObj = checkRadarUnitActive(unit)

                -- 显示检测方法的结果
                local methodStr = string.format("存在:%s,生命:%s,雷达:%s,跟踪:%s",
                    allMethods.unit_exists and "√" or "×",
                    allMethods.unit_life and "√" or "×",
                    allMethods.unit_radar_on and "√" or "×",
                    allMethods.has_tracked_obj and "√" or "×"
                )

                local detectionStr = #unitDetections > 0 and ("(" .. table.concat(unitDetections, ",") .. ")") or "(无探测)"
                local trackStr = trackedObj and ("跟踪:" .. tostring(trackedObj)) or ""

                debugInfo = debugInfo .. string.format(" | 开机:%s %s %s\n    检测: %s\n",
                    unitActive and "是" or "否", detectionStr, trackStr, methodStr)

                if unitActive then
                    groupActive = true
                    table.insert(activeRadars, unitType)
                    if not bestRadarUnit then bestRadarUnit = unit end
                    for _, method in ipairs(unitDetections) do
                        if not detectionMethods[method] then
                            detectionMethods[method] = true
                            table.insert(detectionMethods, method)
                        end
                    end
                end
            else
                debugInfo = debugInfo .. "\n"
            end
        else
            debugInfo = debugInfo .. string.format("    单位%d: 不存在或已销毁\n", i)
        end
    end

    debugInfo = debugInfo .. string.format("  结果: 组状态=%s, 活跃雷达=%d\n", groupActive and "开机" or "关机", #activeRadars)

    return groupActive, activeRadars, bestRadarUnit, detectionMethods, debugInfo
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
                        -- 载荷模拟：检查是否有足够的"钥匙"武器
                        local canApply, message = checkJammerPreset(jammer, p.alq99, p.alq249)

                        if canApply then
                            maxEmitterCapacity[jammer] = p.cap
                            emitterCapacity[jammer] = math.min(emitterCapacity[jammer], p.cap)
                            -- 保存负载配置
                            jammerSettings[jammer].currentPreset = {alq99=p.alq99, alq249=p.alq249}
                            local totalJam = (p.alq99 * ALQ99_JAM_VALUE) + (p.alq249 * ALQ249_JAM_VALUE)
                            if jammerGroupIDs[jammer] then
                                trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                    jammer .. " 载荷设置: " .. p.label .. " (总干扰值: " .. totalJam .. ")", 4)
                            end
                        else
                            if jammerGroupIDs[jammer] then
                                trigger.action.outTextForGroup(jammerGroupIDs[jammer],
                                    "载荷配置失败: " .. message, 6)
                            end
                        end
                    end)
                end

                -- 载荷模拟菜单
                local loadoutSimMenu = missionCommands.addSubMenuForGroup(gid, "载荷模拟", root)

                -- 长基线干涉定位控制
                missionCommands.addCommandForGroup(gid, "启用长基线定位", loadoutSimMenu, function()
                    tryEnableLBI(jammer)
                end)

                missionCommands.addCommandForGroup(gid, "禁用长基线定位", loadoutSimMenu, function()
                    esmEnabled[jammer] = false
                    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "长基线干涉定位已禁用", 3)
                end)

                -- 载荷状态查询
                missionCommands.addCommandForGroup(gid, "检查载荷状态", loadoutSimMenu, function()
                    local state = checkLoadoutState(jammer)
                    if state.valid then
                        local statusMsg = string.format(
                            "载荷状态报告:\n" ..
                            "AIM-9L: %d枚 (长基线: %s)\n" ..
                            "Mk-83: %d枚 (ALQ-99: %d个可用)\n" ..
                            "Mk-84: %d枚 (ALQ-249: %d个可用)",
                            state.rawCounts.aim9, state.hasLBI and "可用" or "不可用",
                            state.rawCounts.mk83, state.alq99Count,
                            state.rawCounts.mk84, state.alq249Count
                        )
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], statusMsg, 8)
                    else
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "无法获取载荷状态", 3)
                    end
                end)

                -- Area Defensive
                local dmenu = missionCommands.addSubMenuForGroup(gid, "防御区域干扰", root)
                missionCommands.addCommandForGroup(gid, "开启", dmenu, function()
                    jammerSettings[jammer].defensive = true
if jammerGroupIDs[jammer] then
    if DEBUG_MODE then
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御区域干扰已开启", 4)
    else
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御干扰：开启", 2)
    end
end
                end)
                missionCommands.addCommandForGroup(gid, "关闭", dmenu, function()
                    jammerSettings[jammer].defensive = false
if jammerGroupIDs[jammer] then
    if DEBUG_MODE then
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御区域干扰已关闭", 4)
    else
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "防御干扰：关闭", 2)
    end
end
                end)

                -- Area Offensive
                local aomenu = missionCommands.addSubMenuForGroup(gid, "攻击区域干扰", root)
                missionCommands.addCommandForGroup(gid, "On", aomenu, function()
                    jammerSettings[jammer].offensive = true
if jammerGroupIDs[jammer] then
    if DEBUG_MODE then
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击区域干扰已开启", 4)
    else
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击干扰：开启", 2)
    end
end
                end)
                missionCommands.addCommandForGroup(gid, "Off", aomenu, function()
                    jammerSettings[jammer].offensive = false
if jammerGroupIDs[jammer] then
    if DEBUG_MODE then
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击区域干扰已关闭", 4)
    else
        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "攻击干扰：关闭", 2)
    end
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
                local tsMenu = missionCommands.addSubMenuForGroup(gid, "目标选择（≤80nm）", sjMenu)
                spotTargetMenus[jammer] = tsMenu

                -- 初始化目标选择项数组
                spotTargetCommands[jammer] = {}

                -- 创建刷新函数
                local function refreshSpotTargetList()
                    -- 移除所有现有的目标选择项
                    if spotTargetCommands[jammer] then
                        for _, item in ipairs(spotTargetCommands[jammer]) do
                            missionCommands.removeItemForGroup(gid, item)
                        end
                    end
                    spotTargetCommands[jammer] = {}

                    local jammerUnit = Unit.getByName(jammer)
                    if not jammerUnit or not jammerUnit:isExist() then
                        local noUnitItem = missionCommands.addCommandForGroup(gid, "（本机不存在）", tsMenu, function() end)
                        table.insert(spotTargetCommands[jammer], noUnitItem)
                        return
                    end

                    local jammerPos = jammerUnit:getPoint()
                    local count = 0
                    local redGroups = coalition.getGroups(coalition.side.RED)

                    for _, group in ipairs(redGroups or {}) do
                        for _, unit in ipairs(group:getUnits()) do
                            if unit and unit:isExist() and isRadarishUnit(unit) then
                                local tgtPos = unit:getPoint()
                                local dist = get3DDist(jammerPos, tgtPos)
                                if dist <= 148160 then -- 80nm in meters
                                    -- 检查雷达开机状态
                                    local radarActive, detectionMethods, unitMethods, trackedObj = checkRadarUnitActive(unit)

                                    -- 检查地形可见性
                                    local losOK = land.isVisible(jammerPos, tgtPos)

                                    -- 只有开机且无地形阻挡的雷达才加入列表
                                    if radarActive and losOK then
                                        count = count + 1
                                        local bearing = getBearing(jammerPos, tgtPos)
                                        local distNM = math.floor(dist / 1852 + 0.5)
                                        local name = getNatoName(unit)
                                        local internalName = unit:getName()
                                        local detectionStr = #detectionMethods > 0 and ("(" .. table.concat(detectionMethods, ",") .. ")") or ""
                                        local label = string.format("%s | %d° %dnm [开机] %s [%s]", name, bearing, distNM, detectionStr, internalName)

                                        -- 捕获雷达单元名称用于回调
                                        local capturedUnitName = internalName
                                        local capturedLabel = label

                                        local targetItem = missionCommands.addCommandForGroup(gid, label, tsMenu, function()
                                            jammerSettings[jammer].spotTarget = capturedUnitName
                                            if jammerGroupIDs[jammer] then
                                                trigger.action.outTextForGroup(jammerGroupIDs[jammer], "点目标干扰已开启: " .. capturedLabel, 4)
                                            end
                                        end)

                                        table.insert(spotTargetCommands[jammer], targetItem)
                                    end
                                end
                            end
                        end
                    end

                    if count == 0 then
                        local noTargetItem = missionCommands.addCommandForGroup(gid, "（当前无可用目标）", tsMenu, function() end)
                        table.insert(spotTargetCommands[jammer], noTargetItem)
                    end

                    -- 添加手动刷新按钮
                    local refreshButton = missionCommands.addCommandForGroup(gid, "手动刷新目标列表", tsMenu, function()
                        refreshSpotTargetList()
                        trigger.action.outTextForGroup(gid, "目标列表已刷新", 2)
                    end)
                    table.insert(spotTargetCommands[jammer], refreshButton)
                end

                -- 立即执行第一次刷新
                refreshSpotTargetList()

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

                -- === ESM / ELINT（RWR 目标列表） ===
                local esmRoot = missionCommands.addSubMenuForGroup(gid, "ESM / ELINT (RWR)", root)
                esmMenus[jammer] = { root = esmRoot }

                -- 创建条件性雷达选择子菜单（需要载荷验证）
                esmMenus[jammer].listRoot = missionCommands.addSubMenuForGroup(gid, "开机雷达选择（≤80nm）", esmRoot)

                -- 添加载荷检查提示
                missionCommands.addCommandForGroup(gid, "载荷要求：需2枚AIM-9L", esmRoot, function()
                    local state = checkLoadoutState(jammer)
                    if state.valid then
                        local msg = string.format("载荷检查: AIM-9L数量 %d/2 (%s)",
                            state.rawCounts.aim9,
                            state.hasLBI and "满足要求" or "不满足要求"
                        )
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], msg, 5)
                    else
                        trigger.action.outTextForGroup(jammerGroupIDs[jammer], "无法检查载荷状态", 3)
                    end
                end)

                -- 简化为纯手动刷新机制
                esmMenus[jammer].radarItems = {}

                -- 创建刷新函数
                local function refreshRadarList()
                    -- 移除所有现有的雷达选择项
                    if esmMenus[jammer].radarItems then
                        for _, item in ipairs(esmMenus[jammer].radarItems) do
                            missionCommands.removeItemForGroup(gid, item)
                        end
                    end
                    esmMenus[jammer].radarItems = {}

                    local jammerUnit = Unit.getByName(jammer)
                    if not jammerUnit or not jammerUnit:isExist() then
                        local noUnitItem = missionCommands.addCommandForGroup(gid, "（本机不存在）", esmMenus[jammer].listRoot, function() end)
                        table.insert(esmMenus[jammer].radarItems, noUnitItem)
                        return
                    end

                    local jammerPos = jammerUnit:getPoint()
                    local count = 0
                    local totalRadars = 0

                    -- Debug信息汇总
                    local debugMsg = "=== ESM 雷达扫描调试 ===\n"

                    local redGroups = coalition.getGroups(coalition.side.RED)
                    if not redGroups then
                        debugMsg = debugMsg .. "未找到红方单位组！\n"
                    else
                        debugMsg = debugMsg .. "发现 " .. #redGroups .. " 个红方单位组\n"
                    end

                    for _, group in ipairs(redGroups or {}) do
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
                            local distNM = math.floor(dist / 1852 + 0.5)
                            local name = getNatoName(targetUnit)
                            local bearing = getBearing(jammerPos, tgtPos)

                            if dist <= 148160 then -- 80nm in meters
                                local losOK = land.isVisible(jammerPos, tgtPos)

                                -- 检查组内每个雷达单位的开机状态
                                for _, unit in ipairs(group:getUnits()) do
                                    if unit and unit:isExist() and isRadarishUnit(unit) then
                                        totalRadars = totalRadars + 1
                                        local unitPos = unit:getPoint()
                                        local unitDist = get3DDist(jammerPos, unitPos)
                                        local unitDistNM = math.floor(unitDist / 1852 + 0.5)
                                        local unitName = getNatoName(unit)
                                        local unitBearing = getBearing(jammerPos, unitPos)

                                        -- 检查单个雷达单位的开机状态
                                        local unitActive, unitDetections, unitMethods, trackedObj = checkRadarUnitActive(unit)

                                        local detectionStr = #unitDetections > 0 and ("(" .. table.concat(unitDetections, ",") .. ")") or "(无探测)"
                                        local unitLosOK = land.isVisible(jammerPos, unitPos)
                                        local losStr = unitLosOK and "LOS:通" or "LOS:阻"
                                        local statusStr = unitActive and "开机" or "关机"

                                        debugMsg = debugMsg .. string.format("  %s | %d° %dnm | %s | %s %s\n",
                                            unitName, unitBearing, unitDistNM, losStr, statusStr, detectionStr)

                                        -- 只有开机的雷达单位才加入列表
                                        if unitActive and unitDist <= 148160 then
                                            count = count + 1
                                            -- 强绑定：直接显示内部单位名称确保100%准确
                                            local internalName = unit:getName()
                                            local label = string.format("%s | %d° %dnm [开机] [%s]", unitName, unitBearing, unitDistNM, internalName)

                                            -- 创建回调函数：每次点击时重新获取最新信息，避免竞态条件
                                            local capturedUnitName = internalName  -- 在创建时捕获单位名
                                            local capturedLabel = label  -- 在创建时捕获标签

                                            local radarItem = missionCommands.addCommandForGroup(gid, label, esmMenus[jammer].listRoot, function()
                                                -- 载荷模拟检查：验证是否启用了长基线定位
                                                if not esmEnabled[jammer] then
                                                    trigger.action.outTextForGroup(gid, "长基线定位未启用，请先在载荷模拟菜单中启用", 5)
                                                    return
                                                end

                                                -- 二次载荷检查：确保当前仍然满足要求
                                                local currentState = checkLoadoutState(jammer)
                                                if not (currentState.valid and currentState.hasLBI) then
                                                    trigger.action.outTextForGroup(gid, "载荷不足：需要2枚AIM-9L用于长基线定位", 5)
                                                    esmEnabled[jammer] = false  -- 自动禁用
                                                    return
                                                end

                                                -- 确保 esmState 表存在
                                                if not esmState[jammer] then
                                                    esmState[jammer] = {}
                                                end

                                                -- 使用捕获的单位名，避免从可能已变化的label解析
                                                local extractedUnitName = capturedUnitName

                                                if DEBUG_MODE then
                                                    trigger.action.outTextForGroup(gid,
                                                        string.format("===选择解析===\n你选择的列表项: %s\n捕获的单位名: %s\n================",
                                                            capturedLabel, extractedUnitName or "解析失败"), 6)
                                                end

                                                if not extractedUnitName then
                                                    trigger.action.outTextForGroup(gid, "无法解析列表中的单位名，请重新选择", 3)
                                                    return
                                                end

                                                -- 根据解析出的单位名查找实际单位
                                                local actualUnit = Unit.getByName(extractedUnitName)
                                                if not actualUnit or not actualUnit:isExist() then
                                                    trigger.action.outTextForGroup(gid, "目标雷达已不存在，请重新选择", 3)
                                                    return
                                                end

                                                -- 获取实际单位的当前信息
                                                local actualUnitName = getNatoName(actualUnit)
                                                local jammerUnit = Unit.getByName(jammer)
                                                local currentDistance = 0
                                                if jammerUnit and jammerUnit:isExist() then
                                                    local jammerPos = jammerUnit:getPoint()
                                                    local targetPos = actualUnit:getPoint()
                                                    currentDistance = math.floor(get3DDist(jammerPos, targetPos) / 1852 + 0.5)
                                                end

                                                if DEBUG_MODE then
                                                    trigger.action.outTextForGroup(gid,
                                                        string.format("===最终确认===\n解析单位名: %s\n实际雷达类型: %s\n当前距离: %dnm\n================",
                                                            extractedUnitName, actualUnitName, currentDistance), 6)
                                                end

                                                -- 清理进行中的定位标记，但保留已完成的精确标记
                                                -- 清理圈标记（总是清理，因为要重新开始）
                                                if esmState[jammer].ringId then
                                                    removeMarkId(esmState[jammer].ringId)
                                                    esmState[jammer].ringId = nil
                                                end
                                                -- 只有在重新选择同一目标时才清理精确标记，否则保留已完成的定位
                                                if esmState[jammer].markId and esmState[jammer].targetUnitName == extractedUnitName then
                                                    trigger.action.removeMark(esmState[jammer].markId)
                                                    esmState[jammer].markId = nil
                                                end

                                                esmState[jammer].targetUnitName = extractedUnitName
                                                esmState[jammer].dwell = 0
                                                esmState[jammer].lastSeen = 0
                                                esmState[jammer].lastProgressReport = 0
                                                esmState[jammer].lastDebugReport = 0
                                                esmState[jammer].ringStage = 0


                                                -- 目标选择确认信息
                                                if DEBUG_MODE then
                                                    trigger.action.outTextForGroup(gid,
                                                        string.format("ESM目标已选择：%s\n距离：%dnm\n需要持续开机30秒进行定位\n开始监听...\n目标内部名: %s\n干扰器: %s",
                                                            actualUnitName, currentDistance, extractedUnitName, jammer), 8)
                                                else
                                                    trigger.action.outTextForGroup(gid,
                                                        string.format("开始定位：%s (%dnm)", actualUnitName, currentDistance), 3)
                                                end
                                            end)

                                            table.insert(esmMenus[jammer].radarItems, radarItem)
                                        end
                                    end
                                end
                            else
                                debugMsg = debugMsg .. string.format("%s组 | %d° %dnm | 超出80nm\n",
                                    group:getName(), bearing, distNM)
                            end
                        end
                    end

                    if DEBUG_MODE then
                        debugMsg = debugMsg .. string.format("=== 扫描完成：%d/%d 雷达可选 ===", count, totalRadars)
                        trigger.action.outTextForGroup(gid, debugMsg, 15)
                    end

                    if count == 0 then
                        local noRadarItem = missionCommands.addCommandForGroup(gid, "（当前无开机雷达）", esmMenus[jammer].listRoot, function() end)
                        table.insert(esmMenus[jammer].radarItems, noRadarItem)
                    end

                    -- 添加手动刷新按钮
                    local refreshButton = missionCommands.addCommandForGroup(gid, "手动刷新雷达列表", esmMenus[jammer].listRoot, function()
                        refreshRadarList()
                        trigger.action.outTextForGroup(gid, "雷达列表已刷新", 2)
                    end)
                    table.insert(esmMenus[jammer].radarItems, refreshButton)
                end

                -- 立即执行第一次刷新
                refreshRadarList()

                missionCommands.addCommandForGroup(gid, "取消当前 ESM 目标", esmRoot, function()
                    if esmState[jammer] and esmState[jammer].targetUnitName then
                        local targetName = esmState[jammer].targetUnitName
                        -- 清理圈标记
                        if esmState[jammer].ringId then
                            removeMarkId(esmState[jammer].ringId)
                            esmState[jammer].ringId = nil
                        end
                        -- 清理精确点标记（如果有）
                        if esmState[jammer].markId then
                            trigger.action.removeMark(esmState[jammer].markId)
                            esmState[jammer].markId = nil
                        end
                        esmState[jammer].targetUnitName = nil
                        esmState[jammer].dwell = 0
                        esmState[jammer].lastSeen = 0
                        esmState[jammer].lastProgressReport = 0
                        esmState[jammer].ringStage = 0
                        trigger.action.outTextForGroup(gid, "ESM目标已清除：" .. targetName, 4)
                    else
                        trigger.action.outTextForGroup(gid, "当前无ESM目标", 4)
                    end
                end)

if jammerGroupIDs[jammer] then
    trigger.action.outTextForGroup(jammerGroupIDs[jammer], "电子战干扰菜单已创建: " .. jammer, 4)
end
            end
        end
    end
    return timer.getTime() + menuCheckInterval
end

-- 修改：启动三个循环，导弹循环使用0.5秒间隔，ESM循环使用1秒间隔
timer.scheduleFunction(SAFE("jammerLoop", jammerLoop), {}, timer.getTime() + 3)
timer.scheduleFunction(SAFE("missileLoop", missileLoop), {}, timer.getTime() + 1)  -- 导弹循环0.5秒间隔
timer.scheduleFunction(SAFE("esmLoop", esmLoop), {}, timer.getTime() + ESM_TICK)  -- ESM循环1秒间隔
timer.scheduleFunction(SAFE("setupMenus", setupMenus), {}, timer.getTime() + 2)

-- 原自动刷新功能已移除，改为手动刷新机制

-- === 载荷模拟系统启动 ===

-- 启动载荷状态监控循环
timer.scheduleFunction(SAFE("loadoutMonitorLoop", loadoutMonitorLoop), {}, timer.getTime() + 5)

-- 事件监听器：快速响应武器投放/发射
local loadoutEventHandler = {
    onEvent = function(self, event)
        if event.id == world.event.S_EVENT_SHOT or event.id == world.event.S_EVENT_WEAPON_ADD then
            -- 武器发射/投放事件，立即检查载荷状态
            if event.initiator and event.initiator.getName then
                local unitName = event.initiator:getName()
                -- 检查是否是干扰机
                for _, jammerName in ipairs(jammerUnits) do
                    if unitName == jammerName then
                        -- 延迟1秒后检查载荷（让弹药更新完成）
                        timer.scheduleFunction(function()
                            local currentState = checkLoadoutState(jammerName)
                            if currentState.valid then
                                local previousState = loadoutState[jammerName] or {}

                                -- 检查ESM状态变化
                                if esmEnabled[jammerName] and not currentState.hasLBI then
                                    esmEnabled[jammerName] = false
                                    if jammerGroupIDs[jammerName] then
                                        trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
                                            "警告: 武器发射导致AIM-9L不足，长基线定位已自动禁用", 5)
                                    end
                                end

                                -- 检查干扰吊舱状态
                                local currentPreset = jammerSettings[jammerName] and jammerSettings[jammerName].currentPreset
                                if currentPreset then
                                    local needALQ99 = currentPreset.alq99 or 0
                                    local needALQ249 = currentPreset.alq249 or 0

                                    if currentState.alq99Count < needALQ99 or currentState.alq249Count < needALQ249 then
                                        -- 载荷不足，禁用干扰功能
                                        jammerSettings[jammerName].offensive = false
                                        jammerSettings[jammerName].defensive = false
                                        jammerSettings[jammerName].offDir = nil
                                        jammerSettings[jammerName].defDir = nil
                                        maxEmitterCapacity[jammerName] = 0
                                        emitterCapacity[jammerName] = 0

                                        if jammerGroupIDs[jammerName] then
                                            trigger.action.outTextForGroup(jammerGroupIDs[jammerName],
                                                "警告: 武器投放导致载荷不足，干扰功能已自动禁用", 5)
                                        end
                                    end
                                end

                                loadoutState[jammerName] = currentState
                            end
                        end, nil, timer.getTime() + 1)
                        break
                    end
                end
            end
        end
    end
}

-- 注册事件监听器
world.addEventHandler(loadoutEventHandler)

-- 输出载荷模拟系统启动信息
if DEBUG_MODE then
    trigger.action.outTextForCoalition(coalition.side.BLUE, "载荷模拟系统已启动", 10)
end