#MIT License

#Copyright (c) 2024 Daz B. Like

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
@tool

extends Node2D

enum ProcType {
	PROC,
	PHYS_PROC
}

enum SmoothType {
	PRED,
	SPRING_DAMP,
	ADAPTIVE,
	SMOOTH_DAMP,
	SCREENS
}

const MIN_VELOCITY_THRESHOLD: float = 0.0001
const MIN_DELTA_THRESHOLD: float = 0.0001

# Properties
# TODO: implement more signals
signal target_changed(new_target, old_target)
signal zoom_level_changed(new_level, old_level)
signal rotation_enabled()
signal rotation_disabled()
signal offset_changed(new_offset, old_offset)
signal screen_shake_started(type)
signal screen_shake_finished(type)
signal process_mode_changed(new_mode)

var _margin_offset_points := {
	"point1": Vector2.ZERO,
	"point2": Vector2.ZERO,
	"offset": Vector2.ZERO
}
var _tracking_multiple_objects: bool = false
var _framing_offset := Vector2.ZERO
var _target_node: NodePath = "": set = _set_target_node
var _tgt_pos: Vector2 = Vector2.ZERO
var _tgt_rot: float = 0.0
var _target_radius: float = 100
var _tgt_zoom: = Vector2.ZERO
var _last_tgt_pos: = Vector2.ZERO
var _last_cur_pos := Vector2.ZERO
var _last_velocity: = Vector2()
var _current_velocity_x: float = 0.0
var _current_velocity_y: float = 0.0
var _time_elapsed: = 0.0
var _target: Node2D
var _camera: Camera2D
var _offset: Vector2 = Vector2.ZERO: set = _set_offset
var _target_offset: Vector2 = Vector2.ZERO
var _cur_offset: Vector2
var _cur_pos: Vector2
var _cur_zoom: Vector2 = Vector2.ONE
var _cur_rot: float
@onready var _vp = get_viewport()
@onready var _vp_size = get_viewport_rect().size

var _offset_smoothly: bool = true
var _offset_speed: float = 1.0

var _drag_smoothly: bool = true
var _drag_speed: Vector2 = Vector2(2.0, 2.0)
var _prediction_time: Vector2 = Vector2(5, 5)
var _drag_type: int = SmoothType.PRED: set = _set_drag_smooth_type

var _rotate: bool = false: set = _set_rotate
var _rotate_smoothly: bool = true
var _rotation_speed: float = 5.0

var _zoom_level: float = 1.0: set = _set_zoom_level
var _zoom_smoothly: bool = true
var _zoom_speed: float = 5.0
var _limit_rect: Rect2 = Rect2()
var _limit_smoothly: bool = false
var _left_limit: int = -100000
var _right_limit: int = 100000
var _top_limit: int = -100000
var _bottom_limit: int = 100000
var _process_mode: int = ProcType.PHYS_PROC: set = _set_process_mode

var _screen_center: Vector2: get = _get_screen_center, set = _set_screen_center
var _screen_rect: Rect2 = Rect2()
var _margin_rect: Rect2 = Rect2()
#SmoothType.SCREENS
var _target_screen_position: Vector2
var _is_transitioning: bool = false
var _last_update_time: float = 0.0
var _update_interval: float = 0.2

var _enable_v_margins: bool = false
var _enable_h_margins: bool = false
var _drag_margin_right: float = 0.2
var _drag_margin_left: float = 0.2
var _drag_margin_top: float = 0.2
var _drag_margin_bottom: float = 0.2
var _screen_shake_data := {
	"is_shaking": false,
	"offset": Vector2.ZERO,
	"zoom_offset": Vector2.ZERO,
	"rotation_offset": 0.0,
	"active_shakes": []
}
var _show_bounds: bool = false
var _draw_bounds: bool = true

func _enter_tree() -> void:
	add_to_group("procam")

func _ready() -> void:
	_setup_target_properties()
	if not Engine.is_editor_hint() and _target:
		_setup_camera()
		_update_camera()

