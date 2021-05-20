class_name TileWorld

# Data management class.
# Creates a view of the world's tiles as a 2-dimensional array,
# with an offset (distance of the most top-left position from 0,0) 
# and the size of the world

var data: Array = [] setget set_data
var offset: Vector2 = Vector2.ZERO setget set_offset
var size: Vector2 = Vector2.ZERO setget set_size
var transform: Transform2D setget set_transform

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

func set_data(new_data: Array):
	data = new_data

func set_offset(new_offset: Vector2):
	offset = new_offset
	transform = Transform2D(0, new_offset)

func set_size(new_size: Vector2):
	size = new_size

func set_transform(new_transform: Transform2D):
	transform = new_transform

# Returns a dictionnary compatible with JSON format for easier export
func to_dict():
	return {
		"data": data, 
		"offset": [offset.x, offset.y], 
		"size": [size.x, size.y]
	}

# Setups an already initialized world from a dictionnary.
# Warning: Considers the data is valid. Make sure it is beforehand, 
# or you might end up crashing the simulation.
func from_dict(dict: Dictionary):
	data = dict.get("data")
	offset = Vector2(dict["offset"][0], dict["offset"][1])
	size = Vector2(dict["size"][0], dict["size"][1])
