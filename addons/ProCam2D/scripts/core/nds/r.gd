@tool
extends "b.gd"

const GROUP_NAME = "procam_rooms"

var room_size = Vector2(1000, 600): set = set_room_size
var zoom = 1.0
var open_sides := 0: set = set_open_sides

var _rect = Rect2()
var _current_camera = null
var _is_inside = false
var og_drag_type: int

signal room_entered(room)
signal room_exited(room)

func _init():
	add_to_group(GROUP_NAME)

func _ready():
	_update_rect()

func _update_rect():
	_rect = Rect2(-room_size/2, room_size)
	queue_redraw()

func is_point_inside(cam):
	var point = cam._target_position
	var local_point = to_local(point)
	var is_inside_now = enabled and _rect.has_point(local_point)
	
	if is_inside_now and not _is_inside:
		_is_inside = true
		og_drag_type = cam.drag_type
		cam.drag_type = 0
		emit_signal("room_entered", self)
	elif not is_inside_now and _is_inside:
		_is_inside = false
		cam.drag_type = og_drag_type
		emit_signal("room_exited", self)
	
	return is_inside_now

func apply_constraint(camera):
	if camera != _current_camera:
		_current_camera = camera
	
	var viewport_size = get_viewport_rect().size
	var target_zoom = max(viewport_size.x / room_size.x, viewport_size.y / room_size.y) 
	camera._target_zoom = clamp(camera._target_zoom, target_zoom * max(zoom, 1.0), INF)
	camera._target_rotation = global_rotation
	var half_visible_rect = viewport_size / (2 * camera._target_zoom)
	var min_pos = global_position + _rect.position + half_visible_rect
	var max_pos = global_position + _rect.end - half_visible_rect
	var camera_pos = camera._target_position

	if not (open_sides & 1): camera_pos.x = max(camera_pos.x, min_pos.x)
	if not (open_sides & 2): camera_pos.x = min(camera_pos.x, max_pos.x)
	if not (open_sides & 4): camera_pos.y = max(camera_pos.y, min_pos.y)
	if not (open_sides & 8): camera_pos.y = min(camera_pos.y, max_pos.y)
	return camera_pos

func set_open_sides(value):
	open_sides = value
	_update_rect()

func set_room_size(value):
	room_size = value
	_update_rect()

func _draw_debug():
	var start = _rect.position
	var end = _rect.end
	for i in range(4):
		var color = Color.YELLOW if open_sides & (1 << i) else debug_color[0]
		match i:
			0: draw_line(Vector2(start.x, start.y), Vector2(start.x, end.y), color, 1)
			1: draw_line(Vector2(end.x, start.y), Vector2(end.x, end.y), color, 1)
			2: draw_line(Vector2(start.x, start.y), Vector2(end.x, start.y), color, 1)
			3: draw_line(Vector2(start.x, end.y), Vector2(end.x, end.y), color, 1)

func _exit_tree():
	if _is_inside:
		emit_signal("room_exited", self)


func _get_property_list():
	var properties = []
	properties.append({
		"name": "Room Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		"name": "room_size",
		"type": TYPE_VECTOR2,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		"name": "zoom",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		"name": "open_sides",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_FLAGS,
		"hint_string": "Left, Right, Top, Bottom",
		"usage": PROPERTY_USAGE_DEFAULT
	})
	return properties
