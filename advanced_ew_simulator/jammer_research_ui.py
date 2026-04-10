#!/usr/bin/env python3
"""
Desktop UI for the jammer research layer.

Features:
- Select DCS radar type from mapped candidates
- Select jammer profile and jammer mode
- Adjust angle, distance, nearest visible enemy range, altitude, and gain via sliders
- View live JSR / probability outputs
- View radar gain polar plot and probability polar plot
"""

from __future__ import annotations

import math
import tkinter as tk
from tkinter import ttk

import matplotlib
matplotlib.use("TkAgg")
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from jammer_research_config import load_config, persist_ui_and_runtime_state
from jammer_research_engine import (
    SimulationInput,
    get_available_modes,
    get_default_jammer_profile,
    get_jammer_profile_metadata,
    get_jammer_profiles,
    get_radar_mapping_lookup,
    get_radar_options,
    get_sigmoid_k,
    get_template_profiles,
    sample_gain_curve,
    sample_jsr_probability_curve,
    sample_probability_curve,
    simulate,
)

FEET_PER_METER = 3.28084
METERS_PER_FOOT = 1.0 / FEET_PER_METER
AUTOSAVE_INTERVAL_MS = 10000


class JammerResearchUI:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Jammer Research UI")
        self.root.geometry("1500x900")
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

        self.radar_options = get_radar_options()
        self.radar_lookup = get_radar_mapping_lookup()
        self.template_profiles = get_template_profiles()
        self.config = load_config()
        self.ui_state = self.config.get("ui_state", {}) if isinstance(self.config.get("ui_state", {}), dict) else {}

        self.selected_radar_label = tk.StringVar()
        self.selected_template_key = tk.StringVar()
        self.selected_jammer_profile = tk.StringVar(
            value=str(self.ui_state.get("selected_jammer_profile", get_default_jammer_profile()))
        )
        self.selected_jammer_mode = tk.StringVar(
            value=str(self.ui_state.get("selected_jammer_mode", get_available_modes()[2]))
        )
        self.los_ok = tk.BooleanVar(value=bool(self.ui_state.get("los_ok", True)))

        self.angle_deg = tk.DoubleVar(value=float(self.ui_state.get("angle_deg", 10.0)))
        self.jammer_range_nm = tk.DoubleVar(value=float(self.ui_state.get("jammer_range_nm", 40.0)))
        self.target_range_nm = tk.DoubleVar(value=float(self.ui_state.get("target_range_nm", 20.0)))
        self.jammer_altitude_ft = tk.DoubleVar(value=float(self.ui_state.get("jammer_altitude_ft", 8000.0 * FEET_PER_METER)))
        self.extra_gain_db = tk.DoubleVar(value=float(self.ui_state.get("extra_gain_db", 0.0)))
        self.power_coeff_db = tk.DoubleVar(value=float(self.ui_state.get("power_coeff_db", 16.0)))
        self.sigmoid_k = tk.DoubleVar(value=float(self.ui_state.get("sigmoid_k", get_sigmoid_k())))

        self.mapped_template_text = tk.StringVar()
        self.mapped_power_text = tk.StringVar()
        self.radar_role_text = tk.StringVar()
        self.radar_notes_text = tk.StringVar()
        self.loadout_info_text = tk.StringVar()

        self.probability_text = tk.StringVar()
        self.jsr_text = tk.StringVar()
        self.effective_power_text = tk.StringVar()
        self.direction_gain_text = tk.StringVar()
        self.altitude_bonus_text = tk.StringVar()
        self.loadout_gain_text = tk.StringVar()
        self.pending_persist_payload = None

        self._build_layout()
        self._initialize_default_radar()
        self.update_view()
        self.root.after(AUTOSAVE_INTERVAL_MS, self._autosave_tick)

    def _build_layout(self) -> None:
        self.root.columnconfigure(0, weight=0)
        self.root.columnconfigure(1, weight=1)
        self.root.rowconfigure(0, weight=1)

        controls = ttk.Frame(self.root, padding=10)
        controls.grid(row=0, column=0, sticky="ns")

        plots = ttk.Frame(self.root, padding=10)
        plots.grid(row=0, column=1, sticky="nsew")
        plots.columnconfigure(0, weight=1)
        plots.rowconfigure(0, weight=1)

        self._build_controls(controls)
        self._build_plots(plots)

    def _build_controls(self, parent: ttk.Frame) -> None:
        row = 0

        ttk.Label(parent, text="Radar", font=("Segoe UI", 11, "bold")).grid(row=row, column=0, sticky="w")
        row += 1

        self.radar_combo = ttk.Combobox(
            parent,
            textvariable=self.selected_radar_label,
            values=[label for label, _ in self.radar_options],
            state="readonly",
            width=48,
        )
        self.radar_combo.grid(row=row, column=0, sticky="ew", pady=(0, 8))
        self.radar_combo.bind("<<ComboboxSelected>>", lambda _event: self.on_radar_change())
        row += 1

        ttk.Button(parent, text="Reload Params File", command=self.reload_from_config).grid(
            row=row, column=0, sticky="ew", pady=(0, 10)
        )
        row += 1

        info_frame = ttk.LabelFrame(parent, text="Mapped Radar Info", padding=8)
        info_frame.grid(row=row, column=0, sticky="ew", pady=(0, 10))
        info_frame.columnconfigure(1, weight=1)
        ttk.Label(info_frame, text="Mapped Template").grid(row=0, column=0, sticky="w")
        ttk.Label(info_frame, textvariable=self.mapped_template_text).grid(row=0, column=1, sticky="w")
        ttk.Label(info_frame, text="Mapped Power Coeff").grid(row=1, column=0, sticky="w")
        ttk.Label(info_frame, textvariable=self.mapped_power_text).grid(row=1, column=1, sticky="w")
        ttk.Label(info_frame, text="Radar Role").grid(row=2, column=0, sticky="w")
        ttk.Label(info_frame, textvariable=self.radar_role_text, wraplength=260).grid(row=2, column=1, sticky="w")
        ttk.Label(info_frame, text="Notes").grid(row=3, column=0, sticky="nw")
        ttk.Label(info_frame, textvariable=self.radar_notes_text, wraplength=260, justify="left").grid(row=3, column=1, sticky="w")
        row += 1

        model_frame = ttk.LabelFrame(parent, text="Simulation Inputs", padding=8)
        model_frame.grid(row=row, column=0, sticky="ew", pady=(0, 10))
        model_frame.columnconfigure(1, weight=1)

        ttk.Label(model_frame, text="Template").grid(row=0, column=0, sticky="w")
        self.template_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_template_key,
            values=list(self.template_profiles.keys()),
            state="readonly",
            width=22,
        )
        self.template_combo.grid(row=0, column=1, sticky="ew", pady=2)
        self.template_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())

        ttk.Label(model_frame, text="Power Coeff dB").grid(row=1, column=0, sticky="w")
        coeff_spin = tk.Spinbox(
            model_frame,
            from_=-10.0,
            to=40.0,
            increment=0.5,
            textvariable=self.power_coeff_db,
            width=12,
            command=self.update_view,
        )
        coeff_spin.grid(row=1, column=1, sticky="w", pady=2)
        coeff_spin.bind("<KeyRelease>", lambda _event: self.update_view())

        ttk.Label(model_frame, text="Loadout Preset").grid(row=2, column=0, sticky="w")
        self.jammer_profile_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_jammer_profile,
            values=get_jammer_profiles(),
            state="readonly",
            width=22,
        )
        self.jammer_profile_combo.grid(row=2, column=1, sticky="ew", pady=2)
        self.jammer_profile_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())
        ttk.Label(model_frame, textvariable=self.loadout_info_text, wraplength=260, justify="left").grid(
            row=3, column=0, columnspan=2, sticky="w", pady=(2, 4)
        )

        ttk.Label(model_frame, text="Jammer Mode").grid(row=4, column=0, sticky="w")
        self.jammer_mode_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_jammer_mode,
            values=get_available_modes(),
            state="readonly",
            width=22,
        )
        self.jammer_mode_combo.grid(row=4, column=1, sticky="ew", pady=2)
        self.jammer_mode_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())

        los_check = ttk.Checkbutton(model_frame, text="Line of Sight", variable=self.los_ok, command=self.update_view)
        los_check.grid(row=5, column=0, columnspan=2, sticky="w", pady=(4, 0))
        row += 1

        slider_frame = ttk.LabelFrame(parent, text="Geometry Controls", padding=8)
        slider_frame.grid(row=row, column=0, sticky="ew", pady=(0, 10))
        slider_frame.columnconfigure(0, weight=1)
        self._add_slider(slider_frame, 0, "Off-boresight Angle (deg)", self.angle_deg, 0.0, 90.0, 1.0)
        self._add_slider(slider_frame, 1, "Jammer -> Radar Range (nm)", self.jammer_range_nm, 5.0, 100.0, 1.0)
        self._add_slider(slider_frame, 2, "Nearest Visible Enemy Range (nm)", self.target_range_nm, 5.0, 100.0, 1.0)
        self._add_slider(slider_frame, 3, "Jammer Altitude (ft)", self.jammer_altitude_ft, 0.0, 50000.0, 100.0)
        self._add_slider(slider_frame, 4, "Manual Extra Gain (dB)", self.extra_gain_db, -10.0, 10.0, 0.5)
        self._add_slider(slider_frame, 5, "Sigmoid k", self.sigmoid_k, 0.05, 0.50, 0.01)
        row += 1

        result_frame = ttk.LabelFrame(parent, text="Live Result", padding=8)
        result_frame.grid(row=row, column=0, sticky="ew")
        result_frame.columnconfigure(1, weight=1)
        ttk.Label(result_frame, text="Jam Probability").grid(row=0, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.probability_text, font=("Segoe UI", 14, "bold")).grid(row=0, column=1, sticky="w")
        ttk.Label(result_frame, text="JSR").grid(row=1, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.jsr_text).grid(row=1, column=1, sticky="w")
        ttk.Label(result_frame, text="Loadout Gain (vs 1x ALQ-99)").grid(row=2, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.loadout_gain_text).grid(row=2, column=1, sticky="w")
        ttk.Label(result_frame, text="Altitude Bonus").grid(row=3, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.altitude_bonus_text).grid(row=3, column=1, sticky="w")
        ttk.Label(result_frame, text="Effective Jammer Power").grid(row=4, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.effective_power_text).grid(row=4, column=1, sticky="w")
        ttk.Label(result_frame, text="Radar Direction Gain").grid(row=5, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.direction_gain_text).grid(row=5, column=1, sticky="w")

    def _build_plots(self, parent: ttk.Frame) -> None:
        self.figure = Figure(figsize=(10, 8), dpi=100)
        grid = self.figure.add_gridspec(2, 2, height_ratios=[1.0, 0.8])
        self.gain_ax = self.figure.add_subplot(grid[0, 0], projection="polar")
        self.prob_ax = self.figure.add_subplot(grid[0, 1], projection="polar")
        self.jsr_curve_ax = self.figure.add_subplot(grid[1, :])
        self.figure.tight_layout()

        self.canvas = FigureCanvasTkAgg(self.figure, master=parent)
        canvas_widget = self.canvas.get_tk_widget()
        canvas_widget.grid(row=0, column=0, sticky="nsew")

    def _add_slider(
        self,
        parent: ttk.LabelFrame,
        row: int,
        label: str,
        variable: tk.DoubleVar,
        minimum: float,
        maximum: float,
        resolution: float,
    ) -> None:
        wrapper = ttk.Frame(parent)
        wrapper.grid(row=row, column=0, sticky="ew", pady=4)
        wrapper.columnconfigure(0, weight=1)
        ttk.Label(wrapper, text=label).grid(row=0, column=0, sticky="w")
        ttk.Label(wrapper, textvariable=variable, width=8).grid(row=0, column=1, sticky="e")
        scale = tk.Scale(
            wrapper,
            from_=minimum,
            to=maximum,
            orient="horizontal",
            resolution=resolution,
            variable=variable,
            showvalue=False,
            command=lambda _value: self.update_view(),
            length=320,
        )
        scale.grid(row=1, column=0, columnspan=2, sticky="ew")

    def _initialize_default_radar(self) -> None:
        if not self.radar_options:
            return
        saved_label = str(self.ui_state.get("selected_radar_label", ""))
        valid_labels = {label for label, _ in self.radar_options}
        default_label = saved_label if saved_label in valid_labels else self.radar_options[0][0]
        self.selected_radar_label.set(default_label)
        self.on_radar_change()

    def _reload_runtime_collections(self) -> None:
        current_radar_label = self.selected_radar_label.get()
        current_template_key = self.selected_template_key.get()
        current_jammer_profile = self.selected_jammer_profile.get()
        current_jammer_mode = self.selected_jammer_mode.get()

        self.radar_options = get_radar_options()
        self.radar_lookup = get_radar_mapping_lookup()
        self.template_profiles = get_template_profiles()

        radar_labels = [label for label, _ in self.radar_options]
        template_keys = list(self.template_profiles.keys())
        jammer_profiles = get_jammer_profiles()
        jammer_modes = get_available_modes()

        self.radar_combo["values"] = radar_labels
        self.template_combo["values"] = template_keys
        self.jammer_profile_combo["values"] = jammer_profiles
        self.jammer_mode_combo["values"] = jammer_modes

        if radar_labels and current_radar_label not in radar_labels:
            self.selected_radar_label.set(radar_labels[0])
        if template_keys and current_template_key not in template_keys:
            self.selected_template_key.set(template_keys[0])
        if jammer_profiles and current_jammer_profile not in jammer_profiles:
            self.selected_jammer_profile.set(jammer_profiles[0])
        if jammer_modes and current_jammer_mode not in jammer_modes:
            self.selected_jammer_mode.set(jammer_modes[0])

    def reload_from_config(self) -> None:
        self.config = load_config()
        self.ui_state = self.config.get("ui_state", {}) if isinstance(self.config.get("ui_state", {}), dict) else {}

        self.selected_jammer_profile.set(str(self.ui_state.get("selected_jammer_profile", get_default_jammer_profile())))
        self.selected_jammer_mode.set(str(self.ui_state.get("selected_jammer_mode", get_available_modes()[0])))
        self.los_ok.set(bool(self.ui_state.get("los_ok", True)))
        self.angle_deg.set(float(self.ui_state.get("angle_deg", 10.0)))
        self.jammer_range_nm.set(float(self.ui_state.get("jammer_range_nm", 40.0)))
        self.target_range_nm.set(float(self.ui_state.get("target_range_nm", 20.0)))
        self.jammer_altitude_ft.set(float(self.ui_state.get("jammer_altitude_ft", 8000.0 * FEET_PER_METER)))
        self.extra_gain_db.set(float(self.ui_state.get("extra_gain_db", 0.0)))
        self.power_coeff_db.set(float(self.ui_state.get("power_coeff_db", 16.0)))
        self.sigmoid_k.set(float(self.ui_state.get("sigmoid_k", get_sigmoid_k())))

        self._reload_runtime_collections()

        radar_labels = {label for label, _ in self.radar_options}
        saved_label = str(self.ui_state.get("selected_radar_label", ""))
        if saved_label in radar_labels:
            self.selected_radar_label.set(saved_label)
        elif self.radar_options:
            self.selected_radar_label.set(self.radar_options[0][0])

        self.on_radar_change()

    def _get_selected_radar_name(self) -> str:
        selected_label = self.selected_radar_label.get()
        for label, radar_name in self.radar_options:
            if label == selected_label:
                return radar_name
        return self.radar_options[0][1]

    def on_radar_change(self) -> None:
        self._reload_runtime_collections()
        radar_name = self._get_selected_radar_name()
        mapping = self.radar_lookup[radar_name]
        self.selected_template_key.set(mapping.template_key)
        self.power_coeff_db.set(mapping.power_coeff_db)
        self.mapped_template_text.set(mapping.template_key)
        self.mapped_power_text.set(f"{mapping.power_coeff_db:.1f} dB")
        self.radar_role_text.set(mapping.radar_role)
        self.radar_notes_text.set(mapping.notes)
        self.update_view()

    def _build_input(self) -> SimulationInput:
        return SimulationInput(
            radar_type_name=self._get_selected_radar_name(),
            template_key=self.selected_template_key.get(),
            power_coeff_db=float(self.power_coeff_db.get()),
            jammer_profile=self.selected_jammer_profile.get(),
            jammer_mode=self.selected_jammer_mode.get(),
            angle_deg=float(self.angle_deg.get()),
            jammer_range_nm=float(self.jammer_range_nm.get()),
            target_range_nm=float(self.target_range_nm.get()),
            jammer_altitude_m=float(self.jammer_altitude_ft.get()) * METERS_PER_FOOT,
            los_ok=bool(self.los_ok.get()),
            extra_jammer_gain_db=float(self.extra_gain_db.get()),
            sigmoid_k=float(self.sigmoid_k.get()),
        )

    def _queue_persist_state(self, input_data: SimulationInput) -> None:
        self.pending_persist_payload = {
            "selected_radar_name": input_data.radar_type_name,
            "ui_state": {
                "selected_radar_label": self.selected_radar_label.get(),
                "selected_template_key": input_data.template_key,
                "selected_jammer_profile": input_data.jammer_profile,
                "selected_jammer_mode": input_data.jammer_mode,
                "los_ok": input_data.los_ok,
                "angle_deg": float(self.angle_deg.get()),
                "jammer_range_nm": float(self.jammer_range_nm.get()),
                "target_range_nm": float(self.target_range_nm.get()),
                "jammer_altitude_ft": float(self.jammer_altitude_ft.get()),
                "extra_gain_db": float(self.extra_gain_db.get()),
                "power_coeff_db": float(self.power_coeff_db.get()),
                "sigmoid_k": float(self.sigmoid_k.get()),
            },
            "template_key": input_data.template_key,
            "power_coeff_db": input_data.power_coeff_db,
            "sigmoid_k": float(self.sigmoid_k.get()),
        }

    def _flush_pending_state(self) -> None:
        if not self.pending_persist_payload:
            return
        payload = self.pending_persist_payload
        persist_ui_and_runtime_state(
            selected_radar_name=payload["selected_radar_name"],
            ui_state=payload["ui_state"],
            template_key=payload["template_key"],
            power_coeff_db=payload["power_coeff_db"],
            sigmoid_k=payload["sigmoid_k"],
        )
        self.pending_persist_payload = None

    def _autosave_tick(self) -> None:
        try:
            self._flush_pending_state()
        finally:
            if self.root.winfo_exists():
                self.root.after(AUTOSAVE_INTERVAL_MS, self._autosave_tick)

    def on_close(self) -> None:
        try:
            self._flush_pending_state()
        finally:
            self.root.destroy()

    def update_view(self) -> None:
        try:
            self._reload_runtime_collections()
            radar_name = self._get_selected_radar_name()
            mapping = self.radar_lookup[radar_name]
            self.mapped_template_text.set(mapping.template_key)
            self.mapped_power_text.set(f"{mapping.power_coeff_db:.1f} dB")
            self.radar_role_text.set(mapping.radar_role)
            self.radar_notes_text.set(mapping.notes)
            profile_metadata = get_jammer_profile_metadata(self.selected_jammer_profile.get())
            self.loadout_info_text.set(
                "ALQ-99 x{alq99} | ALQ-249 x{alq249} | channels {channels:.0f} | total power {total:.0f} | cap {cap:.0f} | baseline: 1x ALQ-99 = 0 dB".format(
                    alq99=int(profile_metadata["alq99"]),
                    alq249=int(profile_metadata["alq249"]),
                    channels=profile_metadata["total_channels"],
                    cap=profile_metadata["cap"],
                    total=profile_metadata["total_jam_value"],
                )
            )
            input_data = self._build_input()
            result = simulate(input_data)
            self.probability_text.set(f"{result.jam_probability:.3f}")
            self.jsr_text.set(f"{result.jsr_db:.2f} dB")
            self.loadout_gain_text.set(f"{result.profile_gain_db:.2f} dB")
            self.altitude_bonus_text.set(f"{result.altitude_bonus_db:.2f} dB")
            self.effective_power_text.set(f"{result.effective_jammer_power_db:.2f} dB")
            self.direction_gain_text.set(f"{result.radar_direction_gain_db:.2f} dB")
            self._queue_persist_state(input_data)
            self._draw_plots(input_data, result)
        except Exception as exc:
            self.probability_text.set("error")
            self.jsr_text.set(str(exc))
            self.loadout_info_text.set("-")
            self.loadout_gain_text.set("-")
            self.altitude_bonus_text.set("-")
            self.effective_power_text.set("-")
            self.direction_gain_text.set("-")

    def _draw_plots(self, input_data: SimulationInput, result) -> None:
        self.gain_ax.clear()
        self.prob_ax.clear()
        self.jsr_curve_ax.clear()

        theta_deg, gain_db = sample_gain_curve(input_data.template_key, step_deg=1.0)
        theta_wrapped = [math.radians((theta + 360.0) % 360.0) for theta in theta_deg]
        min_db = min(-60.0, float(min(gain_db)) - 5.0)
        radius = [max(g, min_db) - min_db for g in gain_db]

        self.gain_ax.plot(theta_wrapped, radius, linewidth=2)
        self.gain_ax.fill(theta_wrapped, radius, alpha=0.15)
        self.gain_ax.set_title("Radar Gain Polar", va="bottom")
        tick_values_db = [min_db, -40.0, -30.0, -20.0, -10.0, 0.0]
        tick_values_db = sorted(set(v for v in tick_values_db if v >= min_db))
        tick_positions = [value - min_db for value in tick_values_db]
        self.gain_ax.set_rticks(tick_positions)
        self.gain_ax.set_yticklabels([f"{int(value)} dB" for value in tick_values_db])
        self.gain_ax.set_ylim(0, max(tick_positions) if tick_positions else 1)

        selected_angle_rad = math.radians(input_data.angle_deg)
        current_gain_radius = max(result.radar_direction_gain_db, min_db) - min_db
        self.gain_ax.plot([selected_angle_rad, selected_angle_rad], [0, current_gain_radius], color="red", linewidth=2)
        self.gain_ax.scatter([selected_angle_rad], [current_gain_radius], color="red", s=30)

        prob_theta_deg, probabilities = sample_probability_curve(input_data, step_deg=1.0)
        prob_theta_wrapped = [math.radians(theta) for theta in prob_theta_deg]
        self.prob_ax.plot(prob_theta_wrapped, probabilities, linewidth=2)
        self.prob_ax.fill(prob_theta_wrapped, probabilities, alpha=0.15)
        self.prob_ax.set_title("Jam Probability Polar", va="bottom")
        self.prob_ax.set_rticks([0.2, 0.4, 0.6, 0.8, 1.0])
        self.prob_ax.set_ylim(0, 1.0)

        self.prob_ax.plot([selected_angle_rad, selected_angle_rad], [0, result.jam_probability], color="red", linewidth=2)
        self.prob_ax.scatter([selected_angle_rad], [result.jam_probability], color="red", s=30)

        sigmoid_k = float(self.sigmoid_k.get())
        jsr_values, curve_probabilities = sample_jsr_probability_curve(sigmoid_k=sigmoid_k)
        self.jsr_curve_ax.plot(jsr_values, curve_probabilities, linewidth=2, label=f"Sigmoid k={sigmoid_k:.2f}")
        self.jsr_curve_ax.axvline(0.0, color="gray", linestyle="--", linewidth=1)
        self.jsr_curve_ax.axhline(0.5, color="gray", linestyle="--", linewidth=1)
        self.jsr_curve_ax.scatter([result.jsr_db], [result.jam_probability], color="red", s=36, zorder=5)
        self.jsr_curve_ax.annotate(
            f"Current: {result.jsr_db:.2f} dB / {result.jam_probability:.3f}",
            xy=(result.jsr_db, result.jam_probability),
            xytext=(10, 10),
            textcoords="offset points",
            color="red",
        )
        self.jsr_curve_ax.set_title("JSR(dB) -> Jamming Probability", pad=10)
        self.jsr_curve_ax.set_xlabel("JSR (dB)")
        self.jsr_curve_ax.set_ylabel("Jamming Probability")
        self.jsr_curve_ax.set_xlim(float(jsr_values[0]), float(jsr_values[-1]))
        self.jsr_curve_ax.set_ylim(0.0, 1.0)
        self.jsr_curve_ax.grid(True, alpha=0.3)
        self.jsr_curve_ax.legend(loc="lower right")

        self.figure.tight_layout()
        self.canvas.draw_idle()


def main() -> None:
    root = tk.Tk()
    JammerResearchUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
