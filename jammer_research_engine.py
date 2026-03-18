#!/usr/bin/env python3
"""
Shared simulation engine for the jammer research layer.
"""

from __future__ import annotations

import importlib.util
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

from jammer_research_catalog import (
    RadarMappingCandidate,
    TemplateProfile,
    build_mapping_lookup,
    build_template_lookup,
)


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
TEMPLATE_LOOKUP = build_template_lookup()
RADAR_MAPPING_LOOKUP = build_mapping_lookup()


JAMMER_PROFILES = {
    "EA-18G strongest default": {"extra_gain_db": 0.0},
    "EA-18G conservative": {"extra_gain_db": -3.0},
    "EA-18G boosted": {"extra_gain_db": 3.0},
    "Custom": {"extra_gain_db": 0.0},
}


@dataclass
class SimulationInput:
    radar_type_name: str
    template_key: str
    power_coeff_db: float
    jammer_profile: str
    jammer_mode: str
    angle_deg: float
    jammer_range_nm: float
    target_range_nm: float
    jammer_altitude_m: float
    los_ok: bool
    extra_jammer_gain_db: float = 0.0
    altitude_bonus_per_10km_db: float = 0.0
    altitude_bonus_cap_db: float = 0.0


@dataclass
class SimulationResult:
    radar_type_name: str
    template_key: str
    power_coeff_db: float
    jammer_profile: str
    jammer_mode: str
    angle_deg: float
    jammer_range_nm: float
    target_range_nm: float
    jammer_altitude_m: float
    los_ok: bool
    radar_direction_gain_db: float
    jammer_mode_power_db: float
    profile_gain_db: float
    manual_extra_gain_db: float
    altitude_bonus_db: float
    effective_jammer_power_db: float
    jsr_db: float
    jam_probability: float


def nm_to_km(range_nm: float) -> float:
    return range_nm * BACKEND.JAMMING_CONFIG["NM_TO_KM"]


def get_available_modes() -> List[str]:
    return sorted(BACKEND.JAMMING_CONFIG["JAMMER_MODES"].keys())


def get_jammer_profiles() -> List[str]:
    return list(JAMMER_PROFILES.keys())


def get_template_profiles() -> Dict[str, TemplateProfile]:
    return TEMPLATE_LOOKUP


def get_radar_mapping_lookup() -> Dict[str, RadarMappingCandidate]:
    return RADAR_MAPPING_LOOKUP


def get_radar_options() -> List[Tuple[str, str]]:
    options = []
    for radar_name, mapping in sorted(RADAR_MAPPING_LOOKUP.items(), key=lambda item: item[1].display_name.lower()):
        label = f"{mapping.display_name} | {radar_name}"
        options.append((label, radar_name))
    return options


def build_pattern(template: TemplateProfile):
    return BACKEND.make_custom_pattern(
        name=template.display_name,
        HPBW_deg=template.hpbw_deg,
        floor_db=template.floor_db,
        sidelobes=template.sidelobes,
    )


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


def simulate(input_data: SimulationInput) -> SimulationResult:
    if input_data.template_key not in TEMPLATE_LOOKUP:
        raise ValueError(f"Unknown template: {input_data.template_key}")

    if input_data.jammer_mode not in BACKEND.JAMMING_CONFIG["JAMMER_MODES"]:
        raise ValueError(f"Unknown jammer mode: {input_data.jammer_mode}")

    template = TEMPLATE_LOOKUP[input_data.template_key]
    pattern = build_pattern(template)
    radar_direction_gain_linear = pattern.gain(BACKEND.np.array([input_data.angle_deg]))[0]
    radar_direction_gain_db = float(BACKEND.lin_to_db(radar_direction_gain_linear))

    jammer_mode_power_db = float(BACKEND.JAMMING_CONFIG["JAMMER_MODES"][input_data.jammer_mode])
    profile_gain_db = float(JAMMER_PROFILES.get(input_data.jammer_profile, {}).get("extra_gain_db", 0.0))
    altitude_bonus_db = compute_altitude_bonus_db(
        input_data.jammer_altitude_m,
        input_data.altitude_bonus_per_10km_db,
        input_data.altitude_bonus_cap_db,
    )

    effective_jammer_power_db = (
        jammer_mode_power_db
        + profile_gain_db
        + input_data.extra_jammer_gain_db
        + altitude_bonus_db
    )

    target_loss_db = float(BACKEND.compute_range_loss_db(nm_to_km(input_data.target_range_nm), is_radar=True))
    jammer_loss_db = float(BACKEND.compute_range_loss_db(nm_to_km(input_data.jammer_range_nm), is_radar=False))

    jsr_db = (
        (effective_jammer_power_db + radar_direction_gain_db - jammer_loss_db)
        - (input_data.power_coeff_db + 0.0 - target_loss_db)
    )

    jam_probability = 0.0 if not input_data.los_ok else float(BACKEND.jamming_probability_sigmoid(jsr_db))

    return SimulationResult(
        radar_type_name=input_data.radar_type_name,
        template_key=input_data.template_key,
        power_coeff_db=input_data.power_coeff_db,
        jammer_profile=input_data.jammer_profile,
        jammer_mode=input_data.jammer_mode,
        angle_deg=input_data.angle_deg,
        jammer_range_nm=input_data.jammer_range_nm,
        target_range_nm=input_data.target_range_nm,
        jammer_altitude_m=input_data.jammer_altitude_m,
        los_ok=input_data.los_ok,
        radar_direction_gain_db=radar_direction_gain_db,
        jammer_mode_power_db=jammer_mode_power_db,
        profile_gain_db=profile_gain_db,
        manual_extra_gain_db=input_data.extra_jammer_gain_db,
        altitude_bonus_db=altitude_bonus_db,
        effective_jammer_power_db=effective_jammer_power_db,
        jsr_db=jsr_db,
        jam_probability=jam_probability,
    )


def sample_gain_curve(template_key: str, step_deg: float = 1.0):
    template = TEMPLATE_LOOKUP[template_key]
    pattern = build_pattern(template)
    theta_deg = BACKEND.np.arange(-180.0, 181.0, step_deg, dtype=float)
    gain_linear = pattern.gain(theta_deg)
    gain_db = 10.0 * BACKEND.np.log10(BACKEND.np.maximum(gain_linear, 1e-10))
    return theta_deg, gain_db


def sample_probability_curve(input_data: SimulationInput, step_deg: float = 1.0):
    theta_deg = BACKEND.np.arange(0.0, 361.0, step_deg, dtype=float)
    probabilities = []
    for angle in theta_deg:
        angle_folded = angle if angle <= 180.0 else 360.0 - angle
        scenario = SimulationInput(
            radar_type_name=input_data.radar_type_name,
            template_key=input_data.template_key,
            power_coeff_db=input_data.power_coeff_db,
            jammer_profile=input_data.jammer_profile,
            jammer_mode=input_data.jammer_mode,
            angle_deg=float(min(angle_folded, 180.0)),
            jammer_range_nm=input_data.jammer_range_nm,
            target_range_nm=input_data.target_range_nm,
            jammer_altitude_m=input_data.jammer_altitude_m,
            los_ok=input_data.los_ok,
            extra_jammer_gain_db=input_data.extra_jammer_gain_db,
            altitude_bonus_per_10km_db=input_data.altitude_bonus_per_10km_db,
            altitude_bonus_cap_db=input_data.altitude_bonus_cap_db,
        )
        probabilities.append(simulate(scenario).jam_probability)
    return theta_deg, probabilities

