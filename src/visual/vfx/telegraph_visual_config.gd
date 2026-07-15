class_name TelegraphVisualConfig
extends Resource

@export var beam_color: Color = Color(1.0, 0.12, 0.18, 0.62)
@export var marker_color: Color = Color(1.0, 0.22, 0.28, 0.82)
@export var beam_enabled: bool = true
@export var beam_radius_meters: float = 0.055
@export var muzzle_marker_radius_meters: float = 0.12
@export var target_marker_radius_meters: float = 0.24
@export var segment_count: int = 7
@export_range(0.0, 0.8, 0.01) var segment_gap_ratio: float = 0.32
@export var pulse_speed_hz: float = 2.8
@export var pulse_scale_strength: float = 0.22
@export var emission_energy: float = 2.2
@export var no_depth_test: bool = false


func is_valid_config() -> bool:
	return (
		beam_radius_meters > 0.0
		and muzzle_marker_radius_meters > 0.0
		and target_marker_radius_meters > 0.0
		and segment_count > 0
		and segment_gap_ratio >= 0.0
		and segment_gap_ratio < 1.0
		and pulse_speed_hz >= 0.0
		and pulse_scale_strength >= 0.0
		and emission_energy >= 0.0
	)
