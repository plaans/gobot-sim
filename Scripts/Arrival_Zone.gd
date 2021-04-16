extends Node2D


# Declare member variables here. Examples:
var possible_processes : Array
#list of processes that can be generated for packages

export var output_size = 1
var output_buffer : Array
#output_buffer will be an array of packages

export var wait_time = 5
#time between generation of packages

export (PackedScene) var PackageScene

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.start(wait_time)
#
#func set_buffer_sizes(input, output):
#	input_size = input
#	output_size = output
#
#	var input_sprite = get_node("Input_Belt/Sprite")
#	var output_sprite = get_node("Output_Belt/Sprite")
#	var stand_length = input_sprite.texture.get_size().x * input_sprite.scale.x
#
#	#for scale changes we do it to the childs of the stand and not the stand directly 
#	#so that when a package becomes child of the stand it gets the right position but keeps its original scale
#	input_sprite.scale.x *= input_size
#	get_node("Input_Belt/CollisionShape2D").scale.x *= input_size
#	output_sprite.scale.x *= output_size
#	get_node("Output_Belt/CollisionShape2D").scale.x *= output_size
#	$Input_Belt.position.x -= stand_length * (input_size-1)/2
#	$Output_Belt.position.x += stand_length * (output_size-1)/2
#
#func set_possible_processes(list_of_processes):
#	possible_processes = list_of_processes
			
			
			
#func adjust_positions(for_input : bool):
#	#adjust the positions of all packages based on their position in the Array
#	#this will be done for the input belt if for_input=true and for the output belt if for_input=false
#
#	var buffer : Array
#	var size : int
#	var multiplicator : int #will be 1 for the input and -1 for the output, used to adjust the direction to translate
#	var sprite
#
#	if for_input:
#		buffer = input_buffer
#		size = input_size
#		multiplicator = 1
#		sprite = get_node("Input_Belt/Sprite")
#	else:
#		buffer = output_buffer
#		size = output_size
#		multiplicator = -1
#		sprite = get_node("Output_Belt/Sprite")
#
#	var belt_length = sprite.texture.get_size().x * sprite.scale.x
#	var spacing_length = belt_length/(size+1) #space between 2 consecutives packages depending on the size of the belt			
#
#	for k in range(buffer.size()):
#		var package = buffer[k]
#		package.position.x = 0
#		#put package to the end of the belt
#		package.position.x += multiplicator * spacing_length * (size-1)/2
#
#		#then moves to the left based no number of packages already on belt
#		package.position.x -= multiplicator * k * spacing_length
		

		
func is_output_available():
	#returns true if there is at least one package available in the output buffer
	return output_buffer.size()>0	

func take():
	#to take a package from the output of the machine
	if output_buffer.size()>0:
		var package = output_buffer.pop_front()
		$Output_Belt.remove_child(package)
		package.position.x=0
		return package


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	if taskInProgress:
#		timeSinceStart += delta
#		if timeSinceStart >= taskDuration:
#			#task ended so check if space available on output belt
#			if output_buffer.size()<output_size:
#				taskInProgress = false
#
#				#remove task from list of the package (because it was done)
#				var tasks_list = current_package.get_processes()
#				tasks_list.remove(tasks_list.find([current_process_id,taskDuration]))
#
#				#add package to output belt
#				output_buffer.push_back(current_package)
#				remove_child(current_package)
#				$Output_Belt.add_child(current_package)
#				adjust_positions(false)
#
#	else:
#		#case where no task currently processed, so check if package waiting in input_buffer
#		if input_buffer.size()>0:
#			current_package = input_buffer.pop_front()
#			$Input_Belt.remove_child(current_package)
#			add_child(current_package)
#			current_package.position.x = 0 #to remove the relative position used while on the belt
#			adjust_positions(true)
#
#			var process = process_to_be_done(current_package)#we know process will not be null since we checked when putting in input_buffer
#			current_process_id = process[0]
#			taskDuration = process[1]
#
#			timeSinceStart = 0.0
#			taskInProgress = true
			
		
		
		
		
		
		
		
		
func _on_Timer_timeout():
	
	if output_buffer.size()<output_size:
		
		var new_package = PackageScene.instance()
		new_package.set_processes([[0,3],[1,7]])
		get_parent().add_package(new_package)
		$Output_Belt.add_child(new_package)
		output_buffer.push_back(new_package)
	
	$Timer.start(wait_time)#start again the timer
