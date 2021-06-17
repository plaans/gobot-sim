tool
extends Controller

export(int, 1, 2000) var points_amount = 200 setget set_points_amount
export(float, 0, 1000) var effect_radius = 500 setget set_effect_radius # px

export(bool) var debug_draw = true setget set_debug_draw
export(Gradient) var debug_proximity_gradient = preload("res://Assets/progress_gradient.tres")

var rays: Array = []

func _ready():
	setup_rays()

func _process(delta):
	if debug_draw:
		update()

func _draw():
	if !debug_draw:
		return
	
	for i in rays.size():
		var dist: Vector2 = rays[i].cast_to
		if rays[i].is_colliding():
			dist = (rays[i].get_collision_point() - global_position).rotated(-global_rotation)
		draw_line(Vector2.ZERO, dist, debug_proximity_gradient.interpolate(dist.length()/effect_radius))
	
	if target_point:
		draw_line(Vector2.ZERO, (target_point - global_position).rotated(-global_rotation), Color.blue)

# From Springer Handbook of Robotics, chap. 35.9.1 - Potential Fields method
const REP_CONST: float = -50.0
const ATT_CONST: float = 100.0

func get_velocity()->Vector2:
	if target_point == null:
		return Vector2.ZERO
	
	var att_force: Vector2 = (target_point - self.global_position).normalized() * ATT_CONST
	var rep_force: Vector2 = Vector2.ZERO
	for ray in rays:
		var ray_dist = ray.get_collision_point() - self.global_position
		if ray_dist.length() <= 0:
			rep_force += (ray_dist).normalized() * REP_CONST
		elif ray_dist.length() < ray.cast_to.length():
			rep_force += (ray_dist).normalized() * (1/ray_dist.length() - 1/ray.cast_to.length()) * REP_CONST
	
	return att_force + rep_force

func reached_target()->bool:
	if target_point == null:
		return false
	
	return (target_point - self.global_position).length() < target_margin

func setup_rays():
	# Clear the current rays
	for ray in get_children():
		remove_child(ray)
	rays.clear()
	
	# Create new rays
	var angle_step = 2*PI / points_amount
	for i in points_amount:
		var new_ray = RayCast2D.new()
		# effect_radius was given in meters
		new_ray.cast_to = Vector2.RIGHT.rotated(i*angle_step) * effect_radius
		new_ray.enabled = true
		
		rays.append(new_ray)
		add_child(new_ray)
	
	update()

func set_points_amount(new_amount: int):
	points_amount = new_amount
	setup_rays()

func set_effect_radius(new_radius: float):
	effect_radius = new_radius
	setup_rays()

func set_debug_draw(new_state: bool):
	debug_draw = new_state
	update()
