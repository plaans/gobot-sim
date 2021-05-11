class_name TileManager, "res://Assets/icons/TileManager.svg"

# Used for getting connected cells and their polygons

var tilemap: TileMap

const DIRS_4 = [
		Vector2.LEFT,
		Vector2.UP,
		Vector2.RIGHT,
		Vector2.DOWN
	]
const DIRS_8 = [
		Vector2.LEFT,
		Vector2(-1, -1),
		Vector2.UP,
		Vector2(1, -1),
		Vector2.RIGHT,
		Vector2(1, 1),
		Vector2.DOWN,
		Vector2(-1, 1)
	]

enum {
	CLOCKWISE,
	COUNTER_CLOCKWISE
}

func _init(tilemap: TileMap):
	self.tilemap = tilemap

# Given an array of tile names, returns the corresponding ids
func get_ids_from_group(group: Array)->Array:
	var ids = []
	for name in group:
		ids.append(tilemap.tile_set.find_tile_by_name(name))
		
	return ids

func get_used_cells_by_group(group: Array)->Array:
	var ids = get_ids_from_group(group)
	var used_cells := []
	for id in ids:
		used_cells += tilemap.get_used_cells_by_id(id)
	return used_cells

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
				# from world data coordinates to real coordinates
				connected_cells.append( cells_transform.xform( fill_cells(cells, Vector2(i,j), world.size, ids)))
	return connected_cells

# same as get_connected_cells_by_ids(), but using an array of tile names instead.
func get_connected_cells_by_group(world: TileWorld, group: Array)->Array:
	return get_connected_cells_by_ids(world, get_ids_from_group(group))


func get_adjacent_cells_by_ids(pos: Vector2, ids: Array)->Array:
	var adjacent_cells = []
	for dir in DIRS_4:
		if tilemap.get_cellv(pos+dir) in ids:
			adjacent_cells.append(pos+dir)
	return adjacent_cells

func get_adjacent_cells_by_group(pos: Vector2, group: Array)->Array:
	return get_adjacent_cells_by_ids(pos, get_ids_from_group(group))

# Given a TileWorld, returns a rectangular polygon as a PoolVector2Array encasing the whole used area.
func get_outline(world: TileWorld)->PoolVector2Array:
	return PoolVector2Array([
		world.offset * tilemap.cell_size,
		Vector2(world.offset.x, world.offset.y + world.size.y) * tilemap.cell_size,
		(world.offset + world.size) * tilemap.cell_size, 
		Vector2(world.offset.x + world.size.x, world.offset.y) * tilemap.cell_size,
	])

# Given an array of cell position, returns an array of 2-values arrays.
# This is used to transform a PoolVector2Array into a JSON-compatible structure
# Note: not recommended for big arrays of Vector2
func cells_to_arrays(cells: Array)->Array:
	var new_array = []
	for cell in cells:
		new_array.append([cell.x,cell.y])
	return new_array

# Given an array of cell positions, returns an array of polygons matching the cells, merged if intersecting.
# Note: if the tile in the cell doesn't have a collision shape defined, the polygon will be defined automatically
# as the cell size
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

# Given a TileWorld and a group of tiles to fill,
# returns the merged collision polys of connected tiles from this group.
func collision_polys_from_group(world: TileWorld, tiles_group: Array)-> Array:
	var cell_groups = get_connected_cells_by_group(world, tiles_group)
	return collision_polys_from_cell_groups(cell_groups)

# Given an array of group of tiles, returns the merged collision polys from the cells
func collision_polys_from_cell_groups(cell_groups: Array)-> Array:
	# Usual process:
	# cells_to_polys() -> make_collision_polys()
	var new_polys = []
	for group in cell_groups:
		new_polys += cells_to_polys(group)
	return PolyHelper.make_collision_polys(new_polys)

########## Fill functions ##########

# Given an array of cells, the current cell, the size of the area and an array of ids,
# returns true if the cell is in the area and its id is contained in the ids array, else returns false.
func is_cell_valid(cells: Array, pos: Vector2, size: Vector2, ids: Array)-> bool :
	return !(0 > pos.x or pos.x >= size.x or 0 > pos.y or pos.y >= size.y or !cells[pos.x][pos.y] in ids)

# Given an array of cells, a starting cell position, the size of the area and an array of ids,
# fills every connected cell with an id present in the ids array, and returns a PoolVector2Array with 
# the position of every filled cells.
# Note: the cells array is passed by reference and will be mutated
func fill_cells(cells: Array, start: Vector2, size: Vector2, ids: Array)->PoolVector2Array:
	var fill_id = -10
	var filled_cells = PoolVector2Array()
	
	var queue = []
	queue.append(start)
	filled_cells.append(start)
	cells[start.x][start.y] = fill_id
	
	while queue.size() > 0:
		for dir in DIRS_4:
			var new_pos = queue[0]+dir
			if is_cell_valid(cells, new_pos, size, ids):
				queue.append(new_pos)
				filled_cells.append(new_pos)
				cells[new_pos.x][new_pos.y] = fill_id
		queue.remove(0)
	
	return filled_cells

# Given an array of cells, the current cell, the size of the area and an array of ids,
# returns an array with the position of every adjacent cells with ids present in the ids array
func fill_adjacent_cells(cells: Array, pos: Vector2, size: Vector2, ids: Array)->Array:
	var fill_id = -10
	var filled_cells = []
	
	for dir in DIRS_4:
		var new_pos = pos+dir
		if is_cell_valid(cells, new_pos, size, ids):
			filled_cells.append(new_pos)
			cells[new_pos.x][new_pos.y] = fill_id
	
	return filled_cells

# Similar to fill_adjacent_cells, but only fills and returns the first cell.
# The priority can be used to get different results, but has no impact on the complexity
func fill_first_adjacent_cell(cells: Array, pos: Vector2, size: Vector2, ids: Array, priority: int = CLOCKWISE)->Vector2:
	var fill_id = -10
	var filled_cell = null
	var dirs = DIRS_4
	if priority == COUNTER_CLOCKWISE:
		dirs.invert()
	
	var i := 0
	while i < dirs.size() and !filled_cell:
		var new_pos = pos+dirs[i]
		if is_cell_valid(cells, new_pos, size, ids):
			filled_cell = new_pos
			cells[new_pos.x][new_pos.y] = fill_id
		i += 1
	
	return filled_cell

# Given an array of cells, a starting cell position, a direction to fill, the size of the area and an array of ids,
# fills a line of connected cell in the given direction, with an id present in the ids array, and returns
# a PoolVector2Array with the position of every filled cells.
# Note: the cells array is passed by reference and will be mutated
func fill_directional_cells(cells: Array, start: Vector2, dir: Vector2, size: Vector2, ids: Array)->PoolVector2Array:
	var fill_id = -10
	var filled_cells = PoolVector2Array()
	
	var queue = []
	queue.append(start)
	filled_cells.append(start)
	cells[start.x][start.y] = fill_id
	
	while queue.size() > 0:
		var new_pos = queue[0]+dir
		if is_cell_valid(cells, new_pos, size, ids):
			queue.append(new_pos)
			filled_cells.append(new_pos)
			cells[new_pos.x][new_pos.y] = fill_id
		queue.remove(0)
	
	return filled_cells

