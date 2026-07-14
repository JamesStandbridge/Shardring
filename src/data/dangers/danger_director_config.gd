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
