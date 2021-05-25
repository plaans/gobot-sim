extends Node


var tile_size : Vector2 = Vector2(1,1) #size of a tile in pixel

var nodes_count = {}
#used to count how many instances of Robot, Machine, etc. have been created to create new names

var named_nodes_map = {} #used to know correspondance between robot names and instances

func new_name(node : Node, category : String) -> String:
	#attributes a new name to the given node, and registers it in named_nodes_map to be able to acces it later by name
	if not(nodes_count.has(category)):
		nodes_count[category] = 0
	else:
		nodes_count[category] += 1
	var new_name = 	category + str(nodes_count[category])	
	named_nodes_map[new_name] = node	
	return new_name
	
func get_node_from_name(name : String):
	if named_nodes_map.has(name):
		return named_nodes_map[name]
		
func set_tile_size(size : Vector2):
	tile_size = size
	
func pixels_to_meters(original_vector : Vector2) -> Array:
	#convert a position in pixel to a position in meter (assuming a tile is 1mx1m)
	#takes a position in Vector2 format 
	#and outputs the position as an [x,y] Array format which is the format used for transmission of data
	return [original_vector.x/tile_size.x, original_vector.y/tile_size.y]
	
func pixels_to_tiles(original_vector : Vector2) -> Array:
	#convert a position in pixel to a position in tile (indexes of the tile)
	#takes a position in Vector2 format 
	#and outputs the position as an [x,y] Array format which is the format used for transmission of data
	return [floor(original_vector.x/tile_size.x), floor(original_vector.y/tile_size.y)]	
	
func convert_array_pixels_to_meters(original_array : Array) -> Array:
	var new_array = []
	for position in original_array:
		new_array.append(pixels_to_meters(position))
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
		new_array.append(pixels_to_tiles(position))
	return new_array
	
func convert_vector2s_array_to_arrays_array(original_array : Array) -> Array:
	#convert a list of positions as Vector2 to [x,y] format
	var new_array = []
	for position in original_array:
		new_array.append([position.x, position.y])
	return new_array

func meters_to_pixels(original_array : Array) -> Vector2:
	#inverse of pixels_to_meters function
	return Vector2(original_array[0]*tile_size.x, original_array[1]*tile_size.y)
	
func tiles_to_pixels(original_array : Array) -> Vector2:
	#inverse of pixels_to_tiles function
	return Vector2(original_array[0]*tile_size.x + tile_size.x/2, original_array[1]*tile_size.y + tile_size.y / 2)
	
func add_export_static(node : Node):
	node.add_to_group("export_static")	
	if not(node.has_method("export_static")):
		Logger.log_error("Added node %s to export_static but it does not have export_static method" % str(node))
		
func add_export_dynamic(node : Node):
	node.add_to_group("export_dynamic")	
	if not(node.has_method("export_dynamic")):
		Logger.log_error("Added node %s to export_dynamic but it does not have export_dynamic method" % str(node))


