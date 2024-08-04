##################################################################
##################################################################
##################################################################
#############                                        #############
#############             Work in progress           #############
#############            not yet functional          #############
#############                                        ############
#############                                        #############
##################################################################
##################################################################
##################################################################

@tool
extends PCamAddon

# Add to the "procam_addons" group
func _init():
	stage = "pre_process"

# Export variables for customization
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var speed_threshold: float = 10.0

# Internal variables
var _current_zoom: float = 1.0

func pre_process(camera, delta):
	if not enabled:
		return

	var speed = camera._velocity.length()
	var target_zoom = _calculate_target_zoom(speed)
	_current_zoom = target_zoom
	camera._target_zoom = _current_zoom

func _calculate_target_zoom(speed: float) -> float:
	var zoom_level = 1.0
	
	if speed > speed_threshold:
		# Zoom out as speed increases
		var speed_factor = (speed - speed_threshold) / speed_threshold
		zoom_level = 1.0 / (1.0 + (speed_factor))
	else:
		# Zoom in slightly when speed is below threshold
		zoom_level = 1.0 / (1.0 - ((speed_threshold - speed) / speed_threshold))
	return clamp(zoom_level, min_zoom, max_zoom)

# Optional: Reset function to restore default state
func reset():
	_current_zoom = 1.0
