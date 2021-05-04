extends TileMap

onready var manager = TileManager.new(self)
onready var world = TileWorld.new(self)

var park_area_res = preload("res://Scenes/ParkingArea.tscn")
var interact_area_res = preload("res://Scenes/InteractArea.tscn")
var machine_res = preload("res://Scenes/Machine.tscn")
var belt_res = preload("res://Scenes/Belt.tscn")

const GROUP_SOLID = ["Wall", "InputBelt", "OutputBelt"]
const GROUP_PARKING = ["ChargingFloor"]
const GROUP_INTERACT = ["InteractionFloor"]
const GROUP_BELT = ["InputBelt", "OutputBelt"]
const GROUP_MACHINE = ["Machine"]

enum BeltType {
	INPUT,
	OUTPUT
}

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
	
	# Make the machines
	var machines = make_machines()

# Creates machine. at the position of the cells in the group GROUP_MACHINE and returns all the machines.
# Also creates the belts connected to each machine and links them.
func make_machines()->Array:
	var machines = []
	for machine_cell in manager.get_used_cells_by_group(GROUP_MACHINE):
		# Place the machine in the center of the cell
		var new_pos = machine_cell*cell_size + cell_size/2
		var new_machine = machine_res.instance()
		new_machine.position = new_pos
		add_child(new_machine)
		
		var belts = make_belts(machine_cell)
		new_machine.input_belt = belts[0]
		new_machine.output_belt = belts[1]
		
		machines.append(new_machine)
	return machines

# Given a starting cell (machine_cell), returns an array of 2 belts: an input at index 0, an output at index 1.
# The goal of this function is to provide a reliable way to get exactly 1 belt of each type - as such,
# if there is more that 1 belt of a type connected to the machine, only the first one will be created.
# A machine can have no belt of a type connected, in this case the corresponding index will be null.
func make_belts(machine_cell: Vector2)->Array:
	var belts = [null, null]
	for belt_cell in manager.get_adjacent_cells_by_group(machine_cell, GROUP_BELT):
		var id: int = get_cellv(belt_cell)
		# Check for the type of the cell
		var type = -1
		match tile_set.tile_get_name(id):
			"InputBelt":
				type = BeltType.INPUT
			"OutputBelt":
				type = BeltType.OUTPUT
		# If the type is invalid or alredy set, don't create a belt
		if type != -1 and !belts[type]:
			belts[type] = make_single_belt(machine_cell, belt_cell, id, type)
	return belts

# Given a start position, the next position, the id of tile to fill and a belt type, returns a single belt.
# The function uses the difference between the next and the start position as adirection to fill cells.
# Note: when encountering the end of the line, checking for the first adjacent cell will be made clockwise 
# from the left -> left, up, right, down
func make_single_belt(start: Vector2, next: Vector2, id: int, type: int):
	var belt_lines := []
	var cells: Array = world.data.duplicate(true)
	var cell_transform := Transform2D(0, world.offset)
	
	# Fill directionnally, get first adjacent tile, repeat from there
	var pos = cell_transform.xform(start)
	var next_pos = cell_transform.xform(next)
	while next_pos:
		var new_line = manager.fill_directional_cells(cells, next_pos, next_pos-pos, world.size, [id])
		if new_line.size() > 0:
			belt_lines.append(new_line)
			pos = new_line[-1]
			next_pos = manager.fill_first_adjacent_cell(cells, pos, world.size, [id])
		else:
			next_pos = null
	
	# Compute the visual line's points
	var new_points = []
	var i := 0
	while i < belt_lines.size():
		if i == 0:
			new_points.append(map_to_world(cell_transform.xform_inv(belt_lines[i][0])) + cell_size/2)
		new_points.append(map_to_world(cell_transform.xform_inv(belt_lines[i][-1])) + cell_size/2)
		i += 1 # Well, of course it gets stuck if you forget this !
	# Create the Belt object itself
	var new_belt = belt_res.instance()
	new_belt.belt_type = type
	new_belt.line_points = new_points
	add_child(new_belt)
	
	return new_belt
	
