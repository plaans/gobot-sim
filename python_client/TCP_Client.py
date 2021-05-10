import socket

import json


class TCP_Client:
	def __init__(self, address, port):
		self.address = address
		self.port = port

		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.connect((self.address, self.port))

	def send_data(self, data):
		message = json.dumps(data)
		length = len(message).to_bytes(4,'little') 
		try:
			self.sock.sendall(length + bytes(message,encoding="utf-8"))
		except:
			print("Error sending, trying to reconnect")
			try:
				self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
				self.sock.connect((self.address, self.port))
				self.sock.sendall(length + bytes(message,encoding="utf-8"))
			except:
				pass


	def read_data(self):
		data = self.sock.recv(4)
		if len(data)>0:
			size = int.from_bytes(data,'little')
			data = self.sock.recv(size)
			message = json.loads(data)
			return message

	def kill(self):
		self.sock.close()

