extends KinematicBody2D

onready var _Package = get_node("../../Package")

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

var carried_package

func _physics_process(delta):
	if moving:
		var collision = move_and_collide(velocity*delta)
		#if carried_package!=null:
			#carried_package.position = position
		
		move_time -= delta
		if collision or move_time <= 0.0:
			stop()
			
func is_moving():
	return moving

func goto(dir:float, speed:float, time:float):
	# dir : rad
	# speed : px/s
	# time : s
	move_time = time
	velocity = speed * Vector2.RIGHT.rotated(dir) # already normalized
	moving = true
	# Send "started"

func stop():
	move_time = 0.0
	velocity = Vector2.ZERO
	moving = false
	# Send "stopped"
	
func pickup():
	if carried_package==null:
		#no package carried so pick up function
		
		#first find the closest stand
		var closest_stand = find_closest_stand()
		
		#then check if a close enough stand was found
		if closest_stand !=null:
			var stand_package = closest_stand.get_node("Package")
			if stand_package!=null:
				carried_package=stand_package
				closest_stand.remove_child(carried_package)
				self.add_child(carried_package)
				carried_package.set_owner(self)
	else:
		#already carrying a package so drop off function
		
		var closest_stand = find_closest_stand()
		
		#then check if a close enough stand was found
		if closest_stand !=null:
			var stand_package = closest_stand.get_node("Package")
			if stand_package==null:
				self.remove_child(carried_package)
				closest_stand.add_child(carried_package)
				carried_package.set_owner(closest_stand)
				carried_package=null
	
func find_closest_stand():
	#if no stands in pickup radius returns null
	#if multiple stands are in pickup radius returns the closest one
	
	var stands = $Area2D.get_overlapping_bodies()
	print(stands)
	var closest_stand = null
	var dist_min=1000000
	for stand in stands:
		var distance = self.position.distance_to(stand.position)
		if distance <= dist_min:
			dist_min = distance
			closest_stand = stand	
	return closest_stand
	
