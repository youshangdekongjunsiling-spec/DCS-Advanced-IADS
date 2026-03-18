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

def create_radar_pattern_systematic(hpbw_base: float, category: str, name: str) -> Pattern:
    """
    根据系统性分类创建雷达模式
    category: "aesa" (相控阵), "mid" (中代), "early" (早期)
    """
    # 计算有效HPBW (加宽1.4倍)
    hpbw_eff = 1.4 * hpbw_base
    sigma = hpbw_eff / 2.355
    sigma_sl = 0.8 * sigma
    
    # 旁瓣位置
    t1, t2, t3 = 1.5 * hpbw_eff, 3.0 * hpbw_eff, 4.5 * hpbw_eff
    
    # 根据类别设置旁瓣幅度和基底噪声
    if category == "aesa":
        A1, A2, A3 = 0.05, 0.035, 0.0245  # 相控阵：低旁瓣
        floor = 0.003
        category_name = "相控阵"
    elif category == "mid":
        A1, A2, A3 = 0.10, 0.07, 0.049    # 中代：中等旁瓣
        floor = 0.01
        category_name = "中代"
    elif category == "early":
        A1, A2, A3 = 0.25, 0.175, 0.1225  # 早期：高旁瓣
        floor = 0.02
        category_name = "早期"
    else:
        raise ValueError(f"Unknown category: {category}")
    
    lobes = [
        Lobe(1.0, 0.0, sigma),           # 主瓣
        Lobe(A1, t1, sigma_sl),          # 第一旁瓣
        Lobe(A1, -t1, sigma_sl),
        Lobe(A2, t2, sigma_sl),          # 第二旁瓣
        Lobe(A2, -t2, sigma_sl),
        Lobe(A3, t3, sigma_sl),          # 第三旁瓣
        Lobe(A3, -t3, sigma_sl),
    ]
    
    return Pattern(
        name=f"{name} ({category_name}) - HPBW={hpbw_eff:.1f}°",
        lobes=lobes,
        floor=floor,
        normalize=False,
    )

