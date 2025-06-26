extends StaticBody2D

# A belt that needs to be linked to a machine to work.
# The link to the machine is only logical and does not affect the hierarchy of the scene.
# Linking is done from the machine, by setting this node as an input or output belt.
# To make the belt itself, set the size and the line points at any time.
#
# belt_type affects the visual direction of the belt and the way packages are accepted


enum BeltType {
	INPUT,
	OUTPUT
}

export var size : int = 1 setget set_size # slots
export var visual_speed: float = 1.0 setget set_visual_speed # slot/s

var belt_type: int = BeltType.INPUT setget set_belt_type
var packages: Array = []
var machine: Node = null # reference to the machine the belt is linked to
var line_points: PoolVector2Array setget set_line_points
# Points used to make the line and the path

onready var _PackagePath = $PackagePath
onready var _VisualLine = $Line2D

var cells : Array #contains the cells of the belt
var polys : Array

var interact_areas : Array

var belt_name : String

func _ready():
	# At the start of the simulation, make the line if there are points already set
	if line_points:
		setup_line()
	
	_VisualLine.material.set_shader_param("speed", visual_speed)

	#generate a name 
	belt_name = ExportManager.register_new_node(self, "belt")
	
	ExportManager.add_export_static(self)
	ExportManager.add_export_dynamic(self)
	
func get_name() -> String:
	return belt_name

func set_size(new_size: int):
	size = new_size

func set_belt_type(new_type: int):
	belt_type = new_type
	match belt_type:
		BeltType.INPUT:
			add_to_group("input")
		BeltType.OUTPUT:
			add_to_group("output")

func set_visual_speed(new_visual_speed: float):
	visual_speed = new_visual_speed
	# in case the Line2D isn't loaded yet
	if _VisualLine:
		_VisualLine.material.set_shader_param("speed", visual_speed)

func set_line_points(new_points: PoolVector2Array):
	line_points = new_points
	setup_line()

func is_full():
	return packages.size() >= size
func is_empty():
	return packages.size() == 0

# Note: must be called after node entered the tree, or it will not have any effect
func setup_line():
	# Skip function if the node has not entered the scene tree, or if there are
	# no line_points specified
	if !is_inside_tree() or !line_points:
		return
	
	var new_points = line_points
	var new_curve = Curve2D.new()
	# The belt is caculated starting from the machine, and so the order 
	# of the points needs to be inverted if the belt_type is an OUTPUT
	if belt_type == BeltType.OUTPUT:
		new_points.invert()
	
	_VisualLine.points = new_points
	for point in new_points:
		new_curve.add_point(point)
	_PackagePath.curve = new_curve

# Used called by a robot or a machine trying to place a package on the belt.
# If the belt is full return false, else return true
# If the belt is an input, check if the linked machine accepts the package and
# return the result.
func can_accept_package(package: Node)->bool:
	if is_full():
		return false
	elif machine and belt_type == BeltType.INPUT:
		return machine.match_process(package)
	else:
		return true

# Adds the given package at the end of the packages array
func add_package(package: Node):
	var slot: float = packages.size()
	packages.append(package)
	package.get_parent().remove_child(package)
	_PackagePath.add_child(package)
	
	package.position = Vector2.ZERO
	package.unit_offset = 1.0
	move_package_offset(package, slot/size + 0.5/size)

# Removes a package at the given index, and returns the removed package.
# In case of failure, returns null
func remove_package(index: int = 0)->Node:
	var old_package: Node = null
	if packages.size() > 0:
		old_package = packages[index]
		packages.remove(index)
	# Skips moving packages if no package was removed
	if old_package:
		old_package.get_parent().remove_child(old_package)
		var slot := wrapf(index, 0, packages.size()-1)
		while old_package and slot < packages.size():
			move_package_offset(packages[slot], slot/size + 0.5/size)
			slot += 1
	
	return old_package
	
func find_package_index(package: Node) -> int:
	var i = 0
	var result = -1
	for p in packages:
		if p == package:
			result = i
			break
		i=i+1
	return result

# Interpolate a Package's offset on the belt between its current offset and the given offset
# Note: this is only visual and does not affect the availability of a package
func move_package_offset(package: PathFollow2D, new_offset: float):
	var tween = $Tween
	var duration: float = 0.0
	if visual_speed != 0.0:
		duration = 1.0/visual_speed
	tween.remove(package, "unit_offset")
	tween.interpolate_property(package, "unit_offset", package.unit_offset, new_offset, duration)
	if !tween.is_active():
		tween.start()
		
func get_packages_names() -> Array:
	#returns Array containing name of all packages on the belt
	var names_array = []
	for package in packages:
		names_array.append(package.get_name())
	return names_array
	
func get_interact_areas_names() -> Array:
	#returns Array containing name of all interact areas associated with this belt
	var names_array = []
	for interact_area in interact_areas:
		names_array.append(interact_area.get_name())
	return names_array	
		
func export_static() -> Array:
	var export_data = []
	export_data.append(["Belt.instance", belt_name, "belt"])
	
	var belt_type_name 
	if belt_type == BeltType.INPUT:
		belt_type_name = "input"
	else:
		belt_type_name = "output"
	export_data.append(["Belt.belt_type", belt_name, belt_type_name])
	
	export_data.append(["Belt.cells", belt_name, ExportManager.convert_vector2s_array_to_arrays_array(cells)])
	export_data.append(["Belt.polygons", belt_name, ExportManager.convert_polys_list_to_meters(polys)])
	
	export_data.append(["Belt.interact_areas", belt_name, get_interact_areas_names()])
	

	
	return export_data
	
func export_dynamic() -> Array:
	var export_data = []
	export_data.append(["Belt.packages_list", belt_name, get_packages_names()])
	
	return export_data
