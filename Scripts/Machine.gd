extends Node2D


# Declare member variables here. Examples:
var possible_processes : Array
#ids of all processes that can be done by this machine (initialized from Main node)
var machine_id : int
#id to uniquely identify this machine (also attributed from Main node)

var colors_rects : Array #will contain the array of the sprites used to store colors
onready var color_palette = get_parent().get_color_palette()

export var input_size = 1
export var output_size = 1
var input_buffer : Array
#input_buffer will be an array of packages

var current_package : Node
var current_process_id : int
#package and process being currently done

var output_buffer : Array
#output_buffer will be an array of packages

var taskInProgress : bool = false #true if there is currently a task being processed
var timeSinceStart #will be reset when a new task begins 
var taskDuration #duration of current task

var current_battery_frame : int = 0

#variables used to make the color of current process blink
var blinking_rect 
var original_color

# Called when the node enters the scene tree for the first time.
func _ready():
	input_buffer=[]
	output_buffer=[]
	taskInProgress=false
	generates_display()
	
func set_buffer_sizes(input, output):
	input_size = input
	output_size = output
	
	var input_sprite = get_node("Input_Belt/Sprite")
	var output_sprite = get_node("Output_Belt/Sprite")
	var stand_length = input_sprite.texture.get_size().x * input_sprite.scale.x
	
	#for scale changes we do it to the childs of the stand and not the stand directly 
	#so that when a package becomes child of the stand it gets the right position but keeps its original scale
	input_sprite.scale.x *= input_size
	get_node("Input_Belt/CollisionShape2D").scale.x *= input_size
	output_sprite.scale.x *= output_size
	get_node("Output_Belt/CollisionShape2D").scale.x *= output_size
	$Input_Belt.position.x -= stand_length * (input_size-1)/2
	$Output_Belt.position.x += stand_length * (output_size-1)/2
	
func set_possible_processes(list_of_processes):
	possible_processes = list_of_processes
	update_tasks_display()
	
func set_id(id : int):
	machine_id = id
	
func get_id() -> int:
	return machine_id

func can_accept_package(package : Node):
	#returns true if both there is space in the input_buffer and the machine can accept the package
	return (input_buffer.size()<input_size) and (process_to_be_done(package) != null)

func add_package(package : Node):
	
	#first check if package compatible with machine
	if can_accept_package(package):
		
		#to add a new package to the input of the machine
		if input_buffer.size()<input_size:
			input_buffer.append(package)
			add_child(package)
			package.position.y=-4.5
			package.position.x=compute_position(input_buffer.size()-1, true)
			package.set_draw_behind_parent(true)
			#adjust_positions(true)
			

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
		var package = output_buffer.pop_back()
		remove_child(package)
		package.position.x=0
		package.position.y=0
		package.set_draw_behind_parent(false)
		return package
		
func find_rect(process_id : int):
	#find rect displaying color of corresponding process if it exists
	var index_in_list = possible_processes.find(process_id)
	if index_in_list<0 or index_in_list>=10:
		#if index of process not in list, too late in list to be visually displayed, return null
		return null
	else:
		return colors_rects[index_in_list]
			

func generates_display():
	for k in range(10):
		var rect := ColorRect.new()
		
		rect.rect_size.x = 9
		rect.rect_size.y = 2
		
		if k%2:
			rect.rect_position.x = -21
		else:
			rect.rect_position.x = 12
		
		rect.rect_position.y = -15 + 5 * int(k/2)
		rect.modulate = ColorN(color_palette[k], 1)
		rect.visible = false
		$StaticBody2D/AnimatedSprite.add_child(rect)
		colors_rects.append(rect)
	

func update_tasks_display():
	for k in range(possible_processes.size()):
		if k<10:
			#only display  for the first 10 processes
			var process_id = possible_processes[k]
			var color_name
			if process_id<color_palette.size():
				color_name = color_palette[process_id]
			else:
				#if too much different tasks compared to palette size default other colors to white
				color_name = "white"
				Logger.log_warning("More tasks than the size of color palette, defaulting to displaying as white")
			
			colors_rects[k].modulate = ColorN(color_name, 1)
			colors_rects[k].visible = true
	if possible_processes.size() > 10 :
		Logger.log_warning("More than 10 possible processes for a machine, displaying only the first 10")
		
	for k in range(possible_processes.size(),10):
		colors_rects[k].visible = false
			
func update_battery_display():
	
		
	var display = $StaticBody2D/AnimatedSprite
	var new_frame 
	if not(taskInProgress):
		new_frame = 0
	else:
		var progress_ratio = min(timeSinceStart / taskDuration, 1)
		if progress_ratio>=0.25 and progress_ratio<=0.75:
			progress_ratio = (progress_ratio-0.25)/0.5
			var nb_frame = display.get_sprite_frames().get_frame_count("default")
			new_frame = ceil(progress_ratio  * nb_frame-1)
		else:
			new_frame = 0
	
	if new_frame != current_battery_frame:
		current_battery_frame = new_frame
		display.set_frame(current_battery_frame)	
			
