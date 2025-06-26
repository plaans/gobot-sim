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
		
		var data_to_send = {'action_id':action_id}
		var encoded_message = JSON.print({'type': 'action_preempt', 'data':data_to_send})
		Communication.send_message(encoded_message)
	

	#then create new command id
	action_id = ExportManager.generate_new_command_id()
	current_state = states.ACTIVE
	command_name = command
	
	var data_to_send = {'action_id':action_id, 'temp_id':temp_id}
	var encoded_message = JSON.print({'type': 'action_response', 'data':data_to_send})
	Communication.send_message(encoded_message)
	

func reject(temp_id):
	current_state = states.REJECTED
	
	var data_to_send = {'action_id':-1,'temp_id':temp_id}
	var encoded_message = JSON.print({'type': 'action_response', 'data':data_to_send})
	Communication.send_message(encoded_message)
			
func send_feedback(feedback):
	var data_to_send = {'feedback':feedback, 'action_id':action_id}
	var encoded_message = JSON.print({'type': 'action_feedback', 'data':data_to_send})
	Communication.send_message(encoded_message)		
		
func send_result(result : bool):
	if result:
		current_state = states.SUCCEEDED
	else:
		current_state = states.ABORTED
		
	var data_to_send = {'result':result, 'action_id':action_id}
	var encoded_message = JSON.print({'type': 'action_result', 'data':data_to_send})
	Communication.send_message(encoded_message)
	command_name = null
	action_id = -1
	

func cancel_action():
	if current_state == states.ACTIVE:
		
		var data_to_send = {'action_id':action_id, 'cancelled' : true}
		var encoded_message = JSON.print({'type': 'action_cancel', 'data':data_to_send})
		Communication.send_message(encoded_message)
		current_state = states.RECALLED
#	else:
#		var encoded_message = JSON.print({'type': 'action_cancel', 'action_id':action_id, 'cancelled' : false})
#		Communication.send_message(encoded_message)

