extends KinematicBody2D


signal action_done

var robot_name : String

# Moving
# Note: 1m ~ 32px so 3m/s = 96px/s
var move_speed : float = 0.0 # px/s - set when using do_move
var move_dir : Vector2 # px - should be normalized, set when using do_move
var move_time : float = 0.0

# Rotating
var rotation_speed : float = 0.0 # rad/s - set when using do_rotation
var rotation_time : float = 0.0

# Navigating
var navigating : bool = false

# Battery
export var max_battery : float = 10.0
export var battery_drain_rate : float = 0.1
export var battery_charge_rate : float = 0.8
var current_battery : float = 10.0

var in_station : bool setget set_in_station
var in_interact : Array = []
var carried_package : Node2D

var velocity : Vector2 = Vector2.ZERO # Set when doing a movement, manipulated by the controller

# Controller
export(NodePath) var controller_path = "PFController"
onready var _Controller: Node2D = get_node_or_null(controller_path)
# Other Nodes
onready var _Raycast : RayCast2D = $RayCast2D
onready var _Progress = $Sprite/TextureProgress
onready var _MoveTimer = $MoveTimer
onready var _RotationTimer = $RotationTimer
# Battery gradient
export var progress_gradient: Gradient = preload("res://Assets/progress_gradient.tres")

func _ready():
	ExportManager.add_export_static(self)
	ExportManager.add_export_dynamic(self)
	current_battery = max_battery
	
	#generate a name 
	robot_name = ExportManager.new_name("robot")
	if !_Controller:
		Logger.log_error("No controller defined for %s - local collision avoidance will be disabled"%robot_name)
	
	ExportManager.add_new_robot(self)

func _physics_process(delta):
	if is_moving():
		var move_type = ""
		if navigating and has_controller():
			# If navigating with a controller, velocity is set directly from it
			if _Controller.reached_target():
				# Stop moving once the target is reached
				stop_navigate()
				# Send "navigate_to finished"
			# Use velocity given by the controller
			else:
				velocity = _Controller.get_velocity()
		else:
			# If moving but there is no controller, move in the given direction
			move_time -= delta
			if move_time <= 0.0:
				stop_move()
				# Send "do_move finished"
			else:
				# Calculate velocity from the direction and speed
				velocity = move_dir * move_speed
		
		if current_battery <= 0:
			stop_navigate()
			# Send "battery depleted"
		else:
			var collision = move_and_collide(velocity * delta)
			if collision:
				stop_navigate()  # Stopping the navigation also stops the movement
				# Send "collision during movement"
	
	if is_rotating():
		rotation_time -= delta
		if rotation_time <= 0.0:
			stop_rotation()
			# Send "do_rotation finished"
			Communication.command_result(robot_name, "do_rotation", "do_rotation command completed successfully")
		elif current_battery <= 0.0:
			stop_rotation()
			# Send "battery depleted"
			Communication.command_result(robot_name, "do_rotation", "Could not complete rotation command because battery became empty")
		else:
			rotate(rotation_speed * delta)

func _process(delta):
	if not(in_station):
		var new_battery = max(0, current_battery - battery_drain_rate*delta)
		if current_battery>0 and new_battery==0:
			Logger.log_info("Battery became empty for robot of id %s" % self.get_instance_id())
		current_battery = new_battery
	else:
		current_battery = min(max_battery, current_battery + battery_charge_rate*delta)

	update_battery_display()
	
func get_name() -> String:
	return robot_name
	
func set_in_station(state : bool):
	in_station = state
	if in_station:
		$AnimationPlayer.play("charging")
	else:
		$AnimationPlayer.seek(0,true)
		$AnimationPlayer.stop()

func get_battery_proportion():
	return current_battery / max_battery
	
func update_battery_display():
	_Progress.value = get_battery_proportion()*100
	_Progress.tint_progress = progress_gradient.interpolate(get_battery_proportion())

func has_controller()->bool:
	return _Controller != null


func do_move(angle: float, speed: float, duration: float):
	move_dir = Vector2(cos(angle), sin(angle))
	move_speed = speed
	move_time = duration

func do_rotation(speed: float, duration: float):
	rotation_speed = speed
	rotation_time = duration

func is_moving()->bool:
	return move_time > 0.0
	
func is_rotating()->bool:
	return rotation_time > 0.0

func stop_move():
	velocity = Vector2.ZERO
	move_time = 0.0

