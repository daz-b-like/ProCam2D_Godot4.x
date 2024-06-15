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

enum {
	 PHYSICS_PROCESS,
	 IDLE_PROCESS
}

enum {
	 SCREEN_SHAKE_HORIZONTAL,
	 SCREEN_SHAKE_VERTICAL,
	 SCREEN_SHAKE_PERLIN,
	 SCREEN_SHAKE_RANDOM,
	 SCREEN_SHAKE_ZOOM,
	 SCREEN_SHAKE_ROTATE,
	 SCREEN_SHAKE_CIRCULAR
}

enum {
	 DRAG_TYPE_PRED,
	 DRAG_TYPE_SPRING_DAMP,
	 DRAG_TYPE_ADAPTIVE,
	 DRAG_TYPE_SMOOTH_DAMP
}

var current_position: Vector2: get = get_cur_pos, set = set_cur_pos
var current_rotation: float: get = get_cur_rot, set = set_cur_rot
var track_multiple_objects: bool: get = get_tmo, set = set_tmo
var target: Object: get = get_target, set = set_target
var target_radius: float: get = get_tr, set = set_tr
var offset: Vector2: get = get_offset, set = set_offset
var process_type: int: get = get_pm, set = set_pm
var offset_smoothly: bool: get = get_os, set = set_os
var offset_speed: float: get = get_ospd, set = set_ospd
var drag_smoothly: bool: get = get_ds, set = set_ds
var drag_speed: Vector2: get = get_dspd, set = set_dspd
var drag_type: int: get = get_dt, set = set_dt
var rotate: bool: get = get_r, set = set_r
var rotation_speed: float: get = get_rspd, set = set_rspd
var rotate_smoothly: bool: get = get_rs, set = set_rs
var zoom_level: float: get = get_zoom_level, set = set_zoom_level
var zoom_smoothly: bool: get = get_zs, set = set_zs
var zoom_speed: float: get = get_zspd, set = set_zspd
var limit_smoothly: bool: get = get_ls, set = set_ls
var left_limit: float: get = get_ll, set = set_ll
var right_limit: float: get = get_rl, set = set_rl
var top_limit: float: get = get_tl, set = set_tl
var bottom_limit: float: get = get_bl, set = set_bl
var enable_v_margins: bool: get = get_vm, set = set_vm
var enable_h_margins: bool: get = get_hm, set = set_hm
var drag_left_margin: float: get = get_lm, set = set_lm
var drag_right_margin: float: get = get_rm, set = set_rm
var drag_top_margin: float: get = get_tm, set = set_tm
var drag_bottom_margin: float: get = get_bm, set = set_bm
var screen_center: Vector2: get = get_sc, set = set_sc
var ACTIVE_PROCAM: Node

func _ready() -> void:
	if get_tree().has_group("procam"):
			ACTIVE_PROCAM = get_tree().get_nodes_in_group("procam")[0]

# Helper functions
func _ensure_active_procam() -> bool:
	return ACTIVE_PROCAM != null

func _set_active_procam_value(property: String, value):
	if _ensure_active_procam():
		ACTIVE_PROCAM.set(property, value)

func _get_active_procam_value(property: String):
	if _ensure_active_procam():
		return ACTIVE_PROCAM.get(property)
	return null

# Public functions
func start_shake(types: = [SCREEN_SHAKE_PERLIN], duration: float = 0.3, magnitude: float = 3.5, speed: float = 20.0) -> void:
	if _ensure_active_procam():
		ACTIVE_PROCAM._start_shake(types, duration, magnitude, speed)

# Property setters and getters
func set_target(value: Object):
	if _ensure_active_procam():
		target = value
		ACTIVE_PROCAM._change_target_to(target)

func get_target() -> Node2D:
	return _get_active_procam_value("_target")

func set_cur_pos(value: Vector2):
	_set_active_procam_value("_cur_pos", value)

func get_cur_pos() -> Vector2:
	return _get_active_procam_value("_cur_pos")

func set_cur_rot(value):
	_set_active_procam_value("_cur_rot", float(value))

func get_cur_rot() -> float:
	return _get_active_procam_value("_cur_rot")

func set_zoom_level(value):
	_set_active_procam_value("_zoom_level", float(value))

func get_zoom_level() -> float:
	return _get_active_procam_value("_cur_zoom")

func set_tmo(value: bool):
	_set_active_procam_value("_tracking_multiple_objects", value)

