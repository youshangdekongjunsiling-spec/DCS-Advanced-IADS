#!/usr/bin/env python3
"""
Main research entry for the EA-18G jamming model.

This file is the single Python entry point for the research layer.
It wraps the existing synchronized radar/JSR backend and exposes:

1. A single-shot jamming probability simulation.
2. A distance sweep simulation.
3. A stable place to add future research parameters before migrating
   anything into the runtime Lua script.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional


ROOT_DIR = Path(__file__).resolve().parent
BACKEND_PATH = ROOT_DIR / "Jammer parameters" / "Rader_polar_plot_lua_sync.py"


def load_backend():
    spec = importlib.util.spec_from_file_location("jammer_research_backend", BACKEND_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load backend module: {BACKEND_PATH}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


BACKEND = load_backend()


@dataclass
class ScenarioInput:
    radar_name: str
    jammer_mode: str = "spot"
    theta_deg: float = 10.0
    range_jammer_radar_km: float = 55.0
    range_radar_target_km: float = 37.0
    jammer_altitude_m: float = 8000.0
    jammer_extra_gain_db: float = 0.0
    altitude_bonus_per_10km_db: float = 0.0
    altitude_bonus_cap_db: float = 0.0
    los_ok: bool = True
    sigmoid_k: Optional[float] = None


@dataclass
class ScenarioResult:
    radar_name: str
    jammer_mode: str
    theta_deg: float
    range_jammer_radar_km: float
    range_radar_target_km: float
    jammer_altitude_m: float
    los_ok: bool
    jammer_mode_power_db: float
    jammer_extra_gain_db: float
    altitude_bonus_db: float
    effective_jammer_power_db: float
    radar_direction_gain_db: float
    jsr_db: float
    jam_probability: float


def get_available_radars() -> List[str]:
    patterns = BACKEND.builtin_patterns_lua_sync()
    return sorted(patterns.keys())


def get_available_modes() -> List[str]:
    return sorted(BACKEND.JAMMING_CONFIG["JAMMER_MODES"].keys())


def compute_altitude_bonus_db(
    jammer_altitude_m: float,
    altitude_bonus_per_10km_db: float,
    altitude_bonus_cap_db: float,
) -> float:
    if jammer_altitude_m <= 0 or altitude_bonus_per_10km_db <= 0:
        return 0.0

    raw_bonus = (jammer_altitude_m / 10000.0) * altitude_bonus_per_10km_db
    if altitude_bonus_cap_db > 0:
        return min(raw_bonus, altitude_bonus_cap_db)
    return raw_bonus


def simulate_jamming_probability(scenario: ScenarioInput) -> ScenarioResult:
    if scenario.radar_name not in get_available_radars():
        raise ValueError(f"Unknown radar: {scenario.radar_name}")

    if scenario.jammer_mode not in get_available_modes():
        raise ValueError(f"Unknown jammer mode: {scenario.jammer_mode}")

    if scenario.range_jammer_radar_km <= 0:
        raise ValueError("range_jammer_radar_km must be > 0")

    if scenario.range_radar_target_km <= 0:
        raise ValueError("range_radar_target_km must be > 0")

    pattern = BACKEND.get_radar_pattern(scenario.radar_name)
    if pattern is None:
        raise ValueError(f"Radar pattern not found: {scenario.radar_name}")

    radar_direction_gain_linear = pattern.gain(BACKEND.np.array([scenario.theta_deg]))[0]
    radar_direction_gain_db = float(BACKEND.lin_to_db(radar_direction_gain_linear))

    jammer_mode_power_db = float(BACKEND.JAMMING_CONFIG["JAMMER_MODES"][scenario.jammer_mode])
    altitude_bonus_db = compute_altitude_bonus_db(
        scenario.jammer_altitude_m,
        scenario.altitude_bonus_per_10km_db,
        scenario.altitude_bonus_cap_db,
    )
    effective_jammer_power_db = jammer_mode_power_db + scenario.jammer_extra_gain_db + altitude_bonus_db

    jsr_db = float(
        BACKEND.compute_jsr_db(
            scenario.radar_name,
            radar_direction_gain_db,
            effective_jammer_power_db,
            scenario.range_radar_target_km,
            scenario.range_jammer_radar_km,
        )
    )

    if scenario.los_ok:
        jam_probability = float(BACKEND.jamming_probability_sigmoid(jsr_db, scenario.sigmoid_k))
    else:
        jam_probability = 0.0

    return ScenarioResult(
        radar_name=scenario.radar_name,
        jammer_mode=scenario.jammer_mode,
        theta_deg=scenario.theta_deg,
        range_jammer_radar_km=scenario.range_jammer_radar_km,
        range_radar_target_km=scenario.range_radar_target_km,
        jammer_altitude_m=scenario.jammer_altitude_m,
        los_ok=scenario.los_ok,
        jammer_mode_power_db=jammer_mode_power_db,
        jammer_extra_gain_db=scenario.jammer_extra_gain_db,
        altitude_bonus_db=altitude_bonus_db,
        effective_jammer_power_db=effective_jammer_power_db,
        radar_direction_gain_db=radar_direction_gain_db,
        jsr_db=jsr_db,
        jam_probability=jam_probability,
    )


def simulate_distance_sweep(
    scenario: ScenarioInput,
    range_from_km: float,
    range_to_km: float,
    range_step_km: float,
) -> List[ScenarioResult]:
    if range_step_km <= 0:
        raise ValueError("range_step_km must be > 0")
    if range_to_km < range_from_km:
        raise ValueError("range_to_km must be >= range_from_km")

    results: List[ScenarioResult] = []
    current = range_from_km
    while current <= range_to_km + 1e-9:
        sweep_input = ScenarioInput(
            radar_name=scenario.radar_name,
            jammer_mode=scenario.jammer_mode,
            theta_deg=scenario.theta_deg,
            range_jammer_radar_km=current,
            range_radar_target_km=scenario.range_radar_target_km,
            jammer_altitude_m=scenario.jammer_altitude_m,
            jammer_extra_gain_db=scenario.jammer_extra_gain_db,
            altitude_bonus_per_10km_db=scenario.altitude_bonus_per_10km_db,
            altitude_bonus_cap_db=scenario.altitude_bonus_cap_db,
            los_ok=scenario.los_ok,
            sigmoid_k=scenario.sigmoid_k,
        )
        results.append(simulate_jamming_probability(sweep_input))
        current += range_step_km
    return results


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Main research entry for the EA-18G jamming model."
    )
    parser.add_argument("--list-radars", action="store_true", help="List all supported radar models.")
    parser.add_argument("--list-modes", action="store_true", help="List jammer mode presets.")
    parser.add_argument("--json-output", action="store_true", help="Print results as JSON.")

    parser.add_argument("--radar-name", type=str, default="S-300PS 40B6M tr")
    parser.add_argument("--jammer-mode", type=str, default="spot")
    parser.add_argument("--theta-deg", type=float, default=10.0)
    parser.add_argument("--jammer-range-km", type=float, default=55.0)
    parser.add_argument("--target-range-km", type=float, default=37.0)
    parser.add_argument("--jammer-altitude-m", type=float, default=8000.0)
    parser.add_argument("--jammer-extra-gain-db", type=float, default=0.0)
    parser.add_argument("--altitude-bonus-per-10km-db", type=float, default=0.0)
    parser.add_argument("--altitude-bonus-cap-db", type=float, default=0.0)
    parser.add_argument("--sigmoid-k", type=float, default=None)

    parser.add_argument("--no-los", action="store_true", help="Force no line of sight.")
    parser.add_argument("--sweep-from-km", type=float, default=None)
    parser.add_argument("--sweep-to-km", type=float, default=None)
    parser.add_argument("--sweep-step-km", type=float, default=5.0)
    return parser


def print_result_text(result: ScenarioResult) -> None:
    print(f"Radar: {result.radar_name}")
    print(f"Mode: {result.jammer_mode}")
    print(f"Off-boresight Angle: {result.theta_deg:.2f} deg")
    print(f"Jammer -> Radar Range: {result.range_jammer_radar_km:.2f} km")
    print(f"Radar -> Target Range: {result.range_radar_target_km:.2f} km")
    print(f"Jammer Altitude: {result.jammer_altitude_m:.0f} m")
    print(f"LOS: {'yes' if result.los_ok else 'no'}")
    print(f"Mode Power: {result.jammer_mode_power_db:.2f} dB")
    print(f"Extra Gain: {result.jammer_extra_gain_db:.2f} dB")
    print(f"Altitude Bonus: {result.altitude_bonus_db:.2f} dB")
    print(f"Effective Jammer Power: {result.effective_jammer_power_db:.2f} dB")
    print(f"Radar Direction Gain: {result.radar_direction_gain_db:.2f} dB")
    print(f"JSR: {result.jsr_db:.2f} dB")
    print(f"Jam Probability: {result.jam_probability:.4f}")


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.list_radars:
        for radar_name in get_available_radars():
            print(radar_name)
        return

    if args.list_modes:
        for mode_name in get_available_modes():
            print(mode_name)
        return

    scenario = ScenarioInput(
        radar_name=args.radar_name,
        jammer_mode=args.jammer_mode,
        theta_deg=args.theta_deg,
        range_jammer_radar_km=args.jammer_range_km,
        range_radar_target_km=args.target_range_km,
        jammer_altitude_m=args.jammer_altitude_m,
        jammer_extra_gain_db=args.jammer_extra_gain_db,
        altitude_bonus_per_10km_db=args.altitude_bonus_per_10km_db,
        altitude_bonus_cap_db=args.altitude_bonus_cap_db,
        los_ok=not args.no_los,
        sigmoid_k=args.sigmoid_k,
    )

    if args.sweep_from_km is not None or args.sweep_to_km is not None:
        if args.sweep_from_km is None or args.sweep_to_km is None:
            raise SystemExit("Both --sweep-from-km and --sweep-to-km are required for sweep mode.")

        results = simulate_distance_sweep(
            scenario,
            args.sweep_from_km,
            args.sweep_to_km,
            args.sweep_step_km,
        )
        if args.json_output:
            print(json.dumps([asdict(result) for result in results], indent=2, ensure_ascii=False))
        else:
            for result in results:
                print_result_text(result)
                print("-" * 40)
        return

    result = simulate_jamming_probability(scenario)
    if args.json_output:
        print(json.dumps(asdict(result), indent=2, ensure_ascii=False))
    else:
        print_result_text(result)


if __name__ == "__main__":
    main()