func _setup_camera() -> void:
	z_index = 2000
	_camera = Camera2D.new()
	_camera.ignore_rotation = false
	var grandpa = get_parent().get_parent()
	await grandpa.ready
	grandpa.add_child(_camera)
	_camera.make_current()

func _setup_target_properties():
	if not _target_node:
		return
	else:
		_target = get_node(_target_node)
	if _target and not _target.is_class("Camera2D"):
		_last_tgt_pos = _target.global_position
		_last_cur_pos = _target.global_position
		_cur_pos = _target.global_position
		_cur_zoom = Vector2(_zoom_level, _zoom_level)
		_cur_rot = _target.rotation if _rotate else 0.0
		_cur_offset = _offset
		_cur_pos.x = clamp(_cur_pos.x, _left_limit + _vp_size.x / 2, _right_limit - _vp_size.x / 2)
		_cur_pos.y = clamp(_cur_pos.y, _top_limit + _vp_size.y / 2, _bottom_limit - _vp_size.y / 2)
	else:
		_target = null

func _physics_process(delta: float) -> void:
	if _process_mode == ProcType.PHYS_PROC:
		_update_screen_and_margin_rects()
		_main_loop(delta)

func _process(delta: float) -> void:
	if _process_mode == ProcType.PROC:
		_update_screen_and_margin_rects()
		_main_loop(delta)

