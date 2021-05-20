extends Navigation2D

export(NodePath) var world_map_path = "../WorldMap"
export var nav_margin : float = 20

onready var _WorldMap : TileMap = get_node_or_null(world_map_path)
var _NavpolyInstance: NavigationPolygonInstance = null

var static_navpoly: NavigationPolygon
var outline: PoolVector2Array
var shape_outlines: Array

# Called when the node enters the scene tree for the first time.
# Note: closed shapes don't have a navigation shape in the inside
func _ready():
	pass
	
func make_navigation():
	# The function fails if there is no _WorldMap defined
	if !_WorldMap:
		return
	
	# Cleanup the current navigation
	for child in get_children():
		# Clear all children
		child.queue_free()
	
	var manager: TileManager = _WorldMap.manager
	var world: TileWorld = _WorldMap.world

	# Usual process:
	# Step 1 - Get polys and outline from tilemap
	var new_outline: PoolVector2Array = manager.get_outline(world)
	var new_polys = []
	var cells_groups = manager.get_connected_cells_by_group(world, _WorldMap.GROUP_SOLID)
	for group in cells_groups:
		new_polys += manager.cells_to_polys(group)
	# Add other collision shapes if needed
	for node in get_tree().get_nodes_in_group("solid"):
		new_polys.append_array(PolyHelper.get_polys_from_collision_object(node))
	# Step 2 - Grow polys with nav_margin
	new_polys = PolyHelper.grow_polys(new_polys, nav_margin)
	# Step 3 - Merge polys
	new_polys = PolyHelper.merge_polys(new_polys)
	# Step 4 - Exclude polys from outline
	new_outline = PolyHelper.outline_exclude_polys(new_polys, new_outline)
	
	# Create the static NavigationPolygon
	outline = new_outline
	shape_outlines = new_polys
	static_navpoly = PolyHelper.make_navigation_poly(new_polys, new_outline)
	
	# Make NavigationPolygonInstance and set the static_navpoly as current NavigationPolygon
	_NavpolyInstance = NavigationPolygonInstance.new()
	set_navpoly(static_navpoly)
	add_child(_NavpolyInstance)

func cut_poly(poly: PoolVector2Array, deep: bool = false)->NavigationPolygon:
	var new_poly: NavigationPolygon = NavigationPolygon.new()
	var local_outline: PoolVector2Array = outline
	var local_shape_outlines: Array = shape_outlines.duplicate()
	
	local_shape_outlines.append(poly)
	# Skip steps 1 & 2
	# Step 3 - Merge polys
	local_shape_outlines = PolyHelper.merge_polys(local_shape_outlines)
	# Step 4 - Exclude polys from outline
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
	_NavpolyInstance.navpoly = new_navpoly

func reset_navpoly():
	_NavpolyInstance.navpoly = static_navpoly
