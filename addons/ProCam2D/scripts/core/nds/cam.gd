@tool
extends "b.gd"

const GROUP_NAME: = "procam"

# Enums

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

#signals
signal cinematic_started(cinematic_id)
signal cinematic_stopped(cinematic_id)
signal addon_message(message)

#variables
var follow_mode = FollowMode.SINGLE_TARGET: set = set_follow_mode
var drag_type = DragType.LOOK_AHEAD: set = set_drag_type
var smooth_drag: bool = true: set = set_smooth_drag
var smooth_drag_speed: Vector2 = Vector2(5, 5)
var max_distance: = Vector2(100000,100000)
var prediction_time: Vector2 = Vector2(9, 9)
var offset: Vector2 = Vector2.ZERO
var smooth_offset: bool = true:  set = set_smooth_offset
var smooth_offset_speed: float = 2.0
var allow_rotation: bool = true: set = set_allow_rotation
var smooth_rotation: bool = true: set = set_smooth_rotation
var smooth_rotation_speed: float = 5.0
var zoom: float = 1.0
var smooth_zoom: bool = true: set = set_smooth_zoom
var smooth_zoom_speed: float = 5.0
var auto_zoom: bool = true: set = set_auto_zoom
var min_zoom: float = 0.0
var max_zoom: float = 1.0
var zoom_margin: float = 5.0
var smooth_limit: bool = true
var left_limit: int = -10000000
var right_limit: int = 10000000
var top_limit: int = -10000000
var bottom_limit: int = 10000000
var use_h_margins: bool = false: set = set_use_h_margins
var use_v_margins: bool = false: set = set_use_v_margins
var left_margin: float = 0.3
var right_margin: float = 0.3
var top_margin: float = 0.3
var bottom_margin: float = 0.3
var working_radius := 2000.0
var global_debug_draw := false: set = set_global_debug_draw
@export var addons: Array[PCamAddon] = []

# Private variables
var _cell_size := 8000.0
var _global_debug_draw: bool
var _target_offset: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO
var _current_offset_velocity: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO
var _current_velocity: Vector2 = Vector2.ZERO
var _current_rotation: float = 0.0
var _target_rotation: float = 0.0
var _current_rotation_velocity: float = 0.0
var _current_zoom: float = 0.0
var _target_zoom: float = 0.0
var _current_zoom_velocity: float = 0.0
var _margin_offset: Vector2 = Vector2.ZERO
var _velocity: Vector2
var _camera: Camera2D
var _spatial_hash = {}
var _accumulated_rotation: float = 0.0
var _previous_target_angle: float = 0.0
var _nearby_nodes = []
var _viewport_size: Vector2
var _active_path = null
var _playing_cinematic: bool = false
var _active_cinematic_id: String = ""
var _current_cinematic_index: int = 0
var _active_cinematics: Array = []
# Influence nodes
var _targets: Array = []
var _rooms: Array = []
var _magnets: Array = []
var _paths: Array = []
var _zooms: Array = []
var _cinematics: Array = []

func _init() -> void:
	add_to_group(GROUP_NAME)

func _ready() -> void:
	super._ready()
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	if Engine.is_editor_hint():
		return
	_gather_influence_nodes()
	_setup_camera()
	_setup_addons()
	_setup_spatial_hash()
	check_camera_priority()

func _setup_spatial_hash():
	_cell_size = working_radius * 2
	for node in _rooms + _magnets + _zooms:
		_add_to_spatial_hash(node)

func _add_to_spatial_hash(node):
	var cell = _get_cell(node.global_position)
	if not _spatial_hash.has(cell):
		_spatial_hash[cell] = []
	_spatial_hash[cell].append(node)

func _remove_from_spatial_hash(node):
	var cell = _get_cell(node.global_position)
	if _spatial_hash.has(cell):
		_spatial_hash[cell].erase(node)

func _get_cell(position):
	return Vector2(floor(position.x / _cell_size), floor(position.y / _cell_size))

