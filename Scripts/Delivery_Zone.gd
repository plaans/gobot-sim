extends Node2D


var simulation_start_time
var log_name


# Called when the node enters the scene tree for the first time.
func _ready():
	simulation_start_time = OS.get_unix_time()
		
func can_accept_package(package : Node):
	#returns true if the package can be delivered (no processes left to be done)
	return package.get_processes().size()==0
	
func set_log_name(name: String):
	if name=="":
		log_name = "res://logs/log"+str(simulation_start_time)+".txt"
	else:
		log_name = name
	print( log_name)
	
func get_elapsed_time():
	var current_time = OS.get_unix_time()
	return current_time - simulation_start_time
	
	

func add_package(package : Node):
	
	#first check if package is ready to be delivered
	if can_accept_package(package):
		
			
		#if necessary do a treatment to log the delivery time
		var delivery_time = get_elapsed_time()
		
		var file = File.new()
		if file.file_exists(log_name):
			file.open(log_name, File.READ_WRITE)
		else:
			file.open(log_name, File.WRITE)
		file.seek_end()
		file.store_line(str(delivery_time))
		file.close()
		
		#delete the package
		get_parent().remove_package(package) #remove package from the list kept in Main node
		package.queue_free()
		
			
