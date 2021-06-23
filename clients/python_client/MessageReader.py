import json
from typing import Callable, Dict

from TCP_Client import TCP_Client

class MessageReader():
	def __init__(self, TCP_Client : TCP_Client):
		self.state = {}
		self.TCP_Client = TCP_Client
		self.callbacks = {}
	
	def process_new_data(self) -> bool:
		#reads and processes new data if available, and returns True if data was read and False if no data was available
		data = self.TCP_Client.read()
		if data==None:
			return False
		else:
			key = data['type']
			if key in self.callbacks:
				self.callbacks[key](data)	
			return True

	def bind_function(self, data_type : str, function : Callable):
		self.callbacks[data_type] = function

