class_name ShardObjectiveConfig
extends Resource

@export var base_required_shards: int = 3
@export var additional_shard_every_levels: int = 2
@export var max_required_shards: int = 7
@export var pickup_radius_meters: float = 1.15
@export var min_distance_from_player_meters: float = 9.0
@export var center_safe_radius_meters: float = 5.0
@export var spawn_delay_after_collect_seconds: float = 1.2
@export var risk_tier_per_collected_shard: int = 1
@export var post_collect_peak_duration_seconds: float = 5.0
@export var intensity_bonus_per_collected_shard: float = 0.45
@export var spawn_search_attempts: int = 36
@export var visual_height_offset_meters: float = 0.85


func is_valid_config() -> bool:
	return (
		base_required_shards > 0
		and additional_shard_every_levels > 0
		and max_required_shards >= base_required_shards
		and pickup_radius_meters > 0.0
		and min_distance_from_player_meters >= 0.0
		and center_safe_radius_meters >= 0.0
		and spawn_delay_after_collect_seconds >= 0.0
		and risk_tier_per_collected_shard >= 0
		and post_collect_peak_duration_seconds >= 0.0
		and intensity_bonus_per_collected_shard >= 0.0
		and spawn_search_attempts > 0
		and visual_height_offset_meters >= 0.0
	)


func get_required_shards_for_level(level_index: int) -> int:
	var safe_level_index := maxi(level_index, 1)
	var added_shards := floori(float(safe_level_index - 1) / float(additional_shard_every_levels))
	return mini(base_required_shards + added_shards, max_required_shards)