func _main_loop(delta: float) -> void:
	if Engine.is_editor_hint() or !_target:
		return
	_update_target()


	var velocity: Vector2 = (_tgt_pos - _last_tgt_pos) / max(delta, MIN_DELTA_THRESHOLD)
	if velocity.length() < MIN_VELOCITY_THRESHOLD:
		velocity = Vector2.ZERO  # Ensuring no unintended movement when target is still

	var acceleration: Vector2 = (velocity - _last_velocity) / max(delta, MIN_DELTA_THRESHOLD)
	if acceleration.length() < MIN_VELOCITY_THRESHOLD:
		acceleration = Vector2.ZERO  # Ensuring no unintended movement when target is still

	_last_tgt_pos = _tgt_pos
	_last_cur_pos = _cur_pos
	_last_velocity = velocity

	# Smooth offset
	var offset_duration: float = (1.0 / _offset_speed if _offset_speed != 0.0 else 1 / 0.1)
	if _drag_type != SmoothType.SCREENS:
		if _offset_smoothly:
			_cur_offset = _cur_offset.lerp(_target_offset, _exp_smoothing(offset_duration, delta))
		else:
			_cur_offset = _target_offset
	else: _cur_offset = Vector2.ZERO
		
		
	var predicted_target_position:Vector2 = Vector2.ZERO
	predicted_target_position.x =  _predict_future_position(_tgt_pos.x, velocity.x, (_prediction_time.x/10 if _prediction_time.x!=0 else 0.01))
	predicted_target_position.y =  _predict_future_position(_tgt_pos.y, velocity.y, (_prediction_time.y/10 if _prediction_time.y!=0 else 0.01))
	# Smooth position
	var scroll_easing_duration_x: float = (1.0 / _drag_speed.x if _drag_speed.x != 0 else 1 / 0.1)
	var scroll_easing_duration_y: float = (1.0 / _drag_speed.y if _drag_speed.y != 0 else 1 / 0.1)

	if _drag_type != SmoothType.SCREENS:
		if _drag_smoothly:
			match _drag_type:
				SmoothType.PRED:
					var result_x = _smooth_damp(_cur_pos.x, predicted_target_position.x, _current_velocity_x, scroll_easing_duration_x, INF, delta)
					_cur_pos.x = result_x["new_position"]
					_current_velocity_x = result_x["new_velocity"]

					var result_y = _smooth_damp(_cur_pos.y, predicted_target_position.y, _current_velocity_y, scroll_easing_duration_y, INF, delta)
					_cur_pos.y = result_y["new_position"]
					_current_velocity_y = result_y["new_velocity"]
				SmoothType.SPRING_DAMP:
					var result_x = _spring_damp(_cur_pos.x, _tgt_pos.x, _current_velocity_x, 20, _drag_speed.x, delta)
					_cur_pos.x = result_x["new_position"]
					_current_velocity_x = result_x["new_velocity"]

					var result_y = _spring_damp(_cur_pos.y, _tgt_pos.y, _current_velocity_y, 20, _drag_speed.y, delta)
					_cur_pos.y = result_y["new_position"]
					_current_velocity_y = result_y["new_velocity"]
				SmoothType.ADAPTIVE:
					var result_x = _adaptive_smooth_damp(_cur_pos.x, _tgt_pos.x, _current_velocity_x, INF, delta)
					_cur_pos.x = result_x["new_position"]
					_current_velocity_x = result_x["new_velocity"]

					var result_y = _adaptive_smooth_damp(_cur_pos.y, _tgt_pos.y, _current_velocity_y, INF, delta)
					_cur_pos.y = result_y["new_position"]
					_current_velocity_y = result_y["new_velocity"]
				SmoothType.SMOOTH_DAMP:
					var result_x = _smooth_damp(_cur_pos.x, _tgt_pos.x, _current_velocity_x, scroll_easing_duration_x, INF, delta)
					_cur_pos.x = result_x["new_position"]
					_current_velocity_x = result_x["new_velocity"]

					var result_y = _smooth_damp(_cur_pos.y, _tgt_pos.y, _current_velocity_y, scroll_easing_duration_y, INF, delta)
					_cur_pos.y = result_y["new_position"]
					_current_velocity_y = result_y["new_velocity"]
		else:
			_cur_pos = _tgt_pos
	else:
		if not _tracking_multiple_objects:
			if _drag_smoothly:
				var screen_size = get_viewport_rect().size * _zoom_level

				# Update target position based on elapsed time
				if _time_elapsed - _last_update_time >= _update_interval:
					_last_update_time = _time_elapsed

					if _tgt_pos.x < _cur_pos.x - screen_size.x / 2:
						_target_screen_position.x -= screen_size.x
					elif _tgt_pos.x > _cur_pos.x + screen_size.x / 2:
						_target_screen_position.x += screen_size.x

					if _tgt_pos.y < _cur_pos.y - screen_size.y / 2:
						_target_screen_position.y -= screen_size.y
					elif _tgt_pos.y > _cur_pos.y + screen_size.y / 2:
						_target_screen_position.y += screen_size.y

					if _target_screen_position != _cur_pos:
						_is_transitioning = true

				if _is_transitioning:
					var result_x = _smooth_damp(_cur_pos.x, _target_screen_position.x, _current_velocity_x, scroll_easing_duration_x, INF, delta)
					_cur_pos.x = result_x["new_position"]
					_current_velocity_x = result_x["new_velocity"]

					var result_y = _smooth_damp(_cur_pos.y, _target_screen_position.y, _current_velocity_y, scroll_easing_duration_y, INF, delta)
					_cur_pos.y = result_y["new_position"]
					_current_velocity_y = result_y["new_velocity"]

					if abs(_cur_pos.x - _target_screen_position.x) < 1.0 and abs(_cur_pos.y - _target_screen_position.y) < 1.0:
						_cur_pos = _target_screen_position
						_is_transitioning = false
				
			else:
				
				var screen_size = get_viewport_rect().size
				var new_x = _cur_pos.x
				var new_y = _cur_pos.y

				if _tgt_pos.x < _cur_pos.x - screen_size.x / 2:
					new_x -= screen_size.x
				elif _tgt_pos.x > _cur_pos.x + screen_size.x / 2:
					new_x += screen_size.x

				if _tgt_pos.y < _cur_pos.y - screen_size.y / 2:
					new_y -= screen_size.y
				elif _tgt_pos.y > _cur_pos.y + screen_size.y / 2:
					new_y += screen_size.y

				_cur_pos.x = new_x
				_cur_pos.y = new_y
		else :
			var result_x = _smooth_damp(_cur_pos.x, _tgt_pos.x, _current_velocity_x, scroll_easing_duration_x, INF, delta)
			_cur_pos.x = result_x["new_position"]
			_current_velocity_x = result_x["new_velocity"]

			var result_y = _smooth_damp(_cur_pos.y, _tgt_pos.y, _current_velocity_y, scroll_easing_duration_y, INF, delta)
			_cur_pos.y = result_y["new_position"]
			_current_velocity_y = result_y["new_velocity"]

	# Clamp positions within limits
	if not _limit_smoothly and not _tracking_multiple_objects:
		_cur_pos.x = clamp(_cur_pos.x, _left_limit + _vp_size.x / 2, _right_limit - _vp_size.x / 2)
		_cur_pos.y = clamp(_cur_pos.y, _top_limit + _vp_size.y / 2, _bottom_limit - _vp_size.y / 2)

	# Smooth rotation
	var rotation_easing_duration = 1.0 / _rotation_speed if _rotation_speed != 0 else 1 / 0.1
	if _rotate_smoothly and _rotate:
		_cur_rot = lerp_angle(_cur_rot, _tgt_rot, _exp_smoothing(rotation_easing_duration, delta))
	else:
		_cur_rot = _tgt_rot if _rotate else _cur_rot

	# Smooth zoom
	var zoom_easing_duration = 1.0 / _zoom_speed if _zoom_speed != 0 else 1 / 0.1
	if _zoom_smoothly:
		_cur_zoom = _cur_zoom.lerp(_tgt_zoom, _exp_smoothing(zoom_easing_duration, delta))
	else:
		_cur_zoom = _tgt_zoom

	_time_elapsed += delta
	_update_camera()

