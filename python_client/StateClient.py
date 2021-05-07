import socket
import sys

import math

import json
import time

import pprint

from multiprocessing import Process


from TCP_Client import TCP_Client

class StateClient(TCP_Client):
	def __init__(self, address, port):
		self.state = {}

		TCP_Client.__init__(self, address, port)

		self.listen_to_server()
	

	def listen_to_server(self):
		while True:
			data = self.read_data()
			self.update(data)

			pprint.pprint(self.state)
			print(self.coordinates("robot1"))

	def update(self, data):
		for line in data:
			if len(line)>=3:#to check the data has the right format
				name = line[1]
				attribute = line[0]
				value = line[2]
				self.state[name][attribute] = value

	def get_data(self, key, name):
		if name in self.state and key in self.state[name]:
			return self.state[name][key]

	# getter functions, that access the state and return some information
	def coordinates(self, name):
		return get_data("coordinates",name)

	def rotation(self, robot_name):
		return get_data("rotation",robot_name)

	def battery(self, robot_name):
		return get_data("battery",robot_name)

	def is_moving(self, robot_name):
		return get_data("is_moving",robot_name)

	def is_rotating(self, robot_name):
		return get_data("is_rotating",robot_name)

	def in_station(self, robot_name):
		return get_data("in_station",robot_name)



	def input_area(self, machine_name):
		return get_data("input_area",machine_name)

	def output_area(self, machine_name):
		return get_data("output_area",machine_name)

	def buffers_sizes(self, machine_name):
		return get_data("buffers_sizes",machine_name)

	def processes_list(self, name):
		return get_data("processes_list", name)



	def package_location(self, package_name):
		return get_data("batlocationtery",package_name)

	

	

if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