func _get_nearby_nodes(position, radius):
	var nearby_nodes = []
	var center_cell = _get_cell(position)
	var cells_to_check = ceil(radius / _cell_size)
	
	for x in range(-cells_to_check, cells_to_check + 1):
		for y in range(-cells_to_check, cells_to_check + 1):
			var check_cell = center_cell + Vector2(x, y)
			if _spatial_hash.has(check_cell):
				for node in _spatial_hash[check_cell]:
					if node.global_position.distance_to(position) <= radius:
						nearby_nodes.append(node)
	
	return nearby_nodes

func check_camera_priority():
	var cameras = _get_nodes_in_group("procam")
	if cameras.size() > 0:
		for camera in cameras:
			camera.enabled = (camera == cameras[0])
	else:
		enabled = true

func _setup_camera() -> void:
	_current_position = global_position
	_current_rotation = global_rotation
	_current_zoom = zoom
	_camera = Camera2D.new()
	_camera.ignore_rotation = false
	_update_limits()
	set_global_debug_draw(_global_debug_draw)
	set_tha_process_mode(_pm)
	_camera.set_process_mode(process_frame)
	call_deferred("add_child", _camera)
	call_deferred("_reparent_camera")
	_camera.enabled = true
	if _camera.is_inside_tree():
		_camera.make_current()
	reset_camera()

func _reparent_camera() -> void:
	var root = get_tree().root
	var first_node = root.get_child(0)
	if first_node != self:
		var current_parent = get_parent()
		if current_parent:
			current_parent.remove_child(self)
		first_node.add_child(self)
		set_owner(first_node)

func _update_limits() -> void:
	_camera.limit_left = left_limit
	_camera.limit_right = right_limit
	_camera.limit_top = top_limit
	_camera.limit_bottom = bottom_limit

func _gather_influence_nodes() -> void:
	_rooms = _get_nodes_in_group("procam_rooms")
	_magnets = _get_nodes_in_group("procam_magnets")
	_paths = _get_nodes_in_group("procam_paths")
	_zooms = _get_nodes_in_group("procam_zooms")
	_cinematics = _get_nodes_in_group("procam_cinematics")
	for node in _rooms + _paths:
		if not node.is_connected("priority_changed", Callable( self, "_on_node_priority_changed")):
			node.connect("priority_changed", Callable( self, "_on_node_priority_changed"))
	for node in _rooms + _magnets + _zooms:
		if not node.is_connected("position_changed", Callable(self, "_on_node_position_changed")):
			node.connect("position_changed", Callable(self, "_on_node_position_changed"))
			node.connect("tree_left", Callable( self, "on_node_exited"))
	for node in _get_nodes_in_group("procam_targets") + _get_nodes_in_group("procam_rooms") + _get_nodes_in_group("procam_magnets") + _get_nodes_in_group("procam_zooms") + _get_nodes_in_group("procam_paths") + _get_nodes_in_group("procam_cinematics"):
		if not is_connected("debug_draw_changed", Callable(node, "change_debug")):
			connect("debug_draw_changed", Callable(node, "change_debug"))
			node.debug_draw = _global_debug_draw

func _on_node_priority_changed(node) -> void:
	var groups = node.get_groups()
	for group_name in groups:
		if group_name.begins_with("procam"):
			match group_name:
				"procam_rooms":
					_rooms = _get_nodes_in_group("procam_rooms")
				"procam_paths":
					_paths = _get_nodes_in_group("procam_paths")

func on_node_exited(node):
	_remove_from_spatial_hash(node)

func _on_node_position_changed(node):
	_remove_from_spatial_hash(node)
	_add_to_spatial_hash(node)

func _get_nodes_in_group(group_name: String) -> Array:
	var nodes = get_tree().get_nodes_in_group(group_name)
	nodes.sort_custom(Callable(PCamUtils, "_sort_by_priority"))
	return nodes

