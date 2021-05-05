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
			key = str(line[:-1])
			value = line[-1]
			self.state[key] = value


	# getter functions, that access the state and return some information
	def coordinates(self, robot_name):
		key = str(["coordinates",robot_name])
		if key in self.state:
			return self.state[key]

	def package_location(self, package_name):
		key = str(["location",package_name])
		if key in self.state:
			return self.state[key]

	

if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

