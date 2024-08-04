extends Object
class_name PCamUtils

# Predicts the future position based on current position, velocity, and prediction time
static func predict_future_position(current_position: float, velocity: float, prediction_time: float) -> float:
	return current_position + velocity * prediction_time

# Applies spring-damper motion to a value
static func spring_damp(current: float, target: float, current_velocity: float, spring_constant: float, damping_ratio: float, delta: float) -> Dictionary:
	var difference = target - current
	damping_ratio = max(damping_ratio, 0.0001)
	var spring_force = difference * spring_constant
	var damping_force = (-current_velocity / damping_ratio) * 10
	var force = spring_force + damping_force
	current_velocity += force * delta
	var new_position = current + current_velocity * delta
	return {"new_position": new_position, "new_velocity": current_velocity}

# Applies smooth damping to a value
static func smooth_damp(current: float, target: float, current_velocity: float, smooth_time: float, max_speed: float, delta: float) -> Dictionary:
	smooth_time = 1 / max(0.0001, smooth_time)
	var omega = 2.0 / smooth_time
	var x = omega * delta
	var texp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change = current - target
	var max_change = max_speed * smooth_time
	change = clamp(change, -max_change, max_change)
	target = current - change
	var temp = (current_velocity + omega * change) * delta
	current_velocity = (current_velocity - omega * temp) * texp
	var new_position = target + (change + temp) * texp
	return {"new_position": new_position, "new_velocity": current_velocity}

static func adaptive_smooth_damp(current: float, target: float, current_velocity: float, max_speed: float, delta: float) -> Dictionary:
	# Calculate the current speed as the absolute value of current velocity
	var speed = abs(current_velocity)
	var base_smooth_time: float = 0.3
	# Adapt the smooth_time based on the speed, decreasing as the object slows down
	var smooth_time = max(base_smooth_time * (1.0 - speed / 100.0), base_smooth_time)
	
	# Ensure smooth_time has a minimum value to avoid being too small
	smooth_time = max(0.0001, smooth_time)
	
	# Calculate the omega
	var omega = 2.0 / smooth_time
	
	# Calculate x
	var x = omega * delta
	
	# Calculate exponential decay
	var texp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	# Calculate change value
	var change = current - target
	var original_to = target
	
	# Clamp change to maximum speed
	var max_change = max_speed * smooth_time
	change = clamp(change, -max_change, max_change)
	
	# Calculate target
	target = current - change
	
	# Calculate temporary
	var temp = (current_velocity + omega * change) * delta
	
	# Calculate new velocity
	current_velocity = (current_velocity - omega * temp) * texp
	
	# Calculate new position
	var new_position = target + (change + temp) * texp
	
	# Ensure new position does not exceed target if necessary
	if (original_to - current > 0.0) == (new_position > original_to):
		new_position = original_to
		current_velocity = (new_position - original_to) / delta
	
	return {"new_position": new_position, "new_velocity": current_velocity}

static func wrap_angle(angle: float) -> float:
	return fposmod(angle + PI, 2 * PI) - PI

static func shortest_angle_distance(from: float, to: float) -> float:
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(difference + max_angle/2, max_angle) - max_angle/2

static func _calculate_continuous_angle_diff(from: float, to: float) -> float:
	var diff = to - from
	# Adjust for crossing the -π/2 to π/2 boundary
	if diff > PI/2 or diff < -PI/2:
		diff = 0
	
	return diff

static func smooth_damp_angle(current: float, target: float, current_velocity: float, smooth_time: float, max_speed: float, delta: float) -> Dictionary:
	target = current + shortest_angle_distance(current, target)
	var result = smooth_damp(current, target, current_velocity, smooth_time, max_speed, delta)
	return {"new_angle": result.new_position, "new_velocity": result.new_velocity}

static func clamp_point_inside_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clamp(point.x, rect.position.x, rect.end.x),
		clamp(point.y, rect.position.y, rect.end.y)
	)

static func _sort_by_priority(a, b):
	if a.priority == b.priority:
		return a.get_instance_id() < b.get_instance_id()
	return a.priority > b.priority

static func sort_by_area(a, b) -> bool:
	return a.rect_size.x * a.rect_size.y < b.rect_size.x * b.rect_size.y

static func ease_in(t: float) -> float:
	return t * t

static func ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

static func ease_in_out(t: float) -> float:
	return 2 * t * t if t < 0.5 else 1 - pow(-2 * t + 2, 2) / 2

static func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t

static func inverse_lerp(a: float, b: float, v: float) -> float:
	return (v - a) / (b - a) if b - a != 0 else 0.0

static func remap(value: float, input_start: float, input_end: float, output_start: float, output_end: float) -> float:
	var t = inverse_lerp(input_start, input_end, value)
	return lerp(output_start, output_end, t)
