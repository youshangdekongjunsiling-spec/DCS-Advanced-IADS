#!/usr/bin/env python3
"""
Generate reviewable radar-template mapping reports for the research layer.
"""

from __future__ import annotations

import csv
import json
from dataclasses import asdict
from pathlib import Path
from typing import List

from jammer_research_catalog import (
    TemplateProfile,
    RadarMappingCandidate,
    build_radar_mapping_candidates,
    build_template_profiles,
)


ROOT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = ROOT_DIR / "jammer_research_outputs" / "mapping_review"


def write_json(templates, mappings, path: Path) -> None:
    payload = {
        "templates": {key: asdict(value) for key, value in templates.items()},
        "mapping_candidates": [asdict(item) for item in mappings],
    }
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def write_csv(mappings: List[RadarMappingCandidate], path: Path) -> None:
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(asdict(mappings[0]).keys()))
        writer.writeheader()
        for item in mappings:
            writer.writerow(asdict(item))


def write_markdown(
    templates: dict[str, TemplateProfile],
    mappings: List[RadarMappingCandidate],
    path: Path,
) -> None:
    lines: List[str] = []
    lines.append("# DCS Radar Template Mapping Candidates")
    lines.append("")
    lines.append("## Template Families")
    lines.append("")
    lines.append("| Key | Display Name | Default Power Coeff dB | HPBW deg | Floor dB | Description |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for template in templates.values():
        lines.append(
            f"| {template.key} | {template.display_name} | {template.default_power_coeff_db:.1f} | "
            f"{template.hpbw_deg:.1f} | {template.floor_db:.1f} | {template.description} |"
        )

    lines.append("")
    lines.append("## Mapping Candidates")
    lines.append("")
    lines.append("| DCS Type Name | Display Name | Role | Template | Power Coeff dB | Confidence | Source Family | Notes |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for item in mappings:
        lines.append(
            f"| {item.dcs_type_name} | {item.display_name} | {item.radar_role} | "
            f"{item.template_key} | {item.power_coeff_db:.1f} | {item.confidence} | "
            f"{item.source_family} | {item.notes} |"
        )

    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    templates = build_template_profiles()
    mappings = build_radar_mapping_candidates()

    write_json(templates, mappings, OUTPUT_DIR / "radar_template_mapping_candidates.json")
    write_csv(mappings, OUTPUT_DIR / "radar_template_mapping_candidates.csv")
    write_markdown(templates, mappings, OUTPUT_DIR / "radar_template_mapping_candidates.md")

    print(f"Mapping review generated: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
