#!/usr/bin/env python3
"""
Shared simulation engine for the jammer research layer.
"""

from __future__ import annotations

import importlib.util
import math
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from jammer_research_catalog import (
    RadarMappingCandidate,
    TemplateProfile,
    build_mapping_lookup,
    build_template_lookup,
)
from jammer_research_config import load_config


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


def _apply_backend_overrides(config: Dict[str, object]) -> None:
    backend_overrides = config.get("backend_overrides", {})
    if not isinstance(backend_overrides, dict):
        return

    sigmoid_k = backend_overrides.get("sigmoid_k")
    if sigmoid_k is not None:
        BACKEND.JAMMING_CONFIG["SIGMOID_K"] = float(sigmoid_k)

    jammer_modes = backend_overrides.get("jammer_modes")
    if isinstance(jammer_modes, dict):
        for mode_name, mode_power in jammer_modes.items():
            BACKEND.JAMMING_CONFIG["JAMMER_MODES"][mode_name] = float(mode_power)


def _load_runtime_config() -> Dict[str, object]:
    config = load_config()
    _apply_backend_overrides(config)
    return config


def _get_engine_settings() -> Dict[str, object]:
    engine_settings = _load_runtime_config().get("engine", {})
    return engine_settings if isinstance(engine_settings, dict) else {}


def get_default_altitude_bonus_per_10km_db() -> float:
    return float(_get_engine_settings().get("default_altitude_bonus_per_10km_db", 10.0))


def get_default_radar_echo_base_db() -> float:
    return float(_get_engine_settings().get("default_radar_echo_base_db", 30.0))


def _get_channel_model() -> Dict[str, float]:
    channel_model = _get_engine_settings().get("channel_model", {})
    if not isinstance(channel_model, dict):
        channel_model = {}

    return {
        "alq99_channel_count": float(channel_model.get("alq99_channel_count", 1.0)),
        "alq99_channel_power": float(channel_model.get("alq99_channel_power", 2.0)),
        "alq249_channel_count": float(channel_model.get("alq249_channel_count", 2.0)),
        "alq249_channel_power": float(channel_model.get("alq249_channel_power", 5.0)),
    }


def build_jammer_profiles() -> Dict[str, Dict[str, float]]:
    engine_settings = _get_engine_settings()
    preset_list = engine_settings.get("loadout_presets", [])
    if not isinstance(preset_list, list):
        preset_list = []

    channel_model = _get_channel_model()
    alq99_channel_count = channel_model["alq99_channel_count"]
    alq99_channel_power = channel_model["alq99_channel_power"]
    alq249_channel_count = channel_model["alq249_channel_count"]
    alq249_channel_power = channel_model["alq249_channel_power"]
    reference_total_power = alq99_channel_count * alq99_channel_power

    profiles: Dict[str, Dict[str, float]] = {}
    for preset in preset_list:
        if not isinstance(preset, dict):
            continue

        label = str(preset.get("label", ""))
        alq99_count = float(preset.get("alq99", 0))
        alq249_count = float(preset.get("alq249", 0))
        cap = float(preset.get("cap", 0))

        total_channels = (alq99_count * alq99_channel_count) + (alq249_count * alq249_channel_count)
        total_jam_value = (
            (alq99_count * alq99_channel_count * alq99_channel_power)
            + (alq249_count * alq249_channel_count * alq249_channel_power)
        )

        if total_jam_value <= 0 or reference_total_power <= 0:
            extra_gain_db = -120.0
            enabled = False
        else:
            extra_gain_db = 10.0 * math.log10(total_jam_value / reference_total_power)
            enabled = True

        profiles[label] = {
            "alq99": alq99_count,
            "alq249": alq249_count,
            "cap": cap,
            "total_channels": float(total_channels),
            "total_jam_value": float(total_jam_value),
            "extra_gain_db": float(extra_gain_db),
            "enabled": enabled,
        }

    return profiles


def get_default_jammer_profile() -> str:
    profiles = build_jammer_profiles()
    engine_settings = _get_engine_settings()
    default_profile = str(engine_settings.get("default_jammer_profile", ""))
    if default_profile in profiles:
        return default_profile
    return next(iter(profiles.keys()), "")


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
    altitude_bonus_per_10km_db: Optional[float] = None
    altitude_bonus_cap_db: float = 0.0
    sigmoid_k: Optional[float] = None


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
    profile_cap: float
    profile_total_jam_value: float
    manual_extra_gain_db: float
    altitude_bonus_db: float
    effective_jammer_power_db: float
    jsr_db: float
    jam_probability: float
    sigmoid_k: float


def nm_to_km(range_nm: float) -> float:
    return range_nm * BACKEND.JAMMING_CONFIG["NM_TO_KM"]


def get_available_modes() -> List[str]:
    _load_runtime_config()
    return sorted(BACKEND.JAMMING_CONFIG["JAMMER_MODES"].keys())


def get_jammer_profiles() -> List[str]:
    return list(build_jammer_profiles().keys())


def get_jammer_profile_metadata(profile_name: str) -> Dict[str, float]:
    return build_jammer_profiles()[profile_name]


