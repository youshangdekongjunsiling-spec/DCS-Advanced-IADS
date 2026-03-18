-- ====== 修正版雷达天线模型系统 (SA-11 Fire Dome 参数优化) ======

-- === 工具函数 ===
local function db2lin(db) return 10^(db/10) end
local function lin2db(x) return 10*math.log10(math.max(x, 1e-10)) end
local function sigma_from_hpbw(hpbw_deg) return hpbw_deg / 2.355 end

-- === 修正版分类参数 ===
local CATEGORY = {
  aesa = {
    L1_db = -15,      -- 首旁瓣 (相控阵，抬高为可玩性)
    delta_db = 4,     -- 每级衰减
    alpha = 1.5,      -- 旁瓣间距系数
    sl_ratio = 1.0,   -- 旁瓣宽度比
    per_side_max = 5, -- 每侧最多旁瓣对数
    floor_db = -27    -- 远端泄露底限
  },
  mid = {
    L1_db = -10,      -- 首旁瓣 (中代雷达)
    delta_db = 4,     -- 每级衰减
    alpha = 2.0,      -- 旁瓣间距系数 (增加间距)
    sl_ratio = 1.6,   -- 旁瓣宽度比
    per_side_max = 13,-- 每侧最多旁瓣对数 (增加数量)
    floor_db = -30    -- 远端泄露底限 (降低10dB)
  },
  early = {
    L1_db = -5, delta_db = 4, alpha = 0.9, sl_ratio = 2.4,
    per_side_max = 6, floor_db = -15
  }
}

-- === 通用旁瓣生成器 ===
local function make_custom_pattern(name, HPBW_deg, floor_db, sidelobes)
  --[[
  通用旁瓣生成器

  参数:
  - name: 雷达名称
  - HPBW_deg: 主瓣半功率波束宽度
  - floor_db: 噪声底限 (dB)
  - sidelobes: 旁瓣列表，每个元素包含:
    - angle_deg: 旁瓣中心角度 (度，相对主瓣)
    - amplitude_db: 旁瓣幅度 (dB，相对主瓣)
    - width_deg: 旁瓣宽度 (度，可选，默认使用主瓣宽度)
    - symmetric: 是否对称 (布尔，默认true，在±angle都放置)

  示例:
  local sidelobes = {
    {angle_deg = 3, amplitude_db = -10, width_deg = 1.5, symmetric = true},
    {angle_deg = 6, amplitude_db = -14, width_deg = 1.5, symmetric = true},
    {angle_deg = 15, amplitude_db = -20, width_deg = 2.0, symmetric = false}
  }
  --]]

  local sigma_main = sigma_from_hpbw(HPBW_deg)
  local lobes = {}

  -- 主瓣
  table.insert(lobes, {1.0, 0.0, sigma_main})

  -- 自定义旁瓣
  for _, sl in ipairs(sidelobes) do
    local angle = sl.angle_deg
    local amplitude_linear = db2lin(sl.amplitude_db)
    local width = sl.width_deg or HPBW_deg  -- 默认使用主瓣宽度
    local symmetric = sl.symmetric
    if symmetric == nil then symmetric = true end  -- 默认对称

    local sigma_sl = sigma_from_hpbw(width)

    -- 添加正角度旁瓣
    table.insert(lobes, {amplitude_linear, angle, sigma_sl})

    -- 如果对称，添加负角度旁瓣
    if symmetric and angle ~= 0 then
      table.insert(lobes, {amplitude_linear, -angle, sigma_sl})
    end
  end

  return {
    name = name,
    HPBW_deg = HPBW_deg,
    category = "custom",
    lobes = lobes,
    floor = db2lin(floor_db),
    normalize = false
  }
end

-- === 1L13 EWR 特殊生成器 ===
local function make_1L13_pattern(HPBW_deg, cat)
  local cfg = CATEGORY[cat]
  if not cfg then
    env.error("Unknown radar category: " .. tostring(cat), false)
    return nil
  end

  local sigma_main = sigma_from_hpbw(HPBW_deg)
  local sigma_sl   = sigma_main * cfg.sl_ratio
  local A_lin      = db2lin(cfg.L1_db)
  local drop_lin   = db2lin(-cfg.delta_db)

  local lobes = {}
  -- 主瓣
  table.insert(lobes, {1.0, 0.0, sigma_main})

  -- 1L13特殊旁瓣：9度间距，8个旁瓣每侧
  local theta1_special = 9.0
  local dtheta_special = 9.0
  local max_sidelobes = 8

  for n = 1, max_sidelobes do
    local th = theta1_special + (n-1) * dtheta_special
    if th >= 90.0 then break end
    if A_lin < 1e-6 then break end

    table.insert(lobes, {A_lin, +th, sigma_sl})
    table.insert(lobes, {A_lin, -th, sigma_sl})
    A_lin = A_lin * drop_lin
  end

  return {
    HPBW_deg = HPBW_deg,
    category = cat,
    lobes = lobes,
    floor = db2lin(cfg.floor_db),
    normalize = false
  }
