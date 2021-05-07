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

		TCP_Client.__init__(self, address, port)
	

	def send_command(command, callback_function):
		#format of command is a list containing name of command and arguments, for example ['navigate_to','robot1',50,100]
		action_id = 0 #generation of unique id still to do
		data_to_send = {'type': 'robot-command', 'data': {}}
		data_to_send['data']['command'] = command
		data_to_send['id'] = action_id

		self.callback_functions[action_id] = callback_function

		self.send_data(data_to_send)

	def receive_response(response_data):
		action_id = response_data["id"]
		function_to_call = self.callback_functions[action_id]
		function_to_call(response_data)
	

if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

