@tool
#MIT License

#Copyright (c) 2024 dazlike

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
extends Node2D

@export var parallax_z_index: float = 0.0
@export var parallax_fov: float = 70.0
@export var enable_auto_scaling: bool = true  # Checkbox to enable auto scaling

@onready var camera = get_tree().get_first_node_in_group("procam")
var initial_position: Vector2
var initial_camera_position: Vector2
var initial_scale: float

func _enter_tree() -> void:
	add_to_group("ppparallax")

func _ready() -> void:
	if not camera:
		camera = null
		printerr("ProCam2D node not found in tree!")
		return

	
	initial_position = global_position
	initial_camera_position = camera.global_position
	initial_scale = scale.x

func _process(_delta: float) -> void:
	if not camera or not camera._target:
		return
	if camera._process_mode == 1:
		return
	update_parallax_and_scale()
	
func _physics_process(_delta: float) -> void:
	if get_tree().get_first_node_in_group("procam"):
		if not camera:
			camera = get_tree().get_first_node_in_group("procam")
		update_configuration_warnings()
	else: camera = null
	if not camera or not camera._target:
		return
	if camera._process_mode == 0:
		return
	update_parallax_and_scale()

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_TRANSFORM_CHANGED:
		update_parallax_and_scale()

func update_parallax_and_scale() -> void:
	if not camera:
		return
	
	global_position = apply_parallax_effect(initial_position, parallax_z_index, parallax_fov, initial_camera_position, camera.global_position)
	
	if enable_auto_scaling:
		var new_scale = initial_scale * apply_perspective_scale(parallax_z_index, parallax_fov)
		scale = Vector2(new_scale, new_scale)

func apply_parallax_effect(position: Vector2, z_index: float, fov: float, initial_origin: Vector2, current_origin: Vector2) -> Vector2:
	if z_index == 0:
		return position
	
	# Convert FOV to radians
	var fov_rad = deg_to_rad(fov)
	
	# Calculate the perspective scale
	var perspective_scale = apply_perspective_scale(z_index, fov_rad)
	
	# Calculate the change in camera position
	var origin_offset = current_origin - initial_origin
	
	# Apply the parallax effect based on the camera movement
	var parallaxed_position = position + (origin_offset * perspective_scale)
	
	return parallaxed_position

func apply_perspective_scale(z_value: float, fov_rad: float) -> float:
	var distance = abs(z_value)
	var perspective_scale = 1.0 / (1.0 + (distance / tan(fov_rad / 2.0)))
	return perspective_scale

func _get_configuration_warnings():
	if camera:
		return ""
	else:
		return "This node works with an existing ProCam2D node in tree!"
