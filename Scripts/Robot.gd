extends KinematicBody2D

var carried_package;

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

export var current_battery : float = 10.0
export var max_battery : float = 10.0
export var battery_drain_rate : float = 0.4
export var battery_charge_rate : float = 0.4
onready var battery_original_scale : float = $Battery_Display.scale.y #for display
onready var battery_original_size : float = $Battery_Display.texture.get_size().y * $Battery_Display.scale.y #for display

var in_station : bool

func _physics_process(delta):
	if moving:
		if current_battery == 0:
			stop()
		else:
			var collision = move_and_collide(velocity*delta)
			#if carried_package!=null:
				#carried_package.position = position
			
			move_time -= delta
			if collision or move_time <= 0.0:
				stop()

func _process(delta):
	if not(in_station):
		current_battery = max(0, current_battery - battery_drain_rate*delta)
	else:
		current_battery = min(max_battery, current_battery + battery_charge_rate*delta)
	update_battery_display()
	
func set_in_station(state : bool):
	in_station = state
	
func get_in_station() -> bool:
	return in_station
			
func update_battery_display():
	var display = $Battery_Display
	display.scale.y= battery_original_scale * current_battery / max_battery
	
	
	display.position.y = battery_original_size * (1 - current_battery / max_battery)/2
			
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
	
