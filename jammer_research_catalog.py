#!/usr/bin/env python3
"""
Catalog of research-layer radar templates and DCS radar mapping candidates.

This module is intentionally static and review-friendly:
- template families define angular behavior
- power_coeff_db defines baseline radar strength
- DCS radar names are mapped to template families plus power coeff
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Dict, List


@dataclass
class TemplateProfile:
    key: str
    display_name: str
    description: str
    default_power_coeff_db: float
    hpbw_deg: float
    floor_db: float
    sidelobes: List[Dict[str, float]]


@dataclass
class RadarMappingCandidate:
    dcs_type_name: str
    display_name: str
    radar_role: str
    template_key: str
    power_coeff_db: float
    confidence: str
    source_family: str
    notes: str


def build_template_profiles() -> Dict[str, TemplateProfile]:
    return {
        "omni_search": TemplateProfile(
            key="omni_search",
            display_name="Omni Search Radar",
            description="搜索/预警模板。主瓣宽、全向易吃到干扰，但可通过更高基础功率避免远距致盲。",
            default_power_coeff_db=8.0,
            hpbw_deg=24.0,
            floor_db=-3.0,
            sidelobes=[
                {"angle_deg": 15, "amplitude_db": -1.0, "width_deg": 18.0, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -2.0, "width_deg": 20.0, "symmetric": True},
                {"angle_deg": 45, "amplitude_db": -3.0, "width_deg": 22.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -4.0, "width_deg": 24.0, "symmetric": True},
                {"angle_deg": 75, "amplitude_db": -5.0, "width_deg": 26.0, "symmetric": True},
                {"angle_deg": 90, "amplitude_db": -6.0, "width_deg": 28.0, "symmetric": True},
            ],
        ),
        "legacy_fcr_wide": TemplateProfile(
            key="legacy_fcr_wide",
            display_name="Legacy Fire Control Radar",
            description="老式火控模板。主瓣明显但较宽，旁瓣也较大，正半球范围内仍常有较高干扰成功率。",
            default_power_coeff_db=9.0,
            hpbw_deg=10.0,
            floor_db=-18.0,
            sidelobes=[
                {"angle_deg": 12, "amplitude_db": -5.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 24, "amplitude_db": -8.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 36, "amplitude_db": -11.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 48, "amplitude_db": -14.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 60, "amplitude_db": -17.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 72, "amplitude_db": -20.0, "width_deg": 8.0, "symmetric": True},
                {"angle_deg": 84, "amplitude_db": -23.0, "width_deg": 8.0, "symmetric": True},
            ],
        ),
        "mid_fcr_compact": TemplateProfile(
            key="mid_fcr_compact",
            display_name="Mid-Generation Fire Control Radar",
            description="中先进火控模板。主瓣更窄，旁瓣收缩，偏离主瓣约30度后成功率显著下降。",
            default_power_coeff_db=16.0,
            hpbw_deg=3.2,
            floor_db=-36.0,
            sidelobes=[
                {"angle_deg": 6, "amplitude_db": -9.0, "width_deg": 3.2, "symmetric": True},
                {"angle_deg": 12, "amplitude_db": -14.0, "width_deg": 3.2, "symmetric": True},
                {"angle_deg": 18, "amplitude_db": -19.0, "width_deg": 3.2, "symmetric": True},
                {"angle_deg": 24, "amplitude_db": -24.0, "width_deg": 3.2, "symmetric": True},
                {"angle_deg": 30, "amplitude_db": -30.0, "width_deg": 3.2, "symmetric": True},
            ],
        ),
        "aesa_fcr_narrow": TemplateProfile(
            key="aesa_fcr_narrow",
            display_name="AESA Fire Control Radar",
            description="最先进火控模板。主瓣极窄，旁瓣极低，通常只有与锁定目标近共线时才容易干扰成功。",
            default_power_coeff_db=25.0,
            hpbw_deg=1.2,
            floor_db=-50.0,
            sidelobes=[
                {"angle_deg": 2.5, "amplitude_db": -18.0, "width_deg": 1.2, "symmetric": True},
                {"angle_deg": 5.0, "amplitude_db": -28.0, "width_deg": 1.2, "symmetric": True},
                {"angle_deg": 8.0, "amplitude_db": -38.0, "width_deg": 1.2, "symmetric": True},
                {"angle_deg": 12.0, "amplitude_db": -46.0, "width_deg": 1.2, "symmetric": True},
            ],
        ),
    }


def build_radar_mapping_candidates() -> List[RadarMappingCandidate]:
    return [
        RadarMappingCandidate("1L13 EWR", "1L13 Nebo", "early warning radar", "omni_search", 0.0, "high", "research+skynet", "老式 VHF 预警雷达，整体易受扰。"),
        RadarMappingCandidate("P-19 st", "P-19 Flat Face", "search radar", "omni_search", 3.0, "high", "research", "老式搜索雷达，略强于 1L13。"),
        RadarMappingCandidate("p-19 s-125 sr", "P-19 / S-125 SR", "search radar", "omni_search", 4.0, "high", "skynet", "SA-2/SA-3 配套的老式搜索雷达。"),
        RadarMappingCandidate("EWR P-37 BAR LOCK", "P-37 Bar Lock", "early warning radar", "omni_search", 7.0, "medium", "skynet", "老式远程 EWR，但整体功率应高于 1L13/P-19。"),
        RadarMappingCandidate("55G6 EWR", "55G6 Tall Rack", "modern early warning radar", "omni_search", 18.0, "medium", "skynet", "现代搜索雷达；仍吃全向干扰，但远距更难致盲。"),
        RadarMappingCandidate("FPS-117 Dome", "FPS-117 Dome", "modern search radar", "omni_search", 22.0, "medium", "skynet", "现代固定阵列搜索雷达，建议用高基础功率。"),
        RadarMappingCandidate("FPS-117", "FPS-117", "modern search radar", "omni_search", 22.0, "medium", "skynet", "与 Dome 版本同档处理。"),
        RadarMappingCandidate("NASAMS_Radar_MPQ64F1", "AN/MPQ-64 Sentinel F1", "modern search radar", "omni_search", 18.0, "medium", "skynet", "现代机动 3D 搜索雷达，易受全向干扰但整体较硬。"),
        RadarMappingCandidate("Dog Ear radar", "9S80M1 Dog Ear", "target acquisition radar", "omni_search", 14.0, "medium", "skynet", "短程现代搜索/获取雷达，可先归搜索模板。"),
        RadarMappingCandidate("Hawk sr", "Hawk Search Radar", "search radar", "omni_search", 8.0, "high", "research+skynet", "老式搜索雷达，不应视为先进火控。"),
        RadarMappingCandidate("S-300PS 64H6E sr", "64N6 Big Bird", "modern long-range search radar", "omni_search", 26.0, "medium", "research+skynet", "现代高性能搜索雷达；用搜索模板但给更大基础功率。"),
        RadarMappingCandidate("S-300PS 40B6MD sr", "5N66/76N6 Clam Shell", "search radar", "omni_search", 16.0, "medium", "research+skynet", "现代搜索/低空补盲类雷达，比 Big Bird 略弱。"),
        RadarMappingCandidate("S-300PS 40B6MD sr_19J6", "Tin Shield / 19J6", "search radar", "omni_search", 14.0, "medium", "skynet", "搜索类补充雷达，可先按中等搜索功率处理。"),

        RadarMappingCandidate("SNR_75V", "Fan Song", "legacy fire control radar", "legacy_fcr_wide", 7.0, "high", "research+skynet", "老式火控雷达，主瓣宽且旁瓣明显。"),
        RadarMappingCandidate("snr s-125 tr", "Low Blow / S-125 TR", "legacy fire control radar", "legacy_fcr_wide", 8.0, "high", "skynet", "与 SA-2 同代，略强。"),
        RadarMappingCandidate("Kub STR", "Straight Flush", "legacy fire control radar", "legacy_fcr_wide", 9.0, "high", "research", "你明确指定的老式火控模板代表。"),
        RadarMappingCandidate("Kub 1S91 str", "1S91 Straight Flush", "legacy fire control radar", "legacy_fcr_wide", 9.0, "high", "skynet", "与 Kub STR 视为同档。"),
        RadarMappingCandidate("Hawk tr", "Hawk HPIR", "legacy fire control radar", "legacy_fcr_wide", 10.0, "high", "research+skynet", "老式跟踪/照射雷达，主瓣明确但不算窄。"),
        RadarMappingCandidate("Osa 9A33 ln", "Osa / SA-8", "legacy fire control radar", "legacy_fcr_wide", 11.0, "high", "research+skynet", "一体化短程系统，但抗干扰能力仍有限。"),
        RadarMappingCandidate("ZSU-23-4 Shilka", "Shilka", "legacy tracking radar", "legacy_fcr_wide", 8.0, "medium", "research+skynet", "老式炮瞄跟踪雷达。"),
        RadarMappingCandidate("rapier_fsa_blindfire_radar", "Rapier Blindfire", "legacy fire control radar", "legacy_fcr_wide", 11.0, "medium", "skynet", "老式短程火控雷达，先按宽主瓣火控处理。"),

        RadarMappingCandidate("SA-11 Buk LN 9A310M1", "Buk Fire Dome", "mid-generation fire control radar", "mid_fcr_compact", 17.0, "high", "research+skynet", "中先进火控模板的代表样本。"),
        RadarMappingCandidate("SA-17 Buk M1-2 LN", "Buk M1-2", "mid-generation fire control radar", "mid_fcr_compact", 19.0, "high", "research", "比 SA-11 更强一档。"),
        RadarMappingCandidate("SA-11 Buk SR 9S18M1", "Snow Drift", "mid-generation search radar", "mid_fcr_compact", 15.0, "medium", "skynet", "搜索雷达，但方向性已明显收束。"),
        RadarMappingCandidate("Buk SR 9S18M1", "Snow Drift", "mid-generation search radar", "mid_fcr_compact", 15.0, "medium", "research", "与 Skynet 同名异写法别名。"),
        RadarMappingCandidate("Tor 9A331", "Tor", "modern short-range fire control radar", "mid_fcr_compact", 19.0, "medium", "research+skynet", "先进短程火控，但仍不建议归到相控阵火控档。"),
        RadarMappingCandidate("Roland ADS", "Roland ADS", "short-range tracking/fire control radar", "mid_fcr_compact", 14.0, "medium", "research", "代际新于 Hawk/SA-6，但不属高端阵列火控。"),
        RadarMappingCandidate("Roland Radar", "Roland Radar", "short-range search radar", "mid_fcr_compact", 14.0, "medium", "skynet", "和 Roland ADS 同档处理。"),
        RadarMappingCandidate("2S6 Tunguska", "Tunguska", "short-range tracking/fire control radar", "mid_fcr_compact", 15.0, "medium", "skynet", "现代近程系统，指向性和抗干扰强于老式火控。"),
        RadarMappingCandidate("Tunguska_2S6", "Tunguska", "short-range tracking/fire control radar", "mid_fcr_compact", 15.0, "medium", "research", "研究层别名。"),
        RadarMappingCandidate("Gepard", "Gepard", "short-range tracking radar", "mid_fcr_compact", 13.0, "medium", "research+skynet", "比 Shilka 更现代，但仍不应过强。"),
        RadarMappingCandidate("HQ-7_STR_SP", "HQ-7 STR", "short-range fire control radar", "mid_fcr_compact", 15.0, "low", "skynet", "缺少足够本地研究，暂放中先进短程档。"),
        RadarMappingCandidate("HEMTT_C-RAM_Phalanx", "C-RAM Phalanx", "close-in tracking radar", "mid_fcr_compact", 14.0, "low", "skynet", "先按中先进近程跟踪雷达处理。"),

        RadarMappingCandidate("S-300PS 40B6M tr", "30N6 Flap Lid", "aesa-like fire control radar", "aesa_fcr_narrow", 26.0, "high", "research+skynet", "你定义的最先进火控模板代表。"),
        RadarMappingCandidate("S-300PS 5H63C 30H6_tr", "30H6 TR", "aesa-like fire control radar", "aesa_fcr_narrow", 26.0, "high", "skynet", "与 30N6 同档。"),
        RadarMappingCandidate("Patriot str", "AN/MPQ-53/65", "aesa-like fire control radar", "aesa_fcr_narrow", 25.0, "high", "research+skynet", "现代相控阵火控雷达代表。"),

        RadarMappingCandidate("Strela-10M3", "Strela-10M3", "short-range acquisition/tracking", "legacy_fcr_wide", 6.0, "low", "skynet", "低优先级占位。"),
        RadarMappingCandidate("Strela-1 9P31", "Strela-1", "short-range acquisition/tracking", "legacy_fcr_wide", 5.0, "low", "skynet", "低优先级占位。"),
        RadarMappingCandidate("RLS_19J6", "Tin Shield", "search radar", "omni_search", 10.0, "medium", "skynet", "搜索/警戒雷达，先按搜索模板处理。"),
        RadarMappingCandidate("RPC_5N62V", "Square Pair / 5N62V", "long-range fire control radar", "legacy_fcr_wide", 12.0, "medium", "skynet", "SA-5 火控雷达，长程但仍属老式火控体制。"),
    ]


def build_template_lookup() -> Dict[str, TemplateProfile]:
    return build_template_profiles()


def build_mapping_lookup() -> Dict[str, RadarMappingCandidate]:
    return {entry.dcs_type_name: entry for entry in build_radar_mapping_candidates()}


def catalog_as_dict() -> Dict[str, object]:
    return {
        "templates": {key: asdict(profile) for key, profile in build_template_profiles().items()},
        "radar_mapping_candidates": [asdict(entry) for entry in build_radar_mapping_candidates()],
    }
