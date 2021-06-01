import time
import threading 

from MessageReader import MessageReader
from StateClient import StateClient
from ActionClient import ActionClient
from TCP_Client import TCP_Client


class CompleteClient():
	def __init__(self, address : str = 'localhost', port : int = 10000, frequency : float = 60):
		self.address = address
		self.port = port
		self.wait_delay = 1/frequency

		self.TCP_Client =TCP_Client(address, port)
		self.MessageReader = MessageReader(self.TCP_Client)
		self.ActionClient = ActionClient(self.TCP_Client)
		self.StateClient = StateClient()

		self.MessageReader.bind_function("response", self.ActionClient.receive_response)
		self.MessageReader.bind_function("result", self.ActionClient.receive_response)
		self.MessageReader.bind_function("static", self.StateClient.update)
		self.MessageReader.bind_function("dynamic", self.StateClient.update)

		self.thread = threading.Thread(target=self.thread_action)
		self.stop_thread = threading.Event()
		self.thread.daemon = True
		self.thread.start()
		

	def kill(self):
		self.stop_thread.set()
		self.thread.join()
		self.TCP_Client.kill()


	def thread_action(self):
		while not self.stop_thread.wait(self.wait_delay):
			#read all new messages
			new_data_was_available = self.MessageReader.process_new_data()
			while new_data_was_available and not(self.stop_thread.is_set()):
				new_data_was_available = self.MessageReader.process_new_data()


if __name__ == "__main__":
	client = CompleteClient("localhost",10000)

	

	#client.ActionClient.navigate_to('robot0', 15, 15)

	time.sleep(20)

	client.kill()
	


