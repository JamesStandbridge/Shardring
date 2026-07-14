class_name CameraShakeConfig
extends Resource

@export var duration_seconds: float = 0.14
@export var amplitude_meters: float = 0.07
@export var angular_amplitude_degrees: float = 0.45
@export var frequency_hz: float = 24.0
@export var decay_power: float = 1.8
@export var vertical_axis_ratio: float = 0.65


func is_valid_config() -> bool:
	return (
		duration_seconds > 0.0
		and amplitude_meters >= 0.0
		and angular_amplitude_degrees >= 0.0
		and frequency_hz > 0.0
		and decay_power > 0.0
		and vertical_axis_ratio >= 0.0
	)
