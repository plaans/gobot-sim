extends TileMap

onready var manager = TileManager.new(self)
onready var world = TileWorld.new(self)

var park_area_res = preload("res://Scenes/ParkingArea.tscn")
var interact_area_res = preload("res://Scenes/InteractArea.tscn")

const GROUP_SOLID = ["Wall", "Belt"]
const GROUP_PARKING = ["ChargingFloor"]
const GROUP_INTERACT = ["InteractionFloor"]
const GROUP_BELT = ["Belt"]
const GROUP_MACHINE = ["MachineSlot"]
# Called when the node enters the scene tree for the first time.
func _ready():
	# Make ParkingArea
	var new_park_area = park_area_res.instance()
	new_park_area.name = "ParkingArea "+str(new_park_area)
	for col_poly in collision_polys_from_group(GROUP_PARKING):
		new_park_area.add_child(col_poly)
	self.add_child(new_park_area)
	
	# Make multiple InteractAreas
	for col_poly in collision_polys_from_group(GROUP_INTERACT):
		var new_interact_area = interact_area_res.instance()
		new_interact_area.name = "InteractArea "+str(new_interact_area)
		new_interact_area.add_child(col_poly)
		self.add_child(new_interact_area)
	
	# Make Belt objects from
	var machine_cells = get_used_cells_by_group(GROUP_MACHINE)
	for cell in machine_cells:
		var new_belts := get_linked_belts(cell)

func collision_polys_from_group(tiles_group: Array)-> Array:
	# Usual process:
	# get_connected_cells_by_group() -> cells_to_polys() 
	# -> make_collision_polys()
	var cells_groups = manager.get_connected_cells_by_group(world, tiles_group)
	var new_polys = []
	for group in cells_groups:
		new_polys += manager.cells_to_polys(group)
	return PolyHelper.make_collision_polys(new_polys)

func get_linked_belts(machine_pos: Vector2)->Array:
	var belts = []
	for dir in manager.DIRS_4:
		pass
	return belts

func get_used_cells_by_group(group: Array)->Array:
	var ids = manager.get_ids_from_group(group)
	var used_cells := []
	for id in ids:
		used_cells += get_used_cells_by_id(id)
	return used_cells