func _update_camera():
	if Engine.is_editor_hint() or !_target:
		return
	var final_pos: Vector2 =  _cur_pos + (_screen_shake_data.offset if _screen_shake_data.is_shaking else Vector2.ZERO) + _drag_margins_refactoring() #if !tracking_multiple_objects else Vector2.ZERO
	var final_rot: float = _cur_rot + (_screen_shake_data.rotation_offset if _screen_shake_data.is_shaking else 0)
	var final_zoom: Vector2 = (_cur_zoom + (_screen_shake_data.zoom_offset if _screen_shake_data.is_shaking else Vector2.ZERO))
	var final_offset: Vector2 = _cur_offset.rotated(_cur_rot)
	_camera.offset = final_offset
	if not _rotate:
		_camera.limit_top = _top_limit + final_offset.y
		_camera.limit_bottom = _bottom_limit - final_offset.y
		_camera.limit_left = _left_limit + final_offset.x
		_camera.limit_right = _right_limit - final_offset.x
	else:
		_camera.limit_top = -1000000000
		_camera.limit_bottom = 1000000000
		_camera.limit_left = -1000000000
		_camera.limit_right = 1000000000
	_camera.process_mode = _process_mode
	_camera.global_position = final_pos
	_camera.global_rotation = final_rot
	global_position = final_pos + final_offset
	global_rotation = final_rot
	_camera.zoom = Vector2.ONE / final_zoom
	_track_objects()
	_update_shakes()

func _update_target():
	if _target:
		if !_tracking_multiple_objects:
			_tgt_zoom = Vector2(_zoom_level, _zoom_level)
			_tgt_pos.x = _target.global_position.x
			_tgt_pos.y = _target.global_position.y
		_tgt_rot = _target.global_rotation
		#smooth limiting
		if _limit_smoothly and not _rotate:
			_tgt_pos.x =  clamp(_tgt_pos.x, _left_limit + _vp_size.x/2, _right_limit - _vp_size.x/2)
			_tgt_pos.y =  clamp(_tgt_pos.y, _top_limit + _vp_size.y/2, _bottom_limit - _vp_size.y/2)

