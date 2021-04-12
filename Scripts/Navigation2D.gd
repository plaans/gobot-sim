extends Navigation2D

export var _WorldMapPath : NodePath

onready var _NavPolyInstance : NavigationPolygonInstance = $NavigationPolygonInstance
onready var _WorldMap : TileMap = get_node(_WorldMapPath)

# Called when the node enters the scene tree for the first time.
func _ready():
	if _WorldMap:
		var solid_tiles = ["Wall", "Belt"]
		var polygon = NavigationPolygon.new()
		var used_rect = _WorldMap.get_used_rect()
		
		var outline = PoolVector2Array([
			used_rect.position, 
			Vector2(used_rect.position.x, used_rect.end.y),
			Vector2(used_rect.end.x, used_rect.position.y),
			used_rect.end
		])
		polygon.add_outline(outline)
		
		for tile_name in solid_tiles:
			var id = _WorldMap.tileset.find_tile_by_name(tile_name)
			var used_tiles = _WorldMap.get_used_cells_by_id(id)
			for tile in used_tiles:
				pass
				# TODO: get each tile's shape then deflate the polys
				# Geometry.offset_polygon_2d(polygon, -10)
				#
				# https://www.youtube.com/watch?v=uzqRjEoBcTI
				# https://github.com/godotengine/godot/issues/1887#issuecomment-495317178
		
		polygon.make_polygons_from_outlines()
		_NavPolyInstance.navpoly = polygon

