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
extends Node

signal screen_shake_finished(types)

enum ShakeType {
	HORIZONTAL,
	VERTICAL,
	PERLIN,
	RANDOM,
	ZOOM,
	ROTATE,
	CIRCULAR
}

var _time_elapsed: float = 0.0
var _process_mode: int = 0
var _camera: Node2D
var _noise: = FastNoiseLite.new()

var _shake_data := {
	"start_time": 0.0,
	"duration": 0.0,
	"magnitude": 0.0,
	"speed": 0.0,
	"offset": Vector2.ZERO,
	"zoom_offset": Vector2.ZERO,
	"rotation_offset": 0.0,
	"types": []
}

func initialize(camera: Node2D, types: Array, duration: float, magnitude: float, speed: float, process_mode: int) -> void:
	_camera = camera
	_shake_data["types"] = types
	_shake_data["duration"] = duration
	_shake_data["magnitude"] = magnitude
	_shake_data["speed"] = speed
	_shake_data["start_time"] = _time_elapsed
	_process_mode = process_mode
	_camera._screen_shake_data["active_shakes"].append(self)

func _ready() -> void:
	# This function will be called when the node is added to the scene
	pass

func _physics_process(delta: float) -> void:
	if _process_mode == 1:
		_update_shake(delta)

func _process(delta: float) -> void:
	if _process_mode == 0:
		_update_shake(delta)

func _update_shake(delta: float) -> void:
	_time_elapsed += delta
	if _shake_data["start_time"] + _shake_data["duration"] <= _time_elapsed:
		_camera.emit_signal("screen_shake_finished", _shake_data["types"])
		_camera._screen_shake_data["active_shakes"].erase(self)
		queue_free()
	else:
		for type in _shake_data["types"]:
			match type:
				ShakeType.HORIZONTAL:
					_shake_data["offset"] = _calculate_horizontal_offset()
				ShakeType.VERTICAL:
					_shake_data["offset"] = _calculate_vertical_offset()
				ShakeType.CIRCULAR:
					_shake_data["offset"] = _calculate_circular_offset()
				ShakeType.PERLIN:
					_shake_data["offset"] = _calculate_perlin_offset()
				ShakeType.RANDOM:
					_shake_data["offset"] = _calculate_random_offset()
				ShakeType.ROTATE:
					_shake_data["rotation_offset"] = _calculate_rotation_offset()
				ShakeType.ZOOM:
					_shake_data["zoom_offset"] = _calculate_zoom_offset()

func get_offset() -> Vector2:
	return _shake_data["offset"]

func get_zoom_offset() -> Vector2:
	return _shake_data["zoom_offset"]

func get_rotation_offset() -> float:
	return _shake_data["rotation_offset"]

# Calculation methods for different shake types
func _calculate_circular_offset() -> Vector2:
	var angle = _time_elapsed * (_shake_data["speed"] * 5)
	var radius = _shake_data["magnitude"]
	return Vector2(cos(angle) * radius, sin(angle) * radius)

func _calculate_zoom_offset() -> Vector2:
	var zoom_amount = sin(_time_elapsed * _shake_data["speed"] * 10) * _shake_data["magnitude"] / 1500
	return Vector2(zoom_amount, zoom_amount)

func _calculate_rotation_offset() -> float:
	return sin(_time_elapsed * _shake_data["speed"] * 10) * _shake_data["magnitude"] / 500

func _calculate_random_offset() -> Vector2:
	return Vector2(randf_range(-_shake_data["magnitude"], _shake_data["magnitude"]),
					randf_range(-_shake_data["magnitude"], _shake_data["magnitude"]))

func _calculate_horizontal_offset() -> Vector2:
	return Vector2(sin(_time_elapsed * _shake_data["speed"] * 5) * _shake_data["magnitude"], 0)

func _calculate_vertical_offset() -> Vector2:
	return Vector2(0, sin(_time_elapsed * _shake_data["speed"] * 5) * _shake_data["magnitude"])

func _calculate_perlin_offset() -> Vector2:
	return Vector2(_noise.get_noise_1d(_time_elapsed * _shake_data["speed"] * 100) * _shake_data["magnitude"],
					_noise.get_noise_1d((_time_elapsed + 1000) * _shake_data["speed"] * 100) * _shake_data["magnitude"])