func adjust_positions(for_input : bool):
	#adjust the positions of all packages based on their position in the Array
	#this will be done for the input belt if for_input=true and for the output belt if for_input=false
	
	var buffer : Array
	var size : int
	var multiplicator : int #will be 1 for the input and -1 for the output, used to adjust the direction to translate
	var sprite
	var origin #position of the corresponding belt
	
	if for_input:
		buffer = input_buffer
		size = input_size
		multiplicator = 1
		sprite = get_node("Input_Belt/Sprite")
		origin = $Input_Belt.position.x
	else:
		buffer = output_buffer
		size = output_size
		multiplicator = -1
		sprite = get_node("Output_Belt/Sprite")
		origin = $Output_Belt.position.x
		
	var belt_length = sprite.texture.get_size().x * sprite.scale.x
	var spacing_length = belt_length/(size+1) #space between 2 consecutives packages depending on the size of the belt			
	
	for k in range(buffer.size()):
		var package = buffer[k]
		package.position.x = 0
		#put package to the end of the belt
		package.position.x += origin + multiplicator * spacing_length * (size-1)/2
			
		#then moves to the left based no number of packages already on belt
		package.position.x -= multiplicator * k * spacing_length
		
func compute_position(index : int, for_input : bool) -> float:
	#computes where a package needs to be located depending on his position in the machine
	#the argument index is the position in the buffer #(input_buffer if for_input = true
	#and output_buffer if for_input = false)
	#returns the x position the package needs to be displayed at (in the machine local coordinates)
	
	if (for_input and index >= input_size) or (not(for_input) and index >= output_size):
		return 0.0
	else:
		#input or output_belt
		var size : int
		var multiplicator : int #will be 1 for the input and -1 for the output, used to adjust the direction to translate
		var sprite
		var origin #position of the corresponding belt
		
		if for_input:
			#case of input
			size = input_size
			multiplicator = 1
			sprite = get_node("Input_Belt/Sprite")
			origin = $Input_Belt.position.x
		else:
			#case of output
			size = output_size
			multiplicator = -1
			sprite = get_node("Output_Belt/Sprite")
			origin = $Output_Belt.position.x
			
		var belt_length = sprite.texture.get_size().x * sprite.scale.x
		var spacing_length = belt_length/(size+1) #space between 2 consecutives packages depending on the size of the belt			
	
		var xposition = 0
		#put package to the end of the belt
		xposition += origin + multiplicator * spacing_length * (size-1)/2
			
		#then moves to the left based no number of packages already on belt
		xposition -= multiplicator * index * spacing_length
			
		return xposition
			
func interpolate_package_position(package : Node, origin_id : int,
								 is_origin_in_input : bool, destination_id : int, is_destination_in_input : bool,
								  ratio : float):
	#places the package correctly based on his id at origin and at destination 
	#(id defined as in compute_position function, with the sign indicating if input or output buffer)
	var origin_x = compute_position(origin_id, is_origin_in_input)
	var destination_x = compute_position(destination_id, is_destination_in_input)
	package.position.x= origin_x + ratio * (destination_x - origin_x)
		
func move_packages():
	#moves all packages to their current position
	
	if taskInProgress:
		var progress_ratio = min(timeSinceStart / taskDuration, 1)
		
		#packages on output_buffer need to be moved if there is space left
		if output_buffer.size()<output_size:
			for k in range(output_buffer.size()):
				var package = output_buffer[k]
				interpolate_package_position(package, k, false, k+1, false, progress_ratio)
				
		#then move package currently being processed, depending on if first or second half
		if progress_ratio<=0.25:
			current_package.position.x = (1 - progress_ratio/0.25) * compute_position(0, true)
		elif progress_ratio>=0.75:
			current_package.position.x = (progress_ratio-0.75)/0.25 * compute_position(0, false)
		#interpolate_package_position(current_package, 0, true, 0, false, progress_ratio)
		
		#then move packages in input_buffer
		for k in range(1,input_buffer.size()):
			var package = input_buffer[k]
			interpolate_package_position(package, k, true, k-1, true, progress_ratio)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if taskInProgress:
		timeSinceStart += delta
		move_packages()
		
		#update color of display
		if blinking_rect!=null:
			var new_color = Color.from_hsv(original_color.h, 0.2, original_color.v)
			blinking_rect.modulate = original_color.linear_interpolate(new_color, 0.5+0.5*sin(-PI/2 + 5*timeSinceStart)) 
		
		if 	timeSinceStart/taskDuration>=0.75 and ((timeSinceStart-delta)/taskDuration<0.75):
			#remove task from list of the package (because it was done)
			var tasks_list = current_package.get_processes()
			tasks_list.remove(tasks_list.find([current_process_id,taskDuration]))
			current_package.update_tasks_display()
			
		if timeSinceStart >= taskDuration:
			#task ended so check if space available on output belt
			if output_buffer.size()<output_size:
				taskInProgress = false
				input_buffer.pop_front()
				
				#add package to output belt
				output_buffer.push_front(current_package)
				#adjust_positions(false)
				
				blinking_rect.modulate = original_color
				blinking_rect = null
				
				Logger.log_info("%-12s %8s %8s %8s" % ["processed", machine_id, current_process_id, taskDuration])
		
	else:
		#case where no task currently processed, so check if package waiting in input_buffer and space in output_buffer
		if input_buffer.size()>0 and output_buffer.size()<output_size:
			current_package = input_buffer[0]
			#current_package.position.x = 0 #to remove the relative position used while on the belt
			#adjust_positions(true)
			
			var process = process_to_be_done(current_package)#we know process will not be null since we checked when putting in input_buffer
			current_process_id = process[0]
			taskDuration = process[1]
			
			timeSinceStart = 0.0
			taskInProgress = true
			
			blinking_rect = find_rect(current_process_id)
			if blinking_rect!= null:
				original_color = blinking_rect.modulate
			
	update_battery_display()		
	
 