func _update_screen_and_margin_rects():
	if not (Engine.is_editor_hint() and _draw_bounds or !Engine.is_editor_hint() and _show_bounds):
		return
	var window_size = get_viewport_rect().size
	_vp_size = window_size * _cur_zoom

	var margin_left = position.x - _vp_size.x / 2 * _drag_margin_left
	var margin_top = position.y - _vp_size.y / 2 * _drag_margin_top
	var margin_right = position.x + _vp_size.x / 2 * _drag_margin_right
	var margin_bottom = position.y + _vp_size.y / 2 * _drag_margin_bottom
	_screen_rect = Rect2(-_vp_size / 2, _vp_size)
	_limit_rect = Rect2(_left_limit - global_position.x, _top_limit - global_position.y, _right_limit - _left_limit,_bottom_limit - _top_limit)
	_margin_rect = Rect2(margin_left - position.x - _cur_offset.x, margin_top - position.y - _cur_offset.y, margin_right - margin_left, margin_bottom - margin_top)
	queue_redraw()

func _drag_margins_refactoring() -> Vector2:
	var margin_left: float = _cur_pos.x - _vp_size.x / 2 * _drag_margin_right
	var margin_top: float = _cur_pos.y - _vp_size.y / 2 * _drag_margin_bottom
	var margin_right: float = _cur_pos.x + _vp_size.x / 2 * _drag_margin_left
	var margin_bottom: float = _cur_pos.y + _vp_size.y / 2 * _drag_margin_top

	_margin_offset_points.point1 = Vector2(margin_right - _cur_pos.x, margin_bottom - _cur_pos.y)
	_margin_offset_points.point2 = Vector2(margin_left - _cur_pos.x, margin_top - _cur_pos.y)
	var margin_offset_calculation = -(_cur_pos - _last_cur_pos).rotated(-_cur_rot)

	# Horizontal margin
	if _enable_h_margins:
		if _margin_offset_points.point1.x + 5 > _margin_offset_points.offset.x + margin_offset_calculation.x:
			_margin_offset_points.offset.x += margin_offset_calculation.x
		if _margin_offset_points.point2.x - 5 > _margin_offset_points.offset.x + margin_offset_calculation.x:
			_margin_offset_points.offset.x -= margin_offset_calculation.x
	else:
		_margin_offset_points.offset.x = lerp(_margin_offset_points.offset.x, 0.0, 0.1)
	
	# Vertical margin
	if _enable_v_margins:
		if _margin_offset_points.point1.y + 5 > _margin_offset_points.offset.y + margin_offset_calculation.y:
			_margin_offset_points.offset.y += margin_offset_calculation.y
		if _margin_offset_points.point2.y - 5 > _margin_offset_points.offset.y + margin_offset_calculation.y:
			_margin_offset_points.offset.y -= margin_offset_calculation.y
	else:
		_margin_offset_points.offset.y = lerp(_margin_offset_points.offset.y, 0.0, 0.1)

	_margin_offset_points.offset.x = clamp(_margin_offset_points.offset.x, _margin_offset_points.point2.x, _margin_offset_points.point1.x)
	_margin_offset_points.offset.y = clamp(_margin_offset_points.offset.y, _margin_offset_points.point2.y, _margin_offset_points.point1.y)
	
	return _margin_offset_points.offset.rotated(_cur_rot) if !_tracking_multiple_objects and _drag_type != SmoothType.SCREENS else Vector2.ZERO

