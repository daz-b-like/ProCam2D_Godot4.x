@tool
extends PCamAddon
class_name PCamMouseFollow

@export var max_distance := 200.0
var _current_offset := Vector2.ZERO   

func _init():
	stage = "pre_process"

func pre_process(camera, delta):
	if not enabled or camera._playing_cinematic:
		return
	var viewport = camera.get_viewport()
	if not viewport:
		return
	var mouse_position = viewport.get_mouse_position()
	var viewport_size = viewport.size
	var screen_center =camera.get_viewport_rect().size / 2
	var distance = mouse_position.distance_to(screen_center)
	var direction = screen_center.direction_to(mouse_position)
	distance = clamp(distance, -max_distance, max_distance)
	var target_pos = direction * distance
	_current_offset = target_pos
	camera._target_position += _current_offset
