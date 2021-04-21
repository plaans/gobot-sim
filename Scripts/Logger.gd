extends Node


var log_location #location to save logs to

var elapsed_time #used to check to regularly dave log to file

var log_data : String

var thread

var mutex

export var interval = 12 #time between writing log to file, default being two minutes

# The thread will start here.
func _ready():
	thread = Thread.new()
	mutex = Mutex.new()
	
	
	# Create a timer node
	
	var timer = Timer.new()
	timer.set_wait_time(interval)
	timer.set_one_shot(false)
	timer.connect("timeout", self, "trigger_save")
	add_child(timer)
	timer.start()


func trigger_save():
	thread.start(self, "save_to_file", "")
	
func save_to_file(_arg):
	mutex.lock()
	var copie = log_data
	mutex.unlock()
	
	var file = File.new()
	if file.file_exists(log_location):
		file.open(log_location, File.READ_WRITE) #to open while keeping existing content
	else:
		file.open(log_location, File.WRITE) 
	file.store_string(copie)
	file.close()
	
	thread.wait_to_finish()

func set_log_location(location : String):
	log_location = location

func log_info(text : String):
	mutex.lock()
	log_data += "[INF] %8.3f %s \n" % [OS.get_ticks_msec()/1000.0, text] 
	mutex.unlock()

func log_error(text : String):
	mutex.lock()
	log_data += "[INF] %8.3f %s \n" % [OS.get_ticks_msec()/1000.0, text] 
	mutex.unlock()
	
func warning(text : String):
	mutex.lock()
	log_data += "[INF] %8.3f %s \n" % [OS.get_ticks_msec()/1000.0, text] 
	mutex.unlock()
