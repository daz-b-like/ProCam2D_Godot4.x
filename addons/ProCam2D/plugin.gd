#MIT License

#Copyright (c) 2024 Daz B. Like / Kalulu games

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
extends EditorPlugin
const PROCAM2D: String = "ProCam2D"
const PCAMTARGET: String = "PCamTarget"
const PCAMCINEMATIC: String = "PCamCinematic"
const PCAMMAGNET: String = "PCamMagnet"
const PCAMPATH: String = "PCamPath"
const PCAMZOOM: String = "PCamZoom"
const PCAMROOM: String = "PCamRoom"
var good_load: bool = false

func _enter_tree() -> void:
	# nodes
	var pcam2d = preload("res://addons/ProCam2D/scripts/procam2d.gd")
	var pcamtarget = preload("res://addons/ProCam2D/scripts/pcam_target.gd")
	var pcamzoom = preload("res://addons/ProCam2D/scripts/procam_zoom.gd")
	var pcamroom = preload("res://addons/ProCam2D/scripts/pcam_room.gd")
	var pcammagnet = preload("res://addons/ProCam2D/scripts/pcam_magnet.gd")
	var pcamcinematic = preload("res://addons/ProCam2D/scripts/pcam_cinematicpoint.gd")
	var pcampath = preload("res://addons/ProCam2D/scripts/pcam_path.gd")
	# icons
	var camicon = preload("res://addons/ProCam2D/assets/icons/pcam.png")
	var targeticon = preload("res://addons/ProCam2D/assets/icons/pcam_target.png")
	var cinematicicon = preload("res://addons/ProCam2D/assets/icons/pcam_cinematic.png")
	var magneticon = preload("res://addons/ProCam2D/assets/icons/pcam_magnet.png")
	var pathicon = preload("res://addons/ProCam2D/assets/icons/pcam_path.png")
	var zoomicon = preload("res://addons/ProCam2D/assets/icons/pcam_zoom.png")
	var roomicon = preload("res://addons/ProCam2D/assets/icons/pcam_room.png")
	
	#check if all went well
	good_load = pcam2d and pcamtarget and pcamzoom and pcamroom \
				and pcammagnet and pcamcinematic and pcampath \
				and camicon and targeticon and cinematicicon and magneticon \
				and pathicon and zoomicon and roomicon
	#adding ProCam Nodes
	if good_load:
		add_autoload_singleton("procam", "res://addons/ProCam2D/scripts/autoload.gd")
		add_custom_type(PROCAM2D, "Node2D", pcam2d, camicon)
		add_custom_type(PCAMTARGET, "Node2D", pcamtarget, targeticon)
		add_custom_type(PCAMCINEMATIC, "Node2D", pcamcinematic, cinematicicon)
		add_custom_type(PCAMMAGNET, "Node2D", pcammagnet, magneticon)
		add_custom_type(PCAMPATH, "Node2D", pcampath, pathicon)
		add_custom_type(PCAMZOOM, "Node2D", pcamzoom, zoomicon)
		add_custom_type(PCAMROOM, "Node2D", pcamroom, roomicon)

func _exit_tree() -> void:
	if good_load:
		remove_autoload_singleton("procam")
		remove_custom_type(PROCAM2D)
		remove_custom_type(PCAMTARGET)
		remove_custom_type(PCAMCINEMATIC)
		remove_custom_type(PCAMMAGNET)
		remove_custom_type(PCAMPATH)
		remove_custom_type(PCAMZOOM)
		remove_custom_type(PCAMROOM)
