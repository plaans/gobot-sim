extends Node


var log_location #location to save logs to

var elapsed_time #used to check to regularly dave log to file

var log_data : String

var thread

var mutex

export var interval = 10 #time between writing log to file in seconds

var popup

# The thread will start here.
func _ready():
	thread = Thread.new()
	mutex = Mutex.new()
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	var timer = Timer.new()
	timer.set_wait_time(interval)
	timer.set_one_shot(false)
	timer.connect("timeout", self, "trigger_save")
	add_child(timer)
	timer.start()
	
	popup = AcceptDialog.new()
	get_tree().current_scene.add_child(popup)
	popup.pause_mode = Node.PAUSE_MODE_PROCESS
	popup.set_exclusive(true)
	
	popup.add_button("Quit", true, "text")
	popup.connect("confirmed", self, "popup_continue_simulation")
	popup.connect("custom_action", self, "popup_quit_simulation")
	popup.connect("popup_hide", self, "popup_continue_simulation")
	

func trigger_save():
	thread.start(self, "save_to_file", "")
	thread.wait_to_finish()
	
func save_to_file(_arg):
	mutex.lock()
	var copie = log_data
	mutex.unlock()
	
	var file = File.new()
	var error
	if file.file_exists(log_location):
		error = file.open(log_location, File.READ_WRITE) #to open while keeping existing content
	else:
		error = file.open(log_location, File.WRITE) 
	if not(error):
		file.store_string(copie)
		file.close()

func set_log_location(location : String):
	log_location = location
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		trigger_save()
		
func display_error_message(message_text : String):	
	get_tree().paused = true
	var popup_message = "An error occured :\n %s \n Do you still want to continue the simulation ?" % message_text
	popup.set_text(popup_message)
	popup.popup_centered()
	
func popup_continue_simulation():
	popup.hide()
	get_tree().paused = false
	
func popup_quit_simulation(_action : String):
	trigger_save()
	get_tree().quit()
	
func log_with_tag(tag : String, text : String):	
	mutex.lock()
	log_data += "[%s] %8.3f %s \n" % [tag, OS.get_ticks_msec()/1000.0, text] 
	mutex.unlock()
	print( "[%s] %8.3f %s \n" % [tag, OS.get_ticks_msec()/1000.0, text])
	
func log_info(text : String):
	log_with_tag("INF", text)

func log_error(text : String):
	log_with_tag("ERR", text)

	display_error_message(text)
	
func log_warning(text : String):
	log_with_tag("WAR", text)
