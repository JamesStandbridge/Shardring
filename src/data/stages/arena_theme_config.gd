class_name ArenaThemeConfig
extends Resource

@export var theme_id: StringName = &"kenney_meadow"
@export var display_name: String = "Kenney Meadow"
@export var floor_colors: PackedColorArray = PackedColorArray(
	[
		Color(0.38, 0.55, 0.34, 1.0),
		Color(0.39, 0.56, 0.35, 1.0),
		Color(0.37, 0.54, 0.33, 1.0),
		Color(0.40, 0.55, 0.34, 1.0),
	]
)
@export var terrain_texture_enabled: bool = true
@export var terrain_albedo_texture: Texture2D
@export var terrain_detail_texture: Texture2D
@export var terrain_base_color: Color = Color(0.34, 0.50, 0.30, 1.0)
@export var terrain_secondary_color: Color = Color(0.42, 0.57, 0.34, 1.0)
@export var terrain_accent_color: Color = Color(0.52, 0.45, 0.28, 1.0)
@export var terrain_texture_strength: float = 0.78
@export var terrain_color_variation_strength: float = 0.22
@export var terrain_texture_tile_meters: float = 6.5
@export var terrain_patch_scale_meters: float = 10.0
@export var terrain_detail_texture_strength: float = 0.16
@export var terrain_detail_texture_tile_meters: float = 2.2
@export var terrain_detail_scale_meters: float = 2.6
@export var terrain_detail_strength: float = 0.07
@export var terrain_speckle_strength: float = 0.035
@export var wall_color: Color = Color(0.36, 0.28, 0.21, 1.0)
@export var seam_color: Color = Color(0.22, 0.34, 0.25, 1.0)
@export var border_color: Color = Color(0.48, 0.37, 0.24, 1.0)
@export var seam_width_meters: float = 0.0
@export var border_width_meters: float = 0.34
@export var trim_height_offset_meters: float = 0.045
@export var material_roughness: float = 0.86
@export var background_color: Color = Color(0.60, 0.78, 0.88, 1.0)
@export var ambient_light_color: Color = Color(1.0, 0.95, 0.84, 1.0)
@export var ambient_light_energy: float = 0.76
@export var key_light_color: Color = Color(1.0, 0.93, 0.76, 1.0)
@export var key_light_energy: float = 1.28
@export var fill_light_color: Color = Color(0.62, 0.76, 1.0, 1.0)
@export var fill_light_energy: float = 0.44


func is_valid_theme() -> bool:
	return (
		not str(theme_id).is_empty()
		and not display_name.is_empty()
		and floor_colors.size() > 0
		and terrain_texture_strength >= 0.0
		and terrain_texture_strength <= 1.0
		and terrain_color_variation_strength >= 0.0
		and terrain_color_variation_strength <= 1.0
		and terrain_texture_tile_meters > 0.0
		and terrain_patch_scale_meters > 0.0
		and terrain_detail_texture_strength >= 0.0
		and terrain_detail_texture_strength <= 1.0
		and terrain_detail_texture_tile_meters > 0.0
		and terrain_detail_scale_meters > 0.0
		and terrain_detail_strength >= 0.0
		and terrain_detail_strength <= 1.0
		and terrain_speckle_strength >= 0.0
		and terrain_speckle_strength <= 1.0
		and seam_width_meters >= 0.0
		and border_width_meters >= 0.0
		and trim_height_offset_meters >= 0.0
		and material_roughness >= 0.0
		and material_roughness <= 1.0
		and ambient_light_energy >= 0.0
		and key_light_energy >= 0.0
		and fill_light_energy >= 0.0
	)


func get_floor_color(index: int) -> Color:
	if floor_colors.is_empty():
		return terrain_base_color
	var palette_color := floor_colors[index % floor_colors.size()]
	return terrain_base_color.lerp(palette_color, terrain_color_variation_strength * 0.25)
