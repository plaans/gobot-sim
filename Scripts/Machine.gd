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

func is_input_full():
	#returns true if the input buffer is currently full 
	return input_buffer.size()==input_size

func add_package(package : Node):
	#first check if package compatible with machine
	
	#to add a new package to the input of the machine
	if input_buffer.size()<input_size:
		input_buffer.append(package)

func process_to_be_done(package : Node):
	#for a given package determines the next task to be done and its duration
	#returns null if th package has no task compatible with this machine		
	var processes = package.get_processes()
	var list_processes = processes[0]
	for element in list_processes:
		var process = element[0]
		var time = element[1]
		if possible_processes.has(process):
			return element	
	return null
		
func is_output_available():
	#returns true if there is at least one package available in the output buffer
	return output_buffer.size()>0	
		
func take(package : Node):
	#to take a package from the output of the machine
	if output_buffer.size()>0:
		return input_buffer.pop_front()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if taskInProgress:
		timeSinceStart += delta
		if timeSinceStart >= taskDuration:
			#remove task from list of the package (because it was done)
			var tasks_list = current_package.get_processes()
			tasks_list.remove(tasks_list.find(current_process_id))
		
		
		
 
