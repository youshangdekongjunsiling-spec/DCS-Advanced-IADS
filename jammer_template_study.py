#!/usr/bin/env python3
"""
Template-based jamming study for the EA-18G research layer.

This script defines a simplified set of radar template families and generates:

1. Template parameter JSON.
2. Gain polar plots for each template.
3. Full probability tables for:
   - distances: 10, 20, 30, 40, 50, 60, 70 nm
   - off-boresight angles: 0..90 deg
   - jammer modes: spot / sector / broadcast

The study keeps the research-layer assumptions explicit and does not touch the
runtime Lua script.
"""

from __future__ import annotations

import csv
import importlib.util
import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, List

from jammer_research_catalog import TemplateProfile, build_template_profiles

ROOT_DIR = Path(__file__).resolve().parent
BACKEND_PATH = ROOT_DIR / "Jammer parameters" / "Rader_polar_plot_lua_sync.py"
OUTPUT_DIR = ROOT_DIR / "jammer_research_outputs" / "template_study"

DISTANCES_NM = [10, 20, 30, 40, 50, 60, 70]
ANGLES_DEG = list(range(0, 91, 10))
MODES = ["spot", "sector", "broadcast"]

# Research assumption for this batch study:
# keep the locked target at 20nm from the radar, matching the earlier escort
# jamming validation scenario.
DEFAULT_TARGET_RANGE_NM = 20.0

# Strongest default loadout assumption:
# current mode powers are treated as the strongest calibrated loadout, so no
# additional loadout penalty or bonus is applied in this batch study.
DEFAULT_EXTRA_JAMMER_GAIN_DB = 0.0


