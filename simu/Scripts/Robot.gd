extends KinematicBody2D


signal action_done

var robot_name : String

# Moving
# Note: move_speed is in px/s but should be adapted from m/s
var move_speed : float = 0.0 # px/s - set when using do_move
var move_dir : Vector2 # px - should be normalized, set when using do_move
var move_time : float = 0.0
# Velocity in px/s
const default_speed: int = 50
const default_battery_capacity = 10

# Rotating
var rotation_speed : float = 0.0 # rad/s - set when using do_rotation
var rotation_time : float = 0.0

# Navigating
var navigating : bool = false
var nav_path: PoolVector2Array
var real_nav_path: PoolVector2Array
var current_nav_point: int = 0
var distance_to_path: Vector2 = Vector2.ZERO
var nav_margin = 0 # px
export(float) var nav_running_margin = 20 # px
export(float) var nav_end_margin = 5 # px

# Battery
export var max_battery : float = System.default_battery_capacity
export var battery_drain_rate : float = System.default_battery_drain_rate
export var battery_drain_rate_idle: float = System.default_battery_drain_rate_idle
export var battery_charge_rate : float = System.default_battery_charge_rate
var current_battery : float = System.default_battery_capacity

var in_station : bool setget set_in_station
var in_interact : Array = []
var in_parking_area: Array = []
var carried_package : Node2D

var velocity : Vector2 = Vector2.ZERO # Set when doing a movement, manipulated by the controller

# Controller
export(NodePath) var controller_path = "PFController"
#onready var _Controller: Node2D = get_node_or_null(controller_path)
var _Controller: Node2D 
# Other Nodes
onready var _Raycast : RayCast2D = $RayCast2D
onready var _Progress = $Sprite/TextureProgress
onready var _Navigation = get_tree().get_nodes_in_group("navigation").front()
# Battery gradient
export var progress_gradient: Gradient = preload("res://Assets/progress_gradient.tres")
var _teleport = false

# Debug
export(float) var points_spacing = 3 # px
export(bool) var debug_draw = false setget set_debug_draw
export(Array, Color) var debug_colors = [Color.white, Color.purple, Color.white]

func _ready():
	current_battery = max_battery
	debug_draw = false
	
	if !_Navigation:
		Logger.log_error("No navigation available for %s - global motion planning will be disabled"%robot_name)
#	if !_Controller:
#		Logger.log_error("No controller defined for %s - local collision avoidance will be disabled"%robot_name)

	#generate a name 
	robot_name = ExportManager.register_new_node(self, "robot")
	
	ExportManager.add_export_static(self)
	ExportManager.add_export_dynamic(self)
	
func set_controller(robot_controller):
	if robot_controller == "PF":
		_Controller = get_node_or_null("PFController")
		set_collision_mask_bit(0, true) #make collisions active if using PFController
	elif robot_controller == "none":
		_Controller = null
	elif robot_controller == "teleport":
		_teleport = true

