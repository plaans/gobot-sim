from typing import Dict, List

from TCP_Client import TCP_Client


class ActionClient():
	def __init__(self, TCP_Client : TCP_Client):
		self.state = {}
		self.TCP_Client = TCP_Client
		self.counter = 0
		self.callback_functions = {}

	def send_command(self, command : List, response_callback = None, result_callback = None):
		#format of command is a list containing name of command and arguments, for example ['navigate_to','robot1',50,100]
		action_id = self.counter
		self.counter += 1
		data_to_send = {'type': 'robot_command'}
		data_to_send['data'] = command
		data_to_send['id'] = action_id
		

		self.callback_functions[action_id] = {}
		self.callback_functions[action_id]["response"] = response_callback
		self.callback_functions[action_id]["result"] = result_callback

		self.TCP_Client.write(data_to_send)

	def receive_response(self, response_message : Dict):
		print(response_message)
		response_type = response_message["type"]
		response_data = response_message["data"]
		action_id = response_message["id"]

		if action_id in self.callback_functions:
			function_to_call = self.callback_functions[action_id][response_type]
			if callable(function_to_call):
				function_to_call(response_data)

	def navigate_to(self, robot_name : str, dest_x : float, dest_y : float):
		command_to_send = ["navigate_to", robot_name, dest_x, dest_y]
		self.send_command(command_to_send, print, print)

	def navigate_to_area(self, robot_name : str, area_name : str):
		command_to_send = ["navigate_to_area", robot_name, area_name]
		self.send_command(command_to_send, print, print)

	def pick(self, robot_name : str):
		command_to_send = ["pick", robot_name]
		self.send_command(command_to_send, print, print)

	def place(self, robot_name : str):
		command_to_send = ["place", robot_name]
		self.send_command(command_to_send, print, print)

	def do_rotation(self, robot_name : str, rotation : float, speed : float):
		command_to_send = ["do_rotation", robot_name, rotation, speed]
		self.send_command(command_to_send, print, print)

