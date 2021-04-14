extends Navigation2D

export var _WorldMapPath : NodePath
export var nav_margin : float = 10

onready var _NavPolyInstance : NavigationPolygonInstance = $NavigationPolygonInstance
onready var _WorldMap : TileMap = get_node(_WorldMapPath)

# Called when the node enters the scene tree for the first time.
func _ready():
	if _WorldMap:
		var solid_tiles = ["Wall","Belt"]
		var polygon = NavigationPolygon.new()
		var used_rect = _WorldMap.get_used_rect()

		var outline = PoolVector2Array([
			used_rect.position*_WorldMap.cell_size, 
			Vector2(used_rect.position.x, used_rect.end.y)*_WorldMap.cell_size,
			used_rect.end*_WorldMap.cell_size,
			Vector2(used_rect.end.x, used_rect.position.y)*_WorldMap.cell_size
		])
		outline = Geometry.offset_polygon_2d(outline, -nav_margin)[0]
		
		var ids = PoolIntArray()
		for tile_name in solid_tiles:
			ids.append(_WorldMap.tile_set.find_tile_by_name(tile_name))
		var tiles_packs = get_connected_cells(ids, _WorldMap)
		
		for tiles in tiles_packs:
			var is_on_edge = false
			var new_poly = PoolVector2Array()
			for tile in tiles:
				var id = _WorldMap.get_cellv(tile)
				var tilemap_offset = _WorldMap.map_to_world(tile)
				var tile_transform = _WorldMap.tile_set.tile_get_shape_transform(id, 0).translated(tilemap_offset)
				var tile_poly = _WorldMap.tile_set.tile_get_shape(id, 0).get_points()
				tile_poly = tile_transform.xform(tile_poly)
				tile_poly = Geometry.offset_polygon_2d(tile_poly, nav_margin)[0]
				
				if is_cell_on_edges(tile, used_rect.size):
					is_on_edge = true
					
				new_poly = Geometry.merge_polygons_2d(new_poly, tile_poly)[0]
			
			#new_poly = Geometry.offset_polygon_2d(new_poly, nav_margin)[0]
			if is_on_edge:
				outline = Geometry.clip_polygons_2d(outline, new_poly)[0]
			else:
				polygon.add_outline(new_poly)

			# get each tile's shape then inflate the poly
			#
			# https://www.youtube.com/watch?v=uzqRjEoBcTI
			# https://github.com/godotengine/godot/issues/1887#issuecomment-495317178
		polygon.add_outline(outline)
		polygon.make_polygons_from_outlines()
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
				cell_blocks.append(fill(world, Vector2(i,j), ids))
	
	return cell_blocks

func is_cell_on_edges(pos: Vector2, size:Vector2):
	return (pos.x == 0 or pos.x == size.x-1 or pos.y == 0 or pos.y == size.y-1)

func is_cell_valid(world: Array,  pos: Vector2, size: Vector2, ids: PoolIntArray)-> bool :
	return !(0 > pos.x or pos.x >= size.x or 0 > pos.y or pos.y >= size.y or !world[pos.x][pos.y] in ids)

func fill(world: Array, start: Vector2, ids: PoolIntArray, fill_id = -10)->PoolVector2Array:
	# world est passé par référence
	var return_array = PoolVector2Array()
	
	var size = Vector2(world.size(), world[0].size())
	var queue = PoolVector2Array()
	var dirs = PoolVector2Array([
		Vector2.LEFT, 
		Vector2.RIGHT, 
		Vector2.UP, 
		Vector2.DOWN, 
		Vector2(-1, -1), 
		Vector2(-1, 1), 
		Vector2(1, 1), 
		Vector2(1, -1)
	])
	queue.append(start)
	
	while queue.size() > 0:
		for dir in dirs:
			var new_pos = queue[0]+dir
			if(is_cell_valid(world, new_pos, size, ids)):
				world[new_pos.x][new_pos.y] = fill_id
				queue.append(new_pos)
				return_array.append(new_pos)
		queue.remove(0)
	
	return return_array
	
	