func _update(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_targets(delta)
	_apply_influences()
	_apply_addons_by_stage("pre_process", delta) # Pre-processing addons
	_update_offset(delta)
	_update_position(delta)
	_update_rotation(delta)
	_update_zoom(delta)
	_apply_addons_by_stage("post_smoothing", delta) # Post-smoothing addons
	_update_limits()
	_apply_limits()
	_apply_addons_by_stage("final_adjust", delta) # Final adjustment addons
	_apply_transforms()
	
func _apply_limits():
	#position limits
	if not _playing_cinematic:
		_current_position.x = clamp(_current_position.x, _target_position.x - max_distance.x, _target_position.x + max_distance.x)
		_current_position.y = clamp(_current_position.y, _target_position.y - max_distance.y, _target_position.y + max_distance.y)
	_current_position = PCamUtils.clamp_point_inside_rect(_current_position, _calculate_limit_rect()[1])
	#zoom limits
	var limit_rect = _calculate_limit_rect()[2]
	var zoom_limit = max(_viewport_size.y / limit_rect.size.y, _viewport_size.x / limit_rect.size.x)
	_current_zoom  = clamp(_current_zoom, zoom_limit, INF)

func _update_targets(delta) -> void:
	_viewport_size = get_viewport_rect().size
	_nearby_nodes = _get_nearby_nodes(global_position, 2000)
	_targets.clear()
	for target in _get_nodes_in_group("procam_targets"):
		if target.enabled:
			if not target.disable_outside_limits or (target.disable_outside_limits and _calculate_limit_rect()[2].has_point(to_local(target.global_position))):
				target._update_velocity(delta)
				_targets.append(target)
	_target_rotation = _calculate_target_rotation()
	_target_position = _calculate_target_position()
	_target_zoom = _calculate_target_zoom()
	_target_offset = offset.rotated(_current_rotation) if not _playing_cinematic else Vector2.ZERO

func _apply_influences():
	_target_zoom = _apply_zoom_influences()
	_target_position = _apply_magnet_influence(_target_position)
	_target_position = _apply_deadzones(_target_position)
	_target_position = _apply_path_constraints(_target_position)
	_target_position = _apply_room_constraints(_target_position)
	_target_position = _apply_cinematic_influences(_target_position)

func _update_offset(delta: float) -> void:
	if smooth_offset:
		var result_x = PCamUtils.smooth_damp(_current_offset.x, _target_offset.x, _current_offset_velocity.x, smooth_offset_speed, INF, delta)
		_current_offset.x = result_x.new_position
		_current_offset_velocity.x = result_x.new_velocity
		var result_y = PCamUtils.smooth_damp(_current_offset.y, _target_offset.y, _current_offset_velocity.y, smooth_offset_speed, INF, delta)
		_current_offset.y = result_y.new_position
		_current_offset_velocity.y = result_y.new_velocity
	else: 
		_current_offset = _target_offset

func _update_position(delta: float) -> void:
	var target_position = _target_position
	
	if smooth_limit:
		target_position = PCamUtils.clamp_point_inside_rect(target_position, _calculate_limit_rect()[1])
	
	if smooth_drag:
		match drag_type:
			DragType.SPRING_DAMP:
				var result_x = PCamUtils.spring_damp(_current_position.x, target_position.x, _current_velocity.x, 15.0, smooth_drag_speed.x, delta)
				_current_position.x = result_x.new_position
				_current_velocity.x = result_x.new_velocity
				var result_y = PCamUtils.spring_damp(_current_position.y, target_position.y, _current_velocity.y, 15.0, smooth_drag_speed.y, delta)
				_current_position.y = result_y.new_position
				_current_velocity.y = result_y.new_velocity
			DragType.SMOOTH_DAMP:
				var result_x = PCamUtils.smooth_damp(_current_position.x, target_position.x, _current_velocity.x, smooth_drag_speed.x, INF, delta)
				_current_position.x = result_x.new_position
				_current_velocity.x = result_x.new_velocity
				var result_y = PCamUtils.smooth_damp(_current_position.y, target_position.y, _current_velocity.y, smooth_drag_speed.y, INF, delta)
				_current_position.y = result_y.new_position
				_current_velocity.y = result_y.new_velocity	
			DragType.AUTO_SPEED:
				var result_x = PCamUtils.adaptive_smooth_damp(_current_position.x, target_position.x, _current_velocity.x, INF, delta)
				_current_position.x = result_x.new_position
				_current_velocity.x = result_x.new_velocity
				var result_y = PCamUtils.adaptive_smooth_damp(_current_position.y, target_position.y, _current_velocity.y, INF, delta)
				_current_position.y = result_y.new_position
				_current_velocity.y = result_y.new_velocity
			DragType.LOOK_AHEAD:
				target_position = Vector2(
					PCamUtils.predict_future_position(target_position.x, _velocity.x, max(prediction_time.x/10, 0.01)),
					PCamUtils.predict_future_position(target_position.y, _velocity.y, max(prediction_time.y/10, 0.01))
				)
				var result_x = PCamUtils.smooth_damp(_current_position.x, target_position.x, _current_velocity.x, smooth_drag_speed.x * 0.2, INF, delta)
				_current_position.x = result_x.new_position
				_current_velocity.x = result_x.new_velocity
				var result_y = PCamUtils.smooth_damp(_current_position.y, target_position.y, _current_velocity.y, smooth_drag_speed.y * 0.2, INF, delta)
				_current_position.y = result_y.new_position
				_current_velocity.y = result_y.new_velocity
	else:
		_current_position = target_position

func _update_rotation(delta: float) -> void:
	if not allow_rotation:
		return
	
	var target_rotation = _target_rotation
	
	if smooth_rotation:
		var result = PCamUtils.smooth_damp_angle(_current_rotation, target_rotation, _current_rotation_velocity, smooth_rotation_speed, INF, delta)
		_current_rotation = result.new_angle
		_current_rotation_velocity = result.new_velocity
	else:
		_current_rotation = target_rotation

func _update_zoom(delta: float) -> void:
	var target_zoom = _target_zoom
	
	if smooth_zoom:
		var result = PCamUtils.smooth_damp(_current_zoom, target_zoom, _current_zoom_velocity, smooth_zoom_speed, INF, delta)
		_current_zoom = result.new_position
		_current_zoom_velocity = result.new_velocity
	else:
		_current_zoom = target_zoom

func _apply_room_constraints(pos: Vector2) -> Vector2:
	var active_room = null
	for room in _nearby_nodes:
		if room.is_in_group("procam_rooms") and room.is_point_inside(self):
			if not active_room or room.priority > active_room.priority:
				active_room = room
	if active_room:
		pos = active_room.apply_constraint(self)
	return pos

func _apply_zoom_influences() -> float:
	var final_zoom: float = _target_zoom
	for node in _nearby_nodes:
		if node.is_in_group("procam_zooms"):
			final_zoom = node.apply_influence(self)
	return final_zoom

func _apply_path_constraints(pos: Vector2) -> Vector2:
	var active_path = null
	for path in _paths:
		if path.should_constrain():
			if not active_path or path.priority > active_path.priority:
				active_path = path
	if active_path:
		pos = active_path.apply_constraint(pos)
	return pos

func _apply_magnet_influence(pos: Vector2) -> Vector2:
	for node in _nearby_nodes:
		if node.is_in_group("procam_magnets"):
			pos = node.apply_influence(pos)
	return pos

func _apply_cinematic_influences(pos: Vector2) -> Vector2:
	if not _playing_cinematic or _active_cinematics.is_empty():
		return pos
	
	var current_cinematic = _active_cinematics[_current_cinematic_index]
	
	if current_cinematic.is_complete():
		_current_cinematic_index += 1
		if _current_cinematic_index >= _active_cinematics.size():
			stop_cinematic()
			return pos
		_active_cinematics[_current_cinematic_index].start(self)
	
	return current_cinematic.apply_influence(self)

func _apply_addons_by_stage(stage: String, delta: float) -> void:
	var stage_addons = []
	for addon in addons:
		if addon is PCamAddon and addon.enabled and addon.stage == stage:
				stage_addons.append(addon)
	
	stage_addons.sort_custom(Callable(PCamUtils, "_sort_by_priority"))
	for addon in stage_addons:
		addon.apply(self, delta)

func _apply_deadzones(target_position: Vector2) -> Vector2:
	if !follow_mode == FollowMode.SINGLE_TARGET:
		return target_position
	
	var drag_rect = _calculate_deadzone_rect()
	_margin_offset = target_position - global_position
	var rotated_offset = _margin_offset.rotated(-_current_rotation)
	
	var camera_movement = Vector2.ZERO
	
	if rotated_offset.x < drag_rect.position.x:
		camera_movement.x = rotated_offset.x - drag_rect.position.x
	elif rotated_offset.x > drag_rect.end.x:
		camera_movement.x = rotated_offset.x - drag_rect.end.x
	
	if rotated_offset.y < drag_rect.position.y:
		camera_movement.y = rotated_offset.y - drag_rect.position.y
	elif rotated_offset.y > drag_rect.end.y:
		camera_movement.y = rotated_offset.y - drag_rect.end.y
	
	camera_movement = global_position + camera_movement.rotated(_current_rotation)
	return Vector2(camera_movement.x if use_h_margins else target_position.x,
				   camera_movement.y if use_v_margins else target_position.y)

func _apply_transforms() -> void:
	global_position = _current_position + _current_offset
	global_rotation = _current_rotation
	_camera.zoom = Vector2(_current_zoom,_current_zoom) #(+ Vector2.ONE*2) #uncomment for debugging

func _calculate_deadzone_rect() -> Rect2:
	var size = _viewport_size / _current_zoom
	var half_width = size.x / 2
	var half_height = size.y / 2
	
	var margin_left = half_width * (1.0 - left_margin)
	var margin_top = half_height * (1.0 - top_margin)
	var margin_right = half_width * (1.0 - right_margin)
	var margin_bottom = half_height * (1.0 - bottom_margin)
	
	var rect = Rect2(
		-half_width + margin_left,
		-half_height + margin_top,
		size.x - margin_left - margin_right,
		size.y - margin_top - margin_bottom
	)
	return rect

func _calculate_limit_rect() -> Array:
	var limit_rect_pos = to_local(Vector2(left_limit, top_limit))
	var limit_rect_size = Vector2(right_limit - left_limit, bottom_limit - top_limit)
	return [Rect2(limit_rect_pos + Vector2.ONE, limit_rect_size - Vector2.ONE), 
			Rect2(to_global(limit_rect_pos) + (_viewport_size/_current_zoom)/2, limit_rect_size - _viewport_size/_current_zoom),
			Rect2(limit_rect_pos , limit_rect_size)]

func _calculate_target_position() -> Vector2:
	if _playing_cinematic:
		return global_position
	match follow_mode:
		FollowMode.SINGLE_TARGET:
			return _calculate_single_target_position()
		FollowMode.MULTI_TARGET:
			return _calculate_multi_target_position()
	return global_position

func _calculate_single_target_position() -> Vector2:
	if not _targets.is_empty():
		_velocity = _targets[0].velocity
		return _targets[0].get_target_position()
	return global_position

func _calculate_multi_target_position() -> Vector2:
	if _targets.is_empty():
		return global_position
	
	var total_influence = Vector2.ZERO
	var weighted_position = Vector2.ZERO
	var weighted_velocity = Vector2.ZERO
	for target in _targets:
		var target_influence = target.get_influence()
		total_influence += target_influence
		weighted_velocity += target.velocity * target_influence
		weighted_position += target.get_target_position() * target_influence
		
	if total_influence.length_squared() > 0:
		_velocity =  weighted_velocity / total_influence
	else:
		_velocity = Vector2.ZERO
	
	if total_influence.length_squared() > 0:
		return weighted_position / total_influence
	else:
		return global_position

func _calculate_target_rotation() -> float:
	if _targets.is_empty() or _playing_cinematic:
		return global_rotation
		
	if follow_mode == FollowMode.SINGLE_TARGET:
		return _update_accumulated_rotation(_targets[0].global_rotation) * _targets[0].rotation_influence
	
	var total_influence = 0.0
	var weighted_sin = 0.0
	var weighted_cos = 0.0
	
	for target in _targets:
		var target_influence = target.get_rotation_influence()
		total_influence += target_influence
		weighted_sin += sin(target.global_rotation) * target_influence
		weighted_cos += cos(target.global_rotation) * target_influence
	
	if total_influence > 0:
		var average_angle = atan2(weighted_sin, weighted_cos)
		return _update_accumulated_rotation(average_angle)
	else:
		return _accumulated_rotation

func _update_accumulated_rotation(target_angle: float) -> float:
	var angle_diff = PCamUtils._calculate_continuous_angle_diff(_previous_target_angle, target_angle)
	_accumulated_rotation += angle_diff
	_previous_target_angle = target_angle
	return _accumulated_rotation

func _calculate_target_zoom() -> float:
	if not auto_zoom or _targets.is_empty() or follow_mode == FollowMode.SINGLE_TARGET or _playing_cinematic:
		return zoom
	
	var target_rect = Rect2()
	
	# Initialize the rect with the first target
	var first_target = _targets[0]
	var first_pos = to_local(first_target.get_target_position())
	target_rect = Rect2(first_pos - Vector2(first_target.radius, first_target.radius),
						Vector2(first_target.radius * 2, first_target.radius * 2))
	
	# Expand the rect to include all other targets
	for i in range(1, _targets.size()):
		var target = _targets[i]
		var target_pos = to_local(target.get_target_position())
		var target_rect_local = Rect2(target_pos - Vector2(target.radius, target.radius),
									  Vector2(target.radius * 2, target.radius * 2))
		target_rect = target_rect.merge(target_rect_local)
	
	# Calculate the center of the target rect
	_target_position = to_global(target_rect.get_center())

	
	# Apply zoom margin
	target_rect = target_rect.grow(target_rect.size.length() * (zoom_margin) * 0.01)
	
	# Calculate the zoom required to fit the target_rect
	var x_zoom = _viewport_size.x / target_rect.size.x
	var y_zoom = _viewport_size.y / target_rect.size.y
	var new_zoom = min(x_zoom, y_zoom)
	
	# Clamp the zoom value
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	return new_zoom

func _draw_debug() -> void:
	var target_position = _target_position
	var screen_rect = Rect2(Vector2.ONE - _viewport_size/2, _viewport_size - Vector2.ONE)
	if Engine.is_editor_hint():
		draw_rect(screen_rect, debug_color[1],false,1)
	# Draw center cursor
	draw_arc(Vector2.ZERO, 10 * debug_draw_scaler, 0, TAU, 20, debug_color[1], 1)
	draw_arc(Vector2.ZERO, 13 * debug_draw_scaler, 0, TAU, 20, debug_color[1], 1)
	draw_line(- Vector2(10 * debug_draw_scaler, 0), + Vector2(10 * debug_draw_scaler, 0), debug_color[1], 1)
	draw_line(- Vector2(0, 10 * debug_draw_scaler), + Vector2(0, 10 * debug_draw_scaler), debug_color[1], 1)
		# Draw target position
	if !Engine.is_editor_hint():
		if _current_offset != Vector2.ZERO:
			draw_line(to_local(target_position), to_local(target_position + _current_offset), debug_color[1] - Color(0, 0, 0, 0.8), 1)
			draw_arc(to_local(target_position), 5 * debug_draw_scaler, 0, TAU, 20, debug_color[1] - Color(0, 0, 0, 0.8), 1)
		draw_line(Vector2.ZERO, to_local(target_position + _current_offset), debug_color[1], 1)
		draw_arc(to_local(target_position + _current_offset), 5 * debug_draw_scaler, 0, TAU, 20, debug_color[1], 1)
		
	
	# Draw drag margin rect
	if use_h_margins or use_v_margins:
		var drag_rect = _calculate_deadzone_rect()
		draw_rect(drag_rect, debug_color[0], false, 1)
	
	# Draw camera limits rect
	var limit_rect = _calculate_limit_rect()[0]
	draw_line(limit_rect.position, limit_rect.position + Vector2(limit_rect.size.x, 0).rotated(-global_rotation), debug_color[0])
	draw_line(limit_rect.position, limit_rect.position + Vector2(0, limit_rect.size.y).rotated(-global_rotation), debug_color[0])
	draw_line(limit_rect.position + Vector2(limit_rect.size.x, 0).rotated(-global_rotation), limit_rect.position + limit_rect.size.rotated(-global_rotation), debug_color[0])
	draw_line(limit_rect.position + Vector2(0, limit_rect.size.y).rotated(-global_rotation), limit_rect.position + limit_rect.size.rotated(-global_rotation), debug_color[0])

# Public methods
func reset_camera():
	global_position = _calculate_target_position()
	global_rotation = _calculate_target_rotation()
	_current_zoom = _calculate_target_zoom()
	_current_offset = offset
	_current_velocity = Vector2.ZERO
	_current_rotation_velocity = 0
	_current_offset_velocity = Vector2.ZERO
	_current_zoom_velocity = 0
	_apply_transforms()

func set_position(new_position: Vector2):
	_current_position = new_position
	_apply_transforms()

func set_rotation(new_rotation: float):
	_current_rotation = new_rotation
	_apply_transforms()

func set_zoom(new_zoom: float):
	_current_zoom = new_zoom
	_apply_transforms()

func add_addon(addon: PCamAddon) -> void:
	if addon and not addons.has(addon):
		addon.setup(self)
		addons.append(addon)

func remove_addon(addon: PCamAddon) -> void:
	if addon and not addons.has(addon):
		addon.exit(self)
		addons.erase(addon)

func _setup_addons():
	if addons.is_empty():
		return
	for addon in addons:
		if addon and addon is PCamAddon:
			addon.setup(self)
		
func get_addons() -> Array:
	return addons
	
func add_target(target) -> void:
	if not target.is_in_group("procam_targets"):
		target.add_to_group("procam_targets")
	if not _targets.has(target):
		_targets.append(target)

func clear_targets():
	_targets.clear()

func remove_target(target) -> void:
	if target.is_in_group("procam_targets"):
		target.remove_from_group("procam_targets")
	if _targets.has(target):
		_targets.erase(target)

func get_targets() -> Array:
	return _targets.duplicate()

func get_camera_bounds() -> Rect2:
	var size = _viewport_size / _current_zoom
	var top_left = global_position - size / 2
	return Rect2(top_left, size)

func is_point_visible(point: Vector2) -> bool:
	return get_camera_bounds().has_point(point)

func start_cinematic(cinematic_id) -> void:
	var id_string: String
	reset_camera()
	if typeof(cinematic_id) == TYPE_INT:
		id_string = str(cinematic_id)
	elif typeof(cinematic_id) == TYPE_STRING:
		id_string = cinematic_id
	else:
		push_error("Invalid cinematic_id type. Expected int or String.")
		return
	_active_cinematic_id = id_string
	_current_cinematic_index = 0
	_active_cinematics = _get_cinematics_by_id(id_string)
	if _active_cinematics.is_empty():
		print("No cinematics found with id: ", id_string)
		return
	_active_cinematics.sort_custom(Callable(PCamUtils, "_sort_by_priority"))
	_active_cinematics[0].start(self)
	_playing_cinematic = true
	emit_signal("cinematic_started", _active_cinematic_id)

func stop_cinematic() -> void:
	emit_signal("cinematic_stopped", _active_cinematic_id)
	_active_cinematic_id = ""
	_current_cinematic_index = 0
	for cinematic in _active_cinematics:
		cinematic.stop()
	_active_cinematics.clear()
	_playing_cinematic = false

func _get_cinematics_by_id(cinematic_id: String) -> Array:
	var filtered_cinematics = []
	for cinematic in _cinematics:
		if cinematic.cinematic_id == cinematic_id and cinematic.enabled and cinematic.priority >= 0:
			filtered_cinematics.append(cinematic)
	return filtered_cinematics

func _get_property_list():
	var properties = []
	
	# General settings
	properties.append({
		"name": "General",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		"name": "process_frame",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Idle, physics"
	})
	properties.append({
		"name": "follow_mode",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Single Target,Multi Target"
	})
	properties.append({
		"name": "drag_type",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Smooth Damp,Look Ahead,Auto Speed,Spring Damp"
	})
	
	# Movement settings
	properties.append({
		"name": "Movement",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "smooth_drag",
		"type": TYPE_BOOL
	})
	if get("smooth_drag"):
		properties.append({
			"name": "smooth_drag_speed",
			"type": TYPE_VECTOR2
		})
	properties.append({
		"name": "max_distance",
		"type": TYPE_VECTOR2
	})
	if get("drag_type") == DragType.LOOK_AHEAD:
		properties.append({
			"name": "prediction_time",
			"type": TYPE_VECTOR2
		})
	
	# Offset settings
	properties.append({
		"name": "Offset",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "offset",
		"type": TYPE_VECTOR2
	})
	properties.append({
		"name": "smooth_offset",
		"type": TYPE_BOOL
	})
	if get("smooth_offset"):
		properties.append({
			"name": "smooth_offset_speed",
			"type": TYPE_FLOAT
		})
	
	# Rotation settings
	properties.append({
		"name": "Rotation",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "allow_rotation",
		"type": TYPE_BOOL
	})
	if get("allow_rotation"):
		properties.append({
			"name": "smooth_rotation",
			"type": TYPE_BOOL
		})
		if get("smooth_rotation"):
			properties.append({
				"name": "smooth_rotation_speed",
				"type": TYPE_FLOAT
			})
	
	# Zoom settings
	properties.append({
		"name": "Zoom",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "zoom",
		"type": TYPE_FLOAT
	})
	properties.append({
		"name": "smooth_zoom",
		"type": TYPE_BOOL
	})
	if get("smooth_zoom"):
		properties.append({
			"name": "smooth_zoom_speed",
			"type": TYPE_FLOAT
		})
	properties.append({
		"name": "auto_zoom",
		"type": TYPE_BOOL
	})
	if get("auto_zoom"):
		properties.append({
			"name": "min_zoom",
			"type": TYPE_FLOAT
		})
		properties.append({
			"name": "max_zoom",
			"type": TYPE_FLOAT
		})
		properties.append({
			"name": "zoom_margin",
			"type": TYPE_FLOAT
		})
	
	# Limits settings
	properties.append({
		"name": "Limits",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "smooth_limit",
		"type": TYPE_BOOL
	})
	properties.append({
		"name": "left_limit",
		"type": TYPE_INT
	})
	properties.append({
		"name": "right_limit",
		"type": TYPE_INT
	})
	properties.append({
		"name": "top_limit",
		"type": TYPE_INT
	})
	properties.append({
		"name": "bottom_limit",
		"type": TYPE_INT
	})
	
	# Margins settings
	properties.append({
		"name": "Margins",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "use_h_margins",
		"type": TYPE_BOOL
	})
	properties.append({
		"name": "use_v_margins",
		"type": TYPE_BOOL
	})
	if get("use_h_margins"):
		properties.append({
			"name": "left_margin",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,0.01"
		})
		properties.append({
			"name": "right_margin",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,0.01"
		})
	if get("use_v_margins"):
		properties.append({
			"name": "top_margin",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,0.01"
		})
		properties.append({
			"name": "bottom_margin",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,0.01"
		})
	# optimization and debug
	properties.append({
		"name": "optimization & debug",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	properties.append({
		"name": "working_radius",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,10000,1.0"
	})
	properties.append({
		"name": "global_debug_draw",
		"type": TYPE_BOOL
	})
	# Addons
	properties.append({
		"name": "Addons",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	return properties

func set_follow_mode(value):
	follow_mode = value
	notify_property_list_changed()

func set_drag_type(value):
	drag_type = value
	notify_property_list_changed()

func set_smooth_drag(value):
	smooth_drag = value
	notify_property_list_changed()

func set_smooth_offset(value):
	smooth_offset = value
	notify_property_list_changed()

func set_allow_rotation(value):
	allow_rotation = value
	notify_property_list_changed()

func set_smooth_rotation(value):
	smooth_rotation = value
	notify_property_list_changed()

func set_smooth_zoom(value):
	smooth_zoom = value
	notify_property_list_changed()

func set_auto_zoom(value):
	auto_zoom = value
	notify_property_list_changed()

func set_use_h_margins(value):
	use_h_margins = value
	notify_property_list_changed()

func set_use_v_margins(value):
	use_v_margins = value
	notify_property_list_changed()

func set_global_debug_draw(value):
	global_debug_draw = value
	_global_debug_draw = value
	debug_draw = value
	emit_signal("debug_draw_changed", self)
	
func get_global_debug_draw() -> bool:
	return _global_debug_draw
