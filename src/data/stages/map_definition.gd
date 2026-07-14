class_name MapDefinition
extends Resource

@export var map_id: StringName = &"toybox_mint"
@export var display_name: String = "Toybox Mint"
@export var arena_config: ArenaConfig = ArenaConfig.new()
@export var arena_theme: ArenaThemeConfig = ArenaThemeConfig.new()
@export var director_config: DangerDirectorConfig = DangerDirectorConfig.new()
@export var difficulty_config: DifficultyConfig = DifficultyConfig.new()
@export var default_danger_definition: DangerDefinition = DangerDefinition.new()
@export var danger_definitions: Array[DangerDefinition] = []


func is_valid_map() -> bool:
	return (
		not str(map_id).is_empty()
		and not display_name.is_empty()
		and arena_config != null
		and arena_config.radius_meters > 0.0
		and arena_theme != null
		and arena_theme.is_valid_theme()
		and director_config != null
		and director_config.credits_per_second > 0.0
		and difficulty_config != null
		and difficulty_config.max_intensity >= difficulty_config.starting_intensity
		and default_danger_definition != null
		and default_danger_definition.is_valid_definition()
	)


func get_danger_definitions() -> Array[DangerDefinition]:
	var definitions: Array[DangerDefinition] = []
	for definition: DangerDefinition in danger_definitions:
		if definition != null:
			definitions.append(definition)
	return definitions