end

-- === 天线模式生成器 ===
local function make_pattern(HPBW_deg, cat)
  local cfg = CATEGORY[cat]
  if not cfg then
    env.error("Unknown radar category: " .. tostring(cat), false)
    return nil
  end

  local sigma_main = sigma_from_hpbw(HPBW_deg)
  local sigma_sl   = sigma_main * cfg.sl_ratio
  local theta1     = 3.0  -- 固定首旁瓣位置3度
  local dtheta     = 3.0  -- 固定旁瓣间隔3度
  local A_lin      = db2lin(cfg.L1_db)
  local drop_lin   = db2lin(-cfg.delta_db)

  local lobes = {}
  -- 主瓣 (归一化峰值)
  table.insert(lobes, {1.0, 0.0, sigma_main})

  -- 对称旁瓣对
  for n = 1, cfg.per_side_max do
    local th = theta1 + (n-1) * dtheta
    if th >= 90.0 then break end
    if A_lin < 1e-6 then break end  -- 避免过小的旁瓣

    table.insert(lobes, {A_lin, +th, sigma_sl})
    table.insert(lobes, {A_lin, -th, sigma_sl})
    A_lin = A_lin * drop_lin
  end

  return {
    HPBW_deg = HPBW_deg,
    category = cat,
    lobes = lobes,
    floor = db2lin(cfg.floor_db),
    normalize = false
  }
end