# 雷达模式基于系统性技术规格分类
def builtin_patterns() -> Dict[str, Pattern]:
    return {
        # ===========================================================================
        # 相控阵 / 现代FCR（第一旁瓣≥5%）：SA-10 30N6, Patriot MPQ-53/65, 64N6E 等
        # ===========================================================================
        
        "SA-10_FlapLid": create_radar_pattern_systematic(1.0, "aesa", "SA-10 FlapLid (30N6)"),
        
        "Patriot_MPQ": create_radar_pattern_systematic(1.1, "aesa", "Patriot MPQ (AN/MPQ-53/65)"),
        
        "BigBird_64N6": create_radar_pattern_systematic(2.0, "aesa", "BigBird 64N6"),
        
        # ===========================================================================
        # 中代FCR / 跟踪雷达（第一旁瓣≥10%）：SA-11 Fire Dome, SA-15 Tor, SA-17 Buk,
        #                               Hawk HPIR, Osa Land Roll(跟踪/指示), Snow Drift(指配)
        # ===========================================================================
        
        "SA-11_FireDome": create_radar_pattern_systematic(1.2, "mid", "SA-11 Fire Dome (9S35)"),
        
        "Tor_TTR": create_radar_pattern_systematic(1.2, "mid", "Tor TTR"),
        
        "SA-17_Buk_M1": create_radar_pattern_systematic(1.0, "mid", "SA-17 Buk M1"),
        
        "Hawk_HPIR": create_radar_pattern_systematic(1.5, "mid", "Hawk HPIR"),
        
        "Osa_LandRoll": create_radar_pattern_systematic(1.5, "mid", "Osa Land Roll"),
        
        "SA-11_SnowDrift": create_radar_pattern_systematic(4.0, "mid", "SA-11 Snow Drift (9S18M)"),
        
        # ===========================================================================
        # 早期 / 老式搜索/跟踪/EWR（第一旁瓣≥25%）：SA-6 1S91、SNR-75、P-19、P-37、ST-68U、1L13、Hawk PAR
        # ===========================================================================
        
        "SA-6_StraightFlush": create_radar_pattern_systematic(1.0, "early", "SA-6 Straight Flush (1S91)"),
        
        "SNR_75_FanSong": create_radar_pattern_systematic(7.5, "early", "SNR-75 Fan Song (SA-2)"),
        
        "P-19_FlatFace": create_radar_pattern_systematic(4.5, "early", "P-19 Flat Face"),
        
        "P-37_BarLock": create_radar_pattern_systematic(2.0, "early", "P-37 Bar Lock"),
        
        "ST68U_TinShield": create_radar_pattern_systematic(6.5, "early", "ST-68U Tin Shield"),
        
        "1L13_Nebo": create_radar_pattern_systematic(6.0, "early", "1L13 Nebo"),
        
        "Hawk_PAR": create_radar_pattern_systematic(3.5, "early", "Hawk PAR"),
        
        # 向后兼容的别名
        "SA10_FlapLid": create_radar_pattern_systematic(1.0, "aesa", "SA-10 FlapLid (Legacy)"),
        "SA11_FireDome": create_radar_pattern_systematic(1.2, "mid", "SA-11 Fire Dome (Legacy)"),
        "SA6_StraightFlush": create_radar_pattern_systematic(1.0, "early", "SA-6 Straight Flush (Legacy)"),
        "SA8_LandRoll": create_radar_pattern_systematic(1.5, "mid", "SA-8 Land Roll (Legacy)"),
        "SA11_SnowDrift": create_radar_pattern_systematic(4.0, "mid", "SA-11 Snow Drift (Legacy)"),
        "P19_FlatFace": create_radar_pattern_systematic(4.5, "early", "P-19 Flat Face (Legacy)"),
        "P37_BarLock": create_radar_pattern_systematic(2.0, "early", "P-37 Bar Lock (Legacy)"),
        "BigBird_64N6": create_radar_pattern_systematic(2.0, "aesa", "BigBird 64N6 (Legacy)"),
        "ST68U_TinShield": create_radar_pattern_systematic(6.5, "early", "ST-68U Tin Shield (Legacy)"),
        "1L13_Nebo": create_radar_pattern_systematic(6.0, "early", "1L13 Nebo (Legacy)"),
        "Hawk_PAR": create_radar_pattern_systematic(3.5, "early", "Hawk PAR (Legacy)"),
        "Patriot_MPQ": create_radar_pattern_systematic(1.1, "aesa", "Patriot MPQ (Legacy)"),
        "Hawk_HPIR": create_radar_pattern_systematic(1.5, "mid", "Hawk HPIR (Legacy)"),
        "SA-17_Buk_M1": create_radar_pattern_systematic(1.0, "mid", "SA-17 Buk M1 (Legacy)"),
        "SNR_75_FanSong": create_radar_pattern_systematic(7.5, "early", "SNR-75 Fan Song (Legacy)"),
        "Tor_TTR": create_radar_pattern_systematic(1.2, "mid", "Tor TTR (Legacy)"),
        "Osa_LandRoll": create_radar_pattern_systematic(1.5, "mid", "Osa Land Roll (Legacy)"),
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
    plt.figure(figsize=(7,4.5))
    plt.plot(theta, gain)
    plt.xlabel("Angle off boresight (deg)")
    plt.ylabel("Relative gain (normalized)")
    plt.title(f"{pattern.name} — Gain vs Angle")
    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.tight_layout()
    plt.savefig(outfile, dpi=150)
    plt.close()

def plot_polar(pattern: Pattern, theta_min: float, theta_max: float, step: float, outfile: str) -> None:
    # Polar expects radians from 0..2π. We'll map off-boresight to absolute angle around the dish.
    # For a symmetric view, convert theta in degrees to radians on [0, 2π) by mapping μ=0 to 0 rad direction.
    theta = np.arange(theta_min, theta_max + step, step, dtype=float)
    gain = pattern.gain(theta)

    # Map [-180, 180] -> [0, 2π)
    theta_wrapped = np.radians((theta + 360.0) % 360.0)

    plt.figure(figsize=(6,6))
    ax = plt.subplot(111, projection="polar")
    ax.plot(theta_wrapped, gain)
    ax.set_title(f"{pattern.name} — Polar Gain", va='bottom')
    # Optional: set 0° to the right (default), increasing CCW.
    # Keep defaults per instructions (no specific styles/colors).
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
