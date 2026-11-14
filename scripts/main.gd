extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")
const JOYSTICK_SCRIPT := preload("res://scripts/mobile_joystick.gd")
const SAVE_PATH := "user://bloxtacos_profile.cfg"

const CLASSIC_GREEN := Color("#6e9d45")
const CLASSIC_BLUE := Color("#1769aa")
const PANEL_WHITE := Color("#f5f7fa")
const TEXT_DARK := Color("#273746")

var _player: ClassicPlayer
var _joystick: MobileJoystick
var _mouse_look_active := false
var _world_root: Node3D
var _canvas: CanvasLayer
var _ui_root: Control
var _page_panel: PanelContainer
var _page_content: VBoxContainer
var _wallet_label: Label
var _chat_log: RichTextLabel
var _chat_input: LineEdit
var _chat_panel: PanelContainer
var _round_label: Label
var _mode_hint: Label
var _interaction_button: Button
var _game_hud_controls: Array[Control] = []
var _active_page := "home"
var _current_mode := "classic"
var _wallet := 100
var _owned_items: Array[String] = []
var _equipped_items: Array[String] = []
var _selected_avatar := "noob"
var _pizza_stage := 0
var _pizza_orders := 0
var _pizza_tips := 0
var _round_active := false
var _round_remaining := 60.0
var _disaster_kind := "flood"
var _disaster_delay := 5.0
var _water: MeshInstance3D
var _tornado_visual: Node3D
var _water_start_y := -3.0
var _water_level_speed := 0.22
var _weather_clock := 0.0
var _chat_messages: Array[String] = []

const CATALOG := [
	{"id":"classic_cap", "name":"Boné Clássico", "description":"Um boné azul retrô.", "price":15, "color":Color("#2874bd"), "category":"Chapéus"},
	{"id":"retro_shades", "name":"Óculos Retrô", "description":"Lentes escuras de estilo antigo.", "price":20, "color":Color("#2d3540"), "category":"Rostos"},
	{"id":"gold_crown", "name":"Coroa Dourada", "description":"Uma coroa brilhante.", "price":35, "color":Color("#f2c64b"), "category":"Chapéus"},
	{"id":"green_visor", "name":"Viseira Verde", "description":"Visual esportivo clássico.", "price":15, "color":Color("#35ad70"), "category":"Chapéus"},
	{"id":"red_backpack", "name":"Mochila Vermelha", "description":"Para levar suas coisas pelo mapa.", "price":30, "color":Color("#c34a42"), "category":"Acessórios"},
	{"id":"star_halo", "name":"Auréola Estelar", "description":"Um aro dourado sobre a cabeça.", "price":25, "color":Color("#f5d65a"), "category":"Acessórios"},
	{"id":"headphones", "name":"Fones Azuis", "description":"Fones para explorar com estilo.", "price":25, "color":Color("#3e6fbd"), "category":"Acessórios"},
	{"id":"classic_scarf", "name":"Cachecol Vermelho", "description":"Um toque de cor para o avatar.", "price":10, "color":Color("#b33f3f"), "category":"Roupas"},
	{"id":"gold_chain", "name":"Corrente Dourada", "description":"Acessório dourado simples.", "price":20, "color":Color("#f3c64e"), "category":"Acessórios"},
	{"id":"blue_tee", "name":"Emblema Azul", "description":"Um detalhe azul no torso.", "price":12, "color":Color("#2f79d0"), "category":"Roupas"}
]

func _ready() -> void:
	_setup_input_map()
	_load_profile()
	_build_environment()
	_build_classic_yard()
	_spawn_player()
	_build_hud()
	_open_page("home")
	_add_chat_message("BloxTacos", "Bem-vindo! Este é o chat clássico local.")
	print("BloxTacos iniciado: menu clássico, avatares GLB, catálogo local e experiências.")

func _process(delta: float) -> void:
	if _player != null and _joystick != null:
		_player.set_joystick_input(_joystick.direction)
	if _round_active:
		_update_disaster(delta)
	if _current_mode == "pizza" and _mode_hint != null:
		_update_pizza_hint()