def get_template_profiles() -> Dict[str, TemplateProfile]:
    template_lookup = build_template_lookup()
    config = _load_runtime_config()
    template_overrides = config.get("template_overrides", {})
    if isinstance(template_overrides, dict):
        for template_key, override in template_overrides.items():
            if template_key not in template_lookup or not isinstance(override, dict):
                continue
            base_entry = template_lookup[template_key]
            template_lookup[template_key] = replace(
                base_entry,
                display_name=str(override.get("display_name", base_entry.display_name)),
                description=str(override.get("description", base_entry.description)),
                default_power_coeff_db=float(
                    override.get("default_power_coeff_db", base_entry.default_power_coeff_db)
                ),
                hpbw_deg=float(override.get("hpbw_deg", base_entry.hpbw_deg)),
                floor_db=float(override.get("floor_db", base_entry.floor_db)),
                sidelobes=override.get("sidelobes", base_entry.sidelobes),
            )
    return template_lookup


def get_radar_mapping_lookup() -> Dict[str, RadarMappingCandidate]:
    mapping_lookup = build_mapping_lookup()
    config = _load_runtime_config()
    radar_overrides = config.get("radar_overrides", {})
    if isinstance(radar_overrides, dict):
        for radar_name, override in radar_overrides.items():
            if radar_name not in mapping_lookup or not isinstance(override, dict):
                continue
            base_entry = mapping_lookup[radar_name]
            mapping_lookup[radar_name] = replace(
                base_entry,
                template_key=str(override.get("template_key", base_entry.template_key)),
                power_coeff_db=float(override.get("power_coeff_db", base_entry.power_coeff_db)),
            )
    return mapping_lookup


def get_radar_options() -> List[Tuple[str, str]]:
    options = []
    for radar_name, mapping in sorted(get_radar_mapping_lookup().items(), key=lambda item: item[1].display_name.lower()):
        label = f"{mapping.display_name} | {radar_name}"
        options.append((label, radar_name))
    return options


def get_sigmoid_k() -> float:
    _load_runtime_config()
    return float(BACKEND.JAMMING_CONFIG["SIGMOID_K"])


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
    template_lookup = get_template_profiles()
    if input_data.template_key not in template_lookup:
        raise ValueError(f"Unknown template: {input_data.template_key}")

    if input_data.jammer_mode not in BACKEND.JAMMING_CONFIG["JAMMER_MODES"]:
        raise ValueError(f"Unknown jammer mode: {input_data.jammer_mode}")

    template = template_lookup[input_data.template_key]
    pattern = build_pattern(template)
    radar_direction_gain_linear = pattern.gain(BACKEND.np.array([input_data.angle_deg]))[0]
    radar_direction_gain_db = float(BACKEND.lin_to_db(radar_direction_gain_linear))

    jammer_mode_power_db = float(BACKEND.JAMMING_CONFIG["JAMMER_MODES"][input_data.jammer_mode])
    profile_metadata = build_jammer_profiles().get(input_data.jammer_profile, {})
    profile_gain_db = float(profile_metadata.get("extra_gain_db", 0.0))
    profile_cap = float(profile_metadata.get("cap", 0.0))
    profile_total_jam_value = float(profile_metadata.get("total_jam_value", 0.0))

    altitude_bonus_per_10km_db = (
        get_default_altitude_bonus_per_10km_db()
        if input_data.altitude_bonus_per_10km_db is None
        else float(input_data.altitude_bonus_per_10km_db)
    )
    altitude_bonus_db = compute_altitude_bonus_db(
        input_data.jammer_altitude_m,
        altitude_bonus_per_10km_db,
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
    radar_echo_base_db = get_default_radar_echo_base_db()

    jsr_db = (
        (effective_jammer_power_db + radar_direction_gain_db - jammer_loss_db)
        - (input_data.power_coeff_db + radar_echo_base_db - target_loss_db)
    )

    sigmoid_k = get_sigmoid_k() if input_data.sigmoid_k is None else float(input_data.sigmoid_k)
    jam_probability = 0.0 if not input_data.los_ok else float(BACKEND.jamming_probability_sigmoid(jsr_db, sigmoid_k))

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
        profile_cap=profile_cap,
        profile_total_jam_value=profile_total_jam_value,
        manual_extra_gain_db=input_data.extra_jammer_gain_db,
        altitude_bonus_db=altitude_bonus_db,
        effective_jammer_power_db=effective_jammer_power_db,
        jsr_db=jsr_db,
        jam_probability=jam_probability,
        sigmoid_k=sigmoid_k,
    )


def sample_gain_curve(template_key: str, step_deg: float = 1.0):
    template = get_template_profiles()[template_key]
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
            sigmoid_k=input_data.sigmoid_k,
        )
        probabilities.append(simulate(scenario).jam_probability)
    return theta_deg, probabilities


def sample_jsr_probability_curve(
    min_jsr_db: float = -30.0,
    max_jsr_db: float = 30.0,
    step_db: float = 0.1,
    sigmoid_k: Optional[float] = None,
):
    jsr_values = BACKEND.np.arange(min_jsr_db, max_jsr_db + step_db, step_db, dtype=float)
    probabilities = BACKEND.jamming_probability_sigmoid(
        jsr_values,
        get_sigmoid_k() if sigmoid_k is None else float(sigmoid_k),
    )
    return jsr_values, probabilities
