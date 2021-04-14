extends KinematicBody2D

var carried_package;

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

#var carried_package

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
	
func add_package(Package : Node):
	carried_package = Package
	add_child(carried_package)
	
func pickup():
	if carried_package==null:
		#no package carried so pick up function
		
		#first find the closest output stand
		var closest_stand = find_closest_stand("output")
		
		if closest_stand !=null:
			var machine = closest_stand.get_parent() #get machine corresponding to this output stand
			#machine can actually also be a Delivery_Zone or Arrival_Zone but it will still have the functions needed
				
			if machine.is_output_available():
				carried_package = machine.take()
				add_child(carried_package)
				
	else: 
		#already carrying a package so drop off function
		
		#first find the closest input stand
		var closest_stand = find_closest_stand("input")
		
		if closest_stand !=null:
			var machine = closest_stand.get_parent() #get machine corresponding to this input stand
			if machine.can_accept_package(carried_package):
				remove_child(carried_package)
				machine.add_package(carried_package)
				carried_package = null 
	
func find_closest_stand(group : String):
	#if no stands in pickup radius returns null
	#if multiple stands are in pickup radius returns the closest one
	
	var stands = $Area2D.get_overlapping_bodies()
	var closest_stand = null
	var dist_min=1000000
	for stand in stands:
		if stand.is_in_group(group):
			var distance = self.position.distance_to(stand.position)
			if distance <= dist_min:
				dist_min = distance
				closest_stand = stand	
	return closest_stand
	
