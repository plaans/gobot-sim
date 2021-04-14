extends Node


# Declare member variables here. Examples:
var possible_processes : Array
#ids of all processes that can be done by this machine (initialized from Main node)

export var input_size = 3
export var output_size = 2
var input_buffer : Array
#input_buffer will be an array of packages

var current_package : Node
var current_process_id : int
#package and process being currently done

var output_buffer : Array
#output_buffer will be an array of packages

var taskInProgress #true if there is currently a task being processed
var timeSinceStart #will be reset when a new task begins 
var taskDuration #duration of current task



# Called when the node enters the scene tree for the first time.
func _ready():
	input_buffer=[]
	output_buffer=[]
	
func set_possible_processes(list_of_processes):
	possible_processes = list_of_processes

func can_accept_package(package : Node):
	#returns true if both there is space in the input_buffer and the machine can accept the package
	return (input_buffer.size()<input_size) and (process_to_be_done(package) != null)

func add_package(package : Node):
	
	#first check if package compatible with machine
	if can_accept_package(package):
		
		#to add a new package to the input of the machine
		if input_buffer.size()<input_size:
			input_buffer.append(package)
			$Input_Belt.add_child(package)

func process_to_be_done(package : Node):
	#for a given package determines the next task to be done and its duration
	#returns null if th package has no task compatible with this machine		
	var list_processes = package.get_processes()
	for element in list_processes:
		var process = element[0]
		if possible_processes.has(process):
			return element	
	return null
		
func is_output_available():
	#returns true if there is at least one package available in the output buffer
	return output_buffer.size()>0	
		
func take():
	#to take a package from the output of the machine
	if output_buffer.size()>0:
		var package = output_buffer.pop_front()
		$Output_Belt.remove_child(package)
		return package
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if taskInProgress:
		timeSinceStart += delta
		if timeSinceStart >= taskDuration:
			#task ended so check if space available on output belt
			if output_buffer.size()<output_size:
				taskInProgress = false
			
				#remove task from list of the package (because it was done)
				var tasks_list = current_package.get_processes()
				tasks_list.remove(tasks_list.find([current_process_id,taskDuration]))
				
				#add package to output belt
				output_buffer.push_back(current_package)
				remove_child(current_package)
				$Output_Belt.add_child(current_package)
		
	else:
		#case where no task currently processed, so check if package waiting in input_buffer
		if input_buffer.size()>0:
			current_package = input_buffer.pop_front()
			$Input_Belt.remove_child(current_package)
			add_child(current_package)
			
			var process = process_to_be_done(current_package)#we know process will not be null since we checked when putting in input_buffer
			current_process_id = process[0]
			taskDuration = process[1]
			
			timeSinceStart = 0.0
			taskInProgress = true
			
		
 
