class_name DangerDirectorConfig
extends Resource

@export var credits_per_second: float = 1.25
@export var max_stored_credits: float = 8.0
@export var initial_decision_delay_seconds: float = 1.0
@export var decision_interval_seconds: float = 0.35
@export var max_total_active_dangers: int = 64
@export var skip_log_interval: int = 20
@export var first_peak_delay_seconds: float = 4.0
@export var peak_duration_seconds: float = 12.0
@export var recovery_duration_seconds: float = 5.0
@export var peak_credit_multiplier: float = 1.75
@export var peak_decision_interval_multiplier: float = 0.65
@export var recovery_credit_multiplier: float = 0.45
@export var exit_credit_multiplier: float = 0.55
@export var exit_decision_interval_multiplier: float = 1.45
@export var max_readability_pressure: int = 5
@export var exit_max_readability_pressure: int = 3
@export var peak_max_readability_pressure: int = 7


func is_valid_config() -> bool:
	return (
		credits_per_second > 0.0
		and max_stored_credits > 0.0
		and initial_decision_delay_seconds >= 0.0
		and decision_interval_seconds > 0.0
		and max_total_active_dangers > 0
		and skip_log_interval > 0
		and first_peak_delay_seconds >= 0.0
		and peak_duration_seconds > 0.0
		and recovery_duration_seconds > 0.0
		and peak_credit_multiplier > 0.0
		and peak_decision_interval_multiplier > 0.0
		and recovery_credit_multiplier >= 0.0
		and exit_credit_multiplier >= 0.0
		and exit_decision_interval_multiplier > 0.0
		and max_readability_pressure >= 0
		and exit_max_readability_pressure >= 0
		and peak_max_readability_pressure >= 0
	)
