class_name ArenaConfig
extends Resource

@export var radius_meters: float = 42.0
@export var thickness_meters: float = 1.0
@export var cell_count: int = 72
@export var boundary_vertex_count: int = 128
@export var boundary_irregularity_meters: float = 3.2
@export var boundary_irregularity_control_points: int = 14
@export var min_cell_site_distance_meters: float = 3.0
@export var surface_height_amplitude_meters: float = 0.45
@export var surface_height_frequency: float = 0.13
@export var reconstruction_interval_seconds: float = 30.0
@export var generation_seed: int = 42
@export var debug_show_cell_labels: bool = false
