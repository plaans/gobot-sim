class_name ActionServer


var registered_commands = {}

enum states {
	PENDING, ACTIVE, RECALLED, REJECTED, PREEMPTED, ABORTED, SUCCEEDED
}

var current_state

var command_name

var action_id

func set_new_goal(command, temp_id):
	if current_state == states.ACTIVE:
		#send message that previous goal was premepted
		current_state = states.PREEMPTED 
		var encoded_message = JSON.print({'type': 'action_preempt', 'command_id':action_id})
		Communication.send_message(encoded_message)
	

	#then create new command id
	action_id = ExportManager.generate_new_command_id()
	current_state = states.ACTIVE
	command_name = command
	var encoded_message = JSON.print({'type': 'action_response', 'command_id':action_id, 'temp_id':temp_id})
	Communication.send_message(encoded_message)
	

func reject(temp_id):
	current_state = states.REJECTED
	var encoded_message = JSON.print({'type': 'action_response', 'command_id':-1,'temp_id':temp_id})
	Communication.send_message(encoded_message)
			
func send_feedback(feedback):
	var encoded_message = JSON.print({'type': 'action_feedback', 'feedback':feedback, 'action_id':action_id})
	Communication.send_message(encoded_message)		
		
func send_result(result : bool):
	var encoded_message = JSON.print({'type': 'action_result', 'result':result, 'action_id':action_id})
	Communication.send_message(encoded_message)
	

func cancel_action():
	if current_state == states.ACTIVE:
		var encoded_message = JSON.print({'type': 'action_cancel', 'action_id':action_id, 'cancelled' : true})
		Communication.send_message(encoded_message)
	else:
		var encoded_message = JSON.print({'type': 'action_cancel', 'action_id':action_id, 'cancelled' : false})
		Communication.send_message(encoded_message)

