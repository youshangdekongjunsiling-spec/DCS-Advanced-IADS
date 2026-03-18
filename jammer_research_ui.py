#!/usr/bin/env python3
"""
Desktop UI for the jammer research layer.

Features:
- Select DCS radar type from mapped candidates
- Select jammer profile and jammer mode
- Adjust angle, distance, target range, altitude, and gain via sliders
- View live JSR / probability outputs
- View radar gain polar plot and probability polar plot
"""

from __future__ import annotations

import math
import tkinter as tk
from tkinter import ttk

from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from jammer_research_engine import (
    SimulationInput,
    get_available_modes,
    get_jammer_profiles,
    get_radar_mapping_lookup,
    get_radar_options,
    get_template_profiles,
    sample_gain_curve,
    sample_probability_curve,
    simulate,
)


class JammerResearchUI:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Jammer Research UI")
        self.root.geometry("1500x900")

        self.radar_options = get_radar_options()
        self.radar_lookup = get_radar_mapping_lookup()
        self.template_profiles = get_template_profiles()

        self.selected_radar_label = tk.StringVar()
        self.selected_template_key = tk.StringVar()
        self.selected_jammer_profile = tk.StringVar(value=get_jammer_profiles()[0])
        self.selected_jammer_mode = tk.StringVar(value=get_available_modes()[2])
        self.los_ok = tk.BooleanVar(value=True)

        self.angle_deg = tk.DoubleVar(value=10.0)
        self.jammer_range_nm = tk.DoubleVar(value=40.0)
        self.target_range_nm = tk.DoubleVar(value=20.0)
        self.jammer_altitude_m = tk.DoubleVar(value=8000.0)
        self.extra_gain_db = tk.DoubleVar(value=0.0)
        self.power_coeff_db = tk.DoubleVar(value=16.0)

        self.mapped_template_text = tk.StringVar()
        self.mapped_power_text = tk.StringVar()
        self.radar_role_text = tk.StringVar()
        self.radar_notes_text = tk.StringVar()

        self.probability_text = tk.StringVar()
        self.jsr_text = tk.StringVar()
        self.effective_power_text = tk.StringVar()
        self.direction_gain_text = tk.StringVar()

        self._build_layout()
        self._initialize_default_radar()
        self.update_view()

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

        radar_combo = ttk.Combobox(
            parent,
            textvariable=self.selected_radar_label,
            values=[label for label, _ in self.radar_options],
            state="readonly",
            width=48,
        )
        radar_combo.grid(row=row, column=0, sticky="ew", pady=(0, 8))
        radar_combo.bind("<<ComboboxSelected>>", lambda _event: self.on_radar_change())
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
        template_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_template_key,
            values=list(self.template_profiles.keys()),
            state="readonly",
            width=22,
        )
        template_combo.grid(row=0, column=1, sticky="ew", pady=2)
        template_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())

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

        ttk.Label(model_frame, text="Jammer Profile").grid(row=2, column=0, sticky="w")
        jammer_profile_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_jammer_profile,
            values=get_jammer_profiles(),
            state="readonly",
            width=22,
        )
        jammer_profile_combo.grid(row=2, column=1, sticky="ew", pady=2)
        jammer_profile_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())

        ttk.Label(model_frame, text="Jammer Mode").grid(row=3, column=0, sticky="w")
        jammer_mode_combo = ttk.Combobox(
            model_frame,
            textvariable=self.selected_jammer_mode,
            values=get_available_modes(),
            state="readonly",
            width=22,
        )
        jammer_mode_combo.grid(row=3, column=1, sticky="ew", pady=2)
        jammer_mode_combo.bind("<<ComboboxSelected>>", lambda _event: self.update_view())

        los_check = ttk.Checkbutton(model_frame, text="Line of Sight", variable=self.los_ok, command=self.update_view)
        los_check.grid(row=4, column=0, columnspan=2, sticky="w", pady=(4, 0))
        row += 1

        slider_frame = ttk.LabelFrame(parent, text="Geometry Controls", padding=8)
        slider_frame.grid(row=row, column=0, sticky="ew", pady=(0, 10))
        slider_frame.columnconfigure(0, weight=1)
        self._add_slider(slider_frame, 0, "Off-boresight Angle (deg)", self.angle_deg, 0.0, 90.0, 1.0)
        self._add_slider(slider_frame, 1, "Jammer -> Radar Range (nm)", self.jammer_range_nm, 5.0, 100.0, 1.0)
        self._add_slider(slider_frame, 2, "Radar -> Target Range (nm)", self.target_range_nm, 5.0, 100.0, 1.0)
        self._add_slider(slider_frame, 3, "Jammer Altitude (m)", self.jammer_altitude_m, 0.0, 15000.0, 100.0)
        self._add_slider(slider_frame, 4, "Manual Extra Gain (dB)", self.extra_gain_db, -10.0, 10.0, 0.5)
        row += 1

        result_frame = ttk.LabelFrame(parent, text="Live Result", padding=8)
        result_frame.grid(row=row, column=0, sticky="ew")
        result_frame.columnconfigure(1, weight=1)
        ttk.Label(result_frame, text="Jam Probability").grid(row=0, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.probability_text, font=("Segoe UI", 14, "bold")).grid(row=0, column=1, sticky="w")
        ttk.Label(result_frame, text="JSR").grid(row=1, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.jsr_text).grid(row=1, column=1, sticky="w")
        ttk.Label(result_frame, text="Effective Jammer Power").grid(row=2, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.effective_power_text).grid(row=2, column=1, sticky="w")
        ttk.Label(result_frame, text="Radar Direction Gain").grid(row=3, column=0, sticky="w")
        ttk.Label(result_frame, textvariable=self.direction_gain_text).grid(row=3, column=1, sticky="w")

    def _build_plots(self, parent: ttk.Frame) -> None:
        self.figure = Figure(figsize=(10, 6), dpi=100)
        self.gain_ax = self.figure.add_subplot(121, projection="polar")
        self.prob_ax = self.figure.add_subplot(122, projection="polar")
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
        default_label, _ = self.radar_options[0]
        self.selected_radar_label.set(default_label)
        self.on_radar_change()

    def _get_selected_radar_name(self) -> str:
        selected_label = self.selected_radar_label.get()
        for label, radar_name in self.radar_options:
            if label == selected_label:
                return radar_name
        return self.radar_options[0][1]

    def on_radar_change(self) -> None:
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
            jammer_altitude_m=float(self.jammer_altitude_m.get()),
            los_ok=bool(self.los_ok.get()),
            extra_jammer_gain_db=float(self.extra_gain_db.get()),
        )

    def update_view(self) -> None:
        try:
            input_data = self._build_input()
            result = simulate(input_data)
            self.probability_text.set(f"{result.jam_probability:.3f}")
            self.jsr_text.set(f"{result.jsr_db:.2f} dB")
            self.effective_power_text.set(f"{result.effective_jammer_power_db:.2f} dB")
            self.direction_gain_text.set(f"{result.radar_direction_gain_db:.2f} dB")
            self._draw_plots(input_data, result)
        except Exception as exc:
            self.probability_text.set("error")
            self.jsr_text.set(str(exc))
            self.effective_power_text.set("-")
            self.direction_gain_text.set("-")

    def _draw_plots(self, input_data: SimulationInput, result) -> None:
        self.gain_ax.clear()
        self.prob_ax.clear()

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

        self.figure.tight_layout()
        self.canvas.draw_idle()


def main() -> None:
    root = tk.Tk()
    JammerResearchUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
