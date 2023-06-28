from typing import Callable, Dict, List
import threading 
import uuid

from .TCP_Client import TCP_Client
from .ActionClient import ActionClient


class ActionClientManager():
	def __init__(self, TCP_Client : TCP_Client):
		self.TCP_Client = TCP_Client

		self.actions = {}

	def run_command(self, command):
			#format of command is a list containing name of command and arguments, for example ['navigate_to','robot1',50,100]
			#the functions wait until the first response from the server, and then returns the ID attributed to the action
			temp_id = str(uuid.uuid4())
			data_to_send = {}
			if "process" in command:				
				data_to_send = {'type': 'machine_command', 'data' : {}}
			else:
				data_to_send = {'type': 'robot_command', 'data' : {}}
			data_to_send['data']['command_info'] = command
			data_to_send['data']['temp_id'] = temp_id		

			new_action = ActionClient(self, temp_id)
			self.actions[temp_id] = new_action
			new_action.set_id(temp_id)

			self.TCP_Client.write(data_to_send)
			return new_action.wait_id_attributed()

	def set_feedback_callback(self, action_id, callback : Callable):
		if action_id in self.actions:
			self.actions[action_id].set_feedback_callback(callback)

	def set_result_callback(self, action_id, callback : Callable):
		if action_id in self.actions:
			self.actions[action_id].set_result_callback(callback)

	def get_state(self, action_id):
		if action_id in self.actions:
			return self.actions[action_id].get_state()

	def wait_result(self, action_id, timeout : float):
		if action_id in self.actions :
			return self.actions[action_id].wait_result(timeout)
		else:
			return False


	def receive_response(self, response_message : Dict):
		temp_id = response_message['data']["temp_id"]
		new_command_id = response_message['data']["action_id"]

		if temp_id in self.actions:
			action = self.actions[temp_id]

			if new_command_id == -1:
				action.reject()
			else:
				self.actions[new_command_id] = action
				action.accept(new_command_id)

				del self.actions[temp_id]

	def receive_feedback(self, response_message : Dict):
		action_id = response_message['data']["action_id"]
		feedback = response_message['data']["feedback"]
		if action_id in self.actions:
			self.actions[action_id].receive_feedback(feedback)

	def receive_result(self, response_message : Dict):
		action_id = response_message['data']["action_id"]
		result = response_message['data']["result"]
		if action_id in self.actions:
			self.actions[action_id].receive_result(result)

	def send_cancel_request(self, command_id):
		data_to_send = {'type': 'cancel_request', 'data' : {}}
		data_to_send['data']['action_id'] = command_id
		self.TCP_Client.write(data_to_send)

	def receive_preempt(self, response_message : Dict):
		action_id = response_message['data']["action_id"]
		if action_id in self.actions:
			self.actions[action_id].preempted()

	def receive_cancel_response(self, response_message : Dict):
		action_id = response_message['data']["action_id"]
		cancelled = response_message['data']["cancelled"]
		if action_id in self.actions:
			self.actions[action_id].cancel(cancelled)