func _track_objects() -> void:
	if !_tracking_multiple_objects:
		return
	var window_size = get_viewport_rect().size
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF

	# Iterate through all tracking points to determine the bounding box
	for point in get_tree().get_nodes_in_group("pptrackpoints"):
		var pos = point.global_position
		var radius = point._radius
		if not _rotate:
			pos.x = clamp(pos.x,_left_limit + radius, _right_limit - radius)
			pos.y = clamp(pos.y,_top_limit + radius, _bottom_limit - radius)
		if point._enabled:
			# Expand the AABB by the radius in all directions
			min_x = min(min_x, pos.x - radius)
			max_x = max(max_x, pos.x + radius)
			min_y = min(min_y, pos.y - radius)
			max_y = max(max_y, pos.y + radius)
	# Include the target's position and radius in the AABB calculation
	var target_pos = _target.global_position
	if not _rotate:
		target_pos.x = clamp(target_pos.x,_left_limit + _target_radius, _right_limit - _target_radius)
		target_pos.y = clamp(target_pos.y,_top_limit + _target_radius, _bottom_limit - _target_radius)
	min_x = min(min_x, target_pos.x - _target_radius)
	max_x = max(max_x, target_pos.x + _target_radius)
	min_y = min(min_y, target_pos.y - _target_radius)
	max_y = max(max_y, target_pos.y + _target_radius)

	# Create the bounding box from the min and max coordinates
	var rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	rect.expand(_target.global_position)
	var aspect_ratio: float = window_size.aspect()
	var width: float = rect.size.x
	var height: float = rect.size.y

	if height * aspect_ratio > width:
		width = height * aspect_ratio
	else:
		height = width / aspect_ratio

	# Calculate the center of the bounding box
	_tgt_pos = rect.get_center()

	# Calculate the corners of the original bounding box
	var corners = [
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)
	]

	# Rotate the corners around the center
	var rotated_corners = []
	for corner in corners:
		var local_corner = corner - _tgt_pos
		var rotated_corner = local_corner.rotated(_cur_rot) + _tgt_pos
		rotated_corners.append(rotated_corner)

	# Calculate the axis-aligned bounding box (AABB) of the rotated rectangle
	var aabb_min_x = rotated_corners[0].x
	var aabb_max_x = rotated_corners[0].x
	var aabb_min_y = rotated_corners[0].y
	var aabb_max_y = rotated_corners[0].y

	for corner in rotated_corners:
		aabb_min_x = min(aabb_min_x, corner.x)
		aabb_max_x = max(aabb_max_x, corner.x)
		aabb_min_y = min(aabb_min_y, corner.y)
		aabb_max_y = max(aabb_max_y, corner.y)

	var aabb_width = aabb_max_x - aabb_min_x
	var aabb_height = aabb_max_y - aabb_min_y

	if aabb_height * aspect_ratio > aabb_width:
		aabb_width = aabb_height * aspect_ratio
	else:
		aabb_height = aabb_width / aspect_ratio

	var aabb_size = Vector2(aabb_width, aabb_height)

	# Adjust final zoom level calculation to avoid excessive unzooming
	var target_length = max(aabb_size.x, aabb_size.y)
	var final_zoom = ((target_length * max(_zoom_level,1)) / max(window_size.x, window_size.y)) / max(_zoom_level,1)
	if final_zoom > _zoom_level:
		_tgt_zoom = Vector2(final_zoom, final_zoom)
	else:
		_tgt_zoom = Vector2(_zoom_level, _zoom_level)


func _predict_future_position(current_position: float, velocity: float, prediction_time: float) -> float:
	return current_position + velocity * prediction_time

func _exp_smoothing(duration: float, delta: float) -> float:
	return 1.0 - exp(-delta / duration)

func _spring_damp(current: float, target: float, current_velocity: float, spring_constant: float, damping_ratio: float, delta: float) -> Dictionary:
	# Calculate the difference between the current position and the target
	var difference = target - current
	
	# Calculate the spring force
	var spring_force = difference * spring_constant
	
	# Calculate the damping force
	var damping_force = (-current_velocity / damping_ratio) * 10
	
	# Calculate the total force acting on the object
	var force = spring_force + damping_force
	
	# Update the velocity based on the force and time delta
	current_velocity += force * delta
	
	# Update the position based on the new velocity and time delta
	var new_position = current + current_velocity * delta
	
	return {"new_position": new_position, "new_velocity": current_velocity}

