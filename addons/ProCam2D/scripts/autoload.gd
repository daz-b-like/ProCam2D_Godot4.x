extends Node

enum FollowMode {
	SINGLE_TARGET,
	MULTI_TARGET
}

enum DragType {
	SMOOTH_DAMP,
	LOOK_AHEAD,
	AUTO_SPEED,
	SPRING_DAMP,
}

var process_frame: set = set_process_frame, get = get_process_frame
var follow_mode: int = FollowMode.SINGLE_TARGET: set = set_follow_mode, get = get_follow_mode
var drag_type : int = DragType.SMOOTH_DAMP: set = set_drag_type, get = get_drag_type
var smooth_drag: bool = true: set = set_smooth_drag, get = get_smooth_drag
var smooth_drag_speed: Vector2 = Vector2(5, 5): set = set_smooth_drag_speed, get = get_smooth_drag_speed
var prediction_time: Vector2 = Vector2(9, 9): set = set_prediction_time, get = get_prediction_time
var offset: Vector2 = Vector2.ZERO: set = set_offset, get = get_offset
var smooth_offset: bool = true: set = set_smooth_offset, get = get_smooth_offset
var smooth_offset_speed: float = 5.0: set = set_smooth_offset_speed, get = get_smooth_offset_speed
var allow_rotation: bool = false: set = set_allow_rotation, get = get_allow_rotation
var smooth_rotation: bool = true: set = set_smooth_rotation, get = get_smooth_rotation
var smooth_rotation_speed: float = 5.0: set = set_smooth_rotation_speed, get = get_smooth_rotation_speed
var zoom: float = 1.0: set = setter_for_zoom, get = get_zoom
var smooth_zoom: bool = true: set = set_smooth_zoom, get = get_smooth_zoom
var smooth_zoom_speed: float = 5.0: set = set_smooth_zoom_speed, get = get_smooth_zoom_speed
var auto_zoom: bool = true: set = set_auto_zoom, get = get_auto_zoom
var min_zoom: float = 0.0: set = set_min_zoom, get = get_min_zoom
var max_zoom: float = 1.0: set = set_max_zoom, get = get_max_zoom
var zoom_margin: float = 5.0: set = set_zoom_margin, get = get_zoom_margin
var smooth_limit: bool = true: set = set_smooth_limit, get = get_smooth_limit
var left_limit: int = -10000000: set = set_left_limit, get = get_left_limit
var right_limit: int = 10000000: set = set_right_limit, get = get_right_limit
var top_limit: int = -10000000: set = set_top_limit, get = get_top_limit
var bottom_limit: int = 10000000: set = set_bottom_limit, get = get_bottom_limit
var use_h_margins: bool = false: set = set_use_h_margins, get = get_use_h_margins
var use_v_margins: bool = false: set = set_use_v_margins, get = get_use_v_margins
var left_margin: float = 0.3: set = set_left_margin, get = get_left_margin
var right_margin: float = 0.3: set = set_right_margin, get = get_right_margin
var top_margin: float = 0.3: set = set_top_margin, get = get_top_margin
var bottom_margin: float = 0.3: set = set_bottom_margin, get = get_bottom_margin
var cam: Node2D

func _ready():
	get_tree().connect("tree_changed", Callable(self, "_on_scene_changed"))

func start_cinematic(id):
	cam.start_cinematic(id)

func stop_cinematic():
	cam.stop_cinematic()

func get_camera_bounds() -> Rect2:
	return cam.get_camera_bounds()

func reset_camera():
	cam.reset_camera()
	stop_cinematic()

func add_addon(addon: PCamAddon) -> void:
	cam.add_addon(addon)

func get_addons() -> Array:
	return cam.get_addons()

func remove_addon(addon: PCamAddon) -> void:
	cam.remove_addon(addon)

func set_position(new_position: Vector2):
	cam.set_position(new_position)

func set_rotation(new_rotation: float):
	cam.set_rotation(new_rotation)

func set_zoom(new_zoom: float):
	cam.set_zoom(new_zoom)

#setters
func set_follow_mode(value):
	follow_mode = value
	if cam:
		cam.follow_mode = value

func set_drag_type(value):
	drag_type = value
	if cam:
		cam.drag_type = value

func set_smooth_drag(value):
	smooth_drag = value
	if cam:
		cam.smooth_drag = value

func set_smooth_drag_speed(value):
	smooth_drag_speed = value
	if cam:
		cam.smooth_drag_speed = value

func set_prediction_time(value):
	prediction_time = value
	if cam:
		cam.prediction_time = value

func set_offset(value):
	offset = value
	if cam:
		cam.offset = value

func set_smooth_offset(value):
	smooth_offset = value
	if cam:
		cam.smooth_offset = value

func set_smooth_offset_speed(value):
	smooth_offset_speed = value
	if cam:
		cam.smooth_offset_speed = value

func set_allow_rotation(value):
	allow_rotation = value
	if cam:
		cam.allow_rotation = value

func set_smooth_rotation(value):
	smooth_rotation = value
	if cam:
		cam.smooth_rotation = value

