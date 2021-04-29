extends Node2D

enum BeltType {
	INPUT,
	OUTPUT
}
export(BeltType) var type = BeltType.INPUT
export var size : int = 0 setget set_size, get_size

onready var _PackagePath = $PackagePath
var packages: Array = []

func _ready():
	# At the start of the simulation, create the path the packages will follow
	# from the points of the visual line
	var new_curve = Curve2D.new()
	for point in $Line2D.points:
		new_curve.add_point(point)
	_PackagePath.curve = new_curve

func set_size(new_size: int):
	size = new_size
func get_size():
	return size

# Adds the given package at the end of the packages array
func add_package(package: Node2D):
	packages.append(package)
	package.get_parent().remove_child(package)
	_PackagePath.add_child(package)
	
	package.pos = Vector2.ZERO
	package.unit_offset = 0.0
	
	# TODO: Place package on the line at the right offset

func remove_package(index: int):
	pass
	
	# TODO: When package is removed, move all packages to next offset with Tween
