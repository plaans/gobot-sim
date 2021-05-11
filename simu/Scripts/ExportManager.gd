extends Node


var tile_size : Vector2 = Vector2(1,1) #size of a tile in pixel

var nodes_count = {}
#used to count how many instances of Robot, Machine, etc. have been created to create new names



func new_name(category : String) -> String:
	if not(nodes_count.has(category)):
		nodes_count[category] = 0
	else:
		nodes_count[category] += 1
	return category + str(nodes_count[category])


func set_tile_size(size : Vector2):
	tile_size = size
	
	
func pixels_to_meters(original_vector : Vector2) -> Array:
	#convert a position in pixel to a position in meter (assuming a tile is 1mx1m)
	#takes a position in Vector2 format 
	#and outputs the position as an [x,y] Array format which is the format used for transmission of data
	return [original_vector.x/tile_size.x, original_vector.y/tile_size.y]
	
func convert_array_pixels_to_meters(original_array : Array) -> Array:
	#convert a list of position 
	var new_array = []
	for position in original_array:
		new_array.append(pixels_to_meters(position))
	return new_array
	
func meters_to_pixels(original_array : Array) -> Vector2:
	#inverse of pixels_to_meters function
	return Vector2(original_array[0]*tile_size.x, original_array[1]*tile_size.y)

