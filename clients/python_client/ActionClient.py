import socket
import sys

import math

import json
import time

import pprint

from multiprocessing import Process


from TCP_Client import TCP_Client

class ActionClient(TCP_Client):
	def __init__(self, address, port):
		self.state = {}
		self.callback_functions = {}
		self.counter = 0

		TCP_Client.__init__(self, address, port)
	

	def send_command(command, response_callback = None, result_callback = None):
		#format of command is a list containing name of command and arguments, for example ['navigate_to','robot1',50,100]
		action_id = self.counter
		self.counter += 1
		data_to_send = {'type': 'robot-command', 'data': {}}
		data_to_send['data']['command'] = command
		data_to_send['id'] = action_id

		self.callback_functions[action_id]["response"] = response_callback
		self.callback_functions[action_id]["result"] = result_callback

		self.send_data(data_to_send)

	def receive_response(response_data):
		action_id = response_data["id"]
		if action_id in self.callback_functions:
			function_to_call = self.callback_functions[action_id]["response"]
			function_to_call(response_data)

	def receive_result(response_data):
		action_id = response_data["id"]
		if action_id in self.callback_functions:
			function_to_call = self.callback_functions[action_id]["result"]
			function_to_call(response_data)
	


	def navigate_to(robot_name, dest_x, dest_y):
		command_to_send = ["navigate_to", robot_name, dest_x, dest_y]
		send_command(command_to_send, print, print)

	def pickup(robot_name):
		command_to_send = ["pickup", robot_name]
		send_command(command_to_send, print, print)

	def add_rotation(robot_name, rotation, speed):
		command_to_send = ["add_rotation", robot_name, rotation, speed]
		send_command(command_to_send, print, print)




if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()
