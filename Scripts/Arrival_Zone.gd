extends Node2D


var next_packages : Array setget set_next_packages,get_next_packages
#list of the next packages to be generated, containing for each package the list of processes it will have to do

export var output_size = 1
var output_buffer : Array
#output_buffer will be an array of packages

export var wait_time = 5
#time between generation of packages

export (PackedScene) var PackageScene

# Called when the node enters the scene tree for the first time.
#func _ready():
	#$Timer.start(wait_time)

		
func is_output_available():
	#returns true if there is at least one package available in the output buffer
	return output_buffer.size()>0	

func take():
	#to take a package from the output of the machine
	if output_buffer.size()>0:
		var package = output_buffer.pop_front()
		remove_child(package)
		package.position.x=0
		return package


func _process(delta):
	if output_buffer.size()==0 and next_packages.size()>0:
		var new_package = PackageScene.instance()
		new_package.set_name(get_parent().new_package_name())
		add_child(new_package)
		var processes_list = next_packages.pop_front()
		for i in range (processes_list.size()):
				processes_list[i] = [int(processes_list[i][0]),int(processes_list[i][1])]
		new_package.set_processes(processes_list)
		get_parent().add_package(new_package)#to register in the list of packages kept in main
		output_buffer.push_back(new_package)
		
		
func set_next_packages(packages_list : Array):
	next_packages = packages_list
	
func get_next_packages() -> Array:
	return next_packages		
		
		
		
#func _on_Timer_timeout():
#
#	if output_buffer.size()<output_size:
#
#		var new_package = PackageScene.instance()
#		$Output_Belt.add_child(new_package)
#		new_package.set_processes([[0,3],[1,7]])
#		get_parent().add_package(new_package)
#		output_buffer.push_back(new_package)
#
#	$Timer.start(wait_time)#start again the timer