func _physics_process(delta):
	var in_action = false
	if navigating:
		in_action = true
		if real_nav_path.size() > 0 and global_position.distance_to(real_nav_path[0]) > points_spacing:
			real_nav_path.append(global_position)
		
		if current_nav_point > 0:
			var current_dist = nav_path[current_nav_point-1] - global_position
			var target_dist = (nav_path[current_nav_point-1] - nav_path[current_nav_point])
			distance_to_path = current_dist - current_dist.project(target_dist)
		# The robot either just started navigating or reached a point
		if !is_moving():
			# Reached the end of the path
			if current_nav_point < nav_path.size()-1:
				current_nav_point += 1
				nav_margin = 0
				move_to(nav_path[current_nav_point],move_speed)
			else:
				stop_navigate()
			
			if has_controller():
				if current_nav_point == nav_path.size()-1:
					nav_margin = nav_end_margin
				else:
					nav_margin = nav_running_margin
				_Controller.target_margin = nav_margin
	
	# Movement
	if is_moving():
		in_action = true
		# If navigating with a controller, velocity is set directly from it
		if navigating and has_controller():
			if _Controller.reached_target():
				stop_move()
			else:
				velocity = _Controller.get_velocity()
		# If moving but there is no controller, move in the given direction
		else:
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
				Logger.log_warning("Collision of robot %s" % robot_name)
				# stop_navigate()  # Stopping the navigation also stops the movement
				# Send "collision during movement"
	
	# Rotation
	if is_rotating():
		in_action = true
		rotation_time -= delta
		if rotation_time <= 0.0:
			rotate(rotation_speed * (rotation_time + delta))
			stop_rotation()
			# Send "do_rotation finished"
			#Communication.command_result(robot_name, "do_rotation", "do_rotation command completed successfully")
		elif current_battery <= 0.0:
			stop_rotation()
			# Send "battery depleted"
			#Communication.command_result(robot_name, "do_rotation", "Could not complete rotation command because battery became empty")
		else:
			rotate(rotation_speed * delta)
	
	if in_action:
		var new_battery = max(0, current_battery - battery_drain_rate*delta)
		if current_battery>0 and new_battery==0:
			Logger.log_info("Battery became empty for %s" % robot_name)
		current_battery = new_battery
	else:
		var new_battery = max(0, current_battery - battery_drain_rate_idle*delta)
		if current_battery>0 and new_battery==0:
			Logger.log_info("Battery became empty for %s" % robot_name)
		current_battery = new_battery
	
func _process(delta):
	if debug_draw:
		update()
	
	if in_station:
		current_battery = min(max_battery, current_battery + battery_charge_rate*delta)
		
	#if not(in_station):
		#var new_battery = max(0, current_battery - battery_drain_rate*delta)
		#if current_battery>0 and new_battery==0:
		#	Logger.log_info("Battery became empty for %s" % robot_name)
		#current_battery = new_battery
	#else:
	#	current_battery = min(max_battery, current_battery + battery_charge_rate*delta)

	update_battery_display()

func _draw():
	if !debug_draw:
		return
	
	if nav_path.size() >= 2:
		draw_polyline(transform.xform_inv(nav_path), debug_colors[0], 2.0)
	if real_nav_path.size() >= 2:
		draw_polyline(transform.xform_inv(real_nav_path), debug_colors[1], 2.0)
		draw_line(Vector2.ZERO, distance_to_path, debug_colors[2])

func set_debug_draw(state: bool):
	debug_draw = state
	update()

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

# Note: speed is in px/s
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

# Note: speed is in m/s
func move_to(point: Vector2, speed: float):
	# In the case the robot has local collision avoidance,
	# let the controller handle the motion
	if _teleport:
		position = point
	else:
		if has_controller():
			_Controller.target_point = point
		var new_vector = point - self.global_position
		do_move(new_vector.angle(), speed, new_vector.length() / speed)

func navigate_to(point: Vector2, speed: float = default_speed):
	if _teleport:
		position = point
	else:
		if !_Navigation:
			Logger.log_warning("No navigation available - cancelling command")
			Communication.command_result(robot_name, "navigate_to", "Could not complete navigate_to command because no navigation is available")
			return
		# Stop current navigation
		stop_navigate()
		# Setup path variables
		nav_path = _Navigation.get_simple_path(global_position, point)
		real_nav_path = PoolVector2Array([global_position])
		# Start navigating
		navigating = true
		current_nav_point = 0
		move_speed = speed
		emit_signal("action_done")
	
func navigate_to_cell(tile_x, tile_y, speed: float = default_speed):
	var target_position = ExportManager.tiles_to_pixels([tile_x, tile_y])
	navigate_to(target_position, speed)
	
func navigate_to_area(area):
	var destination_cell = find_closest_cell(area.cells)
	navigate_to_cell(destination_cell.x, destination_cell.y)
		
		
func go_charge():
	var parking_areas = get_tree().get_nodes_in_group("parking_areas")
	var destination_cell = find_closest_cell(find_closest_area(parking_areas).cells)
	navigate_to_cell(destination_cell.x, destination_cell.y)
	
	
