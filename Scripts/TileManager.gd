class_name TileManager, "res://Assets/icons/TileManager.svg"

var tilemap: TileMap

func _init(tilemap: TileMap):
	self.tilemap = tilemap

func get_ids_from_group(group: Array)->Array:
	var ids = []
	for name in group:
		ids.append(tilemap.tile_set.find_tile_by_name(name))
		
	return ids

func get_connected_cells_by_group(world: TileWorld, group: Array)->Array:
	return get_connected_cells_by_ids(world, get_ids_from_group(group))
	
func get_connected_cells_by_ids(world: TileWorld, ids: Array)->Array:
	var connected_cells = []
	var cells = world.data.duplicate()
	var cells_transform = Transform2D(0, world.offset)
	
	for i in range(world.size.x):
		for j in range(world.size.y):
			if cells[i][j] in ids:
				connected_cells.append( cells_transform.xform( fill_cells(cells, Vector2(i,j), world.size, ids)))
	
	return connected_cells

func get_outline(world: TileWorld):
	return PoolVector2Array([
		world.offset * tilemap.cell_size, 
		Vector2(world.offset.x, world.offset.y + world.size.y) * tilemap.cell_size,
		(world.offset + world.size) * tilemap.cell_size, 
		Vector2(world.offset.x + world.size.x, world.offset.y) * tilemap.cell_size,
	])

# given an array of cells, returns an array of polygons
func merge_cells_polys(cells: PoolVector2Array)->Array:
	var cells_polys = []
	for cell in cells:
		# get each tile's shape then merge them
		#
		# https://www.youtube.com/watch?v=uzqRjEoBcTI
		# https://github.com/godotengine/godot/issues/1887#issuecomment-495317178
		var id = tilemap.get_cellv(cell)
		var tilemap_offset = tilemap.map_to_world(cell)
		var tile_transform = tilemap.tile_set.tile_get_shape_transform(id, 0).translated(tilemap_offset)
		var tile_poly = tilemap.tile_set.tile_get_shape(id, 0).get_points()
		tile_poly = tile_transform.xform(tile_poly)
		
		cells_polys.append(tile_poly)
	
	return PolyHelper.merge_polys(cells_polys)

func is_cell_valid(cells: Array, pos: Vector2, size: Vector2, ids: Array)-> bool :
	return !(0 > pos.x or pos.x >= size.x or 0 > pos.y or pos.y >= size.y or !cells[pos.x][pos.y] in ids)

# Note: the cells array is passed by reference and will be mutated
func fill_cells(cells: Array, start: Vector2, size: Vector2, ids: Array)->PoolVector2Array:
	var fill_id = -10
	var filled_cells = PoolVector2Array()
	
	var queue = []
	var dirs = [
		Vector2.LEFT, 
		Vector2.RIGHT, 
		Vector2.UP, 
		Vector2.DOWN
	]
	queue.append(start)
	filled_cells.append(start)
	cells[start.x][start.y] = fill_id
	
	while queue.size() > 0:
		for dir in dirs:
			var new_pos = queue[0]+dir
			if(is_cell_valid(cells, new_pos, size, ids)):
				queue.append(new_pos)
				filled_cells.append(new_pos)
				cells[new_pos.x][new_pos.y] = fill_id
		queue.remove(0)
	
	return filled_cells
