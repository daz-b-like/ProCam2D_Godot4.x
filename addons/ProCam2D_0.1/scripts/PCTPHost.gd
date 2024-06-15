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

var _radius: float = 100: set = set_radius
var _enabled: bool = false: set = set_enabled
var _debug_draw: bool = false: set = set_draw

func _enter_tree() -> void:
		add_to_group("pptrackpoints")
		
func _ready() -> void:
	queue_redraw()

func _exit_tree() -> void:
	remove_from_group("pptrackpoints")

func _get_property_list():
	var props = []
	props.append({
		"name": "Track point Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	props.append({
		"name": "_radius",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0,1000,0.01"
		})
	props.append({
		"name": "_enabled",
		"type": TYPE_BOOL
	})
	props.append({
		"name": "_debug_draw",
		"type": TYPE_BOOL
	})
	return props

func set_enabled(value):
	_enabled = value
	if !value and is_in_group("track_points"):
		remove_from_group("track_points")
	elif value and !is_in_group("track_points"):
		add_to_group("track_points")
	queue_redraw()  # Ensure the draw method is called when enabled status changes

func set_draw(value):
	_debug_draw = value
	queue_redraw()

func set_radius(value):
	_radius = value
	queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint() or _enabled and _debug_draw:
		# Draw the filled circle with transparency
		var main_color = Color.WHITE
		main_color.a = 0.1
		draw_circle(Vector2.ZERO, _radius, main_color)

		# Draw the inner circle (center point indicator)
		draw_circle(Vector2.ZERO, 10, Color.WHITE)


func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		queue_redraw()