func face_belt(node : Node2D, speed : float = 5):
	if not(node.has_method("set_belt_type")):
		Logger.log_warning("the argument used for face_belt is not the name of a belt")
		
	else:
		var collision_polygon
		for child_node in node.get_children():
			if child_node is CollisionPolygon2D:
				collision_polygon = child_node
				break
		
		var center = ExportManager.polygon_center(collision_polygon.polygon)
		var angle = Vector2.RIGHT.angle_to(center - position)
		rotate_to(angle, speed)
		
func find_closest_cell(cells_list : Array) -> Array:
	var dist_min
	var closest_cell = null
	
	for cell in cells_list:
		var new_dist = position.distance_to(ExportManager.tiles_to_pixels([cell.x, cell.y]))
		if closest_cell == null or new_dist<dist_min:
			dist_min = new_dist
			closest_cell = cell
	
	return closest_cell
	
func find_closest_area(areas_list : Array) -> Node:
	var dist_min
	var closest_area = null
	
	for area in areas_list:
		var closest_cell = find_closest_cell(area.cells)
		var new_dist = position.distance_to(ExportManager.tiles_to_pixels([closest_cell.x, closest_cell.y]))
		if closest_area == null or new_dist<dist_min:
			dist_min = new_dist
			closest_area = area
	
	return closest_area
	
#Returns the parking area or the belt with which the robot can interact 
func get_location() -> String:
	var interacts: Array = in_interact;
	var parkings: Array = in_parking_area;
	
	if interacts.empty():
		if !parkings.empty():
			return parkings[0].get_name()
	elif parkings.empty():
		return interacts[0].get_name()
	
	return String("unk_location")
	
	
	
func get_closest_area() -> Node:
	var areas = get_tree().get_nodes_in_group("parking_areas")
	areas += get_tree().get_nodes_in_group("interact_areas")
	return find_closest_area(areas)

func add_package(Package : Node):
	carried_package = Package
	carried_package.position = Vector2(7, 0)
	add_child(carried_package)
	
func pick():
	if carried_package:
		Logger.log_warning("Already carrying a package for pick() call")
		return false
	
	var target_belt = get_target_belt(1)
	if target_belt and !target_belt.is_empty():
		var new_package = target_belt.remove_package()
		add_package(new_package)
		return true
	else:
		Logger.log_warning("Invalid belt for pick() call")
		return false

func pick_package(package: Node):
	if carried_package:
		Logger.log_warning("Already carrying a package for pick_package() call")
		return false
	if !package:
		Logger.log_warning("No package specified for pick_package() call")
		return false
	
	var target_belt = get_target_belt(1)
	if target_belt and !target_belt.is_empty():
		var target_index: int = target_belt.packages.find(package)
		if target_index >= 0:
			var new_package = target_belt.remove_package(target_index)
			add_package(new_package)
			return true
		else:
			Logger.log_warning("No package %s in target belt for pick_package() call"%package.package_name)
			return false
	else:
		Logger.log_warning("Invalid target belt for pick_package() call")
		return false

func place():
	if !carried_package:
		Logger.log_warning("No current package for place() call")
		return false
	
	var target_belt = get_target_belt(0)
	if target_belt and target_belt.can_accept_package(carried_package):
		target_belt.add_package(carried_package)
		carried_package = null 
		return true
	else:
		Logger.log_warning("No belt found for place() call")
		return false
	


# Given a group string, returns the node which the robot's raycast is colliding with 
# if it's in the group.
# If there is no node colliding, if the node is not in the given group,
# or if the robot is not in an interaction area, returns null.
func get_target_belt(type: int)->Node:
	if in_interact.size() == 0:
		return null
	
	_Raycast.force_raycast_update()
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
	var export_data=[]
	# static export of drain and charge rate for the battery, as well as default displacement velocity
	export_data.append(["Robot.charge_rate", robot_name, battery_charge_rate])
	export_data.append(["Robot.drain_rate", robot_name, battery_drain_rate])
	export_data.append(["Robot.standard_speed", robot_name, ExportManager.pixel_to_meter(default_speed)])
	# default export: instance of the robot
	export_data.append(["Robot.instance", robot_name, "robot"])
	return export_data
	
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
	export_data.append(["Robot.closest_area", robot_name, get_closest_area().get_name()])
	export_data.append(["Robot.location", robot_name, get_location()])
	return export_data
