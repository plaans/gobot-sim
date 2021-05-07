import socket
import sys

import math

import json
import time

import pprint

from multiprocessing import Process


from TCP_Client import TCP_Client
from StateClient import StateClient
from ActionClient import ActionClient

class CompleteClient(TCP_Client, StateClient, ActionClient):
	def __init__(self, address, port):
		TCP_Client.__init__(self, address, port)
		self.listen_to_server()

	def listen_to_server(self):
		while True:
			data = self.read_data()
			
			if data["type"] == "response":
				ActionClient.receive_response(self,data)
			elif data["type"] == "state" or data["type"] == "environment":
				StateClient.update(self,data)

if __name__ == "__main__":

	client = StateClient("localhost",10000)

	

	client.kill()

