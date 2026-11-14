class_name AvatarItems
extends RefCounted

## Small original cosmetics assembled from primitive meshes. They are attached
## to the avatar root so they work with both bundled GLB characters.
static func apply(root: Node3D, equipped_ids: Array) -> void:
	if root == null:
		return
	var old_layer := root.get_node_or_null("BloxTacosCosmetics")
	if old_layer != null:
		old_layer.queue_free()
	var layer := Node3D.new()
	layer.name = "BloxTacosCosmetics"
	root.add_child(layer)
	for item_id in equipped_ids:
		match String(item_id):
			"classic_cap":
				_add_box(layer, "CapBrim", Vector3(0, 1.58, 0), Vector3(0.82, 0.12, 0.82), Color("#174f91"))
				_add_box(layer, "CapCrown", Vector3(0, 1.78, 0.02), Vector3(0.62, 0.34, 0.62), Color("#226fbd"))
			"retro_shades":
				_add_box(layer, "LeftLens", Vector3(-0.19, 1.52, -0.31), Vector3(0.28, 0.16, 0.07), Color("#101820"))
				_add_box(layer, "RightLens", Vector3(0.19, 1.52, -0.31), Vector3(0.28, 0.16, 0.07), Color("#101820"))
				_add_box(layer, "ShadeBridge", Vector3(0, 1.54, -0.34), Vector3(0.16, 0.06, 0.06), Color("#d7e1e8"))
			"gold_crown":
				_add_box(layer, "CrownBase", Vector3(0, 1.66, 0), Vector3(0.72, 0.16, 0.62), Color("#f2b632"))
				_add_box(layer, "CrownPoint1", Vector3(-0.25, 1.82, 0), Vector3(0.12, 0.26, 0.12), Color("#ffdb63"))
				_add_box(layer, "CrownPoint2", Vector3(0, 1.86, 0), Vector3(0.12, 0.34, 0.12), Color("#ffdb63"))
				_add_box(layer, "CrownPoint3", Vector3(0.25, 1.82, 0), Vector3(0.12, 0.26, 0.12), Color("#ffdb63"))
			"green_visor":
				_add_box(layer, "VisorTop", Vector3(0, 1.62, -0.01), Vector3(0.78, 0.14, 0.72), Color("#279c62"))
				_add_box(layer, "VisorFront", Vector3(0, 1.55, -0.35), Vector3(0.82, 0.07, 0.26), Color("#45c980"))
			"red_backpack":
				_add_box(layer, "Backpack", Vector3(0, 0.98, 0.36), Vector3(0.66, 0.78, 0.34), Color("#b83c35"))
				_add_box(layer, "PackPocket", Vector3(0, 0.82, 0.55), Vector3(0.42, 0.28, 0.08), Color("#e45a4e"))
			"star_halo":
				var halo := MeshInstance3D.new()
				halo.name = "StarHalo"
				var torus := TorusMesh.new()
				torus.inner_radius = 0.43
				torus.outer_radius = 0.51
				halo.mesh = torus
				halo.position = Vector3(0, 1.99, 0)
				halo.material_override = _material(Color("#f5d65a"))
				layer.add_child(halo)
			"headphones":
				_add_box(layer, "HeadphoneBand", Vector3(0, 1.73, 0), Vector3(0.76, 0.10, 0.18), Color("#252b35"))
				_add_box(layer, "HeadphoneLeft", Vector3(-0.39, 1.55, 0), Vector3(0.14, 0.34, 0.26), Color("#3e6fbd"))
				_add_box(layer, "HeadphoneRight", Vector3(0.39, 1.55, 0), Vector3(0.14, 0.34, 0.26), Color("#3e6fbd"))
			"classic_scarf":
				_add_box(layer, "Scarf", Vector3(0, 1.22, -0.02), Vector3(0.72, 0.18, 0.58), Color("#b33f3f"))
			"gold_chain":
				_add_box(layer, "Chain", Vector3(0, 1.25, -0.31), Vector3(0.50, 0.06, 0.07), Color("#f3c64e"))
			"blue_tee":
				_add_box(layer, "ShirtBadge", Vector3(0, 1.15, -0.31), Vector3(0.32, 0.22, 0.06), Color("#2f79d0"))

static func _add_box(parent: Node3D, node_name: String, position: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	return mat
