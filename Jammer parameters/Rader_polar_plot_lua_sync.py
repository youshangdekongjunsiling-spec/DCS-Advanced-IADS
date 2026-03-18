#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Updated radar antenna gain pattern plotter - synchronized with Lua script parameters
- Matches exactly the parameters used in the EA18G EW Script
- Model: G(theta) = sum_i A_i * exp( - (theta - mu_i)^2 / (2*sigma_i^2) ) + floor
- Angles in degrees; theta is off-boresight angle.
- Outputs: Cartesian and Polar plots with dB scaling
- Jamming effectiveness analysis with SNR-based probability calculations
"""
import argparse
import json
import math
from dataclasses import dataclass, asdict
from typing import List, Dict
import numpy as np
import matplotlib.pyplot as plt

# ====== 干扰系统参数配置 ======
JAMMING_CONFIG = {
    # 干扰器功率模式 (dB) - 针对JSR物理模型调整
    "JAMMER_MODES": {
        "broadcast": 23,   # 广播干扰 (增加5.5dB以满足EWR 70nm目标)
        "sector": 27,      # 扇面干扰
        "spot": 45         # 点干扰 (大幅增加以满足侧瓣干扰目标)
    },

    # 雷达发射功率 r_radar (dB) - 针对JSR物理模型和护航干扰场景调整
    "RADAR_POWER": {
        "1L13 EWR": 3,            # 大型预警雷达
        "S-300PS 64H6E sr": 42,   # S-300搜索雷达
        "S-300PS 40B6M tr": 6,    # S-300跟踪雷达 (进一步降低14dB以满足30nm点干扰目标)
        "SA-11 Buk LN 9A310M1": 4, # SA-11火控雷达 (进一步降低6dB以满足40nm点干扰目标)
        "Buk SR 9S18M1": 40,      # Buk搜索雷达
        "Osa 9A33 ln": 32,        # SA-8雷达
        "Kub STR": 35,            # SA-6雷达
        "P-19 st": 38,            # P-19雷达
        "Hawk tr": 33,            # Hawk跟踪雷达
        "Hawk sr": 36,            # Hawk搜索雷达
        "Gepard": 30,             # Gepard雷达
        "Patriot str": 40,        # 爱国者雷达
        "Tor 9A331": 32,          # Tor雷达
        "SNR_75V": 42,            # SA-2雷达
    },

    # Sigmoid函数参数
    "SIGMOID_K": 0.2,             # 陡峭度参数
    "TARGET_JAM_PROB": 0.5,       # 目标干扰概率 (50%)

    # 距离计算参数
    "NM_TO_KM": 1.852,           # 海里到公里转换
    "REFERENCE_RANGE_KM": 100,    # 参考距离 (km)
}

# 设计目标 (用于验证参数设置)
DESIGN_TARGETS = {
    "EWR_broadcast_70nm": {"radar": "1L13 EWR", "mode": "broadcast", "range_nm": 70, "angle": 0},
    "SA11_spot_40nm_sidelobe": {"radar": "SA-11 Buk LN 9A310M1", "mode": "spot", "range_nm": 40, "angle": 15},
    "S300_spot_30nm_sidelobe": {"radar": "S-300PS 40B6M tr", "mode": "spot", "range_nm": 30, "angle": 10},
}

@dataclass
class Lobe:
    A: float          # amplitude (linear, relative to main-lobe peak)
    mu_deg: float     # center angle (degrees, off-boresight)
    sigma_deg: float  # Gaussian width (degrees)

@dataclass
class Pattern:
    name: str
    HPBW_deg: float
    category: str
    lobes: List[Lobe]
    floor: float = 0.0
    normalize: bool = False

    def gain(self, theta_deg: np.ndarray) -> np.ndarray:
        """Compute relative gain vs angle in degrees (matches Lua antenna_gain_linear)."""
        theta = theta_deg.astype(float)
        total = np.zeros_like(theta, dtype=float)

        for l in self.lobes:
            d = theta - l.mu_deg
            total += l.A * np.exp(-(d * d) / (2.0 * (l.sigma_deg ** 2)))

        # Apply floor (matches Lua: if s < model.floor then s = model.floor end)
        total = np.maximum(total, self.floor)
        return total

def db_to_lin(db_value: float) -> float:
    """Convert dB to linear power ratio"""
    return 10 ** (db_value / 10)

def sigma_from_hpbw(hpbw_deg: float) -> float:
    """Convert HPBW to Gaussian sigma (matches Lua)"""
    return hpbw_deg / 2.355

def lin_to_db(linear_value: float) -> float:
    """Convert linear to dB"""
    return 10 * np.log10(np.maximum(linear_value, 1e-10))

def compute_range_loss_db(range_km: float, is_radar: bool = True) -> float:
    """
    计算距离损耗 (dB)
    - 雷达到目标: 四次方反比 (双程)
    - 干扰器到雷达: 平方反比 (单程)
    """
    ref_range = JAMMING_CONFIG["REFERENCE_RANGE_KM"]
    if is_radar:
        # 雷达方程: 四次方反比
        return 40 * np.log10(range_km / ref_range)
    else:
        # 干扰方程: 平方反比
        return 20 * np.log10(range_km / ref_range)

def compute_jsr_db(radar_name: str, jammer_direction_gain_db: float, r_jammer_db: float,
                   range_radar_target_km: float, range_jammer_radar_km: float) -> float:
    """
    计算干扰信号比 (JSR: Jamming-to-Signal Ratio) in dB - 护航干扰场景

    场景：干扰机保护距离雷达 range_radar_target_km 的目标

    Signal_Power ∝ radar_power × G_target × (1/range_target^4)
    Jamming_Power ∝ jammer_power × G_jammer × (1/range_jammer^2)

    JSR = Jamming_Power / Signal_Power

    Parameters:
    - radar_name: 雷达类型
    - jammer_direction_gain_db: 雷达在干扰机方向的增益 (dB)
    - r_jammer_db: 干扰器功率 (dB)
    - range_radar_target_km: 雷达到目标距离 (km, 固定)
    - range_jammer_radar_km: 干扰器到雷达距离 (km, 变量)

    Returns: JSR in dB (正值表示干扰信号比目标信号强)
    注意：假设目标在雷达主瓣方向 (G_target = 0dB)
    """
    r_radar = JAMMING_CONFIG["RADAR_POWER"].get(radar_name, 35)

    # 用户公式：r_radar + r_direction_db - r_jammer_db - r_distance = JSR
    # 当JSR = 0时，干扰概率50%

    # 距离损耗项
    r_distance_target = compute_range_loss_db(range_radar_target_km, is_radar=True)  # 目标距离损耗（雷达方程）
    r_distance_jammer = compute_range_loss_db(range_jammer_radar_km, is_radar=False)  # 干扰器距离损耗（通信方程）

    # 根据用户公式计算JSR
    # 目标信号：r_radar + 0dB(主瓣) - r_distance_target
    # 干扰信号：r_jammer + r_direction_db - r_distance_jammer
    # JSR = 干扰信号 - 目标信号
    jsr_db = (r_jammer_db + jammer_direction_gain_db - r_distance_jammer) - (r_radar + 0.0 - r_distance_target)

    return jsr_db

def jamming_probability_sigmoid(jsr_db: float, k: float = None) -> float:
    """
    使用Sigmoid函数将JSR转换为干扰成功概率

    P_jam = 1 / (1 + exp(-k * JSR_dB))

    当JSR > 0时，干扰信号比目标信号强，干扰概率高
    当JSR < 0时，干扰信号比目标信号弱，干扰概率低

    JSR = Jamming-to-Signal Ratio (干扰信号比)
    """
    if k is None:
        k = JAMMING_CONFIG["SIGMOID_K"]
    return 1.0 / (1.0 + np.exp(-k * jsr_db))

def compute_jamming_range_for_probability(radar_name: str, theta_deg: float,
                                          target_prob: float = 0.5,
                                          jammer_mode: str = "spot",
                                          range_radar_target_km: float = 50) -> float:
    """
    计算在给定角度和目标干扰概率下，所需的干扰器距离

    通过数值求解找到使 P_jam = target_prob 的距离
    """
    # 获取雷达增益模式
    pattern = get_radar_pattern(radar_name)
    if pattern is None:
        return np.inf

    # 计算该角度下的方向增益
    r_direction_linear = pattern.gain(np.array([theta_deg]))[0]
    r_direction_db = lin_to_db(r_direction_linear)

    # 获取干扰器功率
    r_jammer_db = JAMMING_CONFIG["JAMMER_MODES"][jammer_mode]

    # 数值求解：寻找使P_jam = target_prob的距离
    from scipy.optimize import brentq

    def prob_diff(range_jammer_km):
        if range_jammer_km <= 0:
            return 1.0 - target_prob
        jsr = compute_jsr_db(radar_name, r_direction_db, r_jammer_db,
                           range_radar_target_km, range_jammer_km)
        prob = jamming_probability_sigmoid(jsr)
        return prob - target_prob

    try:
        # 在1km到1000km范围内搜索
        range_result = brentq(prob_diff, 1.0, 1000.0)
        return range_result
    except ValueError:
        # 如果无解，返回无穷大或0
        prob_1km = prob_diff(1.0)
        if prob_1km > 0:
            return 0.0  # 即使在1km也无法达到目标概率
        else:
            return np.inf  # 即使在1000km也能超过目标概率

def get_radar_pattern(radar_name: str) -> Pattern:
    """获取指定雷达的增益模式"""
    patterns = builtin_patterns_lua_sync()
    return patterns.get(radar_name, None)

def make_custom_pattern(name: str, HPBW_deg: float, floor_db: float, sidelobes: List[Dict]) -> Pattern:
    """
    通用旁瓣生成器

    Parameters:
    - name: 雷达名称
    - HPBW_deg: 主瓣半功率波束宽度
    - floor_db: 噪声底限 (dB)
    - sidelobes: 旁瓣列表，每个元素包含:
        - angle_deg: 旁瓣中心角度 (度，相对主瓣)
        - amplitude_db: 旁瓣幅度 (dB，相对主瓣)
        - width_deg: 旁瓣宽度 (度，可选，默认使用主瓣宽度)
        - symmetric: 是否对称 (布尔，默认True，在±angle都放置)

    Example:
    sidelobes = [
        {"angle_deg": 3, "amplitude_db": -10, "width_deg": 1.5, "symmetric": True},
        {"angle_deg": 6, "amplitude_db": -14, "width_deg": 1.5, "symmetric": True},
        {"angle_deg": 15, "amplitude_db": -20, "width_deg": 2.0, "symmetric": False}
    ]
    """
    sigma_main = sigma_from_hpbw(HPBW_deg)

    lobes = []
    # 主瓣
    lobes.append(Lobe(1.0, 0.0, sigma_main))

    # 自定义旁瓣
    for sl in sidelobes:
        angle = sl["angle_deg"]
        amplitude_linear = db_to_lin(sl["amplitude_db"])
        width = sl.get("width_deg", HPBW_deg)  # 默认使用主瓣宽度
        symmetric = sl.get("symmetric", True)   # 默认对称

        sigma_sl = sigma_from_hpbw(width)

        # 添加正角度旁瓣
        lobes.append(Lobe(amplitude_linear, angle, sigma_sl))

        # 如果对称，添加负角度旁瓣
        if symmetric and angle != 0:
            lobes.append(Lobe(amplitude_linear, -angle, sigma_sl))

    return Pattern(
        name=name,
        HPBW_deg=HPBW_deg,
        category="custom",
        lobes=lobes,
        floor=db_to_lin(floor_db),
        normalize=False
    )

def make_pattern_lua_sync(HPBW_deg: float, category: str, name: str) -> Pattern:
    """
    Create radar pattern with EXACT same parameters as Lua script
    Categories: "aesa", "mid", "early" - matches CATEGORY table in Lua
    """
    # EXACT parameters from Lua CATEGORY table
    CATEGORY = {
        "aesa": {
            "L1_db": -15,       # 首旁瓣 (相控阵，抬高为可玩性)
            "delta_db": 4,      # 每级衰减
            "alpha": 1.5,       # 旁瓣间距系数
            "sl_ratio": 1.0,    # 旁瓣宽度比
            "per_side_max": 5,  # 每侧最多旁瓣对数
            "floor_db": -27     # 远端泄露底限
        },
        "mid": {
            "L1_db": -10, "delta_db": 4, "alpha": 2.0, "sl_ratio": 1.6,
            "per_side_max": 13, "floor_db": -30
        },
        "early": {
            "L1_db": -5, "delta_db": 4, "alpha": 0.9, "sl_ratio": 2.4,
            "per_side_max": 6, "floor_db": -15
        }
    }

    if category not in CATEGORY:
        raise ValueError(f"Unknown category: {category}")

    cfg = CATEGORY[category]

    # Calculate parameters (matches Lua make_pattern function)
    sigma_main = sigma_from_hpbw(HPBW_deg)
    sigma_sl = sigma_main * cfg["sl_ratio"]
    theta1 = 3.0  # Fixed first sidelobe at 3 degrees
    dtheta = 3.0  # Fixed spacing of 3 degrees between sidelobes
    A_lin = db_to_lin(cfg["L1_db"])
    drop_lin = db_to_lin(-cfg["delta_db"])

    # Generate lobes (matches Lua algorithm exactly)
    lobes = []
    lobes.append(Lobe(1.0, 0.0, sigma_main))  # Main lobe

    # Special handling for 1L13 EWR (Nebo) - triple spacing, more sidelobes
    if name.startswith("1L13 EWR"):
        # 1L13 special parameters: 9 degrees spacing, 8 sidelobes per side
        theta1_special = 9.0
        dtheta_special = 9.0
        max_sidelobes = 8

        for n in range(1, max_sidelobes + 1):
            th = theta1_special + (n-1) * dtheta_special
            if th >= 90.0:
                break
            lobes.append(Lobe(A_lin, +th, sigma_sl))
            lobes.append(Lobe(A_lin, -th, sigma_sl))
            A_lin = A_lin * drop_lin
    else:
        # Normal radar pattern
        for n in range(1, cfg["per_side_max"] + 1):
            th = theta1 + (n-1) * dtheta
            if th >= 90.0:
                break
            lobes.append(Lobe(A_lin, +th, sigma_sl))
            lobes.append(Lobe(A_lin, -th, sigma_sl))
            A_lin = A_lin * drop_lin

    # Category names for display
    category_names = {"aesa": "AESA", "mid": "Mid-Gen", "early": "Early"}

    return Pattern(
        name=f"{name} ({category_names[category]}) - HPBW={HPBW_deg:.1f}°",
        HPBW_deg=HPBW_deg,
        category=category,
        lobes=lobes,
        floor=db_to_lin(cfg["floor_db"]),
        normalize=False
    )

def builtin_patterns_lua_sync() -> Dict[str, Pattern]:
    """
    EXACT same radar list as Lua radarAntennaModels table
    Keys match DCS unit:getTypeName() exactly
    """
    return {
        # S-300/SA-10系列 (相控阵)
        "S-300PS 40B6M tr": make_pattern_lua_sync(1.0, "aesa", "S-300PS 40B6M tr (30N6)"),
        "S-300PS 64H6E sr": make_pattern_lua_sync(2.0, "aesa", "S-300PS 64H6E sr (Big Bird)"),
        "S-300PS 40B6MD sr": make_pattern_lua_sync(3.5, "mid", "S-300PS 40B6MD sr (5N66/76N6)"),

        # SA-11/17 Buk系列 (中代)
        "SA-11 Buk LN 9A310M1": make_pattern_lua_sync(1.2, "mid", "SA-11 Buk LN 9A310M1 (Fire Dome)"),
        "Buk SR 9S18M1": make_custom_pattern(               # Snow Drift (Search Radar, 4.5deg spacing)
            name="Buk SR 9S18M1 (Snow Drift) - 4.5deg spacing",
            HPBW_deg=1.8,
            floor_db=-25,
            sidelobes=[
                {"angle_deg": 4.5, "amplitude_db": -10, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 9.0, "amplitude_db": -14, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 13.5, "amplitude_db": -18, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 18.0, "amplitude_db": -22, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 22.5, "amplitude_db": -26, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 27.0, "amplitude_db": -30, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 31.5, "amplitude_db": -34, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 36.0, "amplitude_db": -38, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 40.5, "amplitude_db": -42, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 45.0, "amplitude_db": -46, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 49.5, "amplitude_db": -50, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 54.0, "amplitude_db": -54, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 58.5, "amplitude_db": -58, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 63.0, "amplitude_db": -62, "width_deg": 1.8, "symmetric": True},
                {"angle_deg": 67.5, "amplitude_db": -66, "width_deg": 1.8, "symmetric": True},
            ]
        ),
        "SA-17 Buk M1-2 LN": make_pattern_lua_sync(1.0, "mid", "SA-17 Buk M1-2 LN"),

        # SA-15/SA-8近程 (中代)
        "Tor 9A331": make_pattern_lua_sync(1.2, "mid", "Tor 9A331 (SA-15 TTR)"),
        "Osa 9A33 ln": make_custom_pattern(                 # SA-8 Land Roll (6deg spacing, doubled beam width)
            name="Osa 9A33 ln (SA-8 Land Roll) - 6deg spacing",
            HPBW_deg=3.0,  # doubled
            floor_db=-30,  # mid-gen level
            sidelobes=[
                {"angle_deg": 6, "amplitude_db": -10, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 12, "amplitude_db": -14, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 18, "amplitude_db": -18, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 24, "amplitude_db": -22, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -26, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 36, "amplitude_db": -30, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 42, "amplitude_db": -34, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 48, "amplitude_db": -38, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 54, "amplitude_db": -42, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -46, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 66, "amplitude_db": -50, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 72, "amplitude_db": -54, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 78, "amplitude_db": -58, "width_deg": 3.0, "symmetric": True},
            ]
        ),

        # 早期系统
        "SNR_75V": make_pattern_lua_sync(7.5, "early", "SNR_75V (SA-2 Fan Song)"),
        "Kub STR": make_custom_pattern(                     # SA-6 Fire Control Radar (10deg spacing, 3dB attenuation, 6deg width)
            name="Kub STR (SA-6 Straight Flush) - 10deg spacing",
            HPBW_deg=6.0,  # consistent with sidelobe width
            floor_db=-18,  # early level
            sidelobes=[
                {"angle_deg": 10, "amplitude_db": -5, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 20, "amplitude_db": -8, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -11, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 40, "amplitude_db": -14, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 50, "amplitude_db": -17, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -20, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 70, "amplitude_db": -23, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 80, "amplitude_db": -26, "width_deg": 6.0, "symmetric": True},
            ]
        ),
        "P-19 st": make_custom_pattern(                      # Flat Face (5deg spacing, 3dB attenuation, 4deg width)
            name="P-19 st (Flat Face) - 5deg spacing",
            HPBW_deg=4.0,  # main lobe width 4deg
            floor_db=-15,  # early level
            sidelobes=[
                {"angle_deg": 5, "amplitude_db": -3, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 10, "amplitude_db": -6, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 15, "amplitude_db": -9, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 20, "amplitude_db": -12, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 25, "amplitude_db": -15, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -18, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 35, "amplitude_db": -21, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 40, "amplitude_db": -24, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 45, "amplitude_db": -27, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 50, "amplitude_db": -30, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 55, "amplitude_db": -33, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -36, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 65, "amplitude_db": -39, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 70, "amplitude_db": -42, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 75, "amplitude_db": -45, "width_deg": 4.0, "symmetric": True},
                {"angle_deg": 80, "amplitude_db": -48, "width_deg": 4.0, "symmetric": True},
            ]
        ),
        # 1L13 EWR - Universal generator example (more sidelobes, 5dB attenuation)
        "1L13 EWR": make_custom_pattern(
            name="1L13 EWR (Nebo) - Universal Generator",
            HPBW_deg=6.0,
            floor_db=-20,
            sidelobes=[
                {"angle_deg": 9, "amplitude_db": -5, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 18, "amplitude_db": -10, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 27, "amplitude_db": -15, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 36, "amplitude_db": -20, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 45, "amplitude_db": -25, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 54, "amplitude_db": -30, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 63, "amplitude_db": -35, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 72, "amplitude_db": -40, "width_deg": 6.0, "symmetric": True},
                {"angle_deg": 81, "amplitude_db": -45, "width_deg": 6.0, "symmetric": True},
            ]
        ),

        # 西方系统
        "Patriot str": make_pattern_lua_sync(1.1, "aesa", "Patriot str (AN/MPQ-53/65)"),
        "Hawk tr": make_custom_pattern(                     # Hawk tracking radar (4deg spacing, 7dB attenuation)
            name="Hawk tr (HPIR) - 4deg spacing",
            HPBW_deg=1.5,
            floor_db=-25,
            sidelobes=[
                {"angle_deg": 4, "amplitude_db": -10, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 8, "amplitude_db": -17, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 12, "amplitude_db": -24, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 16, "amplitude_db": -31, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 20, "amplitude_db": -38, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 24, "amplitude_db": -45, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 28, "amplitude_db": -52, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 32, "amplitude_db": -59, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 36, "amplitude_db": -66, "width_deg": 1.5, "symmetric": True},
                {"angle_deg": 40, "amplitude_db": -73, "width_deg": 1.5, "symmetric": True},
            ]
        ),
        "Hawk sr": make_custom_pattern(                     # Hawk search radar (5deg spacing, 4dB attenuation)
            name="Hawk sr (PAR) - 5deg spacing",
            HPBW_deg=3.5,
            floor_db=-20,
            sidelobes=[
                {"angle_deg": 5, "amplitude_db": -5, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 10, "amplitude_db": -9, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 15, "amplitude_db": -13, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 20, "amplitude_db": -17, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 25, "amplitude_db": -21, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -25, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 35, "amplitude_db": -29, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 40, "amplitude_db": -33, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 45, "amplitude_db": -37, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 50, "amplitude_db": -41, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 55, "amplitude_db": -45, "width_deg": 3.5, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -49, "width_deg": 3.5, "symmetric": True},
            ]
        ),
        "Roland ADS": make_pattern_lua_sync(2.0, "mid", "Roland ADS"),

        # 自行防空
        "Tunguska_2S6": make_pattern_lua_sync(2.0, "mid", "Tunguska_2S6 (1RL144)"),
        "Gepard": make_custom_pattern(                     # German SPAAG system (6deg spacing, 6dB attenuation)
            name="Gepard (German SPAAG) - 6deg spacing",
            HPBW_deg=3.0,
            floor_db=-20,
            sidelobes=[
                {"angle_deg": 6, "amplitude_db": -5, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 12, "amplitude_db": -11, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 18, "amplitude_db": -17, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 24, "amplitude_db": -23, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -29, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 36, "amplitude_db": -35, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 42, "amplitude_db": -41, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 48, "amplitude_db": -47, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 54, "amplitude_db": -53, "width_deg": 3.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -59, "width_deg": 3.0, "symmetric": True},
            ]
        ),
        "ZSU-23-4 Shilka": make_pattern_lua_sync(4.0, "early", "ZSU-23-4 Shilka (Gun Dish)"),

        # 注意：别名雷达已移除以避免重复图片生成
    }

def save_pattern_json(pattern: Pattern, path: str) -> None:
    """Save pattern to JSON file for use in other tools"""
    with open(path, "w", encoding="utf-8") as f:
        data = {
            "name": pattern.name,
            "HPBW_deg": pattern.HPBW_deg,
            "category": pattern.category,
            "floor": pattern.floor,
            "normalize": pattern.normalize,
            "lobes": [asdict(l) for l in pattern.lobes],
        }
        json.dump(data, f, ensure_ascii=False, indent=2)

def load_pattern_json(path: str) -> Pattern:
    """Load pattern from JSON file"""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    lobes = [Lobe(**l) for l in data["lobes"]]
    return Pattern(
        name=data.get("name", "CustomPattern"),
        HPBW_deg=data.get("HPBW_deg", 1.0),
        category=data.get("category", "mid"),
        lobes=lobes,
        floor=float(data.get("floor", 0.001)),
        normalize=bool(data.get("normalize", False)),
    )

def plot_cartesian(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    """Plot Cartesian gain pattern in dB"""
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)

    # Convert to dB (avoid log(0)) - use 10*log10 for power gain
    gain_db = 10 * np.log10(np.maximum(gain, 1e-10))

    plt.figure(figsize=(10, 6))
    plt.plot(theta, gain_db, linewidth=2)
    plt.xlabel("Angle off boresight (deg)")
    plt.ylabel("Gain (dB)")
    plt.title(f"{pattern.name}\nLua Script Synchronized - Category: {pattern.category}")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5, alpha=0.7)

    # Set dB range for radar patterns
    plt.ylim(-40, 5)

    # Add reference lines
    plt.axhline(y=0, color='k', linestyle='-', alpha=0.8, label='0dB (Peak)')
    plt.axhline(y=-3, color='r', linestyle='--', alpha=0.7, label='-3dB (HPBW)')
    plt.axhline(y=-10, color='orange', linestyle='--', alpha=0.7, label='-10dB')
    plt.axhline(y=-20, color='g', linestyle='--', alpha=0.7, label='-20dB')

    # Mark sidelobe levels
    if pattern.category == "aesa":
        plt.axhline(y=-15, color='purple', linestyle=':', alpha=0.7, label='First Sidelobe')
    elif pattern.category == "mid":
        plt.axhline(y=-10, color='purple', linestyle=':', alpha=0.7, label='First Sidelobe')
    elif pattern.category == "early":
        plt.axhline(y=-5, color='purple', linestyle=':', alpha=0.7, label='First Sidelobe')

    plt.legend(loc='upper right')
    plt.tight_layout()
    plt.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close()

def plot_polar(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    """Plot polar gain pattern"""
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)

    # Convert to dB for display scaling - use 10*log10 for power gain
    gain_db = 10 * np.log10(np.maximum(gain, 1e-10))

    # For polar plot, convert to display amplitude (0-1 range)
    # Map -30dB to 0, 0dB to 1
    gain_display = np.maximum((gain_db + 30) / 30, 0)

    # Map angles to radians [0, 2π)
    theta_wrapped = np.radians((theta + 360.0) % 360.0)

    plt.figure(figsize=(10, 10))
    ax = plt.subplot(111, projection="polar")
    ax.plot(theta_wrapped, gain_display, linewidth=2)
    ax.set_title(f"{pattern.name}\nPolar Pattern (Lua Synchronized)", va='bottom', pad=30)

    # Set radial ticks and labels (dB scale)
    radial_ticks = [0.0, 0.33, 0.67, 1.0]
    radial_labels = ['-30dB', '-20dB', '-10dB', '0dB']
    ax.set_rticks(radial_ticks)
    ax.set_yticklabels(radial_labels)

    # Set angular ticks
    ax.set_xticks(np.radians([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]))
    ax.set_xticklabels(['0°', '30°', '60°', '90°', '120°', '150°', '180°', '210°', '240°', '270°', '300°', '330°'])

    # Set radial range
    ax.set_ylim(0, 1.1)

    # Add category info
    ax.text(0.02, 0.98, f"Category: {pattern.category}\nHPBW: {pattern.HPBW_deg:.1f}°",
            transform=ax.transAxes, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    plt.tight_layout()
    plt.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close()

def plot_polar_dynamic_center(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    """Plot polar gain pattern with dynamic center (floor at center)"""
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)

    # Convert to dB for display scaling - use 10*log10 for power gain
    gain_db = 10 * np.log10(np.maximum(gain, 1e-10))

    # Dynamic center: floor_db at center, 0dB at edge
    floor_db = 10 * np.log10(pattern.floor)
    dynamic_range = -floor_db  # 从floor到0dB的范围

    # Map floor_db to 0, 0dB to 1
    gain_display = np.maximum((gain_db - floor_db) / dynamic_range, 0)

    # Map angles to radians [0, 2π)
    theta_wrapped = np.radians((theta + 360.0) % 360.0)

    plt.figure(figsize=(10, 10))
    ax = plt.subplot(111, projection="polar")
    ax.plot(theta_wrapped, gain_display, linewidth=2)
    ax.set_title(f"{pattern.name}\nPolar Pattern (Dynamic Center)", va='bottom', pad=30)

    # Set radial ticks and labels (dynamic dB scale)
    radial_ticks = [0.0, 0.25, 0.5, 0.75, 1.0]
    db_values = [floor_db, floor_db + 0.25*dynamic_range, floor_db + 0.5*dynamic_range,
                 floor_db + 0.75*dynamic_range, 0]
    radial_labels = [f'{db:.0f}dB' for db in db_values]
    ax.set_rticks(radial_ticks)
    ax.set_yticklabels(radial_labels)

    # Set angular ticks
    ax.set_xticks(np.radians([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]))
    ax.set_xticklabels(['0°', '30°', '60°', '90°', '120°', '150°', '180°', '210°', '240°', '270°', '300°', '330°'])

    # Set radial range
    ax.set_ylim(0, 1.1)

    # Add category info
    ax.text(0.02, 0.98, f"Category: {pattern.category}\nHPBW: {pattern.HPBW_deg:.1f}°\nFloor: {floor_db:.0f}dB",
            transform=ax.transAxes, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    plt.tight_layout()
    plt.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close()

def plot_jamming_effectiveness_polar(radar_name: str, outfile: str,
                                     jammer_mode: str = "spot",
                                     range_radar_target_km: float = 37,  # 20nm for escort jamming
                                     max_range_km: float = 200) -> None:
    """
    绘制干扰效果极坐标图 (Escort Jamming Scenario)
    显示在不同角度下，达到50%干扰概率所需的干扰器距离
    目标飞机距离雷达固定为20nm，干扰器距离为变量
    """
    pattern = get_radar_pattern(radar_name)
    if pattern is None:
        print(f"Radar not found: {radar_name}")
        return

    # 角度范围：-180到180度
    theta_deg = np.arange(-180, 181, 2, dtype=float)
    jamming_ranges_km = []

    print(f"Computing jamming effectiveness analysis for {radar_name}...")

    for theta in theta_deg:
        range_km = compute_jamming_range_for_probability(
            radar_name, theta,
            target_prob=JAMMING_CONFIG["TARGET_JAM_PROB"],
            jammer_mode=jammer_mode,
            range_radar_target_km=range_radar_target_km
        )
        # Limit maximum display range
        range_km = min(range_km, max_range_km)
        jamming_ranges_km.append(range_km)

    jamming_ranges_km = np.array(jamming_ranges_km)

    # 转换为显示范围 (0-1)
    range_display = jamming_ranges_km / max_range_km

    # 转换角度为弧度
    theta_wrapped = np.radians((theta_deg + 360.0) % 360.0)

    plt.figure(figsize=(12, 12))
    ax = plt.subplot(111, projection="polar")
    ax.plot(theta_wrapped, range_display, linewidth=2, color='red')
    ax.fill(theta_wrapped, range_display, alpha=0.3, color='red')

    # Title
    jammer_power = JAMMING_CONFIG["JAMMER_MODES"][jammer_mode]
    ax.set_title(f"{radar_name}\nJamming Effectiveness Analysis ({jammer_mode.title()} Mode: {jammer_power}dB)\nRange for 50% Jamming Probability",
                 va='bottom', pad=30)

    # 设置径向刻度 (距离)
    radial_ticks = [0.0, 0.25, 0.5, 0.75, 1.0]
    range_values = [0, max_range_km*0.25, max_range_km*0.5, max_range_km*0.75, max_range_km]
    radial_labels = [f'{r:.0f}km' for r in range_values]
    ax.set_rticks(radial_ticks)
    ax.set_yticklabels(radial_labels)

    # 设置角度刻度
    ax.set_xticks(np.radians([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]))
    ax.set_xticklabels(['0°', '30°', '60°', '90°', '120°', '150°', '180°', '210°', '240°', '270°', '300°', '330°'])

    # 设置径向范围
    ax.set_ylim(0, 1.1)

    # Add information text
    radar_power = JAMMING_CONFIG["RADAR_POWER"].get(radar_name, 35)
    info_text = f"Radar Power: {radar_power}dB\n"
    info_text += f"Jammer Mode: {jammer_mode.title()} ({jammer_power}dB)\n"
    info_text += f"Target Range: {range_radar_target_km}km\n"
    info_text += f"Jam Probability: {JAMMING_CONFIG['TARGET_JAM_PROB']*100:.0f}%"

    ax.text(0.02, 0.98, info_text,
            transform=ax.transAxes, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='yellow', alpha=0.8))

    # Add performance statistics
    min_range = np.min(jamming_ranges_km[jamming_ranges_km > 0])
    max_range = np.max(jamming_ranges_km[jamming_ranges_km < max_range_km])
    avg_range = np.mean(jamming_ranges_km[jamming_ranges_km < max_range_km])

    stats_text = f"Min Range: {min_range:.1f}km\n"
    stats_text += f"Max Range: {max_range:.1f}km\n"
    stats_text += f"Avg Range: {avg_range:.1f}km"

    ax.text(0.98, 0.02, stats_text,
            transform=ax.transAxes, verticalalignment='bottom', horizontalalignment='right',
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))

    plt.tight_layout()
    plt.savefig(outfile, dpi=150, bbox_inches='tight')
    plt.close()

    print(f"Jamming effectiveness plot saved: {outfile}")

def validate_design_targets() -> None:
    """Validate system meets design targets"""
    print("=== Validating Design Targets ===\n")

    for target_name, target in DESIGN_TARGETS.items():
        radar_name = target["radar"]
        mode = target["mode"]
        range_nm = target["range_nm"]
        angle = target["angle"]

        range_km = range_nm * JAMMING_CONFIG["NM_TO_KM"]

        # 计算该条件下的干扰概率
        pattern = get_radar_pattern(radar_name)
        if pattern is None:
            print(f"[FAIL] {target_name}: Radar not found {radar_name}")
            continue

        # 获取方向增益
        r_direction_linear = pattern.gain(np.array([angle]))[0]
        r_direction_db = lin_to_db(r_direction_linear)

        # 计算SNR和干扰概率 (escort jamming: target at fixed 20nm, jammer at variable distance)
        r_jammer_db = JAMMING_CONFIG["JAMMER_MODES"][mode]
        range_radar_target_km = 20 * JAMMING_CONFIG["NM_TO_KM"]  # Fixed target distance: 20nm
        jsr = compute_jsr_db(radar_name, r_direction_db, r_jammer_db, range_radar_target_km, range_km)
        jam_prob = jamming_probability_sigmoid(jsr)

        # 验证结果
        target_prob = JAMMING_CONFIG["TARGET_JAM_PROB"]
        success = abs(jam_prob - target_prob) < 0.1  # 10%容差

        status = "[PASS]" if success else "[FAIL]"
        print(f"{status} {target_name}:")
        print(f"   Radar: {radar_name}")
        print(f"   Mode: {mode} ({r_jammer_db}dB)")
        print(f"   Range: {range_nm}nm ({range_km:.1f}km)")
        print(f"   Angle: {angle}°")
        print(f"   Direction Gain: {r_direction_db:.1f}dB")
        print(f"   JSR: {jsr:.1f}dB")
        print(f"   Jam Probability: {jam_prob:.1%} (Target: {target_prob:.1%})")
        print()

def print_pattern_details(pattern: Pattern) -> None:
    """Print detailed pattern information for verification"""
    print(f"\n=== {pattern.name} ===")
    print(f"Category: {pattern.category}")
    print(f"HPBW: {pattern.HPBW_deg:.1f}°")
    print(f"Floor: {10*math.log10(pattern.floor):.1f} dB")
    print(f"Number of lobes: {len(pattern.lobes)}")
    print("\nLobe details:")
    for i, lobe in enumerate(pattern.lobes):
        lobe_db = 10 * math.log10(lobe.A) if lobe.A > 0 else -float('inf')
        if i == 0:
            print(f"  Main lobe: {lobe_db:+5.1f} dB at {lobe.mu_deg:+4.1f}° (σ={lobe.sigma_deg:.2f}°)")
        else:
            print(f"  Sidelobe {i}: {lobe_db:+5.1f} dB at {lobe.mu_deg:+4.1f}° (σ={lobe.sigma_deg:.2f}°)")

def main():
    parser = argparse.ArgumentParser(description="Radar gain pattern plotter - Lua script synchronized")
    parser.add_argument("--pattern", type=str, default=None,
                        help="Built-in pattern key (see --list). If not specified, generates all patterns.")
    parser.add_argument("--json", type=str, default=None,
                        help="Path to a JSON file defining a custom Pattern.")
    parser.add_argument("--theta-min", type=float, default=-90.0,
                        help="Minimum angle (deg) to plot (off-boresight).")
    parser.add_argument("--theta-max", type=float, default=90.0,
                        help="Maximum angle (deg) to plot (off-boresight).")
    parser.add_argument("--step", type=float, default=0.1,
                        help="Angular step (deg).")
    parser.add_argument("--out-prefix", type=str, default="lua_sync_radar",
                        help="Output file prefix.")
    parser.add_argument("--export-json", type=str, default=None,
                        help="Save the chosen pattern into a JSON file and exit.")
    parser.add_argument("--list", action="store_true", help="List built-in pattern keys and exit.")
    parser.add_argument("--details", action="store_true", help="Print detailed pattern information.")
    parser.add_argument("--jamming", action="store_true", help="Generate jamming effectiveness plots.")
    parser.add_argument("--jammer-mode", type=str, default="spot", choices=["broadcast", "sector", "spot"],
                        help="Jammer mode for effectiveness analysis.")
    parser.add_argument("--dynamic-center", action="store_true", help="Use dynamic center for polar plots.")
    parser.add_argument("--validate-targets", action="store_true", help="Validate design targets and exit.")
    args = parser.parse_args()

    patterns = builtin_patterns_lua_sync()

    # 验证设计目标
    if args.validate_targets:
        validate_design_targets()
        return

    if args.list:
        print("Built-in patterns (synchronized with Lua script):")
        for key, pattern in patterns.items():
            print(f" - {key:25s} | HPBW: {pattern.HPBW_deg:4.1f}° | Category: {pattern.category}")
        return

    # Single pattern processing
    if args.pattern:
        if args.pattern not in patterns:
            raise SystemExit(f"Unknown pattern '{args.pattern}'. Use --list to see available keys.")

        pat = patterns[args.pattern]

        if args.details:
            print_pattern_details(pat)

        if args.export_json:
            save_pattern_json(pat, args.export_json)
            print(f"Saved JSON: {args.export_json}")
            return

        cart_path = f"{args.out_prefix}_{args.pattern}_cart.png"

        # 选择极坐标图类型
        if args.dynamic_center:
            polar_path = f"{args.out_prefix}_{args.pattern}_polar_dynamic.png"
            plot_polar_dynamic_center(pat, args.theta_min, args.theta_max, args.step, polar_path)
        else:
            polar_path = f"{args.out_prefix}_{args.pattern}_polar.png"
            plot_polar(pat, args.theta_min, args.theta_max, args.step, polar_path)

        plot_cartesian(pat, args.theta_min, args.theta_max, args.step, cart_path)

        print(f"Generated plots for {args.pattern}:")
        print(f"  Cartesian: {cart_path}")
        print(f"  Polar: {polar_path}")

        # 生成干扰效果图
        if args.jamming:
            jam_path = f"{args.out_prefix}_{args.pattern}_jamming_{args.jammer_mode}.png"
            plot_jamming_effectiveness_polar(args.pattern, jam_path, args.jammer_mode)
            print(f"  Jamming: {jam_path}")

        if args.details:
            print_pattern_details(pat)
        return

    # JSON file processing
    if args.json:
        pat = load_pattern_json(args.json)
        if args.export_json:
            save_pattern_json(pat, args.export_json)
            print(f"Saved JSON: {args.export_json}")
            return

        cart_path = f"{args.out_prefix}_custom_cart.png"
        polar_path = f"{args.out_prefix}_custom_polar.png"

        plot_cartesian(pat, args.theta_min, args.theta_max, args.step, cart_path)
        plot_polar(pat, args.theta_min, args.theta_max, args.step, polar_path)

        print(f"Generated plots for custom pattern:")
        print(f"  Cartesian: {cart_path}")
        print(f"  Polar: {polar_path}")
        return

    # Generate all patterns
    print("Generating all radar gain patterns (Lua script synchronized)...")
    print(f"Angle range: {args.theta_min} to {args.theta_max} degrees")
    print(f"Angular step: {args.step} degrees")
    print("-" * 60)

    success_count = 0
    for pattern_name, pattern in patterns.items():
        print(f"Generating {pattern_name} ...")

        cart_path = f"{args.out_prefix}_{pattern_name}_cart.png"
        polar_path = f"{args.out_prefix}_{pattern_name}_polar.png"

        try:
            plot_cartesian(pattern, args.theta_min, args.theta_max, args.step, cart_path)
            plot_polar(pattern, args.theta_min, args.theta_max, args.step, polar_path)

            print(f"  [OK] Cartesian: {cart_path}")
            print(f"  [OK] Polar: {polar_path}")
            success_count += 1

            if args.details:
                print_pattern_details(pattern)

        except Exception as e:
            print(f"  [ERROR] Failed to generate {pattern_name}: {e}")

    print("-" * 60)
    print(f"Complete! Generated {success_count} radar patterns with {success_count * 2} plot files.")
    print("All parameters synchronized with Lua script.")

if __name__ == "__main__":
    main()