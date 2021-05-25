import json
from typing import Callable, Dict

from TCP_Client import TCP_Client

class MessageReader():
	def __init__(self, TCP_Client : TCP_Client):
		self.state = {}
		self.TCP_Client = TCP_Client
		self.callbacks = {}
	
	def check_new_data(self):
		data = self.TCP_Client.read()
		while data != None:
			key = data['type']
			if key in self.callbacks:
				self.callbacks[key](data)	
			data = self.TCP_Client.read()

	
	def read_data(self) -> Dict:
		data = self.TCP_Client.read(4)
		if len(data)>0:
			size = int.from_bytes(data,'little')
			data = self.TCP_Client.read(size)
			message = json.loads(data)
			return message
		else:
			return None

	def bind_function(self, data_type : str, function : Callable):
		self.callbacks[data_type] = function