func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event is InputEventScreenDrag:
		var screen_size := get_viewport().get_visible_rect().size
		if event.position.x > screen_size.x * 0.38 and event.position.y < screen_size.y - 145.0:
			_player.add_look_input(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_mouse_look_active = event.pressed
	elif event is InputEventMouseMotion and _mouse_look_active:
		_player.add_look_input(event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _active_page == "none":
			_open_page("home")
		elif event.keycode == KEY_ENTER and _active_page == "none" and _current_mode == "pizza":
			_pizza_interact()

func _setup_input_map() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_forward", KEY_UP)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_back", KEY_DOWN)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("jump", KEY_SPACE)
	_add_key_action("respawn", KEY_R)

func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	if not InputMap.action_has_event(action_name, key_event):
		InputMap.action_add_event(action_name, key_event)

func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		_wallet = int(config.get_value("profile", "wallet", 100))
		_owned_items.clear()
		for saved_item in config.get_value("profile", "owned_items", []):
			_owned_items.append(String(saved_item))
		_equipped_items.clear()
		for saved_item in config.get_value("profile", "equipped_items", []):
			_equipped_items.append(String(saved_item))
		_selected_avatar = String(config.get_value("profile", "avatar", "noob"))
	else:
		_wallet = 100
		_owned_items = []
		_equipped_items = []
		_selected_avatar = "noob"
	_save_profile()

func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "wallet", _wallet)
	config.set_value("profile", "owned_items", _owned_items)
	config.set_value("profile", "equipped_items", _equipped_items)
	config.set_value("profile", "avatar", _selected_avatar)
	config.save(SAVE_PATH)

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#477eb0")
	sky_material.sky_horizon_color = Color("#c4d6e7")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d7e3ed")
	environment.ambient_light_energy = 0.76
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "ClassicSun"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _build_classic_yard() -> void:
	_current_mode = "classic"
	_clear_world()
	_world_root = Node3D.new()
	_world_root.name = "ClassicYardWorld"
	add_child(_world_root)
	_add_baseplate(_world_root, 64.0, CLASSIC_GREEN)
	_add_block(_world_root, "WelcomeBlue", Vector3(-9, 1, -10), Vector3(5, 2, 2), Color("#267ac0"))
	_add_block(_world_root, "WelcomeRed", Vector3(-14, 1, -10), Vector3(2, 2, 2), Color("#c94a40"))
	_add_block(_world_root, "WelcomeYellow", Vector3(-4, 1, -10), Vector3(2, 2, 2), Color("#e5b83c"))
	for i in range(5):
		_add_block(_world_root, "ObbyStep_%02d" % i, Vector3(7.0 + i * 4.0, 0.7 + i * 0.62, -12), Vector3(3, 0.5, 3), [Color("#e75a4f"), Color("#e6b641"), Color("#438bd0"), Color("#59a75d"), Color("#8a67ba")][i])
	_add_block(_world_root, "TowerRed", Vector3(-20, 1.0, 8), Vector3(4, 2, 4), Color("#c94a40"))
	_add_block(_world_root, "TowerBlue", Vector3(-20, 3.1, 8), Vector3(3.2, 2.2, 3.2), Color("#267ac0"))
	_add_block(_world_root, "TowerYellow", Vector3(-20, 5.35, 8), Vector3(2.4, 2.3, 2.4), Color("#e5b83c"))
	_create_tree(_world_root, Vector3(20, 0, 20))
	_create_tree(_world_root, Vector3(25, 0, 15))
	_create_tree(_world_root, Vector3(-25, 0, -19))
	_create_sign(_world_root, Vector3(0, 0, -5), "BLOXTACOS  •  CLASSIC YARD")
	_reset_player_spawn(Vector3(0, 0.2, 5))

func _build_natural_disaster_world() -> void:
	_round_active = false
	_current_mode = "disaster"
	_clear_world()
	_world_root = Node3D.new()
	_world_root.name = "NaturalDisastersWorld"
	add_child(_world_root)
	_add_baseplate(_world_root, 72.0, Color("#60934b"))
	_create_sign(_world_root, Vector3(0, 0, -28), "BLOXTACOS  •  NATURAL DISASTERS")
	# Beach hut and safe platforms.
	_add_block(_world_root, "BeachHouseFloor", Vector3(-13, 0.45, -3), Vector3(10, 0.9, 8), Color("#c6a36b"))
	_add_block(_world_root, "BeachHouseBack", Vector3(-13, 3.0, 1), Vector3(10, 5, 0.5), Color("#e8e0d2"))
	_add_block(_world_root, "BeachHouseLeft", Vector3(-18, 3.0, -3), Vector3(0.5, 5, 8), Color("#e8e0d2"))
	_add_block(_world_root, "BeachHouseRight", Vector3(-8, 3.0, -3), Vector3(0.5, 5, 8), Color("#e8e0d2"))
	_add_block(_world_root, "BeachRoof", Vector3(-13, 5.8, -3), Vector3(11, 0.8, 9), Color("#b44a3d"))
	# Main tower with climbable block steps.
	_add_block(_world_root, "SurvivalTower", Vector3(12, 5, -4), Vector3(5, 10, 5), Color("#497eb3"))
	for step in range(6):
		_add_block(_world_root, "TowerStep_%02d" % step, Vector3(8.0 + float(step) * 1.1, 0.7 + float(step) * 1.35, -1.0), Vector3(2.4, 0.45, 3.0), Color("#d5b14a"))
	_add_block(_world_root, "HighPlatform", Vector3(12, 10.5, -4), Vector3(9, 0.5, 9), Color("#e7e4d9"))
	# A few square buildings, trees and rocks form a small island.
	_add_building(_world_root, Vector3(22, 0, 15), Color("#d6dbe0"), Color("#b64b43"))
	_add_building(_world_root, Vector3(-24, 0, 16), Color("#e5d6b9"), Color("#4d7fae"))
	_create_tree(_world_root, Vector3(28, 0, -20))
	_create_tree(_world_root, Vector3(-28, 0, -20))
	_add_block(_world_root, "RockA", Vector3(0, 1.2, 19), Vector3(5, 2.4, 4), Color("#727d84"))
	_add_block(_world_root, "RockB", Vector3(4, 2.8, 20), Vector3(3, 3.0, 3), Color("#8a9499"))
	_water = MeshInstance3D.new()
	_water.name = "RisingFloodWater"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(74, 74)
	_water.mesh = water_mesh
	_water.position = Vector3(0, -3.0, 0)
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.12, 0.52, 0.88, 0.70)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.22
	water_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_water.material_override = water_material
	_world_root.add_child(_water)
	_tornado_visual = Node3D.new()
	_tornado_visual.name = "WindstormFunnel"
	_tornado_visual.position = Vector3(-18, 0, -12)
	_world_root.add_child(_tornado_visual)
	for funnel_part in range(4):
		var funnel := MeshInstance3D.new()
		var funnel_mesh := CylinderMesh.new()
		funnel_mesh.top_radius = 0.45 + float(funnel_part) * 0.22
		funnel_mesh.bottom_radius = 1.05 + float(funnel_part) * 0.28
		funnel_mesh.height = 2.4
		funnel.mesh = funnel_mesh
		funnel.position.y = 1.2 + float(funnel_part) * 1.55
		var funnel_material := StandardMaterial3D.new()
		funnel_material.albedo_color = Color(0.72, 0.78, 0.82, 0.72)
		funnel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		funnel_material.roughness = 1.0
		funnel.material_override = funnel_material
		_tornado_visual.add_child(funnel)
	_tornado_visual.hide()
	_reset_player_spawn(Vector3(0, 0.2, 22))

