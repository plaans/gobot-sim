extends Navigation2D

export var _WorldMapPath : NodePath
export var nav_margin : float = 10

onready var _WorldMap : TileMap = get_node(_WorldMapPath)

var current_navpoly_id: int
var static_transform: Transform2D
var static_navpoly: NavigationPolygon
var outline: PoolVector2Array
var shape_outlines: Array

# Called when the node enters the scene tree for the first time.
# Note: closed shapes don't have a navigation shape in the inside
func _ready():
	# Make NavigationPolygonInstance
#	var new_navpoly_instance = NavigationPolygonInstance.new()
	
	if _WorldMap:
		var manager: TileManager = _WorldMap.manager
		var world: TileWorld = _WorldMap.world
	
		# Usual process:
		# get_connected_cells_by_group() -> cells_to_polys()
		# -> grow_polys() -> merge_polys() -> outline_exclude_polys() -> make_navigation_poly()
		var new_outline: PoolVector2Array = manager.get_outline(world)
		
		var cells_groups = manager.get_connected_cells_by_group(world, _WorldMap.GROUP_SOLID)
		var new_polys = []
		for group in cells_groups:
			new_polys += manager.cells_to_polys(group)
		new_polys = PolyHelper.grow_polys(new_polys, nav_margin)
		new_polys = PolyHelper.merge_polys(new_polys)
		new_outline = PolyHelper.outline_exclude_polys(new_polys, new_outline)
		
		outline = new_outline
		shape_outlines = new_polys
		static_transform = Transform2D(0.0, world.offset)
		static_navpoly = PolyHelper.make_navigation_poly(new_polys, new_outline)
		current_navpoly_id = self.navpoly_add(static_navpoly, static_transform)
	
	
func cut_poly(poly: PoolVector2Array, deep: bool = false)->NavigationPolygon:
	var new_poly: NavigationPolygon = NavigationPolygon.new()
	var local_outline: PoolVector2Array = outline
	var local_shape_outlines: Array = shape_outlines.duplicate()
	
	local_shape_outlines.append(poly)
	# Skip Passes 1 & 2
	# Pass 3 - Merge
	local_shape_outlines = PolyHelper.merge_polys(local_shape_outlines)
	# Pass 4 - Exclude
	local_outline = PolyHelper.outline_exclude_polys(local_shape_outlines, local_outline)
	
	for poly in local_shape_outlines:
		new_poly.add_outline(poly)
	new_poly.add_outline(local_outline)
	new_poly.make_polygons_from_outlines()
	
	if deep:
		static_navpoly = new_poly
		outline = local_outline
		shape_outlines = local_shape_outlines
	
	return new_poly

func set_navpoly(new_navpoly):
	self.navpoly_remove(current_navpoly_id)
	current_navpoly_id = self.navpoly_add(new_navpoly, static_transform)

func reset_navpoly():
	self.navpoly_remove(current_navpoly_id)
	current_navpoly_id = self.navpoly_add(static_navpoly, static_transform)
