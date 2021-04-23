class_name TileWorld

# Data management class.
# Creates a view of the world's tiles as a 2-dimensional array,
# with an offset (distance of the most top-left position from 0,0) 
# and the size of the world

var data: Array setget set_data, get_data
var offset: Vector2 setget set_offset, get_offset
var size: Vector2 setget set_size, get_size

func _init(tilemap: TileMap = null):
	# If no tilemap has been given, skip initialization
	if !tilemap:
		return
		
	var used_rect = tilemap.get_used_rect()
	
	offset = used_rect.position
	size = used_rect.size
	data = []
	
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

func get_size()->Vector2:
	return size
func set_size(new_size: Vector2):
	size = new_size

# Returns a dictionnary compatible with JSON format for easier export
func to_dict():
	return {
		"data": data, 
		"offset": {
			"x": offset.x, 
			"y": offset.y
		}, 
		"size": {
			"x": size.x, 
			"y": size.y
		}
	}