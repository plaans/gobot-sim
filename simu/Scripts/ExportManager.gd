extends Node


var tile_size : Vector2 = Vector2(1,1) #size of a tile in pixel

var nodes_count = {}
#used to count how many instances of Robot, Machine, etc. have been created to create new names

var named_nodes_map = {} #used to know correspondance between robot names and instances

var robot_interfaces_map = {}

var machine_interfaces_map = {}

var command_id = 0 #counter used to generate command ids

func register_new_node(node : Node, category : String) -> String:
	#attributes a new name to the given node, and registers it in named_nodes_map to be able to acces it later by name
	if not(nodes_count.has(category)):
		nodes_count[category] = 0
	else:
		nodes_count[category] += 1
	var new_name = 	category + str(nodes_count[category])	
	
	named_nodes_map[new_name] = node	
	
	#if robot nodes creates a corresponding robot interface
	if category == "robot":
		var new_robot_interface = RobotInterface.new(node)
		robot_interfaces_map[new_name] = new_robot_interface
		node.add_child(new_robot_interface)
	elif category == "machine":
		var new_machine_interface = MachineInterface.new(node)
		machine_interfaces_map[new_name] = new_machine_interface
		node.add_child(new_machine_interface)
	return new_name
	
func get_node_from_name(name : String):
	if named_nodes_map.has(name):
		return named_nodes_map[name]
		
func get_robot_interface(robot_name : String):
	if robot_interfaces_map.has(robot_name):
		return robot_interfaces_map[robot_name]

func get_all_robot_interfaces() -> Array:
	return robot_interfaces_map.values()
		
func get_machine_interface(machine_name : String):
	if machine_interfaces_map.has(machine_name):
		return machine_interfaces_map[machine_name]
		
func get_all_machine_interfaces() -> Array:
	return machine_interfaces_map.values()
		
func set_tile_size(size : Vector2):
	tile_size = size
	
func pixel_to_meter(original_value : float) : 
	#supposes that tiles are always squared
	return original_value/tile_size.x

func vector_pixels_to_meters(original_vector : Vector2) -> Array:
	#convert a position in pixel to a position in meter (assuming a tile is 1mx1m)
	#takes a position in Vector2 format 
	#and outputs the position as an [x,y] Array format which is the format used for transmission of data
	return [original_vector.x/tile_size.x, original_vector.y/tile_size.y]
	
func vector_pixels_to_tiles(original_vector : Vector2) -> Array:
	#convert a position in pixel to a position in meter (assuming a tile is 1mx1m)
	#takes a position in Vector2 format 
	#and outputs the position as an [x,y] Array format which is the format used for transmission of data
	return [floor(original_vector.x/tile_size.x), floor(original_vector.y/tile_size.y)]	

func vector_pixels_to_vector_meters(original_vector : Vector2) -> Vector2:
	#convert a position in pixel to a position in meter (assuming a tile is 1mx1m)
	#takes a position in Vector2 format 
	#and outputs the position as a Vector2
	var new_vector = original_vector / tile_size
	return Vector2(floor(new_vector.x),floor(new_vector.y))

func convert_array_pixels_to_meters(original_array : Array) -> Array:
	var new_array = []
	for position in original_array:
		new_array.append(vector_pixels_to_meters(position))
	return new_array
	
func convert_polys_list_to_meters(original_array : Array) -> Array:
	#convert a list of polygons (each polygon being a list of points) from pixels coordonitales to meters
	var new_array = []
	for poly in original_array:
		new_array.append(convert_array_pixels_to_meters(poly))
	return new_array
		
func convert_array_pixels_to_tiles(original_array : Array) -> Array:
	var new_array = []
	for position in original_array:
		new_array.append(vector_pixels_to_tiles(position))
	return new_array
	
func convert_vector2s_array_to_arrays_array(original_array : Array) -> Array:
	#convert a list of positions as Vector2 to [x,y] format
	var new_array = []
	for position in original_array:
		new_array.append([position.x, position.y])
	return new_array


func meter_to_pixel(original_value : float) : 
	#supposes that tiles are always squared
	return original_value*tile_size.x

func tiles_to_pixels(original_array : Array) -> Vector2:
	#inverse of vector_pixels_to_tiles 
	return meters_to_pixels(original_array) + tile_size/2

func meters_to_pixels(original_array : Array) -> Vector2:
	# inverse of vector_pixels_to_meters
	return Vector2(original_array[0]*tile_size.x, original_array[1]*tile_size.y)
	
func add_export_static(node : Node):
	if not(node.has_method("export_static")):
		Logger.log_error("Cannot add node %s to export_static because it does not have export_static method" % str(node))
	else:
		node.add_to_group("export_static")	
		#it is necessary to send at the time of initialization the static information to clients
		Communication.send_message(JSON.print({'type' : 'static', 'data' :node.call("export_static")}))
		
func add_export_dynamic(node : Node):
	if not(node.has_method("export_dynamic")):
		Logger.log_error("Cannot add node %s to export_static because it does not have export_dynamic method" % str(node))
	else:
		node.add_to_group("export_dynamic")	
		
func generate_new_command_id():
	command_id+=1
	return command_id

func polygon_center(points_list : PoolVector2Array):
	var size = points_list.size()
	var points_sum = Vector2(0,0)
	if size>0:
		for point in points_list:
			points_sum += point
		return points_sum / size