func stop_rotation():
	rotation_time = 0.0

func stop_navigate():
	if has_controller():
		_Controller.target_point = null
	navigating = false
	stop_move()

func rotate_to(target_angle: float, speed: float):
	var new_rotation = wrapf(target_angle - self.rotation, -PI, PI)
	var new_speed = speed * sign(new_rotation)
	do_rotation(new_speed, new_rotation / new_speed)

func move_to(point: Vector2, speed: float):
	var new_vector = point - self.global_position
	do_move(new_vector.angle(), speed, new_vector.length() / speed)

func navigate_to(point: Vector2):
	if has_controller():
		_Controller.target_point = point
		navigating = true
		# Make sure the robot moves
		move_time = 1.0
	else:
		Logger.log_warning("%s doesn't have a controller. Using move_to instead"%robot_name)
		# given 1m = 32px, move at a speed of 3m/s
		move_to(point, 96)
	
	emit_signal("action_done")
	
func navigate_to_cell(tile_x, tile_y):
	var target_position = ExportManager.tiles_to_pixels([tile_x, tile_y])
	navigate_to(target_position)

func add_package(Package : Node):
	carried_package = Package
	carried_package.position = Vector2(7, 0)
	add_child(carried_package)
	
func pick():
	Logger.log_info("%-12s" % "pick")
	if carried_package:
		Logger.log_warning("Already carrying a package for pick() call")
		return
	
	var target_belt = get_target_belt(1)
	if target_belt and !target_belt.is_empty():
		var new_package = target_belt.remove_package()
		add_package(new_package)
	else:
		Logger.log_warning("Invalid belt for pick() call")

func pick_package(package: Node):
	Logger.log_info("%-12s" % "pick_package")
	if carried_package:
		Logger.log_warning("Already carrying a package for pick_package() call")
		return
	if !package:
		Logger.log_warning("No package specified for pick_package() call")
		return
	
	var target_belt = get_target_belt(1)
	if target_belt and !target_belt.is_empty():
		var target_index: int = target_belt.packages.find(package)
		if target_index >= 0:
			var new_package = target_belt.remove_package(target_index)
			add_package(new_package)
		else:
			Logger.log_warning("No package %s in target belt for pick_package() call"%package.package_name)
	else:
		Logger.log_warning("Invalid target belt for pick_package() call")

func place():
	Logger.log_info("%-12s" % "place")
	if !carried_package:
		Logger.log_warning("No current package for place() call")
		return
	
	var target_belt = get_target_belt(0)
	if target_belt and target_belt.can_accept_package(carried_package):
		target_belt.add_package(carried_package)
		carried_package = null 
	else:
		Logger.log_warning("No belt found for place() call")
	

# Given a group string, returns the node which the robot's raycast is colliding with 
# if it's in the group.
# If there is no node colliding, if the node is not in the given group,
# or if the robot is not in an interaction area, returns null.
func get_target_belt(type: int)->Node:
	if in_interact.size() == 0:
		return null
	
	var target_object = _Raycast.get_collider()
	if target_object and target_object.is_in_group("belts") and target_object.belt_type == type:
		for interact_area in in_interact:
			if interact_area.belt == target_object:
				return target_object
	# If a condition has't been met, return null
	return null
	
func get_interact_areas_names() -> Array:
	#returns Array containing name of all interact areas the robot is in
	var names_array = []
	for interact_area in in_interact:
		names_array.append(interact_area.get_name())
	return names_array	
	
func export_static() -> Array:
	return [["Robot.instance", robot_name, "robot"]]
	
func export_dynamic() -> Array:
	var export_data=[]
	export_data.append(["Robot.coordinates", robot_name, ExportManager.vector_pixels_to_meters(position)])
	export_data.append(["Robot.coordinates_tile", robot_name, ExportManager.vector_pixels_to_tiles(position)])
	
	export_data.append(["Robot.rotation", robot_name, rotation])
	
	export_data.append(["Robot.battery", robot_name, get_battery_proportion()])
	
	export_data.append(["Robot.velocity", robot_name, ExportManager.vector_pixels_to_meters(velocity)])
	export_data.append(["Robot.rotation_speed", robot_name, rotation_speed])
	
	export_data.append(["Robot.in_station", robot_name, in_station])
	export_data.append(["Robot.in_interact_areas", robot_name, get_interact_areas_names()])
	return export_data
