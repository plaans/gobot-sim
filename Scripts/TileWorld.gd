class_name TileWorld

var data: Array
var offset: Vector2
var size: Vector2

func _init(tilemap: TileMap):
	var used_rect = tilemap.get_used_rect()
	
	offset = used_rect.position
	size = used_rect.size
	data = []
	
	for i in range(used_rect.position.x, used_rect.end.x):
		var col = []
		for j in range(used_rect.position.y, used_rect.end.y):
			col.append(tilemap.get_cell(i,j))
		data.append(col)

func get_data():
	return data
func get_size():
	return size
func get_offset():
	return offset
	
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
