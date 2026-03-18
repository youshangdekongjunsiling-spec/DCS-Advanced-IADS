#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Plot multi-Gaussian radar antenna gain patterns and save figures.
- Model: G(theta) = sum_i A_i * exp( - (theta - mu_i)^2 / (2*sigma_i^2) ) + floor
- Angles in degrees; theta is off-boresight angle.
- Outputs: Cartesian and Polar plots (each in its own figure).
"""
import argparse
import json
import math
from dataclasses import dataclass, asdict
from typing import List, Dict
import numpy as np
import matplotlib.pyplot as plt

@dataclass
class Lobe:
    A: float          # amplitude (relative to main-lobe peak)
    mu_deg: float     # center angle (degrees, off-boresight)
    sigma_deg: float  # Gaussian width (degrees)

@dataclass
class Pattern:
    name: str
    lobes: List[Lobe]
    floor: float = 0.0
    normalize: bool = True  # normalize peak to 1.0 after floor + lobes

    def gain(self, theta_deg: np.ndarray) -> np.ndarray:
        """Compute relative gain vs angle in degrees."""
        theta = theta_deg.astype(float)
        total = np.zeros_like(theta, dtype=float)
        for l in self.lobes:
            # Convert to radians only to square? We keep degrees consistently.
            d = theta - l.mu_deg
            total += l.A * np.exp(-(d * d) / (2.0 * (l.sigma_deg ** 2)))
        total += float(self.floor)
        if self.normalize:
            peak = np.max(total)
            if peak > 0:
                total = total / peak
        return total

def db_to_lin(db_value: float) -> float:
    """Convert dB to linear power ratio"""
    return 10 ** (db_value / 10)

def make_pattern(hpbw_deg: float, category: str, name: str) -> Pattern:
    """
    根据新的配置创建雷达模式
    category: "aesa" (相控阵), "mid" (中代), "early" (早期)
    """
    # 类别配置
    category_config = {
        "aesa": {"A1": db_to_lin(-15), "drop_lin": db_to_lin(-4), "per_side": 3, "sigma_sl": 1.0, "floor": 0.002},
        "mid": {"A1": db_to_lin(-10), "drop_lin": db_to_lin(-4), "per_side": 11, "sigma_sl": 2.5, "floor": 0.010},
        "early": {"A1": db_to_lin(-5), "drop_lin": db_to_lin(-4), "per_side": 5, "sigma_sl": 6.0, "floor": 0.030},
    }
    
    cfg = category_config[category]
    sigma_main = hpbw_deg / 2.355
    A1, drop, N, sigma_sl = cfg["A1"], cfg["drop_lin"], cfg["per_side"], cfg["sigma_sl"]
    theta1 = max(1.5 * hpbw_deg, 2.0)
    dtheta = (90.0 - theta1) / N
    
    lobes = [Lobe(1.0, 0.0, sigma_main)]  # 主瓣
    
    A = A1
    for i in range(1, N + 1):
        theta = theta1 + (i - 1) * dtheta
        lobes.append(Lobe(A, theta, sigma_sl))
        lobes.append(Lobe(A, -theta, sigma_sl))
        A = A * drop
    
    # 类别名称映射
    category_names = {"aesa": "相控阵", "mid": "中代", "early": "早期"}
    
    return Pattern(
        name=f"{name} ({category_names[category]}) - HPBW={hpbw_deg:.1f}°",
        lobes=lobes,
        floor=cfg["floor"],
        normalize=False,
    )

# 雷达模式基于DCS实际雷达名称和新的配置系统
def builtin_patterns() -> Dict[str, Pattern]:
    return {
        # ===========================================================================
        # S-300 / SA-10 系 - 相控阵
        # ===========================================================================
        "S-300PS 40B6M tr": make_pattern(1.0, "aesa", "S-300PS 40B6M tr (30N6)"),
        "S-300PS 40B6MD sr": make_pattern(2.0, "aesa", "S-300PS 40B6MD sr (5N66/76N6)"),
        "S-300PS 64H6E sr": make_pattern(2.0, "aesa", "S-300PS 64H6E sr (64N6E Big Bird)"),
        
        # ===========================================================================
        # 早期/老式雷达
        # ===========================================================================
        "SNR_75V": make_pattern(7.5, "early", "SNR-75V (SA-2 Fan Song)"),
        "Kub STR": make_pattern(1.0, "early", "Kub STR (SA-6 Straight Flush)"),
        
        # ===========================================================================
        # 中代雷达
        # ===========================================================================
        "Tor 9A331": make_pattern(1.2, "mid", "Tor 9A331 (SA-15 Tor TTR)"),
        "Buk SR 9S18M1": make_pattern(4.0, "mid", "Buk SR 9S18M1 (SA-11 Snow Drift)"),
        "SA-11 Buk LN 9A310M1": make_pattern(1.2, "mid", "SA-11 Buk LN 9A310M1 (Fire Dome)"),
        "SA-17 Buk M1-2 LN": make_pattern(1.0, "mid", "SA-17 Buk M1-2 LN"),
        
        # ===========================================================================
        # 西方雷达
        # ===========================================================================
        "Roland ADS": make_pattern(2.0, "mid", "Roland ADS"),
        "Patriot str": make_pattern(1.1, "aesa", "Patriot str (MPQ-53/65)"),
        "Hawk tr": make_pattern(1.5, "mid", "Hawk tr (HPIR)"),
        "Hawk sr": make_pattern(3.5, "early", "Hawk sr (PAR)"),
        
        # ===========================================================================
        # 向后兼容的别名
        # ===========================================================================
        "SA-10_FlapLid": make_pattern(1.0, "aesa", "SA-10 FlapLid (Legacy)"),
        "Patriot_MPQ": make_pattern(1.1, "aesa", "Patriot MPQ (Legacy)"),
        "BigBird_64N6": make_pattern(2.0, "aesa", "BigBird 64N6 (Legacy)"),
        "SA-11_FireDome": make_pattern(1.2, "mid", "SA-11 Fire Dome (Legacy)"),
        "Tor_TTR": make_pattern(1.2, "mid", "Tor TTR (Legacy)"),
        "SA-17_Buk_M1": make_pattern(1.0, "mid", "SA-17 Buk M1 (Legacy)"),
        "Hawk_HPIR": make_pattern(1.5, "mid", "Hawk HPIR (Legacy)"),
        "Osa_LandRoll": make_pattern(1.5, "mid", "Osa Land Roll (Legacy)"),
        "SA-11_SnowDrift": make_pattern(4.0, "mid", "SA-11 Snow Drift (Legacy)"),
        "SA-6_StraightFlush": make_pattern(1.0, "early", "SA-6 Straight Flush (Legacy)"),
        "SNR_75_FanSong": make_pattern(7.5, "early", "SNR-75 Fan Song (Legacy)"),
        "P-19_FlatFace": make_pattern(4.5, "early", "P-19 Flat Face (Legacy)"),
        "P-37_BarLock": make_pattern(2.0, "early", "P-37 Bar Lock (Legacy)"),
        "ST68U_TinShield": make_pattern(6.5, "early", "ST-68U Tin Shield (Legacy)"),
        "1L13_Nebo": make_pattern(6.0, "early", "1L13 Nebo (Legacy)"),
        "Hawk_PAR": make_pattern(3.5, "early", "Hawk PAR (Legacy)"),
        "SA10_FlapLid": make_pattern(1.0, "aesa", "SA-10 FlapLid (Legacy2)"),
        "SA11_FireDome": make_pattern(1.2, "mid", "SA-11 Fire Dome (Legacy2)"),
        "SA6_StraightFlush": make_pattern(1.0, "early", "SA-6 Straight Flush (Legacy2)"),
        "SA8_LandRoll": make_pattern(1.5, "mid", "SA-8 Land Roll (Legacy2)"),
        "SA11_SnowDrift": make_pattern(4.0, "mid", "SA-11 Snow Drift (Legacy2)"),
        "P19_FlatFace": make_pattern(4.5, "early", "P-19 Flat Face (Legacy2)"),
        "P37_BarLock": make_pattern(2.0, "early", "P-37 Bar Lock (Legacy2)"),
    }

def save_pattern_json(pattern: Pattern, path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        data = {
            "name": pattern.name,
            "floor": pattern.floor,
            "normalize": pattern.normalize,
            "lobes": [asdict(l) for l in pattern.lobes],
        }
        json.dump(data, f, ensure_ascii=False, indent=2)

def load_pattern_json(path: str) -> Pattern:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    lobes = [Lobe(**l) for l in data["lobes"]]
    return Pattern(
        name=data.get("name", "CustomPattern"),
        lobes=lobes,
        floor=float(data.get("floor", 0.0)),
        normalize=bool(data.get("normalize", True)),
    )

def plot_cartesian(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)
    
    # 转换为dB
    gain_db = 20 * np.log10(np.maximum(gain, 1e-10))  # 避免log(0)
    
    plt.figure(figsize=(7,4.5))
    plt.plot(theta, gain_db)
    plt.xlabel("Angle off boresight (deg)")
    plt.ylabel("Gain (dB)")
    plt.title(f"{pattern.name} — Gain vs Angle")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    
    # 设置dB范围，通常雷达增益图显示-60dB到0dB
    plt.ylim(-60, 5)
    
    # 添加主要dB线
    plt.axhline(y=0, color='k', linestyle='-', alpha=0.3)
    plt.axhline(y=-3, color='r', linestyle='--', alpha=0.5, label='-3dB')
    plt.axhline(y=-10, color='orange', linestyle='--', alpha=0.5, label='-10dB')
    plt.axhline(y=-20, color='g', linestyle='--', alpha=0.5, label='-20dB')
    
    plt.legend()
    plt.tight_layout()
    plt.savefig(outfile, dpi=150)
    plt.close()

def plot_polar(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    # Polar expects radians from 0..2π. We'll map off-boresight to absolute angle around the dish.
    # For a symmetric view, convert theta in degrees to radians on [0, 2π) by mapping μ=0 to 0 rad direction.
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)

    # 转换为dB
    gain_db = 20 * np.log10(np.maximum(gain, 1e-10))  # 避免log(0)
    
    # 对于极坐标图，我们需要将dB转换为线性幅度用于显示
    # 但保持dB的数值范围
    gain_display = 10 ** (gain_db / 20)  # 转换回线性用于极坐标显示
    
    # Map [-180, 180] -> [0, 2π)
    theta_wrapped = np.radians((theta + 360.0) % 360.0)

    plt.figure(figsize=(8,8))
    ax = plt.subplot(111, projection="polar")
    ax.plot(theta_wrapped, gain_display)
    ax.set_title(f"{pattern.name} — Polar Gain Pattern", va='bottom', pad=20)
    
    # 设置径向刻度标签为dB
    ax.set_rticks([0.1, 0.2, 0.3, 0.5, 0.7, 1.0])
    ax.set_yticklabels(['-20dB', '-14dB', '-10dB', '-6dB', '-3dB', '0dB'])
    
    # 设置角度刻度
    ax.set_xticks(np.radians([0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]))
    ax.set_xticklabels(['0°', '30°', '60°', '90°', '120°', '150°', '180°', '210°', '240°', '270°', '300°', '330°'])
    
    # 设置径向范围
    ax.set_ylim(0, 1.1)
    
    plt.tight_layout()
    plt.savefig(outfile, dpi=150)
    plt.close()

def main():
    parser = argparse.ArgumentParser(description="Plot multi-Gaussian radar gain patterns and save figures.")
    parser.add_argument("--pattern", type=str, default=None,
                        help="Built-in pattern key (see --list). If not specified, generates all patterns.")
    parser.add_argument("--json", type=str, default=None,
                        help="Path to a JSON file defining a custom Pattern.")
    parser.add_argument("--theta-min", type=float, default=-90.0,
                        help="Minimum angle (deg) to plot (off-boresight).")
    parser.add_argument("--theta-max", type=float, default=90.0,
                        help="Maximum angle (deg) to plot (off-boresight).")
    parser.add_argument("--step", type=float, default=0.05,
                        help="Angular step (deg).")
    parser.add_argument("--out-prefix", type=str, default="radar_gain",
                        help="Output file prefix (e.g., 'gain' -> 'gain_cart.png', 'gain_polar.png').")
    parser.add_argument("--export-json", type=str, default=None,
                        help="Save the chosen built-in pattern into a JSON file and exit.")
    parser.add_argument("--list", action="store_true", help="List built-in pattern keys and exit.")
    parser.add_argument("--all", action="store_true", help="Generate plots for all radar patterns.")
    args = parser.parse_args()

    patterns = builtin_patterns()

    if args.list:
        print("Built-in patterns:")
        for key in patterns.keys():
            print(" -", key)
        return

    # 如果指定了JSON文件，处理单个模式
    if args.json:
        pat = load_pattern_json(args.json)
        if args.export_json:
            save_pattern_json(pat, args.export_json)
            print(f"Saved JSON: {args.export_json}")
            return

        cart_path = f"{args.out_prefix}_cart.png"
        polar_path = f"{args.out_prefix}_polar.png"

        plot_cartesian(pat, args.theta_min, args.theta_max, args.step, cart_path)
        plot_polar(pat, args.theta_min, args.theta_max, args.step, polar_path)

        print(f"Saved: {cart_path}")
        print(f"Saved: {polar_path}")
        return

    # 如果指定了单个模式
    if args.pattern:
        if args.pattern not in patterns:
            raise SystemExit(f"Unknown pattern '{args.pattern}'. Use --list to see available keys.")
        
        pat = patterns[args.pattern]
        
        if args.export_json:
            save_pattern_json(pat, args.export_json)
            print(f"Saved JSON: {args.export_json}")
            return

        cart_path = f"{args.out_prefix}_{args.pattern}_cart.png"
        polar_path = f"{args.out_prefix}_{args.pattern}_polar.png"

        plot_cartesian(pat, args.theta_min, args.theta_max, args.step, cart_path)
        plot_polar(pat, args.theta_min, args.theta_max, args.step, polar_path)

        print(f"Saved: {cart_path}")
        print(f"Saved: {polar_path}")
        return

    # 默认行为：生成所有雷达模式的图表
    print("生成所有雷达模式的增益图...")
    print(f"角度范围: {args.theta_min}° 到 {args.theta_max}°")
    print(f"角度步长: {args.step}°")
    print("-" * 50)
    
    for pattern_name, pattern in patterns.items():
        print(f"正在生成 {pattern_name} 的增益图...")
        
        cart_path = f"{args.out_prefix}_{pattern_name}_cart.png"
        polar_path = f"{args.out_prefix}_{pattern_name}_polar.png"

        try:
            plot_cartesian(pattern, args.theta_min, args.theta_max, args.step, cart_path)
            plot_polar(pattern, args.theta_min, args.theta_max, args.step, polar_path)
            
            print(f"  ✓ 笛卡尔图: {cart_path}")
            print(f"  ✓ 极坐标图: {polar_path}")
        except Exception as e:
            print(f"  ✗ 生成 {pattern_name} 时出错: {e}")
    
    print("-" * 50)
    print(f"完成！共生成了 {len(patterns)} 个雷达模式的 {len(patterns) * 2} 个图表文件。")

if __name__ == "__main__":
    main()
