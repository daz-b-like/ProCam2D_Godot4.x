
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
extends EditorPlugin

const PROCAM2D: String = "ProCam2D"
#const PROCAMPARALLAX: String = "PCParallaxLayer"
const PROCAMTRACKPOINT: String = "PCTrackPoint"
var good_load: bool = false

func _enter_tree() -> void:
	var pcam = preload("res://addons/ProCam2D/scripts/ProCam2D.gd")
	var pcam_icon = preload("res://addons/ProCam2D/icons/ProCam2D_icon.png")
	var pcamtp = preload("res://addons/ProCam2D/scripts/PCTrackPoint.gd")
	var pcamtp_icon = preload("res://addons/ProCam2D/icons/TrackPoint_icon.png")
	#ProCam Nodes
	if pcam != null and pcam_icon != null and pcamtp != null and pcamtp_icon != null:
		add_custom_type(PROCAM2D, "Node2D", pcam, pcam_icon)
		add_custom_type(PROCAMTRACKPOINT, "Node2D", pcamtp, pcamtp_icon)
		add_autoload_singleton("ProCam","res://addons/ProCam2D/scripts/ProCam.gd")
		good_load = true

func _exit_tree() -> void:
	remove_custom_type(PROCAM2D)
	remove_custom_type(PROCAMTRACKPOINT)
	remove_autoload_singleton("ProCam")


func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(get_script().resource_path.get_base_dir() + "/plugin.cfg")
	return config.get_value("plugin", "version")
