import socket
import json


class TCP_Client:
	def __init__(self, address = 'localhost', port = 10000):
		self.address = address
		self.port = port

		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

	def connect(self) -> bool:
		try:
			self.sock.connect((self.address, self.port))
			return True
		except:
			return False

	def write(self, data):
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


	def read(self):
		data = self.sock.recv(4)
		if len(data)>0:
			size = int.from_bytes(data,'little')
			data = self.sock.recv(size)
			message = json.loads(data)
			return message
		else:
			return None

	def kill(self):
		self.sock.close()
