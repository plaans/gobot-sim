extends TileMap

onready var manager = TileManager.new(self)
onready var world = TileWorld.new(self)

var park_area_res = preload("res://Scenes/Parking_Area.tscn")

const GROUP_SOLID = ["Wall", "Belt"]
const GROUP_PARKING = ["ChargingFloor"]
# Called when the node enters the scene tree for the first time.
func _ready():
	# Make ParkingArea
	var new_park_area = park_area_res.instance()
	
	# Usual process:
	# get_connected_cells_by_group() -> cells_to_polys() -> make_collision_polys()
	var cells_groups = manager.get_connected_cells_by_group(world, GROUP_PARKING)
	var new_polys = []
	for group in cells_groups:
		new_polys += manager.cells_to_polys(group)
	var collision_polys = PolyHelper.make_collision_polys(new_polys)
	
	for col_poly in collision_polys:
		new_park_area.add_child(col_poly)
	
	self.add_child(new_park_area)
	
	
