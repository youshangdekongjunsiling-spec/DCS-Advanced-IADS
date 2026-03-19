#!/usr/bin/env python3
"""
External configuration helpers for the jammer research layer.
"""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Dict


ROOT_DIR = Path(__file__).resolve().parent
CONFIG_PATH = ROOT_DIR / "jammer_research_params.json"


DEFAULT_RESEARCH_CONFIG: Dict[str, Any] = {
    "backend_overrides": {
        "sigmoid_k": 0.2,
        "jammer_modes": {
            "broadcast": 23.0,
            "sector": 27.0,
            "spot": 45.0,
        },
    },
    "template_overrides": {},
    "engine": {
        "default_altitude_bonus_per_10km_db": 10.0,
        "channel_model": {
            "alq99_channel_count": 1.0,
            "alq99_channel_power": 2.0,
            "alq249_channel_count": 2.0,
            "alq249_channel_power": 5.0,
        },
        "loadout_presets": [
            {"label": "\u65e0\u5e72\u6270\u540a\u8231", "alq99": 0, "alq249": 0, "cap": 0},
            {"label": "1x ALQ-99", "alq99": 1, "alq249": 0, "cap": 1000},
            {"label": "2x ALQ-99", "alq99": 2, "alq249": 0, "cap": 2000},
            {"label": "3x ALQ-99", "alq99": 3, "alq249": 0, "cap": 3000},
            {"label": "1x ALQ-249", "alq99": 0, "alq249": 1, "cap": 3000},
            {"label": "2x ALQ-249", "alq99": 0, "alq249": 2, "cap": 4000},
            {"label": "2x ALQ-249 + 1x ALQ-99", "alq99": 1, "alq249": 2, "cap": 4500},
        ],
        "default_jammer_profile": "2x ALQ-249 + 1x ALQ-99",
    },
    "radar_overrides": {},
    "ui_state": {
        "selected_radar_label": "",
        "selected_template_key": "",
        "selected_jammer_profile": "2x ALQ-249 + 1x ALQ-99",
        "selected_jammer_mode": "spot",
        "los_ok": True,
        "angle_deg": 10.0,
        "jammer_range_nm": 40.0,
        "target_range_nm": 20.0,
        "jammer_altitude_ft": 26246.72,
        "extra_gain_db": 0.0,
        "power_coeff_db": 16.0,
        "sigmoid_k": 0.2,
    },
}


def _deep_merge(defaults: Any, incoming: Any) -> Any:
    if isinstance(defaults, dict) and isinstance(incoming, dict):
        merged = deepcopy(defaults)
        for key, value in incoming.items():
            if key in merged:
                merged[key] = _deep_merge(merged[key], value)
            else:
                merged[key] = deepcopy(value)
        return merged
    return deepcopy(incoming)


def get_config_path() -> Path:
    return CONFIG_PATH


def _ensure_config_file() -> None:
    if CONFIG_PATH.exists():
        return
    save_config(DEFAULT_RESEARCH_CONFIG)


def load_config() -> Dict[str, Any]:
    _ensure_config_file()
    try:
        raw = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception:
        raw = {}
    return _deep_merge(DEFAULT_RESEARCH_CONFIG, raw)


def save_config(config: Dict[str, Any]) -> None:
    CONFIG_PATH.write_text(json.dumps(config, indent=2, ensure_ascii=False), encoding="utf-8")


def update_config(mutator) -> Dict[str, Any]:
    config = load_config()
    mutator(config)
    save_config(config)
    return config


def persist_ui_and_runtime_state(
    selected_radar_name: str,
    ui_state: Dict[str, Any],
    template_key: str,
    power_coeff_db: float,
    sigmoid_k: float,
) -> Dict[str, Any]:
    def mutate(config: Dict[str, Any]) -> None:
        config.setdefault("ui_state", {}).update(ui_state)
        config.setdefault("backend_overrides", {})["sigmoid_k"] = float(sigmoid_k)

        radar_overrides = config.setdefault("radar_overrides", {})
        radar_entry = radar_overrides.setdefault(selected_radar_name, {})
        radar_entry["template_key"] = template_key
        radar_entry["power_coeff_db"] = float(power_coeff_db)

    return update_config(mutate)
