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
export var battery_drain_rate : float = 0.4
export var battery_charge_rate : float = 0.8
onready var battery_original_scale : float = $Battery_Display.scale.y #for display
onready var battery_original_size : float = $Battery_Display.texture.get_size().y * $Battery_Display.scale.y #for display

var in_station : bool


func _physics_process(delta):
	if !moving && following:
		if move_time <= 0.0:
			current_path_point += 1
			
		if current_path_point >= path.size():
			stop_path()
		else:
			var dir_vec: Vector2 = (path[current_path_point] - position)
			var speed = 96.0
			var time = dir_vec.length()/speed
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
				var new_rotation = self.rotation + rotation_speed * delta
				self.rotation = new_rotation

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
	get_parent().log_text("goto:"+str(dir)+";"+str(speed)+";"+str(time))
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
	
func do_rotation(angle:float, speed:float = -1):
	# angle : rad
	#if speed negative or not specified take max_speed value
	
	if current_battery>0:
		if speed <=0:
			rotation_speed = max_rotation_speed
		else:
			rotation_speed = speed
		
		if angle <0:
			rotation_speed *= -1
		
		rotate_time = angle / rotation_speed
		target_angle = self.rotation + angle
		rotating = true 
		
func stop_rotation():
	rotating = false 
	rotation_speed = 0
	rotate_time = 0.0
	
func pickup():
	get_parent().log_text("pickup:")
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
	
