tool
extends Node2D

export(int, 1, 2000) var points_amount = 100 setget set_points_amount
export(float, 0, 500) var effect_radius = 100.0 setget set_effect_radius # px
export(Vector2) var target = null # px, in global coordinates

export(bool) var debug_draw = true
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
			dist = rays[i].get_collision_point() - self.global_position
		draw_line(Vector2.ZERO, dist, debug_proximity_gradient.interpolate(dist.length()/effect_radius))
	
	if target:
		draw_line(Vector2.ZERO, target - self.global_position, Color.blue)
	

func setup_rays():
	# Clear the current rays
	for ray in get_children():
		remove_child(ray)
	rays.clear()
	
	# Create new rays
	var angle_step = 2*PI / points_amount
	for i in points_amount:
		var new_ray = RayCast2D.new()
		new_ray.cast_to = Vector2.RIGHT.rotated(i*angle_step) * effect_radius
		new_ray.enabled = true
		
		rays.append(new_ray)
		add_child(new_ray)

func set_points_amount(new_amount: int):
	points_amount = new_amount
	setup_rays()

func set_effect_radius(new_radius: float):
	effect_radius = new_radius
	setup_rays()

