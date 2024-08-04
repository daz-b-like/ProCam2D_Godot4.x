@tool
extends "b.gd"

const GROUP_NAME := "procam_cinematics"

@export var cinematic_id := ""
@export var hold_time := 1.0
@export var target_zoom := 1.0
@export var drag_speed := Vector2(5, 5)
@export var rotation_speed := 5.0
@export var zoom_speed := 5.0

var _original_values := {}
var _timer: Timer
var _active := false
var _camera

func _init() -> void:
	add_to_group(GROUP_NAME)

func _ready() -> void:
	super._ready()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(Callable(self, "_on_hold_time_complete"))
	add_child(_timer)

func start(camera) -> void:
	_camera = camera
	_active = true
	_timer.start(hold_time)
	_store_and_apply_values(camera)

func stop() -> void:
	_active = false
	_timer.stop()

func is_complete() -> bool:
	return not _active

func apply_influence(camera) -> Vector2:
	if _active:
		camera._target_rotation = global_rotation
		camera._target_zoom = target_zoom
		return global_position
		queue_redraw()
	return camera.global_position

func _on_hold_time_complete() -> void:
	_active = false
	_restore_original_values()

func _store_and_apply_values(camera) -> void:
	_original_values = {
		"drag_speed": camera.smooth_drag_speed,
		"rotation_speed": camera.smooth_rotation_speed,
		"zoom_speed": camera.smooth_zoom_speed,
		"drag_type": camera.drag_type
	}
	camera.smooth_drag_speed = drag_speed
	camera.smooth_rotation_speed = rotation_speed
	camera.smooth_zoom_speed = zoom_speed
	camera._target_rotation = global_rotation
	camera._target_zoom = target_zoom
	camera.drag_type = 0

func _restore_original_values() -> void:
	_camera.drag_type = _original_values.drag_type
	_camera.smooth_drag_speed = _original_values.drag_speed
	_camera.smooth_rotation_speed = _original_values.rotation_speed
	_camera.smooth_zoom_speed = _original_values.zoom_speed

func _draw_debug() -> void:
	# Draw main circle
	draw_circle(Vector2.ZERO, 30 * debug_draw_scaler, debug_color[1])
	
	# Draw hold time indicator (decreasing arc)
	var time_left_ratio := 1.0
	if _active and _timer:
		time_left_ratio = _timer.time_left / hold_time
	var hold_time_angle := time_left_ratio * TAU
	draw_arc(Vector2.ZERO, 35 * debug_draw_scaler, -TAU/4, hold_time_angle - TAU/4, 32, debug_color[0], 3)