func _build_pizza_place_world() -> void:
	_round_active = false
	_current_mode = "pizza"
	_clear_world()
	_world_root = Node3D.new()
	_world_root.name = "PizzaPlaceWorld"
	add_child(_world_root)
	_add_baseplate(_world_root, 58.0, Color("#79a653"))
	# Restaurant exterior and interior, built from original block geometry.
	_add_block(_world_root, "RestaurantFloor", Vector3(0, 0.18, 0), Vector3(25, 0.36, 20), Color("#d8d0bd"))
	_add_block(_world_root, "BackWall", Vector3(0, 4.0, -9.7), Vector3(25, 8, 0.6), Color("#f0eee8"))
	_add_block(_world_root, "LeftWall", Vector3(-12.2, 4.0, 0), Vector3(0.6, 8, 20), Color("#f0eee8"))
	_add_block(_world_root, "RightWall", Vector3(12.2, 4.0, 0), Vector3(0.6, 8, 20), Color("#f0eee8"))
	_add_block(_world_root, "FrontAwning", Vector3(0, 6.0, 9.2), Vector3(25, 0.55, 2.0), Color("#b8423b"))
	_add_block(_world_root, "SignPanel", Vector3(0, 7.0, -9.25), Vector3(12, 1.8, 0.35), Color("#2c6498"))
	_add_label_3d(_world_root, "PizzaPlaceSign", "PIZZA PLACE", Vector3(0, 7.0, -9.0), 48, Color.WHITE)
	# Ordering counter.
	_add_block(_world_root, "OrderCounter", Vector3(-8.0, 1.0, 3.0), Vector3(5.0, 2.0, 1.4), Color("#99663e"))
	_add_block(_world_root, "OrderCounterTop", Vector3(-8.0, 2.08, 3.0), Vector3(5.3, 0.18, 1.7), Color("#f4eee2"))
	_add_label_3d(_world_root, "OrderLabel", "PEDIDOS", Vector3(-8.0, 3.0, 2.3), 28, Color("#245b8d"))
	# Prep counter and pizza display.
	_add_block(_world_root, "PrepCounter", Vector3(-1.5, 1.0, -3.0), Vector3(6.0, 2.0, 2.0), Color("#9b6c45"))
	_add_block(_world_root, "PrepTop", Vector3(-1.5, 2.08, -3.0), Vector3(6.3, 0.18, 2.3), Color("#f2e3c7"))
	_create_pizza_prop(_world_root, Vector3(-1.5, 2.22, -3.0))
	_add_label_3d(_world_root, "PrepLabel", "COZINHA", Vector3(-1.5, 3.0, -4.2), 28, Color("#245b8d"))
	# Oven and delivery shelf.
	_add_block(_world_root, "PizzaOven", Vector3(6.0, 1.6, -5.7), Vector3(4.5, 3.2, 3.2), Color("#737b82"))
	_add_block(_world_root, "OvenDoor", Vector3(6.0, 1.4, -4.0), Vector3(2.2, 1.8, 0.18), Color("#343a40"))
	_add_block(_world_root, "OvenWindow", Vector3(6.0, 1.45, -3.88), Vector3(1.35, 0.78, 0.08), Color("#e2a94b"))
	_add_label_3d(_world_root, "OvenLabel", "FORNO", Vector3(6.0, 3.6, -4.2), 28, Color("#245b8d"))
	_add_block(_world_root, "DeliveryShelf", Vector3(8.0, 1.0, 4.0), Vector3(4.2, 2.0, 1.2), Color("#8b5c3c"))
	_add_block(_world_root, "DeliveryTop", Vector3(8.0, 2.1, 4.0), Vector3(4.5, 0.18, 1.5), Color("#f2e3c7"))
	_add_label_3d(_world_root, "DeliveryLabel", "ENTREGAS", Vector3(8.0, 3.0, 3.4), 26, Color("#245b8d"))
	# Customer seating.
	for table_index in range(3):
		var tx := -5.0 + float(table_index) * 8.0
		_add_block(_world_root, "TableTop_%d" % table_index, Vector3(tx, 1.5, 7.0), Vector3(3.2, 0.22, 2.4), Color("#f2e3c7"))
		_add_block(_world_root, "TableLeg_%d" % table_index, Vector3(tx, 0.75, 7.0), Vector3(0.35, 1.4, 0.35), Color("#80553a"))
		for side in [-1.0, 1.0]:
			_add_block(_world_root, "Seat_%d_%d" % [table_index, int(side)], Vector3(tx, 0.7, 7.0 + side * 2.0), Vector3(1.5, 1.0, 1.1), Color("#b84a43"))
	_create_tree(_world_root, Vector3(18, 0, -12))
	_create_sign(_world_root, Vector3(0, 0, 14), "BLOXTACOS  •  PIZZA PLACE")
	_pizza_stage = 0
	_pizza_orders = 0
	_pizza_tips = 0
	_reset_player_spawn(Vector3(0, 0.2, 11.0))

func _clear_world() -> void:
	if _world_root != null:
		_world_root.queue_free()
		_world_root = null
	_water = null
	_tornado_visual = null

func _reset_player_spawn(spawn: Vector3) -> void:
	if _player != null:
		_player.spawn_position = spawn
		_player.respawn()

func _spawn_player() -> void:
	var player_node := PLAYER_SCRIPT.new() as ClassicPlayer
	player_node.name = "LocalPlayer"
	player_node.spawn_position = Vector3(0.0, 0.2, 5.0)
	player_node.current_avatar = _selected_avatar
	player_node.set_equipped_items(_equipped_items)
	_player = player_node
	add_child(_player)