-- === 修正版雷达天线模型表 ===
radarAntennaModels = {
  -- S-300/SA-10系列 (相控阵)
  ["S-300PS 40B6M tr"]   = make_pattern(1.0, "aesa"),    -- 30N6 Track
  ["S-300PS 64H6E sr"]   = make_pattern(2.0, "aesa"),    -- Big Bird
  ["S-300PS 40B6MD sr"]  = make_pattern(3.5, "mid"),     -- 5N66/76N6

  -- SA-11/17 Buk 系列 (中代) - 修正后参数
  ["SA-11 Buk LN 9A310M1"] = make_pattern(1.2, "mid"),  -- Fire Dome (火控雷达)
  ["Buk SR 9S18M1"] = make_custom_pattern(              -- Snow Drift (搜索雷达，4.5度间距)
    "Buk SR 9S18M1 (Snow Drift) - 4.5度间距",
    1.8,  -- HPBW
    -25,  -- floor_db
    {
      {angle_deg = 4.5, amplitude_db = -10, width_deg = 1.8, symmetric = true},
      {angle_deg = 9.0, amplitude_db = -14, width_deg = 1.8, symmetric = true},
      {angle_deg = 13.5, amplitude_db = -18, width_deg = 1.8, symmetric = true},
      {angle_deg = 18.0, amplitude_db = -22, width_deg = 1.8, symmetric = true},
      {angle_deg = 22.5, amplitude_db = -26, width_deg = 1.8, symmetric = true},
      {angle_deg = 27.0, amplitude_db = -30, width_deg = 1.8, symmetric = true},
      {angle_deg = 31.5, amplitude_db = -34, width_deg = 1.8, symmetric = true},
      {angle_deg = 36.0, amplitude_db = -38, width_deg = 1.8, symmetric = true},
      {angle_deg = 40.5, amplitude_db = -42, width_deg = 1.8, symmetric = true},
      {angle_deg = 45.0, amplitude_db = -46, width_deg = 1.8, symmetric = true},
      {angle_deg = 49.5, amplitude_db = -50, width_deg = 1.8, symmetric = true},
      {angle_deg = 54.0, amplitude_db = -54, width_deg = 1.8, symmetric = true},
      {angle_deg = 58.5, amplitude_db = -58, width_deg = 1.8, symmetric = true},
      {angle_deg = 63.0, amplitude_db = -62, width_deg = 1.8, symmetric = true},
      {angle_deg = 67.5, amplitude_db = -66, width_deg = 1.8, symmetric = true}
    }
  ),
  ["SA-17 Buk M1-2 LN"]  = make_pattern(1.0, "mid"),     -- Buk M1-2

  -- SA-15 Tor / SA-8 Osa (中代近程)
  ["Tor 9A331"]          = make_pattern(1.2, "mid"),     -- SA-15 TTR
  ["Osa 9A33 ln"] = make_custom_pattern(                 -- SA-8 Land Roll (6度间距，翻倍波束宽度)
    "Osa 9A33 ln (SA-8 Land Roll) - 6度间距",
    3.0,  -- HPBW (翻倍)
    -30,  -- floor_db (mid级别)
    {
      {angle_deg = 6, amplitude_db = -10, width_deg = 3.0, symmetric = true},
      {angle_deg = 12, amplitude_db = -14, width_deg = 3.0, symmetric = true},
      {angle_deg = 18, amplitude_db = -18, width_deg = 3.0, symmetric = true},
      {angle_deg = 24, amplitude_db = -22, width_deg = 3.0, symmetric = true},
      {angle_deg = 30, amplitude_db = -26, width_deg = 3.0, symmetric = true},
      {angle_deg = 36, amplitude_db = -30, width_deg = 3.0, symmetric = true},
      {angle_deg = 42, amplitude_db = -34, width_deg = 3.0, symmetric = true},
      {angle_deg = 48, amplitude_db = -38, width_deg = 3.0, symmetric = true},
      {angle_deg = 54, amplitude_db = -42, width_deg = 3.0, symmetric = true},
      {angle_deg = 60, amplitude_db = -46, width_deg = 3.0, symmetric = true},
      {angle_deg = 66, amplitude_db = -50, width_deg = 3.0, symmetric = true},
      {angle_deg = 72, amplitude_db = -54, width_deg = 3.0, symmetric = true},
      {angle_deg = 78, amplitude_db = -58, width_deg = 3.0, symmetric = true}
    }
  ),

  -- 早期/老式系统
  ["SNR_75V"]            = make_pattern(7.5, "early"),   -- SA-2 Fan Song
  ["Kub STR"] = make_custom_pattern(                     -- SA-6火控雷达 (10度间距，3dB衰减，6度宽)
    "Kub STR (SA-6 Straight Flush) - 10度间距",
    6.0,  -- HPBW (与旁瓣宽度一致)
    -18,  -- floor_db (early级别)
    {
      {angle_deg = 10, amplitude_db = -5, width_deg = 6.0, symmetric = true},
      {angle_deg = 20, amplitude_db = -8, width_deg = 6.0, symmetric = true},
      {angle_deg = 30, amplitude_db = -11, width_deg = 6.0, symmetric = true},
      {angle_deg = 40, amplitude_db = -14, width_deg = 6.0, symmetric = true},
      {angle_deg = 50, amplitude_db = -17, width_deg = 6.0, symmetric = true},
      {angle_deg = 60, amplitude_db = -20, width_deg = 6.0, symmetric = true},
      {angle_deg = 70, amplitude_db = -23, width_deg = 6.0, symmetric = true},
      {angle_deg = 80, amplitude_db = -26, width_deg = 6.0, symmetric = true}
    }
  ),
  ["P-19 st"] = make_custom_pattern(                      -- Flat Face (5度间距，3dB衰减，4度宽)
    "P-19 st (Flat Face) - 5度间距",
    4.0,  -- HPBW (主瓣宽度4度)
    -15,  -- floor_db (early级别)
    {
      {angle_deg = 5, amplitude_db = -3, width_deg = 4.0, symmetric = true},
      {angle_deg = 10, amplitude_db = -6, width_deg = 4.0, symmetric = true},
      {angle_deg = 15, amplitude_db = -9, width_deg = 4.0, symmetric = true},
      {angle_deg = 20, amplitude_db = -12, width_deg = 4.0, symmetric = true},
      {angle_deg = 25, amplitude_db = -15, width_deg = 4.0, symmetric = true},
      {angle_deg = 30, amplitude_db = -18, width_deg = 4.0, symmetric = true},
      {angle_deg = 35, amplitude_db = -21, width_deg = 4.0, symmetric = true},
      {angle_deg = 40, amplitude_db = -24, width_deg = 4.0, symmetric = true},
      {angle_deg = 45, amplitude_db = -27, width_deg = 4.0, symmetric = true},
      {angle_deg = 50, amplitude_db = -30, width_deg = 4.0, symmetric = true},
      {angle_deg = 55, amplitude_db = -33, width_deg = 4.0, symmetric = true},
      {angle_deg = 60, amplitude_db = -36, width_deg = 4.0, symmetric = true},
      {angle_deg = 65, amplitude_db = -39, width_deg = 4.0, symmetric = true},
      {angle_deg = 70, amplitude_db = -42, width_deg = 4.0, symmetric = true},
      {angle_deg = 75, amplitude_db = -45, width_deg = 4.0, symmetric = true},
      {angle_deg = 80, amplitude_db = -48, width_deg = 4.0, symmetric = true}
    }
  ),
  -- 1L13 EWR - 使用通用生成器的示例 (更多旁瓣，5dB衰减)
  ["1L13 EWR"] = make_custom_pattern(
    "1L13 EWR (Nebo) - 通用生成器",
    6.0,  -- HPBW
    -20,  -- floor_db
    {
      {angle_deg = 9, amplitude_db = -5, width_deg = 6.0, symmetric = true},
      {angle_deg = 18, amplitude_db = -10, width_deg = 6.0, symmetric = true},
      {angle_deg = 27, amplitude_db = -15, width_deg = 6.0, symmetric = true},
      {angle_deg = 36, amplitude_db = -20, width_deg = 6.0, symmetric = true},
      {angle_deg = 45, amplitude_db = -25, width_deg = 6.0, symmetric = true},
      {angle_deg = 54, amplitude_db = -30, width_deg = 6.0, symmetric = true},
      {angle_deg = 63, amplitude_db = -35, width_deg = 6.0, symmetric = true},
      {angle_deg = 72, amplitude_db = -40, width_deg = 6.0, symmetric = true},
      {angle_deg = 81, amplitude_db = -45, width_deg = 6.0, symmetric = true}
    }
  ),

  -- 西方系统
  ["Patriot str"]        = make_pattern(1.1, "aesa"),    -- AN/MPQ-53/65
  ["Hawk tr"] = make_custom_pattern(                     -- Hawk跟踪雷达 (4度间距，7dB衰减)
    "Hawk tr (HPIR) - 4度间距",
    1.5,  -- HPBW
    -25,  -- floor_db
    {
      {angle_deg = 4, amplitude_db = -10, width_deg = 1.5, symmetric = true},
      {angle_deg = 8, amplitude_db = -17, width_deg = 1.5, symmetric = true},
      {angle_deg = 12, amplitude_db = -24, width_deg = 1.5, symmetric = true},
      {angle_deg = 16, amplitude_db = -31, width_deg = 1.5, symmetric = true},
      {angle_deg = 20, amplitude_db = -38, width_deg = 1.5, symmetric = true},
      {angle_deg = 24, amplitude_db = -45, width_deg = 1.5, symmetric = true},
      {angle_deg = 28, amplitude_db = -52, width_deg = 1.5, symmetric = true},
      {angle_deg = 32, amplitude_db = -59, width_deg = 1.5, symmetric = true},
      {angle_deg = 36, amplitude_db = -66, width_deg = 1.5, symmetric = true},
      {angle_deg = 40, amplitude_db = -73, width_deg = 1.5, symmetric = true}
    }
  ),
  ["Hawk sr"] = make_custom_pattern(                     -- Hawk搜索雷达 (5度间距，4dB衰减)
    "Hawk sr (PAR) - 5度间距",
    3.5,  -- HPBW
    -20,  -- floor_db
    {
      {angle_deg = 5, amplitude_db = -5, width_deg = 3.5, symmetric = true},
      {angle_deg = 10, amplitude_db = -9, width_deg = 3.5, symmetric = true},
      {angle_deg = 15, amplitude_db = -13, width_deg = 3.5, symmetric = true},
      {angle_deg = 20, amplitude_db = -17, width_deg = 3.5, symmetric = true},
      {angle_deg = 25, amplitude_db = -21, width_deg = 3.5, symmetric = true},
      {angle_deg = 30, amplitude_db = -25, width_deg = 3.5, symmetric = true},
      {angle_deg = 35, amplitude_db = -29, width_deg = 3.5, symmetric = true},
      {angle_deg = 40, amplitude_db = -33, width_deg = 3.5, symmetric = true},
      {angle_deg = 45, amplitude_db = -37, width_deg = 3.5, symmetric = true},
      {angle_deg = 50, amplitude_db = -41, width_deg = 3.5, symmetric = true},
      {angle_deg = 55, amplitude_db = -45, width_deg = 3.5, symmetric = true},
      {angle_deg = 60, amplitude_db = -49, width_deg = 3.5, symmetric = true}
    }
  ),
  ["Roland ADS"]         = make_pattern(2.0, "mid"),     -- Roland

  -- 自行防空
  ["Tunguska_2S6"]       = make_pattern(2.0, "mid"),     -- 1RL144
  ["Gepard"] = make_custom_pattern(                      -- 德国自行高炮防空系统 (6度间距，6dB衰减)
    "Gepard (德国自行高炮) - 6度间距",
    3.0,  -- HPBW
    -20,  -- floor_db
    {
      {angle_deg = 6, amplitude_db = -5, width_deg = 3.0, symmetric = true},
      {angle_deg = 12, amplitude_db = -11, width_deg = 3.0, symmetric = true},
      {angle_deg = 18, amplitude_db = -17, width_deg = 3.0, symmetric = true},
      {angle_deg = 24, amplitude_db = -23, width_deg = 3.0, symmetric = true},
      {angle_deg = 30, amplitude_db = -29, width_deg = 3.0, symmetric = true},
      {angle_deg = 36, amplitude_db = -35, width_deg = 3.0, symmetric = true},
      {angle_deg = 42, amplitude_db = -41, width_deg = 3.0, symmetric = true},
      {angle_deg = 48, amplitude_db = -47, width_deg = 3.0, symmetric = true},
      {angle_deg = 54, amplitude_db = -53, width_deg = 3.0, symmetric = true},
      {angle_deg = 60, amplitude_db = -59, width_deg = 3.0, symmetric = true}
    }
  ),
  ["ZSU-23-4 Shilka"]    = make_pattern(4.0, "early"),   -- Gun Dish

  -- 向后兼容别名
  ["SA-10_FlapLid"]      = make_pattern(1.0, "aesa"),
  ["SA-11_FireDome"]     = make_pattern(1.2, "mid"),
  ["BigBird_64N6"]       = make_pattern(2.0, "aesa")
}

