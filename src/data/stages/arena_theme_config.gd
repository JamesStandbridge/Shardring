class_name ArenaThemeConfig
extends Resource

@export var theme_id: StringName = &"toybox_mint"
@export var display_name: String = "Toybox Mint"
@export var floor_colors: PackedColorArray = PackedColorArray(
	[
		Color(0.42, 0.66, 0.59, 1.0),
		Color(0.45, 0.61, 0.75, 1.0),
		Color(0.55, 0.68, 0.47, 1.0),
		Color(0.66, 0.52, 0.62, 1.0),
		Color(0.48, 0.63, 0.52, 1.0),
	]
)
@export var background_color: Color = Color(0.68, 0.84, 0.88, 1.0)
@export var ambient_light_color: Color = Color(1.0, 0.96, 0.88, 1.0)
@export var ambient_light_energy: float = 0.72
@export var key_light_color: Color = Color(1.0, 0.96, 0.88, 1.0)
@export var key_light_energy: float = 1.35
@export var fill_light_color: Color = Color(0.64, 0.76, 1.0, 1.0)
@export var fill_light_energy: float = 0.45


func is_valid_theme() -> bool:
	return (
		not str(theme_id).is_empty()
		and not display_name.is_empty()
		and floor_colors.size() > 0
		and ambient_light_energy >= 0.0
		and key_light_energy >= 0.0
		and fill_light_energy >= 0.0
	)


func get_floor_color(index: int) -> Color:
	if floor_colors.is_empty():
		return Color(0.42, 0.66, 0.59, 1.0)
	return floor_colors[index % floor_colors.size()]
