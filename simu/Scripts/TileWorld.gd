class_name TileWorld

# Data management class.
# Creates a view of the world's tiles as a 2-dimensional array,
# with an offset (distance of the most top-left position from 0,0) 
# and the size of the world

var data: Array = [] setget set_data
var offset: Vector2 = Vector2.ZERO setget set_offset
var size: Vector2
var transform: Transform2D

func _init(init_object = null):
	# Loads the world differently depending on the 
	match typeof(init_object):
		TYPE_DICTIONARY:
			from_dict(init_object)
		TYPE_OBJECT:
			if init_object is TileMap:
				from_tilemap(init_object)

func set_data(new_data: Array):
	# Set new data
	data = new_data
	# Calculate new size
	var new_size = Vector2()
	new_size.x = new_data.size()
	for col in new_data:
		new_size.y = max(new_size.y, col.size())
	size = new_size

func set_offset(new_offset: Vector2):
	# Set new offset
	offset = new_offset
	# Calculate new tranform
	transform = Transform2D(0, new_offset)

# Returns a dictionnary compatible with JSON format for easier export
func to_dict():
	return {
		"data": data, 
		"offset": [offset.x, offset.y]
	}

# Setups an already initialized world from a dictionnary.
# Warning: Considers the data is valid. Make sure it is beforehand, 
# or you might end up crashing the simulation.
func from_dict(dict: Dictionary):
	set_data(dict.get("data"))
	set_offset(Vector2(dict["offset"][0], dict["offset"][1]))

# Setups an already initialized world from a tilemap
func from_tilemap(tilemap: TileMap):
	var new_data = []
	var used_rect = tilemap.get_used_rect()
	for i in range(used_rect.position.x, used_rect.end.x):
		var col = []
		for j in range(used_rect.position.y, used_rect.end.y):
			col.append(tilemap.get_cell(i,j))
		new_data.append(col)
	
	set_data(new_data)
	set_offset(used_rect.position)
