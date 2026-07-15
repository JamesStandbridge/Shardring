class_name MeshSceneExtractor
extends RefCounted


static func extract_first_mesh(scene: PackedScene) -> Mesh:
	if scene == null:
		return null

	var root := scene.instantiate()
	var mesh_instance := _find_first_mesh_instance(root)
	var mesh: Mesh = null
	if mesh_instance != null and mesh_instance.mesh != null:
		mesh = _duplicate_mesh_with_transform(mesh_instance)
	root.free()
	return mesh


static func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D

	for child: Node in node.get_children():
		var found := _find_first_mesh_instance(child)
		if found != null:
			return found

	return null


static func _duplicate_mesh_with_transform(mesh_instance: MeshInstance3D) -> Mesh:
	var source_mesh := mesh_instance.mesh
	var transformed_mesh := ArrayMesh.new()
	var source_transform := _get_transform_from_scene_root(mesh_instance)

	for surface_index in range(source_mesh.get_surface_count()):
		var arrays := source_mesh.surface_get_arrays(surface_index)
		_transform_vertices(arrays, source_transform)
		_transform_normals(arrays, source_transform.basis)
		transformed_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := source_mesh.surface_get_material(surface_index)
		if material != null:
			transformed_mesh.surface_set_material(surface_index, material)

	return transformed_mesh


static func _get_transform_from_scene_root(node: Node3D) -> Transform3D:
	var scene_transform := node.transform
	var parent := node.get_parent()
	while parent is Node3D:
		scene_transform = (parent as Node3D).transform * scene_transform
		parent = parent.get_parent()
	return scene_transform


static func _transform_vertices(arrays: Array, source_transform: Transform3D) -> void:
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for vertex_index in range(vertices.size()):
		vertices[vertex_index] = source_transform * vertices[vertex_index]
	arrays[Mesh.ARRAY_VERTEX] = vertices


static func _transform_normals(arrays: Array, source_basis: Basis) -> void:
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	for normal_index in range(normals.size()):
		normals[normal_index] = (source_basis * normals[normal_index]).normalized()
	arrays[Mesh.ARRAY_NORMAL] = normals