def load_backend():
    spec = importlib.util.spec_from_file_location("jammer_research_backend", BACKEND_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load backend module: {BACKEND_PATH}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


BACKEND = load_backend()


@dataclass
class ProbabilityRow:
    template_key: str
    template_name: str
    mode: str
    distance_nm: int
    angle_deg: int
    target_range_nm: float
    power_coeff_db: float
    radar_direction_gain_db: float
    jammer_mode_power_db: float
    effective_jammer_power_db: float
    jsr_db: float
    jam_probability: float


def nm_to_km(range_nm: float) -> float:
    return range_nm * BACKEND.JAMMING_CONFIG["NM_TO_KM"]


def build_pattern(template: TemplateProfile):
    return BACKEND.make_custom_pattern(
        name=template.display_name,
        HPBW_deg=template.hpbw_deg,
        floor_db=template.floor_db,
        sidelobes=template.sidelobes,
    )


def compute_jsr_db_for_template(
    template: TemplateProfile,
    angle_deg: float,
    mode: str,
    distance_nm: float,
    target_range_nm: float,
    extra_jammer_gain_db: float = 0.0,
):
    pattern = build_pattern(template)
    radar_direction_gain_linear = pattern.gain(BACKEND.np.array([angle_deg]))[0]
    radar_direction_gain_db = float(BACKEND.lin_to_db(radar_direction_gain_linear))

    jammer_mode_power_db = float(BACKEND.JAMMING_CONFIG["JAMMER_MODES"][mode])
    effective_jammer_power_db = jammer_mode_power_db + extra_jammer_gain_db

    range_radar_target_km = nm_to_km(target_range_nm)
    range_jammer_radar_km = nm_to_km(distance_nm)

    target_loss_db = float(BACKEND.compute_range_loss_db(range_radar_target_km, is_radar=True))
    jammer_loss_db = float(BACKEND.compute_range_loss_db(range_jammer_radar_km, is_radar=False))

    jsr_db = (
        (effective_jammer_power_db + radar_direction_gain_db - jammer_loss_db)
        - (template.default_power_coeff_db + 0.0 - target_loss_db)
    )

    jam_probability = float(BACKEND.jamming_probability_sigmoid(jsr_db))
    return radar_direction_gain_db, jammer_mode_power_db, effective_jammer_power_db, jsr_db, jam_probability


def plot_template_gain_polar(template: TemplateProfile, output_path: Path) -> None:
    pattern = build_pattern(template)
    theta_deg = BACKEND.np.arange(-180.0, 181.0, 1.0, dtype=float)
    gain_linear = pattern.gain(theta_deg)
    gain_db = 10.0 * BACKEND.np.log10(BACKEND.np.maximum(gain_linear, 1e-10))

    min_db = min(-60.0, template.floor_db - 5.0)
    gain_db_clipped = BACKEND.np.maximum(gain_db, min_db)
    radius = gain_db_clipped - min_db
    theta_wrapped = BACKEND.np.radians((theta_deg + 360.0) % 360.0)

    fig = BACKEND.plt.figure(figsize=(8, 8))
    ax = fig.add_subplot(111, projection="polar")
    ax.plot(theta_wrapped, radius, linewidth=2)
    ax.fill(theta_wrapped, radius, alpha=0.2)
    ax.set_title(f"{template.display_name}\nGain Polar Plot", va="bottom", pad=20)

    tick_values_db = [min_db, -40.0, -30.0, -20.0, -10.0, 0.0]
    tick_values_db = sorted(set(v for v in tick_values_db if v >= min_db))
    tick_positions = [value - min_db for value in tick_values_db]
    tick_labels = [f"{int(value)} dB" for value in tick_values_db]
    ax.set_rticks(tick_positions)
    ax.set_yticklabels(tick_labels)
    ax.set_ylim(0, max(tick_positions) if tick_positions else 1)

    BACKEND.plt.tight_layout()
    BACKEND.plt.savefig(output_path, dpi=150, bbox_inches="tight")
    BACKEND.plt.close(fig)


def write_probability_csv(rows: List[ProbabilityRow], output_path: Path) -> None:
    with output_path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(asdict(rows[0]).keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow(asdict(row))


def render_mode_table(rows: List[ProbabilityRow], mode: str) -> str:
    header = ["Distance/Angle"] + [f"{angle}°" for angle in ANGLES_DEG]
    lines = ["| " + " | ".join(header) + " |", "| " + " | ".join(["---"] * len(header)) + " |"]

    filtered_rows = [row for row in rows if row.mode == mode]
    for distance_nm in DISTANCES_NM:
        values = [f"{distance_nm}nm"]
        for angle_deg in ANGLES_DEG:
            match = next(
                row for row in filtered_rows
                if row.distance_nm == distance_nm and row.angle_deg == angle_deg
            )
            values.append(f"{match.jam_probability:.2f}")
        lines.append("| " + " | ".join(values) + " |")

    return "\n".join(lines)


def write_markdown_report(
    templates: Dict[str, TemplateProfile],
    rows: List[ProbabilityRow],
    output_path: Path,
) -> None:
    lines: List[str] = []
    lines.append("# Template-Based Jamming Study")
    lines.append("")
    lines.append("## Assumptions")
    lines.append("")
    lines.append(f"- Locked target range: {DEFAULT_TARGET_RANGE_NM:.0f} nm")
    lines.append("- Strongest default loadout: current mode power presets are used directly")
    lines.append("- No additional altitude bonus is applied in this batch study")
    lines.append("")
    lines.append("## Template Parameters")
    lines.append("")
    lines.append("| Key | Display Name | Power Coeff dB | HPBW deg | Floor dB | Description |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for template in templates.values():
        lines.append(
            f"| {template.key} | {template.display_name} | {template.default_power_coeff_db:.1f} | "
            f"{template.hpbw_deg:.1f} | {template.floor_db:.1f} | {template.description} |"
        )
    lines.append("")

    for template_key, template in templates.items():
        template_rows = [row for row in rows if row.template_key == template_key]
        lines.append(f"## {template.display_name}")
        lines.append("")
        lines.append(f"- Template key: `{template.key}`")
        lines.append(f"- Radar power coefficient: `{template.default_power_coeff_db:.1f} dB`")
        lines.append(f"- Beam template: `HPBW={template.hpbw_deg:.1f} deg`, `floor={template.floor_db:.1f} dB`")
        lines.append(f"- Polar plot: `{template.key}_gain_polar.png`")
        lines.append("")
        for mode in MODES:
            lines.append(f"### {mode.title()} Mode Success Probability")
            lines.append("")
            lines.append(render_mode_table(template_rows, mode))
            lines.append("")

    output_path.write_text("\n".join(lines), encoding="utf-8")


def write_template_json(templates: Dict[str, TemplateProfile], output_path: Path) -> None:
    payload = {key: asdict(template) for key, template in templates.items()}
    output_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def run_template_study() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for stale_file in OUTPUT_DIR.glob("*"):
        if stale_file.is_file():
            stale_file.unlink()

    templates = build_template_profiles()
    rows: List[ProbabilityRow] = []

    for template in templates.values():
        polar_path = OUTPUT_DIR / f"{template.key}_gain_polar.png"
        plot_template_gain_polar(template, polar_path)

        for mode in MODES:
            for distance_nm in DISTANCES_NM:
                for angle_deg in ANGLES_DEG:
                    (
                        radar_direction_gain_db,
                        jammer_mode_power_db,
                        effective_jammer_power_db,
                        jsr_db,
                        jam_probability,
                    ) = compute_jsr_db_for_template(
                        template,
                        angle_deg,
                        mode,
                        distance_nm,
                        DEFAULT_TARGET_RANGE_NM,
                        DEFAULT_EXTRA_JAMMER_GAIN_DB,
                    )

                    rows.append(
                        ProbabilityRow(
                            template_key=template.key,
                            template_name=template.display_name,
                            mode=mode,
                            distance_nm=distance_nm,
                            angle_deg=angle_deg,
                            target_range_nm=DEFAULT_TARGET_RANGE_NM,
                            power_coeff_db=template.default_power_coeff_db,
                            radar_direction_gain_db=radar_direction_gain_db,
                            jammer_mode_power_db=jammer_mode_power_db,
                            effective_jammer_power_db=effective_jammer_power_db,
                            jsr_db=jsr_db,
                            jam_probability=jam_probability,
                        )
                    )

    write_template_json(templates, OUTPUT_DIR / "template_parameters.json")
    write_probability_csv(rows, OUTPUT_DIR / "template_probability_table.csv")
    write_markdown_report(templates, rows, OUTPUT_DIR / "template_probability_report.md")

    print(f"Template study complete: {OUTPUT_DIR}")


if __name__ == "__main__":
    run_template_study()
