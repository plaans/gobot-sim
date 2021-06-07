from typing import Dict, List
import uuid

from TCP_Client import TCP_Client
from ActionServer import ActionServer


class ActionClient():
	def __init__(self, TCP_Client : TCP_Client):
		self.state = {}
		self.TCP_Client = TCP_Client

		self.actions = {}

	def send_command(self, command : List) -> ActionServer:
		#format of command is a list containing name of command and arguments, for example ['navigate_to','robot1',50,100]
		temp_id = str(uuid.uuid4())
		data_to_send = {'type': 'robot_command'}
		data_to_send['data'] = command
		data_to_send['temp_id'] = temp_id
		

		new_action = ActionServer(self, temp_id)
		self.actions[temp_id] = new_action

		self.TCP_Client.write(data_to_send)

		return new_action

	def receive_response(self, response_message : Dict):
		temp_id = response_message["temp_id"]
		new_command_id = response_message["command_id"]

		if temp_id in self.actions:
			action = self.actions[temp_id]

			if new_command_id == -1:
				action.reject()
			else:
				self.actions[new_command_id] = action
				action.set_id(new_command_id)

			del self.actions[temp_id]

	def receive_feedback(self, response_message : Dict):
		action_id = response_message["action_id"]
		feedback = response_message["feedback"]
		if action_id in self.actions:
			self.actions[action_id].receive_feedback(feedback)

	def receive_result(self, response_message : Dict):
		action_id = response_message["action_id"]
		result = response_message["result"]
		if action_id in self.actions:
			self.actions[action_id].receive_result(result)

	def send_cancel_request(self, command_id):
		data_to_send = {'type': 'cancel_request'}
		data_to_send['command_id'] = command_id
		self.TCP_Client.write(data_to_send)

	def receive_cancel_response(self, response_message : Dict):
		action_id = response_message["action_id"]
		cancelled = response_message["cancelled"]
		if action_id in self.actions:
			self.actions[action_id].receive_cancel_response(cancelled)

	def navigate_to(self, robot_name : str, dest_x : float, dest_y : float):
		command_to_send = ["navigate_to", robot_name, dest_x, dest_y]
		return self.send_command(command_to_send)

	def navigate_to_cell(self, robot_name : str, dest_x : float, dest_y : float):
		command_to_send = ["navigate_to_cell", robot_name, dest_x, dest_y]
		return self.send_command(command_to_send)

	def navigate_to_area(self, robot_name : str, area_name : str):
		command_to_send = ["navigate_to_area", robot_name, area_name]
		return self.send_command(command_to_send)

	def pick(self, robot_name : str):
		command_to_send = ["pick", robot_name]
		return self.send_command(command_to_send)

	def place(self, robot_name : str):
		command_to_send = ["place", robot_name]
		return self.send_command(command_to_send)

	def do_rotation(self, robot_name : str, rotation : float, speed : float):
		command_to_send = ["do_rotation", robot_name, rotation, speed]
		return self.send_command(command_to_send)

