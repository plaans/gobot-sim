extends Navigation2D

export var _WorldMapPath : NodePath
export var nav_margin : float = 10

onready var _NavPolyInstance : NavigationPolygonInstance = $NavigationPolygonInstance
onready var _WorldMap : TileMap = get_node(_WorldMapPath)

var static_poly: NavigationPolygon
var outline: PoolVector2Array
var shape_outlines: Array

# Called when the node enters the scene tree for the first time.
# Note: closed shapes don't have a navigation shape in the inside
func _ready():
	if _WorldMap:
		var solid_tiles = ["Wall","Belt"]
		var ids = PoolIntArray()
		for tile_name in solid_tiles:
			ids.append(_WorldMap.tile_set.find_tile_by_name(tile_name))
		
		var polygon = NavigationPolygon.new()
		var used_rect = _WorldMap.get_used_rect()

		outline = PoolVector2Array([
			used_rect.position*_WorldMap.cell_size, 
			Vector2(used_rect.position.x, used_rect.end.y)*_WorldMap.cell_size,
			used_rect.end*_WorldMap.cell_size,
			Vector2(used_rect.end.x, used_rect.position.y)*_WorldMap.cell_size
		])
		outline = Geometry.offset_polygon_2d(outline, -nav_margin)[0]
		
		shape_outlines = []
		var tiles_packs = get_connected_cells(ids, _WorldMap)
		for tiles in tiles_packs:
			var is_on_edge = false
			var new_poly = PoolVector2Array()
			for tile in tiles:
				# get each tile's shape then inflate the poly
				#
				# https://www.youtube.com/watch?v=uzqRjEoBcTI
				# https://github.com/godotengine/godot/issues/1887#issuecomment-495317178
				var id = _WorldMap.get_cellv(tile)
				var tilemap_offset = _WorldMap.map_to_world(tile)
				var tile_transform = _WorldMap.tile_set.tile_get_shape_transform(id, 0).translated(tilemap_offset)
				var tile_poly = _WorldMap.tile_set.tile_get_shape(id, 0).get_points()
				tile_poly = tile_transform.xform(tile_poly)
				
				# Pass 2 - Grow
				tile_poly = Geometry.offset_polygon_2d(tile_poly, nav_margin)[0]
				# Pass 1 - Group
				new_poly = Geometry.merge_polygons_2d(new_poly, tile_poly)[0]
			
			shape_outlines.append(new_poly)
		
		# Pass 3 - Merge
		shape_outlines = merge_polys(shape_outlines)
		# Pass 4 - Exclude
		outline = outline_exclude_polys(shape_outlines, outline)
		
		for poly in shape_outlines:
			polygon.add_outline(poly)
		polygon.add_outline(outline)
		polygon.make_polygons_from_outlines()
		static_poly = polygon
		_NavPolyInstance.navpoly = polygon

func get_connected_cells(ids: PoolIntArray, tilemap: TileMap):
	var world = []
	var cell_blocks = [] # to return
	var used_rect = _WorldMap.get_used_rect()
	
	for i in range(used_rect.position.x, used_rect.end.x):
		var col = PoolIntArray()
		for j in range(used_rect.position.y, used_rect.end.y):
			col.append(tilemap.get_cell(i,j))
		world.append(col)
	
	for i in range(world.size()):
		for j in range(world[0].size()):
			if world[i][j] in ids:
				cell_blocks.append(fill_cells(world, Vector2(i,j), ids))
	
	return cell_blocks

func is_cell_valid(world: Array,  pos: Vector2, size: Vector2, ids: PoolIntArray)-> bool :
	return !(0 > pos.x or pos.x >= size.x or 0 > pos.y or pos.y >= size.y or !world[pos.x][pos.y] in ids)

func fill_cells(world: Array, start: Vector2, ids: PoolIntArray, fill_id = -10)->PoolVector2Array:
	# world est passé par référence
	var return_array = PoolVector2Array()
	
	var size = Vector2(world.size(), world[0].size())
	var queue = PoolVector2Array()
	var dirs = PoolVector2Array([
		Vector2.LEFT, 
		Vector2.RIGHT, 
		Vector2.UP, 
		Vector2.DOWN
	])
	queue.append(start)
	return_array.append(start)
	world[start.x][start.y] = fill_id
	
	while queue.size() > 0:
		for dir in dirs:
			var new_pos = queue[0]+dir
			if(is_cell_valid(world, new_pos, size, ids)):
				queue.append(new_pos)
				return_array.append(new_pos)
				world[new_pos.x][new_pos.y] = fill_id
		queue.remove(0)
	
	return return_array
	
	
func cut_poly(poly: PoolVector2Array, deep: bool = false)->NavigationPolygon:
	var new_poly: NavigationPolygon = NavigationPolygon.new()
	var local_outline: PoolVector2Array = outline
	var local_shape_outlines: Array = shape_outlines.duplicate()
	
	local_shape_outlines.append(poly)
	# Skip Passes 1 & 2
	# Pass 3 - Merge
	local_shape_outlines = merge_polys(local_shape_outlines)
	# Pass 4 - Exclude
	local_outline = outline_exclude_polys(local_shape_outlines, local_outline)
	
	for poly in local_shape_outlines:
		new_poly.add_outline(poly)
	new_poly.add_outline(local_outline)
	new_poly.make_polygons_from_outlines()
	
	if deep:
		static_poly = new_poly
		outline = local_outline
		shape_outlines = local_shape_outlines
	
	return new_poly

func merge_polys(polys: Array)->Array:
	var new_polys = []
	var old_polys = polys.duplicate()
	
	while old_polys.size() > 0:
		var current_poly = old_polys[0]
		old_polys.remove(0)
		
		var i: int = 0
		while i < old_polys.size():
			if Geometry.intersect_polygons_2d(current_poly, old_polys[i]).size() > 0:
				current_poly = Geometry.merge_polygons_2d(current_poly, old_polys[i])[0]
				old_polys.remove(i)
				i = 0
			else:
				i += 1
		new_polys.append(current_poly)
	
	return new_polys

# Careful: polys is passed by reference
func outline_exclude_polys(polys: Array, outline: PoolVector2Array)->PoolVector2Array:
	var new_outline = outline
	
	var i: int = 0
	while i < polys.size():
		if Geometry.clip_polygons_2d(polys[i], new_outline).size() > 0:
			new_outline = Geometry.clip_polygons_2d(new_outline, polys[i])[0]
			polys.remove(i)
			i = 0
		else:
			i += 1
	
	return new_outline
