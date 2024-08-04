@tool
extends "b.gd"

const GROUP_NAME = "procam_magnets"

enum AttractRepel {
	ATTRACT,
	REPEL
}

enum MagnetShape {
	CIRCLE,
	RECTANGLE
}

#signals
signal magnet_entered()
signal magnet_exited()

var magnet_shape = MagnetShape.CIRCLE: set = set_magnet_shape
var attract_repel = AttractRepel.ATTRACT: set = set_attract_repel
var radius: float = 200.0: set = set_radius
var rectangle_size: Vector2 = Vector2(400, 200): set = set_rectangle_size
var use_full_force: bool = true: set = set_use_full_force
var force: Vector2 = Vector2(100.0, 100.0): set = set_force
var falloff_curve: Curve: set = set_falloff_curve

var _is_inside = false
var _current_camera = null

func _init() -> void:
	add_to_group(GROUP_NAME)

func _ready() -> void:
	super._ready()
	if not falloff_curve:
		falloff_curve = Curve.new()
		_setup_default_falloff_curve()

func _setup_default_falloff_curve() -> void:
	falloff_curve.clear_points()
	falloff_curve.add_point(Vector2(0, 1))
	falloff_curve.add_point(Vector2(1, 0))

func apply_influence(pos) -> Vector2:
	if not enabled:
		return pos
	if not falloff_curve:
		_setup_default_falloff_curve()
	
	var direction = global_position - pos
	var distance: float
	var is_inside: bool

	if magnet_shape == MagnetShape.CIRCLE:
		distance = direction.length()
		is_inside = distance <= radius
	else: # RECTANGLE
		var half_size = rectangle_size * 0.5
		var local_pos = direction.abs()
		distance = max(local_pos.x / half_size.x, local_pos.y / half_size.y)
		is_inside = local_pos.x <= half_size.x and local_pos.y <= half_size.y

	# Check for entering or exiting the magnet
	if is_inside and not _is_inside:
		_is_inside = true
		emit_signal("magnet_entered")
	elif not is_inside and _is_inside:
		_is_inside = false
		emit_signal("magnet_exited")

	if not is_inside:
		return pos
	
	var force_direction = direction.normalized() if attract_repel == AttractRepel.ATTRACT else -direction.normalized()
	
	if use_full_force:
		# Apply full attraction or repulsion
		if attract_repel == AttractRepel.ATTRACT:
			return global_position
		else:
			if magnet_shape == MagnetShape.CIRCLE:
				var max_repel_distance = radius - distance
				return pos + force_direction * max_repel_distance
			else: #RECTANGLE
				# Apply logic for full-force repel that slides smoothly along the rectangle's edges
				var local_pos = pos - global_position
				var half_size = rectangle_size * 0.5
				var normalized_pos = Vector2(local_pos.x / half_size.x, local_pos.y / half_size.y)
				var max_component = max(abs(normalized_pos.x), abs(normalized_pos.y))
				if max_component > 1:
					normalized_pos /= max_component
				var edge_pos = Vector2(
					sign(normalized_pos.x) * half_size.x,
					sign(normalized_pos.y) * half_size.y
				)
				if abs(normalized_pos.x) > abs(normalized_pos.y):
					edge_pos.y = local_pos.y
				else:
					edge_pos.x = local_pos.x
				return global_position + edge_pos
	else:
		if magnet_shape == MagnetShape.CIRCLE:
			# Use the original force and falloff calculations
			var force_magnitude = force * falloff_curve.interpolate(distance / radius)
			var max_displacement = distance if attract_repel == AttractRepel.ATTRACT else radius - distance
			var actual_displacement = min(force_magnitude.length(), max_displacement)
			return pos + force_direction * actual_displacement
		else: #RECTANGLE
			# Implement smooth rectangle attraction and repelling that doesn't overshoot and uses falloff curve
			var local_pos = pos - global_position
			var half_size = rectangle_size * 0.5
			var normalized_pos = Vector2(local_pos.x / half_size.x, local_pos.y / half_size.y)
			var max_component = max(abs(normalized_pos.x), abs(normalized_pos.y))
			var distance_factor = max_component
			
			# Calculate the distance to the edge of the rectangle
			var edge_distance = Vector2(
				max(0, abs(local_pos.x) - half_size.x),
				max(0, abs(local_pos.y) - half_size.y)
			)
			var distance_from_edge = edge_distance.length()
			
			# Calculate force magnitude using the falloff curve
			var force_magnitude = force * falloff_curve.interpolate(distance_factor)
			
			var displacement_vector
			
			if attract_repel == AttractRepel.ATTRACT:
				# For attraction, limit displacement to the distance to the center
				displacement_vector = (-local_pos.normalized() * force_magnitude).clamped(local_pos.length())
			else: # REPEL
				var repel_direction
				if edge_distance.length() == 0:
					# Object is inside the rectangle
					if abs(normalized_pos.x) > abs(normalized_pos.y):
						repel_direction = Vector2(sign(local_pos.x), 0)
					else:
						repel_direction = Vector2(0, sign(local_pos.y))
				else:
					# Object is outside the rectangle
					repel_direction = edge_distance.normalized()
				
				# Calculate max repel distance
				var max_repel_distance
				if edge_distance.length() == 0:
					max_repel_distance = min(half_size.x - abs(local_pos.x), half_size.y - abs(local_pos.y))
				else:
					max_repel_distance = distance_from_edge
				
				# Apply force with respect to max repel distance
				displacement_vector = (repel_direction * force_magnitude).clamped(max_repel_distance)
			
			return pos + displacement_vector

func _draw_debug() -> void:
	if magnet_shape == MagnetShape.CIRCLE:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, debug_color[1], 1.0)
	else:  # RECTANGLE
		var rect = Rect2(-rectangle_size/2, rectangle_size)
		draw_rect(rect, debug_color[1], false, 1.0)
	# center circle
	draw_circle(Vector2.ZERO, 10 * debug_draw_scaler, debug_color[0])

func _exit_tree():
	if _is_inside:
		emit_signal("magnet_exited")

func _get_property_list():
	var properties = []
	
	# Magnet Properties
	properties.append({
		"name": "Magnet Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		"name": "attract_repel",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Attract,Repel",
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		"name": "magnet_shape",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Circle,Rectangle",
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	
	# Shape-specific Properties
	if magnet_shape == MagnetShape.CIRCLE:
		properties.append({
			"name": "radius",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	elif magnet_shape == MagnetShape.RECTANGLE:
		properties.append({
			"name": "rectangle_size",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	
	properties.append({
		"name": "use_full_force",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT
	})

	if not use_full_force:
		properties.append({
			"name": "force",
			"type": TYPE_VECTOR2,
			"usage": PROPERTY_USAGE_DEFAULT
		})

		properties.append({
			"name": "falloff_curve",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Curve",
			"usage": PROPERTY_USAGE_DEFAULT
		})
	
	# Debug Properties
	properties.append({
		"name": "debug_color",
		"type": TYPE_COLOR,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	
	return properties

func set_magnet_shape(value):
	magnet_shape = value
	queue_redraw()
	notify_property_list_changed()

func set_attract_repel(value):
	attract_repel = value

func set_radius(value):
	radius = value
	queue_redraw()

func set_rectangle_size(value):
	rectangle_size = value
	queue_redraw()

func set_use_full_force(value):
	use_full_force = value
	notify_property_list_changed()

func set_force(value):
	force = value

func set_falloff_curve(value):
	falloff_curve = value

func set_debug_color(value):
	debug_color = value
	queue_redraw()
