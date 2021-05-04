extends KinematicBody2D

var carried_package;

var moving: bool = false
var move_time: float = 0.0
var velocity: Vector2 = Vector2.ZERO

export var max_rotation_speed : int = 500
var target_angle : float #set when doing a rotation
var rotation_speed
var rotate_time: float = 0.0
var rotating : bool

var path: PoolVector2Array
var path_line: Line2D
var following: bool = false
var current_path_point: int = 0


export var current_battery : float = 10.0
export var max_battery : float = 10.0
export var battery_drain_rate : float = 0.1
export var battery_charge_rate : float = 0.8
export var max_battery_frame : int = 20
var current_battery_frame : int = 0

var in_station: bool setget set_in_station,get_in_station
var in_interact: bool setget set_in_interact,get_in_interact

onready var raycast : RayCast2D = $RayCast2D

func _ready():
	pass

func _physics_process(delta):
	if !moving && following:
		if move_time <= 0.0:
			current_path_point += 1
			
		if current_path_point >= path.size():
			stop_path()
		else:
			var dir_vec: Vector2 = (path[current_path_point] - position)
			var speed = 96.0 # px/s
			var time = dir_vec.length()/speed # s
			goto(dir_vec.angle(), speed, time)
		
	if moving:
		if current_battery == 0:
			stop()
			stop_path()
		else:
			var collision = move_and_collide(velocity*delta)
			#if carried_package!=null:
				#carried_package.position = position
			
			move_time -= delta
			if collision:
				stop()
				stop_path()
				# Send "collision"
			elif move_time <= 0.0:
				stop()
	
	if rotating:
		if current_battery == 0:
			stop_rotation()
		else:
			rotate_time -= delta
			if rotate_time <= 0 :
				self.rotation = target_angle
				stop_rotation()
			else:
				self.rotate(rotation_speed * delta)

func _process(delta):
	#is_facing(get_node("../Machine/Input_Belt"))
	if not(in_station):
		var new_battery = max(0, current_battery - battery_drain_rate*delta)
		if current_battery>0 and new_battery==0:
			Logger.log_info("Battery became empty for robot of id %s" % self.get_instance_id())
		current_battery = new_battery
		$Sprite.modulate = Color(1,1,1)
	else:
		current_battery = min(max_battery, current_battery + battery_charge_rate*delta)
		var original_color = Color(1,1,1)
		var new_color = Color(0.5,1,1)

	update_battery_display()
	
func set_in_station(state : bool):
	in_station = state
	if in_station:
		$AnimationPlayer.play("charging")
	else:
		$AnimationPlayer.seek(0,true)
		$AnimationPlayer.stop()
	
func get_in_station() -> bool:
	return in_station

func set_in_interact(state : bool):
	in_interact = state
	
func get_in_interact() -> bool:
	return in_interact
			
func update_battery_display():
	var display = $Sprite
	var new_frame = int((current_battery / max_battery) * max_battery_frame)
	if new_frame != current_battery_frame:
		current_battery_frame = new_frame
		display.frame = new_frame
			
func is_moving():
	return moving

func goto(dir:float, speed:float, time:float):
	# dir : rad
	# speed : px/s
	# time : s
	Logger.log_info("%-12s %8.3f;%8.3f;%8.3f" % ["goto", dir, speed, time])
	move_time = time
	velocity = speed * Vector2.RIGHT.rotated(dir) # already normalized
	moving = true
	# Send "started"

func navigate_to(point: Vector2):
	stop()
	stop_path()
	var _nav: Navigation2D = get_node("../Navigation2D")
	if _nav:
		path = _nav.get_simple_path(position, point, true)
		var new_path_line = Line2D.new()
		new_path_line.points = path
		new_path_line.width = 2
		new_path_line.default_color = Color(1,1,1,0.5)
		self.path_line = new_path_line
		_nav.add_child(new_path_line)
		
		following = true
		current_path_point = 0

func stop():
	move_time = 0.0
	velocity = Vector2.ZERO
	moving = false
	# Send "stopped"
	

func stop_path():
	following = false
	if path_line:
		path_line.free()

func add_package(Package : Node):
	carried_package = Package
	add_child(carried_package)
	carried_package.position.x=7
	
func do_rotation(angle: float, speed: float):
	# angle : rad
	# speed : rad/s

	rotation_speed = speed
	if angle < 0:
		rotation_speed *= -1
	rotate_time = abs(angle/speed)
	target_angle = self.rotation + angle
	rotating = true 
		
func stop_rotation():
	rotating = false 
	rotation_speed = 0
	rotate_time = 0.0
	
func pickup():
	Logger.log_info("%-12s" % "pickup")
	if carried_package==null:
		#no package carried so pick up function
		
		#first find the closest output stand
		var closest_stand = find_target_stand("output")
		
		if closest_stand !=null:
			var machine = closest_stand.get_parent() #get machine corresponding to this output stand
			#machine can actually also be a Delivery_Zone or Arrival_Zone but it will still have the functions needed
				
			if machine.is_output_available():
				add_package(machine.take())
		else:
			Logger.log_warning("No stand found for pickup call")
				
	else: 
		#already carrying a package so drop off function
		
		#first find the closest input stand
		var closest_stand = find_target_stand("input")
		
		if closest_stand !=null:
			var machine = closest_stand.get_parent() #get machine corresponding to this input stand
			if machine.can_accept_package(carried_package):
				remove_child(carried_package)
				carried_package.position.x=0
				machine.add_package(carried_package)
				carried_package = null 
		else:
			Logger.log_warning("No stand found for pickup call")
				
#func is_facing(body : Node) -> bool:
#
#	var collider = raycast.get_collider()
#	return collider == body
	
func find_target_stand(group : String):
	#if no stands in pickup radius returns null
	#if multiple stands are in pickup radius returns the closest one
	if !in_interact:
		return null
	
	var target_stand = raycast.get_collider()
	if target_stand and target_stand.is_in_group(group):
		return target_stand
	else:
		return null
	
#	var stands = $Area2D.get_overlapping_bodies()
#	var closest_stand = null
#	var dist_min=1000000
#	for stand in stands:
#		if stand.is_in_group(group) and is_facing(stand):
#			var distance = self.position.distance_to(stand.position)
#			if distance <= dist_min:
#				dist_min = distance
#				closest_stand = stand	
#	return closest_stand
	