func get_tmo() -> bool:
	return _get_active_procam_value("_tracking_multiple_objects")

func set_offset(value: Vector2):
	_set_active_procam_value("_offset", value)

func get_offset() -> Vector2:
	return _get_active_procam_value("_offset")

func set_pm(value: int):
	_set_active_procam_value("_process_mode", wrapi(value, 0, 2))

func get_pm() -> int:
	return _get_active_procam_value("_process_mode")

func set_os(value: bool):
	_set_active_procam_value("_offset_smoothly", value)

func get_os() -> bool:
	return _get_active_procam_value("_offset_smoothly")

func set_ospd(value):
	_set_active_procam_value("_offset_speed", float(value))

func get_ospd() -> float:
	return _get_active_procam_value("_offset_speed")

func set_ds(value: bool):
	_set_active_procam_value("_drag_smoothly", value)

func get_ds() -> bool:
	return _get_active_procam_value("_drag_smoothly")

func set_dspd(value: Vector2):
	_set_active_procam_value("_drag_speed", value)

func get_dspd() -> Vector2:
	return _get_active_procam_value("_drag_speed")

func set_dt(value: int):
	_set_active_procam_value("_drag_type", wrapi(value, 0, 4))

func get_dt() -> int:
	return _get_active_procam_value("_drag_type")

func set_r(value: bool):
	_set_active_procam_value("_rotate", value)

func get_r() -> bool:
	return _get_active_procam_value("_rotate")

func set_rspd(value):
	_set_active_procam_value("_rotation_speed", float(value))

func get_rspd() -> float:
	return _get_active_procam_value("_rotation_speed")

func set_rs(value: bool):
	_set_active_procam_value("_rotate_smoothly", value)

func get_rs() -> bool:
	return _get_active_procam_value("_rotate_smoothly")

func set_zs(value: bool):
	_set_active_procam_value("_zoom_smoothly", value)

func get_zs() -> bool:
	return _get_active_procam_value("_zoom_smoothly")

func set_zspd(value):
	_set_active_procam_value("_zoom_speed", float(value))

func get_zspd() -> float:
	return _get_active_procam_value("_zoom_speed")

func set_ls(value: bool):
	_set_active_procam_value("_limit_smoothly", value)

func get_ls() -> bool:
	return _get_active_procam_value("_limit_smoothly")

func set_ll(value):
	_set_active_procam_value("_left_limit", float(value))

func get_ll() -> float:
	return _get_active_procam_value("_left_limit")

func set_rl(value):
	_set_active_procam_value("_right_limit", float(value))

func get_rl() -> float:
	return _get_active_procam_value("_right_limit")

func set_tl(value):
	_set_active_procam_value("_top_limit", float(value))

func get_tl() -> float:
	return _get_active_procam_value("_top_limit")

func set_bl(value):
	_set_active_procam_value("_bottom_limit", float(value))

func get_bl() -> float:
	return _get_active_procam_value("_bottom_limit")

func set_lm(value):
	_set_active_procam_value("_drag_margin_left", float(value))

func get_lm() -> float:
	return _get_active_procam_value("_drag_margin_left")

func set_rm(value):
	_set_active_procam_value("_drag_margin_right", float(value))

func get_rm() -> float:
	return _get_active_procam_value("_drag_margin_right")

func set_tm(value):
	_set_active_procam_value("_drag_margin_top", float(value))

func get_tm() -> float:
	return _get_active_procam_value("_drag_margin_top")

func set_bm(value):
	_set_active_procam_value("_drag_margin_bottom", float(value))

func get_bm() -> float:
	return _get_active_procam_value("_drag_margin_bottom")

func set_vm(value: bool):
	_set_active_procam_value("_enable_v_margins", value)

func get_vm() -> bool:
	return _get_active_procam_value("_enable_v_margins")

func set_hm(value: bool):
	_set_active_procam_value("_enable_h_margins", value)

func get_hm() -> bool:
	return _get_active_procam_value("_enable_h_margins")

func set_tr(value: float):
	_set_active_procam_value("_target_radius", value)

func get_tr() -> float:
	return _get_active_procam_value("_target_radius")

func set_sc(_value):
	if _ensure_active_procam():
		printerr("You can't directly change the screen center. Use current_position")

func get_sc() -> Vector2:
	return _get_active_procam_value("_get_screen_center")
