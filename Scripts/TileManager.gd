class_name TileManager, "res://Assets/icons/TileManager.svg"

# Used for getting connected cells, and create collision and navigation polygons from them

var tilemap: TileMap

func _init(tilemap: TileMap):
	self.tilemap = tilemap

# Given an array of tile names, returns the corresponding ids
func get_ids_from_group(group: Array)->Array:
	var ids = []
	for name in group:
		ids.append(tilemap.tile_set.find_tile_by_name(name))
		
	return ids

# Given a TileWorld and an array of ids, returns an array containing the groups of connected cells
# with the given ids.
# Note: the groups of cells are PoolVector2Arrays, containing all the cell's positions
func get_connected_cells_by_ids(world: TileWorld, ids: Array)->Array:
	var connected_cells = []
	var cells = world.data.duplicate(true)
	var cells_transform = Transform2D(0, world.offset)
	
	for i in range(world.size.x):
		for j in range(world.size.y):
			if cells[i][j] in ids:
				connected_cells.append( cells_transform.xform( fill_cells(cells, Vector2(i,j), world.size, ids)))
	
	return connected_cells

# same as get_connected_cells_by_ids(), but using an array of tile names instead.
func get_connected_cells_by_group(world: TileWorld, group: Array)->Array:
	return get_connected_cells_by_ids(world, get_ids_from_group(group))

# given a TileWorld, returns a rectangular polygon as a PoolVector2Array encasing the whole used area.
func get_outline(world: TileWorld)->PoolVector2Array:
	return PoolVector2Array([
		world.offset * tilemap.cell_size,
		Vector2(world.offset.x, world.offset.y + world.size.y) * tilemap.cell_size,
		(world.offset + world.size) * tilemap.cell_size, 
		Vector2(world.offset.x + world.size.x, world.offset.y) * tilemap.cell_size,
	])

# given an array of cell positions, returns an array of polygons matching the cells, merged if intersecting.
func cells_to_polys(cells: PoolVector2Array)->Array:
	var cells_polys = []
	var replacement_shape = PoolVector2Array([
		tilemap.cell_size,
		Vector2(0, tilemap.cell_size.y),
		Vector2.ZERO,
		Vector2(tilemap.cell_size.x,0)
	])
	
	for cell in cells:
		# get each tile's shape then merge them
		#
		# https://www.youtube.com/watch?v=uzqRjEoBcTI
		# https://github.com/godotengine/godot/issues/1887#issuecomment-495317178
		var id = tilemap.get_cellv(cell)
		var tilemap_offset = tilemap.map_to_world(cell)
		var tile_transform = tilemap.tile_set.tile_get_shape_transform(id, 0).translated(tilemap_offset)
		var tile_shape = tilemap.tile_set.tile_get_shape(id, 0)
		var tile_poly
		if tile_shape:
			tile_poly = tile_shape.get_points()
		else:
			tile_poly = replacement_shape
		tile_poly = tile_transform.xform(tile_poly)
		
		cells_polys.append(tile_poly)
	
	return PolyHelper.merge_polys(cells_polys)

# Given an array of cells, the current cell, the size of the area to fill and an array of ids,
# returns true if the cell is in the area and its id is contained in the ids array, else returns false.
func is_cell_valid(cells: Array, pos: Vector2, size: Vector2, ids: Array)-> bool :
	return !(0 > pos.x or pos.x >= size.x or 0 > pos.y or pos.y >= size.y or !cells[pos.x][pos.y] in ids)

# Given an array of cells, a starting cell position, the size of the area to fill and an array of ids,
# fills every connected cell with an id present in the ids array and returns a PoolVector2Array with 
# the position of every filled cells.
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