func _add_baseplate(parent: Node3D, width: float, color: Color) -> void:
	var ground := StaticBody3D.new()
	ground.name = "ClassicStuddedBaseplate"
	parent.add_child(ground)
	var ground_mesh := MeshInstance3D.new()
	var ground_box := BoxMesh.new()
	ground_box.size = Vector3(width, 1.0, width)
	ground_mesh.mesh = ground_box
	ground_mesh.position.y = -0.5
	ground_mesh.material_override = _make_material(color)
	ground.add_child(ground_mesh)
	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, 1.0, width)
	collision.shape = box_shape
	collision.position.y = -0.5
	ground.add_child(collision)
	_add_studs(parent, width, color.darkened(0.12))

func _add_studs(parent: Node3D, width: float, color: Color) -> void:
	var stud_mesh := BoxMesh.new()
	stud_mesh.size = Vector3(0.72, 0.16, 0.72)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = stud_mesh
	var positions: Array[Vector3] = []
	var limit := int(width * 0.5) - 2
	for x in range(-limit, limit + 1, 2):
		for z in range(-limit, limit + 1, 2):
			positions.append(Vector3(float(x), 0.08, float(z)))
	multimesh.instance_count = positions.size()
	for i in range(positions.size()):
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var studs := MultiMeshInstance3D.new()
	studs.name = "BaseplateStuds"
	studs.multimesh = multimesh
	studs.material_override = _make_material(color)
	parent.add_child(studs)

func _add_block(parent: Node3D, block_name: String, pos: Vector3, dimensions: Vector3, color: Color, collision_enabled: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = block_name
	body.position = pos
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.material_override = _make_material(color)
	body.add_child(mesh_instance)
	if collision_enabled:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)
	return body

func _add_building(parent: Node3D, center: Vector3, wall_color: Color, roof_color: Color) -> void:
	_add_block(parent, "BuildingBody", center + Vector3(0, 2.2, 0), Vector3(8, 4.4, 7), wall_color)
	_add_block(parent, "BuildingRoof", center + Vector3(0, 4.6, 0), Vector3(8.8, 0.6, 7.8), roof_color)
	_add_block(parent, "BuildingDoor", center + Vector3(0, 1.1, -3.56), Vector3(1.4, 2.2, 0.12), Color("#7f5a3c"), false)
	_add_block(parent, "BuildingWindowA", center + Vector3(-2.3, 2.8, -3.58), Vector3(1.4, 1.2, 0.1), Color("#80c2dc"), false)
	_add_block(parent, "BuildingWindowB", center + Vector3(2.3, 2.8, -3.58), Vector3(1.4, 1.2, 0.1), Color("#80c2dc"), false)

func _create_tree(parent: Node3D, tree_position: Vector3) -> void:
	_add_block(parent, "TreeTrunk", tree_position + Vector3(0, 1.2, 0), Vector3(0.8, 2.4, 0.8), Color("#80502f"))
	_add_block(parent, "TreeLeavesLower", tree_position + Vector3(0, 3.0, 0), Vector3(3.2, 1.6, 3.2), Color("#397e41"))
	_add_block(parent, "TreeLeavesUpper", tree_position + Vector3(0, 4.1, 0), Vector3(2.1, 1.4, 2.1), Color("#4d9950"))

func _create_sign(parent: Node3D, sign_position: Vector3, text_value: String) -> void:
	_add_block(parent, "SignPost", sign_position + Vector3(0, 1.2, 0), Vector3(0.35, 2.4, 0.35), Color("#80502f"))
	_add_block(parent, "SignBoard", sign_position + Vector3(0, 2.65, 0), Vector3(8.8, 1.35, 0.32), Color("#1d5f98"))
	_add_label_3d(parent, "SignText", text_value, sign_position + Vector3(0, 2.68, -0.19), 36, Color.WHITE)