func _adaptive_smooth_damp(current: float, target: float, current_velocity: float, max_speed: float, delta: float) -> Dictionary:
	# Calculate the current speed as the absolute value of current velocity
	var speed = abs(current_velocity)
	var base_smooth_time: float = 0.3
	# Adapt the smooth_time based on the speed, decreasing as the object slows down
	var smooth_time = max(base_smooth_time * (1.0 - speed / 100.0), base_smooth_time)
	
	# Ensure smooth_time has a minimum value to avoid being too small
	smooth_time = max(0.0001, smooth_time)
	
	# Calculate the omega
	var omega = 2.0 / smooth_time
	
	# Calculate x
	var x = omega * delta
	
	# Calculate exponential decay
	var texp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	# Calculate change value
	var change = current - target
	var original_to = target
	
	# Clamp change to maximum speed
	var max_change = max_speed * smooth_time
	change = clamp(change, -max_change, max_change)
	
	# Calculate target
	target = current - change
	
	# Calculate temporary
	var temp = (current_velocity + omega * change) * delta
	
	# Calculate new velocity
	current_velocity = (current_velocity - omega * temp) * texp
	
	# Calculate new position
	var new_position = target + (change + temp) * texp
	
	# Ensure new position does not exceed target if necessary
	if (original_to - current > 0.0) == (new_position > original_to):
		new_position = original_to
		current_velocity = (new_position - original_to) / delta
	
	return {"new_position": new_position, "new_velocity": current_velocity}

func clamp_cam_pos():
	pass

func _smooth_damp(current: float, target: float, current_velocity: float, smooth_time: float, max_speed: float, delta: float) -> Dictionary:
	# Ensure smooth_time is non-zero
	smooth_time = max(0.0001, smooth_time)
	
	# Calculate the omega
	var omega = 2.0 / smooth_time
	
	# Calculate x
	var x = omega * delta
	
	# Calculate exponential decay
	var texp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	# Calculate change value
	var change = current - target
	var original_to = target
	
	# Clamp change to maximum speed
	var max_change = max_speed * smooth_time
	change = clamp(change, -max_change, max_change)
	
	# Calculate target
	target = current - change
	
	# Calculate temporary
	var temp = (current_velocity + omega * change) * delta
	
	# Calculate new velocity
	current_velocity = (current_velocity - omega * temp) * texp
	
	# Calculate new position
	var new_position = target + (change + temp) * texp
	
	return {"new_position": new_position, "new_velocity": current_velocity}

func _start_shake(types: Array, duration: float, magnitude: float, speed: float) -> void:
	var shake = preload("res://addons/ProCam2D/scripts/PCSShakes.gd").new()
	shake.initialize(self, types, duration, magnitude, speed, _process_mode)
	add_child(shake)
	_screen_shake_data["is_shaking"] = true

func _update_shakes():
	if _screen_shake_data["is_shaking"]:
		if not _screen_shake_data["active_shakes"].is_empty():
			var total_offset: Vector2
			var total_zoom: Vector2
			var total_rotation: float
			for shake in _screen_shake_data["active_shakes"]:
				total_offset += shake.get_offset()
				total_zoom += shake.get_zoom_offset()
				total_rotation += shake.get_rotation_offset()
			_screen_shake_data["offset"] = total_offset
			_screen_shake_data["zoom_offset"] = total_zoom
			_screen_shake_data["rotation_offset"] = total_rotation
		else:
			_screen_shake_data["is_shaking"] = false
			_screen_shake_data["offset"] = Vector2.ZERO
			_screen_shake_data["zoom_offset"] = Vector2.ZERO
			_screen_shake_data["rotation_offset"] = 0.0

func _set_target_node(value):
	_target_node = value
	update_configuration_warnings()
	
func _set_zoom_level(value):
	emit_signal("zoom_level_changed", _zoom_level, value)
	_zoom_level = value

