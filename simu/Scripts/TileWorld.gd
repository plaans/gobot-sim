class_name TileWorld

# Data management class.
# Creates a view of the world's tiles as a 2-dimensional array,
# with an offset (distance of the most top-left position from 0,0) 
# and the size of the world

var data: Array setget set_data, get_data
var offset: Vector2 setget set_offset, get_offset
var size: Vector2 setget set_size, get_size
var transform: Transform2D 

func _init(tilemap: TileMap = null):
	# If no tilemap has been given, skip initialization
	if !tilemap:
		return
		
	var used_rect = tilemap.get_used_rect()
	
	set_offset(used_rect.position)
	set_size(used_rect.size)
	set_data([])
	
	for i in range(used_rect.position.x, used_rect.end.x):
		var col = []
		for j in range(used_rect.position.y, used_rect.end.y):
			col.append(tilemap.get_cell(i,j))
		data.append(col)

func get_data()->Array:
	return data
func set_data(new_data: Array):
	data = new_data

func get_offset()->Vector2:
	return offset
func set_offset(new_offset: Vector2):
	offset = new_offset
	transform = Transform2D(0, new_offset)

func get_size()->Vector2:
	return size
func set_size(new_size: Vector2):
	size = new_size

# Returns a dictionnary compatible with JSON format for easier export
func to_dict():
	return {
		"data": data, 
		"offset": [offset.x, offset.y], 
		"size": [size.x, size.y]
	}

func from_dict(dict: Dictionary):
	data = dict.get("data")
	var temp_offset = dict.get("offset")
	if temp_offset and typeof(temp_offset) == TYPE_ARRAY:
		offset = Vector2(temp_offset[0], temp_offset[1])
	var temp_size = dict.get("size")
	if temp_size and typeof(temp_size) == TYPE_ARRAY:
		size = Vector2(temp_size[0], temp_size[1])