func _add_label_3d(parent: Node3D, node_name: String, value: String, position_3d: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = value
	label.position = position_3d
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_size = 7
	parent.add_child(label)

func _create_pizza_prop(parent: Node3D, position_3d: Vector3) -> void:
	var base := MeshInstance3D.new()
	var crust := CylinderMesh.new()
	crust.top_radius = 0.82
	crust.bottom_radius = 0.82
	crust.height = 0.14
	base.mesh = crust
	base.position = position_3d
	base.material_override = _make_material(Color("#d8a44d"))
	parent.add_child(base)
	var cheese := MeshInstance3D.new()
	var topping := CylinderMesh.new()
	topping.top_radius = 0.72
	topping.bottom_radius = 0.72
	topping.height = 0.055
	cheese.mesh = topping
	cheese.position = position_3d + Vector3(0, 0.09, 0)
	cheese.material_override = _make_material(Color("#f3d56b"))
	parent.add_child(cheese)
	for i in range(6):
		var pepperoni := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.13
		disc.bottom_radius = 0.13
		disc.height = 0.035
		pepperoni.mesh = disc
		var angle := TAU * float(i) / 6.0
		pepperoni.position = position_3d + Vector3(cos(angle) * 0.38, 0.13, sin(angle) * 0.38)
		pepperoni.material_override = _make_material(Color("#b74335"))
		parent.add_child(pepperoni)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material

# -----------------------------------------------------------------------------
# Classic-style 2016-era interface
# -----------------------------------------------------------------------------
func _build_hud() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "BloxTacosInterface"
	add_child(_canvas)
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(_ui_root)
	_build_top_bar()
	_build_page_panel()
	_build_chat_widget()
	_build_game_controls()
	_build_round_status()

func _build_top_bar() -> void:
	var top := PanelContainer.new()
	top.name = "ClassicTopBar"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 58
	top.add_theme_stylebox_override("panel", _panel_style(Color("#f7f8fa"), Color("#c7d0d8"), 0, 0))
	_ui_root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(row)
	var logo := Label.new()
	logo.text = "BloxTacos"
	logo.add_theme_font_size_override("font_size", 26)
	logo.add_theme_color_override("font_color", Color("#1769aa"))
	logo.custom_minimum_size.x = 170
	logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(logo)
	row.add_child(_nav_button("Início", "home"))
	row.add_child(_nav_button("Experiências", "games"))
	row.add_child(_nav_button("Avatar", "avatar"))
	row.add_child(_nav_button("Catálogo", "catalog"))
	row.add_child(_nav_button("Chat", "chat"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_wallet_label = Label.new()
	_wallet_label.text = "◈ %d Robux" % _wallet
	_wallet_label.add_theme_font_size_override("font_size", 17)
	_wallet_label.add_theme_color_override("font_color", Color("#26713e"))
	_wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wallet_label.custom_minimum_size.x = 125
	row.add_child(_wallet_label)

func _nav_button(text_value: String, page_name: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(100, 40)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT_DARK)
	button.add_theme_stylebox_override("normal", _button_style(Color("#e9edf1"), Color("#d2d9df")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#dfeaf4"), Color("#7aaed4")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#c8dff1"), Color("#5794c3")))
	button.pressed.connect(_open_page.bind(page_name))
	return button

func _build_page_panel() -> void:
	_page_panel = PanelContainer.new()
	_page_panel.name = "PagePanel"
	_page_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page_panel.offset_left = 115
	_page_panel.offset_top = 82
	_page_panel.offset_right = -115
	_page_panel.offset_bottom = -88
	_page_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f5f7fa"), Color("#bfcbd5"), 2, 8))
	_ui_root.add_child(_page_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_page_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	_page_content = VBoxContainer.new()
	_page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_page_content)

func _open_page(page_name: String) -> void:
	_active_page = page_name
	if page_name == "none":
		_page_panel.hide()
		if _chat_panel != null:
			_chat_panel.show()
		_set_game_controls_visible(true)
		return
	_page_panel.show()
	if _chat_panel != null:
		_chat_panel.hide()
	_set_game_controls_visible(false)
	for child in _page_content.get_children():
		_page_content.remove_child(child)
		child.queue_free()
	match page_name:
		"home": _show_home_page()
		"games": _show_games_page()
		"avatar": _show_avatar_page()
		"catalog": _show_catalog_page()
		"chat": _show_chat_page()
		_: _show_home_page()

func _show_home_page() -> void:
	_page_content.add_child(_page_title("Bem-vindo ao BloxTacos", "Uma plataforma independente com visual clássico de 2016–2017."))
	var summary := _make_card("Seu perfil", "Avatar: %s     •     Saldo: %d Robux de demonstração" % [_avatar_display_name(_selected_avatar), _wallet], Color("#eaf2f8"))
	_page_content.add_child(summary)
	_page_content.add_child(_page_title("Continue jogando", "Escolha uma experiência para entrar."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_page_content.add_child(row)
	row.add_child(_experience_card("Classic Yard", "Explore a baseplate, os studs e um pequeno obby.", Color("#6e9d45"), "classic"))
	row.add_child(_experience_card("Natural Disasters", "Suba para locais seguros e sobreviva a eventos naturais.", Color("#4d89b8"), "disaster"))
	row.add_child(_experience_card("Pizza Place", "Receba pedidos, prepare pizzas e faça entregas.", Color("#bd6943"), "pizza"))
	var footer := _make_label("As experiências são protótipos locais. Multiplayer e contas online ainda não estão conectados.", 13, Color("#667783"))
	_page_content.add_child(footer)
	_page_content.add_child(_make_button("JOGAR CLASSIC YARD", Color("#2878b8"), _start_classic))

func _show_games_page() -> void:
	_page_content.add_child(_page_title("Experiências", "Entre em uma das experiências incluídas nesta versão."))
	_page_content.add_child(_experience_card("Classic Yard", "Baseplate com studs, obstáculos e construções clássicas.", Color("#6e9d45"), "classic"))
	_page_content.add_child(_experience_card("Natural Disasters", "Rodadas de enchente, tremor e ventania com 60 segundos de sobrevivência.", Color("#4d89b8"), "disaster"))
	_page_content.add_child(_experience_card("Pizza Place", "Trabalhe em quatro estações para concluir pedidos de pizza.", Color("#bd6943"), "pizza"))

func _show_avatar_page() -> void:
	_page_content.add_child(_page_title("Avatar", "Escolha o personagem que vai acompanhar você nas experiências."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_page_content.add_child(row)
	row.add_child(_avatar_card("noob", "Noob R6", "Modelo 3D rigado enviado nesta conversa. Visual clássico amarelo e azul."))
	row.add_child(_avatar_card("bacon", "Bacon Hair", "Modelo 3D rigado com cabelo bacon e uma animação incluída."))
	_page_content.add_child(_make_label("A escolha fica salva neste dispositivo. Os dois modelos aparecem no mundo 3D.", 13, Color("#687985")))

func _show_catalog_page() -> void:
	_page_content.add_child(_page_title("Catálogo", "Compre acessórios com seus 100 Robux iniciais de demonstração."))
	var wallet_text := _make_label("Saldo atual: %d Robux de demonstração" % _wallet, 16, Color("#26713e"))
	_page_content.add_child(wallet_text)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_page_content.add_child(grid)
	for item in CATALOG:
		grid.add_child(_catalog_card(item))
	_page_content.add_child(_make_label("Os Robux desta versão são apenas créditos locais de teste: não podem ser transferidos nem usados no Roblox.", 12, Color("#7b858e")))

func _show_chat_page() -> void:
	_page_content.add_child(_page_title("Chat clássico", "Janela inspirada no chat antigo. Por enquanto, as mensagens são locais neste dispositivo."))	
	var chat_panel := PanelContainer.new()
	chat_panel.custom_minimum_size.y = 300
	chat_panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffffff"), Color("#c8d2dc"), 1, 4))
	_page_content.add_child(chat_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	chat_panel.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	var history := RichTextLabel.new()
	history.fit_content = false
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history.scroll_following = true
	history.bbcode_enabled = true
	history.add_theme_color_override("default_color", Color("#273746"))
	for entry in _chat_messages:
		history.append_text(entry + "\n")
	stack.add_child(history)
	var input_row := HBoxContainer.new()
	stack.add_child(input_row)
	var input := LineEdit.new()
	input.placeholder_text = "Digite uma mensagem..."
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_row.add_child(input)
	var send := _make_button("Enviar", Color("#2878b8"), func(): _send_chat_from(input, history))
	input_row.add_child(send)
	input.text_submitted.connect(func(_value: String): _send_chat_from(input, history))
	_page_content.add_child(_make_label("Não há conexão com outros jogadores nesta versão. O chat online será ligado quando o backend multiplayer for implementado.", 12, Color("#7b858e")))

func _page_title(title_text: String, subtitle_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#273746"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#6b7883"))
	box.add_child(subtitle)
	return box

func _make_card(title_text: String, body_text: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(220, 84)
	panel.add_theme_stylebox_override("panel", _panel_style(color, color.darkened(0.12), 1, 5))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	var title := _make_label(title_text, 16, TEXT_DARK)
	stack.add_child(title)
	var body := _make_label(body_text, 12, Color("#53616d"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	return panel

func _experience_card(title_text: String, description: String, color: Color, mode_id: String) -> Control:
	var panel := _make_card(title_text, description, Color("#ffffff"))
	panel.custom_minimum_size = Vector2(0, 142)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := panel.get_child(0) as MarginContainer
	var stack := margin.get_child(0) as VBoxContainer
	var stripe := ColorRect.new()
	stripe.color = color
	stripe.custom_minimum_size = Vector2(0, 7)
	stack.add_child(stripe)
	var play := _make_button("JOGAR", color, func(): _launch_mode(mode_id))
	stack.add_child(play)
	return panel

func _avatar_card(avatar_id: String, title_text: String, details: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(260, 220)
	panel.add_theme_stylebox_override("panel", _panel_style(Color.WHITE, Color("#c8d2dc"), 1, 5))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	stack.add_child(_create_avatar_preview(avatar_id))
	stack.add_child(_make_label(title_text, 19, Color("#273746")))
	var desc := _make_label(details, 12, Color("#657681"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(desc)
	var selected := avatar_id == _selected_avatar
	var choose := _make_button("EQUIPADO" if selected else "ESCOLHER AVATAR", Color("#4c975d") if selected else Color("#2878b8"), func(): _choose_avatar(avatar_id))
	choose.disabled = selected
	stack.add_child(choose)
	return panel


func _create_avatar_preview(avatar_id: String) -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(0, 150)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(360, 220)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.own_world_3d = true
	container.add_child(viewport)
	var preview_world := Node3D.new()
	viewport.add_child(preview_world)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.0, 3.4)
	camera.look_at(Vector3(0, 0.88, 0), Vector3.UP)
	camera.current = true
	preview_world.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.25
	preview_world.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2, 2, 2)
	fill.light_energy = 0.55
	preview_world.add_child(fill)
	var avatar_path := "res://assets/avatars/bacon_hair.glb" if avatar_id == "bacon" else "res://assets/avatars/noob_r6.glb"
	var avatar_resource := load(avatar_path)
	if avatar_resource is PackedScene:
		var model := (avatar_resource as PackedScene).instantiate() as Node3D
		if avatar_id == "bacon":
			model.scale = Vector3.ONE * 32.0
		else:
			model.rotation.x = -PI * 0.5
		model.rotation.y += -0.22
		preview_world.add_child(model)
	return container

func _catalog_card(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 130)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color.WHITE, Color("#d1d8df"), 1, 4))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	var swatch := ColorRect.new()
	swatch.color = item.color
	swatch.custom_minimum_size = Vector2(28, 28)
	top.add_child(swatch)
	var title := _make_label(String(item.name), 14, TEXT_DARK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var desc := _make_label(String(item.description), 11, Color("#6d7b86"))
	stack.add_child(desc)
	var owned := _owned_items.has(String(item.id))
	var equipped := _equipped_items.has(String(item.id))
	var button_text := "EQUIPADO" if equipped else ("EQUIPAR" if owned else "COMPRAR  ◈ %d" % int(item.price))
	var action := _make_button(button_text, Color("#4e975d") if owned else Color("#2878b8"), func(): _catalog_action(String(item.id)))
	stack.add_child(action)
	return panel

func _make_button(text_value: String, color: Color, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(118, 38)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(color, color.darkened(0.12)))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12), color))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.16), color.darkened(0.24)))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#9ca8b1"), Color("#8a969f")))
	button.pressed.connect(callback)
	return button

func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _panel_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_chat_widget() -> void:
	_chat_panel = PanelContainer.new()
	_chat_panel.name = "ClassicChatWidget"
	_chat_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_chat_panel.position = Vector2(16, 72)
	_chat_panel.size = Vector2(300, 170)
	_chat_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.96, 0.97, 0.98, 0.94), Color("#aebbc5"), 1, 3))
	_ui_root.add_child(_chat_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_chat_panel.add_child(margin)
	var stack := VBoxContainer.new()
	margin.add_child(stack)
	var title := _make_label("CHAT", 13, Color("#2d5f8b"))
	stack.add_child(title)
	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.fit_content = false
	_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_log.scroll_following = true
	_chat_log.add_theme_font_size_override("normal_font_size", 11)
	_chat_log.add_theme_color_override("default_color", Color("#34495a"))
	stack.add_child(_chat_log)
	var row := HBoxContainer.new()
	stack.add_child(row)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Clique para conversar..."
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_chat_input)
	var send := Button.new()
	send.text = ">"
	send.custom_minimum_size = Vector2(34, 30)
	send.pressed.connect(_send_chat_from.bind(_chat_input, _chat_log))
	row.add_child(send)
	_chat_input.text_submitted.connect(func(_value: String): _send_chat_from(_chat_input, _chat_log))
	for message in _chat_messages:
		_chat_log.append_text(message + "\n")

func _build_game_controls() -> void:
	_joystick = JOYSTICK_SCRIPT.new() as MobileJoystick
	_joystick.name = "VirtualJoystick"
	_joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick.position = Vector2(30, -204)
	_joystick.size = Vector2(176, 176)
	_ui_root.add_child(_joystick)
	var jump := Button.new()
	jump.text = "PULAR"
	jump.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	jump.position = Vector2(-156, -156)
	jump.size = Vector2(126, 104)
	jump.add_theme_font_size_override("font_size", 19)
	jump.add_theme_color_override("font_color", Color.WHITE)
	jump.add_theme_stylebox_override("normal", _button_style(Color("#2878b8"), Color("#e5f1fb")))
	jump.pressed.connect(_on_jump_pressed)
	_ui_root.add_child(jump)
	_game_hud_controls.append(jump)
	var respawn := Button.new()
	respawn.text = "RENASCER"
	respawn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	respawn.position = Vector2(-156, -210)
	respawn.size = Vector2(126, 42)
	respawn.add_theme_font_size_override("font_size", 12)
	respawn.add_theme_color_override("font_color", Color.WHITE)
	respawn.add_theme_stylebox_override("normal", _button_style(Color("#4e5c68"), Color("#d3dbe2")))
	respawn.pressed.connect(_on_respawn_pressed)
	_ui_root.add_child(respawn)
	_game_hud_controls.append(respawn)
	_interaction_button = Button.new()
	_interaction_button.text = "INTERAGIR"
	_interaction_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_interaction_button.position = Vector2(-298, -94)
	_interaction_button.size = Vector2(126, 52)
	_interaction_button.add_theme_font_size_override("font_size", 14)
	_interaction_button.add_theme_color_override("font_color", Color.WHITE)
	_interaction_button.add_theme_stylebox_override("normal", _button_style(Color("#bd6943"), Color("#f5e4d8")))
	_interaction_button.pressed.connect(_pizza_interact)
	_ui_root.add_child(_interaction_button)
	_interaction_button.hide()
	var menu_button := Button.new()
	menu_button.text = "MENU"
	menu_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_button.position = Vector2(-156, -258)
	menu_button.size = Vector2(126, 38)
	menu_button.add_theme_font_size_override("font_size", 12)
	menu_button.pressed.connect(_open_page.bind("home"))
	_ui_root.add_child(menu_button)
	_game_hud_controls.append(menu_button)

func _build_round_status() -> void:
	_round_label = _make_label("", 16, Color.WHITE)
	_round_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_round_label.position = Vector2(0, 66)
	_round_label.size = Vector2(0, 32)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_color_override("font_shadow_color", Color("#1a2732"))
	_round_label.add_theme_constant_override("shadow_offset_x", 2)
	_round_label.add_theme_constant_override("shadow_offset_y", 2)
	_ui_root.add_child(_round_label)
	_mode_hint = _make_label("", 13, Color.WHITE)
	_mode_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_mode_hint.position = Vector2(220, -43)
	_mode_hint.size = Vector2(700, 26)
	_mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_hint.add_theme_color_override("font_shadow_color", Color("#1a2732"))
	_mode_hint.add_theme_constant_override("shadow_offset_x", 1)
	_mode_hint.add_theme_constant_override("shadow_offset_y", 1)
	_ui_root.add_child(_mode_hint)

func _set_game_controls_visible(value: bool) -> void:
	if _joystick != null:
		_joystick.visible = value
	for control in _game_hud_controls:
		if is_instance_valid(control):
			control.visible = value
	if _interaction_button != null:
		_interaction_button.visible = value and _current_mode == "pizza"

func _choose_avatar(avatar_id: String) -> void:
	_selected_avatar = avatar_id
	if _player != null:
		_player.set_avatar(avatar_id)
	_save_profile()
	_open_page("avatar")

func _catalog_action(item_id: String) -> void:
	var item: Dictionary = {}
	for candidate in CATALOG:
		if String(candidate.id) == item_id:
			item = candidate
			break
	if item.is_empty():
		return
	if not _owned_items.has(item_id):
		var cost := int(item.price)
		if _wallet < cost:
			_add_chat_message("BloxTacos", "Saldo insuficiente para %s." % String(item.name))
			return
		_wallet -= cost
		_owned_items.append(item_id)
		_equipped_items.append(item_id)
	else:
		if _equipped_items.has(item_id):
			_equipped_items.erase(item_id)
		else:
			_equipped_items.append(item_id)
	if _player != null:
		_player.set_equipped_items(_equipped_items)
	_save_profile()
	_update_wallet()
	_open_page("catalog")

func _update_wallet() -> void:
	if _wallet_label != null:
		_wallet_label.text = "◈ %d Robux" % _wallet

func _avatar_display_name(avatar_id: String) -> String:
	return "Bacon Hair" if avatar_id == "bacon" else "Noob R6"

func _launch_mode(mode_id: String) -> void:
	match mode_id:
		"classic": _start_classic()
		"disaster": _start_disaster()
		"pizza": _start_pizza()
	_open_page("none")

func _start_classic() -> void:
	_round_active = false
	if _player != null:
		_player.set_camera_shake(0.0)
	_round_label.text = "CLASSIC YARD  •  EXPLORE"
	_mode_hint.text = "WASD / joystick para andar  •  Arraste para girar a câmera  •  Espaço para pular"
	_build_classic_yard()
	_open_page("none")

func _start_disaster() -> void:
	if _player != null:
		_player.set_camera_shake(0.0)
	_build_natural_disaster_world()
	var disasters := ["flood", "quake", "wind"]
	_disaster_kind = disasters[randi_range(0, disasters.size() - 1)]
	_round_remaining = 60.0
	_disaster_delay = 5.0
	_weather_clock = 0.0
	_round_active = true
	_water_start_y = -3.0
	if _water != null:
		_water.position.y = _water_start_y
	if _tornado_visual != null:
		_tornado_visual.visible = _disaster_kind == "wind"
	_round_label.text = "NATURAL DISASTERS  •  PREPARE-SE"
	_mode_hint.text = "Você tem 5 segundos para encontrar um lugar seguro."
	_open_page("none")

func _start_pizza() -> void:
	if _player != null:
		_player.set_camera_shake(0.0)
	_build_pizza_place_world()
	_round_label.text = "PIZZA PLACE  •  PEDIDO #1"
	_mode_hint.text = "Vá até cada estação e toque em INTERAGIR. No PC, pressione ENTER."
	_interaction_button.show()
	_open_page("none")

func _update_disaster(delta: float) -> void:
	_weather_clock += delta
	if _disaster_delay > 0.0:
		_disaster_delay -= delta
		_round_label.text = "ALERTA: %s COMEÇA EM %d" % [_disaster_display_name(), ceili(_disaster_delay)]
		return
	_round_remaining -= delta
	match _disaster_kind:
		"flood":
			if _water != null:
				_water.position.y += _water_level_speed * delta
				if _player != null and _player.global_position.y < _water.position.y + 1.0:
					_round_active = false
					_player.respawn()
					_round_label.text = "A ENCHENTE CHEGOU! TENTE DE NOVO"
					_mode_hint.text = "Suba para uma plataforma mais alta antes da água chegar."
		"quake":
			if _player != null:
				_player.set_camera_shake(0.12 + absf(sin(_weather_clock * 6.0)) * 0.12)
			if _world_root != null:
				_world_root.position = Vector3(sin(_weather_clock * 13.0) * 0.07, 0, cos(_weather_clock * 11.0) * 0.06)
		"wind":
			if _player != null:
				_player.set_camera_shake(0.04)
				if int(_weather_clock * 3.0) % 3 == 0:
					_player.add_weather_push(Vector3(sin(_weather_clock * 2.2), 0, cos(_weather_clock * 1.7)) * delta * 2.8)
			if _tornado_visual != null:
				_tornado_visual.rotation.y += delta * 2.4
				_tornado_visual.position.x = -18.0 + sin(_weather_clock * 0.45) * 7.0
				_tornado_visual.position.z = -12.0 + cos(_weather_clock * 0.36) * 6.0
	_round_label.text = "%s  •  %02d s" % [_disaster_display_name(), ceili(maxf(0.0, _round_remaining))]
	if _round_remaining <= 0.0:
		_round_active = false
		if _player != null:
			_player.set_camera_shake(0.0)
		if _world_root != null:
			_world_root.position = Vector3.ZERO
		_round_label.text = "VOCÊ SOBREVIVEU!  •  PARABÉNS"
		_mode_hint.text = "Toque em Experiências para jogar outra rodada."

func _disaster_display_name() -> String:
	match _disaster_kind:
		"flood": return "ENCHENTE"
		"quake": return "TERREMOTO"
		"wind": return "VENTANIA"
	return "DESASTRE NATURAL"

func _pizza_interact() -> void:
	if _current_mode != "pizza" or _player == null:
		return
	var station_positions := [Vector3(-8, 1, 3), Vector3(-1.5, 2, -3), Vector3(6, 1.6, -5.7), Vector3(8, 1, 4)]
	var station_names := ["balcão de pedidos", "preparo da pizza", "forno", "área de entregas"]
	var target: Vector3 = station_positions[_pizza_stage]
	if _player.global_position.distance_to(target) > 5.0:
		_mode_hint.text = "Chegue mais perto: %s." % station_names[_pizza_stage]
		return
	_pizza_stage += 1
	if _pizza_stage >= 4:
		_pizza_orders += 1
		_pizza_tips += 25
		_pizza_stage = 0
		_round_label.text = "PEDIDO CONCLUÍDO!  •  %d pedidos  •  %d gorjetas" % [_pizza_orders, _pizza_tips]
		_mode_hint.text = "Pedido entregue! Você ganhou 25 gorjetas fictícias. Próximo pedido: balcão."
	else:
		_round_label.text = "PIZZA PLACE  •  ETAPA %d/4" % (_pizza_stage + 1)
		_mode_hint.text = "Agora vá para %s." % station_names[_pizza_stage]

func _update_pizza_hint() -> void:
	if _active_page != "none" or _player == null:
		return
	var station_positions := [Vector3(-8, 1, 3), Vector3(-1.5, 2, -3), Vector3(6, 1.6, -5.7), Vector3(8, 1, 4)]
	var station_names := ["PEDIDOS", "PREPARO", "FORNO", "ENTREGAS"]
	var near_station := _player.global_position.distance_to(station_positions[_pizza_stage]) <= 5.0
	_interaction_button.visible = near_station
	if near_station:
		_mode_hint.text = "Toque em INTERAGIR: %s." % station_names[_pizza_stage]

func _send_chat_from(input: LineEdit, history: RichTextLabel) -> void:
	var message := input.text.strip_edges()
	if message.is_empty():
		return
	message = message.left(140)
	_add_chat_message("Você", message)
	if history != null and history != _chat_log:
		history.append_text("[color=#2678b8]Você:[/color] %s\n" % _bbcode_escape(message))
	input.clear()

func _add_chat_message(author: String, message: String) -> void:
	var escaped := _bbcode_escape(message)
	var entry := "[color=#2678b8]%s:[/color] %s" % [author, escaped]
	_chat_messages.append(entry)
	while _chat_messages.size() > 40:
		_chat_messages.pop_front()
	if _chat_log != null:
		_chat_log.append_text(entry + "\n")

func _bbcode_escape(value: String) -> String:
	return value.replace("[", "\\[").replace("]", "\\]")

func _on_jump_pressed() -> void:
	if _player != null:
		_player.jump()

func _on_respawn_pressed() -> void:
	if _player != null:
		_player.respawn()

