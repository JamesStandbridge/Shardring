class_name ProjectileLauncherConfig
extends Resource

enum LauncherType {
	SINGLE_SHOT,
	MULTI_SHOT,
	PERSISTENT,
}

enum TelegraphMode {
	FIXED_LENGTH,
	TO_TARGET,
}

@export var launcher_type: LauncherType = LauncherType.SINGLE_SHOT
@export var projectile_config: ProjectileConfig = ProjectileConfig.new()
@export var telegraph_duration_seconds: float = 1.35
@export var shot_count: int = 1
@export var shot_interval_seconds: float = 0.35
@export var linger_after_last_shot_seconds: float = 0.35
@export var launcher_lifetime_seconds: float = 2.5
@export var min_distance_from_player_meters: float = 8.0
@export var spawn_height_meters: float = 0.55
@export var shot_height_meters: float = 1.25
@export var muzzle_local_offset: Vector3 = Vector3(0.0, 0.1, -0.78)
@export var visual_yaw_offset_degrees: float = 0.0
@export var spawn_interval_seconds: float = 3.2
@export var initial_spawn_delay_seconds: float = 1.0
@export var spawn_search_attempts: int = 16
@export var max_active_launchers: int = 256
@export var max_active_projectiles: int = 4096
@export var launcher_visual_radius_meters: float = 0.55
@export var launcher_scene: PackedScene
@export var telegraph_visual_config: TelegraphVisualConfig
@export var telegraph_mode: TelegraphMode = TelegraphMode.TO_TARGET
@export var telegraph_visual_length_meters: float = 28.0
@export var telegraph_visual_width_meters: float = 0.24
@export var telegraph_visual_thickness_meters: float = 0.16
@export var telegraph_surface_height_meters: float = 0.1
@export var telegraph_min_length_meters: float = 2.5
@export var telegraph_target_padding_meters: float = 1.2
@export var telegraph_muzzle_marker_radius_meters: float = 0.13
@export var telegraph_target_marker_radius_meters: float = 0.22
@export var launcher_charge_scale_min: float = 0.68
@export var launcher_charge_scale_max: float = 1.35
@export var launcher_color: Color = Color(0.68, 0.08, 0.06, 1.0)
@export var charge_color: Color = Color(1.0, 0.34, 0.08, 1.0)
@export var telegraph_color: Color = Color(1.0, 0.18, 0.05, 1.0)
@export var emission_energy: float = 1.8
