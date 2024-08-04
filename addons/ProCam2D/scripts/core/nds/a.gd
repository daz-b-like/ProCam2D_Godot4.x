extends Resource
class_name PCamAddon

@export var enabled: bool = true
@export var priority = 0
var stage := "post_smoothing"

func pre_process(camera, delta):
	pass

func post_smoothing(camera, delta):
	pass

func final_adjust(camera, delta):
	pass

func apply(camera, delta):
	match stage:
		"pre_process":
			pre_process(camera, delta)
		"post_smoothing":
			post_smoothing(camera, delta)
		"final_adjust":
			final_adjust(camera, delta)

func setup(camera):
	pass

func exit(camera):
	pass
