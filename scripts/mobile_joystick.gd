extends Control
class_name MobileJoystick

## Joystick virtual simples: não depende de imagens ou plugins externos.
var direction: Vector2 = Vector2.ZERO
var _active_finger: int = -1
var _mouse_active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(176.0, 176.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_finger == -1:
			_active_finger = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == _active_finger:
			_active_finger = -1
			direction = Vector2.ZERO
			queue_redraw()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _active_finger:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_active = event.pressed
		if _mouse_active:
			_update_from_position(event.position)
		else:
			direction = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and _mouse_active:
		_update_from_position(event.position)

func _update_from_position(local_position: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.37
	if radius <= 0.0:
		return
	direction = ((local_position - center) / radius).limit_length(1.0)
	queue_redraw()
	accept_event()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	draw_circle(center, radius, Color(0.035, 0.08, 0.11, 0.48))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.76, 0.91, 0.95, 0.55), 4.0, true)
	draw_circle(center, radius * 0.58, Color(0.18, 0.33, 0.39, 0.23))
	var knob_center := center + direction * radius * 0.57
	draw_circle(knob_center, radius * 0.36, Color(0.94, 0.97, 0.98, 0.88))
	draw_arc(knob_center, radius * 0.36, 0.0, TAU, 48, Color(0.14, 0.28, 0.34, 0.82), 3.0, true)
