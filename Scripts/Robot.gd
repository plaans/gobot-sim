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


var robot_name

signal action_done

export var max_battery : float = 10.0
export var battery_drain_rate : float = 0.1
export var battery_charge_rate : float = 0.8
var current_battery : float = 10.0

var in_station: bool setget set_in_station
var in_interact: bool setget set_in_interact


onready var raycast : RayCast2D = $RayCast2D
onready var _Progress = $Sprite/TextureProgress
export var progress_gradient: Gradient = preload("res://Assets/robot/progress_gradient.tres")

export var TEST_ROBOT_SPEED = 96 #px/s
# Note:
# 1m ~ 32px
# so 3m/s = 96px/s

func _ready():
	add_to_group("export_static")
	add_to_group("export_dynamic")
	current_battery = max_battery

func _physics_process(delta):
	if !moving && following:
		if move_time <= 0.0:
			current_path_point += 1
			
		if current_path_point >= path.size():
			stop_path()
			Communication.command_result(robot_name, "navigate_to", "Navigate_to command completed successfully")
		else:
			var dir_vec: Vector2 = (path[current_path_point] - position)
			var speed = TEST_ROBOT_SPEED # px/s
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
			Communication.command_result(robot_name, "do_rotation", "Could not complete rotation command because battery became empty")
		else:
			rotate_time -= delta
			if rotate_time <= 0 :
				self.rotation = target_angle
				stop_rotation()
				Communication.command_result(robot_name, "do_rotation", "do_rotation command completed successfully")
			else:
				self.rotate(rotation_speed * delta)

func _process(delta):
	#is_facing(get_node("../Machine/Input_Belt"))
	if not(in_station):
		var new_battery = max(0, current_battery - battery_drain_rate*delta)
		if current_battery>0 and new_battery==0:
			Logger.log_info("Battery became empty for robot of id %s" % self.get_instance_id())
		current_battery = new_battery
	else:
		current_battery = min(max_battery, current_battery + battery_charge_rate*delta)

	update_battery_display()

func set_name(name : String):
	robot_name = name
	
func get_name() -> String:
	return robot_name
	
func set_in_station(state : bool):
	in_station = state
	if in_station:
		$AnimationPlayer.play("charging")
	else:
		$AnimationPlayer.seek(0,true)
		$AnimationPlayer.stop()
	
func get_in_station() -> bool:
	return in_station
	
func get_battery_proportion():
	return current_battery / max_battery
	

func set_in_interact(state : bool):
	in_interact = state
			
func update_battery_display():
	_Progress.value = current_battery/max_battery*100
	_Progress.tint_progress = progress_gradient.interpolate(_Progress.value/100)
			
func is_moving():
	return following
	
func is_rotating():
	return rotating

func goto(dir:float, speed:float, time:float):
	# dir : rad
	# speed : px/s
	# time : s
	#Logger.log_info("%-12s %8.3f;%8.3f;%8.3f" % ["goto", dir, speed, time])
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
		
	emit_signal("action_done")

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
	carried_package.position = Vector2(7, 0)
	add_child(carried_package)
	
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
	if !carried_package:
		#no package carried so pick up function
		
		#first find the closest output belt
		var target_belt = find_target_belt(1)
		if target_belt and !target_belt.is_empty():
			var package = target_belt.remove_package()
			print(package)
			add_package(package)
		else:
			Logger.log_warning("No belt found for pickup call")
				
	else: 
		#already carrying a package so drop off function
		
		#first find the closest input belt
		var target_belt = find_target_belt(0)
		if target_belt and target_belt.can_accept_package(carried_package):
			target_belt.add_package(carried_package)
			carried_package = null 
		else:
			Logger.log_warning("No belt found for pickup call")

# Given a group string, returns the node which the robot's raycast is colliding with 
# if it's in the group.
# If there is no node colliding, if the node is not in the given group,
# or if the robot is not in an interaction area, returns null.
func find_target_belt(type: int)->Node:
	if !in_interact:
		return null
	
	var target_object = raycast.get_collider()
	if target_object and target_object.is_in_group("belts") and target_object.belt_type == type:
		return target_object
		print("found belt")
	else:
		return null
	
func export_static():
	return [["robot", robot_name]]
	
func export_dynamic():
	var export_data=[]
	export_data.append(["coordinates", robot_name, [position.x, position.y]])
	export_data.append(["rotation", robot_name, rotation])
	export_data.append(["battery", robot_name, get_battery_proportion()])
	export_data.append(["is_moving", robot_name, is_moving()])
	export_data.append(["is_rotating", robot_name, is_rotating()])
	export_data.append(["in_station", robot_name, in_station])
	return export_data
		
	
