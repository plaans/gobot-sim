extends TileMap

onready var manager = TileManager.new(self)
onready var world = TileWorld.new(self)

var park_area_res = preload("res://Scenes/ParkingArea.tscn")
var interact_area_res = preload("res://Scenes/InteractArea.tscn")
var machine_res = preload("res://Scenes/Machine.tscn")

const GROUP_SOLID = ["Wall", "InputBelt", "OutputBelt"]
const GROUP_PARKING = ["ChargingFloor"]
const GROUP_INTERACT = ["InteractionFloor"]
const GROUP_BELT = ["InputBelt", "OutputBelt"]
const GROUP_MACHINE = ["Machine"]
# Called when the node enters the scene tree for the first time.
func _ready():
	# Make ParkingArea
	var new_park_area = park_area_res.instance()
	new_park_area.name = "ParkingArea "+str(new_park_area)
	for col_poly in manager.collision_polys_from_group(world, GROUP_PARKING):
		new_park_area.add_child(col_poly)
	self.add_child(new_park_area)
	
	# Make multiple InteractAreas
	for col_poly in manager.collision_polys_from_group(world, GROUP_INTERACT):
		var new_interact_area = interact_area_res.instance()
		new_interact_area.name = "InteractArea "+str(new_interact_area)
		new_interact_area.add_child(col_poly)
		self.add_child(new_interact_area)
	
	make_machines()

func make_machines():
	# Make Machines
	var machine_cells = manager.get_used_cells_by_group(GROUP_MACHINE)
	print(machine_cells)
	for cell in machine_cells:
		var new_pos = cell*cell_size + cell_size/2
		var new_machine = machine_res.instance()
		new_machine.position = new_pos
		add_child(new_machine)
		
	
