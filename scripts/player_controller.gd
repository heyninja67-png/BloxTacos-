extends CharacterBody3D
class_name ClassicPlayer

const AVATAR_PATHS := {
	"noob": "res://assets/avatars/noob_r6.glb",
	"bacon": "res://assets/avatars/bacon_hair.glb",
}

@export var walk_speed: float = 7.6
@export var ground_acceleration: float = 34.0
@export var air_acceleration: float = 13.0
@export var jump_strength: float = 8.7
@export var gravity_strength: float = 24.0

var spawn_position: Vector3 = Vector3(0.0, 0.1, 5.0)
var current_avatar: String = "noob"
var _joystick_input: Vector2 = Vector2.ZERO
var _camera_pivot: Node3D
var _camera: Camera3D
var _visual_root: Node3D
var _avatar_instance: Node3D
var _animation_player: AnimationPlayer
var _last_animation: StringName = &""
var _equipped_items: Array = []
var _sway_clock: float = 0.0
var _camera_shake_amount: float = 0.0
var _camera_base_rotation: Vector3 = Vector3(-0.22, 0.0, 0.0)
var _noob_skeleton: Skeleton3D

func _ready() -> void:
	_build_collision()
	_visual_root = Node3D.new()
	_visual_root.name = "AvatarRoot"
	add_child(_visual_root)
	_build_camera()
	set_avatar(current_avatar)
	position = spawn_position

func set_joystick_input(value: Vector2) -> void:
	_joystick_input = value.limit_length(1.0)

func add_look_input(relative_motion: Vector2) -> void:
	if _camera_pivot == null or _camera == null:
		return
	_camera_pivot.rotation.y -= relative_motion.x * 0.006
	_camera_base_rotation.x = clampf(_camera_base_rotation.x - relative_motion.y * 0.005, -0.75, 0.18)
	_camera.rotation.x = _camera_base_rotation.x

func set_camera_shake(amount: float) -> void:
	_camera_shake_amount = clampf(amount, 0.0, 0.5)

func jump() -> void:
	if is_on_floor():
		velocity.y = jump_strength

func set_avatar(avatar_id: String) -> void:
	if not AVATAR_PATHS.has(avatar_id):
		avatar_id = "noob"
	current_avatar = avatar_id
	if _avatar_instance != null:
		_visual_root.remove_child(_avatar_instance)
		_avatar_instance.queue_free()
	_avatar_instance = null
	_animation_player = null
	_noob_skeleton = null
	var resource := load(String(AVATAR_PATHS[avatar_id]))
	if not (resource is PackedScene):
		push_error("GLB do avatar não foi importado: " + String(AVATAR_PATHS[avatar_id]))
		return
	_avatar_instance = (resource as PackedScene).instantiate() as Node3D
	_avatar_instance.name = "Avatar_" + avatar_id
	if avatar_id == "bacon":
		# O arquivo do Bacon Hair foi exportado com escala de centímetros.
		_avatar_instance.scale = Vector3.ONE * 32.0
	else:
		# O Noob do arquivo enviado usa eixo Z como vertical; alinhar ao eixo Y do Godot.
		_avatar_instance.rotation.x = -PI * 0.5
	_visual_root.add_child(_avatar_instance)
	_animation_player = _find_animation_player(_avatar_instance)
	_noob_skeleton = _find_skeleton(_avatar_instance)
	if _animation_player != null:
		var animation_names := _animation_player.get_animation_list()
		for animation_name in animation_names:
			if String(animation_name).to_upper() == "RESET":
				continue
			var clip := _animation_player.get_animation(animation_name)
			if clip != null:
				clip.loop_mode = Animation.LOOP_LINEAR
				_animation_player.play(animation_name)
				break
	AvatarItems.apply(_visual_root, _equipped_items)

func set_equipped_items(item_ids: Array) -> void:
	_equipped_items = item_ids.duplicate()
	AvatarItems.apply(_visual_root, _equipped_items)

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	_camera_pivot.rotation.y = 0.0
	_camera_base_rotation.x = -0.22
	_camera.rotation.x = _camera_base_rotation.x

func add_weather_push(push: Vector3) -> void:
	velocity.x += push.x
	velocity.z += push.z

func _physics_process(delta: float) -> void:
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_input := _joystick_input if _joystick_input.length() > 0.12 else keyboard_input
	var camera_forward := -_camera_pivot.global_basis.z
	var camera_right := _camera_pivot.global_basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()
	var wish_direction := camera_right * move_input.x + camera_forward * -move_input.y
	if wish_direction.length() > 1.0:
		wish_direction = wish_direction.normalized()
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, wish_direction.x * walk_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, wish_direction.z * walk_speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	if Input.is_action_just_pressed("jump"):
		jump()
	if Input.is_action_just_pressed("respawn"):
		respawn()
	if wish_direction.length() > 0.08:
		var target_rotation := atan2(-wish_direction.x, -wish_direction.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_rotation, minf(1.0, delta * 12.0))
	move_and_slide()

func _process(delta: float) -> void:
	_sway_clock += delta * (9.0 if Vector2(velocity.x, velocity.z).length() > 0.35 else 2.2)
	if _noob_skeleton != null and current_avatar == "noob":
		_animate_noob_legs()
	if _camera != null and _camera_shake_amount > 0.001:
		_camera.rotation.z = sin(Time.get_ticks_msec() * 0.025) * _camera_shake_amount
		_camera.position.y = 2.15 + sin(Time.get_ticks_msec() * 0.035) * _camera_shake_amount * 0.45
	else:
		if _camera != null:
			_camera.rotation.z = 0.0
			_camera.position.y = 2.15

func _animate_noob_legs() -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.35 and is_on_floor()
	var swing := sin(_sway_clock) * (0.48 if moving else 0.035)
	var left_index := _noob_skeleton.find_bone("Left Leg_04")
	var right_index := _noob_skeleton.find_bone("Right Leg_05")
	if left_index >= 0:
		_noob_skeleton.set_bone_pose_rotation(left_index, Quaternion(Vector3.RIGHT, swing))
	if right_index >= 0:
		_noob_skeleton.set_bone_pose_rotation(right_index, Quaternion(Vector3.RIGHT, -swing))

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.46
	capsule.height = 2.85
	collision.shape = capsule
	collision.position = Vector3(0.0, 1.425, 0.0)
	add_child(collision)

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0.0, 1.32, 0.0)
	add_child(_camera_pivot)
	_camera = Camera3D.new()
	_camera.name = "ThirdPersonCamera"
	_camera.position = Vector3(0.0, 2.15, 7.4)
	_camera.rotation.x = _camera_base_rotation.x
	_camera.current = true
	_camera.fov = 72.0
	_camera_pivot.add_child(_camera)
