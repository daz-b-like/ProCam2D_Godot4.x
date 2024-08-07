@tool
extends Node2D

# Enums
enum ProcessMode {
	IDLE,
	PHYSICS,
	OFF
}
var process_frame: int = ProcessMode.OFF: set = set_tha_process_mode
@export var enabled: bool = true: set = set_enabled
@export var priority: int = 0: set = set_priority
var debug_draw: bool = false
var debug_color := [ Color("#563AFB"), Color("#7a90d8"), Color.YELLOW]
var _pm : int = 1
var debug_draw_scaler: float
# Signals

signal debug_draw_changed(node)
signal priority_changed(node)
signal position_changed(node)
signal tree_left(node)

func _ready() -> void:
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX-1
	debug_draw_scaler = get_viewport_rect().size.y/600
	setup_signals()
	_update_process_mode()

func _process(delta):
	if enabled and process_frame == ProcessMode.IDLE:
		_update(delta)
		queue_redraw()

func _physics_process(delta):
	if enabled and process_frame == ProcessMode.PHYSICS:
		_update(delta)
		queue_redraw()

func setup_signals():
	tree_exiting.connect(Callable(self, "on_tree_exited"))

func set_priority(value: int):
	if priority != value:
		priority = value
		emit_signal("priority_changed", value)

func set_enabled(value):
	enabled = value
	queue_redraw()
	update_configuration_warnings()

func _update(_delta: float) -> void:
	# Virtual method to be overridden by child classes
	pass

func change_debug(camera):
	debug_draw = camera.debug_draw
	queue_redraw()

func set_tha_process_mode(value):
	if process_frame != value:
		_pm = value
		process_frame = value
		_update_process_mode()

func _update_process_mode() -> void:
	set_process(process_frame == ProcessMode.IDLE)
	set_physics_process(process_frame == ProcessMode.PHYSICS)

func _draw() -> void:
	if not enabled:
		return
	if debug_draw or Engine.is_editor_hint():
		_draw_debug()

func _draw_debug() -> void:
	# Virtual method to be overridden by child classes for debug drawing
	pass

func on_tree_exited():
	emit_signal("tree_left", self)
