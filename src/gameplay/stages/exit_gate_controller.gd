class_name ExitGateController
extends Node3D

signal gate_entered

@export var gate_scene: PackedScene
@export var player_path: NodePath
@export var stage_controller_path: NodePath
@export var open_distance_meters: float = 5.0
@export var close_distance_meters: float = 6.4
@export var transition_distance_meters: float = 1.25
@export var open_speed: float = 3.4
@export_range(0.0, 1.0, 0.01) var required_open_ratio_for_transition: float = 0.82
@export var open_angle_degrees: float = 82.0
@export var visual_height_offset_meters: float = 1.05

var _player: PlayerController
var _stage_controller: StageController
var _visual_root: Node3D
var _left_door_pivot: Node3D
var _right_door_pivot: Node3D
var _open_amount: float = 0.0
var _target_open_amount: float = 0.0
var _gate_available: bool = false
var _transition_requested: bool = false
var _using_gate_scene_visual: bool = false


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	_stage_controller = get_node_or_null(stage_controller_path) as StageController
	_build_visual()
	set_gate_available(false, Vector3.ZERO)
	DebugLog.info(&"ExitGate", "ready")


func _physics_process(delta: float) -> void:
	step_gate_for_tests(delta)


func step_gate_for_tests(delta: float) -> void:
	if not _gate_available:
		return

	_update_target_open_amount()
	_open_amount = move_toward(_open_amount, _target_open_amount, open_speed * delta)
	_apply_open_animation()
	_request_transition_if_ready()


func set_gate_available(is_available: bool, gate_position: Vector3) -> void:
	_gate_available = is_available
	_transition_requested = false
	_target_open_amount = 0.0
	if is_available:
		global_position = gate_position
		visible = true
	else:
		_open_amount = 0.0
		visible = false
	_apply_open_animation()


func is_gate_available() -> bool:
	return _gate_available


func get_open_amount() -> float:
	return _open_amount


func get_target_open_amount() -> float:
	return _target_open_amount


func get_distance_to_player() -> float:
	if _player == null:
		_player = get_node_or_null(player_path) as PlayerController
	if _player == null:
		return INF
	return global_position.distance_to(_player.global_position)


func is_using_gate_scene_visual() -> bool:
	return _using_gate_scene_visual


func _build_visual() -> void:
	if gate_scene != null:
		_visual_root = gate_scene.instantiate() as Node3D
		if _visual_root != null:
			add_child(_visual_root)
			_left_door_pivot = (
				_visual_root.find_child("exit_gate_left_pivot", true, false) as Node3D
			)
			_right_door_pivot = (
				_visual_root.find_child("exit_gate_right_pivot", true, false) as Node3D
			)
			_using_gate_scene_visual = _left_door_pivot != null and _right_door_pivot != null

	if _visual_root == null or _left_door_pivot == null or _right_door_pivot == null:
		if _visual_root != null:
			_visual_root.queue_free()
		_using_gate_scene_visual = false
		_build_fallback_visual()

	_visual_root.position.y = visual_height_offset_meters


func _build_fallback_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "ExitGateFallbackVisual"
	add_child(_visual_root)

	var cyan := _create_material(Color(0.14, 0.82, 0.88, 1.0), 0.45)
	var cream := _create_material(Color(0.97, 0.9, 0.72, 1.0), 0.0)
	var dark := _create_material(Color(0.18, 0.22, 0.3, 1.0), 0.0)

	var frame := MeshInstance3D.new()
	frame.name = "exit_gate_frame"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(3.1, 2.55, 0.32)
	frame.mesh = frame_mesh
	frame.position = Vector3(0.0, 0.55, 0.0)
	frame.set_surface_override_material(0, cyan)
	_visual_root.add_child(frame)

	var arch_cutout := MeshInstance3D.new()
	arch_cutout.name = "exit_gate_arch_cutout"
	var cutout_mesh := BoxMesh.new()
	cutout_mesh.size = Vector3(2.2, 1.9, 0.36)
	arch_cutout.mesh = cutout_mesh
	arch_cutout.position = Vector3(0.0, 0.34, -0.01)
	arch_cutout.set_surface_override_material(0, dark)
	_visual_root.add_child(arch_cutout)

	_left_door_pivot = _create_door_pivot("exit_gate_left_pivot", -0.04, -0.58, cream)
	_right_door_pivot = _create_door_pivot("exit_gate_right_pivot", 0.04, 0.58, cream)


func _create_door_pivot(
	pivot_name: String, hinge_x: float, door_center_x: float, door_material: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.position = Vector3(hinge_x, 0.32, -0.22)
	_visual_root.add_child(pivot)

	var door := MeshInstance3D.new()
	door.name = "%s_panel" % pivot_name
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.08, 1.65, 0.16)
	door.mesh = door_mesh
	door.position = Vector3(door_center_x - hinge_x, 0.0, 0.0)
	door.set_surface_override_material(0, door_material)
	pivot.add_child(door)
	return pivot


func _create_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material


func _update_target_open_amount() -> void:
	var distance := get_distance_to_player()
	if distance <= open_distance_meters:
		_target_open_amount = 1.0
	elif distance >= close_distance_meters:
		_target_open_amount = 0.0


func _apply_open_animation() -> void:
	if _left_door_pivot == null or _right_door_pivot == null:
		return

	var open_angle := deg_to_rad(open_angle_degrees) * _open_amount
	var wobble := sin(_open_amount * PI * 3.0) * deg_to_rad(4.0) * _open_amount
	_left_door_pivot.rotation.y = -open_angle - wobble
	_right_door_pivot.rotation.y = open_angle + wobble
	if _visual_root != null:
		var bounce := 1.0 + sin(_open_amount * PI) * 0.05
		_visual_root.scale = Vector3(bounce, 1.0 + sin(_open_amount * PI) * 0.04, bounce)


func _request_transition_if_ready() -> void:
	if _transition_requested:
		return
	if _open_amount < required_open_ratio_for_transition:
		return
	if get_distance_to_player() > transition_distance_meters:
		return

	_transition_requested = true
	gate_entered.emit()
	if _stage_controller == null:
		_stage_controller = get_node_or_null(stage_controller_path) as StageController
	if _stage_controller != null:
		_stage_controller.request_advance_stage()