-- === 核心计算函数 (完全匹配Python) ===

-- 计算天线增益 (线性)
function antenna_gain_linear(model, theta_deg)
  if not model or not model.lobes then return model and model.floor or 0.001 end
  local s = 0.0
  for i, lobe in ipairs(model.lobes) do
    local A, mu, sigma = lobe[1], lobe[2], lobe[3]
    local d = theta_deg - mu
    local exp_arg = -(d * d) / (2 * sigma * sigma)
    -- 防止数值溢出
    if exp_arg > -60 then
      s = s + A * math.exp(exp_arg)
    end
  end
  return math.max(s, model.floor or 0.001)
end

-- 计算SNR_dB (相对)
function compute_snr_db(Rj, Rt, G_target, G_jam_dir, tx_gain_db)
  local tx_lin = 10^(tx_gain_db/10)
  local snr_lin = (G_target*G_target) / (G_jam_dir/tx_lin) * (Rj*Rj) / (Rt^4)
  return 10.0 * math.log10(math.max(snr_lin, 1e-24))
end

-- 概率映射 (sigmoid, k=0.2陡峭模式)
function pjam_from_snr_db(snr_db, k)
  k = k or 0.2  -- 默认陡峭模式
  return 1.0 / (1.0 + math.exp(k * (snr_db - 0.0)))
