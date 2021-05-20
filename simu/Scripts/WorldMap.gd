extends TileMap

onready var manager: TileManager = TileManager.new(self)
onready var world: TileWorld = TileWorld.new(self)

export(PackedScene) var park_area_scene = preload("res://Scenes/ParkingArea.tscn")
export(PackedScene) var interact_area_scene = preload("res://Scenes/InteractArea.tscn")
export(PackedScene) var machine_scene = preload("res://Scenes/Machines/Machine.tscn")
export(PackedScene) var input_machine_scene = preload("res://Scenes/Machines/InputMachine.tscn")
export(PackedScene) var output_machine_scene = preload("res://Scenes/Machines/OutputMachine.tscn")
export(PackedScene) var belt_scene = preload("res://Scenes/Belt.tscn")

const GROUP_SOLID = ["Wall", "InputBelt", "OutputBelt"]
const GROUP_PARKING = ["ChargingFloor"]
const GROUP_INTERACT = ["InteractionFloor"]
const GROUP_BELT = ["InputBelt", "OutputBelt"]
const GROUP_MACHINE = ["Machine", "InputMachine", "OutputMachine"]

var machines = []
var belts = []
var interact_areas = []
var parking_areas = []

enum BeltType {
	INPUT,
	OUTPUT
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the cell size property in export manager 
	ExportManager.set_tile_size(cell_size)
	

func make_environment():
	# The function fails if there is no world defined
	if !world:
		return
	
	# Cleanup the current environment
	machines.empty()
	belts.empty()
	interact_areas.empty()
	parking_areas.empty()
	for child in get_children():
		# Clear all children
		child.queue_free()
	
	# Create ParkingAreas
	make_parking_areas()
	# Create Machines, Belts and InteractAreas
	make_machines()

# Creates machine. at the position of the cells in the group GROUP_MACHINE and returns all the machines.
# Also creates the belts connected to each machine and links them.
func make_machines():
	for machine_cell in manager.get_used_cells_by_group(GROUP_MACHINE):
		# Create the right type of machine
		var new_machine
		match tile_set.tile_get_name(get_cellv(machine_cell)):
			"InputMachine":
				new_machine = input_machine_scene.instance()
			"OutputMachine":
				new_machine = output_machine_scene.instance()
			_:
				new_machine = machine_scene.instance()
		# Place the machine in the center of the cell
		new_machine.position = machine_cell*cell_size + cell_size/2
		add_child(new_machine)
		
		# Create the belts
		var new_belts = make_belts(machine_cell)
		new_machine.input_belt = new_belts[0]
		new_machine.output_belt = new_belts[1]
		
		machines.append(new_machine)

# Given a starting cell (machine_cell), returns an array of 2 belts: an input at index 0, an output at index 1.
# The goal of this function is to provide a reliable way to get exactly 1 belt of each type - as such,
# if there is more that 1 belt of a type connected to the machine, only the first one will be created.
# A machine can have no belt of a type connected, in this case the corresponding index will be null.
func make_belts(machine_cell: Vector2)->Array:
	var new_belts = [null, null]
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
		if type != -1 and !new_belts[type]:
			new_belts[type] = make_single_belt(machine_cell, belt_cell, id, type)
	return new_belts

# Given a start position, the next position, the id of tile to fill and a belt type, returns a single belt.
# The function uses the difference between the next and the start position as adirection to fill cells.
# Note: when encountering the end of the line, checking for the first adjacent cell will be made clockwise 
# from the left -> left, up, right, down
func make_single_belt(start: Vector2, next: Vector2, id: int, type: int):
	var belt_lines := []
	var cells: Array = world.data.duplicate(true)
	
	# Compute the visual line's points during fill
	var new_points = []
	# Fill directionnally, get first adjacent tile, repeat from there
	var pos = world.transform.xform_inv(start)
	var next_pos = world.transform.xform_inv(next)
	var dir: Vector2 = (next_pos-pos).normalized()
	new_points.append(map_to_world(world.transform.xform(pos)) + (cell_size/2)*(Vector2.ONE + dir))
	while next_pos:
		var new_line = manager.fill_directional_cells(cells, next_pos, dir, world.size, [id])
		if new_line.size() > 0:
			belt_lines.append(world.transform.xform(new_line))
			pos = new_line[-1]
			next_pos = manager.fill_first_adjacent_cell(cells, pos, world.size, [id])
			if next_pos:
				dir = (next_pos-pos).normalized()
				new_points.append(map_to_world(world.transform.xform(pos)) + (cell_size/2))
			else:
				new_points.append(map_to_world(world.transform.xform(pos)) + (cell_size/2)*(Vector2.ONE + dir))
		else:
			next_pos = null
	
	# Calculate belt's size from number of tiles
	var new_size := 0
	for line in belt_lines:
		new_size += line.size()

	# Create the Belt object itself
	var new_belt = belt_scene.instance()
	new_belt.size = new_size
	new_belt.belt_type = type
	new_belt.line_points = new_points
	
	# Make the collision poly
	var col_polys = manager.collision_polys_from_cell_groups(belt_lines)
	for col_poly in col_polys:
		new_belt.add_child(col_poly)
	
	# Make the InteractAreas
	make_interact_area(belt_lines, new_belt)
	
	new_belt.cells = manager.cell_groups_to_cells(belt_lines)
	new_belt.polys = PolyHelper.get_polys_from_collision_object(new_belt)
	
	add_child(new_belt)
	
	belts.append(new_belt)
	return new_belt

# Given an array containing the cells of the belt, returns an array of InteractAreas.
# 
func make_interact_area(belt_lines: Array, belt: Node):
	# Get the cell groups attached to the belt
	var new_groups = manager.get_connected_cells_to_groups_by_group(world, belt_lines, GROUP_INTERACT)
	# Create all the collision polys from the cell groups
	var col_polys = manager.collision_polys_from_cell_groups(new_groups)
	
	var new_interact_area = interact_area_scene.instance()
	new_interact_area.belt = belt
	belt.interact_areas.append(new_interact_area)
	
	# Add multiple collision polys to the area
	for col_poly in col_polys:
		new_interact_area.add_child(col_poly)
	add_child(new_interact_area)
	
	new_interact_area.cells = manager.cell_groups_to_cells(new_groups)
	new_interact_area.polys = PolyHelper.get_polys_from_collision_object(new_interact_area)
	
	interact_areas.append(new_interact_area)

func make_parking_areas():
	# Get cell groups of ParkingArea
	var new_groups = manager.get_connected_cells_by_group(world, GROUP_PARKING)
	# Create all the collision polys from the cell groups
	var col_polys = manager.collision_polys_from_cell_groups(new_groups)
	
	# Create new ParkingArea
	var new_park_area = park_area_scene.instance()
	# Add multiple collision polys to the area
	for col_poly in col_polys:
		new_park_area.add_child(col_poly)
	add_child(new_park_area)
	
	new_park_area.cells = manager.cell_groups_to_cells(new_groups)
	new_park_area.polys = PolyHelper.get_polys_from_collision_object(new_park_area)
	
	parking_areas.append(new_park_area)
