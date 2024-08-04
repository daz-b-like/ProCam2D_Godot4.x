@tool
extends PCamAddon
class_name PCamGrids

@export var grid_size := Vector2(64,64)
@export var grid_offset := Vector2.ZERO

func setup(camera):
	stage = "pre_process"

func pre_process(camera, delta):
	var snapped_target = camera._target_position.snapped(grid_size) + grid_offset
	camera._target_position = snapped_target