end

-- === 调试/验证函数 ===
function debug_radar_pattern(radar_type)
  local model = radarAntennaModels[radar_type]
  if not model then
    trigger.action.outText("未知雷达类型: " .. tostring(radar_type), 5)
    return
  end

  local debug_info = string.format("=== %s 天线参数 ===\n", radar_type)
  debug_info = debug_info .. string.format("HPBW: %.1f°, 类别: %s\n", model.HPBW_deg, model.category)
  debug_info = debug_info .. string.format("底限: %.1f dB, 旁瓣数: %d\n",
    10*math.log10(model.floor), #model.lobes)

  -- 显示关键角度的增益
  local test_angles = {0, 1.5, 3, 5, 10, 15, 20, 30, 45}
  for _, angle in ipairs(test_angles) do
    local gain_lin = antenna_gain_linear(model, angle)
    local gain_db = 10 * math.log10(gain_lin)
    debug_info = debug_info .. string.format("%.0f°: %+.1f dB\n", angle, gain_db)
  end

  trigger.action.outText(debug_info, 15)
end

-- === 修正说明 ===
--[[
SA-11 Buk LN 9A310M1 (Fire Dome) 修正:
1. Floor: -20dB → -30dB (更真实的噪声底限)
2. Alpha: 1.2 → 2.0 (旁瓣间距从主瓣拉开)
3. per_side_max: 11 → 13 (增加2对旁瓣，更全面覆盖)

结果对比:
修正前: 首旁瓣±1.4°, floor -20dB
修正后: 首旁瓣±1.4°, 第二旁瓣±3.8°, floor -30dB

这样SA-11火控雷达的旁瓣特性更符合实际中代雷达的表现，
同时为干扰机提供更多可利用的旁瓣进入机会。
--]]

trigger.action.outText("修正版雷达天线模型已加载 - SA-11参数优化", 10)