func _set_offset(value):
	_offset = value
	_target_offset = _offset
	emit_signal("offset_changed",value,_offset)
	
func _set_process_mode(value):
	_process_mode = value
	emit_signal("process_mode_changed",value,_process_mode)

func _set_drag_smooth_type(value):
	_drag_type = value
	notify_property_list_changed()
	
func _set_rotate(value:bool):
	_rotate = value
	if value == true:
		emit_signal("rotation_enabled")
	else: emit_signal("rotation_disabled")

func _change_target_to(new_target: Node2D) -> void:
	var old_target = _target_node
	_target = new_target
	emit_signal("target_changed", _target, old_target)

func _get_screen_center() -> Vector2:
	return _camera.get_screen_center_position()
	
func _set_screen_center(_value):
	printerr("You can't directly change the screen center. Use current_position")

func _draw():
	if Engine.is_editor_hint() and _draw_bounds or not Engine.is_editor_hint() and _show_bounds and _target:
		draw_rect(_screen_rect, Color.WHITE, false, 1.5)
		draw_rect(_limit_rect,Color.RED, false,1.5)
		# Draw margin bounds
		if _enable_h_margins or _enable_v_margins:
			draw_rect(_margin_rect, Color.YELLOW, false, 1.5)

func _get_configuration_warning():
	if _target_node:
		return ""
	else:
		return "Target node not set"

func _get_property_list():
	var props = []

	# Target Node
	props.append({
		"name": "ProCam2D Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	props.append({
		"name": "Target",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})

	props.append({
		"name": "_target_node",
		"type": TYPE_NODE_PATH
	})
	props.append({
		"name": "_target_radius",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.01,1000.0,0.1"
	})
	props.append({
		"name": "_process_mode",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Process,Physics Process"
	})
	#Offsetting
	props.append({
		"name": "Offsetting",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_offset",
		"type": TYPE_VECTOR2
	})
	props.append({
		"name": "_offset_smoothly",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_offset_speed",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,100.0"
	})

	# drag Smoothing
	props.append({
		"name": "Dragging",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_drag_smoothly",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_drag_speed",
		"type": TYPE_VECTOR2,
	})
	props.append({
		"name": "_drag_type",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Predictive,Spring damp,Adaptive,Smooth damp, Screens"
	})
	if _drag_type == SmoothType.PRED:
		props.append({
			"name": "_prediction_time",
			"type": TYPE_VECTOR2,
	})
	# Rotation Smoothing
	props.append({
		"name": "Rotation",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_rotate",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_rotation_speed",
		"type": TYPE_FLOAT
	})
	props.append({
		"name": "_rotate_smoothly",
		"type": TYPE_BOOL
	})
	# Zoom Smoothing
	props.append({
		"name": "Zooming",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_zoom_level",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.01,100,0.1"
	})
	props.append({
		"name": "_zoom_smoothly",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_zoom_speed",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,100"
	})
	# Limits
	props.append({
		"name": "Drag limits",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_limit_smoothly",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_left_limit",
		"type": TYPE_INT,
	})
	props.append({
		"name": "_right_limit",
		"type": TYPE_INT,
	})
	props.append({
		"name": "_top_limit",
		"type": TYPE_INT,
	})
	props.append({
		"name": "_bottom_limit",
		"type": TYPE_INT,
	})
	props.append({
		"name": "Drag margins",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_enable_h_margins",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_enable_v_margins",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_drag_margin_right",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,1,0.01"
	})
	props.append({
		"name": "_drag_margin_left",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,1.0,0.01"
	})
	props.append({
		"name": "_drag_margin_top",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,1,0.01"
	})
	props.append({
		"name": "_drag_margin_bottom",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,1,0.01"
	})
	props.append({
		"name": "Editor",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_draw_bounds",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "Runtime",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	props.append({
		"name": "_show_bounds",
		"type": TYPE_BOOL
	})
	return props
