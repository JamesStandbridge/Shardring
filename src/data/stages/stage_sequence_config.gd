class_name StageSequenceConfig
extends Resource

@export var maps: Array[MapDefinition] = [MapDefinition.new()]
@export var base_required_threat_budget: float = 22.0
@export var threat_budget_per_level: float = 8.0
@export var difficulty_intensity_per_level: float = 0.25
@export var map_seed_stride: int = 1009


func is_valid_sequence() -> bool:
	if (
		maps.is_empty()
		or base_required_threat_budget <= 0.0
		or threat_budget_per_level < 0.0
		or difficulty_intensity_per_level < 0.0
		or map_seed_stride <= 0
	):
		return false

	for map_definition: MapDefinition in maps:
		if map_definition == null or not map_definition.is_valid_map():
			return false

	return true


func get_map_for_level(level_index: int) -> MapDefinition:
	if maps.is_empty():
		return null

	var safe_level_index := maxi(level_index, 1)
	var map_index := (safe_level_index - 1) % maps.size()
	return maps[map_index]


func get_required_threat_budget_for_level(level_index: int) -> float:
	var safe_level_index := maxi(level_index, 1)
	return base_required_threat_budget + float(safe_level_index - 1) * threat_budget_per_level


func get_generation_seed_for_level(map_definition: MapDefinition, level_index: int) -> int:
	var safe_level_index := maxi(level_index, 1)
	var base_seed := 1
	if map_definition != null and map_definition.arena_config != null:
		base_seed = map_definition.arena_config.generation_seed
	return base_seed + (safe_level_index - 1) * map_seed_stride


func get_starting_intensity_for_level(map_definition: MapDefinition, level_index: int) -> float:
	var base_intensity := 1.0
	var max_intensity := 1.0
	if map_definition != null and map_definition.difficulty_config != null:
		base_intensity = map_definition.difficulty_config.starting_intensity
		max_intensity = map_definition.difficulty_config.max_intensity

	var safe_level_index := maxi(level_index, 1)
	return minf(
		base_intensity + float(safe_level_index - 1) * difficulty_intensity_per_level, max_intensity
	)
