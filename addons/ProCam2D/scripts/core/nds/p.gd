@tool
extends "b.gd"

const GROUP_NAME = "procam_paths"

enum AxisConstraint {
	X,
	Y
}

@export_enum("X","Y") var constraint_axis: int = AxisConstraint.Y

var _path: Path2D: set = set_path
var _configuration_warning: String = ""
var _pos: Vector2
var _path_follow := PathFollow2D.new()
var _pos2d := Node2D.new()

func _init() -> void:
	add_to_group(GROUP_NAME)

func _ready():
	super._ready()
	connect("child_entered_tree", Callable(self, "update_configuration_warning"))
	_update_path()

func should_constrain() -> bool:
	return enabled and _path != null

func apply_constraint(camera_pos: Vector2) -> Vector2:
	if not _path and Engine.is_editor_hint():
		return camera_pos

	var local_point = to_local(camera_pos)
	
	var constrained_local_pos = local_point
	match constraint_axis:
		AxisConstraint.X:
			var closest_offset = _path.curve.get_closest_offset(Vector2(_pos2d.position.x,local_point.y))
			_pos2d.position = _path.curve.sample_baked(closest_offset, false)
			constrained_local_pos.x = _pos2d.position.x
		AxisConstraint.Y:
			var closest_offset = _path.curve.get_closest_offset(Vector2(local_point.x, _pos2d.position.y))
			_pos2d.position = _path.curve.sample_baked(closest_offset, false)
			constrained_local_pos.y = _pos2d.position.y
	_pos = constrained_local_pos
	queue_redraw()
	return to_global(_pos)

func _update_path():
	_path = null
	_configuration_warning = ""

	for child in get_children():
		if child is Path2D:
			_path = child
			if not Engine.is_editor_hint():
				_path.call_deferred("add_child", _path_follow)
				_path_follow.call_deferred("add_child", _pos2d)
			break

	if not _path:
		_configuration_warning = "PCamPath node requires a Path2D child to define the path."
	_update_configuration_warning()

func _get_configuration_warning() -> String:
	return _configuration_warning

func _update_configuration_warning():
	if not enabled:
		_configuration_warning = "PCamPath is disabled."
	elif not _path:
		_configuration_warning = "PCamPath node requires a Path2D child to define the path."
	else:
		_configuration_warning = ""
	notify_property_list_changed()
	update_configuration_warnings()

func set_path(path):
	_path = path
	update_configuration_warnings()

func _draw_debug():
	if not _path:
		return
	var points = _path.curve.get_baked_points()
	draw_circle(points[0], 5 * debug_draw_scaler, debug_color[1])
	for i in range(1, points.size()):
		draw_line(points[i-1], points[i], debug_color[1], 2, true)
	draw_circle(points[points.size()-1], 5 * debug_draw_scaler, debug_color[1])
	draw_circle(_pos2d.position, 5 * debug_draw_scaler, debug_color[2])
