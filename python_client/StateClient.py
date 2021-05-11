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
			self.update(data['data'])

			pprint.pprint(self.state)

	def update(self, data):
		for line in data:
			if len(line)>=3:#to check the data has the right format
				name = line[1]
				attribute = line[0]
				value = line[2]
				if name not in self.state:
					self.state[name] = {}
				self.state[name][attribute] = value

	def get_data(self, key, name):
		if name in self.state and key in self.state[name]:
			return self.state[name][key]

	# getter functions, that access the state and return some information
	def coordinates(self, name):
		return self.get_data("coordinates",name)

	def rotation(self, robot_name):
		return self.get_data("rotation",robot_name)

	def battery(self, robot_name):
		return self.get_data("battery",robot_name)

	def velocity(self, robot_name):
		return self.get_data("velocity",robot_name)

	def rotation_speed(self, robot_name):
		return self.get_data("rotation_speed",robot_name)

	def in_station(self, robot_name):
		return self.get_data("in_station",robot_name)

	def in_interact(self, robot_name):
		return self.in_interact("in_station",robot_name)


	def input_belt(self, machine_name):
		return self.get_data("input_belt",machine_name)

	def output_belt(self, machine_name):
		return self.get_data("output_belt",machine_name)

	def processes_list(self, name):
		return self.get_data("processes_list", name)



	def package_location(self, package_name):
		return self.get_data("batlocationtery",package_name)

	

	

if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

