@tool
extends "b.gd"

const GROUP_NAME: = "procam_zooms"

enum ZoomShape { CIRCLE, RECTANGLE }

var zoom_shape = ZoomShape.CIRCLE: set = set_zoom_shape
var radius = 200.0: set = set_radius
var rectangle_size = Vector2(400, 200): set = set_rectangle_size
var zoom_factor = 1.5: set = set_zoom_factor
var gradual_zoom = true: set = set_gradual_zoom

signal zoom_area_entered(zoom)
signal zoom_area_exited(zoom)
signal zoom_level_changed(zoom_level)

var _is_in_zoom_area = false
var _current_zoom_level = 1.0
var _half_size = Vector2.ZERO

func _init():
	add_to_group(GROUP_NAME)

func _ready():
	super._ready()
	_update_half_size()

func set_rectangle_size(new_size):
	rectangle_size = new_size
	_update_half_size()

func _update_half_size():
	_half_size = rectangle_size * 0.5
	queue_redraw()

func apply_influence(camera):
	if not enabled:
		return camera._target_zoom

	var local_pos = to_local(camera._target_position)
	var t = 0.0
	var is_inside = false

	if zoom_shape == ZoomShape.CIRCLE:
		t = local_pos.length() / radius
		is_inside = t <= 1.0
	else:  # ZoomShape.RECTANGLE
		t = max(abs(local_pos.x) / _half_size.x, abs(local_pos.y) / _half_size.y)
		is_inside = t <= 1.0

	if is_inside and not _is_in_zoom_area:
		_is_in_zoom_area = true
		emit_signal("zoom_area_entered", self)
	elif not is_inside and _is_in_zoom_area:
		_is_in_zoom_area = false
		emit_signal("zoom_area_exited", self)

	var new_zoom_level
	if is_inside:
		new_zoom_level = camera._target_zoom * lerp(zoom_factor, 1.0, t) if gradual_zoom else camera._target_zoom * zoom_factor
	else:
		new_zoom_level = camera._target_zoom

	if abs(new_zoom_level - _current_zoom_level) > 0.01:
		_current_zoom_level = new_zoom_level
		emit_signal("zoom_level_changed", _current_zoom_level)

	return new_zoom_level

func set_zoom_shape(value):
	zoom_shape = value
	queue_redraw()
	notify_property_list_changed()

func set_radius(value):
	radius = value
	queue_redraw()

func set_zoom_factor(value):
	zoom_factor = value

func set_gradual_zoom(value):
	gradual_zoom = value

func _draw_debug():
	if zoom_shape == ZoomShape.CIRCLE:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, debug_color[1], 1.0)
	else:  # ZoomShape.RECTANGLE
		draw_rect(Rect2(-_half_size, rectangle_size), debug_color[1], false, 1.0)
	draw_circle(Vector2.ZERO, 5 * debug_draw_scaler, debug_color[0])

func _exit_tree():
	if _is_in_zoom_area:
		emit_signal("zoom_area_exited", self)

func _get_property_list():
	var properties = []
	
	# Zoom Properties
	properties.append({
		"name": "Zoom Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	
	properties.append({
		"name": "zoom_shape",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Circle,Rectangle",
		"usage": PROPERTY_USAGE_DEFAULT
	})
	# Shape-specific Properties
	if zoom_shape == ZoomShape.CIRCLE:
		properties.append({
			"name": "radius",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	elif zoom_shape == ZoomShape.RECTANGLE:
		properties.append({
			"name": "rectangle_size",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	
	properties.append({
		"name": "zoom_factor",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		"name": "gradual_zoom",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	return properties