func set_smooth_rotation_speed(value):
	smooth_rotation_speed = value
	if cam:
		cam.smooth_rotation_speed = value

func setter_for_zoom(value):
	zoom = value
	if cam:
		cam.zoom = value

func set_smooth_zoom(value):
	smooth_zoom = value
	if cam:
		cam.smooth_zoom = value

func set_smooth_zoom_speed(value):
	smooth_zoom_speed = value
	if cam:
		cam.smooth_zoom_speed = value

func set_auto_zoom(value):
	auto_zoom = value
	if cam:
		cam.auto_zoom = value

func set_min_zoom(value):
	min_zoom = value
	if cam:
		cam.min_zoom = value

func set_max_zoom(value):
	max_zoom = value
	if cam:
		cam.max_zoom = value

func set_zoom_margin(value):
	zoom_margin = value
	if cam:
		cam.zoom_margin = value

func set_smooth_limit(value):
	smooth_limit = value
	if cam:
		cam.smooth_limit = value

func set_left_limit(value):
	left_limit = value
	if cam:
		cam.left_limit = value

func set_right_limit(value):
	right_limit = value
	if cam:
		cam.right_limit = value

func set_top_limit(value):
	top_limit = value
	if cam:
		cam.top_limit = value

func set_bottom_limit(value):
	bottom_limit = value
	if cam:
		cam.bottom_limit = value

func set_use_h_margins(value):
	use_h_margins = value
	if cam:
		cam.use_h_margins = value

func set_use_v_margins(value):
	use_v_margins = value
	if cam:
		cam.use_v_margins = value

func set_left_margin(value):
	left_margin = value
	if cam:
		cam.left_margin = value

func set_right_margin(value):
	right_margin = value
	if cam:
		cam.right_margin = value

func set_top_margin(value):
	top_margin = value
	if cam:
		cam.top_margin = value

func set_bottom_margin(value):
	bottom_margin = value
	if cam:
		cam.bottom_margin = value

func set_process_frame(value):
	if cam:
		cam.process_frame = value

func get_follow_mode() -> int:
	return cam.follow_mode if cam else follow_mode

func get_drag_type() -> int:
	return cam.drag_type if cam else drag_type

func get_smooth_drag() -> bool:
	return cam.smooth_drag if cam else smooth_drag

func get_smooth_drag_speed() -> Vector2:
	return cam.smooth_drag_speed if cam else smooth_drag_speed

func get_prediction_time() -> Vector2:
	return cam.prediction_time if cam else prediction_time

func get_offset() -> Vector2:
	return cam.offset if cam else offset

func get_smooth_offset() -> bool:
	return cam.smooth_offset if cam else smooth_offset

func get_smooth_offset_speed() -> float:
	return cam.smooth_offset_speed if cam else smooth_offset_speed

func get_allow_rotation() -> bool:
	return cam.allow_rotation if cam else allow_rotation

func get_smooth_rotation() -> bool:
	return cam.smooth_rotation if cam else smooth_rotation

func get_smooth_rotation_speed() -> float:
	return cam.smooth_rotation_speed if cam else smooth_rotation_speed

func get_zoom() -> float:
	return cam.zoom if cam else zoom

func get_smooth_zoom() -> bool:
	return cam.smooth_zoom if cam else smooth_zoom

func get_smooth_zoom_speed() -> float:
	return cam.smooth_zoom_speed if cam else smooth_zoom_speed

func get_auto_zoom() -> bool:
	return cam.auto_zoom if cam else auto_zoom

func get_min_zoom() -> float:
	return cam.min_zoom if cam else min_zoom

func get_max_zoom() -> float:
	return cam.max_zoom if cam else max_zoom

func get_zoom_margin() -> float:
	return cam.zoom_margin if cam else zoom_margin

func get_smooth_limit() -> bool:
	return cam.smooth_limit if cam else smooth_limit

func get_left_limit() -> int:
	return cam.left_limit if cam else left_limit

func get_right_limit() -> int:
	return cam.right_limit if cam else right_limit

func get_top_limit() -> int:
	return cam.top_limit if cam else top_limit

func get_bottom_limit() -> int:
	return cam.bottom_limit if cam else bottom_limit

func get_use_h_margins() -> bool:
	return cam.use_h_margins if cam else use_h_margins

func get_use_v_margins() -> bool:
	return cam.use_v_margins if cam else use_v_margins

func get_left_margin() -> float:
	return cam.left_margin if cam else left_margin

func get_right_margin() -> float:
	return cam.right_margin if cam else right_margin

func get_top_margin() -> float:
	return cam.top_margin if cam else top_margin

func get_bottom_margin() -> float:
	return cam.bottom_margin if cam else bottom_margin

func get_process_frame() -> float:
	return cam.process_frame if cam else process_frame

func _on_scene_changed():
	if is_inside_tree():
		var cam_g = get_tree().get_nodes_in_group("procam")
		if not cam_g.is_empty():
			cam = cam_g[0]
		else: cam = null
