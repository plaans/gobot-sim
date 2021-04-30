extends StaticBody2D

# A belt that needs to be linked to a machine to work.
# The link to the machine is only logical and does not affect the hierarchy of the scene.
# Linking is done from the machine, by setting this node as an input or output belt.
#
# belt_type affects the visual direction of the belt and the way packages are accepted


enum BeltType {
	INPUT,
	OUTPUT
}
export(BeltType) var belt_type = BeltType.INPUT
export var size : int = 0 setget set_size, get_size # slots
export var visual_speed: float = 1.0 setget set_visual_speed, get_visual_speed # slot/s
var packages: Array = []
var machine: Node = null # reference to the machine the belt is linked to
var line_points: PoolVector2Array setget set_line_points, get_line_points
# Points used to make the line and the path

onready var _PackagePath = $PackagePath
onready var _VisualLine = $Line2D

func _ready():
	# At the start of the simulation, make the line if there are points
	if line_points:
		setup_line(line_points)
	
	_VisualLine.material.set_shader_param("speed", visual_speed)

func set_size(new_size: int):
	size = new_size
func get_size():
	return size

func set_visual_speed(new_visual_speed: float):
	visual_speed = new_visual_speed
	# in case the Line2D isn't loaded yet
	if _VisualLine:
		_VisualLine.material.set_shader_param("speed", visual_speed)
func get_visual_speed():
	return visual_speed

func set_line_points(new_points: PoolVector2Array):
	line_points = new_points
	setup_line(line_points)
func get_line_points():
	return line_points

func is_full():
	return packages.size() >= size
func is_empty():
	return packages.size() == 0

# Note: must be called after node entered the tree, or it will not have any effect
func setup_line(new_points: PoolVector2Array):
	if !is_inside_tree():
		return
	# Copy the points given at initialization to the Line2D
	if belt_type == BeltType.INPUT:
		new_points.invert()
	_VisualLine.points = new_points
	# then create the path the packages will follow
	# from the points of the visual line
	var new_curve = Curve2D.new()
	for point in new_points:
		new_curve.add_point(point)
	_PackagePath.curve = new_curve

# Used by a robot or a machine to place a package on the belt.
# If the belt is full return false, else return true
# If the belt is an input, check if the linked machine accepts the package and
# return the result.
func can_accept_package(package: Node, mode: int = 0)->bool:
	if is_full():
		return false
	elif machine and belt_type == BeltType.INPUT:
		return machine.match_process(package, mode)
	else:
		return true

# Adds the given package at the end of the packages array
func add_package(package: Node):
	var slot = packages.size()
	packages.append(package)
	package.get_parent().remove_child(package)
	_PackagePath.add_child(package)
	
	package.pos = Vector2.ZERO
	package.unit_offset = 0.0
	move_package_offset(package, slot/size)

# Removes a package at the given index, and returns the removed package.
# In case of failure, returns null
func remove_package(index: int)->Node:
	var old_package: Node = packages[index]
	packages.remove(index)
	# Skips moving packages if no package was removed
	if old_package:
		old_package.get_parent().remove_child(old_package)
		var slot := index
		while old_package and slot < packages.size():
			move_package_offset(packages[slot], slot/size)
			slot += 1
	
	return old_package

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
